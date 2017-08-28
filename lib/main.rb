require_relative 'reverse_translator'

# This module contains the code for the CLI. For now, it takes in
# a single log-file as an argument (with the ".log" extension) and
# outputs a translated log-file (extended with an additional ".trans"
# extension).
module Main
  USAGE = "USAGE: ./reverse_translate <log-file>"
  NO_ARG_MSG = "ERROR: No log-file provided!\n#{USAGE}"

#  PO_FILES = [`find resources/ja/ -name "*.po"`.split] # <-- TODO: Use this instead!
  PO_FILES = [["resources/ja/puppet0.po"]]
 
  def self.error_exit(msg)
    puts msg
    1
  end

  def self.run(argv)
    return error_exit(NO_ARG_MSG) if argv.empty? 
    log_file = argv[0]
    return error_exit("ERROR: #{log_file} does not exist!") unless File.exists?(log_file)
    return error_exit("ERROR: #{log_file} is not a valid log file! Log files must have the "\
      "\".log\" extension.") unless log_file =~ /.*\.log/

    log_file_trans = log_file + ".trans"
    ReverseTranslator.new(PO_FILES).reverse_translate(log_file, log_file_trans)
    puts "#{log_file} was successfully translated, with the result written to #{log_file_trans}!"
    0
  end

  private_class_method :error_exit
end
