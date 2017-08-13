module POEntryFixture
  BASIC_PARAM = "file1.ext"
  QUOTED_PARAM = "\"{0} {1} This is a random quoted string "\
    "with weird \a\b\r\n\s\t characters and regex .\\()[]{}+|^$*? "\
    "characters, to test the escape case\""
  MULTI_LINE_PARAM = "This is a multi-line param\n"\
    "that is used to represent exception generated\n"\
    "messages, because these can also happen"

  UNTRANSLATED_MSG = "This message is not meant to be translated."
  MSGID_TEMPLATE = "{0} is \\{1} OK because this is a simple case of {1} with regular parameters: {2}"
  MSGSTR_TEMPLATE = "{0} is \a\b\r\n\s\t .\\()[]{}+|^$*? more complicated because \\{1} we need to "\
       "ensure that the escaped regex characters are also matched {1} so that things work {2}" 

  INPUT_MSG_TEMPLATE = "#{BASIC_PARAM} is \a\b\r\n\s\t .\\()[]{}+|^$*? more complicated because \\{1} we need to "\
       "ensure that the escaped regex characters are also matched #{QUOTED_PARAM} so that things work #{MULTI_LINE_PARAM}" 

  EXPECTED_RESULT_TEMPLATE = "#{BASIC_PARAM} is \\{1} OK because this is a simple case of "\
    "#{QUOTED_PARAM} with regular parameters: #{MULTI_LINE_PARAM}"

  def self.pluralize(template, num_times)
    template.sub(/(\\\{\d\})/, "\\1#{"s"*num_times}")
  end

  # This method returns an array [constructor_part, expected_part]. 
  # "constructor_part" represents the portion of POParser's result that is 
  # passed to POEntry, while "expected_part" represents the portion of
  # this entry in the "expected" results returned by "make_happy_test_case". 
  def self.make_entry_test_case(generate_entry_name, msg_template, expected_template, num_entries)
    constructor_part = num_entries.times.collect { |i| [generate_entry_name.call, pluralize(msg_template, i)] }.to_h
    expected_part = num_entries.times.collect { |i| pluralize(expected_template, i) }
    [constructor_part, expected_part]
  end

  # This method creates a test case for the POEntry spec tests given the
  # number of msgstr entries. It returns an array of two maps: [constructor, expected].
  # The "constructor" map represents the input that should be passed into
  # POEntry, while "expected" is a map of input messages to their expected
  # translations after calling that entry's reverse_translate method.
  def self.make_happy_test_case(num_msgstr)
    is_plural = num_msgstr > 1
    FixtureUtils.reset
    FixtureUtils.set_is_array(true) if is_plural

    # Generate the "constructor" part
    msgid_part, expected_results = \
      make_entry_test_case(FixtureUtils::MSGID_GEN, MSGID_TEMPLATE, EXPECTED_RESULT_TEMPLATE, is_plural ? 2 : 1)
    msgstr_part, inputs = \
      make_entry_test_case(FixtureUtils::MSGSTR_GEN, MSGSTR_TEMPLATE, INPUT_MSG_TEMPLATE, num_msgstr)

    # Now generate the "expected" part
    expected_plural = (num_msgstr-1).times.collect { |i| [inputs[1+i], expected_results[1]] }.to_h

    [[msgid_part, msgstr_part], {inputs[0] => expected_results[0]}.merge(expected_plural)]
  end

  SIMPLE_TEST_CASE = make_happy_test_case(1)
  SIMPLE_PO_ENTRY = SIMPLE_TEST_CASE[0]
  SIMPLE_INPUT_MSG = SIMPLE_TEST_CASE[1].keys[0]
  SIMPLE_EXPECTED_RESULT = SIMPLE_TEST_CASE[1].values[0] 

  PLURAL_TEST_CASE = make_happy_test_case(3)
  PLURAL_PO_ENTRY = PLURAL_TEST_CASE[0]
  PLURAL_INPUT_EXPECTED = PLURAL_TEST_CASE[1]
end
