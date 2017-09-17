module POEntryFixture
  # At an abstract level, a POEntry encapsulates a map of <Foreign Message> => <Translation>
  # relationships. When translating a message, here is the following pattern that's used:
  #   (1) Find the first foreign message that matches the passed-in message
  #   (2) Substitute its parameters into the translation
  #   (3) Output the translation
  #
  # Thus, for testing purposes, a "Foreign Message" is an object that matches against a given
  # set of strings and, for each match, returns a result object [pre, param_values, post].
  # If a string is not in the set of matched strings, then its "match" method will return
  # nil. We will change the lengths of "pre", "post", and each value in "param_values" so that
  # we can ensure that 'max_untranslated_length' is computed correctly.
  #
  # Furthermore, our POEntry also keeps track of the foreign message with the smallest length.
  # So each "Foreign Message" will keep track of a "length" parameter.
  #
  # Similarly a "Translation" is an object that encapsulates a "template" string into which
  # we can substitute parameters. So, it will mock a single method "substitute_values" that will
  # take a given "param_values" map, and simply concatenate each value after its "template" string
  # -- since the "templates" will be unique, we can figure out whether the correct translation was
  # used.
  #
  # See "setup_po_entry" in "po_entry_spec" to see how this works.
 

  # These are all of our "foreign" messages. Each foreign message consists of a map between
  # the set of matched strings and the result returned for each set.
  #
  # A matched string iFMj is interpreted as the ith matching string of jth foreign message.
  FOREIGN_MESSAGES = 
    [ # The first foreign message
      [{"1FM1" => ["pre"*10, {"1FM1" => "1FM1"}, "post"],
        "2FM1" => ["pre", {"2FM1" => "2FM1"}, "post"*10],
        "3FM1" => ["pre", {"3FM1" => "3FM1"*10}, "post"]}, 10],
      # The second foreign message
      [{"1FM2" => ["pre"*10, {"1FM2" => "1FM2"}, "post"],
        "2FM2" => ["pre", {"2FM2" => "2FM2"}, "post"*10],
        "3FM2" => ["pre", {"3FM2" => "3FM2"*10}, "post"]}, 8]]

  TRANSLATIONS = ["1", "2"]

  def self.create_part_map(generate_part_name, parts)
    parts.map do |part|
      [generate_part_name.call, part]
    end.to_h
  end

  def self.create_entry_map(msgid_parts, msgstr_parts)
    FixtureUtils.reset
    FixtureUtils.set_is_array(true) if msgstr_parts.size > 1
    msgid_map = create_part_map(FixtureUtils::MSGID_GEN, msgid_parts)
    msgstr_map = create_part_map(FixtureUtils::MSGSTR_GEN, msgstr_parts)
    [msgid_map, msgstr_map]
  end

  # This method returns the expected result when POEntry#reverse_translate is called on
  # the given input. Idea is to simulate the "matching" algorithm, extract the translation
  # using the provided translation_key, and then substitute the parameters in as outlined
  # above.
  def self.expected_result(po_entry, translation_key, input)
    po_entry[1].values.each do |(valid_matches, _)|
      match = valid_matches[input]
      next unless match
      pre, param_values, post = match
      translation = po_entry[0][translation_key]

      translated_msg = pre + translation + param_values.values.join + post
      max_untranslated_length = [pre.length, *(param_values.values.map { |s| s.length }), post.length].max
      return [translated_msg, max_untranslated_length]
    end
    nil
  end

  PO_ENTRY_NON_PLURAL = create_entry_map(TRANSLATIONS.first(1), FOREIGN_MESSAGES.first(1)) 
  PO_ENTRY_PLURAL = create_entry_map(TRANSLATIONS, FOREIGN_MESSAGES)

  NON_PLURAL_EXPECTED_MIN_LENGTH = 10
  PLURAL_EXPECTED_MIN_LENGTH = 8
end
