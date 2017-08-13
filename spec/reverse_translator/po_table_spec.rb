require "spec_helper"

describe POTable do
  before do
    allow(POParser).to receive(:parse).with(POTableFixture::MOCK_PO_FILE).and_return(POTableFixture::MOCK_PO_PARSER_DATA)
    @data_entry_map = POTableFixture::MOCK_PO_PARSER_DATA.map { |d| [d, double()] }.to_h
    @data_entry_map.each do |d, e| 
      allow(e).to receive(:reverse_translate) { |msg| msg + (POTableFixture::TRANSLATIONS[d]) } 
    end
    allow(POEntry).to receive(:new) { |d| @data_entry_map[d] }
    @table = POTable.new (POTableFixture::MOCK_PO_FILE)
  end

  describe "#reverse_translate" do
    it "should translate the given message starting with the longest translations" do
      expect(@table.reverse_translate("")).to eql("CBA")
    end
  end
end
