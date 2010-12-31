################################################################################
require 'rectangle'

class Node
  attr_accessor :children,:data,:parent,:bounding_box,:id # DEBUG

  # node holds refernce of tree it belongs to, that way every node doesn't
  # have to hold infos about min and max data (children) number and dimension
  # of data stored in tree
  def initialize (tree, parent = nil, id = "") # id - DEBUG
    @tree = tree
    @parent = parent
    @children = []
    @data = []
    @bounding_box = Rectangle.new(tree.dimension)
    @id = id # DEBUG
  end

  def find_data (rect)
    if leaf?
      if @data.member?(rect)
        return self
      end
    else
      ret = nil
      if @children.any? {|child| ret = child.find_data(rect)}
        return ret
      end
    end
  end

  def insert_data (rect)
    # DEBUG "\ninsert_data(#{rect}) called on #{self}" # DEBUG
    just_insert_data (rect)
    check_overflow()
    self
  end

  def delete_data (rect)
    @data.delete(rect)
    update_boxes()
    check_underfill()
  end

  def export (file,name = "1")
    # DEBUG name
    file.write("\"#{name}\"[shape=record,label=\"")
    if leaf?
      file.write(([@bounding_box] + @data).map(&:export).join("|"))
    else
      file.write(@bounding_box.export)
    end
    file.puts("\"];")
    counter = 1
    @children.each do |child|
      child_name = "#{name}.#{counter.to_s}"
      child.export(file,child_name)
      file.puts("\"#{name}\" -> \"#{child_name}\";")
      counter += 1
    end
  end

  def export_rects(file)
    @bounding_box.export_rect(file,true)
    if leaf?
      @data.each {|data| data.export_rect(file)}
    else
      @children.each {|child| child.export_rects(file)}
    end
  end

  def to_s
    "#<#{self.class.name}:#{object_id} @box=#{@bounding_box}>"
  end

  def inspect
    to_s
  end

  def leaf?
    @children.empty?
  end

  def root?
    @parent.nil?
  end
  
  # returns nil if the node itself is leaf
  def children_are_leaves?
    unless leaf?
      @children[0].leaf?
    end
  end

  def box_area
    @bounding_box.area
  end

  # how much do i need to enlarge bounding_box to insert rect in the node
  def box_area_enlargement (rect)
    return rect.area if (@data + @children).empty?
    if leaf?
      new_area = (@data + [rect]).reduce(:enlarge).area
    else
      new_area = (@children.map(&:bounding_box) +
                  [rect]).reduce(:enlarge).area
    end
    new_area - box_area
  end

  # child_changed parameter is needed for Tree#better_node method
  # where child_overlap after rectangle addition is computed
  # method is called on parent
  def child_overlap (child,child_changed = child)
    # DEBUG "child_overlap(#{child},\n  #{child_changed}) called"
    # DEBUG (@children - [child]).inspect
    child_changed.bounding_box.
      overlap_area_sum((@children - [child]).map(&:bounding_box))
    # DEBUG "child_overlap finished"
  end

  # computes enlargement of child node overlap with other children
  # after inserting data rectangle
  # method is called on parent
  # POKUD JE NEKTERE Z DETI PLNE, POSERE SE - SNAZI SE SPLITOVAT KLON, PRICEMZ
  # PRIDA UZEL DO RODICE
  def child_overlap_enlargement (child,data)
    # DEBUG "child_overlap_enlargement called on #{child},#{data}" # DEBUG
    # DEBUG "child_overlap(#{child},\n  #{child.clone.insert_data(data)}) = " +
    #   "#{child_overlap(child,child.clone.insert_data(data))}"
    # DEBUG "child_overlap(#{child} = #{child_overlap(child)}"
    # remove second parameter from insert_data after proper debug
    # DEBUG_OFF()
    overlap = child_overlap(child,child.clone.just_insert_data(data)) - child_overlap(child)
    # DEBUG_ON()
    overlap
  end

  def add_child(node)
    just_add_child(node)
    check_overflow()
  end

  def clone
    # DEBUG "clone called on #{self}" # DEBUG
    new_node = Node.new(@tree, @parent ? @parent.clone : nil)
    new_node.children = @children.clone
    new_node.data = @data.clone
    new_node.update_box
    new_node
  end
  
  def check_overflow
    # DEBUG "check_overflow called on #{self}"
    if leaf?
      split_data if @data.count > @tree.max
    else
      split_children if @children.count > @tree.max
    end
  end

  def check_underfill
    unless root?
      delete if (leaf? ? @data.count : @children.count) < @tree.min
    else
      if @children.count == 1
        @tree.root = @children[0]
        @tree.root.parent = nil
      end
    end
  end

  def delete
    @parent.delete_child(self)
    @data.each {|data| @tree.insert(data)}
  end

  def delete_child(child)
    @children.delete(child)
    check_underfill()
  end

  def just_insert_data (rect)
    return self if @data.member?(rect)
    @data << rect
    update_boxes
    self
  end

################################################################################
#  protected

  # doesn't check for overflow, used by split
  def just_add_child(node)
    return if @children.member?(node)
    @children << node
    node.parent = self
    update_boxes    
  end

  def update_box
    # DEBUG "update_box(#{@id}) called" # DEBUG
    return if (@data + @children) == []
    if leaf?
      @bounding_box = @data.reduce(:enlarge)
    else
      @bounding_box = @children.map(&:bounding_box).reduce(:enlarge)
    end
  end

  def update_parent_box
    return unless @parent
    @parent.update_box
    @parent.update_parent_box
  end

  def update_children_boxes
    @children.each do |child|
      child.update_children_boxes
      child.update_box
    end
  end

################################################################################
#  private
  def update_boxes
    # DEBUG "update_boxes(#{@id}) called" # DEBUG
    update_children_boxes
    update_box
    update_parent_box
  end
  
  def area_value(group1,group2)
    Rectangle.bounding_box(group1).area +
      Rectangle.bounding_box(group2).area
  end

  def margin_value(group1,group2)
    Rectangle.bounding_box(group1).margin +
      Rectangle.bounding_box(group2).margin
  end

  def overlap_value(group1,group2)
    Rectangle.bounding_box(group1).overlap_area(Rectangle.bounding_box(group2))
  end

  def get_distributions(data)
    distributions = []
    1.upto(@tree.max - 2*@tree.min + 2) do |i|
      distributions << [data.values_at(0..((@tree.min-1)*i)),
                        data.values_at(((@tree.min-1)*i + 1)..data.count - 1)]
    end
    distributions
  end
    
  def sort_by_axis(data,axis)
    data.sort do |rect1,rect2|
      low_diff = rect1.extents[axis][0] - rect2.extents[axis][0]
      unless low_diff == 0
        low_diff
      else
        rect1.extents[axis][1] - rect2.extents[axis][1]
      end
    end
  end
  
  def better_distribution(dist1,dist2)
    overlap1 = overlap_value(*dist1)
    overlap2 = overlap_value(*dist2)
    (overlap1 < overlap2 || (overlap1 == overlap2 &&
      area_value(*dist1) < area_value(*dist2))) ? dist1 : dist2
  end
  
  # for each axis sorts the data, gets the distributions, counts sum
  # of margin_values of each distribution and returns the axis number
  # with the smallest sum
  def choose_split_axis(data)
    sums = []
    @tree.dimension.times do |i|
      distributions = get_distributions(sort_by_axis(data,i))
      sums << distributions.map { |(group1,group2)|
        margin_value(group1,group2) }.reduce(&:+)
    end
    sums.find_index(sums.min)
  end

  def choose_split_index(data,axis)
    distributions = get_distributions(sort_by_axis(data,axis))
    distributions.reduce { |dist1,dist2| better_distribution(dist1,dist2) }
  end

  def get_parent
    if @parent
      @parent
    else
      new_root = Node.new(@tree)
      DEBUG_OFF()
      new_root.add_child(self)
      DEBUG_ON()
      @tree.root = new_root
      new_root
    end
  end

  def split_data
    # DEBUG "split_data called on #{self}"
    axis = choose_split_axis(@data)
    distribution = choose_split_index(@data,axis)
    new_node = Node.new(@tree)
    # distribution[0].each { |data| new_node.insert_data(data) }
    new_node.data = distribution[0]
    new_node.update_box
    @data = distribution[1]
    get_parent.add_child(new_node)
    update_boxes
    # DEBUG "split_data finihed on #{self}"
  end

  def find_children(rect_list)
    rect_list.map { |rect|
      @children.find { |child| child.bounding_box == rect }}
  end

  def split_children
    # DEBUG "examining split_children call"
    # DEBUG "children:"
    # DEBUG @children
    data = @children.map(&:bounding_box)
    # DEBUG "data:"
    # DEBUGPP data
    axis = choose_split_axis(data)
    # DEBUG "axis: #{axis}"
    distribution = choose_split_index(data,axis)
    # DEBUG "distribution:"
    # DEBUGPP distribution
    children_dist = distribution.map { |group| find_children(group) }
    # DEBUG "children_dist:"
    # DEBUGPP children_dist
    new_node = Node.new(@tree)
    # children_dist[0].each { |child| new_node.just_add_child(child) }
    new_node.children = children_dist[0]
    @children = children_dist[1]
    get_parent.add_child(new_node)
    update_boxes
    new_node.update_boxes
  end

  def split
    if leaf?
      split_data
    else
      split_children
    end
  end

  def join
        
  end
end

if __FILE__ == $0
  $node = Node.new(Tree.new(2,5,3))
  $rect = Rectangle.new([[10, 20], [40, 30]])
  $rect2 = Rectangle.new([[10, 20], [30, 40]])
  $node.insert_data($rect)
end
