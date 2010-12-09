################################################################################
require 'rectangle'

class Node
  attr_accessor :children,:data,:parent,:bounding_rect,:id # DEBUG

  # node holds refernce of tree it belongs to, that way every node doesn't
  # have to hold infos about min and max data (children) number and dimension
  # of data stored in tree
  def initialize (tree, parent = nil, id = "") # id - DEBUG
    @tree = tree
    @parent = parent
    @children = []
    @data = []
    @bounding_rect = Rectangle.new(tree.dimension)
    @id = id # DEBUG
  end

  def clone
#    puts "clone called on #{self}" # DEBUG
    new_node = Node.new(@tree, @parent)
    new_node.children = @children.clone
    new_node.data = @data.clone
    new_node.update_box
    new_node
  end
  
  def insert_data (rectangle)
#    puts "\ninsert_data(#{@id}) called" # DEBUG
    return if @data.member?(rectangle)
    @data << rectangle
    update_boxes()
#    split() if @data.length > @tree.max
    self
  end

  def delete_data (rectangle)
    @data.delete(rectangle)
    update_boxes()
#    join() if @data.length < @tree.min
  end

  def export (file,name = "1")
    puts(name) # DEBUG
    file.write("\"#{name}\"[shape=record,label=\"")
    if leaf?
      file.write(([@bounding_rect] + @data).map_meth(:export).join("|"))
    else
      file.write(@bounding_rect.export)
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

  def to_s
    "#<#{self.class.name}:#{object_id} @box=#{@bounding_rect}>"
  end

  def inspect
    to_s
  end

  def leaf?
    @children.empty?
  end
  
  # returns nil if the node itself is leaf
  def children_are_leaves?
    unless leaf?
      @children[0].leaf?
    end
  end

  def box_area
    @bounding_rect.area
  end

  def box_area_enlargement (rect)
    return 0 if (@data + @children).empty?
    if leaf?
      new_area = (@data + [rect]).reduce(:enlarge).area
    else
      new_area = (@children.map_meth(:bounding_rect) +
                  [rect]).reduce(:enlarge).area
    end
    new_area - @bounding_rect.area
  end

  # child_changed parameter is needed for Tree#better_node method
  # where child_overlap after rectangle addition is computed
  # method is called on parent
  def child_overlap (child,child_changed = child)
    child_changed.bounding_rect.
      overlap_area_sum((@children - [child]).map_meth(:bounding_rect))
  end

  # computes enlargement of child node overlap with other children
  # after inserting data rectangle
  # method is called on parent
  def child_overlap_enlargement (child,data)
#    puts "child_overlap_enlargement called on #{child}, #{data}" # DEBUG
    child_overlap(child,child.clone.insert_data(data)) - child_overlap(child)
  end

  def add_child (node)
    return if @children.member?(node)
    @children << node
    node.parent = self
    update_boxes
#    split() if @children.length > @tree.max
  end

################################################################################
  protected
  def update_box
#    puts "update_box(#{@id}) called" # DEBUG
    return if (@data + @children) == []
    if leaf?
      @bounding_rect = @data.reduce(:enlarge)
    else
      @bounding_rect = @children.map_meth(:bounding_rect).reduce(:enlarge)
    end
  end

  def update_parent_box
    return unless @parent
    @parent.update_box
    @parent.update_parent_box
  end

  def update_children_boxes
    @children.each do |child|
      child.update_children_boxes()
      child.update_box()
    end
  end

################################################################################
  private
  def update_boxes
#    puts "update_boxes(#{@id}) called" # DEBUG
    update_children_boxes()
    update_box()
    update_parent_box()
  end

=begin
  def pick_seeds
    @data.combination(2).to_a.reduce { |(rect1,rect2),(rect3,rect4)|
      rect1.enlargement(rect2) > rect3.enlargement(rect4) ?
      [rect1,rect2] : [rect3,rect4] }
  end

  def pick_next (data)

  end
  
  def distribute_entry (group1,group2,entry)

  end

  def split
    seed1,seed2 = pick_seeds
    group1,group2 = [seed1],[seed2]
    remaining = @data.delete(seed1).delete(seed2)
    remaining.each do |data|
      break if(group1.length = @tree.max - @tree.min + 1 ||
               group2.length = @tree.max - @tree.min + 1)
      next_entry = pick_next(remaining)
      distribute_entry(group1,group2,next_entry)
      remaining.delete(next_entry)
    end
  end

  def join
    
  end
=end

end

if __FILE__ == $0
  $node = Node.new(Tree.new(2,5,3))
  $rect = Rectangle.new([[10, 20], [40, 30]])
  $rect2 = Rectangle.new([[10, 20], [30, 40]])
  $node.insert_data($rect)
end
