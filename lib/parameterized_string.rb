# This class represents parameterized strings, such as those used in printf. The
# idea is that the string has certain parameter specifiers (described by a
# regex), where each parameter identifies a unique value that can be substituted
# in its place. Both foreign and English messages in PO files are parameterized strings,
# and currently there are four possible kinds of parameter specifiers:
#   (1) {\d+}
#   (2) %{<identifier>}
#   (3) {{<identifier>}}
#   (4) printf placeholder
# where <identifier> is a variable name, such as those found in Java, C, C++,
# etc. As an example, let msg = "There are {0} people that have {1} hair." Here,
# the param. specifiers are of the form described in (1). We can substitute
# "5" for {0}, and "brown" for {1} to get the message:
#   "There are 5 people that have brown hair."
# Each param. specifier is uniquely identified as follows (case by case):
#   (1) For these specifiers, the argument # (e.g. 0, 1, 2) uniquely identifies
#   the specifier
#
#   (2) and (3) These are uniquely classified by their identifier.
#
#   (4) There are two possibilities here:
#         (a) If the parameterized string has positional arguments, e.g. a string such
#         as:
#            "This is an example of %1$s message with %2$s and %1$d positional
#            parameters for %3$f."
#         Then each parameter is uniquely identified by the number before
#         the "$". So our parameters would be ["1", "2", "1", "3"] in order of appearance.
#
#         (b) If the parameterized string does not have positional arguments (standard
#         printf string), then each parameter is identified by their position (indexed by 1).
#         For example,
#             "This is a standard %d printf string %s that is used as an
#             example %f."
#         So here, %d = 1, %s = 2, %f = 3 so we'd have [1, 2, 3].
#
# TODO: Use the code in the POParam spec tests to test this class out.
# Eventually, the POParam code should be removed.
class ParameterizedString
  # Regexes describing Cases (1), (2), (3).
  #
  # TODO: It turns out that Case (1) can have a type specifier too, e.g.
  # something of the form {0, number}. Modify the regex to account for
  # this.
  STANDARD = /\{(\d+)\}/
  RUBY_PERCENT = /%\{([\p{Alpha}_]\w*)\}/
  HANDLEBAR = /\{\{([\p{Alpha}_]\w*)\}\}/

  # According to the docs, the syntax for a printf format placeholder is:
  #    %[index][flags][width][.precision][length]type 
  # For our purposes, we only care about the index. 
  #
  # TODO: The width and precision components can be dynamic, i.e. they can
  # take another parameter. Consider these cases later, I won't for now b/c
  # they're probably not common and considering them now would add a lot of
  # complexity in the main code.
  INDEX = /(?:(\d+)\$)?/
  FLAGS = /(?:-|\+| |0|#)?/
  WIDTH = /\d*/
  PRECISION = /(?:\.\d+)?/
  LENGTH = /(?:hh|ll|[hlLzjt])?/
  TYPE = /(?:[diufFeEgGxXoscpaAn])/
  PRINTF = Regexp.new(
    /(?:\A|[^%])/.to_s\
    + /%/.to_s\
    + INDEX.to_s\
    + FLAGS.to_s\
    + WIDTH.to_s\
    + PRECISION.to_s\
    + LENGTH.to_s\
    + TYPE.to_s\
  )

  # The regexes for all possible parameters that are captured by
  # the ParameterizedString class.
  PARAM_RES = [STANDARD, RUBY_PERCENT, HANDLEBAR, PRINTF]

  # This method parses out the <prefix> part of the parameterized string. It
  # returns [prefix, rest] where rest is the part of the param_str after
  # the prefix.
  #
  # NOTE: rest should be described by (<param><mid>)* as specified in the
  # initialize method's description
  def parse_prefix(param_str, param_re)
    match_obj = param_re.match(param_str)
    return [param_str, ""] unless match_obj
    return [match_obj.pre_match, match_obj[0] + match_obj.post_match] unless param_re == PRINTF
    # PRINTF matches the previous character (since we want to escape %%). We must include that
    # character as a part of our prefix; our param is whatever comes after that character.
    # Note that we may or may not have a previous character.
    match_obj[0][0] == "%"  ?
      ["", match_obj[0] + match_obj.post_match]
    : [match_obj.pre_match + match_obj[0][0], match_obj[0][1..-1] + match_obj.post_match]
  end

  # This method parses out the param_mids array. It takes in the portion
  # of the string that comes after the prefix (i.e. rest consists of
  # the (<param><mid>)* part), the param_re, and a block that contains
  # details of how to extract the <param> part given a match object, as
  # well as return what comes after the <param> part (call it post_param). We 
  # take advantage of the fact that post_param is a string described by the
  # regex <mid>(<param><mid>)* so that we can use parse_prefix to extract
  # the <mid> part.
  def parse_param_mids_helper(rest, param_re, &extract_param)
    param_mids = []
    while (match_obj = param_re.match(rest)) do 
      param, post_param = extract_param.call(match_obj)
      mid, rest = parse_prefix(post_param, param_re)
      param_mids.push([param, mid])
    end
    param_mids
  end

  def parse_param_mids(rest, param_re)
    match_obj = param_re.match(rest)
    return [] unless match_obj

    # All regexes except PRINTF will have the unique 
    # identifier for a param in the first group match.
    # For PRINTF, there are the positional and non-positional
    # parameter cases. If the param string does have positional
    # parameters, then for all matches on the param, match_obj[1]
    # will be non-nil. This is what we will use to uniquely identify
    # the parameters. So the code below captures two cases:
    #   (1) When param_re != PRINTF
    #   (2) When param_re == PRINTF, and "rest" contains positional
    #   parameters
    return parse_param_mids_helper(rest, param_re) do |match_obj|
      [match_obj[1], match_obj.post_match]
    end if match_obj[1]

    # We have param_re == PRINTF containing non-positional parameters
    # here.
    ix = 0
    parse_param_mids_helper(rest, param_re) do |match_obj|
      [(ix += 1).to_s, match_obj.post_match]
    end
  end

  # The constructor takes in two parameters:
  #   (1) param_str - The param string
  #   (2) param_re  - The regex describing the param specifiers. Must be
  #   one of the regexes in the FORMAT_RE array.
  #
  # We can describe all param strings by the following regex:
  #   <prefix>(<param><mid>)*
  # where <prefix> is the initial part of the string that does
  # not contain any param specifiers; <param> is a param specifier
  # described by the param_re; and <mid> is the part of the string
  # after <param> that does not contain any param specifiers.
  #
  # Thus, we deconstruct the param_str parameter into two pieces:
  #   (1) prefix
  #   (2) param_mids
  # where (2) is an array of pairs (param, mid). Note that we specify
  # a <param> by its unique identifier, as described above.
  #
  # For performance reasons (to avoid a lot of garbage collection), we
  # also keep track of additional components:
  #   (3) params - These are all the param specifiers in the param_str, in
  #   order of appearance (there can be duplicates!)
  #
  #   (4) length - The raw length of param_str, where param specifiers
  #   are not included.
  #
  #   (5) has_adjacent_params - This is a boolean indicating whether or not
  #   the paramted string has adjacent param specifiers. Important for
  #   regex matching (see 6), because these param strings can result in
  #   catastrophic backtracking. Note that a param string has adjacent
  #   param specifiers iff there exists a "mid" that is the empty string.
  #
  #   (6) prefix_re - A regex that matches the prefix
  #
  #   (7) param_mids_re - This is the param_mids array but transformed so that
  #   the <mid> portion consists of a regex matching <mid> in the original
  #   array. If the last <mid> is the empty string, then the regex matches the end
  #   of the string instead -- for the reason why, see the description of the matching
  #   algorithm for more details.
  def initialize(param_str, param_re)
    @prefix, rest = parse_prefix(param_str, param_re)
    @param_mids = parse_param_mids(rest, param_re) 
    @params = @param_mids.map { |(param, _)| param }
    @length = substitute_const("").length 
    @has_adjacent_params = @param_mids[0...-1].any? { |(_, mid)| mid.empty? }

    # Construct the regexes
    @prefix_re = Regexp.new(Regexp.escape(@prefix))
    @param_mids_re = @param_mids.map { |param, mid| [param, Regexp.new(Regexp.escape(mid))] }
    return if @param_mids_re.empty?
    last_param, last_mid_re = @param_mids_re.pop
    @param_mids_re << [last_param, last_mid_re == // ? /\z/ : last_mid_re]
  end

  # This method takes in a map that maps each parameter's identifier to
  # that parameter's value. It will return the parameterized string with
  # those values substituted in.
  #
  # If no values are provided, then the param id will be substituted.
  def substitute_values(param_vals)
    @param_mids.inject(@prefix) do |accum, (param, mid)|
      accum + (param_vals[param] || param) + mid
    end
  end

  # This method is the same as substitute_values, but instead replaces all format
  # specifiers with a constant value (must be a string).
  def substitute_const(val)
    substitute_values(@params.zip(@params.size.times.collect { val }).to_h)
  end

  # This method returns true if the parametrized string has adjacent parameters,
  # false otherwise. Used to avoid catastrophic backtracking.
  def adjacent_params?
    @has_adjacent_params
  end

  # Returns the length of the parameterized string, excluding the parameters themselves.
  def length
    @length
  end

  # Returns the parameter ids of the parameterized string.
  def params
    @params.uniq
  end

  # Two possible cases:
  #   (1) If the msg contains the parameterized string parameterized with values, then this will
  #   return the three element array:
  #      [pre, param_vals, post]
  #   where pre is the part of the msg before the parameterized string; param_vals is a hash map
  #   of the parameters to their values, and post is the part of msg after the
  #   parameterized string.
  #
  #   (2) Otherwise, this method returns nil.
  #
  # The algorithm works as follows. We know that if msg matches our parameterized string, it
  # must match the regex <prefix>(<param><mid>){n} where n = param_mids.length, i.e. the number
  # of parameters in the parameterized string. Thus, we do the following:
  #    (1) First check that it matches the prefix. If it does not, then we return nil.
  #    Otherwise, go to (2).
  #
  #    (2) We have the prefix. "pre" is the part of "msg" preceding the prefix. The part
  #    after the prefix must match (<param><mid>){n}. Thus, we iterate the remaining part
  #    of the string through our param_mids array and do the following for a given
  #    (param, mid) pair:
  #       (a) If the rest of the string does not match <mid>, then we return nil.
  #
  #       (b) If it does, then note that the part preceding the match with <mid> is
  #       the value of param. So we include (param => value) in our param_vals map.
  #       And note that the part after the match with <mid> is still in the form
  #       (<param><mid>){remaining} where remaining is the remaining # of elements in
  #       the param_mids array we have to check.
  #
  #    (3) If (2) does not return nil, then "msg" does match our parameterized string. The
  #    remaining part of msg is the "post" portion we want to return.
  #
  # NOTE: There is a slight edge case. If the last <mid> in the last element of the
  # (<param>, <mid>) array is empty, then the value of that <param> is the remaining
  # part of the string.
  #
  # TODO: Maybe remove the adjacent_params? filter in the main code and have this return
  # nil for strings of that form? Might be a good idea.
  #
  # NOTE: This matching algorithm is an order of magnitude faster than the original regex
  # method. However, it does introduce a limitation in the tool because it does not do a
  # greedy match on the parameter value. For example, if we have a string of the form:
  #    "Example string: '%{line}'"
  # and we are matching some of the form "Example string: ''temp''", then this routine
  # would return:
  #   ["", { "line" => "" }, "temp''"]
  # If this becomes an issue, then the original algorithm can be used or some additional
  # complexity can be added to the routine to consider specific, common cases that might
  # occur.
  def match(msg)
    prefix_match = @prefix_re.match(msg)
    return nil unless prefix_match
    pre = prefix_match.pre_match

    param_vals = {}
    post = @param_mids_re.inject(prefix_match.post_match) do |rest, (param, mid_re)|
      mid_match = mid_re.match(rest)
      return nil unless mid_match
      param_vals.store(param, mid_match.pre_match)
      mid_match.post_match
    end

    [pre, param_vals, post]
  end
end
