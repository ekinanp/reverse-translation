# This module contains regexes for all possible parameters that can be found
# in PO files. Currently, there are the following cases:
#   (1) {\d+}
#   (2) %{<identifier>}
#   (3) {{<identifier>}}
#   (4) printf placeholder (for Postgres)
# where <identifier> = [_(Alpha)]\w*. There are also ways of escaping these
# parameters, however for simplicity I will only consider this case for #4,
# printf, since percent signs are more common in a raw string than something
# like {0}.
#
# TODO: Create test classes to test out some of the regexes in this class.
module POParam
  STANDARD = /\{(\d+)\}/
  RUBY_PERCENT = /%\{([\p{Alpha}_]\w*)\}/
  HANDLEBAR = /\{\{([\p{Alpha}_]\w*)\}\}/

  # According to the docs, the syntax for a printf format placeholder is:
  #    %[parameter][flags][width][.precision][length]type 
  # For our purposes, we only care about the parameter, as that gives us
  # the argument index.
  #
  # TODO: The width and precision parameters can be dynamic, i.e. they can
  # take another parameter. Consider these cases later, I won't for now b/c
  # they're probably not common and considering them now would add a lot of
  # complexity in the main code.
  PARAMETER = /(?:(\d+)\$)?/
  FLAGS = /(?:-|\+| |0|#)?/
  WIDTH = /\d*/
  PRECISION = /(?:\.\d+)?/
  LENGTH = /(?:hh|ll|[hlLzjt])?/
  TYPE = /(?:[diufFeEgGxXoscpaAn])/
  PRINTF = Regexp.new(
    /(?:\A|([^%]))/.to_s\
    + /%/.to_s\
    + PARAMETER.to_s\
    + FLAGS.to_s\
    + WIDTH.to_s\
    + PRECISION.to_s\
    + LENGTH.to_s\
    + TYPE.to_s\
  )

  # Relevant, escaped regex characters for the PO parameter
  # regexes
  REGEXP_CH = /\\(?:\{|\}|\$|\+)/

  # The regexes for all possible parameters in the strings of
  # a PO file.
  PO_PARAMS = [STANDARD, RUBY_PERCENT, HANDLEBAR, PRINTF]

  # This method takes a param regex and converts it to another regex
  # that recognizes escaped characters. For example, STANDARD becomes
  #   /\\\{\d+\\\}/
  def self.to_param_sub_re(param_re)
    Regexp.new(param_re.to_s.gsub(REGEXP_CH) { |m| "\\\\#{m}" })
  end

  # This method takes in a message, a param regex describing the
  # parameters in that message (if any), and a hash-map mapping
  # the names of those parameters to their specific values.
  # It substitutes the values of those parameters into the message.
  #
  # Note that like in extract_params, printf will need to be handled
  # separately.
  def self.substitute_params(msg, param_re, param_vals)
    # If message does not have any parameters, no further work needs to be done.
    return msg if !param_re.match(msg)
    # If message does not have PRINTF-type parameters, we can just do a one-to-one
    # substitution
    return msg.gsub(param_re) { |m| param_vals[param_re.match(m)[1]] } if param_re != PRINTF
    # If message does have PRINTF-type parameters and these parameters are positional,
    # then we can still do one-to-one substitution but we need to also sub-back the previous
    # character
    return msg.gsub(param_re) do |m|
      match = param_re.match(m)
      match[1].to_s + param_vals[match[2]] 
    end if param_re.match(msg)[2]

    # We have non-positional PRINTF parameters. Then we sub iteratively over our param_vals
    # array, i.e. |param_vals| = # of PRINTF parameters. Note we still need to sub-back
    # the previous character.
    ix = 0
    msg.gsub(param_re) do |m|
      match = param_re.match(m)
      match[1].to_s + param_vals[(ix += 1).to_s]
    end
  end

  # This method takes in a po string and a parameter regex describing
  # the parameters inside that string, and extracts these parameters.
  # For example, if the string is "{0} {1} {2}" and the regex is STANDARD,
  # this would return [0, 1, 2].
  #
  # PRINTF is a special case. There are two cases to consider:
  #   (1) If a param has a positional argument (the PARAMETER field),
  #   then all other params will also have one as printf does not allow
  #   the mixing of PARAMETER and PARAMETER-less specifiers. The array
  #   will then consist of the values of the positional argument. For
  #   example for "%$2s %$1s %$2s", this method will return [2, 1, 2].
  #
  #   (2) Otherwise, none of the other params will have a positional
  #   argument, so the method will just return the numeric order
  #   that they appear. So for "%s %d %u %s", it will return
  #   [1, 2, 3, 4].
  def self.extract_params(msg, param_re)
    matches = msg.scan(param_re)
    return [] if matches.empty?
    # At this point, we do have one parameter.
    return matches.reduce(:concat) if param_re != PRINTF
    # If we do have a positional argument then just return the values as-is
    return matches.map { |m| m[1] } if matches.first[1]
    matches.each_index.map { |i| (i + 1).to_s }
  end
end
