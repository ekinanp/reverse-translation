require "spec_helper"

describe POParser do
  before do
    @file = Tempfile.new("po_parser_test_file")
    @file.write(POParserFixture::INPUT_STRING)
    @file.flush
  end

  describe ".parse" do
    it "should parse a valid po file" do
      expect(POParser.parse(@file.path)).to eql(POParserFixture::EXPECTED_RESULT)
    end
  end

  after do
    @file.close
    @file.unlink
  end
end
