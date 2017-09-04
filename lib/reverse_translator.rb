require_relative 'po_table'
require_relative 'log_parser'

# This class contains the code used to reverse translate a given log file.#
# Right now, it will maintain an array of lookup tables where one lookup table
# encapsulates multiple PO files. For initialization, it will take an array of
# arrays of PO files that it needs to create its lookup tables.
class ReverseTranslator 
  MSGS_PER_THREAD = 2000

  def initialize(po_groups)
    @tables = po_groups.map { |po_files| POTable.new(po_files) }
  end

  # This method takes two parameters: an input file object containing the log
  # messages that need to be translated, and an output file object to write the
  # translated messages to. The input file object should be open for reading, while
  # the output file object should be open for writing.
  #
  # TODO: @tables[0] is used as a default. In the future, this should be extended so
  # that a log message can be translated using the table containing the group that
  # it belongs to (e.g. table[0] can be puppet only logs, table[1] postgres, table[2]
  # some other third party log, etc.).
  #
  # NOTE: If performance becomes an issue, consider using a thread pool.
  def reverse_translate(input_file, output_file)
    threads = LogParser.parse(input_file).each_slice(MSGS_PER_THREAD).to_a.map do |log_msgs|
      Thread.new do
        translated_msgs = log_msgs.map do |(prefix, msg)|
          prefix + @tables[0].reverse_translate(msg.strip)
        end
      end
    end

    threads.each do |thread|
      thread.value.each { |log_msg| output_file.puts(log_msg) }
    end
  end
end
