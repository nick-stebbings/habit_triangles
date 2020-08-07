# lINKEDLIST  Implementation for hAppy Habit Triangles

Node = Struct.new(:today, :yest)

module NodeOperations

  def push(current_day_completed)
    self.head_node = Node.new(current_day_completed, head_node)
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
  
  def each_node_completed?
    head_node.each do |current_node|
      yield(current_node.today)  
    end
    head_node
  end

  # Fill in days between last day completed and today
  def update_to_today! 
    #Compare julian days
    days_left = Date.today.jd - date_of_initiation.jd 
    (days_left - length).times { push('f') } unless length == days_left
  end
end

class Habit
  attr_reader :id, :name
  attr_accessor :aspect, :description, :is_atomic
  attr_accessor :date_of_initiation, :head_node

  include NodeOperations
  include Enumerable
  require 'date'

  def initialize(id, name, **options)
    options = {
      aspect: '#a-default-tag',
      description: 'A generic description',
      is_atomic: false,
    }.merge(options) 

    @id = id
    @name = name
    @aspect = options[:aspect]
    @description = options[:description]
    @is_atomic = options[:is_atomic]
    @date_of_initiation = Date.today
    @head_node = push('f')
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
  
  def each
    current_node = head_node
    while current_node
      yield(current_node) if block_given?
      current_node = current_node.yest
    end
    head_node
  end
end