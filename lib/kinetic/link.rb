# = Introduction
# The Klink Ruby API is a Ruby wrapper library to be used with a Klink web server.  It provides a simple, easy to use
# llbrary of methods to access data and other information from a Remedy server.
#

require 'net/http'
require 'uri'
require 'rexml/document'
require 'yaml'
include REXML


module Kinetic
  # Represents a connection to a Klink server.
  class Link

    Kinetic::Link::VERSION = '1.0.7 DEV'

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
    # Example: "SampleUser","Sample Password","klinkserver:8081.yourcompany.com","remedy.yourcompany.com"
    # TODO -- add AR Server port??? -- how does that work with Klink?
    def self.set_connection(user,password,klink_server,ar_server)
      @@user = user
      @@password = password
      @@klink_server = klink_server
      @@ar_server = ar_server
    end
    
    # return true false, if false also return a message of how it failed
    # get a list of forms - if that works - all is well
    # all servers have some sort of form available to public
    def self.test_connection
      # This block tests the connection to the klink server alone
      begin
        html = Net::HTTP.get(URI.parse("http://#{@@klink_server}/klink/about"))
        raise unless html =~ /<a href="http:\/\/www\.kineticdata\.com">/
      rescue
        return false, %`Could not connect to the specified Kinetic Link server "#{@@klink_server}"`
      end
      # This block tests the connection to the klink server and the remedy server
      # by attempting to retrieve data from the remedy server through klink
      begin
        if(self.structures.length > 0) then
          return true
        else
          return false, %`Could not find any forms on server "#{@@ar_server}"`
        end
      rescue Timeout::Error
        return false, %`Timeout occured when attempting to retrieve data from server "#{@@ar_server}"`
      rescue
        return false, %`Exception raised when attempting to retrieve data from server "#{@@ar_server}"`
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
      self.establish_connection if @@connected == false
      
      form_name_escaped = URI.escape(form_name).gsub("&", "%26")
      request_id_escaped = URI.escape(request_id).gsub("&", "%26")
      uri = "http://#{@@klink_server}/klink/delete/#{@@user}:#{@@password}@#{@@ar_server}/" <<
        "#{form_name_escaped}/#{request_id_escaped}"

      response = Net::HTTP.get(URI.parse(uri))
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
    
    # Finds the entry on the form identified by the request_id parameter.  If the
    # fields parameter is specified, only those fields will be retrieved from the
    # form.  There can be a noticeable performance gain when retrieving only a subset
    # of fields from large forms.
    #
    # - form_name - the name of the form to retrieve records from
    # - request_id - the value of the Request ID field for the record to be retrieved
    # - fields - an optional list (Array, or comma-separated String) of field ids
    #            to retrieve (default is all fields)
    #
    # Returns a hash that represents the record.  The hash contains a mapping of
    # fields id to field value for each field specified.
    #
    def self.entry(form_name, request_id, fields = nil)
      self.establish_connection if @@connected == false

      form_name_escaped = URI.escape(form_name).gsub("&", "%26")
      request_id_escaped = URI.escape(request_id).gsub("&", "%26")

      # build up the string of field ids to return
      fields ||= ''
      fields = fields.join(",") if fields.is_a? Array
      fields.gsub!(' ', '')
      fields_escaped = URI.escape(fields).gsub("&", "%26")
      field_list = "?items=#{fields_escaped}" unless fields_escaped.empty?
      
      uri = "http://#{@@klink_server}/klink/entry/#{@@user}:#{@@password}@#{@@ar_server}/" <<
        "#{form_name_escaped}/#{request_id_escaped}#{field_list}"

      response = Net::HTTP.get(URI.parse(uri))
      xmldoc = Document.new(response)

      ret_val = Hash.new

      # TODO -- handle 'Status History' -- right now I just convert to ''
      xmldoc.elements.each('Response/Result/Entry/EntryItem') { |entry_item|
        ret_val[entry_item.attributes['ID']] = entry_item.text || ''
      }

      return ret_val

    end    
    
    # Finds all the records from a form that match the qualification.  If only a subset of fields on the form
    # should be returned, please see the entries_with_fields method.
    #
    # - form_name - the name of the form to retrieve records from
    # - qual - an optional qualification used to select the records: i.e.  "1=1"
    # - sort - an optional list (Array, or comma-separated String) of field ids to sort the results
    #--
    # TODO:  Add sort order (ASC | DESC)
    #++
    # Returns an array of Request IDs of the records on the form that match the qualification, sorted in the order specified with the sort parameter.
    #
    def self.entries(form_name, qual = nil, sort = nil)
      self.establish_connection if @@connected == false

      qual ||= ''
      qualification = "?qualification=#{qual}"
      
      sort ||= ''
      sort = options.join(",") if sort.is_a? Array
      sort.gsub!(' ', '')
      sort_list = "&sort=#{sort}" unless sort.nil? || sort.empty?
      
      uri = URI.escape("http://#{@@klink_server}/klink/entries/#{@@user}:#{@@password}@#{@@ar_server}/#{form_name}#{qualification}#{sort_list}")

      response = Net::HTTP.get(URI.parse(uri))
      xmldoc = Document.new(response)

      ret_val = Array.new

      xmldoc.elements.each('Response/Result/EntryList/Entry') { |id| 
        ret_val << id.attributes['ID']
      }

      return ret_val

    end
    
    # Finds all the records from a form that match the qualification.  If the fields option is specified, only those fields will be retrieved from the form.
    # There can be a noticeable performance gain when retrieving only a subset of fields from large forms. If any of the specified fields is a diary 
    # field, or a long character field that cannot be returned with ARGetList, the call will silently fall back to retrieving a list of entry ids, 
    # then retrieving each entry separately.
    #
    # - form_name - the name of the form to retrieve records from
    # - options - an optional hash of additional parameters to use with the query
    #
    # Available Options
    # - :qual - an optional qualification used to select the records: i.e.  "1=1"
    # - :sort - an optional list (Array, or comma-separated String) of field ids to sort the results
    # - :fields - an optional list (Array, or comma-separated String) of field ids to retrieve (default is no fields)
    #--
    # TODO:  Add sort order (ASC | DESC)
    #++
    # Returns an array of hashes that represent each record that matched the qualification.  Each hash in the array contains a mapping of fields id to field value.
    #
    def self.entries_with_fields(form_name, options = {})
      self.establish_connection if @@connected == false
      
      # build up the qualification as the first parameter - not necessary as the first, but we need to include the ? somewhere.
      qual = options[:qual] || ''
      qualification = "?qualification=#{qual}"
      
      # build up the string of sort fields
      sort = options[:sort] || ''
      sort = options.join(",") if sort.is_a? Array
      sort.gsub!(' ', '')
      sort_list = "&sort=#{sort}" unless sort.nil? || sort.empty?
      
      # build up the string of field ids to return
      fields = options[:fields] || ''
      fields = fields.join(",") if fields.is_a? Array
      fields.gsub!(' ', '')
      field_list = "&items=#{fields}" unless fields.nil? || fields.empty?
      
      uri = URI.escape("http://#{@@klink_server}/klink/entries/#{@@user}:#{@@password}@#{@@ar_server}/#{form_name}#{qualification}#{sort_list}#{field_list}")

      ret_val = Array.new
      
      # try to get the results
      begin
        response = Net::HTTP.get(URI.parse(uri))
        xmldoc = Document.new(response)
        
        # check if there are any errors retrieving dialry fields or character fields that are too long
        if xmldoc.root.attributes['Success'] == "false"
          message = xmldoc.elements["Response/Messages/Message"]
          message_text = message.text if message
          raise StandardError.new(message_text || "Fall back to retrieving each record individually")
        end

        xmldoc.elements.each('Response/Result/EntryList/Entry') { |id| 
          entry = { '1' => id.attributes['ID'] }
          id.elements.each('EntryItem') { |item_id|
            entry[item_id.attributes['ID']] = item_id.text || ''
          }
          ret_val << entry
        }
      rescue StandardError => e
        # if there was a problem, try to get a list of ids, then retrieve each record individually
        self.entries(form_name, qual, sort).each { |entry_id|
          ret_val << self.entry(form_name, entry_id, fields)
        }
      end

      return ret_val
    end

    # return a list of statistics
    # TODO - need to take params 
    def self.statistics(items = {})
      self.establish_connection if @@connected == false

      param_list = "?items=#{items}" if items.size > 0
      uri = URI.escape("http://#{@@klink_server}/klink/statistics/#{@@user}:#{@@password}@#{@@ar_server}#{param_list}")
      
      response = Net::HTTP.get(URI.parse(uri))
      xmldoc = Document.new(response)

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

      param_list = "?items=#{items}" if items.size > 0
      uri = URI.escape("http://#{@@klink_server}/klink/configurations/#{@@user}:#{@@password}@#{@@ar_server}#{param_list}")

      response = Net::HTTP.get(URI.parse(uri))
      xmldoc = Document.new(response)

      ret_val = Hash.new

      xmldoc.elements.each('Response/Result/Configurations/Configuration') { |conf| 
        ret_val[conf.attributes['Name']]=conf.text ||=''
      }

      return ret_val

    end

    # return a list of structures
    def self.structures
      self.establish_connection if @@connected == false

      uri = URI.escape("http://#{@@klink_server}/klink/structures/#{@@user}:#{@@password}@#{@@ar_server}")

      response = Net::HTTP.get(URI.parse(uri))
      xmldoc = Document.new(response)

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

 
    def self.structure(form_name)
      self.establish_connection if @@connected == false
      
      uri = URI.escape("http://#{@@klink_server}/klink/structure/#{@@user}:#{@@password}@#{@@ar_server}/#{form_name}")

      response = Net::HTTP.get(URI.parse(uri))
      xmldoc = Document.new(response)

      structure_map = Hash.new
      xmldoc.elements.each('Response/Result/Structure/StructureItem') { |structure_item|
      
        #        structure_map[structure_item.attributes['ID']] = structure_item.attributes['Name']

        name = structure_item.attributes['Name']
        id = structure_item.attributes['ID']
        type = structure_item.attributes['Type']  # DATA/ATTACHMENT


        field_hash = Hash.new

        field_hash["Name"] = name
        field_hash["ID"] = id
        field_hash["Type"] = type

        structure_item.elements.each('DataType') { |value|
          field_hash["DataType"] = value.text
        }

        structure_item.elements.each('DefaultValue') { |value|
          field_hash["DefaultValue"] = value.text
        }

        structure_item.elements.each('EntryMode') { |value|
          field_hash["EntryMode"] = value.text
        }

        attr = Array.new
        structure_item.elements.each('Attributes/Attribute') { |value|

          attr << value.text
        }
        field_hash["attributes"] = attr


        # TODO - store it by name and by id -- easier to find
        #structure_map[name] = field_hash
        structure_map[id] = field_hash

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
        response, data = http.post(URI.escape("/klink/create/#{@@user}:#{@@password}@#{@@ar_server}"), data, headers)
      else
        response, data = http.post(URI.escape("/klink/update/#{@@user}:#{@@password}@#{@@ar_server}"), data, headers)
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
