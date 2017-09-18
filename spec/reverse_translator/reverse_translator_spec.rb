require "spec_helper"

describe ReverseTranslator do
  before do
    mock_po_file = "foo"

    @mock_table = double()
    allow(POTable).to receive(:new).with([mock_po_file]).and_return(@mock_table) 
    @translator = ReverseTranslator.new([[mock_po_file]])
  end

  describe "#reverse_translate" do
    it "translates all log messages in the input stream, writing their translations to the provided output stream" do
      # mock the log messages
      mock_log_msgs = (1..10).map do |i|
        mock_log_msg = double()
        allow(mock_log_msg).to receive(:value).and_return(i)
        mock_log_msg
      end

      # mock the input and output streams
      mock_input_file = double()
      allow(LogParser).to receive(:parse).with(mock_input_file).and_return(mock_log_msgs)
      translated_msgs = []
      mock_output_file = double()
      allow(mock_output_file).to receive(:puts) { |translated_msg| translated_msgs << translated_msg.value }

      # mock the table's reverse_translate method
      mock_depth = 5 
      allow(@mock_table).to receive(:reverse_translate).with(any_args, mock_depth) do |log_msg|
        old_val = log_msg.value
        allow(log_msg).to receive(:value).and_return(old_val.succ) 
      end

      # run the test
      @translator.reverse_translate(mock_input_file, mock_output_file, mock_depth)
      expect(translated_msgs).to eql((2..11).to_a)
    end
  end
end
