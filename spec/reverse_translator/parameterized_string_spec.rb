require "spec_helper"

describe ParameterizedString do
  # Regexes 
  STANDARD = ParameterizedString::STANDARD
  RUBY_PERCENT = ParameterizedString::RUBY_PERCENT
  HANDLEBAR = ParameterizedString::HANDLEBAR
  PRINTF = ParameterizedString::PRINTF 
  PARAM_RES = ParameterizedString::PARAM_RES

  # Input data for happy cases
  IDENTIFIERS = ParameterizedStringFixture::IDENTIFIERS
  INTEGERS = ParameterizedStringFixture::INTEGERS

  # Regex tests
  describe "regex describing standard parameters" do
    context "given a valid parameter" do
      it "matches it" do
        INTEGERS.each { |i| expect("{#{i}}").to match(STANDARD) } 
      end
    end
    context "given an invalid parameter" do
      it "does not match it" do
        ParameterizedStringFixture::STANDARD_BAD_INPUT.each { |s| expect(s).not_to match(STANDARD) }
      end
    end
  end

  describe "regex describing parameters in ruby-percent style" do
    context "given a valid parameter" do
      it "matches it" do
        IDENTIFIERS.each { |i| expect("%{#{i}}").to match(RUBY_PERCENT) } 
      end
    end
    context "given an invalid parameter" do
      it "does not match it" do
        ParameterizedStringFixture::RUBY_PERCENT_BAD_INPUT.each { |s| expect(s).not_to match(RUBY_PERCENT) }
      end
    end
  end

  describe "regex describing parameters using handlebar notation" do
    context "given a valid parameter" do
      it "matches it" do
        IDENTIFIERS.each { |i| expect("{{#{i}}}").to match(HANDLEBAR) } 
      end
    end
    context "given an invalid parameter" do
      it "does not match it" do
        ParameterizedStringFixture::HANDLEBAR_BAD_INPUT.each { |s| expect(s).not_to match(HANDLEBAR) }
      end
    end
  end

  describe "regex describing printf-style parameters" do
    context "given a valid parameter" do
      # Exhaustive testing here. If we denote the following sets:
      #    A = INDEX
      #    B = FLAGS
      #    C = WIDTHS
      #    D = PRECISION
      #    E = LENGTHS
      #    F = TYPES
      # Then note that only Set F is required. Let x = xAxBxCxDxE be
      # a 5-bit binary number, where xY represents whether Set Y is
      # included or not. Assume that x = 10101. Then the number of
      # possible valid printf parameters for this state (using a finite
      # subset of the integers) is thus |xA||xC||xE||xF|. Taking into
      # consideration all possible values of x (2^5 = 32), the total
      # number of possible test cases that will be considered here is
      # bounded above by 32|xA||xB||xC||xD||xE||xF| = 576000.
      it "matches it" do
        OPTIONAL_SETS = [
          ParameterizedStringFixture::PRINTF_INDEX,
          ParameterizedStringFixture::PRINTF_FLAGS,
          ParameterizedStringFixture::PRINTF_WIDTHS,
          ParameterizedStringFixture::PRINTF_PRECISION,
          ParameterizedStringFixture::PRINTF_LENGTHS,
        ]
        REQUIRED_SET = ParameterizedStringFixture::PRINTF_TYPES
        (0..31).each do |n|
          # Find the included sets and reverse the result so that we can
          # create strings by prepending to the front of the string instead
          # of the end.
          sets = OPTIONAL_SETS.each_with_index.inject([]) do |accum, (set, i)|
            next accum if (n & (1 << (4 - i))) == 0
            accum << set
          end.reverse 

          # Compute the input cases, which is the concatenated Cartesian product
          # of all the included sets prepended with a "%" sign, and then see if
          # they match the regex.
          inputs = sets.inject(REQUIRED_SET) do |accum, set|
            set.product(accum).map { |p| p.join }
          end.map { |i| "%#{i}" }
          inputs.each { |i| expect(i).to match(PRINTF) }
        end
      end
    end
    context "given an invalid parameter" do
      it "does not match it" do
        ParameterizedStringFixture::PRINTF_BAD_INPUT_CASES.each do |re, bad_inputs|
          bad_inputs.each do |input|
            # Optional regexes must match only the empty string. Non-optional ones
            # cannot match.
            next expect(re.match(input)[0]).to eql("") if re.match("")
            expect(input).not_to match(re)
          end
        end
      end
    end
  end

  describe "#substitute_values" do
    context "when the parameterized string is passed in a param_str and param_re for initialization" do
      it "enforces the property that ps.substitute_values(param_vals) == param_str where param_vals maps the param IDs to their original representation in param_str" do
        ParameterizedStringFixture::SUBSTITUTE_VALUES_TEST_CASES.each do |(param_str, param_re, param_vals)|
          ps = ParameterizedString.new(param_str, param_re)
          expect(ps.substitute_values(param_vals)).to eql(param_str)
        end
      end
    end
  end

  describe "#substitute_const" do
    it "enforces the property that ps.substitute_const(v) == ps.substitute_values(params_v_map) where params_v_map is a map of the param ids. to the constant value v" do
      ParameterizedStringFixture::SUBSTITUTE_CONST_TEST_CASES.each do |(param_str, param_re, param_v_map)|
        ps = ParameterizedString.new(param_str, param_re)
        expect(ps.substitute_const("(constant)")).to eql(ps.substitute_values(param_v_map))
      end
    end
  end

  describe "#params" do
    it "returns an array of all the unique parameters appearing in the parameterized string" do
      ParameterizedStringFixture::PARAMS_TEST_CASES.each do |(param_str, param_re, expected)|
        ps = ParameterizedString.new(param_str, param_re)
        expect(ps.params).to eql(expected)
      end
    end
  end

  describe "#length" do
    it "returns the length of the parameterized string (which is the length of the original string excluding the parameters themselves)" do
      ParameterizedStringFixture::LENGTH_TEST_CASES.each do |(param_str, param_re, expected)|
        ps = ParameterizedString.new(param_str, param_re)
        expect(ps.length).to eql(expected)
      end
    end
  end

  describe "#adjacent_params?" do
    it "should return true when the string has adjacent parameters, false otherwise." do
      ParameterizedStringFixture::ADJACENT_PARAMS_TEST_CASES.each do |(param_str, param_re, expected)|
        ps = ParameterizedString.new(param_str, param_re)
        expect(ps.adjacent_params?).to eql(expected)
      end
    end
  end

  describe "#match" do
    context "when the parameterized string is passed in a param_str and param_re for initialization" do
      it "should match the original param_str, with the pre and post fields set to '' and the param_vals map a hash of <id> => <original value>" do
        ParameterizedStringFixture::MATCH_PROPERTY_TEST_CASES.each do |(param_str, param_re, id_orig_map)|
          ps = ParameterizedString.new(param_str, param_re)
          expect(ps.match(param_str)).to eql(["", id_orig_map, ""])
        end
      end
    end
  end
end
