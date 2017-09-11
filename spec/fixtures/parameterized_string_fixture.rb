module ParameterizedStringFixture
  # Testing the individual parameter regexes. These are the data
  # that'll be used for the happy cases.
  IDENTIFIERS = ["_foo", "foo", "foo12345", "foo123__foo123"]
  INTEGERS = (1..10)

  PRINTF_INDEX = INTEGERS.map { |i| "#{i}$" }
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
  #   (1) Ensure that the individual pieces (INDEX, FLAGS, WIDTH) do not match
  #   their respective bad inputs.
  #
  #   (2) Ensure that some combination of the individual pieces does not match the
  #   main PRINTF regex.
  INDEX_BAD_INPUT = ["$", "abc$", "$1", "1 $", "$ 1"]
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

  # Map of regex to its bad input cases for the various components that
  # make up the PRINTF regex.
  PRINTF_BAD_INPUT_CASES = {
    ParameterizedString::INDEX     => INDEX_BAD_INPUT,
    ParameterizedString::FLAGS     => FLAGS_BAD_INPUT,
    ParameterizedString::WIDTH     => WIDTH_BAD_INPUT,
    ParameterizedString::PRECISION => PRECISION_BAD_INPUT,
    ParameterizedString::LENGTH    => LENGTH_BAD_INPUT,
    ParameterizedString::TYPE      => TYPE_BAD_INPUT,
    ParameterizedString::PRINTF    => PRINTF_BAD_INPUT
  }

  # Aliases to the regexes, to save typing
  STANDARD = ParameterizedString::STANDARD
  PRINTF = ParameterizedString::PRINTF

  # All of the test cases below will have three pieces to them:
  #    [param_str, param_re, other]
  # where param_str and param_re are what will be used to construct the parameterized
  # string object, and other is another necessary component for that specific test case.
  # This can be either an additional input, an expected value, whatever. But
  # the idea is that each test case will be built from the param_str's overall structure,
  # given by the <PREFIX>(<PARAM><MID>)* regex described in the ParameterizedString class'
  # comments. Here, however, <PARAM> is represented as a hash map of <id> => <original value>two key components:
  # where <original value> is how the param. appears in the parameterized string (e.g.
  # "%s" for printf, %{<identifier>} for a ruby percent parameter, etc.
  #
  # NOTE: There might be some redundant test cases for some of the parameterized string class'
  # methods, but this abstraction makes it simpler to add a new test case capturing a larger
  # class of instance methods because both methods will use the same pieces.
  #
  # NOTE: The key idea is that once the parameterized string's structure is parsed out,
  # everything else about the string (its length, its parameters) follows. The main work in the
  # parameterized string class is figuring out this structure.
  GENERAL_TEST_CASE_PIECES = [
    ["This string has no parameters", [], STANDARD],

    # For any regex other than PRINTF
    ["This ", [[{"0" => "{0}"}, " has "], [{"1" => "{1}"}, " parameter"]], STANDARD],
    ["", [[{"0" => "{0}"}, " has "], [{"1" => "{1}"}, " parameter"]], STANDARD],
    ["", [[{"0" => "{0}"}, " has "], [{"1" => "{1}"}, " parameter for "], [{"2" => "{2}"}, ""]], STANDARD],
    ["", [[{"0" => "{0}"}, " has "], [{"0" => "{0}"}, " at "], [{"1" => "{1}"}, " and "], [{"1" => "{1}"}, ""]], STANDARD],

    # For PRINTF, but with non-positional parameters
    ["This ", [[{"1" => "%s"}, " has "], [{"2" => "%d"}, " parameter"]], PRINTF],
    ["", [[{"1" => "%s"}, " has "], [{"2" => "%d"}, " parameter"]], PRINTF],
    ["", [[{"1" => "%s"}, " has "], [{"2" => "%s"}, " at "], [{"3" => "%d"}, " and "], [{"4" => "%d"}, ""]], PRINTF],

    # For PRINTF, but with positional parameters
    ["This ", [[{"1" => "%1$s"}, " has "], [{"2" => "%2$d"}, " parameter"]], PRINTF],
    ["", [[{"1" => "%1$s"}, " has "], [{"2" => "%2$d"}, " parameter"]], PRINTF],
    ["", [[{"1" => "%1$s"}, " has "], [{"2" => "%2$d"}, " parameter for "], [{"3" => "%3$f"}, ""]], PRINTF],
    ["", [[{"1" => "%1$s"}, " has "], [{"1" => "%1$s"}, " at "], [{"2" => "%2$d"}, " and "], [{"2" => "%2$d"}, ""]], PRINTF]
  ]

  # This method builds a test case using the above test case pieces. It takes in a block
  # that specifies the "other" part outlined above. For substitute_values, these will be
  # the values that will be used to pass in to that routine; for params, it will be the
  # expected order of the parameters, etc.
  def self.construct_test_case(test_case_pieces = GENERAL_TEST_CASE_PIECES)
    test_case_pieces.map do |(prefix, param_mids, param_re)|
      param_str = param_mids.inject(prefix) do |accum, (param, mid)|
        accum + param.values[0] + mid
      end
      [param_str, param_re, *yield(prefix, param_mids, param_re)]
    end
  end

  SUBSTITUTE_VALUES_TEST_CASES = construct_test_case do |prefix, param_mids, param_re|
    [param_mids.inject({}) do |accum, (param, mid)|
      accum.merge(param)
    end]
  end

  # The constant we will use is the phrase "(constant)" for the tests
  SUBSTITUTE_CONST_TEST_CASES = construct_test_case do |prefix, param_mids, param_re|
    [param_mids.inject({}) do |accum, (param, mid)|
      accum.merge(param.keys[0] => "(constant)")
    end]
  end

  PARAMS_TEST_CASES = construct_test_case do |prefix, param_mids, param_re|
    [param_mids.map { |(param, mid)| param.keys[0] }.uniq ]
  end

  LENGTH_TEST_CASES = construct_test_case do |prefix, param_mids, param_re|
    param_mids.inject(prefix.length) { |accum, (_, mid)| accum + mid.length }
  end

  # Test case pieces that are special to adjacent_params?.
  ADJACENT_PARAMS_TEST_CASE_PIECES = GENERAL_TEST_CASE_PIECES + [
    ["", [[{"0" => "{0}"}, ""], [{"1" => "{1}"}, " has adjacent parameters"]], STANDARD],
    ["This string ", [[{"0" => "{0}"}, ""], [{"1" => "{1}"}, " also has adjacent parameters"]], STANDARD],
    ["Finally, this string contains adjacent parameters too ", [[{"0" => "{0}"}, ""], [{"1" => "{1}"}, ""]], STANDARD]
  ]

  # A parameterized string has adjacent parameters iff any <MID> except the last one
  # is the empty string -- when constructing these test cases, we make this property
  # explicit by considering only the part of param_mids that has the last element
  # removed.
  ADJACENT_PARAMS_TEST_CASES = construct_test_case(ADJACENT_PARAMS_TEST_CASE_PIECES) do |prefix, param_mids, param_re|
    param_mids_dup = param_mids.dup
    param_mids_dup.pop
    param_mids_dup.any? { |(_ ,mid)| mid.empty? }
  end

  # Looking at the TEST_CASE_PIECES values, notice that if we pass the param_str itself
  # as input to match, then the "pre" and "post" pieces should be the empty string, and
  # the "param_vals" map that's returned should be the final map resulting from merging
  # the <id> => <original-value> maps themselves. Thus, these test cases construct the
  # id_orig_map.
  MATCH_PROPERTY_TEST_CASES = construct_test_case do |prefix, param_mids, param_re|
    [param_mids.inject({}) do |accum, (param, _)|
      accum.merge(param)
    end]
  end
end
