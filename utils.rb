class Array
# extension method; returns all (length-1)-combinations of array elements
  def combinations
    combination(length - 1).to_a
  end

  # called like data.map_meth(:method)
  # instead of data.map { |data| data.method }
  def map_meth(fun)
    map { |elem| elem.method(fun).call }
  end

  # called like data.map_fun(:function)
  # instead of data.map { |data| function(data) }
  def map_fun(fun)
    map { |elem| Object.method(fun).call(elem) }
  end
end
