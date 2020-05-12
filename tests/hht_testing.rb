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

  def setup
    FileUtils.mkdir_p(ROOT + "/test_path")
  end

  def test_index_loads
    get "/"
    assert_equal last_response.status, 200
  end
end