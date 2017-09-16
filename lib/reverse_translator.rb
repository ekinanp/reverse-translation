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

  # This method takes three parameters: 
  #   (1) An input file object containing the log messages that need to be translated
  #   (2) An output file object to write the translated messages to
  #   (3) The depth of the translations
  # The input file object should be open for reading, while the output file object should
  # be open for writing.
  #
  # TODO: This should eventually be multi-threaded. Have each thread translate its
  # own chunk of the parsed out messages, returning an array of translated messages.
  # Then combine these messages together and print them out to the output file.
  #
  # TODO: @tables[0] is used as a default. In the future, this should be extended so
  # that a log message can be translated using the table containing the group that
  # it belongs to (e.g. table[0] can be puppet only logs, table[1] postgres, table[2]
  # some other third party log, etc.).
  def reverse_translate(input_file, output_file, depth)
    LogParser.parse(input_file).each do |log_message|
      @tables[0].reverse_translate(log_message, depth)
      output_file.puts(log_message)
    end
  end
end
