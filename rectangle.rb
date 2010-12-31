require 'utils.rb'
################################################################################
class Rectangle
  attr_reader :extents

  def extents= (new_extents)
    @extents = reorganize(new_extents)
  end
  
  def initialize (extents)
    case
      when extents.is_a?(Array) :
        @extents = reorganize(extents)
      when extents.is_a?(Integer) :
        @extents = []
        extents.times { @extents << [0,0] }
      else raise ArgumentError, "extents has to be either an integer or an array"
    end
  end
  
  def == (other)
    @extents == other.extents
  end

  def lengths
    @extents.map { |(low,high)| high - low }
  end

  def area
    lengths.reduce(:*)
  end

  def area_enlargement (rect)
    enlarge(rect).area - area
  end

  def margin
    lengths.combinations.map { |tuple| 2*tuple.reduce(:*) }.reduce(:+)
  end

  def export
    "#{@extents.inspect}"
  end

  def export_rect(file,bounding_box = false)
    color = bounding_box ? "(0,0,0) withpen pencircle scaled 2" :
      "(#{rand()/2 + 0.25},#{rand()/2 + 0.25},#{rand()/2 + 0.25})"
    file.puts("draw (#{@extents[0][0]}mm,#{@extents[1][0]}mm)--" +
              "(#{@extents[0][0]}mm,#{@extents[1][1]}mm)--" +
              "(#{@extents[0][1]}mm,#{@extents[1][1]}mm)--" +
              "(#{@extents[0][1]}mm,#{@extents[1][0]}mm)--cycle " +
              "withcolor #{color};")
  end

  def enlarge (rect)
    Rectangle.new(Rectangle.enlarge_extents(@extents,rect.extents))
  end

  def enlarge! (rect)
    @extents = Rectangle.enlarge_extents(@extents,rect.extents)
  end

  def overlap_area (rect)
    rect = overlap_rect(rect)
    rect ? rect.area : 0
  end

  # can't use map_fun, cause overlap is not global function,
  # but method of rect
  def overlap_area_sum (rect_list)
    rect_list.map {|rect| overlap_area(rect)}.reduce(:+)
  end

  def Rectangle.bounding_box(rect_list)
    rect_list.reduce(&:enlarge)
  end

  def subrect?(rect)
    @extents.count == rect.extents.count &&
      @extents.zip(rect.extents).all? do |((low1,high1),(low2,high2))|
      low1 <= low2 && high1 >= high2
    end
  end

  private
  def reorganize (extents)
    extents.map { |(low,high)| (low < high) ? [low,high] : [high,low] }
  end

  # static method
  def Rectangle.enlarge_extents (extents1,extents2)
    extents1.zip(extents2).map do |(low1,high1),(low2,high2)|
      [[low1,low2].min,[high1,high2].max]
    end
  end

  def Rectangle.overlap_extents (extents1,extents2)
    extents = extents1.zip(extents2).map do |(low1,high1),(low2,high2)|
      [[low1,low2].max,[high1,high2].min]
    end
    (extents.any? {|(low,high)| low >= high}) ? nil : extents
  end

  def overlap_rect (rect)
    extents = Rectangle.overlap_extents(@extents,rect.extents)
    extents ? Rectangle.new(extents) : nil
  end
end

if __FILE__ == $0
  $rect = Rectangle.new([[10, 20], [40, 30]])
  $rect2 = Rectangle.new([[10, 20], [30, 40]])
  $rect == $rect2
end
