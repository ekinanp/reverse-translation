module MainFixture 
  INVALID_LOG_FILE = "invalid_log_file"
  VALID_LOG_FILE = "valid_log_file.log"

  EXPECTED_NO_ARG_MSG = Main::NO_ARG_MSG + "\n"
  EXPECTED_NON_EXISTENT_FILE_MSG = "ERROR: #{INVALID_LOG_FILE} does not exist!\n"
  EXPECTED_INVALID_FILE_MSG = "ERROR: #{INVALID_LOG_FILE} is not a valid log file! "\
  "Log files must have the \".log\" extension.\n"
  EXPECTED_VALID_FILE_MSG = "#{VALID_LOG_FILE} was successfully translated, with the result "\
    "written to #{VALID_LOG_FILE+".trans"}!\n"
end
