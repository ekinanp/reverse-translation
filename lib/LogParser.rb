# TODO: In case a log entry contains a quoted string, escaped characters inside these strings
# need to be handled (like in POParser.rb). This can be done by taking out the logic in
# POParser.rb and making it a separate module that both LogParser and POParser can use.
module LogParser
  DATE_YYYY_MM_DD = /\d{4}-\d{2}-\d{2}/
  SEPARATOR = Regexp.new("(^" + DATE_YYYY_MM_DD.to_s + ")")

  # Parses the given .log file, returning an array of log messages.
  def self.parse(path)
    IO.read(path).split(SEPARATOR)[1..-1].each_slice(2).map { |date_msg| date_msg.join.chomp }
  end
end
