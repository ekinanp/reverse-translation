module POParamFixture
  # Testing the individual parameter regexes. These are the data
  # that'll be used for the happy cases.
  IDENTIFIERS = ["_foo", "foo", "foo12345", "foo123__foo123"]
  INTEGERS = (1..10)

  PRINTF_PARAMETERS = INTEGERS.map { |i| "#{i}$" }
  PRINTF_FLAGS = "-+ 0#".split("")
  PRINTF_WIDTHS = INTEGERS.map { |i| i.to_s }
  PRINTF_PRECISION = INTEGERS.map { |i| ".#{i}" } 
  PRINTF_LENGTHS = ["hh", "ll", "h", "l", "L", "z", "j", "t"]
  PRINTF_TYPES = "diufFeEgGxXoscpaAn".split("")

  # Some bad input that should not be matched.
  STANDARD_BAD_INPUT = ["{}", "{0", "0}", "{0 }", "{ 0}", "{ 0 }", ""]
  RUBY_PERCENT_BAD_INPUT = [
    "%{}", 
    "{foo}", 
    "%{foo", 
    "foo}", 
    "%{foo }", 
    "%{ foo}",
    "%{ foo }",
    "%{1foo}",
    "%{234foo}",
    "%{foo!@#!@}",
    ""
  ]
  HANDLEBAR_BAD_INPUT = [
    "{{}}", 
    "{foo}", 
    "{{foo", 
    "foo}}", 
    "{foo}}",
    "{{foo}",
    "{{foo }}", 
    "{{ foo}}",
    "{{ foo }}",
    "{{1foo}}",
    "{{234foo}}",
    "{{foo!@#!@}}"
  ]

  # printf is trickier, as the regex is complex. It is best to test the following:
  #   (1) Ensure that the individual pieces (PARAMETER, FLAGS, WIDTH) do not match
  #   their respective bad inputs.
  #
  #   (2) Ensure that some combination of the individual pieces does not match the
  #   main PRINTF regex.
  PARAMETER_BAD_INPUT = ["$", "abc$", "$1", "1 $", "$ 1"]
  FLAGS_BAD_INPUT = ["%", "^", "*", "@", "_", "r"]
  WIDTH_BAD_INPUT = ["abc", "abc1234"]
  PRECISION_BAD_INPUT = ["1", "123.", ".abc", "abc."]
  LENGTH_BAD_INPUT = ["aa" ,"bb" ,"ee", "11", "y"]
  TYPE_BAD_INPUT = ["z", "w", "y", "v", "q", ";", ""] 
  PRINTF_BAD_INPUT = [
    "%%",
    "%%s",
    "s",
    "%m",
    "%zzu",
    "%$11.23s",
    "%$1llu",
    "%1$z",
    "%1+1llu",
    "%1$^hhd",
    ""
  ]
  # Map of regex to its bad input cases
  PRINTF_BAD_INPUT_CASES = {
    POParam::PARAMETER => PARAMETER_BAD_INPUT,
    POParam::FLAGS     => FLAGS_BAD_INPUT,
    POParam::WIDTH     => WIDTH_BAD_INPUT,
    POParam::PRECISION => PRECISION_BAD_INPUT,
    POParam::LENGTH    => LENGTH_BAD_INPUT,
    POParam::TYPE      => TYPE_BAD_INPUT,
    POParam::PRINTF    => PRINTF_BAD_INPUT
  }

  # Fixtures for the param substitution methods.
  # Below is a map of <param-regex> => <valid-param-samples>.
  # This will be used to inject random parameters into the strings.
  REGEX_SAMPLE_PARAMS_MAP = {
    POParam::STANDARD     => INTEGERS.map { |i| "{#{i}}" },
    POParam::RUBY_PERCENT => IDENTIFIERS.map { |ident| "%{#{ident}}" },
    POParam::HANDLEBAR    => IDENTIFIERS.map { |ident| "{{#{ident}}}" },
    POParam::PRINTF       => {
      "positional"        => INTEGERS.map { |i| "%#{i}$s" },
      "non-positional"    => "diufFeEgGxXoscpaAn".split("").map { |t| "%#{t}" }
    }
  }

  # This method takes in chunks of a message and a param regex describing
  # the expected parameters of the message. It will then randomly insert
  # some set of parameters into the message. The return value is an array
  #     [parametrized_msg, params, substituted_msg, param_values]
  # where parametrized_msg is the parametrized message, params is an array of the
  # params. that were inserted, as would be returned by the "extract_params"
  # method in the POParam class; substituted_msg is the message with values
  # substituted in for the params, as would be returned by the "substitute_params"
  # method; and param_values is a map of param => value containing the values
  # used for each parameter in making the substituted_msg. 
  #
  # NOTE: The third argument, "positional" is only for the case when param_re is the 
  # PRINTF regex, where we choose to insert either positional or non-positional parameters.
  #
  # For example, if msg = ["This is", "an example", "message"], then assuming that the
  # parameters "{0}" and "{1}" were chosen, this method might return:
  #    [ "This is {0} an example {1} message, ["0", "1"], 
  #      "This is 1 an example 2 message", {"0" => 1, "1" => 2} ]
  # # main array)
  def self.parametrize(msg_chunks, param_re, param_kind="")
    is_printf = param_re == POParam::PRINTF
    sample_space = REGEX_SAMPLE_PARAMS_MAP[param_re]
    sample_space = sample_space[param_kind] if is_printf
    params = (msg_chunks.size - 1).times.collect { sample_space.sample }
    parametrized_msg = FixtureUtils.interleave(msg_chunks, params).join(" ")

    # Now create the substituted message and the value maps
    if !is_printf then
      param_ids = params.map { |p| param_re.match(p)[1] }
    elsif param_kind == "non-positional" then 
      param_ids = params.each_index.map { |i| (i + 1).to_s}
    else 
      param_ids = params.map { |p| param_re.match(p)[2] }
    end
    param_values = param_ids.uniq.map { |param| [param, rand(1..100).to_s] }.to_h
    substituted_msg = FixtureUtils.interleave(msg_chunks, param_ids.map { |id| param_values[id] }).join(" ")

    [parametrized_msg, param_ids, substituted_msg, param_values]
  end

  MSG_TEMPLATE_ONE = ["This is %%", "an", "example message", "for", "params"]

  MSG_TEMPLATES = [MSG_TEMPLATE_ONE]

  # This is map of <param_re> => <test_cases> for the methods "to_param_sub_re",
  # "substitute_params" and "extract_params".
  ALL_TEST_CASES = POParam::PO_PARAMS.map do |param_re|
    parametrized_msgs = MSG_TEMPLATES.map do |msg|
      param_kinds = (param_re == POParam::PRINTF) ? ["non-positional", "positional"] : [""]
      param_kinds.map { |param_kind| parametrize(msg, param_re, param_kind) }
    end
    [param_re, parametrized_msgs.reduce(:concat)]
  end.to_h

  # This method extracts a subset of the ALL_TEST_CASES map. The argument "parts"
  # is an array of indices ranging from 0 - 3 (corresponding to the returned array
  # in parametrize) indicating which parts of the test case need to be extracted
  def self.specific_test_case(parts)
    ALL_TEST_CASES.map do |param_re, test_cases|
      specific_test_cases = test_cases.map do |test_case| 
        parts.map { |part| test_case[part] }
      end
      [param_re, specific_test_cases]
    end.to_h
  end

  TO_PARAM_SUB_RE_TEST_CASES = specific_test_case([0])
  EXTRACT_PARAMS_TEST_CASES = specific_test_case([0, 1])
  SUBSTITUTE_PARAMS_TEST_CASES = specific_test_case([0, 2, 3])

  # Parameter-less message
  NO_PARAM_MSG = "This message has no parameters"
end
