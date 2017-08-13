module ReverseTranslatorFixture
  # Mock PO file paths. Expected order of the translations should be
  # 123
  MOCK_PO_FILES = ["mock_file1.po", "mock_file2.po", "mock_file3.po"]
  TRANSLATIONS = MOCK_PO_FILES.inject([{}, "1"]) do |accum, po_file|
    map, ch = accum
    [map.merge(po_file => ch), ch.succ]
  end.first

  # Mock log file path
  MOCK_LOG_FILE = "foo.log" 

  # A map of the mocked log messages to their expected results after
  # translation
  MOCK_LOG_MSGS_MAP = {
    "message1" => "message1123", 
    "message2" => "message2123",
    "message3" => "message3123"
  }
  EXPECTED_TRANSLATED_LOG = MOCK_LOG_MSGS_MAP.values.join("\n") + "\n"
end
