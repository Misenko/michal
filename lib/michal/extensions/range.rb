# Extension for standard ruby Range class
#
class Range
  # Returns array of equally spread numbers within the range
  #
  # @param [Fixnum] n number of elements in resulting array
  # @return [Array] array of equally spread numbers within the range
  def spread(n)
    fail ::ArgumentError, 'spread must be at least 2' if n < 2
    step_size = size.to_f/(n-1)
    array = to_a
    (0..(n-2)).to_a.map { |i| array[i*step_size]} + [last]
  end
end
