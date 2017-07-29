# TODO: This module considers only happy cases (when the POT file is a valid
# POT file). Maybe add some error message output/error-handling? Not necessary
# for now, though.
module POParser
  MSGID = /msgid(?:_plural)?/
  MSGSTR = /msgstr(?:\[\d+\])?/
  VALUE = /"(.*)"/

  MSGID_ENTRY = Regexp.new("(#{MSGID.to_s})"+"\s+"+"((?:#{VALUE.to_s}\n)+)")
  MSGSTR_ENTRY = Regexp.new("(#{MSGSTR.to_s})"+"\s+"+"((?:#{VALUE.to_s}\n)+)")
  MSGID_PART = Regexp.new("(?:#{MSGID_ENTRY.to_s})+")
  MSGSTR_PART = Regexp.new("(?:#{MSGSTR_ENTRY.to_s})+")

  # Hacky b/c scan returns everything in groups, but keeps it simple. If performance
  # is an issue (lots of arrays created), can hardcode the group vs. non-group regexes
  # if need be.
  PO_ENTRY = Regexp.new("(#{MSGID_PART.to_s+MSGSTR_PART.to_s})")

  def self.parse_part(part, entry_re)
    part.scan(entry_re).inject({}) do |entries, entry|
     key = entry[0]
     val = entry[1].scan(VALUE).join
     entries.merge(key => val)
    end
  end

  # Parses the given PO file, returning an array of pairs of maps. Each pair 
  # of maps will be two entries: <msg-id> <msg-str>. <msg-id> will contain 
  # the values of the "msgid" and "msgid_plural" fields, while <msg-str> will 
  # contain values for "msgstr" and "msgstr[0]" fields. For example, an entry 
  # might look like:
  #
  # <msg-id> = { "msgid" => "Foo", "msgid_plural" => "Foos" }
  # <msg-str> = { "msgstr[0]" => "Translation 1", "msgstr[1]" => "Translation 2" }
  def self.parse(path)
    IO.read(path).scan(PO_ENTRY).map do |entry|
      entry = entry[0]
      msgid_entries = parse_part(MSGID_PART.match(entry)[0], MSGID_ENTRY)
      msgstr_entries = parse_part(MSGSTR_PART.match(entry)[0], MSGSTR_ENTRY)
      [msgid_entries, msgstr_entries]
    end
  end
end
