class RequestsController < ApplicationController
  inherit_resources

  def create
    original_params = params
    request_params_without_units = params['request'].except('customer_attributes').except('units_attributes')
    request_params_with_units =  params['request'].except('customer_attributes')
    customer_params = params['request'].slice('customer_attributes')
    units_params = params['request'].slice('units_attributes')

    # Customer Logic
    #
    # Find existing Customer record by email address, or instantiate new one
    @customer = Customer.find_by_email(params[:request][:customer_attributes][:email].strip)
    if @customer.nil?
      @customer = Customer.new
    end

    # Update that record (in memory, without saving it to database yet) with
    # values from user input
    @customer.update_attributes(customer_params['customer_attributes'])

    # request/order
    @request = Request.new(request_params_with_units)
    @request.order_status = 'requested'
    @request.date_request_submitted = Time.now

    begin
      Request.transaction do
        @request.customer = @customer
        @request.save!
        @request.units.each {|unit|
          unit.special_instructions = ""
          unit.special_instructions += "Pages to Digitize: #{unit.request_pages_to_digitize}\n" unless unit.request_pages_to_digitize.blank?
          unit.special_instructions += "Call Number: #{unit.request_call_number}\n" unless unit.request_call_number.blank?
          unit.special_instructions += "Title: #{unit.request_title}\n" unless unit.request_title.blank?
          unit.special_instructions += "Author: #{unit.request_author}\n" unless unit.request_author.blank?
          unit.special_instructions += "Year: #{unit.request_year}\n" unless unit.request_year.blank?
          unit.special_instructions += "Location: #{unit.request_location}\n" unless unit.request_location.blank?
          unit.special_instructions += "Copy: #{unit.request_copy_number}\n" unless unit.request_copy_number.blank?
          unit.special_instructions += "Volumne: #{unit.request_volume_number}\n" unless unit.request_volume_number.blank?
          unit.special_instructions += "Issue: #{unit.request_issue_number}\n" unless unit.request_issue_number.blank?
          unit.special_instructions += "Description: #{unit.request_description}\n" unless unit.request_description.blank?
          unit.save!
        }
      end

    rescue ActiveRecord::RecordInvalid => invalid
      # validation error; return to form (where error messages will be displayed
      # to user and all fields will be populated with their user-entered values)

      # Reconstitute billable address if nothing was filled in at first.
      @request.customer.build_billable_address if @request.customer.billable_address.nil?
      render :action => 'new'
      return
    end

    # send confirmation email
    begin
      OrderMailer.request_confirmation(@request).deliver unless @customer.email.blank?
    rescue Exception => e
      logger.error "Mailer-related error: #{e.inspect}"
    end

    # finish by passing the inherited_resources create method the redirect url with the appropriate request id.
    session[:request_id] = @request.id
    create!{ thank_you_requests_url }
  end

  # Checks whether user has agreed to our terms/conditions for submitting a
  # digitization request and redirects based on whether user is UVa user or not.
  def agree_to_copyright
    # Check whether user agreed to our terms/conditions
    if params[:agree_to_copyright]
      session[:agree_to_copyright] = true
      # Check whether or not UVa user and redirect as appropriate
      if params[:is_uva]
        if params[:is_uva] == 'yes'
          redirect_to uva_requests_url
        else
          redirect_to public_requests_url
        end
      else
        redirect_to requests_path, :notice => 'You must indicate whether or not you are affiliated with U.Va. to continue.'
      end
    else
      redirect_to requests_path, :notice => 'You must agree to the terms and conditions to continue.'
    end
  end

  def new
    @request = Request.new
    @request.build_customer
    @request.customer.build_billable_address
    @request.customer.build_primary_address

    if session[:agree_to_copyright]
      if session[:computing_id] == 'Non-UVA'
        # user is not affiliated with UVa
        @request.customer.academic_status_id = 1 # set academic_status to "Non-UVa"

      else
        # UVa user; get LDAP info for user (already authenticated via NetBadge)
        ldap_info = UvaLdap.new(session[:computing_id])
        uva_status = ldap_info.uva_status.first

	# If a UVa Customer exist, populate @request.customer with Tracksys sourced data.
        customer_lookup = Customer.find_by_email(ldap_info.email.first)
        if customer_lookup.nil?
          uva_computing_id = ldap_info.uva_computing_id
          department_name = ldap_info.department.first

          # Set values for customer pulled from LDAP
          @request.customer_attributes = {
            :email => ldap_info.email.first,
            :first_name => ldap_info.first_name.first,
            :last_name => ldap_info.last_name.first,
            :academic_status_id => AcademicStatus.find_by_name(uva_status).id,
            :primary_address_attributes => {
              :address_1 => ldap_info.address_1.first,
              :address_2 => ldap_info.address_2.first,
              :phone => ldap_info.phone  # no need to do first, since uva_ldap does not return an array for this value.
            }
          }
        else
          @request.customer = Customer.find_by_email(ldap_info.email.first)
        end

        # Always update Academic Status
        @request.customer.academic_status_id = AcademicStatus.find_by_name(uva_status).id

        # Must build a Billable Address if the existing customer doesn't have one
        # so form pre-population doesn't break.
        if not @request.customer.billable_address
          @request.customer.build_billable_address
        end
      end
    end
  end

  # Reroute a non-UVA person to the new form
  def public
    session[:computing_id] = 'Non-UVA'
    redirect_to :action => :new
  end

  def thank_you
    @request = Request.find(session[:request_id])
    @customer = @request.customer
  end

  # If the person has gotten to this method, then he/she has authenticated themselves as a UVA member.
  # So get the person's UVA information and move onto the request new form
  def uva
    # If the HTTP request is local, use a predefined, existing UVa computing ID.
    # Otherwise, get the user's UVa computing ID from the environment variable
    # set by NetBadge.
    cid = request.env['HTTP_REMOTE_USER'].to_s
    if cid.blank? && Rails.env != "production"
      cid = Settings.dev_user_compute_id
    end
    session[:computing_id] = cid
    redirect_to :action => :new
  end

  private

  def clean_input(thing)
    thing.attributes.each do |key, value|
      if value.is_a? String
        thing[key] = value.strip
      end
    end
    return thing
  end
end
