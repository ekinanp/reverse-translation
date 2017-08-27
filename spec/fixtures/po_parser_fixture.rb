module POParserFixture
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

  # Takes an array of strings representing the values for a single po entry
  # (e.g. a "msgid" entry) and converts it to a quoted string, i.e. how it
  # would be written by xgettext when the POT file is created.
  def self.to_po_values(values)
    escp_values = values.map do |v|
      v.gsub(ESCP_CH) { |m| "\\#{(sub = ESCP_SUB[m[0]]) ? sub : m[0]}" }
    end
    escp_values.map { |v| "\"" + v + "\"" }.join("\n")  
  end

  # Takes an entry name (e.g. "msgid") and that entry's values, and returns
  # them in a way that's displayable in a PO file.
  def self.make_po_entry(entry, values)
    entry + " " + to_po_values(values)
  end

  # This takes in a set of values and an entry name generation function,
  # and returns an array of two parameters, [structure, entries]. "structure"
  # represents the expected map that POParser will get when parsing these entries,
  # while "entries" represent how these entries would look if they were written in
  # a POT file.
  def self.to_po_entries(generate_entry_name, entry_values)
    entry_values.inject([{}, ""]) do |accum, values|
      structure, entries = accum
      entry_name = generate_entry_name.call
      entry = make_po_entry(entry_name, values)
      [structure.merge(entry_name => values.join), entries + entry + "\n"]
    end
  end

  # This method takes in [MsgidValues, MsgStrValues] as input, where MsgidValues and
  # MsgStrValues are both arrays of arrays of strings. MsgidValues represents all the
  # values corresponding to the MsgId entry, while MsgStrValues is the same for the
  # MsgStr entry. This method returns [structure, set] with similar semantics as
  # above.
  def self.make_po_set(msgid_values, msgstr_values)
    FixtureUtils.reset
    FixtureUtils.set_is_array(true) if msgstr_values.length > 1
    msgid_structure, msgid_entries = to_po_entries(FixtureUtils::MSGID_GEN, msgid_values)
    msgstr_structure, msgstr_entries = to_po_entries(FixtureUtils::MSGSTR_GEN, msgstr_values) 
    [[msgid_structure, msgstr_structure], msgid_entries + msgstr_entries + "\n"]
  end

  # This method takes an array of [MsgidValues, MsgstrValues] as input and returns
  # [structure, file_contents] w/ similar semantics as above.
  def self.make_po_file_contents(po_values)
    po_values.inject([[], ""]) do |accum, set_values|
      structure, file_contents = accum
      set_structure, set_contents = make_po_set(set_values[0], set_values[1])
      [structure.push(set_structure), file_contents + "\n" + set_contents]
    end
  end

  # Relevant test data for the POParser. Note that we don't care about what language a message
  # is in, only that the right message contents are extracted and the right param_re describing
  # its parameters.
  MSG = ["\a\b\r\n\s\t\"\\", "Now that the escape characters are done", "Does this message work?", "What about with %{param1} and %{param2} and %{param3} parameters?"]
  TEST_INPUT = [[[MSG], [MSG]], [[MSG, MSG], [MSG, MSG, MSG]]]
  STRUCTURE, INPUT_STRING = make_po_file_contents(TEST_INPUT)
  EXPECTED_RESULT = [POParam::RUBY_PERCENT, STRUCTURE]
end
