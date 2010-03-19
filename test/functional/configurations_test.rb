require File.dirname(__FILE__) +'/../test_helper'


class ConfigurationsTest < Test::Unit::TestCase
  def test_get_configurations

    assert_nothing_thrown {
      configs = Kinetic::Link.configurations

      assert_not_nil configs
      assert_kind_of Hash,configs

   
    }


  end

  def test_get_configuration

    config_name = "HOSTNAME"

    assert_nothing_thrown {
      config = Kinetic::Link.configurations(config_name)

      assert_not_nil config
      assert_kind_of Hash,config
      assert_not_nil config[config_name]
      assert_kind_of String, config[config_name]

    }


  end




  def test_get_multi_configurations

    config_name = "HOSTNAME,OPERATING_SYSTEM"
    config_one = "HOSTNAME"


    assert_nothing_thrown {
      config = Kinetic::Link.configurations(config_name)

      assert_not_nil config
      assert_kind_of Hash,config
      assert (config.keys.size == 2)
      assert_not_nil config[config_one]
      assert_kind_of String, config[config_one]

    }


  end



end







