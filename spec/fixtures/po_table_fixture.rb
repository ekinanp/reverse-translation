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
  #
  # For example if we pass in [3, 3, 2, 2] into this
  # method, we get the following:
  #    [{0 -> "111", 1 -> "111", 2 -> "111"}, {0 -> "11", 1 -> "11"}]
  # as the return value
  def self.make_mock_po_parser_entry(msgid_avg, msgid_slices, msgstr_avg, msgstr_slices)
    [[msgid_avg, msgid_slices], [msgstr_avg, msgstr_slices]].map do |(avg, slices)|
      slices.times.collect { |i| [i, "1"*avg] }.to_h
    end
  end

  # This method returns "mocked" data for an entire PO
  # file. Here, an entry is an array
  # [msgid_avg, msgid_slices, msgstr_avg, msgstr_slices],
  # and a single PO file is an array of these entries.
  # The data are these entries converted to what the
  # parser returns, and then one entry for the param_re
  # captured by the file.
  def self.make_mock_po_parser_file(entries)
    data = entries.map { |entry| make_mock_po_parser_entry(*entry) }
    [POParam::PO_PARAMS.sample, data]
  end

  # There will be two PO files used for testing. File 1's entries will
  # be labeled ABC while File 2's entries will be labeled DEF. The expected
  # order of translation should be ADBECF, with entries B and E having a tie
  # in their msgstr lengths, so that B's msgid entries will win.
  
  # First file's data. Let MPF denote MOCK PO FILE to keep the variable names
  # short.
  MPF_ONE = "mock_file_one.po"
  MPF_ONE_PARSER_RESULTS = make_mock_po_parser_file([
    [2, 2, 50, 10], # A
    [4, 4, 30, 5],  # B
    [8, 2, 10, 2]   # C
  ])
  MPF_ONE_PARAM_RE, MPF_ONE_PARSER_DATA = MPF_ONE_PARSER_RESULTS
  DATA_A, DATA_B, DATA_C = MPF_ONE_PARSER_DATA

  # Second file's data.
  MPF_TWO = "mock_file_two.po"
  MPF_TWO_PARSER_RESULTS = make_mock_po_parser_file([
    [2, 2, 40, 10], # D
    [3, 4, 30, 5],  # E
    [6, 2, 4, 2]   # F
  ])
  MPF_TWO_PARAM_RE, MPF_TWO_PARSER_DATA = MPF_TWO_PARSER_RESULTS
  DATA_D, DATA_E, DATA_F = MPF_TWO_PARSER_DATA

  # Translations 
  TRANSLATIONS = {
    DATA_A => "A",
    DATA_B => "B",
    DATA_C => "C",
    DATA_D => "D",
    DATA_E => "E",
    DATA_F => "F"
  }

  MOCK_PO_FILES = [MPF_ONE, MPF_TWO] 
  MOCK_PO_PARSER_DATA = [DATA_A, DATA_B, DATA_C, DATA_D, DATA_E, DATA_F]
end
