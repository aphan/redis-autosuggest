require 'test_helper'

class TestAutosuggest < MiniTest::Unit::TestCase
  
  def self.unused_db
    @unused_db ||= Redis.new(:db => TestHelper.db_picker)
  end

  def setup
    self.class.unused_db.flushdb
    Redis::Autosuggest.redis = self.class.unused_db 
    @db = Redis::Autosuggest.db
    @subs = Redis::Autosuggest.substrings
    @str1 = "Test String"
  end

  def test_adding_an_item
    Redis::Autosuggest.add(@str1)
    assert @db.hgetall(Redis::Autosuggest.items)["0"] == @str1.downcase
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
  end

  def test_adding_duplicate_item
    Redis::Autosuggest.add(@str1)
    Redis::Autosuggest.add(@str1)
    assert @db.hgetall(Redis::Autosuggest.items).size == 1
    assert @subs.keys.size == @str1.size
  end

  def test_adding_multiple_items
    Redis::Autosuggest.add("one", "two", "three")
    assert @db.hgetall(Redis::Autosuggest.items).size == 3
    assert @subs.keys.size == 10
  end

    def test_adding_multiple_items_with_scores
    Redis::Autosuggest.add_with_score("one", 1, "two", 2, "three", 3)
    assert @db.hgetall(Redis::Autosuggest.items).size == 3
    assert @subs.keys.size == 10
    assert_equal 1, @subs.zscore("one", 0)
    assert_equal 2, @subs.zscore("two", 1)
    assert_equal 3, @subs.zscore("three", 2)
  end

  def test_removing_an_item
    Redis::Autosuggest.add(@str1)
    Redis::Autosuggest.remove(@str1)
    assert @db.hgetall(Redis::Autosuggest.items).empty?
    assert @subs.keys.size == 0
  end

  def test_removing_a_nonexistent_item
    Redis::Autosuggest.add(@str1)
    Redis::Autosuggest.remove("Second test string")
    assert @db.hgetall(Redis::Autosuggest.items).size == 1
    assert @db.hgetall(Redis::Autosuggest.items)["0"] == @str1.downcase
    assert @subs.keys.size == @str1.size
  end

  def test_incrementing_an_items_score
    Redis::Autosuggest.add_with_score(@str1, 5)
    Redis::Autosuggest.increment(@str1)
    @subs.keys.each { |k| assert @subs.zscore(k, 0) == 6 }
    Redis::Autosuggest.increment(@str1, 8)
    @subs.keys.each { |k| assert @subs.zscore(k, 0) == 14 }
    Redis::Autosuggest.increment(@str1, -8)
    @subs.keys.each { |k| assert @subs.zscore(k, 0) == 6 }
  end

  def test_suggesting_items
    Redis::Autosuggest.add_with_score(@str1, 5)
    Redis::Autosuggest.add_with_score("#{@str1} longer", 2)
    suggestions =  Redis::Autosuggest.suggest(@str1[0..4])
    assert_equal [@str1.downcase, "#{@str1} longer".downcase], suggestions
  end

  def test_no_suggestions_found
    Redis::Autosuggest.add(@str1)
    assert Redis::Autosuggest.suggest("nothing here").empty?
  end

  def test_leaderboard_items
    Redis::Autosuggest.use_leaderboard = true
    Redis::Autosuggest.add_with_score(@str1, 3)
    Redis::Autosuggest.add_with_score("Another item", 5)
    Redis::Autosuggest.add_with_score("Third item", 1)
    top_items = Redis::Autosuggest.get_leaderboard
    assert_equal ["another item", @str1.downcase, "third item"], top_items 
    Redis::Autosuggest.use_leaderboard = false 
  end

  MiniTest::Unit.after_tests { self.unused_db.flushdb }
end
