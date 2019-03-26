# This is based on code found here:
#     https://github.com/activeadmin/activeadmin/issues/5201
module ActiveAdmin
   module Views
      module Pages
         # Override some key methohods of the base class defined here:
         #    https://github.com/activeadmin/activeadmin/blob/master/lib/active_admin/views/pages/base.rb
         module TracksysOverrides
            def build_active_admin_head
               super
               within head do
                  meta name: "referrer", content: "origin"
                  script src: "//cdnjs.cloudflare.com/ajax/libs/Chart.js/2.7.0/Chart.bundle.min.js", type: "text/javascript"
                  script src: "//cdnjs.cloudflare.com/ajax/libs/jquery.panzoom/3.2.2/jquery.panzoom.js", type: "text/javascript"
               end
            end

            def build(*args)
               super(*args)
               within body do
                  render 'admin/common/message_popup'
               end
            end
         end

         # Prepend will add this module in front of AcriveAdmin::Views::Pages::Base in the class heirarchy,
         # allowing the extra functionality necessary for header updates and messaging UI to be included 
         # in all instances
         Base.prepend(TracksysOverrides)
      end
   end
end

