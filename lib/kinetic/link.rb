require 'net/http'
require 'uri'
require 'rexml/document'
require 'yaml'
include REXML


module Kinetic
  # Represents a Kinetic Link connection
  class Link

    Kinetic::Link::VERSION='1.0.1'

    @@link_api_version = "Kinetic Link #{Kinetic::Link::VERSION}"

    # required connection information to connect to an ar_server via klink
    @@user = nil
    @@password = nil
    @@klink_server = nil
    @@ar_server = nil
    
    # initialize to false
    # set to connected once we have all the info needed to connect
    @@connected = false
    
    # TODO - Remove this function???
    # Is this the right place for it to be?
    # (Renamed - to see if anything else breaks)
    # Max 30 chars unique
    # can return less than 30 chars
    # currently only numbers
    # TODO - include alpha with case
    # currently 10^30 uniques
    # with mixed alpha 62^30
    # possibly use sha1
    def self.xxxget_guid
      return (rand.to_s.split('.')[1].to_s + rand.to_s.split('.')[1].to_s).slice(0,30)
    end

    # setup connection info
    # Example: Demo,"","klinkserver:8081.yourcompany.com,remedy.yourcompany.com
    # TODO -- add AR Server port??? -- how does that work with Klink?
    def self.set_connection(user,password,klink_server,ar_server)
      @@user=user
      @@password=password
      @@klink_server=klink_server
      @@ar_server=ar_server
    end
    
    # return true false
    # get a list of forms - if that works - all is well
    # all servers have some sort of form available to public
    def self.test_connection

      begin
        if(self.structures.length > 0) then
          return true
        else
          return false
        end
      rescue
        return false
      end
    end
  
    # connect if possible return status of connection
    def self.establish_connection

      if(@@ar_server == nil) then

        # TODO - grab this from somewhere
        environment = $klink_env

        raise "No environment set" if(environment == nil)

        # TODO - assumes it finds a file
        klink_config = YAML::load_file(
          File.expand_path(File.join(".",'klink.yml')))

        begin
          @@user=klink_config[environment]['user']
          @@password=klink_config[environment]['password']
          @@klink_server=klink_config[environment]['klink_server']
          @@ar_server=klink_config[environment]['ar_server']
        rescue
          raise "Problem reading environment: #{$klink_env}"
        end


      end

      # Temp set to true
      @@connected = true

      # Set to actual
      @@connected = self.test_connection


      return true
    end
    
    # delete record with id from the form
    def self.delete(form_name, request_id)

      Link::establish_connection if @@connected == false
      
      form_name_escaped = URI.escape(form_name)
  
      uri = "http://#{@@klink_server}/klink/delete/#{@@user}:#{@@password}@#{@@ar_server}/#{form_name_escaped}/#{request_id}"

      response = Net::HTTP.get URI.parse(uri)

      xmldoc = Document.new response

      ret_val = nil
      error = nil

      xmldoc.elements.each('Response') { |entry_item|
        ret_val = entry_item.attributes['Success']
        if ret_val == 'false' then
          xmldoc.elements.each('Response/Messages/Message') {|error_item|
            if error_item.attributes['MessageNumber'] == '302'
              then error = '302' # Record does not exist
            end
          }
        end
      }

      # 302 == <Message MessageNumber="302" Type="ERROR">Entry does not exist in database</Message>
      raise response.to_s if (ret_val == "false" && error != '302')
  
      return ret_val

    end
    
    # return id(s) of records from the form
    # need to take params 
    # - sort order
    # - field id(s) -- which will be field names
    # - etc -- from Klink list of options
    def self.entry(form_name, request_id)

      Link::establish_connection if @@connected == false
      
      form_name_escaped = URI.escape(form_name)
    
      uri = "http://#{@@klink_server}/klink/entry/#{@@user}:#{@@password}@#{@@ar_server}/#{form_name_escaped}/#{request_id}"

      response = Net::HTTP.get URI.parse(uri)

      xmldoc = Document.new response

      ret_val = Hash.new

      # TODO -- handle 'Status History' -- right now I just convert to ''
      xmldoc.elements.each('Response/Result/Entry/EntryItem') { |entry_item|
        ret_val[entry_item.attributes['ID']] = entry_item.text || ''
      }

      return ret_val

    end    
    
    # TODO - add ability to specify fields to retrieve
    # improves performance
    # Possibly new method entries_with_fields???
    # TODO - same with entry_with_fields
    # return id(s) of records from the form
    # need to take params 
    # - sort order
    # - field id(s) -- which will be field names
    # - etc -- from Klink list of options
    def self.entries(form_name, params = {}, sort = nil)

      self.establish_connection if @@connected == false

      if (params.size > 0) then 
        param_list = URI.escape("?qualification=#{params}")
      end
      
      form_name_escaped = URI.escape(form_name)
    
      uri = "http://#{@@klink_server}/klink/entries/#{@@user}:#{@@password}@#{@@ar_server}/#{form_name_escaped}#{param_list}"

      uri << "&sort=#{sort}" unless sort.nil? 

      response = Net::HTTP.get URI.parse(uri)

      xmldoc = Document.new response

      ret_val = Array.new

      xmldoc.elements.each('Response/Result/EntryList/Entry') { |id| 
        ret_val << id.attributes['ID']
      }

      return ret_val

    end
    
    # return a list of statistics
    # TODO - need to take params 
    def self.statistics(items = {})

      self.establish_connection if @@connected == false

      if (items.size > 0) then 
        param_list = URI.escape("?items=#{items}")
      end
    
      uri = "http://#{@@klink_server}/klink/statistics/#{@@user}:#{@@password}@#{@@ar_server}#{param_list}"
      response = Net::HTTP.get URI.parse(uri)

      xmldoc = Document.new response

      ret_val = Hash.new

      xmldoc.elements.each('Response/Result/Statistics/Statistic') { |stat| 
        ret_val[stat.attributes['Name']]=stat.text ||=''
      }

      return ret_val

    end
    
    # return a list of configurations
    # TODO - need to take params 
    def self.configurations(items = {})

      self.establish_connection if @@connected == false

      if (items.size > 0) then 
        param_list = URI.escape("?items=#{params}")
      end
    
      uri = "http://#{@@klink_server}/klink/configurations/#{@@user}:#{@@password}@#{@@ar_server}#{param_list}"
      uri = URI.escape(uri)
      response = Net::HTTP.get URI.parse(uri)

      xmldoc = Document.new response

      ret_val = Hash.new

      xmldoc.elements.each('Response/Result/Configurations/Configuration') { |conf| 
        ret_val[conf.attributes['Name']]=conf.text ||=''
      }

      return ret_val

    end

    # return a list of structures
    def self.structures

      self.establish_connection if @@connected == false

      uri = "http://#{@@klink_server}/klink/structures/#{@@user}:#{@@password}@#{@@ar_server}"
      uri = URI.escape(uri)
      response = Net::HTTP.get URI.parse(uri)

      xmldoc = Document.new response

      ret_val = Array.new

      xmldoc.elements.each('Response/Result/Structures/Structure') { |structure| 
        ret_val << structure.attributes['ID'] ||=''
      }

      return ret_val

    end

    # TODO - make cleaner and make into a library
    # I just never found it in a library
    def self.clean_input(v)

      new_v = v.is_a?(String) ? v.clone : v
      
      if v.class == String then 
        new_v.gsub!(/&/, '&amp;')
        new_v.gsub!(/\n/, '&#10;')
        new_v.gsub!(/\r/, '&#13;')  # TODO - never tested     
        new_v.gsub!(/\</, '&lt;')
        new_v.gsub!(/\>/, '&gt;')
      end
      
      return new_v

    end

    # TODO - structure needs to return more than field id / field names
    # Would be good to return structure.type
    # also - per field -- field info
    # 
    def self.structure(form_name)

      self.establish_connection if @@connected == false
      
      uri = "http://#{@@klink_server}/klink/structure/#{@@user}:#{@@password}@#{@@ar_server}/#{form_name}"
      uri = URI.escape(uri)
      response = Net::HTTP.get URI.parse(uri)
      
      structure_map = Hash.new

      xmldoc = Document.new response
      xmldoc.elements.each('Response/Result/Structure/StructureItem') { |structure_item| 
        structure_map[structure_item.attributes['ID']] = structure_item.attributes['Name']
      }


      return structure_map
      
    end

    def self.build_connection

      # if port info is included - need to breakup and attach to that port
      if /:/.match(@@klink_server) then
        (location,port) = @@klink_server.split ':'
        http = Net::HTTP.new location, port
      else
        http = Net::HTTP.new @@klink_server
      end

    end

    # TODO - return values of more than just ID
    def self.write(form_name, record_id, name_values = nil)

      self.establish_connection if @@connected == false

      http = self.build_connection

      headers = {
        'Content-Type' => 'application/xml',
        'User-Agent' => @@link_api_version
      }

      data = ""

      if record_id.nil? then
        # create
        data = %|<Entry Structure="#{form_name}">|
      else
        # update
        data = %|<Entry ID="#{record_id}" Structure="#{form_name}">|
      end

      name_values.each do |n,v|
        if v != nil then
          new_v = Link::clean_input(v)
          data += %|<EntryItem ID="#{n}">#{new_v}</EntryItem>|
        end
      end

      data += "</Entry>"

      if record_id.nil? then
        response, data = http.post("/klink/create/#{@@user}:#{@@password}@#{@@ar_server}", data, headers)
      else
        response, data = http.post("/klink/update/#{@@user}:#{@@password}@#{@@ar_server}", data, headers)
      end

      xmldoc = Document.new data
      ret_val = ""


      # This is a create - return ID number
      if record_id.nil? then
        xmldoc.elements.each('Response/Result/Entry') { |entry|
          ret_val = entry.attributes['ID'] ||=''
        }

        raise xmldoc.to_s if ret_val == ''
        return ret_val
      end

      # Fall through to update -- were we successful in the actual update?
      xmldoc.elements.each('Response') { |entry_item|
        ret_val = entry_item.attributes['Success']
        # TODO - this will not happen as Klink has a bug in updates
        # See Redmine#1179
        if ret_val == 'false' then
          raise xmldoc.to_s
        end

        if ret_val == 'true' then

          # Catch bug #1179 -- look for ERROR in message type - if so -- raise an issue
          xmldoc.elements.each('Response/Messages/Message') {|error_item|
            if error_item.attributes['Type'] == 'ERROR' then
              raise xmldoc.to_s
            end
          }

  
        end

   
      }

   
      return true

    end

    def self.create(form_name, name_values = nil)
      self.write(form_name, nil, name_values)
    end

    def self.update(form_name, record_id, name_values = nil)
      x = self.write(form_name, record_id, name_values)
      return x
    end    

  end

end
