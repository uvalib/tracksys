# = AddPidObserver
#
# Certain classes of objects are destined for ingestion into a Fedora repository.  Those objects, observered here,
# are assigned PIDs at the time of their creation (or afterwards if for some reason they were not supplied previously.)
# Those PIDs are drawn from the Fedora repository and are acquired through the AssignPids module.
#
# PIDs should only be assigned after validation in order to prevent issuing an invalid (and possibly never created) object.
class AddPidObserver < ActiveRecord::Observer 
  observe :bibl, :component, :master_file

  def before_save(record)
    if record.pid.blank?
      begin
        record.pid = AssignPids.get_pid
      rescue Exception => e
        # ErrorMailer.deliver_notify_pid_failure(e) unless @skip_pid_notification
      end
    end
  end
end