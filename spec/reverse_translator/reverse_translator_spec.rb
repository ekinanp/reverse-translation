require "spec_helper"

describe ReverseTranslator do
  before do
    @data_table_map = ReverseTranslatorFixture::MOCK_PO_FILES.map { |d| [d, double()] }.to_h
    @data_table_map.each do |d, t| 
      allow(t).to receive(:reverse_translate) { |msg| msg + (ReverseTranslatorFixture::TRANSLATIONS[d]) } 
    end
    allow(POTable).to receive(:new) { |d| @data_table_map[d] }

    allow(LogParser).to receive(:parse).with(ReverseTranslatorFixture::MOCK_LOG_FILE).and_return(ReverseTranslatorFixture::MOCK_LOG_MSGS_MAP.keys)

    @out_file = double()
    @translated_log = ""
    allow(@out_file).to receive(:puts) { |msg| @translated_log = @translated_log + msg + "\n" }
    allow(File).to receive(:open).with(ReverseTranslatorFixture::MOCK_LOG_FILE+".trans", "w").and_return(@out_file)
    @file_closed = false
    allow(@out_file).to receive(:close).with(no_args) { @file_closed = true }

    @reverse_translator = ReverseTranslator.new (ReverseTranslatorFixture::MOCK_PO_FILES)
  end

  describe "#reverse_translate" do
    it "should translate the given log file (denoted by <path>), with the translated log file's path being <path>.trans" do
      @reverse_translator.reverse_translate(ReverseTranslatorFixture::MOCK_LOG_FILE)
      expect(@translated_log).to eql(ReverseTranslatorFixture::EXPECTED_TRANSLATED_LOG)
      expect(@file_closed).to be true
    end
  end
end
