module AddPidBeforeSave
  
  # Several classes of objects (Bibl, Component, MasterFile) all need PIDs, pulled from Fedora
  # at the time they are saved.  Since th
  def add_pid_before_save
    if self.pid.blank?
      begin
        self.pid = AssignPids.get_pid
      rescue Exception => e
        # ErrorMailer.deliver_notify_pid_failure(e) unless @skip_pid_notification
      end
    end
  end

end

ActiveRecord::Base.send(:include, AddPidBeforeSave)