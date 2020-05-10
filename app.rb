require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

# require 'pry'
require 'yaml'

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
   


end
