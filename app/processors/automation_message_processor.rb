# This processor writes the success, error and failure messages to TrackSys as AutomationMessage objects.  
#
# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010

class AutomationMessageProcessor < ApplicationProcessor

  subscribes_to :automation_message, {'activemq.prefetchSize' => 50}

  def on_message(message)
    logger.debug "AutomationMessageProcessor received: " + message
    
    # Decode JSON message into Ruby hash
    decoded = ActiveSupport::JSON.decode(message)
    if decoded.is_a? Hash
      hash = decoded.symbolize_keys
    else
      # value passed was not JSON-encoded
      hash = {:message => decoded.to_s}
    end
    
    # Save values to tracksys database for later review by staff
    am = AutomationMessage.new
    hash.each do |key,value|
      am.send "#{key}=".to_sym, value
    end
    begin
      am.save!
    rescue Exception => err
      logger.error "AutomationMessageProcessor: Can't save message to database: #{err.message}\nMessage was:\n#{message}"
    end
  end

  # Override on_error from ApplicationProcessor. This method is called
  # whenever an exception is raised within on_message. All exceptions are
  # raised, terminating processing.
  
  def on_error(err)
    raise err
  end
end
