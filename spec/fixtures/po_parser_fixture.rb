module POParserFixture
  # A PO file contains both "msgid" and "msgstr" entries -- call an entry with some
  # "msgid" parts and some "msgstr" parts a "po entry" for simplicity. Now a single
  # part in a "po entry" (e.g. a "msgid" field) consists of a value representing the
  # string for that part. In an actual PO file, that part's value will be split across
  # multiple lines. For example, we can have something like:
  #    msgid ""
  #    "This is a message"
  #    msgstr ""
  #    "This is that message's translation"
  #
  # where the value for the msgid part of the message is the phrase "This is a message",
  # while for the msgstr part of the message, this will be the phrase "This is that message's
  # translation".
  #
  # When testing the POParser, we need to ensure that it extracts the correct structure of
  # the PO file. But to do that, we need to simulate how a PO file might be created. Looking
  # at the above example, the simplest way to do this is to let a single part consist of
  # two pieces:
  #    [entry_name, value]
  # where the entry_name can be "msgid", "msgstr", whatever. The value we can represent as an
  # array of strings (to simulate how it is distributed across multiple lines). For our above
  # example, we'd have:
  #    ["msgid", ["", "This is a message"]]
  # for the "msgid" part, and
  #    ["msgstr", ["", "This is that message's translation"]]
  # for the "msgstr" part. Now we can have multiple "msgid" and "msgstr" parts, so really the
  # "msgid" and "msgstr" pieces of the po entry are an array of:
  #    [entry_name, value]
  # each. Thus, our above po entry is captured by the array:
  #    [
  #      [["msgid", ["", "This is a message"]]],
  #      [["msgstr", ["", "This is that message's translation"]]]
  #    ]
  #
  # A PO file is then an array of po entries. Now note that we don't even need the "msgid"
  # and "msgstr" pieces, because in every PO file, the entries will either be something like:
  #    "msgid"
  #    "msgstr"
  # or
  #    "msgid"
  #    "msgid_plural"
  #    "msgstr[0]"
  #    "msgstr[1]"
  #    ...
  #    "msgstr[n]"
  #
  # i.e. we can figure out the "msgid" or "msgstr" pieces given the number of values for a
  # single piece. For example for a "msgid" part, we can have an array of AT MOST 2 values
  # (because nothing more comes after "msgid_plural"), while for a "msgstr" part, if we have
  # MORE than 1 value, then we must have "msgstr[0]", "msgstr[1]", etc.; otherwise, we have just
  # "msgstr". So, we can really represent a PO entry as:
  #   [[msgid_values], [msgstr_values]]
  # where msgid_values or msgstr_values are an array of values, and a single value is an array
  # of strings. Consider this when understanding how the test cases below are made.

  # Implementation details to generate the right test parameters for the POParser
  ESCP_CH = /[\"\\\a\b\r\n\s\t]/
  ESCP_SUB = {
    "\a" => "a",
    "\b" => "b",
    "\r" => "r",
    "\n" => "n",
    "\s" => "s",
    "\t" => "t"
  }

  # Takes a single part's value as described above and stringifies it as it would
  # appear in a PO file.
  def self.stringify_value(value)
    escaped_value = value.map do |s|
      s.gsub(ESCP_CH) { |m| "\\#{(sub = ESCP_SUB[m[0]]) ? sub : m[0]}" }
    end
    escaped_value.map { |s| "\"" + s + "\"" }.join("\n")  
  end

  # Takes a part's name (e.g. "msgid") and its value, and stringifies it as it
  # would appear in a PO file.
  def self.stringify_part(part, value)
    part + " " + stringify_value(value)
  end

  # This routine takes in two parameters:
  #   (1) A generation function to generate each piece of the overall po part's name.
  #   This would be the "msgid" entry names if it's a "msgid" part, or the "msgstr" names
  #   if it is a "msgstr" part.
  #
  #   (2) The values for each part.
  #
  # It returns two pieces of information:
  #   [parsed_parts, stringified_parts]
  #
  # where parsed_parts represents a map of <part-name> -> <part-value>, something like what
  # the POParser would return (excluding the ParameterizedString technicality), while
  # stringified_parts represent those parts displayed together as a single piece of a PO
  # entry (e.g. all of the "msgid" parts put together, or all of the "msgstr" parts.)
  def self.create_part(generate_part_name, values)
    values.inject([{}, ""]) do |accum, value|
      parsed_parts, stringified_parts = accum
      part_name = generate_part_name.call
      stringified_part = stringify_part(part_name, value)
      [parsed_parts.merge(part_name => value.join), stringified_parts + stringified_part + "\n"]
    end
  end

  # This method is similar to create_part above, but for a create_po_entry. Remember that
  # a po_entry consists of a bunch of msgid_values and msgstr_values. It returns:
  #   [parsed_entry, stringified_entry]
  # with similar meanings as described in create_part, except for a single PO entry (both
  # "msgid" and "msgstr" components).
  def self.create_entry(msgid_values, msgstr_values)
    FixtureUtils.reset
    FixtureUtils.set_is_array(true) if msgstr_values.length > 1
    parsed_msgid, stringified_msgid = create_part(FixtureUtils::MSGID_GEN, msgid_values)
    parsed_msgstr, stringified_msgstr = create_part(FixtureUtils::MSGSTR_GEN, msgstr_values) 
    [[parsed_msgid, parsed_msgstr], stringified_msgid + stringified_msgstr + "\n"]
  end

  # Similar to create_entry, except here we take an array of entries. Now, we return
  #   [parsed_entries, stringified_entries]
  # but note that since a PO file is an array of entries, the stringified_entries are
  # the PO file itself! Similarly, the parsed_entries are the parsed PO file!
  #
  # One thing -- recall that the POParser is supposed to return only the non-empty PO
  # entries. A PO entry is non-empty iff both its msgid and msgstr parts are nonempty.
  # A msgid or msgstr part is nonempty iff all of its values are nonempty.
  def self.create_file(entries)
    entries.inject([[], ""]) do |accum, entry|
      parsed_entries, stringified_entries = accum
      parsed_entry, stringified_entry = create_entry(entry[0], entry[1])

      # Only push the parsed_entry if it is non-empty, with the meaning of "non-empty"
      # defined above. Otherwise, ignore it.
      parsed_entries.push(parsed_entry) if parsed_entry.all? do |parsed_part|
        parsed_part.all? { |_, value| not value.empty? }
      end

      [parsed_entries, stringified_entries + "\n" + stringified_entry]
    end
  end
  
  # This is our test PO file. Here, we want to ensure that:
  #   (1) Only non-empty entries are extracted. A PO entry is non-empty iff both its
  #   msgid and msgstr parts are nonempty. A msgid or msgstr part is nonempty iff all
  #   of its values are nonempty.
  #   
  #   (2) The right parameter regex describing the parameters in the file is extracted.
  #   For this case, we want RUBY_PERCENT.
  #
  #   (3) Escaped characters are correctly extracted as-is. E.g. "\n" is extracted as
  #   \n, instead of \\n.
  #
  # TODO: Preferably separate this out to multiple PO files each testing one specific
  # piece of the "parse" method. That will make it easier to see why a particular test
  # might have failed.
  TEST_PO_FILE = [
    # entry
    [ # msgid
      [["This", "is a", "msgid value"]],
      # msgstr
      [["This", "is a", "msgstr value"]]],
    # entry
    [ # msgid
      [["Here", "is another", "msgid value"],
       ["And", "here is a pluralized", "msgid value"]],
      # msgstr
      [["This", "is another", "msgstr value", "but longer"],
       ["Same", "with this one, except", "it is for a pluralized", "msgstr"],
       ["And", "for the heck of it", "here is yet another one"]]],
    [ # msgid
      [["This %{param}", "is an", " %{identifier}"]],
      # msgstr
      [["%{param}", "is an", "%{identifier}"]]],
    # entry
    [ # msgid
      [["%{value}", "%{id}"],
       ["%{value}s"]],
      # msgstr
      [["{0}", "{1}"],
       ["{1}"]]],
    # entry
    [ # msgid
      [["This is a nonempty entry"]],
      # msgstr
      [["This is also a non-empty entry."]]],
    # entry
    [ # msgid
      [["This part is non-empty"],
       [""]],
      # msgstr
      [["This part is fine"],
       ["This part is also fine"]]],
    # entry
    [ # msgid
      [["This part is non-empty"],
       ["And also this part"]],
      # msgstr
      [[""],
       ["This part is fine"]]],
    # entry
    [ # msgid
      [["This is a nonempty entry"]],
      # msgstr
      [["This is also a non-empty entry."]]],
    # entry
    [ # msgid
      [["Lots of \a\b\r\n\s\t\"\\"]],
      # msgstr
      [["More \a\b\r\n\s\t\"\\"]]]
  ]

  EXPECTED_RESULTS, PO_FILE_CONTENTS = create_file(TEST_PO_FILE)
end
