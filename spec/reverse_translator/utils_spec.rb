require "spec_helper"

describe Array do
  describe "#bsearch_index_left" do
    it "returns nil if the value x does not exist in the array" do
      ix = [1, 2, 3].bsearch_index_left(4) do |e|
        UtilsFixture.bsearch_block(4).call(e)
      end

      expect(ix).to eql(nil)
    end
    it "returns the index of the left-most occurrence of x if x exists in the array" do
      UtilsFixture::TEST_CASES_BSEARCH.each do |(array, test_cases)|
        test_cases.each do |input, expected|
          ix = array.bsearch_index_left do |e|
            UtilsFixture::bsearch_block(input).call(e)
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
