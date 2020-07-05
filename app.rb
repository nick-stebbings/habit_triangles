require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'redcarpet'
require 'yaml'
require 'uri'

require_relative 'lib/habit'
require_relative 'lib/objective'

# require 'pry-remote'

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
  def get_task_list(habit_id, habit_list_id)
    session[:lists].find { |l| (l[:habit_id] = habit_id) && (l[:habit_list_id] == habit_list_id) }
  end

  def incomplete_tasks(habit_id, habit_list_id)
    get_task_list(habit_id, habit_list_id)[:todos].reject { |task| task[:completed] }.size
  end

  # After checking if a list is in a completed state, redirect accordingly
  def completed_list_redirection(habit_id, habit_list_id)
    new_url_string = "/list/#{habits_last_list(habit_id)[:habit_list_id]}/complete_all"
    incomplete_tasks(habit_id, habit_list_id).zero? ? new_url_string : ""
  end

  def reset_list!(list)
    list[:todos].each { |t| t[:completed] = false }
  end

  # def incomplete_tasks_string(habit_id, habit_list_id)
  #   "#{incomplete_tasks(habit_id, habit_list_id)}/#{list_size(habit_list_id)}"
  # end

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
  also_reload "paragraphs_text.yaml" if development?
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
    max = session[:objectives].values.map { |objective| objective.id }.max || -1
  when :habit
    max = session[:habits].map { |habit| habit.id }.max || -1
  end
  max + 1
end

def habits_last_list(habit_id)
  all_lists_for_habit = session[:lists].select do |list|
    list[:habit_id] == habit_id
  end
  all_lists_for_habit.max_by { |l| l[:habit_list_id] }
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

def list_exists?(habit_id, h_list_id)
  session[:lists].any? { |l| l[:habit_id] == habit_id && l[:habit_list_id] == h_list_id}
end

def update_habit_after_list_completed!(habit_id, node_index)
  node = get_habit(habit_id).get_nth(node_index)
  return nil if node.today == 't'
  node.today = 't'
end

def calculate_streak(habit)
  count = 0
  habit.each_node_completed? do |node_data|
    break unless node_data == 't'
    count +=1
  end
  count
end

# old helpers do
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
  # if session[:objectives].empty?
    @page_title = 'Happy Habit Triangles'
    @intro_spiel = render_markdown(TEXT[:intro_page][:first])
    erb :index
  # else
  #   current_objective = session[:objectives].values.min_by { |objective| objective.id } #this criteria will change
  #   redirect "/objectives/#{current_objective.id}"
  # end
end

post "/" do # Process front page choice of new objective or new habit
  # We pass a query parameter to indicate first app use to lead the user through
  first_habit = nil

  if !!params[:objective_name] && valid_objective_name?(params[:objective_name].strip)
    # Once a valid objective name has been entered, convert it to a label to use as a hash key in session[:objectives]
    objective_name = snake_case(params[:objective_name].strip)
    # Instantiate a new objective with 3 new habits, redirect to a page to flesh out the first habit
    objective_id = get_next_id(:objective) 

    # Add 3 new habits to a new objective instance
    new_habit_ary = Array.new(3) do |i|
      habit_id = get_next_id(:habit) + i
      habit_name = objective_name + "_cornerstone_#{i}"
      opt = { aspect: params[:aspect_tag] }

      Habit.new(habit_id, habit_name, opt) 
    end
    session[:objectives][objective_name] = Objective.new(objective_id, new_habit_ary, objective_name)

    # Add them to the overall habit list, too
    session[:objectives][objective_name].habits.each do |habit|
      session[:habits] << habit
    end
    # Our first habit to flesh out
    first_habit = session[:objectives][objective_name].habits.first
  elsif !!params[:habit_description] && valid_habit_description?(params[:habit_description].strip)
    habit_name = snake_case(params[:habit_description])
    # Out only habit to flesh out
    first_habit = Habit.new(get_next_id(:habit), habit_name, aspect: params[:aspect_tag])
    # Add it to the overall habit list
    session[:habits] << first_habit
  else
    session[:message] = MESSAGES[:invalid_objective_name]
    halt 422, erb(:index) if session[:message]
  end
  redirect "/habits/#{first_habit.id}/update?initial=true"
end

get "/objectives/:id/update" do |id|
  @objective = get_objective(id.to_i)
  @habits = @objective.habits

  @page_tite = "List of Habits"
  @intro_spiel = "This dashboard allows you to take a quick glance at a list of habits - those linked by objective or all habits in the system."
  @sub_info = "This is a list of habits for the objective named <b>#{@objective.name}</b>."
  
  erb :update_objective, :layout => :layout
end

get "/objectives/:id" do |id|
  @objective = get_objective(id.to_i)

  @page_tite = "List of Habits"
  @intro_spiel = "This dashboard allows you to take a quick glance at a list of habits - those linked by objective or all habits in the system."
  @sub_info = "This is a list of habits for the objective named <b>#{@objective.name}</b>."
  erb :index_habits, :layout => :simple_layout
end

get "/objectives/:id/update" do |id|
  @objective = get_objective(id.to_i)
  @page_title = "Objective Summary"
  @intro_spiel = "This is a list of habits for the objective named <b>#{@objective.name}</b>."
  erb :update_objective, :layout => :simple_layout
end

get "/habits" do
  @page_title = "List of Habits"
  @intro_spiel = "This is a list of all habits."
  @habits = session[:habits]
  erb :index_habits, :layout => :simple_layout
end

# depreciated, creating single habits is not the point
# get "/habits/new" do
#   @atomic = false
#   @page_title = 'Create a new Habit'
#   erb :new_habit
# end

get "/habits/:id" do |id|
  @habits = [get_habit(id.to_i)]
  halt 404 unless @habits

  @page_title = "Habit Overview"
  @intro_spiel = "This is the summary information for your habit with identifier <b>#{@habits.first.name}.</b>"
  erb :index_habits, :layout => :simple_layout
end

get "/habits/:id/update" do |id|
  @habit = get_habit(id.to_i)
  
  @intro_spiel = params[:initial] ? TEXT[:existing_habit][:new] : 'This is just an old habit.'
  @sub_info = render_markdown(TEXT[:existing_habit][:sub_info])
  @page_title = "Update Habit Summary"
  erb :update_habit, :layout => :simple_layout
end

post "/habits/:id" do |id|
  redirect "/habits/#{id}"
end

post "/habits/:id/update" do |id|
  @habit = get_habit(id.to_i)
  @intro_spiel = params[:initial] ? TEXT[:existing_habit][:new] : TEXT[:existing_habit][:old]
  @sub_info = render_markdown(TEXT[:existing_habit][:sub_info]) 
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
    @habit.is_atomic = (params[:is_atomic] == 'on')
    @habit.update_to_today! 
    list_id = @habit.length - 1
    
    if @habit.is_atomic && !list_exists?(id, list_id)
      @intro_spiel = "This is some action list intro."
      
      last_list = habits_last_list(id.to_i)
      
      last_todos = last_list[:todos] unless last_list.nil?
      new_list_duplicate = { habit_id: id.to_i, todos: (last_todos || []), habit_list_id: (!last_list ? 0 : list_id) }
      reset_list!(new_list_duplicate)
      session[:lists] << new_list_duplicate unless list_exists?(id.to_i, list_id)
      redirect "/habits/#{id}/list/#{new_list_duplicate[:habit_list_id]}" 
    end
  end
  redirect "/habits/#{id}"
end

post "/habits/:id/delete" do |id|
  objective = session[:objectives][get_objective_key_by_habit(id.to_i)]
  objective.habits.delete_if { |habit| habit.id == id.to_i}
  session[:habits].delete_if { |habit| habit.id == id.to_i }
  redirect "/objectives/#{objective.id}"
end

## Fractal Habit Triangle

get /\/habits\/fractal((\/(?:\d{1,})){1,})/ do
  # Split habit_id parameters into an array of integers
  habits_in_chain = params['captures'].first.split("/")[1..-1].map(&:to_i)
  @habits = habits_in_chain.map { |id| get_habit(id) }
  @habits.each { |h| h.update_to_today! }
  @length_of_habit = @habits.first.length

  @intro_spiel = render_markdown(params[:initial] ? TEXT[:existing_habit][:new] : TEXT[:existing_habit][:old])
  @page_title = "Fractal Habit Triangle"
  @reference_date = @habits.max_by { |h| h.length }.date_of_initiation
  erb :fractal
end

post /\/habits\/fractal((\/(?:\d{1,})){1,})/ do
  habits_in_chain = params['captures'].first.split("/")[1..-1].map(&:to_i)
  @habits = habits_in_chain.map { |id| get_habit(id) }

  @habit = @habits.first
  day_toggle_switch_value = ("completed-day-" + params[:node_completed_index])
  habit_node_for_day = @habit.get_nth(params[:node_completed_index].to_i)
  habit_node_for_day.today = params.key?(day_toggle_switch_value) ? 't' : 'f'
  redirect "/habits/fractal/#{@habit.id}"
end

## Todo List Modular Routes

# Create a new list attached to Atomic Habit id
# post "/habits/:id/list" do |id|
#   list_name = params[:habit_name].strip
#   session[:lists] << { name: list_name, todos: []}
#   session[:message] = "The list has been created."  
#   redirect "/habits/#{id}" 
# end

# View a list
get "/habits/:habit_id/list/:list_id" do |habit_id, list_id|
  @page_title = "View Habit Actions"
  @habit_id = habit_id.to_i
  @list_id = list_id.to_i
  @name = get_habit(habit_id.to_i).name
  @list = get_task_list(@habit_id, @list_id)
  
  erb :list, :layout => :list_layout
end

# Complete all tasks on a list
post "/habits/:habit_id/list/:list_id/complete_all" do |habit_id, list_id|
  @habit_id = habit_id.to_i
  @list_id = list_id.to_i
  @list = get_task_list(@habit_id, @list_id)

  @list[:todos].each do |task|
    task[:completed] = true
  end
  length_of_habit = get_habit(@habit_id).length
  update_habit_after_list_completed!(@habit_id, length_of_habit - @list_id - 1)
  session[:message] = 'List marked as complete.'
  redirect "/habits/fractal/#{@habit_id}"
end

# Mark an existing task as completed
post "/habits/:habit_id/list/:list_id/actions/:task_id" do |habit_id, list_id, task_id|
  @habit_id = habit_id.to_i
  @list_id = list_id.to_i
  @list = get_task_list(@habit_id, @list_id)

  task = @list[:todos][task_id.to_i]
  task[:completed] = !!(params[:completed] == 'true')
  session[:message] = 'The task has been updated'

  redirect "/habits/#{habit_id}/list/#{@list_id}"
end

# Add an action to an existing list
post "/habits/:habit_id/list/:list_id/actions" do |habit_id, list_id|
  @habit_id = habit_id.to_i
  @list_id = list_id.to_i
  @list = get_task_list(@habit_id, @list_id)
  todo_text = params[:todo].strip

  error = error_for_todo(todo_text)
  if error
    session[:message] = error
    erb :list, layout: :list_layout
  else
    @list[:todos] << { name: todo_text, completed: false }
    session[:message] = "The task has been added."  
    redirect "/habits/#{habit_id}/list/#{list_id}"
  end
end

# Delete existing task
post "/habits/:habit_id/list/:list_id/actions/:task_id/delete" do |habit_id, list_id, task_id|
  get_task_list(habit_id.to_i, list_id.to_i)[:todos].delete_at(task_id.to_i)
  session[:message] = "The task has been deleted."
  redirect "/habits/#{habit_id}/list/#{list_id}"
end
