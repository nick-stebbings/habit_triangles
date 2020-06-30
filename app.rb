require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'
require 'yaml'
require 'uri'

require_relative 'lib/habit'
require_relative 'lib/objective'

require 'pry-remote'

ROOT = File.expand_path('..', __FILE__)
TEXT = YAML.load_file(ROOT + '/public/paragraphs_text.yaml')

MESSAGES = {
  invalid_objective_name: "You entered an invalid objective name. Please try to summarise in up to 5 words, split with spaces.",
  invalid_habit_name: "You entered an invalid habit name. Please try to summarise in up to 5 words, split with spaces.",
  invalid_habit_description: "You entered an invalid habit description. Please limit it to 50 characters or less.",
  invalid_date_of_initiation: "You entered an invalid date, it is in the future!",
  invalid_aspect_tag: "You entered an invalid tag. The format should be #this-is-a-tag"
}

def set_session_variables
  session[:objectives] ||= {}
  session[:lists] ||= []
  session[:habits] ||= session[:objectives].each_with_object([]) { |(objective_name, objective), habits_list| habits_list << objective.habits }.uniq.flatten
end

# For list module
helpers do
  def get_task_list(list_idx)
    session[:lists][list_idx][:todos]
  end

  def list_completed?(list_idx)
    tasks = get_task_list(list_idx)
    tasks.all? { |task| task[:completed] } && tasks.size > 0
  end  

  def incomplete_tasks(list_idx)
    get_task_list(list_idx).reject { |task| task[:completed] }
  end

  def incomplete_tasks_string(list_idx)
    "#{incomplete_tasks(list_idx).size}/#{list_size(list_idx)}"
  end

  def list_size(list_idx)
    get_task_list(list_idx).size
  end

  def sort_lists(list)
    completed = 
    {  false: [],
        true: []
    }
    list.each_index do |idx|
      list_completed?(idx) ? completed[:true].push(idx) : completed[:false].push(idx) 
    end

    completed.each do |_, arr|
      list.each_with_index do |list, idx|
        yield(list, idx) if arr.include?(idx)
      end
    end
  end

  # Sort Todos on a list by "completed". 
  def sort_todos(list)
    complete, incomplete = list.partition{ |task| task[:completed] }

    incomplete.each{ |task| yield(task, list.index(task)) }
    complete.each{ |task| yield(task, list.index(task)) }
  end

  # Return an error message if the name is invalid, otherwise return nil.
  def error_for_list_name(name)
    if !(1..100).cover? name.size   
      "The list name must be between 1 and 100 characters"
    elsif session[:lists].any? {|list| list[:name] == name }
      "The list name must be unique."
    end
  end

  # Return an error message if the Todo is invalid, otherwise return nil.
  def error_for_todo(text)
    if !(1..100).cover? text.size   
      "The task must be between 1 and 100 characters"
    end
  end
  
end

configure do
  enable :sessions
  set :session_secret, 'habit'
  set :erb, :escape_html => true
  also_reload "paragraphs_text.yaml"
end

def get_habit(id)
  session[:habits].find { |habit| habit.id == id }
end

def get_objective(id)
  session[:objectives].values.first { |objective| objective.id == id }
end

def get_next_id(of)  # Return next id in overall objectives hash/habits ary
    case of
    when :objective
      max = session[:objectives].values.map { |objective| objective.id }.max || 0
    when :habit
      max = session[:habits].map { |habit| habit.id }.max || 0
    end
    max + 1
end

def valid_objective_name?(phrase)
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

def get_objective_key_by_habit(id)
  session[:objectives].each { |objective_name, objective| return objective_name if objective.habits.find { |habit| habit.id == id } }
  nil
end

def calculate_streak(habit)
  count = 0
  habit.each_node_completed? do |node_data|
    break unless node_data == 't'
    count +=1
  end
  count
end

# helpers do
  def in_paragraphs(text)
    text.split("\n").map { |para| "<p>#{para}</p>" }.join
  end

  def snake_case(phrase)
    phrase.downcase.split(' ').join('_')
  end
  
  def render_markdown(text)
    renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    renderer.render(text)
  end
# end

before do
  set_session_variables
end

not_found do
  @page_title = "Page Not Found"
  @intro_spiel = "Your page does not exist, did you try to access a wrong habit or objective?"
  erb :error, :layout => :simple_layout
end

error do
  @page_title = "Error"
  @intro_spiel = "An error occurred."
  erb :error, :layout => :simple_layout
end

get "/" do
  if session[:objectives].empty?
    @page_title = 'Happy Habit Triangles'
    @intro_spiel = render_markdown(TEXT[:intro_page][:first])
    erb :index
  else
    current_objective = session[:objectives].values.min_by { |objective| objective.id } #this criteria will change
    redirect "/objectives/#{current_objective.id}"
  end
end

post "/" do # Process front page choice of new objective or new habit
            # We pass a query parameter to indicate first app use to lead the user through
  first_habit = nil

  if !!params[:objective_name] && valid_objective_name?(params[:objective_name].strip)
    # Once a valid objective name has been entered, convert it to a label to use as a hash key in session[:objectives]
    objective_name = snake_case(params[:objective_name].strip)
    # Instantiate a new objective with 3 new habits, redirect to a page to flesh out the first habit
    objective_id = get_next_id(:objective) 

    session[:objectives][objective_name] = Objective.new(objective_id, Array.new(3){ |i| Habit.new(get_next_id(:habit) + i, objective_name + "_cornerstone_#{i}") }, objective_name.strip )
    session[:objectives][objective_name].habits.each do |habit|
      session[:habits] << habit
    end # Added 3 new habits to the objective object
    
    first_habit = session[:objectives][objective_name].habits.first
  elsif !!params[:habit_description] && valid_habit_description?(params[:habit_description].strip)
    habit_name = snake_case(params[:habit_description])
    first_habit = Habit.new(get_next_id(:habit), habit_name, first_day_completed: true)
    session[:habits] << first_habit
  else
    session[:message] = MESSAGES[:invalid_objective_name] # // get this to choose a relevant message
    halt 422, erb(:index) if session[:message]
  end
  redirect "/habits/#{first_habit.id}/update?initial=true"
end

get "/objectives/:id/update" do |id|
  @objective = get_objective(id.to_i)
  @habits = @objective.habits

  erb :update_objective
end

get "/objectives/:id" do |id|
  @objective = get_objective(id.to_i)

  @page_title = "List of Habits"
  @intro_spiel = "This is a list of habits for the objective named <b>#{@objective.name}</b>."
  erb :list_habits, :layout => :simple_layout
end

# depreciated, creating single habits is not the point
# get "/habits/new" do
#   @atomic = false
#   @page_title = 'Create a new Habit'
#   erb :new_habit
# end

get "/habits/:id" do |id|
  @habit = get_habit(id.to_i)
  halt 404 unless @habit

  @page_title = "Habit Overview"
  @intro_spiel = "This is the summary information for your habit with identifier <b>#{@habit.name}.</b>"
  erb :existing_habit, :layout => :simple_layout
end

get "/habits/:id/update" do |id|
  @habit = get_habit(id.to_i)
  
  @intro_spiel = params[:initial] ? TEXT[:existing_habit][:new] : 'This is just an old habit.'
  @sub_info = TEXT[:existing_habit][:sub_info]
  @page_title = "Update Habit Summary"
  erb :update_habit, :layout => :simple_layout
end

get /\/habits\/fractal((\/(?:\d{1,})){1,})/ do
  # Split habit_id parameters into an array of integers
  habits_in_chain = params['captures'].first.split("/")[1..-1].map(&:to_i)

  @habits = habits_in_chain.map { |id| get_habit(id) }
  @habits.each { |h| h.update_to_today! }
  binding.pry

  @intro_spiel = render_markdown(params[:initial] ? TEXT[:existing_habit][:new] : TEXT[:existing_habit][:old])
  @page_title = "Fractal Habit Triangle"
  @reference_date = @habits.max_by { |h| h.length }.date_of_initiation
  erb :fractal
end

post /habits\/fractal((?:\/(?:\d{1,})){1,})/ do |id|
  @habit = get_habit(id.to_i)
  day_toggle_switch_value = ("completed-day-" + params[:node_completed_index]).to_sym
  habit_node_for_day = @habit.get_nth(params[:node_completed_index].to_i)
  
  habit_node_for_day.today = params.key?(day_toggle_switch_value) ? 't' : 'f'
  redirect "/habits/fractal/#{id}"
end

post "/habits/:id/update" do |id|
  @habit = get_habit(id.to_i)
  @intro_spiel = params[:initial] ? TEXT[:existing_habit][:new] : TEXT[:existing_habit][:old]
  @sub_info = TEXT[:existing_habit][:sub_info]
  @page_title = "Update Habit Summary"

  session[:message] = MESSAGES[:invalid_habit_description] unless valid_habit_description?(params[:habit_description])
  session[:message] = MESSAGES[:invalid_aspect_tag] unless valid_aspect?(params[:aspect_tag])
  date = DateTime.parse(params[:date_of_initiation]).new_offset if params[:date_of_initiation]
  session[:message] = MESSAGES[:invalid_date_of_initiation] unless valid_date?(date)

  if session[:message]
    halt erb :update_habit, :layout => :simple_layout 
  else
    @habit.description = params[:habit_description].strip
    @habit.date_of_initiation = date
    @habit.aspect = params[:aspect_tag].strip
    # @habit.head_node.today = (params[:completed_today] == 't') ? 't' : 'f'
  end

  redirect "/habits/#{id}"
end

post "/habits/:id/delete" do |id|
  objective = session[:objectives][get_objective_key_by_habit(id.to_i)]
  objective.habits.delete_if { |habit| habit.id == id.to_i}
  session[:habits].delete_if { |habit| habit.id == id.to_i }
  redirect "/objectives/#{objective.id}"
end

## Todo List Modular Routes

# Create a new list attached to Atomic Habit id
post "/habits/:id/lists" do |id|
  list_name = params[:habit_name].strip
  session[:lists] << { name: list_name, todos: []}
  session[:message] = "The list has been created."  
  redirect "/habits/#{id}" 
end

# View a list
get "/lists/:id" do
  @page_title = "View Habit Actions"
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  erb :list, :layout => :list_layout
end

# Delete existing List
post "/lists/:id/delete" do
  id = params[:id].to_i
  session[:lists].delete_at(id)
  session[:message] = "The list has been deleted."
  redirect "/lists"
end

# Complete all tasks on a list
post "/lists/:id/complete_all" do |id|
  id = id.to_i
  @list = session[:lists][id]

  @list[:todos].each do |task|
    task[:completed] = true
  end

  session[:message] = 'List marked as complete.'
  redirect "/lists/#{id}"
end

# Add an action to an existing list
post "/lists/:list_id/actions" do |list_id|
  @list_id = list_id.to_i
  @list = session[:lists][@list_id]
  todo_text = params[:todo].strip

  error = error_for_todo(todo_text)
  if error
    session[:message] = error
    erb :list, layout: :list_layout
  else
    @list[:todos] << { name: todo_text, completed: false }
    session[:message] = "The task has been added."  
    redirect "/lists/#{@list_id}"
  end
end

# Mark an existing list as completed
post "/lists/:list_id/actions/:task_id" do |list_id, task_id|
  @list_id = list_id.to_i
  @list = session[:lists][@list_id]
  task = @list[:todos][task_id.to_i]
  is_completed = !!(params[:completed] == 'true')
  task[:completed] = is_completed
  session[:message] = 'The task has been updated'
  redirect "/lists/#{list_id}"
end

# Delete existing task
post "/lists/:list_id/actions/:task_id/delete" do
  list_id = params[:list_id].to_i
  task_id = params[:task_id].to_i

  session[:lists][list_id][:todos].delete_at(task_id)
  session[:message] = "The task has been deleted."
  redirect "/lists/#{list_id}"
end










