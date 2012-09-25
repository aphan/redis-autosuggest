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
    @db = Redis::Autosuggest::Config.db
    @subs = Redis::Autosuggest::Config.substrings
    @str1 = "Test String"
  end

  def test_adding_an_item
    Redis::Autosuggest.add_item(@str1, 5)
    assert @db.hgetall(Redis::Autosuggest::Config.items)["0"] == @str1.downcase
    assert @subs.keys.size == @str1.size 
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
    Redis::Autosuggest.add_item(@str1, 5)
    Redis::Autosuggest.add_item(@str1, 5)
    assert @subs.keys.size == @str1.size
    assert @db.hgetall(Redis::Autosuggest::Config.items).size == 1
  end

  def test_removing_an_item
    Redis::Autosuggest.add_item(@str1)
    Redis::Autosuggest.remove_item(@str1)
    assert @db.hgetall(Redis::Autosuggest::Config.items).empty?
    assert @subs.keys.size == 0
  end

  def test_removing_a_nonexistent_item
    Redis::Autosuggest.add_item(@str1)
    Redis::Autosuggest.remove_item("Second test string")
    assert @db.hgetall(Redis::Autosuggest::Config.items).size == 1
    assert @db.hgetall(Redis::Autosuggest::Config.items)["0"] == @str1.downcase
    assert @subs.keys.size == @str1.size
  end

  def test_incrementing_an_items_score
    Redis::Autosuggest.add_item(@str1, 5)
    Redis::Autosuggest.increment(@str1)
    @subs.keys.each { |k| assert @subs.zscore(k, 0) == 6 }
    Redis::Autosuggest.increment(@str1, 8)
    @subs.keys.each { |k| assert @subs.zscore(k, 0) == 14 }
    Redis::Autosuggest.increment(@str1, -8)
    @subs.keys.each { |k| assert @subs.zscore(k, 0) == 6 }
  end

  MiniTest::Unit.after_tests { self.unused_db.flushdb }
end
