# hht_testing.rb
require 'bundler/setup'
ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'minitest/reporters'
require 'fileutils'

Minitest::Reporters.use!
require_relative '../app'

class HHTTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def session
    last_request.env["rack.session"]
  end

  def session_with_a_goal
    {"rack.session" => {goals: {'a_goal' => Goal.new(0, 'a_goal', Habit.new(0, 'a_habit'))}}}
  end

  def setup
  end

  def test_index_loads
    get "/"
    assert_equal last_response.status, 200
  end
  
  def test_it_initially_redirects_to_first_goal_if_one_exists
    get "/", {}, session_with_a_goal
    assert_equal 302, last_response.status
    
    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'goal'
  end

  def test_it_creates_a_goal
    post "/", {goal_name: 'A new goal'}
    assert_includes session[:goals].keys, 'a_new_goal'  
  end
  
  def test_it_creates_3_habits_per_goal
    post "/", {goal_name: 'A new goal'}
    habits_array = session[:goals]['a_new_goal'].habits
    
    assert_equal 3, habits_array.size
    habits_array.each do |item|
      assert_instance_of Habit, item
    end
  end
  
  def test_it_transforms_valid_goal_names_to_snake_case_for_key
    post "/", {goal_name: 'A new goal'}
    goal_name = session[:goals].key? 'a_new_goal'

    assert goal_name
  end
  
  def test_it_disallows_invalid_goal_names
    post "/", {goal_name: 'A new goal that has far too many words and some 3%#%#$'}
    assert_equal 422, last_response.status
  end
  
  def test_it_disallows_invalid_updating_of_habit_description
    post "/", {goal_name: 'A new goal'}
    habits_array = session[:goals]['a_new_goal'].habits

    post "/habits/#{habits_array.first.id}/update", {
      habit_description: 'A new habit that has far too many words and some 3%#%#$',
      aspect_tag: '#some-tag'
    }
    assert_equal 422, last_response.status
  end
  
  def test_it_disallows_invalid_updating_of_habit_aspect
    post "/", {goal_name: 'A new goal'}
    habits_array = session[:goals]['a_new_goal'].habits

    post "/habits/#{habits_array.first.id}/update", {
      habit_description: 'A new habit',
      aspect_tag: 'Some wrong tag'
    }

    assert_equal 422, last_response.status
  end

  def test_it_allows_valid_updating_of_habit_description
    skip
    assert_equal last_response.status, 200
  end

  def test_it_allows_valid_updating_of_aspect_names
    skip
    assert_equal last_response.status, 200
  end

  def test_it_disallows_invalid_updating_of_aspect_names
    skip
    assert_equal last_response.status, 200
  end

  def test_it_disallows_invalid_updating_of_date_of_initiation
    skip
    assert_equal last_response.status, 200
  end

  def test_it_allows_toggling_of_day_completed
    skip
    assert_equal last_response.status, 200
  end
end