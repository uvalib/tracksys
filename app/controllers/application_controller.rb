class ApplicationController < ActionController::Base
  protect_from_forgery

  # Displays an "Access denied" explanatory page. See ApplicationController#authorize
  def access_denied
    render :template => 'shared/access_denied', :layout => false
  end

  def current_user
    computing_id = request.env['HTTP_REMOTE_USER'].to_s
    return StaffMember.find_by_computing_id(computing_id)
  end

  def authorize
    # computing_id = request.env['HTTP_REMOTE_USER'].to_s
    # @user = StaffMember.find_by_computing_id(computing_id)
    @user = current_user
    unless @user and @user.active?
      # Display an "Access denied" explanatory page, because one of these
      # conditions has ocurred:
      #   * user can't be authorized by NetBadge for whatever reason
      #   * user passes NetBadge authorization but is not listed in
      #     staff_members table or is not active
      redirect_to :action => 'access_denied'
      return false
    end 
  end

  def update
    if env["HTTP_USER_AGENT"] =~ /Oxygen/ && env["REQUEST_METHOD"] == "PUT"
      xml = Hash.from_xml(request.body.read)
      params.merge!(xml)
    end
  end

  protected

  def user_for_paper_trail
    user = StaffMember.find_by_computing_id(request.env['HTTP_REMOTE_USER'].to_s)
    if not user.nil?
      user.computing_id
    else
      "Unknown"
    end
  end
end