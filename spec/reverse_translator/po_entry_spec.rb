require "spec_helper"

describe POEntry do
  # This routine sets up the mocked objects representing a foreign message and a
  # translation by transforming the values of the "msgstr" and "msgid" parts of the
  # passed-in entry_map, respectively.
  def setup_po_entry(entry_map)
    # mock out the translation
    msgid_part = entry_map[0].map do |part, translation|
      mock_obj = double()
      allow(mock_obj).to receive(:substitute_values) do |param_values|
        translation + param_values.values.join
      end
      [part, mock_obj]
    end.to_h

    # mock out the foreign message
    msgstr_part = entry_map[1].map do |part, (matches, length)|
      mock_obj = double()
      allow(mock_obj).to receive(:match) { |msg| matches[msg] }
      allow(mock_obj).to receive(:length).and_return(length)

      [part, mock_obj]
    end.to_h

    POEntry.new([msgid_part, msgstr_part])
  end

  context "initialized with a simple po entry (just msgid and msgstr)" do
    po_entry_non_plural = POEntryFixture::PO_ENTRY_NON_PLURAL
    # Mock stuff out
    before do
      @entry = setup_po_entry(po_entry_non_plural)
    end
    describe "#min_length" do
      it "returns the length of the shortest foreign message (msgstr entry)" do
        expect(@entry.min_length).to eql(POEntryFixture::NON_PLURAL_EXPECTED_MIN_LENGTH)
      end
    end
    describe "#reverse_translate" do
      context "given a translatable message" do
        it "returns its translation and the maximum, remaining untranslated portion of the original message" do
          po_entry_non_plural[1].values.each do |(matches, _)|
            matches.keys.each do |input|
              expected = POEntryFixture.expected_result(po_entry_non_plural, "msgid", input)
              expect(@entry.reverse_translate(input)).to eql(expected)
            end
          end
        end
      end
      context "given an untranslatable message" do
        it "returns nil" do
          expect(@entry.reverse_translate("foo")).to be_nil
        end
      end
    end
  end

  context "initialized with a pluralized po entry" do
    po_entry_plural = POEntryFixture::PO_ENTRY_PLURAL
    # Mock stuff out
    before do
      @entry = setup_po_entry(po_entry_plural)
    end
    describe "#min_length" do
      it "returns the length of the shortest foreign message (msgstr entry)" do
        expect(@entry.min_length).to eql(POEntryFixture::PLURAL_EXPECTED_MIN_LENGTH)
      end
    end
    describe "#reverse_translate" do
      context "given a translatable message" do
        it "returns its translation and the maximum, remaining untranslated portion of the original message" do
          po_entry_plural[1].values.each do |(matches, _)|
            matches.keys.each do |input|
              expected = POEntryFixture.expected_result(po_entry_plural, "msgid_plural", input)
              expect(@entry.reverse_translate(input)).to eql(expected)
            end
          end
        end
      end
      context "given an untranslatable message" do
        it "returns nil" do
          expect(@entry.reverse_translate("foo")).to be_nil
        end
      end
    end
  end
end
