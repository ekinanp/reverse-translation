module MainFixture 
  INVALID_LOG_FILE = "invalid_log_file"
  VALID_LOG_FILE = "valid_log_file.log"
  VALID_LOG_FILE_TRANS = VALID_LOG_FILE + ".trans"

  EXPECTED_NON_EXISTENT_FILE_MSG = FixtureUtils.non_existent_file_msg(INVALID_LOG_FILE)
  EXPECTED_INVALID_FILE_MSG = FixtureUtils.invalid_file_msg(INVALID_LOG_FILE)
  EXPECTED_VALID_FILE_MSG = FixtureUtils.valid_file_msg(VALID_LOG_FILE)
end
