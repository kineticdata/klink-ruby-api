require File.dirname(__FILE__) +'/../test_helper'


class StructuresTest < Test::Unit::TestCase
  def test_get_structures

    struct_list = Array.new

    assert_nothing_thrown {
      struct_list = Kinetic::Link.structures

      assert_not_nil struct_list
      assert_kind_of Array,struct_list

    }


  end

 

end







