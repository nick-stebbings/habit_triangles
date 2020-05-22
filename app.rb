require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

require 'pry-remote'
require 'yaml'
require_relative 'lib/habit'
require_relative 'lib/goal'

set :port, 9889
OOT = File.expand_path('..', __FILE__)
TEXT = YAML.load_file(ROOT + '/public/paragraphs_text.yaml')

MESSAGES = {
  invalid_goal_name: "You entered an invalid goal name. Please try to summarise in up to 5 words, split with spaces.",
  invalid_habit_name: "You entered an invalid habit name. Please try to summarise in up to 5 words, split with spaces.",
  invalid_habit_description: "You entered an invalid habit description. Please limit it to 50 characters or less.",
  invalid_date_of_initiation: "You entered an invalid date, it is in the future!",
  invalid_aspect_tag: "You entered an invalid tag. The format should be #this-is-a-tag"
}
def set_session_variables
  session[:goals] ||= {}
  session[:habits] = session[:goals].each_with_object([]) { |(goal_name, goal), habits_list| habits_list << goal.habits }.uniq.flatten
end

before do
  set_session_variables
end

configure do
  enable :sessions
  set :session_secret, 'habit'
  set :erb, :escape_html => true
end

def get_habit(id)
  session[:habits].find { |habit| habit.id == id }
end

def get_goal(id)
  session[:goals].values.first { |goal| goal.id == id }
end

def get_next_id(of)  # Return next id in overall goals hash/habits ary
    case of
    when :goal
      max = session[:goals].values.map { |goal| goal.id }.max || 0
    when :habit
      max = session[:habits].map { |habit| habit.id }.max || 0
    end
    max + 1
end

def valid_goal_name?(phrase)
  phrase.match? %r{^(?:\w* ){0,4}\w+$} # Matches 'up to five words split by a space' format
end

def valid_habit_description?(phrase)
  phrase.length < 50
end

def valid_date?(initiation)
  initiation.is_a?(DateTime) ? (initiation.jd <= DateTime.now.jd) : nil
end

def valid_aspect?(tag)
  tag.match? %r{^#(?:\w*-){0,8}\w+$} # Matches #this-is-a-tag format with at most 8 dashes
end

def get_goal_key_by_habit(id)
  
  session[:goals].each { |goal_name, goal| return goal_name if goal.habits.find { |habit| habit.id == id } }
  nil
end

def calculate_streak(habit)
  count = 0
  habit.each_node_completed? do |node_data|
    break unless node_data
    count +=1
  end
  count
end

helpers do
  def in_paragraphs(text)
    text.split("\n").map { |para| "<p>#{para}</p>" }.join
  end

  def snake_case(phrase)
    phrase.downcase.split(' ').join('_')
  end
end

not_found do
  redirect "/"
end

get "/" do
  if session[:goals].empty?
    @page_title = 'Introduction'
    @intro_spiel = TEXT[:intro_page][:first]
    erb :intro
  else
    current_goal = session[:goals].values.min_by { |goal| goal.id } #this criteria will change
    redirect "/goals/#{current_goal.id}"
  end
end

post "/" do
  if valid_goal_name?(params[:goal_name].strip)
    # Once a valid goal name has been entered, convert it to a label to use as a hash key in session[:goals]
    goal_name = snake_case(params[:goal_name].strip)
    # Instantiate a new goal with 3 new habits, redirect to flesh out the first habit
    goal_id = get_next_id(:goal) 
    #/ Change the habit's IDs to be goal specific ?"#{goal_id}_#{i}"
    session[:goals][goal_name] = Goal.new(goal_id, Array.new(3){ |i| Habit.new(i, goal_name + "_cornerstone_#{i}") }, goal_name.strip )

    session[:goals][goal_name].habits.each do |habit|
      session[:habits] << habit
    end
    
    first_habit = session[:goals][goal_name].habits.first
    redirect "/habits/#{first_habit.id}/update?initial=true"
  else
    session[:message] = MESSAGES[:invalid_goal_name]
    halt 422, erb(:error) if session[:message]
    redirect "/#enter_goal" #how to fragment redirect?
  end
end

get "/habits/:id" do |id|
  @habit = get_habit(id.to_i)
  halt 404 unless @habit
  erb :existing_habit
end

get "/goals/:id" do |id|
  @goal = get_goal(id.to_i)
  session[:goals].keys
end

get "/habits/:id/update" do |id|
  @habit = get_habit(id.to_i)
  @first_habit = !!params[:initial]
  if @first_habit
    @intro_spiel = TEXT[:new_habit][:referred]
  else
    @intro_spiel = 'This is just an old habit.'
  end
  erb :new_habit
end

post "/habits/:id/update" do |id|
  @habit = get_habit(id.to_i)
  
  session[:message] = MESSAGES[:invalid_habit_description] unless valid_habit_description?(params[:habit_description])
  session[:message] = MESSAGES[:invalid_aspect_tag] unless valid_aspect?(params[:aspect_tag])
  date = DateTime.parse(params[:date_of_initiation]).new_offset if params[:date_of_initiation]
  # binding.pry
  session[:message] = MESSAGES[:invalid_date_of_initiation] unless valid_date?(date)
  if session[:message]
    halt 422, erb(:error)
  else
    @habit.description = params[:habit_description].strip
    @habit.date_of_initiation = date
    @habit.aspect = params[:aspect_tag]
    @habit.head_node.today = !!(params[:completed_today] == 'false')
  end

  redirect "/habits/#{id}"
end

post "/habits/:id/delete" do |id|
  goal = session[:goals][get_goal_key_by_habit(id.to_i)]
  binding.pry
  goal.habits.delete_if { |habit| habit.id == id.to_i}
  session[:habits].delete_if { |habit| habit.id == id.to_i }
  redirect "/goals/#{goal.id}"
end












