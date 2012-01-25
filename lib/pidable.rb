# Methods common to models that have a "pid" attribute.
module Pidable
 
  def get_object_label
    resource = RestClient::Resource.new FEDORA_REST_URL, :user => Fedora_username, :password => Fedora_password
    
    url = "/objects/#{self.pid}?format=xml"
  
    begin
      response = resource[url].get
      xml = Nokogiri.XML(response)
      object_label = xml.xpath('//fedora:objectProfile/fedora:objLabel/text()', 'fedora' => 'http://www.fedora.info/definitions/1/0/access/').to_s
    rescue RestClient::ResourceNotFound, RestClient::InternalServerError, RestClient::RequestTimeout
      return false
    end
    return object_label
  end

  def get_datastreams_dsID
   # Set up REST client
    resource = RestClient::Resource.new FEDORA_REST_URL, :user => Fedora_username, :password => Fedora_password
    dsIDs = Array.new

    url = "/objects/#{self.pid}/datastreams?format=xml"
    begin
      response = resource[url].get
      xml = Nokogiri.XML(response)
      xml.xpath('//fedora:objectDatastreams/fedora:datastream/@dsid', 'fedora' => 'http://www.fedora.info/definitions/1/0/access/').each {|dsID|
        dsIDs.push(dsID.to_s)
      }
    rescue RestClient::ResourceNotFound, RestClient::InternalServerError, RestClient::RequestTimeout
      return false
    end
    return dsID
  end

  def get_datastreams_label
   # Set up REST client
    resource = RestClient::Resource.new FEDORA_REST_URL, :user => Fedora_username, :password => Fedora_password
    labels = Array.new

    url = "/objects/#{self.pid}/datastreams?format=xml"
    begin
      response = resource[url].get
      xml = Nokogiri.XML(response)
      xml.xpath('//fedora:objectDatastreams/fedora:datastream/@label', 'fedora' => 'http://www.fedora.info/definitions/1/0/access/').each {|label|
        labels.push(label.to_s)
      }
    rescue RestClient::ResourceNotFound, RestClient::InternalServerError, RestClient::RequestTimeout
      return false
    end
    return labels
  end

  # Returns a boolean indicating whether a datastream for a piddable object
  # exists in the Fedora repo
  def datastream_exists?(dsID)
    # Set up REST client
    resource = RestClient::Resource.new FEDORA_REST_URL, :user => Fedora_username, :password => Fedora_password

    url = "/objects/#{self.pid}/datastreams/#{dsID}?format=xml"
    begin
      response = resource[url].get
    rescue RestClient::ResourceNotFound, RestClient::InternalServerError, RestClient::RequestTimeout
      return false
    end
    return true
  end

  def exists_in_index?
    if pid.nil?
      return false
    else
      @solr_connection = Solr::Connection.new("#{SOLR_URL}", :autocommit => :off)

      begin
        hits = @solr_connection.query("id:#{pid.gsub(/:/, '?')}").hits
      rescue RestClient::ResourceNotFound, RestClient::InternalServerError, RestClient::RequestTimeout
        return false
      end

      return false unless hits.length == 1
    end
  end

  # Returns a boolean indicating whether an object with the same PID as this
  # one exists in the Fedora repo
  def exists_in_repo?
    if pid.nil?
      return false
    else
      resource = RestClient::Resource.new FEDORA_REST_URL, :user => Fedora_username, :password => Fedora_password
      query = "ASK { <info:fedora/#{pid}> <fedora-model:hasModel> <info:fedora/fedora-system:FedoraObject-3.0> }"
      url = "/risearch?type=tuples&lang=sparql&format=csv&query=#{URI.escape(query)}"

      begin
        response = resource[url].get
      rescue RestClient::ResourceNotFound, RestClient::InternalServerError, RestClient::RequestTimeout
          return false
      end

      if response.include? "true"
        return true
      else
        return false
      end


      # # Determine whether this object exists (using Fedora API findObjects, which uses HTTP GET)
      # # * If Fedora finds the object, no exception occurs
      # # * If Fedora can't find the object, RestClient::ResourceNotFound exception occurs
      # # * If any other exception occurs, it remains unhandled and gets raised
      # resource = RestClient::Resource.new FEDORA_REST_URL, :user => Fedora_username, :password => Fedora_password
      # url = "/objects?query=pid%3D#{pid}&resultFormat=xml&pid=true"
 
      # begin
      #   response = resource[url].get
      # rescue RestClient::ResourceNotFound, RestClient::InternalServerError, RestClient::RequestTimeout
      #   return false
      # end
      # return response.include? "#{pid}"
    end
  end

    def exists_in_repo2?
    if pid.nil?
      return false
    else
      # Determine whether this object exists (using Fedora API findObjects, which uses HTTP GET)
      # * If Fedora finds the object, no exception occurs
      # * If Fedora can't find the object, RestClient::ResourceNotFound exception occurs
      # * If any other exception occurs, it remains unhandled and gets raised
      resource = RestClient::Resource.new FEDORA_REST_URL, :user => Fedora_username, :password => Fedora_password
      url = "/objects?query=pid%3D#{pid}&resultFormat=xml&pid=true"
 
      begin
        response = resource[url].get
      rescue RestClient::ResourceNotFound, RestClient::InternalServerError, RestClient::RequestTimeout
        return false
      end
      return response.include? "#{pid}"
    end
  end



  # Below is the SOAP approach to the same method

  # def exists_in_repo?
  #   return false if pid.nil?
  #   
  #   # Create SOAP client for Fedora API-A (access API)
  #   require 'soap/wsdlDriver'
  #   driver = SOAP::WSDLDriverFactory.new(Fedora_apia_wsdl).create_rpc_driver
  #   driver.streamhandler.filterchain << SendBasicAuthAlwaysFilterFactory.create(Fedora_username,Fedora_password) 
  # 
  #   # begin
  #   #   driver.getObjectProfile(:pid=>pid)
  #   #   return true
  #   # rescue 
  #   #   return false
  #   # end
  #   begin
  #     result = driver.getObjectProfile(:pid=>pid)
  #     puts result.inspect #DEBUG
  #     return true
  #   rescue SOAP::FaultError => e
  #     if e.message =~ /ObjectNotInLowlevelStorageException/
  #       return false
  #     else
  #       raise e
  #     end
  #   end
  # end

end
