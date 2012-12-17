require 'test_helper'

class TestFile < MiniTest::Unit::TestCase

  def self.unused_db
    @unused_db ||= Redis.new(:db => TestHelper.db_picker)
  end

  def setup
    self.class.unused_db.flushdb
    Redis::Autosuggest.redis = self.class.unused_db 
    @db = Redis::Autosuggest.db
    @subs = Redis::Autosuggest.substrings
  end

  def test_adding_from_file
    Redis::Autosuggest.add_from_file("test/text/example.txt")
    assert @db.hgetall(Redis::Autosuggest.items).size == 3
    assert @subs.keys.size == 10
  end

  def test_adding_with_score_from_file
    Redis::Autosuggest.add_with_score_from_file("test/text/example_with_score.txt")
    assert @db.hgetall(Redis::Autosuggest.items).size == 3
    assert @subs.keys.size == 10
    assert_equal 12, @subs.zscore("one", 0)
    assert_equal 4, @subs.zscore("two", 1)
    assert_equal 3, @subs.zscore("three", 2)
  end

  MiniTest::Unit.after_tests { self.unused_db.flushdb }
end
