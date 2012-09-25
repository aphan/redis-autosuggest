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
    Redis::Autosuggest.add(@str1, 5)
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
    Redis::Autosuggest.add(@str1, 5)
    Redis::Autosuggest.add(@str1, 5)
    assert @subs.keys.size == @str1.size
    assert @db.hgetall(Redis::Autosuggest::Config.items).size == 1
  end

  def test_removing_an_item
    Redis::Autosuggest.add(@str1)
    Redis::Autosuggest.remove(@str1)
    assert @db.hgetall(Redis::Autosuggest::Config.items).empty?
    assert @subs.keys.size == 0
  end

  def test_removing_a_nonexistent_item
    Redis::Autosuggest.add(@str1)
    Redis::Autosuggest.remove("Second test string")
    assert @db.hgetall(Redis::Autosuggest::Config.items).size == 1
    assert @db.hgetall(Redis::Autosuggest::Config.items)["0"] == @str1.downcase
    assert @subs.keys.size == @str1.size
  end

  def test_incrementing_an_items_score
    Redis::Autosuggest.add(@str1, 5)
    Redis::Autosuggest.increment(@str1)
    @subs.keys.each { |k| assert @subs.zscore(k, 0) == 6 }
    Redis::Autosuggest.increment(@str1, 8)
    @subs.keys.each { |k| assert @subs.zscore(k, 0) == 14 }
    Redis::Autosuggest.increment(@str1, -8)
    @subs.keys.each { |k| assert @subs.zscore(k, 0) == 6 }
  end

  def test_suggesting_items
    Redis::Autosuggest.add(@str1, 5)
    Redis::Autosuggest.add("#{@str1} longer", 2)
    suggestions =  Redis::Autosuggest.suggest(@str1[0..4])
    assert_equal [@str1.downcase, "#{@str1} longer".downcase], suggestions
  end

  def test_no_suggestions_found
    Redis::Autosuggest.add(@str1)
    assert Redis::Autosuggest.suggest("nothing here").empty?
  end

  def test_leaderboard_items
    Redis::Autosuggest::Config.use_leaderboard = true
    Redis::Autosuggest.add(@str1, 3)
    Redis::Autosuggest.add("Another item", 5)
    Redis::Autosuggest.add("Third item", 1)
    top_items = Redis::Autosuggest.leaderboard
    assert_equal ["another item", @str1.downcase, "third item"], top_items 
    Redis::Autosuggest::Config.use_leaderboard = false 
  end

  MiniTest::Unit.after_tests { self.unused_db.flushdb }
end
