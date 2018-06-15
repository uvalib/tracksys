# This is based on code found here:
#     https://github.com/activeadmin/activeadmin/issues/5201
module ActiveAdmin
   module Views
      module Pages

         module OriginHeaderBuilder
            def build(*args)
               super(*args)
               build_origin_header
            end

            def build_origin_header
               within @head do
                  meta name: "referrer", content: "origin"
               end
            end
         end

         module PopupMessageBuilder
            def build(*args)
               super(*args)
               build_popup_message
            end

            def build_popup_message
               within @body do
                  render 'admin/common/message_popup'
               end
            end
         end

         Base.prepend(OriginHeaderBuilder)
         Base.prepend(PopupMessageBuilder)
      end
   end
end
