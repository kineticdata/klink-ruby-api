require File.dirname(__FILE__) +'/../test_helper'

class KineticLink_CreateTest < Test::Unit::TestCase

  def test_create_simple
    fields = {'2' => 'Tester', '4' => 'Shayne', '8' => 'Test entry'}
    assert_nothing_thrown {
      record = Kinetic::Link.create("KLINK_CanonicalForm", fields)
      assert_not_nil(record)
      assert_match(/^\d+$/,record)
      Kinetic::Link.delete("KLINK_CanonicalForm", record)
    }
  end

  def test_create_with_missing_required
    #Missing a required field, 8 is required.
    fields = {'2' => 'Tester', '4' => 'Shayne'}
    record = nil
    assert_throws (:runtime_error) {
      record =  Kinetic::Link.create("KLINK_CanonicalForm", fields)
    }
  rescue RuntimeError
    assert_nil(record)
  end

end