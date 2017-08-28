module LogParser
  # TODO: Find common patterns in these prefix regexes and remove them!
  # CONSOLE-SERVICES.LOG
  # <DATE> <TIMESTAMP,> <SERVICE> <TYPE> <SERVICE>
  #
  # ORCHESTRATION-SERVICES-2017-07-25.0.LOG
  # <DATE> <TIMESTAMP,> <TYPE> <SERVICE>
  # <DATE> <TIMESTAMP,> <TYPE> <SERVICE> <NAME> -
  #
  # ORCHESTRATION-SERVICES.LOG
  # <DATE> <TIMESTAMP,> <TYPE> <SERVICE>
  #
  # PCP-BROKER.LOG
  # <DATE> <TIMESTAMP,> <TYPE> <SERVICE> <SERVICE> 
  #
  # PGSTARTUP.LOG
  # <DATE> <TIMESTAMP.> <TIMEZONE> <SERVICE> <MSGKIND>:
  # <DATE> <TIMESTAMP.> <TIMEZONE> <SERVICE>
  #
  # POSTGRESQL-TUE.LOG
  # <DATE> <TIMESTAMP.> <TIMEZONE> <SERVICE> <MSGKIND>
  # <DATE> <TIMESTAMP.> <TIMEZONE> <SERVICE>
  #
  # PXP-AGENT.LOG
  # <DATE> <TIMESTAMP.> <INFO> <CODE-PART> -

  # Current prefix stuff
  DATE_YYYY_MM_DD = /\d{4}-\d{2}-\d{2}/
  SEPARATOR = Regexp.new("(^" + DATE_YYYY_MM_DD.to_s + ")")

  # Parses the given .log file, returning an array of log messages. It is assumed that each
  # .log file is of the form
  #     (<SEPARATOR><MSG>)*
  def self.parse(path)
    IO.read(path).split(SEPARATOR)[1..-1].each_slice(2).map { |date_msg| date_msg.join.chomp }
  end
end
