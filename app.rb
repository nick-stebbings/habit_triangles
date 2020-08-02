require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'
require 'yaml'
require 'uri'
require 'pry' if development?

require_relative 'lib/habit'
require_relative 'lib/objective'

ROOT = File.expand_path('..', __FILE__)
TEXT = YAML.load_file(ROOT + '/public/paragraphs_text.yaml')

MESSAGES = {
  invalid_objective_name: "You entered an invalid objective name. Please try to summarise in up to 5 words, separated by spaces.",
  invalid_habit_name: "You entered an invalid habit name. Please try to summarise in up to 5 words, split with spaces.",
  invalid_habit_description: "You entered an invalid habit description. Please limit it to 50 characters or less.",
  invalid_date_of_initiation: "You entered an invalid date, it is in the future!",
  invalid_aspect_tag: "You entered an invalid tag. The format should be #this-is-a-tag",
  invalid_task_description: "The task description must be between 1 and 100 characters"
}

def set_session_variables
  session[:objectives] ||= {}
  session[:lists] ||= []
  session[:habits] ||= session[:objectives].each_with_object([]) { |(objective_name, objective), habits_list| habits_list << objective.habits }.uniq.flatten
end

# For list module
helpers do
  ## Getters
  def get_habit(id)
    session[:habits].find { |habit| habit.id == id }
  end

  def get_objective(id)
    session[:objectives].values.first { |objective| objective.id == id }
  end

  def get_next_id(of)
    case of
    when :objective
      max = session[:objectives].values.map { |objective| objective.id }.max || -1
    when :habit
      max = session[:habits].map { |habit| habit.id }.max || -1
    end
    max + 1
  end

  def get_task_list(habit_id, habit_list_id)
    session[:lists].find { |l| (l[:habit_id] == habit_id) && (l[:habit_list_id] == habit_list_id) }
  end

  def get_objective_key_by_habit(id)
    session[:objectives].each { |objective_name, objective| return objective_name if objective.habits.find { |habit| habit.id == id } }
    nil
  end

  def get_last_task_list_for_habit(habit_id)
    all_lists_for_habit = session[:lists].select do |list|
      list[:habit_id] == habit_id
    end
    all_lists_for_habit.max_by { |l| l[:habit_list_id] }
  end

  def number_of_incomplete_tasks(habit_id, habit_list_id)
    get_task_list(habit_id, habit_list_id)[:todos].reject { |task| task[:completed] }.size
  end

  # Redirect accordingly after checking list completed state
  def completed_list_redirection(habit_id, habit_list_id)
    new_url_string = "/list/#{get_last_task_list_for_habit(habit_id)[:habit_list_id]}/complete_all"
    number_of_incomplete_tasks(habit_id, habit_list_id).zero? ? new_url_string : ""
  end

  def mark_all_tasks_completed!(list)
    list[:todos].each do |task|
      task[:completed] = true
    end
  end

  def reset_list_status!(list)
    list[:todos].each { |t| t[:completed] = false }
  end

  # Sort Todos on a list by "completed". 
  def sort_todos(list)
    complete, incomplete = list.partition{ |task| task[:completed] }

    incomplete.each{ |task| yield(task, list.index(task)) }
    complete.each{ |task| yield(task, list.index(task)) }
  end
end

configure do
  enable :sessions
  set :session_secret, 'habit'
  set :erb, :escape_html => true
  also_reload "paragraphs_text.yaml" if development?
end

def valid_objective_name?(phrase)
phrase.match? %r{^(?:\w* ){0,4}\w+$} # Matches 'up to five words split by a space' format
end

def valid_habit_description?(phrase)
  (1..50).cover? phrase.strip.length
end

def valid_date?(initiation)
  initiation.is_a?(DateTime) ? (initiation.jd <= DateTime.now.jd) : nil
end

def valid_aspect?(tag)
  tag.match? %r{^#(?:\w*-){0,8}\w+$} # Matches #this-is-a-tag format with at most 8 dashes
end

  # Return an error message if the Todo is invalid, otherwise return nil.
  def error_for_todo(text)
    MESSAGES[:invalid_task_description] if !(1..100).cover?(text.size)
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

def instantiate_3_habits_in_array(objective_name)
  Array.new(3) do |i|
    habit_id = get_next_id(:habit) + i
    habit_name = objective_name + "_cornerstone_#{i}"
    options = { aspect: params[:aspect_tag] }

    Habit.new(habit_id, habit_name, options) 
  end
end

def valid_input(string, type)
  !!string && (type == :habit ? valid_habit_description?(string) : valid_objective_name?(string))
end

# old helpers do
  def in_paragraphs(text)
    text.split("\n").map { |para| "<p>#{para}</p>" }.join
  end

  def make_identifier(phrase)
    phrase.downcase.split(' ').join('_').strip
  end
  
  def render_markdown(text)
    renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    renderer.render(text)
  end

# end

before do
  set_session_variables
  @intro_spiel ||= ''
  @page_title ||= 'Happy Habit Triangles'
end

not_found do
  @page_title = "Page Not Found"
  @intro_spiel = "Your page does not exist, did you try to access a wrong habit or objective?"
  erb :error, :layout => :simple_layout
end

error do
  @page_title = "Error"
  @intro_spiel = "An error occurred. #{session[:message]}"
  erb :error, :layout => :simple_layout
end

get "/" do
    @page_title = 'Happy Habit Triangles'
    @intro_spiel = render_markdown(TEXT[:intro_page][:first])
    erb :index
end

post "/" do
  # Process front page choice of new objective or new habit
  # We pass a query parameter to indicate first app use to lead the user through

  @habit = nil
  user_input_objective = params[:objective_name]
  user_input_habit = params[:habit_description]
  case
  when valid_input(user_input_objective, :obj)
    # Once a valid objective name has been entered, convert it to a label to use as a hash key in session[:objectives]
    objective_identifier = make_identifier(user_input_objective)
    habits_ary = instantiate_3_habits_in_array(objective_identifier)

    # Add new objects to the session
    session[:objectives][objective_identifier] = Objective.new(get_next_id(:objective), habits_ary, objective_identifier)
    habits_ary.each { |h| session[:habits] << h }
    @habit = habits_ary.first
  when valid_input(user_input_habit, :habit)
    @habit = Habit.new(get_next_id(:habit), make_identifier(user_input_habit), description: user_input_habit, aspect: params[:aspect_tag])
    session[:habits] << @habit
  when user_input_habit && !valid_input(user_input_habit, :habit) || user_input_objective && !valid_input(user_input_objective, :obj)
    session[:message] = user_input_objective ? MESSAGES[:invalid_objective_name] : (MESSAGES[:invalid_habit_description] if user_input_habit)
    @intro_spiel = session[:message]
    @page_title = 'Input Error'
    halt 422, erb(:index)
  end
  session[:message] = nil 
  redirect "/habits/#{@habit.id}/update?initial=true"
end

## Objectives Routes
get "/objectives/:id/update" do |id|
  @objective = get_objective(id.to_i)
  @habits = @objective.habits
  @page_title = "Objective Summary"
  @intro_spiel = TEXT[:objectives][:update]
  @sub_info = "This is a list of habits for the objective named <b>#{@objective.name}</b>."
  
  erb :existing_objective, :layout => :simple_layout
end

get "/objectives/:id" do |id|
  @objective = get_objective(id.to_i)

  @page_title = "List of Habits By Objective"
  @intro_spiel = TEXT[:objectives][:old]
  @sub_info = "This is a list of habits for the objective named <h4>#{@objective.name}</h4>."
  erb :index_habits, :layout => :simple_layout
end

# get "/objectives/:id/update" do |id|
#   @objective = get_objective(id.to_i)
#   @page_title = "Objective Summary"
#   @intro_spiel = "This is a list of habits for the objective named <b>#{@objective.name}</b>."
#   erb :update_objective, :layout => :simple_layout
# end

## Habit Routes
get "/habits" do
  @page_title = "List of Habits"
  @intro_spiel = "This is a list of all habits."
  @habits = session[:habits]
  erb :index_habits, :layout => :simple_layout
end

get "/habits/:id" do |id|
  @habit = get_habit(id.to_i)
  halt 404 unless @habit
  @page_title = "Habit Overview"
  @intro_spiel = "This is the summary information for your habit with identifier <b>#{@habit.name}.</b>" +
  render_markdown(TEXT[:existing_habit][:sub_info])
  erb :update_habit, :layout => :simple_layout
end

get "/habits/:id/update" do |id|
  @habit = get_habit(id.to_i)
  @intro_spiel = params[:initial] ? TEXT[:existing_habit][:new] : TEXT[:existing_habit][:old]
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
    @error = session[:message]
    halt erb :update_habit, :layout => :simple_layout 
  else
    binding.pry
    @habit.description = params[:habit_description].strip
    @habit.date_of_initiation = date
    @habit.aspect = params[:aspect_tag].strip
    @habit.is_atomic = (params[:is_atomic] == 'on')
    @habit.update_to_today! 
    list_id = @habit.length - 1
    
    if @habit.is_atomic && !list_exists?(id.to_i, list_id)
      @intro_spiel = "This is some action list intro."
      
      last_list = get_last_task_list_for_habit(id.to_i)
      last_todos = last_list[:todos] unless last_list.nil?
      new_list_duplicate = { habit_id: id.to_i, todos: (last_todos || []), habit_list_id: (!last_list ? 0 : list_id) }
      reset_list_status!(new_list_duplicate)
      session[:lists] << new_list_duplicate unless list_exists?(id.to_i, list_id)
      redirect "/habits/#{id}/list/#{new_list_duplicate[:habit_list_id]}" 
    end
  end
  redirect "/habits/fractal/#{id}"
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
  
  @habits = habits_in_chain
  .map { |id| get_habit(id) }
  .sort_by(&:length).reverse
  .each { |h| h.update_to_today! }
  unless (@habits.all? {|h| session[:habits].include?(h)})
    halt 404
  end

  @base_habit = @habits.first
  @length_of_longest_habit = @base_habit.length

  @intro_spiel = render_markdown(params[:initial] ? TEXT[:existing_habit][:new] : TEXT[:existing_habit][:old])
  @page_title = "Fractal Habit Triangle"
  @reference_date = @habits.max_by(&:length).date_of_initiation

  erb :fractal
end

post /\/habits\/fractal((\/(?:\d{1,})){1,})/ do
  habits_in_chain = params['captures'].first.split("/")[1..-1].map(&:to_i)
  @habits = habits_in_chain.map { |id| get_habit(id) }
  @habit = @habits.first

  toggle_day_switch_value = ("completed-day-" + params[:node_completed_index])

  habit_node_for_day = @habit.get_nth(params[:node_completed_index].to_i)
  habit_node_for_day.today = params.key?(toggle_day_switch_value) ? 't' : 'f'

  redirect "/habits/fractal/#{@habit.id}"
end

## Todo List Modular Routes
# View a list
get "/habits/:habit_id/list/:list_id" do |habit_id, list_id|
  @habit_id = habit_id.to_i
  @list_id = list_id.to_i
  @page_title = "View Habit Actions"
  unless list_exists?(@habit_id, @list_id)
    session[:message] = 'List does not exist!'
    halt 404
  end
  @name = get_habit(habit_id.to_i).name
  @list = get_task_list(@habit_id, @list_id)

  @intro_spiel = render_markdown( TEXT[:action_list][:intro] )
  
  erb :list, :layout => :list_layout
end

# Complete all tasks on a list
post "/habits/:habit_id/list/:list_id/complete_all" do |habit_id, list_id|
  @habit_id = habit_id.to_i
  @list_id = list_id.to_i
  @list = get_task_list(@habit_id, @list_id)

  mark_all_tasks_completed!(@list)
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

  task[:completed] = !task[:completed]
  
  unless env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    session[:message] = 'The task has been updated'
    redirect "/habits/#{habit_id}/list/#{@list_id}"
  end
end

# Add an action to an existing list
post "/habits/:habit_id/list/:list_id/actions" do |habit_id, list_id|
  @habit_id = habit_id.to_i
  @list_id = list_id.to_i
  @list = get_task_list(@habit_id, @list_id)
  todo_text = params[:todo].strip
  @name = get_habit(habit_id.to_i).name

  error = error_for_todo(todo_text)
  if error
    session[:message] = error
    @page_title = 'Invalid Input'
    halt 422, erb(:list, :layout => :list_layout)
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
