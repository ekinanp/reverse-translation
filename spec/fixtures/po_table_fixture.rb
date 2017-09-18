module POTableFixture
  # A POTable is an array of PO entries that are sorted by average length.
  # Before something becomes a PO entry however, it is a parsed result. A
  # parsed result is an array of <msgid> and <msgstr> parts. The <msgid>
  # portions represent the translations, while the <msgstr> parts represent
  # the foreign messages.
  #
  # We sort by average length. So the values of each <msgid> or <msgstr> piece
  # need to have an associated length to them. Furthermore, we do not consider
  # foreign messages with adjacent parameters as being part of the translation,
  # so the <msgstr> pieces will also have a boolean "true" or "false" indicating
  # whether or not they have adjacent parameters.
  #
  # Now, each PO entry encapsulates a unique <Foreign Message> => <Translation> type
  # relationship. Furthermore, we want to ensure that the "longest" entries are checked
  # first for matches (to avoid shorter entries translating small portions of a foreign
  # message, thus messing up the overall translation). Thus, we will assign each parsed
  # entry a numeric value that serves as its min_length value. Because we will be using
  # unique values for the min_length, this value will also serve to "summarize" that entrie's
  # <Foreign Message> => <Translation> type relationship.
  #
  # TODO: ^ The above comment is a bit vague. Clarify more.
  #
  # So for our purposes, a parsed result consists of the following:
  #   [[<msgid>, <msgstr>], <min_length>]
  # a <msgid> piece consists of:
  #   [<length>, <length>, ...]
  # while a <msgstr> piece consists of:
  #   [[<length>, <adjacent_params?>], [<length>, <adjacent_params?>], ...]
  #
  # Now a PO file, as far as the POTable class is concerned, is a map of <file-path> =>
  # <parsed-results>. 
 
  # With these files, if the sorting is correct and the adjacent parameter filtering works,
  # then the @entries field in the POTable class should be in the following order (indexed
  # by their min_lengths):
  #    8, 7, 6, 5, 4, 2, 1
  PO_FILES_RAW = {
    "file_one" => [
      [[[0], [[1, false], [1, false], [1, false]]], 1],
      [[[1, 1], [[2, false]]], 2],
      [[[2, 2, 2], [[2, true], [2, false]]], 3],
      [[[1], [[4, false], [4, false]]], 4]
    ],
    "file_two" => [
      [[[0], [[5, false], [5, false], [5, false]]], 5],
      [[[1, 1], [[6, false]]], 6],
      [[[2, 2, 2], [[6, false], [6, false]]], 7],
      [[[1], [[7, false], [7, false]]], 8]
    ]
  }

  # What will be passed into POTable's constructor. All this code does is transform
  # each <msgid> and <msgstr> component to a map, since that is what the constructor
  # expects.
  PO_FILES_PARSED = PO_FILES_RAW.map do |path, entries|
    to_map = ->(parsed_parts) do
      parsed_parts.each_with_index.map { |part, i| [i, part] }.to_h
    end
    transformed_entries = entries.map do |(parsed_parts, min_length)|
      [parsed_parts.map { |part| to_map.call(part) }, min_length]
    end
    [path, transformed_entries]
  end.to_h
end
