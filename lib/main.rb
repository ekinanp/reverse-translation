require 'optparse'
require_relative 'reverse_translator'

# This class contains the code for the CLI.
class Main
  attr_reader :po_files

  def initialize
    project_root = File.dirname(File.dirname(__FILE__))
    @po_files = [`find #{project_root}/resources/ja/ -name "*.po"`.split]
    @options = {}
    @options[:depth] = 1

    @opt_parser = OptionParser.new do |opts|
      opts.banner = "Translates the given log file. Note that the passed-in log file must have the\n"\
                    "\".log\" extension. If no log file is provided, then the tool reads from STDIN\n"\
                    "and writes to STDOUT\n\n"\
                    "Usage: ./bin/reverse_translate [log-file] [options]"
      opts.set_summary_indent(' '*2)
      
      opts.separator ""
      opts.separator "Options:"

      depth_descp = ["The depth of the translation, default value is 1. This",
                    "parameter specifies the maximum number of times a given",
                    "message should be translated -- useful for foreign log",
                    "messages that contain other foreign log messages as",
                    "parameters (e.g. error logs containing exception messages).",
                    "If 0 or a negative argument is passed, defaults to infinity.",
                    "Infinity means that the entire lookup table is traversed when",
                    "translating a given message."]
      opts.on("-d", "--depth N", Integer, *depth_descp) do |n|
        @options[:depth] = n > 0 ? n : -1
      end

      opts.separator ""

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit 0
      end
    end
  end
 
  def error_exit(msg)
    puts msg
    1
  end

  def parse(argv)
    begin
      @opt_parser.parse(argv)
    rescue OptionParser::ParseError => e
      exit error_exit("Parsing Error - #{e.message}")
    end
  end

  def run(argv)
    rest = parse(argv)
    if rest.empty?
      ReverseTranslator.new(@po_files, @options[:depth]).reverse_translate(STDIN, STDOUT)
      return 0
    end

    log_file = rest[0]
    return error_exit("ERROR: #{log_file} does not exist!") unless File.exists?(log_file)
    return error_exit("ERROR: #{log_file} is not a valid log file! Log files must have the "\
      "\".log\" extension.") unless log_file =~ /.*\.log/

    log_file_trans = log_file + ".trans"
    input_file = File.open(log_file, "r")
    output_file = File.open(log_file_trans, "w")
    ReverseTranslator.new(@po_files).reverse_translate(input_file, output_file, @options[:depth])
    puts "#{log_file} was successfully translated, with the result written to #{log_file_trans}!"
    input_file.close
    output_file.close
    0
  end

  private :error_exit, :parse
end
