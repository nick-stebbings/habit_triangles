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
  
  def each_node_completed?
    current_node = head_node
    while current_node
      yield(current_node.today)
      current_node = current_node.yest
    end
    head_node
  end
end

class Habit
  attr_accessor :id, :name, :aspect, :description, :date_of_initiation, :head_node
  include NodeOperations
  include Enumerable
  require 'date'

  def initialize(id, name, aspect: '#', description: 'A habit', first_day_completed: false, existing_habit_history: nil)
    @id = id
    @name = name
    @aspect = aspect
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
