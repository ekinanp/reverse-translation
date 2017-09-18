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
      # have to mock again, because rpsec uses the old "max_untranslated_length" value
      allow(mock_flm).to receive(:translated?).and_return(mock_flm.max_untranslated_length.zero?)
      true
    end
    mock_flm
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
      allow(mock_po_entry).to receive(:min_length).and_return(entry_id)
      allow(mock_po_entry).to receive(:id).and_return(entry_id)

      allow(POEntry).to receive(:new).with([mock_msgid, mock_msgstr]).and_return(mock_po_entry)

      [mock_msgid, mock_msgstr]
      end

      allow(POParser).to receive(:parse).with(path).and_return(mock_parser_results)
    end

    @table = POTable.new(POTableFixture::PO_FILES_RAW.keys) 
  end

  describe "#reverse_translate" do
    it "iterates over each entry in the @entries array ordered by average length" do
      mock_flm = mock_foreign_log_message({}, 8)

      @table.reverse_translate(mock_flm, -1)
      expect(mock_flm.checked_entries).to eql([8, 7, 6, 5, 4, 2, 1])
      expect(mock_flm.translated?).to be_falsey
    end
    it "uses binary search to skip entries that do not need to be checked, where it only does the binary search at the initial step, or whenever an entry translates part of the message" do
      mock_flm = mock_foreign_log_message({7 => 5, 5 => 2}, 7)

      @table.reverse_translate(mock_flm, -1)
      expect(mock_flm.checked_entries).to eql([7, 5, 2, 1])
      expect(mock_flm.translated?).to be_falsey
    end
    it "translates up to a certain depth" do
      mock_flm = mock_foreign_log_message({8 => 5}, 8)

      @table.reverse_translate(mock_flm, 1)
      expect(mock_flm.checked_entries).to eql([8])
      expect(mock_flm.translated?).to be_falsey
    end
    it "stops iterating through the entries once the message has been fully translated" do
      mock_flm = mock_foreign_log_message({8 => 0}, 8)

      @table.reverse_translate(mock_flm, -1)
      expect(mock_flm.checked_entries).to eql([8])
      expect(mock_flm.translated?).to be(true)
    end
  end
end
