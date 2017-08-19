require_relative 'po_parser'
require_relative 'po_entry'

# This class represents the reverse-lookup table for an array of PO files.
# It is intended that an array of PO files will correspond to logs obtained
# from services implemented in a specific language (e.g. Clojure). Or they
# can correspond to all the PO files.
class POTable
  def initialize(pot_files)
    @entries = pot_files.map { |f| POParser::parse(f) }.reduce(:concat).sort! do |e1, e2|
      msgstr_avg_cmp = average_length(e2[1]) <=> average_length(e1[1])
      next msgstr_avg_cmp unless msgstr_avg_cmp == 0
      average_length(e2[0]) <=> average_length(e1[0])
    end.map { |e| POEntry.new(e) }
  end

  def reverse_translate(msg)
    @entries.inject(msg) { |new_msg, entry| entry.reverse_translate(new_msg) }
  end

  def average_length(entry)
    entry.values.inject(0.0) { |s, e| s + e.length } / entry.size
  end

  private :average_length
end
