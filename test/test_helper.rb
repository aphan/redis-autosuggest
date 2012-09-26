$LOAD_PATH.unshift 'lib'
require 'minitest/autorun'
require 'debugger'
require 'redis'
require 'redis-namespace'
require 'redis-autosuggest'


class TestHelper
  # get an unused db so that we can safely clear all keys 
  def self.db_picker
    redis = Redis.new
    (0..15).each do |i|
      redis.select(i)
      return i if redis.keys.empty?
    end
  end
end
