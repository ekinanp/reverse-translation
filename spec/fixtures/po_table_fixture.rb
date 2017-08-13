module POTableFixture
  # This method returns "mocked" data for a single entry
  # that would be parsed by POParser and passed onto
  # POEntry's constructor. It takes as parameters
  # the average value of the length of each of the
  # "msgstr" entries, as well as the # of "slices"
  # of these entries. Note we do not need to worry about
  # "msgid" or "msgstr" keys, as POTable's code does
  # not care about them. NOTE: This method assumes
  # that avg is evenly divisible by slices.
  def self.make_mock_po_parser_data(avg, slices)
    [{}, slices.times.collect { |i| [i, "1"*avg] }.to_h]
  end

  # Mock file path
  MOCK_PO_FILE = "mock_file.po"

  # Expected order should be CBA.
  DATA_A = make_mock_po_parser_data(6, 2)
  DATA_B = make_mock_po_parser_data(10, 5)
  DATA_C = make_mock_po_parser_data(50, 10)

  TRANSLATIONS = { DATA_A => "A", DATA_B => "B", DATA_C => "C" }
  MOCK_PO_PARSER_DATA = [DATA_A, DATA_B, DATA_C]
end
