require "spec_helper"

describe LogParser do
  before do
    @file = Tempfile.new("log_parser_test_file")
    @file.write(LogParserFixture::EXPECTED_MSGS.join("\n"))
    @file.flush
  end

  describe ".parse" do
    it "should parse a valid log file" do
      expect(LogParser.parse(@file.path)).to eql(LogParserFixture::EXPECTED_MSGS)
    end
  end

  after do
    @file.close
    @file.unlink
  end
end
