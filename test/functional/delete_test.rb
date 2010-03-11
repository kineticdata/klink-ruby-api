require File.dirname(__FILE__) +'/../test_helper'

class KineticLink_DeleteTest < Test::Unit::TestCase

  def test_delete_simple
    fields = {'2' => "Klink", '4' => "Shayne", '8' => "Test entry - #{Time.now}"}
    new_record = Kinetic::Link.create("KLINK_CanonicalForm", fields)
    success = ''
    assert_nothing_thrown {
      success =  Kinetic::Link.delete("KLINK_CanonicalForm", new_record)
    }
    assert_not_nil(success)
    assert_match(/^true$/,success)
  end

  def test_delete_record_does_not_exist
    success = nil
    assert_nothing_thrown {
      success =  Kinetic::Link.delete("KLINK_CanonicalForm", "DOES_NOT_EXIST")
    }
  rescue RuntimeError
    assert_nil(success)
  end

  def test_delete_record_with_error
    fields = {'2' => "Klink", '4' => "Shayne", '8' => "No can delete"}
    #TODO create this filter
    # this creates a record that will have a filter against it preventing delete
    new_record = Kinetic::Link.create("KLINK_CanonicalForm", fields)
    success = nil
    assert_throws (:runtime_error) {
      success =  Kinetic::Link.delete("KLINK_CanonicalForm", new_record)
    }
  rescue RuntimeError
    assert_nil(success)
  end

end