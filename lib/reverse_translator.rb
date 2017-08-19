require_relative 'po_table'
require_relative 'log_parser'

# This class contains the code used to reverse translate a given log file.#
# Right now, it will maintain an array of lookup tables where one lookup table
# encapsulates multiple PO files. For initialization, it will take an array of
# arrays of PO files that it needs to create its lookup tables.
class ReverseTranslator 
  def initialize(po_groups)
    @tables = po_groups.map { |po_files| POTable.new(po_files) }
  end

  # Reverse translations will be written with the ".trans" extension.
  # This can be changed in the future
  def reverse_translate(log_file)
    log_file_trans = log_file + ".trans"
    out_file = File.open(log_file_trans, "w")
    LogParser.parse(log_file).each do |entry|
      translated_entry = @tables.inject(entry) do |new_entry, table|
        table.reverse_translate(new_entry)
      end
      out_file.puts(translated_entry)
    end
    out_file.close
  end
end
