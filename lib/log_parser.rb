module LogParser
  # This method takes in regexp components that make up a prefix,
  # and builds the overall prefix expression out of them by including 
  # whitespace in-between them. For example if we do build_prefix_re(r1, r2),
  # then this will return r3 = r1\s+r2.
  #
  # Each component should be either a single element array (indicating that it's optional),
  # or not.
  def self.build_prefix_re(*pieces)
    pieces.inject do |prefix_re, piece|
      is_optional = piece.is_a?(Array)
      piece = piece[0] if is_optional
      Regexp.new(prefix_re.to_s + "(?:" + /\s+/.to_s + piece.to_s + ")#{"?" if is_optional}")
    end
  end

  # Prefix components, obtained from examining individual entries in log files, or looking
  # at their logback.xml if the repo had it.
  DATE = /\d{4}-\d{2}-\d{2}/
  TIMESTAMP = /\d{2}:\d{2}:\d{2}[.,]\d*/
  THREAD = /\[[^\s]+\]/
  LEVEL = /[[:upper:]]+/
  CALLER = /\[[^\s]+\](?:(?:\s+\[[^\s]+\]){0,2})/
  # Since timezone can be all uppercase
  TIMEZONE = LEVEL
  # For cpp projects
  NAMESPACE = /\w+(?:\.\w+)*:\d+/ 

  # This prefix applies to:
  #   (1) PCP-BROKER.LOG
  #   (2) PUPPETSERVER.LOG
  #   (3) PUPPETDB
  PREFIX_ONE = build_prefix_re(DATE, TIMESTAMP, LEVEL, THREAD, [CALLER])
  # This prefix applies to:
  #   (1) PXP-Agent (and any CPP project that uses leatherman logging)
  PREFIX_TWO = build_prefix_re(DATE, TIMESTAMP, LEVEL, NAMESPACE, /-/)
  # This prefix applies to:
  #   (1) Postgres logs
  PREFIX_THREE = build_prefix_re(DATE, TIMESTAMP, TIMEZONE, THREAD)
  # This prefix applies to:
  #   (1) CONSOLE-SERVICES.LOG
  PREFIX_FOUR = build_prefix_re(DATE, TIMESTAMP, THREAD, LEVEL, [CALLER])

  # In case we get a log-file where none of the prefixes match, it's highly
  # likely that this will as all of the log files I've looked at capture this
  # general pattern of an YYYY-MM-DD date followed by a timestamp.
  PREFIX_GENERAL = build_prefix_re(DATE, TIMESTAMP)

  # All possible prefixes. Note that the shortest prefix, "PREFIX_GENERAL" is
  # last because we want the longer prefixes to match first.
  PREFIXES = Regexp.union(
    PREFIX_ONE,
    PREFIX_TWO,
    PREFIX_THREE,
    PREFIX_FOUR,
    PREFIX_GENERAL
  )

  SEPARATOR = Regexp.new("(^" + PREFIXES.to_s + /\s+/.to_s + ")")

  # Parses the given file object, returning an array where each entry consists of:
  #     [PREFIX, MSG]
  # It is assumed that each .log file is of the form
  #     (<SEPARATOR><MSG>)*
  def self.parse(file)
    file.read.split(SEPARATOR)[1..-1].each_slice(2).to_a
  end
end
