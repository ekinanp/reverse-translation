require "spec_helper"

describe POEntry do
  context "initialized with a simple po entry (just msgid and msgstr)" do
    before do
      @entry = POEntry.new(POEntryFixture::SIMPLE_PO_ENTRY)
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
      @entry = POEntry.new(POEntryFixture::PLURAL_PO_ENTRY)
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
