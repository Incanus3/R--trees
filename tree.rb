################################################################################
require 'node'

class Tree
  attr_reader :min,:max,:dimension, :root # DEBUG, root odstranit

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

  private
  # could be written much shorter and more effective,
  # but it would be much less readable
  # emacs indents case awefully, don't use tab to indent this method
  def better_child(parent,child1,child2,data)
    overlap_enlargement1 = parent.child_overlap_enlargement(child1,data)
    overlap_enlargement2 = parent.child_overlap_enlargement(child2,data)
    area_enlargement1 = child1.box_area_enlargement(data)
    area_enlargement2 = child2.box_area_enlargement(data)
    area1,area2 = child1.box_area,child2.box_area

    case 
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
  end

  def better_subtree(node1,node2,data)
    area_enlargement1 = node1.box_area_enlargement(data)
    area_enlargement2 = node2.box_area_enlargement(data)
    area1,area2 = node1.box_area,node2.box_area
    area_enlargement1 < area_enlargement2 || 
      (area_enlargement1 == area_enlargement2 &&
       area1 < area2) ? node1 : node2
  end

  def choose_subtree(node,data)
    if node.children_are_leaves?
      node.children.reduce {|node1,node2| better_child(node,node1,node2,data)}
    else
      node.children.reduce {|node1,node2| better_subtree(node1,node2,data)}
    end
  end

  def choose_node(data)
    node = @root
    until(node.leaf?)
      node = choose_subtree(node,data)
    end
    node
  end
end

#if __FILE__ == $0
def run
  $tree = Tree.new(2,5,2)

  $nodes = []
  20.times { $nodes << Node.new($tree) }

  $root = $tree.root
  $nodes.values_at(0,1,2).each { |node| $root.add_child(node) }
  $nodes.values_at(3,4,5).each { |node| $root.children[0].add_child(node) }
  $nodes.values_at(6,7,8).each { |node| $root.children[1].add_child(node) }
  $nodes.values_at(9,10,11).each { |node|
    $root.children[1].children[2].add_child(node) }

  $root.id = "1"
  $nodes[0].id = "1.1"
  $nodes[1].id = "1.2"
  $nodes[2].id = "1.3"
  $nodes[3].id = "1.1.1"
  $nodes[4].id = "1.1.2"
  $nodes[5].id = "1.1.3"
  $nodes[6].id = "1.2.1"
  $nodes[7].id = "1.2.2"
  $nodes[8].id = "1.2.3"
  $nodes[9].id = "1.2.3.1"
  $nodes[10].id = "1.2.3.2"
  $nodes[11].id = "1.2.3.3"

  srand(Time.now.to_i)
  $rects = []
  20.times do
    x = rand(70)
    y = rand(70)
    $rects << Rectangle.new([[x,x + rand(30)],[y,y + rand(30)]])
  end
  $rects.each { |rect| $tree.insert(rect) }

  puts
  puts "Tree created, printing"
  puts "Format: node -> children"
  puts "  data"
  puts

  $tree.each do |node|
    puts node.id + " -> " +
      (node.children.empty? ? "no children" :
       node.children.map {|child| child.id}.join(', '))
    if node.data.empty?
      puts "no data"
    else
      node.data.each {|data| puts "  " + data.to_s}
    end
    puts
  end

  $tree
end

# celkem je vlozeno 34 datovych prvku, presto, ze jich bylo vytvoreno jen 20
# bounding_recty neodpovidaji
