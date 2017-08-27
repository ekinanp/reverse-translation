require "spec_helper"

# TODO: Mock out parts of the code that belong to POParam. This is not that
# important and not worth the effort, but still good to do if time permits.
describe POEntry do
  context "initialized with a simple po entry (just msgid and msgstr)" do
    before do
      @entry = POEntry.new(POEntryFixture::PARAM_RE, POEntryFixture::SIMPLE_PO_ENTRY)
    end
    describe "#reverse_translate" do
      context "given a translatable message" do
        it "translates it, leaving any parameters in the original message unchanged" do
          expect(@entry.reverse_translate(POEntryFixture::SIMPLE_INPUT_MSG)).to eql(POEntryFixture::SIMPLE_EXPECTED_RESULT)
        end
      end
      context "given an untranslatable message" do
        it "does not translate it, leaving it unmodified" do
          expect(@entry.reverse_translate(POEntryFixture::UNTRANSLATED_MSG)).to eql(POEntryFixture::UNTRANSLATED_MSG)
        end
      end
    end
  end

  context "initialized with a pluralized po entry" do
    before do
      @entry = POEntry.new(POEntryFixture::PARAM_RE, POEntryFixture::PLURAL_PO_ENTRY)
    end
    describe "#reverse_translate" do
      context "given a translatable message" do
        it "translates it, leaving any parameters in the original message unchanged" do
          POEntryFixture::PLURAL_INPUT_EXPECTED.each { |input, expected| expect(@entry.reverse_translate(input)).to eql(expected) }
        end
      end
      context "given an untranslatable message" do
        it "does not translate it, leaving it unmodified" do
          expect(@entry.reverse_translate(POEntryFixture::UNTRANSLATED_MSG)).to eql(POEntryFixture::UNTRANSLATED_MSG)
        end
      end
    end
  end
end
