# lINKEDLIST  Implementation for hAppy Habit Triangles

Node = Struct.new(:today, :yest)

module NodeOperations

  def push(current_day, history = nil)
    self.head_node = Node.new(current_day, (history || head_node))  # Push onto another habit history or the head node of the current LL
  end
  
  def each
    current_node = head_node
    while current_node
      yield(current_node)
      current_node = current_node.yest
    end
    head_node
  end
  
  def each_link_completed
    current_node = head_node
    while current_node
      yield(current_node.today)
      current_node = current_node.yest
    end
    head_node
  end
end

class Habit
  attr_accessor :id, :name, :description, :date_of_initiation, :head_node
  include NodeOperations
  include Enumerable
  require 'date'

  def initialize(id, name, first_day_completed = false, description = 'A habit', existing_habit_history = nil)
    @id = id
    @name = name
    @description = description
    @date_of_initiation = Time.now
    @head_node = push(first_day_completed, existing_habit_history)
  end

  def length
    current_node = head_node
    len = current_node.today ? 1 : 0
    while current_node.yest do
      len += 1
      current_node = current_node.yest
    end
    len
  end

  def get_nth(n, node = @head_node)
    node ? n.zero? ? node : get_nth(n - 1, node.yest) : (raise ArgumentError)
  end

  def insert_nth(n, data, head = @head_node)
    @head_node = if n.zero?
                  Node.new(data).tap{ |node| node.yest = head }
                else
                  head.tap{ |node| node.yest = insert_nth(n - 1, data, node.yest) }
                end
  end
  private


    
end
a = Habit.new('eat cheese', true, 'Eat your way to victory')
b = Habit.new('eat  moar cheese', true, 'Eat your way to victory', a.head_node)  # => #<Habit:0x00007fffece0c9e8 @name="eat  moar cheese", @description="Eat your way to victory", @date_of_initiation=2020-05-10 15:35:32.094792 +1200, @head_node=#<struct Node today=true, yest=#<struct Node today=true, yest=nil>>>
  # => #<Habit:0x00007fffece0c9e8
  #     @date_of_initiation=2020-05-10 15:35:32.094792 +1200,
  #     @description="Eat your way to victory",
  #     @head_node=
  #      #<struct Node today=true, yest=#<struct Node today=true, yest=nil>>,
  #     @name="eat  moar cheese">
  b.length  # => 2
  c = b.insert_nth(1, false) # => #<struct Node today=true, yest=#<struct Node today=false, yest=#<struct Node today=true, yest=nil>>>
  b.get_nth(1)  # => #<struct Node today=false, yest=#<struct Node today=true, yest=nil>>
  b.each_link_completed { |bool| puts bool }  # => #<struct Node today=true, yest=#<struct Node today=false, yest=#<struct Node today=true, yest=nil>>>

# >> true
# >> false
# >> true
# >> true
# >> false
# >> true