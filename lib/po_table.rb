require_relative 'po_parser'
require_relative 'po_entry'
require_relative 'array'

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
    start = @entries.bsearch_index_left do |e|
      cmp_res = e.min_length <=> msg.length
      cmp_res == 0 || cmp_res == -1 ? 0 : 1
    end
    return msg unless start

    # Now translate
    translated_msg = msg
    (start...@entries.size).each do |ix|
      old_msg = translated_msg
      translated_msg = @entries[ix].reverse_translate(old_msg) 
      return translated_msg if translated_msg.object_id != old_msg.object_id
    end
    translated_msg
  end

  # This will return the average length of each entry.
  def average_length(entry)
    entry.values.inject(0.0) { |sum, e| sum + e.length } / entry.size
  end

  private :average_length
end
