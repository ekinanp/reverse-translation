require 'spec_helper'

describe "Reverse translation tool CLI" do
  cmd = "bin/reverse_translate"

  context "when the user does not pass in any command line arguments" do
    it "should output an error message, the usage of the tool and return an exit code of 1" do
        expect(`#{cmd}`).to eql(MainFixture::EXPECTED_NO_ARG_MSG)
        expect($?.exitstatus).to eql(1)
    end
  end

  context "when the user passes in a non-existent log file" do
    it "should output an error message, and return an exit code of 1" do
      non_existent_file = "!@#!#!#!"
      expect(`#{cmd} #{non_existent_file}`).to eql(FixtureUtils.non_existent_file_msg(non_existent_file))
      expect($?.exitstatus).to eql(1)
    end
  end
 
  context "when the user passes in an invalid log file" do
    it "should output an error message, and return an exit code of 1" do
      tmp_file = Tempfile.new("reverse_translator_invalid_log_file")
      tmp_file.flush
 
      expect(`#{cmd} #{tmp_file.path}`).to eql(FixtureUtils.invalid_file_msg(tmp_file.path))
      expect($?.exitstatus).to eql(1)
 
      tmp_file.close
      tmp_file.unlink
    end
  end

  context "when the user passes in a valid log file" do
    it "should translate it, tell the user where the translated file was written, and return an exit code of 0" do
      log_generator = LogGenerator.new("lib/pe-rbac-service-ja.po")
      expected_translation, log_file = log_generator.generate(FixtureUtils.unique_path("reverse_translator_valid_log_file"), 10000)
      actual_translation = log_file + ".trans"

      expect(`#{cmd} #{log_file}`).to eql(FixtureUtils.valid_file_msg(log_file))
      expect($?.exitstatus).to eql(0)

      # TODO: Compare files line by line here, if possible. Probably not going to happen, unfortunately b/c of 
      # pluralization. Maybe I could see if there's a way to get an estimate?

      File.delete(log_file, expected_translation, actual_translation)
    end
  end
end
