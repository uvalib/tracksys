ActiveAdmin.register_page "Messages" do
   menu false

   content :only=>:index do
      page_size = params[:page_size]
      page_size = 5 if page_size.nil?
      msgs = Message.where(to_id: current_user.id).page(params[:page]).per(page_size.to_i)

      panel "Inbox" , class: "message-panel" do
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
                     span class: "msg-button delete" do "Delete" end
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
         html = render_to_string partial: "/admin/messages/message", locals: {msg: msg}
         render json: {html: html}
      end
   end
end
