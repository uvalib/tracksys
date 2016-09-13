
module DplaHelper

   def relative_pid_path( pid )
      pid_parts = pid.split(":")
      base = pid_parts[1]
      parts = base.scan(/.../) # break up into 3 digit sections, but this can leave off last digit
      parts << base.last if parts.length * 3 !=  base.length  # get last digit if necessary
      pid_dirs = parts.join("/")
      return File.join(pid_parts[0], pid_dirs)
   end

   def mods_url( pid )
      partial =  relative_pid_path(pid)
      return "#{Settings.delivery_url}dpla/mods/#{relative_pid_path(pid)}/#{pid}.xml"
   end
end
