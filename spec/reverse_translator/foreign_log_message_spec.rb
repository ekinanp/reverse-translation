require "spec_helper"

describe ForeignLogMessage do
  describe "#translated?" do
    it "returns true when the max_untranslated_length is zero, i.e. when there are no more characters left to translate" do
      log_message = ForeignLogMessage.new("prefix", "")
      expect(log_message.translated?).to be_truthy
    end
    it "returns false when the max_untranslated_length is non-zero, i.e. when there are some characters left to translate" do
      log_message = ForeignLogMessage.new("prefix", "message")
      expect(log_message.translated?).to be_falsey
    end
  end
  describe "#to_s" do
    it "concatenates the 'prefix' and 'message' pieces together to produce the overall log message as it would appear in a log file" do
      log_message = ForeignLogMessage.new("prefix", "message")
      expect(log_message.to_s).to eql("prefixmessage")
    end
  end
  describe "#translate_with" do
    before(:each) do
      @log_message = ForeignLogMessage.new("prefix", "message")
    end
    it "returns false and does not modify anything in the foreign log message when the passed-in po_entry cannot translate the message" do
      mock_po_entry = double()
      allow(mock_po_entry).to receive(:reverse_translate).and_return(nil)

      old_msg = @log_message.to_s
      expect(@log_message.translate_with(mock_po_entry)).to be_falsey

      # check that no modifications have been made to the foreign log message
      expect(@log_message.to_s).to eql(old_msg)
      expect(@log_message.translated?).to be_falsey
    end
    it "returns true and updates the foreign log message and its max_untranslated_length when the passed-in po_entry can translate the message" do
      mock_po_entry = double()
      allow(mock_po_entry).to receive(:reverse_translate).and_return(["new_message", 0])

      expect(@log_message.translate_with(mock_po_entry)).to be_truthy

      # check that the right modifications have been made
      expect(@log_message.to_s).to eql("prefixnew_message")
      expect(@log_message.translated?).to be_truthy
    end
  end
end
