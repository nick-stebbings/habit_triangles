require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

require 'pry-remote'
require 'yaml'
require_relative 'public/habit.rb'

set :port, 9889
ROOT = File.expand_path('..', __FILE__)
TEXT = YAML.load_file(ROOT + '/paragraphs_text.yaml')

before do
  session[:goals] ||= {}
  session[:habits] ||= []
end

configure do
  enable :sessions
  set :session_secret, 'habit'
end

helpers do
  def in_paragraphs(text)
    text.split("\n").map { |para| "<p>#{para}</p>" }.join
  end

  def valid_habit_name(phrase)
    phrase.match? %r{^(?:\w* ){0,4}\w+$} # Matches 'up to five words split by a space' format
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
    @page_title = 'Introduction'
    "You've been here before"
  end
end

post "/" do
  # \if a goal name has been entered
    #/  then if it is a valid name,
       # /SET the goal's name
         #/ - initialize 3 habits for that goal
      #  - then redirect to first habit creation page
    #/ else render the page again and show an eror message
  if valid_habit_name(params[:goal_name].strip)
    goal_name = snake_case(params[:goal_name].strip)
    session[:goals][goal_name] = Array.new(3){ |i| Habit.new(i, params[:goal_name]) }
    binding.pry_remote
    redirect "/habits/#{session[:goals][goal_name].first.id}"
  else
    session[:message] = "You entered an invalid habit name. Please try to summarise in up to 5 words, split with spaces."
    redirect "/#enter_goal"
  end



end


















