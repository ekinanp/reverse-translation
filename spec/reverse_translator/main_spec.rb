require "spec_helper"

describe Main do
  describe ".run" do
    invalid_log_file = MainFixture::INVALID_LOG_FILE
    valid_log_file = MainFixture::VALID_LOG_FILE
    valid_log_file_trans = MainFixture::VALID_LOG_FILE_TRANS

    context "given no command line arguments" do
      # TODO: Write test that ensures the tool reads from STDIN and writes to STDOUT, i.e.
      # pass it an empty ARGV
#      it "should output an error message, the usage of the tool and return an exit code of 1" do
#        expect do
#          expect(Main.run([])).to eql(1) 
#        end.to output(MainFixture::EXPECTED_NO_ARG_MSG).to_stdout
#      end
    end

    context "given a non-existent log file" do
      it "should output an error message, and return an exit code of 1" do
        expect(File).to receive(:exists?).with(invalid_log_file).once.and_return(false)
        expect do
          expect(Main.run([invalid_log_file])).to eql(1) 
        end.to output(MainFixture::EXPECTED_NON_EXISTENT_FILE_MSG).to_stdout
      end
    end

    context "given an invalid log file" do
      it "should output an error message, and return an exit code of 1" do
        expect(File).to receive(:exists?).with(invalid_log_file).once.and_return(true)
        expect do
          expect(Main.run([invalid_log_file])).to eql(1) 
        end.to output(MainFixture::EXPECTED_INVALID_FILE_MSG).to_stdout
      end
    end

    context "given a valid log file" do
      it "should translate it, tell the user where the translated file was written, and return an exit code of 0" do
        expect(File).to receive(:exists?).with(valid_log_file).once.and_return(true)

        @mock_translator = double()
        expect(@mock_translator).to receive(:reverse_translate).with(valid_log_file, valid_log_file_trans).once
        expect(ReverseTranslator).to receive(:new).with(Main::PO_FILES).once.and_return(@mock_translator)
        expect do
          expect(Main.run([valid_log_file])).to eql(0) 
        end.to output(MainFixture::EXPECTED_VALID_FILE_MSG).to_stdout
      end
    end
  end
end
