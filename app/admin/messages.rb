ActiveAdmin.register_page "Messages" do
   menu false

   action_item :compose do
      raw("<a id='compose'>Compose New Message</a>")
   end

   content :only=>:index do
      page_size = params[:page_size]
      page_size = 15 if page_size.nil?
      msgs = Message.where(to_id: current_user.id, deleted: 0).page(params[:page]).per(page_size.to_i)

      panel "Inbox" , class: "message-panel" do
         if msgs.length == 0
            h4 do
               "Your inbox is empty"
            end
         else
            paginated_collection(msgs, download_links: false) do
               table_for collection do |msg|
                  column (''), class:"icon" do |msg|
                     cn = "email closed"
                     cn = "email opened" if msg.read
                     span class: "#{cn}" do end
                  end
                  column :from, class:"sender" do |msg|
                     "#{msg.from.full_name} (#{msg.from.email})"
                  end
                  column :subject, class:"subject" do |msg|
                    msg.subject.truncate( 50 )
                  end
                  column :message do |msg|
                     msg.message.truncate( 150 )
                  end
                  column :Date, class:"sent-date" do |msg|
                     msg.sent_at.strftime("%F %r")
                  end
                  column (''), class:"actions" do |msg|
                     div do
                        span class: "msg-button read", "data-msg-id": "#{msg.id}" do "View" end
                     end
                     div do
                        span class: "msg-button delete", "data-msg-id": "#{msg.id}" do "Delete" end
                     end
                  end
               end
            end
         end
         div style: "clear:both" do end
      end

      sent = Message.where(from_id: current_user.id).page(params[:page]).per(page_size.to_i)
      panel "Sent" , class: "message-panel" do
         if sent.length == 0
            h4 do
               "You have no sent messages"
            end
         else
            paginated_collection(sent, download_links: false) do
               table_for collection do |msg|
                  column :to, class:"sender" do |msg|
                     "#{msg.to.full_name} (#{msg.from.email})"
                  end
                  column :subject, class:"subject" do |msg|
                    msg.subject.truncate( 50 )
                  end
                  column :message do |msg|
                     msg.message.truncate( 150 )
                  end
                  column :Date, class:"sent-date" do |msg|
                     msg.sent_at.strftime("%F %r")
                  end
                  column ('read'), class:"icon" do |msg|
                     msg.read
                  end
               end
            end
         end
         div style: "clear:both" do end
      end
      render partial: "reader_modal"
   end

   controller do
      def read_meassge
         msg = Message.find(params[:id])
         msg.update(read: 1)
         session[:last_msg_read] = Time.now
         html = render_to_string partial: "/admin/messages/message", locals: {msg: msg}
         render json: {html: html}
      end

      def create
         to = StaffMember.find(params[:to])
         Message.create!(subject: params[:subject], message: params[:message],
            to_id: params[:to], from_id: current_user.id )
         render plain: "ok"
      end

      def destroy
         msg = Message.find_by(id: params[:id])
         if msg.nil?
            render plain: "Message ID #{params[:id]} not found", status: :not_found and return
         end
         msg.update(deleted: 1, deleted_at: DateTime.now)
         render plain: "OK"
      end
   end
end
