require 'test_helper'

class TestAutosuggest < MiniTest::Unit::TestCase

  def self.unused_db
    @unused_db ||= Redis.new(:db => db_picker)
  end

  # get an unused db so that we can safely clear all keys 
  def self.db_picker
    redis = Redis.new
    (0..15).each do |i|
      redis.select(i)
      return i if redis.keys.empty?
    end
  end

  def setup
    self.class.unused_db.flushdb
    Redis::Autosuggest::Config.redis = self.class.unused_db 
    @subs = Redis::Autosuggest::Config.substrings
  end

  def test_adding_an_item
    str = "Test String"
    Redis::Autosuggest.add_item(str, 5)
    assert @subs.keys.size == str.size
    assert_equal ["0"], @subs.zrevrange("t", 0, -1)
    assert_equal ["0"], @subs.zrevrange("te", 0, -1)
    assert_equal ["0"], @subs.zrevrange("tes", 0, -1)
    assert_equal ["0"], @subs.zrevrange("test", 0, -1)
    assert_equal ["0"], @subs.zrevrange("test ", 0, -1)
    assert_equal ["0"], @subs.zrevrange("test s", 0, -1)
    assert_equal ["0"], @subs.zrevrange("test st", 0, -1)
    assert_equal ["0"], @subs.zrevrange("test str", 0, -1)
    assert_equal ["0"], @subs.zrevrange("test stri", 0, -1)
    assert_equal ["0"], @subs.zrevrange("test strin", 0, -1)
    assert_equal ["0"], @subs.zrevrange("test string", 0, -1)
    @subs.keys.each { |k| assert @subs.zscore(k, 0) == 5 }
  end

  def test_adding_duplicate_item
    str = "Test String"
    Redis::Autosuggest.add_item(str, 5)
    Redis::Autosuggest.add_item(str, 5)
    assert @subs.keys.size == str.size
  end


  MiniTest::Unit.after_tests { self.unused_db.flushdb }
end
