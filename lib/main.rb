require_relative 'reverse_translator'

# This module contains the code for the CLI. If it is not provided
# with any arguments, then it defaults to reading the log message
# input from STDIN and printing the translations to STDOUT. Otherwise,
# it takes in a single log-file as an argument (with the ".log" extension)
# and outputs a translated log-file (extended with an additional ".trans"
# extension).
module Main
  PROJECT_ROOT = File.dirname(File.dirname(__FILE__))
  PO_FILES = [`find #{PROJECT_ROOT}/resources/ja/ -name "*.po"`.split]
 
  def self.error_exit(msg)
    puts msg
    1
  end

  def self.run(argv)
    if argv.empty?
      ReverseTranslator.new(PO_FILES).reverse_translate(STDIN, STDOUT)
      return 0
    end

    log_file = argv[0]
    return error_exit("ERROR: #{log_file} does not exist!") unless File.exists?(log_file)
    return error_exit("ERROR: #{log_file} is not a valid log file! Log files must have the "\
      "\".log\" extension.") unless log_file =~ /.*\.log/

    log_file_trans = log_file + ".trans"
    input_file = File.open(log_file, "r")
    output_file = File.open(log_file_trans, "w")
    ReverseTranslator.new(PO_FILES).reverse_translate(input_file, output_file)
    puts "#{log_file} was successfully translated, with the result written to #{log_file_trans}!"
    input_file.close
    output_file.close
    0
  end

  private_class_method :error_exit
end
