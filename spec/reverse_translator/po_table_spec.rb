require "spec_helper"

describe POTable do
  describe "#reverse_translate" do
    it "should translate the given message starting with the longest translations" do
      allow(POParser).to receive(:parse).with(POTableFixture::MOCK_PO_FILE).once.and_return(POTableFixture::MOCK_PO_PARSER_DATA)
      @data_entry_map = POTableFixture::MOCK_PO_PARSER_DATA.map { |d| [d, double()] }.to_h
      @data_entry_map.each do |d, e| 
        expect(e).to receive(:reverse_translate).once { |msg| msg + (POTableFixture::TRANSLATIONS[d]) } 
      end
      allow(POEntry).to receive(:new).exactly(@data_entry_map.size).times { |d| @data_entry_map[d] }
      @table = POTable.new (POTableFixture::MOCK_PO_FILE)

      expect(@table.reverse_translate("")).to eql("CBA")
    end
  end
end
