# objective.rb

class Objective
  attr_accessor :id, :habits, :name, :description
  def initialize(id, habits, name = 'An objective', description = 'Describe your habit')
    @id = id
    @habits = habits
    @name = name
    @description = description
  end
end