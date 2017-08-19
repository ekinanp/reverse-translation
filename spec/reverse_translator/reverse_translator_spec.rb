require "spec_helper"

describe ReverseTranslator do
  describe "#reverse_translate" do
    @mock_log_file = ReverseTranslatorFixture::MOCK_LOG_FILE
    @mock_log_file_trans = ReverseTranslatorFixture::MOCK_LOG_FILE_TRANS
    it "should translate the given log file (denoted by <path>), with the translated log file's path being <path>.trans" do
      num_log_msgs = ReverseTranslatorFixture::MOCK_LOG_MSGS_MAP.size
      num_po_files = ReverseTranslatorFixture::MOCK_PO_FILES.size
  
      @data_table_map = ReverseTranslatorFixture::MOCK_PO_FILES.map { |d| [d, double()] }.to_h
      @data_table_map.each do |d, t| 
        expect(t).to receive(:reverse_translate).exactly(num_log_msgs).times { |msg| msg + (ReverseTranslatorFixture::TRANSLATIONS[d]) } 
      end
      allow(POTable).to receive(:new).exactly(num_po_files).times { |d| @data_table_map[d] }
  
      expect(LogParser).to receive(:parse).with(@mock_log_file).once.and_return(ReverseTranslatorFixture::MOCK_LOG_MSGS_MAP.keys)
  
      @out_file = double()
      @translated_log = ""
      expect(@out_file).to receive(:puts).exactly(num_log_msgs).times { |msg| @translated_log = @translated_log + msg + "\n" }
      expect(File).to receive(:open).with(@mock_log_file_trans, "w").once.and_return(@out_file)
      expect(@out_file).to receive(:close).with(no_args).once 
  
      @reverse_translator = ReverseTranslator.new (ReverseTranslatorFixture::MOCK_PO_FILES)
      @reverse_translator.reverse_translate(@mock_log_file, @mock_log_file_trans)
      expect(@translated_log).to eql(ReverseTranslatorFixture::EXPECTED_TRANSLATED_LOG)
    end
  end
end
