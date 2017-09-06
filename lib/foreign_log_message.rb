require_relative 'math'

# This class encapsulates foreign log messages. A foreign log message consists
# of three parameters:
#   (1) The prefix (e.g. a timestamp)
#   (2) The message itself
#   (3) The maximum untranslated length
# 
# (3) will be useful for performance reasons. The idea is that when a log message
# is translated, there will always be a "pre" and a "post" component representing
# the parts before and after the message, respectively. A key assumption that is
# made in the tool is that once some part of a message is translated, that part
# is never touched again. This means that the "pre" and "post" components are
# mutually exclusive. See the comments in lib/po_table.rb for more details.
class ForeignLogMessage
  attr_reader :max_untranslated_length

  def initialize(prefix, message)
    @prefix = prefix
    @message = message
    @max_untranslated_length = message.length
  end

  # This method returns true if the foreign log message has been translated,
  # false otherwise. Note that a foreign log message is translated iff the
  # maximum untranslated length is 0 (i.e. there are no characters left to
  # translate).
  def translated?
    @max_untranslated_length.zero?
  end

  # Converts the foreign log message back to a string.
  def to_s
    @prefix + @message
  end

  # This method takes in a POEntry and attempts to use its information to translate
  # the foreign log message. It returns true if some part of the message was translated
  # successfully, false otherwise.
  def translate_with(po_entry)
    result = po_entry.reverse_translate(@message)
    return false unless result
    @message, @max_untranslated_length = result
    true
  end
end
