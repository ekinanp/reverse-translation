# TODO: Change these to require eventually!
require_relative 'POParser'
require_relative 'POEntry'

# This class represents the reverse-lookup table for a single POT file.
# It is an array of POEntries. It will have one method, reverse_translate,
# that takes in a message and tries to translate it using its entries.
# 
# TODO: Have it also account for the pluralization formula later on, making
# sure that msgstr[0] is what corresponds to msgid.
class POTable
  # TODO: Remove this after testing!
  attr_reader :entries 

  def initialize(pot_file)
    @entries = POParser::parse(pot_file).sort! do |e1, e2|
      - (e1[0]["msgid"].length <=> e2[0]["msgid"].length)
    end.map { |e| POEntry.new(e) }
  end

  def reverse_translate(msg)
    entries.inject(msg) { |new_msg, entry| entry.reverse_translate(new_msg) }
  end
end
