require File.dirname(__FILE__) +'/../test_helper'

class KineticLink_UpdateTest < Test::Unit::TestCase

  def test_update_simple
    fields = {'2' => "Klink", '4' => "Shayne", '8' => "Test entry - No time"}
    record = Kinetic::Link.create("KLINK_CanonicalForm", fields)
    updated_fields = {'8' => "Test entry - #{Time.now}"}
    updated_record = nil
    assert_nothing_thrown {
      updated_record =  Kinetic::Link.update("KLINK_CanonicalForm", record, updated_fields)
    }
  rescue RuntimeError
    assert_not_nil(updated_record)
    assert_match(/^\d+$/,updated_record)
  end

  def test_update_record_does_not_exist
    fields = {'8' => "Test entry - #{Time.now}"}
    record = nil
    assert_throws (:runtime_error) {
      record =  Kinetic::Link.update("KLINK_CanonicalForm", "DOES NOT EXIST", fields)
    }
  rescue RuntimeError
    assert_nil(record)
  end


  # Test that we throw an error when we attempt to update a locked field
  def test_update_locked_field
    fields = {'2' => "Klink", '4' => "Shayne", '8' => "Test entry - #{Time.now}"}
    record = Kinetic::Link.create("KLINK_CanonicalForm", fields)
    updated_fields = {'2' => "Test"}
    updated_record = nil
    assert_throws (:runtime_error) {
      updated_record =  Kinetic::Link.update("KLINK_Test", record, updated_fields)
    }
  rescue RuntimeError
    assert_nil(updated_record)
  end
end

