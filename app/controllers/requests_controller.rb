class RequestsController < ApplicationController

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
               session[:computing_id] = 'Non-UVA'
               redirect_to :action => :new
            end
         else
            redirect_to requests_path, :notice => 'You must indicate whether or not you are affiliated with U.Va. to continue.'
         end
      else
         redirect_to requests_path, :notice => 'You must agree to the terms and conditions to continue.'
      end
   end

   # A new request is been started. Confirm/get customer info and render the first step in the
   # order process: customer information
   #
   def new
      Rails.logger.info "Creating new request for #{session[:computing_id]}. Agreed? #{session[:agree_to_copyright]}"
      @customer = Customer.new(academic_status_id: 1)
      if session[:agree_to_copyright]
         if session[:computing_id] != 'Non-UVA'
            # UVa user; get LDAP info for user (already authenticated via NetBadge)
            begin
               ldap_info = UvaLdap.new(session[:computing_id])
               @customer = Customer.new(
                  email: ldap_info.email.first,
                  first_name: ldap_info.first_name.first,
                  last_name:  ldap_info.last_name.first,
                  academic_status_id: AcademicStatus.find_by( name: ldap_info.uva_status.first).id
               )
            rescue Exception=>e
               # Failed trying to get UVA info; default to not affiliated with UVa
               Rails.logger.error "Error getting UVA info: #{e}"
            end
         end
      end
      render :customer_step
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

   # POST customer info from step 1 of the request process; update existing record or create new
   #
   def customer_update
      customer = Customer.find_by(email: params[:email])
      if customer.nil?
         Rails.logger.info("Customer with email '#{params[:email]}' not found. Creating new customer")
         customer = Customer.create(
            first_name: params[:first_name], last_name: params[:last_name],
            email: params[:email], academic_status_id: params[:academic_status_id]
         )
         if !customer.valid?
            @errors = customer.errors
            @customer = Customer.new(
               email: params[:email],
               first_name: params[:first_name],
               last_name: params[:last_name],
               academic_status_id: params[:academic_status_id]
            )
            render :customer_step
            return
         end
      else
         if !customer.update(last_name: params[:last_name], first_name: params[:first_name], academic_status_id: params[:academic_status_id])
            @errors = customer.errors
            @customer =  Customer.new(
               email: params[:email],
               first_name: params[:first_name],
               last_name: params[:last_name],
               academic_status_id: params[:academic_status_id]
            )
            render :customer_step
            return
         end
      end

      redirect_to controller: 'requests', action: 'address_step', customer_id: customer.id, type: "primary"
   end

   # GET request to show primary/business address step
   #
   def address_step
      @address = Address.find_by(addressable_id: params[:customer_id], address_type: params[:type])
      if @address.nil?
         @address =  Address.new(addressable_id: params[:customer_id],
            addressable_type:"Customer", address_type: params[:type])
      else
         if params[:type] == "primary" && !Address.find_by(addressable_id: params[:customer_id], address_type: "billable_address").nil?
            @has_billable = true
         end
      end
   end

   # POST address info from step 2 of the request process; primary/business address create/update
   #
   def address_update
      @address = Address.find_by(addressable_id: params[:customer_id], address_type: params[:address_type])
      if @address.nil?
         @address = Address.new( address_params )
         @address.addressable_id = params[:customer_id]
         @address.addressable_type = "Customer"
         @address.save
      else
         @address.update(address_params)
      end

      if !@address.valid?
         @errors = @address.errors
         render :address_step
         return
      end

      if @address.address_type == "primary" && params[:has_billing_address]
         redirect_to controller: 'requests', action: 'address_step', customer_id: @address.addressable_id, type: "billable_address"
      else
         redirect_to controller: 'requests', action: 'request_step', customer_id: @address.addressable_id
      end
   end

   # GET request to show general request info step
   #
   def request_step
      @customer_id = params[:customer_id]
   end

   # POST request to submit order and items and generate a review screen
   #
   def review_step
      @customer = Customer.find(params[:customer_id])
      @items = JSON.parse(params[:order_items])
      @date_due = params[:date_due]
      @special_instructions = params[:special_instructions]
      @intended_use = IntendedUse.find(params[:intended_use_id])
   end

   # POST to validate addition of an item to an order. Returns JSON with an HTML
   # snippet of the item for a review screen
   #
   def add_item
      item = params[:item]
      if item['title'].blank?
         render json: { success: false, message: "Title is required"}, status: :bad_request
         return
      end
      if item['pages'].blank?
         render json: { success: false, message: "Image or page numbers are required"}, status: :bad_request
         return
      end

      oi = OrderItem.new( title: item["title"], pages: item["pages"],
         call_number: item["callNumber"], author: item["author"], year: item["year"],
         location: item["location:"], description: item["description"],
         source_url: item["sourceUrl"] )
      html = render_to_string partial: "review_item", locals: {item: oi, idx: params['index'].to_i }
      render json: {success: true, html: html}
   end

   # Last step of order wizard complete and submit clicked. Create the order and items
   #
   def create
      @customer = Customer.find(params[:customer_id])
      use = IntendedUse.find(params[:intended_use_id])
      @request = Order.new( order_params )
      @request.date_request_submitted = DateTime.now
      @request.order_status = "requested"
      @request.save!
      JSON.parse(params[:order_items]).each do | req |
         OrderItem.create!( order: @request, title: req["title"], pages: req["pages"],
            call_number: req["callNumber"], author: req["author"], year: req["year"],
            location: req["location:"], description: req["description"],
            source_url: req["sourceUrl"], intended_use: use
         )
      end

      # send confirmation email
     begin
        OrderMailer.request_confirmation(@request).deliver unless @customer.email.blank?
     rescue Exception => e
        logger.error "Mailer-related error: #{e.inspect}"
     end

     render :thank_you
   end

   def address_params
      params.permit(:address_type, :first_name, :last_name, :address_1, :address_2, :city, :state, :post_code, :country, :phone)
   end
   def order_params
      params.permit(:customer_id, :date_due, :special_instructions)
   end
end
