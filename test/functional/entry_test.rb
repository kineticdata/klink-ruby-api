require File.dirname(__FILE__) + '/../test_helper'

class KineticLink_EntryTest < Test::Unit::TestCase

  def test_entry
    entry = nil
    existing_entry = Kinetic::Link::entries('User')[0]
    assert_nothing_thrown {
      entry = Kinetic::Link::entry('User', existing_entry)
    }
    assert_not_nil(entry)
    assert_match(/^\d+$/,entry['1'])
    assert_instance_of(Hash,entry)
  end
  
end

