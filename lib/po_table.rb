require_relative 'po_parser'
require_relative 'po_entry'
require_relative 'po_param'

# This class represents the reverse-lookup table for an array of PO files.
# It is intended that an array of PO files will correspond to logs obtained
# from services implemented in a specific language (e.g. Clojure). Or they
# can correspond to all the PO files.
class POTable
  def initialize(pot_files)
    # First, inject the param_re as a part of every parsed entry returned from
    # the parser, since we'll be sorting them starting from longest to shortest.
    parsed_entries = pot_files.map { |f| POParser::parse(f) }.map do |parsed_entry|
      param_re, entries = parsed_entry 
      entries.map { |e| [param_re, e] }
    end.reduce(:concat)
    # Now, sort the entries by longest match    
    parsed_entries.sort! do |pe1, pe2|
      pre1, e1 = pe1
      pre2, e2 = pe2
      msgstr_avg_cmp = average_length(e2[1], pre2) <=> average_length(e1[1], pre1)
      next msgstr_avg_cmp unless msgstr_avg_cmp == 0
      average_length(e2[0], pre2) <=> average_length(e1[0], pre1)
    end
    # TODO: Test this addition of the code!
    @entries = parsed_entries.inject([]) do |accum, (param_re, po_entry)|
      next accum if po_entry[1].any? { |_, msg| POParam.adjacent_params?(msg, param_re) }
      accum.push(POEntry.new(param_re, po_entry))
    end
  end

  def reverse_translate(msg)
    @entries.inject(msg) { |new_msg, entry| entry.reverse_translate(new_msg) }
  end

  # This will return the average length of each entry. Note that a parameter regex is
  # necessary so that we don't count the parameter names themselves as part of the overall 
  # string's length.
  def average_length(entry, param_re)
    entry.values.inject(0.0) { |sum, e| sum + POParam.substitute_const(e, param_re, "").length } / entry.size
  end

  private :average_length
end
