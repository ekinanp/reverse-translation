require "spec_helper"

describe POTable do
  # Now we mock out the foreign log message inputs that will be passed into
  # POTable#reverse_translate. Here's how this will work. Every foreign log
  # message has a set of entries that can translate a part of it. Each time
  # an entry translates a part of the message, the remaining, untranslated
  # length of that message shrinks to some specified value until it hits zero. 
  #
  # However, we also want to keep track of which entry we encountered in our
  # translation to ensure that the entries are ordered correctly, i.e., that
  # the longest lengthed entry is checked first. To do this, we will have the
  # mock object keep track of all the entries that it has checked.
  #
  # Thus, a foreign log message will maintain a map of <entry-id> =>
  # <new_untranslated_length> to simulate those entries that resulted in a "translation".
  # An entry is only a valid translation if it is a part of that map.
  def mock_foreign_log_message(translating_entries, initial_length)
    mock_flm = double()
    allow(mock_flm).to receive(:max_untranslated_length).and_return(initial_length)
    allow(mock_flm).to receive(:translated?).and_return(mock_flm.max_untranslated_length.zero?)
    allow(mock_flm).to receive(:checked_entries).and_return([])
    allow(mock_flm).to receive(:translate_with) do |entry|
      mock_flm.checked_entries << entry.id
      next false unless translating_entries[entry.id]
      allow(mock_flm).to receive(:max_untranslated_length).and_return(translating_entries[entry.id]) 
      true
    end
  end

  before do
    # setup the POParser and POEntry mocks based on the discussion
    # in the corresponding fixture
    POTableFixture::PO_FILES_PARSED.each do |path, entries|
      mock_parser_results = entries.map do |(parsed_entry, entry_id)|
        # mock msgid pieces
        mock_msgid = parsed_entry[0].map do |part, length|
        mock_part = double()
        allow(mock_part).to receive(:length).and_return(length)
        [part, mock_part]
      end.to_h

      # mock msgstr pieces
      mock_msgstr = parsed_entry[1].map do |part, (length, has_adjacent_params)|
        mock_part = double()
        allow(mock_part).to receive(:length).and_return(length)
        allow(mock_part).to receive(:adjacent_params?).and_return(has_adjacent_params)
        [part, mock_part]
      end.to_h

      mock_po_entry = double()
      allow(mock_po_entry).to receive(:id).and_return(entry_id)

      allow(POEntry).to receive(:new).with([mock_msgid, mock_msgstr]).and_return(mock_po_entry)

      [mock_msgid, mock_msgstr]
      end

      allow(POParser).to receive(:parse).with(path).and_return(mock_parser_results)
    end

    @table = POTable.new(POTableFixture::PO_FILES_RAW.keys) 
  end

  # There are four key operations going on in the code for this method:
  #   (A) Iterating over each entry in the @entries array
  #
  #   (B) Skipping to a later entry by using a binary search before looping, and whenever
  #   an entry successfully translates a message (to avoid processing entries that are longer
  #   than the message itself, and hence cannot ever hope to translate it)
  #
  #   (C) Checking after a successful translation whether or not the maximum depth has been
  #   reached and exiting out of the method if so
  #
  #   (D) Checking after a successful translation whether or not the entire message has
  #   successfully been translated, and exiting out of the method if so.
  #
  # Each test case is "summarized" by a four-digit binary numer xAxBxCxD where a 1 in xI indicates
  # that we're testing to see if Operation I occurred successfully for that test. Thus, there will
  # be 16 total test cases. We can do better by shrinking this number down to 8, as note that the
  # exit condition for xC and xD is the same line of code, so there's no need to test these
  # together.
  describe "#reverse_translate" do
  end
end
