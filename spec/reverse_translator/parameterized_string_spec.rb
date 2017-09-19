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
      # Exhaustive testing here.
      it "matches it" do
        inputs = FixtureUtils.string_cartesian_product(
          ["%"],
          [ParameterizedStringFixture::PRINTF_INDEX],
          [ParameterizedStringFixture::PRINTF_FLAGS],
          [ParameterizedStringFixture::PRINTF_WIDTHS],
          [ParameterizedStringFixture::PRINTF_PRECISION],
          [ParameterizedStringFixture::PRINTF_LENGTHS],
          ParameterizedStringFixture::PRINTF_TYPES
        )

        inputs.each { |i| expect(i).to match(PRINTF) }
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
    context "given an arbitrary parameterized string" do
      param_str = ParameterizedString.new(
        "This {0} string has {1} parameter",
        ParameterizedString::STANDARD
      )
      context "and an input that does not match the 'prefix' part of the string" do
        it "should return nil" do
          expect(param_str.match("Bad prefix")).to be_nil
        end
      end
      context "and an input that fails to match at some <param><mid> pair" do
        it "should return nil" do
          expect(param_str.match("This {special} string does not have {one} parameter")).to be_nil
          expect(param_str.match("This {special} string has {one} param")).to be_nil
        end
      end
      context "and an input that matches the string" do
        it "should return the part preceding the match, the parameter-value map, and the part succeeding the match" do
          input = "Hi there. This {special} string has {one} parameter. Yes, it does."
          expected = ["Hi there. ", {"0" => "{special}", "1" => "{one}"}, ". Yes, it does."]

          expect(param_str.match(input)).to eql(expected)
        end
      end
    end
    context "given a parameterized string with a parameter at the end" do
      it "should set the value of the final parameter to whatever comes after it; equivalently, the 'post' part should always be empty in the return" do
        param_str = ParameterizedString.new(
          "This {0} string has a parameter at the end. {1}",
          ParameterizedString::STANDARD
        )

        test_cases = {
          "Hi there. This {special} string has a parameter at the end. Hopefully its value is set." =>
          ["Hi there. ", {"0" => "{special}", "1" => "Hopefully its value is set."}, ""],
          "This {special} string has a parameter at the end. " =>
          ["", {"0" => "{special}", "1" => ""}, ""]
        }

        test_cases.each { |input, expected| expect(param_str.match(input)).to eql(expected) }
      end
    end
  end
end
