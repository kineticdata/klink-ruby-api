require File.dirname(__FILE__) +'/../test_helper'


class StatisticsTest < Test::Unit::TestCase
  def test_get_statistic

    stat_name = "API_REQUESTS"

    assert_nothing_thrown {
      stat = Kinetic::Link.statistics(stat_name)

      assert_not_nil stat
      assert_kind_of Hash,stat
      assert_not_nil stat[stat_name]
      assert_kind_of String, stat[stat_name]
      assert_kind_of Integer, stat[stat_name].to_i
      assert (stat[stat_name].to_i > 0)

    }


  end

    def test_get_multi_statistic

    stat_name = "API_REQUESTS,CURRENT_USERS"
    stat_one = "API_REQUESTS"


    assert_nothing_thrown {
      stat = Kinetic::Link.statistics(stat_name)

      assert_not_nil stat
      assert_kind_of Hash,stat
      assert (stat.keys.size == 2)
      assert_not_nil stat[stat_one]
      assert_kind_of String, stat[stat_one]
      assert_kind_of Integer, stat[stat_one].to_i
      assert (stat[stat_one].to_i > 0)

    }


  end



end







