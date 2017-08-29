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

  # This method takes two parameters: the log file that's to be translated,
  # and the path of the output file containing the locations of where to write
  # the translations.
  #
  # TODO: This should eventually be multi-threaded. Have each thread translate its
  # own chunk of the parsed out messages, returning an array of translated messages.
  # Then combine these messages together and print them out to the output file.
  def reverse_translate(log_file, log_file_trans)
    out_file = File.open(log_file_trans, "w")
    LogParser.parse(log_file).each do |(prefix, msg)|
      translated_msg = @tables.inject(msg.strip) do |cur_msg, table|
        table.reverse_translate(cur_msg)
      end
      out_file.puts(prefix + translated_msg)
    end
    out_file.close
  end
end
