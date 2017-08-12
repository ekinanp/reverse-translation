require_relative 'po_table'
require_relative 'log_parser'

# This class contains the code used to reverse translate a given log file.
# For now, it hardcodes the possible PO files that it needs to go to as class
# level constants but in the future, this will be remedied
#
# Right now, it will maintain an array of lookup tables where one lookup table
# encapsulates a single POT file. For initialization, it will take the list of
# POT files that it needs in order to create its lookup tables.
class ReverseTranslator 
  attr_reader :tables 

  def initialize(pot_files)
    @tables = pot_files.map { |file| POTable.new(file) }
  end

  # TODO: This method should have a REGEX denoting a valid prefix
  # for the log file. Either this can be a class-level constant,
  # or it can be provided as an input parameter into this function.
  # For now, we will assume that the log file consists only of messages.
  # What if a LOG spans more than one line? The prefixes will separate
  # various LOG files. So I need to add that here. This needs a lot more
  # work in order for it to do its job.
  #
  # Reverse translations will be written with the ".trans" extension.
  # This can be changed in the future
  def reverse_translate(log_file)
    log_file_trans = log_file + ".trans"
    out_file = File.open(log_file_trans, "w")
    LogParser.parse(log_file).each do |entry|
      translated_entry = tables.inject(entry) do |new_entry, table|
        table.reverse_translate(new_entry)
      end
      out_file.puts(translated_entry)
    end
    out_file.close
  end
end
