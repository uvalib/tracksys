module Fedora

  require 'digest/md5'
  require 'rest_client'
  require 'rubygems'
  require 'nokogiri'
 
  # Set up REST client
  @resource = RestClient::Resource.new FEDORA_REST_URL, :user => Fedora_username, :password => Fedora_password

  def self.create_or_update_object(thing, label)    
    if thing.exists_in_repo?
      # update object (using Fedora API modifyObject, which uses HTTP PUT)
      http_verb = :put
    else
      # create object (using Fedora API ingest method, which uses HTTP POST)
      http_verb = :post
    end
    url = "/objects/#{thing.pid}"
    url += "?label=" + CGI.escape(label.truncate(100)) unless label.blank?
#    url += "&logMessage=Tracksys"
    @resource[url].send http_verb, '', :content_type => 'text/xml'
  end
  
  def self.add_or_update_datastream(xml, pid, dsID, dsLabel, options = {})
    controlGroup = options[:controlGroup] || nil
    contentType = options[:contentType] || "text/xml"
    multipart = options[:multipart] || true
    dsLocation = options[:dsLocation] || nil
    mimeType = options[:mimeType] || "text/xml"
    versionable = options[:versionable] || "true"

    # 12/2/2010 - Because of upgrade to Fedora 3.4, we are setting the default
    # controlGroup to Managed Datastream (M) for all datastreams.  The only explicit
    # instance of another controlGroup is for POLICY, where they
    # will both have an Redirect (R) controlGroup.  Also include any potential
    # datastreams that are External Reference (E) just in case.

    # Note: When you call Fedora API addDatastream for any of these XML
    # datastreams, Fedora doesn't seem to care whether the datastream already
    # exists or not. If it exists, Fedora updates it; otherwise, Fedora adds
    # it. So I'm not going to bother with checking whether the datastream
    # exists and calling addDatastream (HTTP POST) or modifyDatastream (HTTP
    # PUT) accordingly. Just calling addDatastream works fine 

    url = "/objects/#{pid}/datastreams/#{dsID}?mimeType=#{mimeType}"
    url += "&controlGroup=#{controlGroup}" unless controlGroup.nil?
    url += "&dsLabel=" + URI.encode(dsLabel)
    url += "&dsLocation=#{dsLocation}" unless dsLocation.nil?
    url += "&versionable=#{versionable}"
 
    if controlGroup == 'E' or controlGroup == 'R'
      @resource[url].post :content_type => contentType, :multipart => multipart
    else
      checksum = Digest::MD5.hexdigest(xml)
      url += "&checksumType=MD5"
      @resource[url].post xml, :content_type => contentType, :multipart => multipart
    end
  end

  def self.add_relationship(pid, subject, predicate, object, isLiteral, datatype, contentType)
    url = "/objects/#{pid}/relationships/new?"
    url += "subject=#{subject}"
    url += "&predicate=#{predicate}"
    url += "&object=#{object}"
    url += "&isLiteral=#{isLiteral}"
    url += "&datatype=#{datatype}"

    @resource[url].post :content_type => contentType
    return url
  end

  def self.get_datastream(pid, dsID, format)
    url = "/objects/#{pid}/datastreams/#{dsID}/content?"
    url += "format=#{format}"

    datastream = @resource[url].get
    return datastream
  end

  def self.purge_datastream(pid, datastream)
    url = "/objects/#{pid}/datastreams/#{datastream}"
    @resource[url].delete
  end
  
  def self.purge_object(pid)
    url = "/objects/#{pid}"
    @resource[url].delete
  end
end
