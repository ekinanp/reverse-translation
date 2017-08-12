MSG_ONE = "2017-07-25 This is a simple log message"
MSG_TWO = "2017-09-10 This is a more complicated log message, written on"\
  "the date of 2016-03-12"
MSG_THREE = "2017-11-12 This is an even more complicated log message (2015-02-13)\n"\
  "because it has new line characters and dates (2014-12-31). Note that newlines\n"\
  "are typically caused by really long exception messages"

EXPECTED_MSGS = [MSG_ONE, MSG_TWO, MSG_THREE]
