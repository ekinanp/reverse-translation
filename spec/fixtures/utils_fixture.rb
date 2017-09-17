module UtilsFixture
  # For Array#bsearch_index_left, a single test case consists of two pieces:
  #   (1) The array to test on
  #   (2) A map of inputs to their expected values
  #
  # Each input will be searched in the provided array. If bsearch_index_left
  # is correct, then we have the following cases:
  #   (a) If the input x exists in the array, then the index of its left-most occurrence
  #   is returned.
  #
  #   (b) Otherwise, nil is returned.
  TEST_CASES_BSEARCH = [
    # The first test case tests the basic bsearch functionality. The second test case tests
    # Case (a) by using a duplicate array to ensure that the left-most occurrence is returned.
    [(0..9).to_a,
     (0..9).map { |x| [x, x] }],

    [[0, 0, 0, 1, 1, 1, 2, 2, 3, 4, 5, 5],
     {0 => 0, 1 => 3, 2 => 6, 3 => 8, 4 => 9, 5 => 10}]
  ]

  # This routine returns a block which can be passed into bsearch_index_left directly. Here,
  # the block will output one of the following three cases:
  #   (1) 0 if the array element == x
  #   (2) -1 if the array element is greater than x
  #   (3) 1 if the array element is less than x
  def self.bsearch_block(x)
    ->(e) { x <=> e }
  end
end
