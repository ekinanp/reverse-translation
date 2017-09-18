require "spec_helper"

describe Array do
  describe "#bsearch_index_left" do
    it "returns nil if the value x does not exist in the array" do
      ix = [1, 2, 3].bsearch_index_left(4) do |e|
        e <=> 4
      end

      expect(ix).to eql(nil)
    end
    it "returns the index of the left-most occurrence of x if x exists in the array" do
      bsearch_test_cases = [
        # The first test case tests the basic bsearch functionality. The second test case tests
        # Case (a) by using a duplicate array to ensure that the left-most occurrence is returned.
        [(0..9).to_a,
         (0..9).map { |x| [x, x] }],

        [[0, 0, 0, 1, 1, 1, 2, 2, 3, 4, 5, 5],
         {0 => 0, 1 => 3, 2 => 6, 3 => 8, 4 => 9, 5 => 10}]
      ]

      bsearch_test_cases.each do |(array, test_cases)|
        test_cases.each do |input, expected|
          ix = array.bsearch_index_left do |e|
            input <=> e
          end

          expect(ix).to eql(expected)
        end
      end
    end
  end
end

describe Math do
  describe ".max" do
    context "given inputs x and y" do
      it "returns x if x > y" do
        expect(Math.max(3, 2)).to eql(3)
      end
      it "returns y if x <= y" do
        expect(Math.max(2, 3)).to eql(3)
      end
    end
  end
end
