class ApplicationController < ActionController::Base
   protect_from_forgery

   helper_method :current_user, :acting_as_user?

   def acting_as_user?
      return !session[:act_as].nil?
   end

   def current_user
      computing_id = request.env['HTTP_REMOTE_USER'].to_s
      if computing_id.blank? && Rails.env != "production"
         computing_id = Settings.dev_user_compute_id
      end
      if @curr_user.nil?
         @curr_user = StaffMember.find_by(computing_id: computing_id)
      end
      if @curr_user.admin? && !session[:act_as].nil?
         @curr_user = StaffMember.find_by(computing_id: session[:act_as])
      end
      return @curr_user
   end

   def authorize
      user = current_user
      unless user and user.active?
         # Display an "Access denied" explanatory page, because one of these
         # conditions has ocurred:
         #   * user can't be authorized by NetBadge for whatever reason
         #   * user passes NetBadge authorization but is not listed in
         #     staff_members table or is not active
         #redirect_to :action => 'access_denied'
         reason = :net_badge
         reason = :no_user if !request.env['HTTP_REMOTE_USER'].nil?
         reason = :not_active if user and !user.active?
         render 'admin/access_denied', :layout => 'requests', :locals=>{ :reason=>reason }
         return false
      end
      return true
   end

   def set_admin_locale
      I18n.locale = :en
   end

   def update
      puts "---------------------- UPDATE ----------------------------"
      if env["HTTP_USER_AGENT"] =~ /Oxygen/ && env["REQUEST_METHOD"] == "PUT"
         xml = Hash.from_xml(request.body.read)
         params.merge!(xml)
      end
   end

end
