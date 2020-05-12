# goal.rb

class Goal
  attr_accessor :id, :habits, :name
  def initialize(id, habits, name = 'A goal')
    @id = id
    @habits = habits
    @name = name
  end
end