# Methods common to models that have a :pid attribute.
module Pidable
  require 'solr'

  require 'activemessaging/processor'
  include ActiveMessaging::MessageSender
  publishes_to :update_fedora_datastreams
   
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

  # Query a given Solr index to determine if object's index record is found there.  A default Solr index is used
  # if none is provided at method invocation.
  def exists_in_index?(solr_url = nil)
    solr_url = STAGING_SOLR_URL if solr_url.nil?
    if pid.nil?
      return false
    else
      @solr_connection = Solr::Connection.new("#{solr_url}", :autocommit => :off)

      begin
        hits = @solr_connection.query("id:#{pid.gsub(/:/, '?')}").hits
      rescue RestClient::ResourceNotFound, RestClient::InternalServerError, RestClient::RequestTimeout
        return false
      end

      return true unless hits.length != 1
    end
  end

  # Returns a boolean indicating whether an object with the same PID as this
  # one exists in the Fedora repo
  def exists_in_repo?
    if ! self.respond_to?(:pid)
      return false
    elsif pid.nil?
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

  def remove_from_repo
    if pid.nil?
      return false
    else
      resource = RestClient::Resource.new FEDORA_REST_URL, :user => Fedora_username, :password => Fedora_password
      url = "/objects/#{pid}"

      begin
        response = resource[url].delete
      rescue RestClient::ResourceNotFound, RestClient::InternalServerError, RestClient::RequestTimeout
        return false
      end
      return response.include? "#{Time.now.strftime('%Y-%m-%d')}"
    end
  end

  def remove_from_index(solr_url = nil)
    solr_url = STAGING_SOLR_URL if solr_url.nil?
    if pid.nil?
      return false
    else
      @solr_connection = Solr::Connection.new("#{solr_url}", :autocommit => :off)

      begin
        @solr_connection.delete(pid)
      rescue RestClient::ResourceNotFound, RestClient::InternalServerError, RestClient::RequestTimeout
        return false
      end
      return true 
    end

  end

  # Methods for ingest and Fedora management workflows
  def update_metadata(datastream)
    message = ActiveSupport::JSON.encode( { :object_class => self.class.to_s, :object_id => self.id, :datastream => datastream })
    publish :update_fedora_datastreams, message
    # flash[:notice] = "#{params[:datastream].gsub(/_/, ' ').capitalize} datastream(s) being updated."
    # redirect_to :action => "show", :controller => "bibl", :id => params[:object_id]
  end

  def fedora_url
    return "#{FEDORA_REST_URL}/objects/#{self.pid}"
  end

  def solr_url(url=SOLR_URL)
    return "#{url}/select?q=id:\"#{self.pid}\""
  end
end
