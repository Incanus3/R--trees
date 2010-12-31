################################################################################
require 'node'

class Tree
  attr_accessor :min,:max,:dimension, :root # DEBUG, root odstranit

  def initialize(min,max,dimension)
    @min = min
    @max = max
    @dimension = dimension
    @root = Node.new(self)
  end

  def insert(data)
    choose_node(data).insert_data(data)
  end

  def delete(data)
    node = find(data)
    if node
      node.delete_data(data)
    end
  end

  def export(path)
    puts "exporting tree..." # DEBUG
    file = File.open(path,"w")
    file.puts("digraph G {")
    @root.export(file)
    file.puts("}")
    file.close
    puts "tree exported" # DEBUG
  end

  def export_rects(path)
    puts "exporting rectangles..."
    file = File.open(path,"w")
    file.puts("beginfig(1);")
    @root.export_rects(file)
    file.puts("endfig;")
    file.puts("end")
    puts "rectangles exported"
  end

  def to_s
    "#<#{self.class.name}:#{object_id} @min=#{@min} @max=#{max} " +
      "@dimenion=#{@dimension}>"
  end

  def inspect
    to_s
  end

  # executes given block for every node in the tree (depth-first traversal)
  def each(node = @root, &block)
    yield(node)
    node.children.each {|child| each(child, &block)}
    nil
  end

  def print_tree
    each do |node|
      puts "#{node.object_id} -> " +
        (node.children.empty? ? "no children" :
         node.children.map {|child| child.object_id}.join(', '))
      if node.data.empty?
        puts " no data"
      else
        node.data.each {|data| puts " " + data.to_s}
      end
      puts
    end
    self
  end

  private
  # could be written much shorter and more effective,
  # but it would be much less readable
  # emacs indents case awefully, don't use tab to indent this method
  def better_child(parent,child1,child2,data)
    # DEBUG "better_child called" #(#{parent},#{child1},#{child2},#{data}) called"
    overlap_enlargement1 = parent.child_overlap_enlargement(child1,data)
    overlap_enlargement2 = parent.child_overlap_enlargement(child2,data)
    # DEBUG "blah"
    area_enlargement1 = child1.box_area_enlargement(data)
    area_enlargement2 = child2.box_area_enlargement(data)
    area1,area2 = child1.box_area,child2.box_area

    val = case
      when overlap_enlargement1 < overlap_enlargement2 : child1
      when overlap_enlargement1 > overlap_enlargement2 : child2
      else # overlap_enlargement1 == overlap_enlargement2
        case
          when area_enlargement1 < area_enlargement2 : child1
          when area_enlargement1 > area_enlargement2 : child2
          else # area_enlargement1 == area_enlargement2
            (area1 <= area2) ? child1 : child2
        end
    end
    # DEBUG "better_child finished"
    val
  end

  def better_subtree(node1,node2,data)
    # DEBUG "better_subtree called"
    area_enlargement1 = node1.box_area_enlargement(data)
    area_enlargement2 = node2.box_area_enlargement(data)
    area1,area2 = node1.box_area,node2.box_area
    area_enlargement1 < area_enlargement2 ||
      (area_enlargement1 == area_enlargement2 &&
       area1 < area2) ? node1 : node2
  end

  def choose_subtree(node,data)
    # DEBUG "choose_subtree(#{node},#{data}) called"
    # DEBUG "children:"
    # DEBUGPP node.children
    if node.children_are_leaves?
      node.children.reduce {|child1,child2| better_child(node,child1,child2,data)}
    else
      node.children.reduce {|child1,child2| better_subtree(child1,child2,data)}
    end
  end

  def choose_node(data)
    # DEBUG "choose_node(#{data}) called"
    node = @root
    until(node.leaf?)
      node = choose_subtree(node,data)
    end
    # DEBUG "choose_node finished"
    node
  end
end

def prepare
  $tree = Tree.new(2,5,2)
  srand(Time.now.to_i)
  $rects = []

  100.times do
    x = rand(70)
    y = rand(70)
    rect = Rectangle.new([[x,x + rand(30)],[y,y + rand(30)]])
    $rects << rect
  end
end

def run
  prepare()

  100.times do |i|
    $tree.insert($rects[i])
    $tree.export(format("tree%03d.dot", i))
  end
  
  puts
  puts "Tree created, printing"
  puts "Format: node -> children"
  puts " data"
  puts

  $tree.print_tree
end

$counter = 0

def step
  if $counter == 0
    prepare()
  end

  $tree.insert($rects[$counter])
  $tree.print_tree
  $counter += 1
end

