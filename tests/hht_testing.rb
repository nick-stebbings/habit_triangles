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

  def session_with_a_objective
    {"rack.session" => {objectives: {'a_objective' => Objective.new(0, [Habit.new(0, 'a_habit')], 'a_objective')}, habits: [Habit.new(0, 'a_habit')]}}
  end

  def setup
  end

  def test_index_loads_introduction_for_new_session
    get "/"
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Introduction'
  end
  
  def test_it_initially_redirects_to_first_objective_if_one_exists
    get "/", {}, session_with_a_objective
    assert_equal 302, last_response.status
    
    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'objective'
  end

  def test_it_creates_a_objective
    post "/", {objective_name: 'A new objective'}
    assert_includes session[:objectives].keys, 'a_new_objective'  
  end
  
  def test_it_creates_3_habits_per_objective
    post "/", {objective_name: 'A new objective'}
    habits_array = session[:objectives]['a_new_objective'].habits
    
    assert_equal 3, habits_array.size
    habits_array.each do |item|
      assert_instance_of Habit, item
    end
  end
  
  def test_it_transforms_valid_objective_names_to_snake_case_for_key
    post "/", {objective_name: 'A new objective'}
    objective_name = session[:objectives].key? 'a_new_objective'

    assert objective_name
  end
  
  def test_it_disallows_invalid_objective_names
    post "/", {objective_name: 'A new objective that has far too many words and some 3%#%#$'}
    assert_equal 422, last_response.status
  end
  
  def test_it_disallows_invalid_updating_of_habit_description
    post "/", {objective_name: 'A new objective'}
    habits_array = session[:objectives]['a_new_objective'].habits

    post "/habits/#{habits_array.first.id}/update", {
      habit_description: 'A new habit that has far too many words and some 3%#%#$ that you really should not put in there',
      aspect_tag: '#some-tag',
      date_of_initiation: DateTime.now
    }
    assert_equal 422, last_response.status
  end
  
  def test_it_allows_valid_updating_of_habit_description
    post "/", {objective_name: 'A new objective'}
    habits_array = session[:objectives]['a_new_objective'].habits
    
    post "/habits/#{habits_array.first.id}/update", {
      habit_description: 'A new habit description that is diff',
      aspect_tag: '#some-tag',
      date_of_initiation: DateTime.now
    }
    
    assert_equal 302, last_response.status
    # Add a line to check the name in the objective page?
  end
  
  def test_it_disallows_invalid_updating_of_habit_aspect
    post "/", {objective_name: 'A new objective'}
    habits_array = session[:objectives]['a_new_objective'].habits
    
    post "/habits/#{habits_array.first.id}/update", {
      habit_description: 'A new habit',
      aspect_tag: 'Some wrong tag'
    }
    
    assert_equal 422, last_response.status
  end
  
  def test_it_allows_valid_updating_of_habit_aspect
    post "/", {objective_name: 'A new objective'}
    habits_array = session[:objectives]['a_new_objective'].habits
    
    post "/habits/#{habits_array.first.id}/update", {
      habit_description: 'A new habit',
      aspect_tag: '#some-actual-tag',
      date_of_initiation: DateTime.now
    }

    assert_equal 302, last_response.status
  end
  
  def test_it_disallows_invalid_updating_of_date_of_initiation
    post "/", {objective_name: 'A new objective'}
    habits_array = session[:objectives]['a_new_objective'].habits

    post "/habits/#{habits_array.first.id}/update", {
      habit_description: 'A new habit',
      aspect_tag: '#some-tag',
      date_of_initiation: (DateTime.now + 10000)
    }

    assert_equal 422, last_response.status
  end
  
  def test_it_allows_viewing_a_habit
    get "/habits/0", {}, session_with_a_objective
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'habit'
  end
  
  def test_it_deletes_a_habit
    post "/habits/0/delete", {}, session_with_a_objective
    assert_equal 302, last_response.status
    get "/habits/0"
    assert_equal 302, last_response.status # 'Not found' route
  end
  
  def test_it_allows_toggling_of_day_completed
    skip
    assert_equal last_response.status, 200
  end

  def test_it_updates_a_habit
    skip
    assert_equal last_response.status, 200
  end
  
  def test_it_allows_toggling_of_day_completed
    skip
    assert_equal last_response.status, 200
  end
end