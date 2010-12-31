class Array
  # extension method; returns all (length-1)-combinations of array elements
  def combinations
    combination(length - 1).to_a
  end
end

$DEBUGGING = true

def DEBUG_ON
  $DEBUGGING = true
end

def DEBUG_OFF
  $DEBUGGING = false
end

def DEBUG(*args)
  if $DEBUGGING
    puts(*args)
  end
end

def DEBUGPP(*args)
  if $DEBUGGING
    pp(*args)
  end
end
