class Array
# extension method; returns all (length-1)-combinations of array elements
  def combinations
    combination(length - 1).to_a
  end
end
