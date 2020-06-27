# lINKEDLIST  Implementation for hAppy Habit Triangles

Node = Struct.new(:today, :yest)

module NodeOperations

  def push(current_day, history = nil)
    self.head_node = Node.new(current_day.to_s, (history || head_node))  # Push onto another habit history or the head node of the current LL
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

  # Fill in days between last day completed and today
  def update_to_today! 
    days_left = Date.today.jd - date_of_initiation.jd
    (days_left - length).times { push('f') } unless length == days_left
  end
end

class Habit
  attr_accessor :id, :name, :aspect, :description, :date_of_initiation, :head_node
  include NodeOperations
  include Enumerable
  require 'date'
=begin   TODO - rearrange instantiations around the following 'options hash' format for readability.
  def initialize(id, name, aspect: '#', description: 'A habit', options)
    options = {
      existing_habit_history: nil,
      is_atmomic: false,
      first_day_completed: false
    }.merge(options) 
=end

  def initialize(id, name, aspect: '#', description: 'A habit', first_day_completed: false, existing_habit_history: nil, is_atomic: false)
    @id = id
    @name = name
    @is_atomic = is_atomic
    @aspect = aspect
    @description = description
    @date_of_initiation = Date.today
    @head_node = push((first_day_completed ? 't' : 'f'), existing_habit_history)
  end

  def length
    current_node = head_node
    len = !!current_node.today ? 1 : 0
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
