ActiveAdmin::Dashboards.build do

  # Define your dashboard sections here. Each block will be
  # rendered on the dashboard in the context of the view. So just
  # return the content which you would like to display.
  
  # == Simple Dashboard Section
  # Here is an example of a simple dashboard section
  #
  #   section "Recent Posts" do
  #     ul do
  #       Post.recent(5).collect do |post|
  #         li link_to(post.title, admin_post_path(post))
  #       end
  #     end
  #   end
  
  # == Render Partial Section
  # The block is rendered within the context of the view, so you can
  # easily render a partial rather than build content in ruby.
  #
  #   section "Recent Posts" do
  #     div do
  #       render 'recent_posts' # => this will render /app/views/admin/dashboard/_recent_posts.html.erb
  #     end
  #   end
  
  # == Section Ordering
  # The dashboard sections are ordered by a given priority from top left to
  # bottom right. The default priority is 10. By giving a section numerically lower
  # priority it will be sorted higher. For example:
  #
  #   section "Recent Posts", :priority => 10
  #   section "Recent User", :priority => 1
  #
  # Will render the "Recent Users" then the "Recent Posts" sections on the dashboard.

  # section "Orders Ready for Delivery", :namespace => :admin do
  #   table_for 
  # end

  section "QA Errors", :namespace => :admin do
    table_for AutomationMessage.has_active_error.qa_workflow do
      column("ID") {|am| link_to "#{am.id}", admin_automation_message_path(am)}
      column :message_type
      column :active_error
      column (:message) {|am| truncate(am.message, :length => 160)}
    end
  end

  section "Archiving Errors", :namespace => :admin do
    table_for AutomationMessage.has_active_error.archive_workflow do
      column("ID") {|am| link_to "#{am.id}", admin_automation_message_path(am)}
      column :message_type
      column :active_error
      column (:message) {|am| truncate(am.message, :length => 160)}
    end
  end

  section "Delivery Errors", :namespace => :admin do
    table_for AutomationMessage.has_active_error.delivery_workflow do
      column("ID") {|am| link_to "#{am.id}", admin_automation_message_path(am)}
      column :message_type
      column :active_error
      column (:message) {|am| truncate(am.message, :length => 160)}
    end
  end

  section "Recent DL Items", :id => 'test' do
    table_for Bibl.in_dl.limit(30) do
      column :call_number
      column ("Title") {|bibl| truncate(bibl.title, :length => 80)}
      column ("Thumbnail") {|bibl| image_tag("http://fedoraproxy.lib.virginia.edu/fedora/get/#{MasterFile.find_by_filename(bibl.exemplar).pid}/djatoka:jp2SDef/getRegion?scale=125", :height => '100')}
      column ("") do |bibl|
        div do
          tweet_button(:via => 'UVaDigServ', :url => "http://search.lib.virginia.edu/catalog/#{bibl.pid}", :text => truncate("#{bibl.title}", :length => 80), :count => 'horizontal')
        end
        div do
          link_to "Pin It", "http://pinterest.com/pin/create/button/?#{URI.encode_www_form("url" => "http://search.lib.virginia.edu/catalog/#{bibl.pid}/view", "media" => "http://fedoraproxy.lib.virginia.edu/fedora/get/#{MasterFile.find_by_filename(bibl.exemplar).pid}/djatoka:jp2SDef/getRegion?scale=800", "description" => "#{bibl.title} &#183; #{bibl.creator_name} &#183; #{bibl.year} &#183; Albert and Shirley Small Special Collections Library, University of Virginia.")}", :class => "pin-it-button"
        end
      end
    end
  end

  # section "Recently Ingested into DL" do
  #   table_for Unit.in_repo.limit(30) do
  #     column("Call Number") {|unit| unit.bibl_call_number}
  #     column("Title") {|unit| truncate(unit.bibl_title, :length => 80)}
  #     column ("Thumbnail") {|unit| image_tag("http://fedoraproxy.lib.virginia.edu/fedora/get/#{MasterFile.find_by_filename(unit.bibl_exemplar).pid}/djatoka:jp2SDef/getRegion?scale=125", :height => '100')}
  #     column ("") do |unit|
  #       div do
  #         tweet_button(:via => 'UVaDigServ', :url => "http://search.lib.virginia.edu/catalog/#{unit.bibl_pid}", :text => truncate("#{unit.bibl_title}", :length => 80), :count => 'horizontal')
  #       end
  #       div do
  #         link_to "Pin It", "http://pinterest.com/pin/create/button/?#{URI.encode_www_form("url" => "http://search.lib.virginia.edu/catalog/#{unit.bibl_pid}/view", "media" => "http://fedoraproxy.lib.virginia.edu/fedora/get/#{MasterFile.find_by_filename(unit.bibl_exemplar).pid}/djatoka:jp2SDef/getRegion?scale=800", "description" => "#{unit.bibl_title} \n\n Albert and Shirley Small Special Collections Library, University of Virginia.")}", :class => "pin-it-button"
  #       end
  #     end
  #   end
  # end

end
