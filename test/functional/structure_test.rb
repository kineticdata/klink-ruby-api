require File.dirname(__FILE__) +'/../test_helper'

class StructureTest < Test::Unit::TestCase


  def test_get_structure

    struc_name = "User"

    assert_nothing_thrown {
      struc_info = Kinetic::Link.structure(struc_name)

      assert_not_nil struc_info
      assert_kind_of Hash,struc_info

    }


  end



end







