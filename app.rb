require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

require 'pry-remote'
require 'yaml'
require_relative 'lib/habit'
require_relative 'lib/goal'

set :port, 9889
ROOT = File.expand_path('..', __FILE__)
TEXT = YAML.load_file(ROOT + '/public/paragraphs_text.yaml')

MESSAGES = {
  invalid_habit_name: "You entered an invalid habit name. Please try to summarise in up to 5 words, split with spaces.",
  invalid_goal_name: "You entered an invalid goal name. Please try to summarise in up to 5 words, split with spaces.",
  invalid_habit_description: "You entered an invalid habit description. Please limit it to 50 characters or less.",
  invalid_aspect_tag: "You entered an invalid tag. The format should be #this-is-a-tag"
}

before do
  session[:goals] ||= {}
  session[:habits] = (session[:goals].values.first.habits) #just for the first habit for now
end

configure do
  enable :sessions
  set :session_secret, 'habit'
end

def get_habit(id)
  session[:habits].first { |habit| habit.id == id }
end

def get_goal(id)
  session[:goals].values.first { |goal| goal.id == id }
end

helpers do
  def in_paragraphs(text)
    text.split("\n").map { |para| "<p>#{para}</p>" }.join
  end

  def valid_goal_name(phrase)
    phrase.match? %r{^(?:\w* ){0,4}\w+$} # Matches 'up to five words split by a space' format
  end

  def valid_habit_description(phrase)
    true
  end
  
  def valid_aspect(tag)
    true
  end
    
  def snake_case(phrase)
    phrase.downcase.split(' ').join('_')
  end
end

get "/" do
  if session[:habits].empty?
    @page_title = 'Introduction'
    @intro_spiel = TEXT[:intro_page][:first]
    erb :intro
  else
    current_goal = session[:goals].values.min_by { |goal| goal.id } #this criteria will change
    redirect "/goals/#{current_goal.id}"
  end
end

post "/" do
  if valid_goal_name(params[:goal_name].strip)
    # Once a valid goal name has been entered, convert it to a label to use as a hash key in session[:goals]
    goal_name = snake_case(params[:goal_name].strip)
    # Instantiate a new goal with 3 new habits, redirect to flesh out the first habit
    session[:goals][goal_name] = Goal.new(0, Array.new(3){ |i| Habit.new(i, goal_name + '_cornerstone') }, goal_name.strip )
    first_habit = session[:goals][goal_name].habits.first
    redirect "/habits/#{first_habit.id}/update?initial=true"
  else
    session[:message] = MESSAGES[:invalid_goal_name]
    redirect "/#enter_goal" #how to fragment redirect?
  end
end

get "/habits/:id" do |id|
  @habit = get_habit(id.to_i)
  erb :existing_habit
end

get "/goals/:id" do |id|
  @goal = get_goal(id.to_i)
  session[:goals].keys
end


get "/habits/:id/update" do |id|
  # //A habit instance has been created, this will populate a form with the details of the habit
  # //IF it is being redirected from the intro page
    # //THEN render a paragraph from the paragraphs yaml exlaining things
  # ELSE just show the habit details,
    # IF there is only one day in the habit AND it is FALSE
      # THEN assume this is a new habit. Do NOT show the data in a form
      # Fields to be shown for a habit:
        # /Date began
        # Streak, calculated from the data structure select
        # /Aspect of habit
        # /Description of habit
        #LATER ON: A link to the super/subhabit associated with this one.
      # //INPUT - did you pass this habit today?

    # //ELSE assume this is a new habit. Show the data in a form
      # - //When the form is submitted, there will be validation
        # - HELPER for decription
          #  -- limit length
        # - HELPER for aspect
       # - /When the form is submitted, update the details in the instance
        # DATE AND CHECKBOX not formatted correctly for update
    # //Reload the page, rendering with errors if validation didn't pass
  @habit = get_habit(id.to_i)
  @first_habit = !!params[:initial]
  if @first_habit
    @intro_spiel = TEXT[:new_habit][:referred]
  else
    @intro_spiel = 'This is just an old habit.'
  end
  binding.pry
  erb :new_habit
end

post "/habits/:id/update" do |id|
  @habit = get_habit(id.to_i)
  session[:message] = MESSAGES[:invalid_habit_description] unless valid_habit_description(params[:habit_description])
  session[:message] = MESSAGES[:invalid_aspect_tag] unless valid_aspect(params[:aspect_tag])

  @habit.description = params[:habit_description].strip
  @habit.date_of_initiation = Date.parse(params[:date_of_initiation])
  # @habit.head_node.today = params[:aspect_tag]
  @habit.head_node.today = !!(params[:completed_today] == 'false')

  redirect "/habits/#{id}"
end














