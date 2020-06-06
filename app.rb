require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'
require 'pry-remote'
require 'yaml'
require_relative 'lib/habit'
require_relative 'lib/objective'

set :port, 9889
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
  session[:habits] = session[:objectives].each_with_object([]) { |(objective_name, objective), habits_list| habits_list << objective.habits }.uniq.flatten
end

before do
  set_session_variables
end

helpers do
  def render_markdown(text)
    renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    renderer.render(text)
  end
end

configure do
  enable :sessions
  set :session_secret, 'habit'
  set :erb, :escape_html => true
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
  if session[:objectives].empty?
    @page_title = 'Introduction'
    @intro_spiel = render_markdown(TEXT[:intro_page][:first])
    erb :index
  else
    current_objective = session[:objectives].values.min_by { |objective| objective.id } #this criteria will change
    redirect "/objectives/#{current_objective.id}"
  end
end

post "/" do
  if valid_objective_name?(params[:objective_name].strip)
    # Once a valid objective name has been entered, convert it to a label to use as a hash key in session[:objectives]
    objective_name = snake_case(params[:objective_name].strip)
    # Instantiate a new objective with 3 new habits, redirect to flesh out the first habit
    objective_id = get_next_id(:objective) 
    #/ Change the habit's IDs to be objective specific ?"#{objective_id}_#{i}"
    session[:objectives][objective_name] = Objective.new(objective_id, Array.new(3){ |i| Habit.new(i, objective_name + "_cornerstone_#{i}") }, objective_name.strip )

    session[:objectives][objective_name].habits.each do |habit|
      session[:habits] << habit
    end
    
    first_habit = session[:objectives][objective_name].habits.first
    redirect "/habits/#{first_habit.id}/update?initial=true"
  else
    session[:message] = MESSAGES[:invalid_objective_name]
    halt 422, erb(:error) if session[:message]
    redirect "/#enter_objective" #how to fragment redirect?
  end
end

get "/habits/new" do
  # Create a habit using inputs:
    # start today? 
     # IF YES then process input then redirect to habits/view 
     # ELSE process input then redirect to habits/update_days 
  # 
  erb :new_habit
end

get "/habits/:id" do |id|
  @habit = get_habit(id.to_i)
  halt 404 unless @habit
  erb :existing_habit
end

get "/objectives/:id" do |id|
  @objective = get_objective(id.to_i)
  session[:objectives].keys
end

get "/habits/:id/update_days" do |id|
  # Habit
end

get "/habits/:id/update" do |id|
  @habit = get_habit(id.to_i)
  @first_habit = !!params[:initial]
  if @first_habit
    @intro_spiel = TEXT[:new_habit][:referred]
  else
    @intro_spiel = 'This is just an old habit.'
  end
  erb :update_habit
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
  objective = session[:objectives][get_objective_key_by_habit(id.to_i)]
  binding.pry
  objective.habits.delete_if { |habit| habit.id == id.to_i}
  session[:habits].delete_if { |habit| habit.id == id.to_i }
  redirect "/objectives/#{objective.id}"
end












