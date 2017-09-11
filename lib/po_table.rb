require_relative 'po_parser'
require_relative 'po_entry'
require_relative 'utils'

# This class represents the reverse-lookup table for an array of PO files.
# It is intended that an array of PO files will correspond to logs obtained
# from services implemented in a specific language (e.g. Clojure). Or they
# can correspond to all the PO files.
class POTable
  def initialize(pot_files, depth)
    # Set the depth of the translation
    @depth = depth

    # Sort the entries by longest match
    parsed_entries = pot_files.map { |f| POParser::parse(f) }.reduce(:concat).sort do |e1, e2|
      msgstr_avg_cmp = average_length(e2[1]) <=> average_length(e1[1])
      next msgstr_avg_cmp unless msgstr_avg_cmp == 0
      average_length(e2[0]) <=> average_length(e1[0])
    end

    # Keep only those entries that do not have any adjacent parameters (to avoid
    # catastrophic backtracking).
    #
    # TODO: Add tests.
    @entries = parsed_entries.select do |entry|
      entry[1].all? { |_, msg| not msg.adjacent_params? }
    end.map { |entry| POEntry.new(entry) }
  end

  # The translation algorithm. Here's how it works. Initially, the
  # message is untranslated, so max_untranslated_length = message.length.
  # We loop and do the following:
  #   (1) If the message was translated from a previous iteration, then we
  #   can reduce the search space by doing a binary search starting at our
  #   previous index, ix, to find the next location that we should start
  #   translating from. This lets us skip entries that we don't need to
  #   consider.
  #
  #   (2) If there is no location, i.e. the remaining po entries are too
  #   large for our message to be translated, OR we've reached the end of
  #   our @entries array, we exit.
  #
  #   (3) Otherwise, we translate the message with the current entry. If
  #   that translation resulted in the entire message being translated OR
  #   we have reached our maximum depth, we exit. Otherwise, we loop to our
  #   next entry and repeat (1) - (3).
  #
  # Initially, was_translated is vacuously true. One key invariant in the
  # loop is that the ix returned by bsearch_index_left(ix) is >= the passed-in
  # ix (because log_message's max_untranslated_length will always shrink). So
  # our loop is guaranteed to terminate.
  def reverse_translate(log_message)
    was_translated = true
    cur_depth = 0
    ix = 0
    loop do
      ix = @entries.bsearch_index_left(ix) do |e|
        cmp_res = e.min_length <=> log_message.max_untranslated_length
        cmp_res == 0 || cmp_res == -1 ? 0 : 1
      end if was_translated
      return unless ix && ix < @entries.size

      was_translated = log_message.translate_with(@entries[ix])
      cur_depth += 1 if was_translated
      return if log_message.translated? || cur_depth == @depth
      ix += 1
    end
  end

  # This will return the average length of each entry.
  def average_length(entry)
    entry.values.inject(0.0) { |sum, e| sum + e.length } / entry.size
  end

  private :average_length
end
