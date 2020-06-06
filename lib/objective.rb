# objective.rb

class Objective
  attr_accessor :id, :habits, :name
  def initialize(id, habits, name = 'An objective')
    @id = id
    @habits = habits
    @name = name
  end
end