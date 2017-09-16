require "spec_helper"

describe POParser do
  describe ".parse" do
    it "should parse a valid po file" do
      EXPECTED_RESULTS, FILE_CONTENTS = POParserFixture.create_file(POParserFixture::TEST_PO_FILE)
      allow(IO).to receive(:read).once.with("foo").and_return(FILE_CONTENTS)
      allow(ParameterizedString).to receive(:new).with(instance_of(String), ParameterizedString::RUBY_PERCENT) do |param_str, _|
        param_str
      end

      expect(POParser.parse("foo")).to eql(EXPECTED_RESULTS)
    end
  end
end
