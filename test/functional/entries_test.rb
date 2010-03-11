require File.dirname(__FILE__) +'/../test_helper'

class KineticLink_EntriesTest < Test::Unit::TestCase

  def test_entries_simple
    entries = nil
    assert_nothing_thrown {
      entries = Kinetic::Link::entries('User')
    }
    assert_not_nil(entries)
    assert_instance_of(Array,entries)
  end

  def test_entries_param_001
    entries = nil
    param = %|'Request ID'!="0"|
    assert_nothing_thrown {
      entries = Kinetic::Link::entries('User', param)
    }
    assert_not_nil(entries)
    assert_instance_of(Array,entries)
  end

  def test_entries_param_002
    entries = nil
    param = %|'request_id'="000000000000027"|
    assert_nothing_thrown {
      entries = Kinetic::Link::entries('User', param)
    }
    assert_not_nil(entries)
    assert_instance_of(Array,entries)
  end

  def test_entries_param_003
    entries = nil
    param = %|1=1|
    assert_nothing_thrown {
      entries = Kinetic::Link::entries('User', param)
    }
    assert_not_nil(entries)
    assert_instance_of(Array,entries)
  end

end

