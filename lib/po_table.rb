require_relative 'po_parser'
require_relative 'po_entry'

# This class represents the reverse-lookup table for an array of PO files.
# It is intended that an array of PO files will correspond to logs obtained
# from services implemented in a specific language (e.g. Clojure). Or they
# can correspond to all the PO files.
class POTable
  def initialize(pot_files)
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

  def reverse_translate(msg)
    @entries.inject(msg) { |new_msg, entry| entry.reverse_translate(new_msg) }
  end

  # This will return the average length of each entry.
  def average_length(entry)
    entry.values.inject(0.0) { |sum, e| sum + e.length } / entry.size
  end

  private :average_length
end
