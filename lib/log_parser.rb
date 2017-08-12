module LogParser
  DATE_YYYY_MM_DD = /\d{4}-\d{2}-\d{2}/
  SEPARATOR = Regexp.new("(^" + DATE_YYYY_MM_DD.to_s + ")")

  # Parses the given .log file, returning an array of log messages. It is assumed that each
  # .log file is of the form
  #     (<SEPARATOR><MSG>)*
  def self.parse(path)
    IO.read(path).split(SEPARATOR)[1..-1].each_slice(2).map { |date_msg| date_msg.join.chomp }
  end
end
