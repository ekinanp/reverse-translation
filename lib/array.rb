# This class extends the ruby Array class

class Array
  # This method performs a binary search on the array searching for the left-most
  # element that satisfies some given property. It takes in a block that returns
  # either -1, 0 or 1. A return value of -1 means that we go to the left of the array
  # to find our desired element; 0 means we found our element; while 1 means we need to
  # go right.
  #
  # The method returns the left-most element of the array s.t. direction.call(e) is 0,
  # otherwise if such an element does not exist, then it returns nil.
  #
  # At a high level, the code does this (assume that the block "direction" is implicitly
  # passed to bsearch_index for clarity):
  #
  #   prev_mid = high+1
  #   while ((prev_mid = bsearch_index(self[low..prev_mid-1]))) {}
  #   prev_mid
  #
  # Unfortunately, the above code wouldn't be very efficient performance wise, because
  # the line self[low..prev_mid-1] creates a temporary array everytime it is invoked. That
  # is why the binary search itself must be explicitly written, as is done below.
  def bsearch_index_left(low = 0, high = self.size - 1, &direction)
    prev_mid = nil
    while (low <= high) do
      mid = low + (high - low)/2
      dir = direction.call(self[mid])
      prev_mid = mid if dir == 0
      dir == 0 || dir == -1 ? high = mid - 1 : low = mid + 1
    end
    prev_mid
  end
end
