require "spec_helper"

describe POParam do
  # Regexes 
  STANDARD = POParam::STANDARD
  RUBY_PERCENT = POParam::RUBY_PERCENT
  HANDLEBAR = POParam::HANDLEBAR
  PRINTF = POParam::PRINTF 
  PARAM_RES = POParam::PO_PARAMS

  # Input data for happy cases
  IDENTIFIERS = POParamFixture::IDENTIFIERS
  INTEGERS = POParamFixture::INTEGERS

  # Regex tests
  describe "regex describing standard parameters" do
    context "given a valid parameter" do
      it "matches it" do
        INTEGERS.each { |i| expect("{#{i}}").to match(STANDARD) } 
      end
    end
    context "given an invalid parameter" do
      it "does not match it" do
        POParamFixture::STANDARD_BAD_INPUT.each { |s| expect(s).not_to match(STANDARD) }
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
        POParamFixture::RUBY_PERCENT_BAD_INPUT.each { |s| expect(s).not_to match(RUBY_PERCENT) }
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
        POParamFixture::HANDLEBAR_BAD_INPUT.each { |s| expect(s).not_to match(HANDLEBAR) }
      end
    end
  end

  describe "regex describing printf-style parameters" do
    context "given a valid parameter" do
      # Exhaustive testing here. If we denote the following sets:
      #    A = PARAMETERS
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
          POParamFixture::PRINTF_PARAMETERS,
          POParamFixture::PRINTF_FLAGS,
          POParamFixture::PRINTF_WIDTHS,
          POParamFixture::PRINTF_PRECISION,
          POParamFixture::PRINTF_LENGTHS,
        ]
        REQUIRED_SET = POParamFixture::PRINTF_TYPES
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
        POParamFixture::PRINTF_BAD_INPUT_CASES.each do |re, bad_inputs|
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

  describe ".escape_param_re" do
    describe "given a regex A describing a possible set of po parameters" do
      it "produces a regex B such that for all strings s matching A, Regexp.escape(s) identically matches B" do
        test_cases = POParamFixture::TO_PARAM_SUB_RE_TEST_CASES 

        test_cases.each do |param_re, msgs|
          escaped_param_re = POParam.escape_param_re(param_re)          
          msgs.each do |(msg)|
            expect(param_re.match(msg)[1..-1]).to eql(escaped_param_re.match(Regexp.escape(msg))[1..-1])
          end
        end
      end
    end
  end

  describe ".extract_params" do
    describe "given a message M and a regex A describing a possible set of po parameters that the message may contain" do
      context "when M has no parameters that match A" do
        it "returns an empty array" do
          msg = POParamFixture::NO_PARAM_MSG
          PARAM_RES.each { |param_re| expect(POParam.extract_params(msg, param_re)).to eql([]) }
        end
      end
      context "when M has parameters that match A" do
        it "returns an array containing all the matched parameters in order of appearance" do
          test_cases = POParamFixture::EXTRACT_PARAMS_TEST_CASES

          test_cases.each do |param_re, cases|
            cases.each do |(msg, params)|
              expect(POParam.extract_params(msg, param_re)).to eql(params)
            end
          end
        end
      end
    end
  end

  describe ".substitute_params" do
    describe "given a parametrized message M, a regex A describing the possible set of po parameters that M may contain, and a map of <param> => <value> for each parameter in M" do
      context "when M has no parameters that match A" do
        it "returns M" do
          msg = POParamFixture::NO_PARAM_MSG
          PARAM_RES.each { |param_re| expect(POParam.substitute_params(msg, param_re, {})).to eql(msg) }
        end
      end
      context "when M has parameters that match A" do
        it "returns M', where M' is M but with all of M's parameters substituted with their corresponding values" do
          test_cases = POParamFixture::SUBSTITUTE_PARAMS_TEST_CASES

          test_cases.each do |param_re, cases|
            cases.each do |(parametrized_msg, expected_msg, param_values)|
              expect(POParam.substitute_params(parametrized_msg, param_re, param_values)).to eql(expected_msg)
            end
          end
        end
      end
    end
  end
end
