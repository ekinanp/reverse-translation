module FixtureUtils
  @@msgid_ctr = 0
  MSGID_GEN = lambda do
    entry_name = (@@msgid_ctr >= 1) ? "msgid_plural" : "msgid"
    @@msgid_ctr = @@msgid_ctr + 1
    entry_name
  end

  @@msgstr_ctr = 0
  @@is_array = false
  MSGSTR_GEN = lambda do
    return "msgstr" if !@@is_array
    entry_name = "msgstr[#{@@msgstr_ctr}]"
    @@msgstr_ctr = @@msgstr_ctr + 1
    entry_name
  end

  def self.set_is_array(val)
    @@is_array = val
  end

  def self.reset
    @@msgid_ctr, @@msgstr_ctr, @@is_array = [0, 0, false]
  end

  def self.non_existent_file_msg(path)
    "ERROR: #{path} does not exist!\n"
  end

  def self.invalid_file_msg(path)
    "ERROR: #{path} is not a valid log file! Log files must have the \".log\" extension.\n"
  end

  def self.valid_file_msg(path)
    "#{path} was successfully translated, with the result written to #{path}.trans!\n"
  end

  def self.unique_path(prefix)
    tmp_file = Tempfile.new(prefix)
    path = tmp_file.path
    tmp_file.close
    tmp_file.unlink
    path
  end

  # Interleaves the array "b" with array "a". Note that
  # if |b| > |a|, then the remaining elements of b are not included.
  def self.interleave(a, b)
    a.zip(b).reduce(:concat).compact
  end

  # This routine takes in a set and returns the underlying set if the set is optional,
  # nil otherwise.
  def self.optional?(set)
    return nil unless set.first.is_a?(Array)
    set.first
  end

  # This routine takes in an array of sets and computes all possible Cartesian
  # products of these sets. Note that some of the sets may be optional.
  # Optional sets should be passed as an array, e.g. as [Xi], while non-optional
  # sets should be passed as-is.
  #
  # Let SETS = X1, X2, X3, ..., XN. Now let x = x1x2x3...xN be an n-digit binary number,
  # where xi represents whether Set Xi is included or not. For non-optional sets, let xi be 1.
  # Notice that the cartesian product of the sets represented in "x" is a valid Cartesian product
  # of each set in SETS. If we let Cx be this Cartesian product, and the set of all valid n-digit
  # binary numbers x be the set X, then our answer is:
  #   C = UNION(Cx s.t. x in X)
  def self.cartesian_product(*sets)
    n = sets.size

    # First, filter out the valid xs from the set of all possible n-digit binary numbers
    # by creating the mask, which is the n-digit binary number x s.t. xi is 1 iff Xi is
    # not optional, 0 otherwise.
    mask = sets.inject(0) do |accum, set|
      accum <<= 1
      accum |= 1 unless optional?(set)
      accum
    end
    valid_xs = (0...2**n).select { |x| x & mask == mask }  

    # Now compute the individual Cxs
    valid_xs.inject([]) do |c, x|
      # Find the included sets
      included_sets = sets.each_with_index.inject([]) do |accum, (set, i)|
        xi = 1 << ((n - 1) - i)
        next accum if (x & xi).zero?
        next accum << set unless optional?(set)
        accum << optional?(set)
      end

      # Now compute Cx, and concatenate it to C
      cx = included_sets.inject do |accum, set|
        accum.product(set).map { |p| p.flatten }
      end
      c.concat(cx)
    end
  end

  # Same as cartesian product above but for sets of strings
  def self.string_cartesian_product(*sets)
    cartesian_product(*sets).map do |p|
      next p unless p.is_a?(Array)
      p.join 
    end
  end
end
