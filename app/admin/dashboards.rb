ActiveAdmin::Dashboards.build do
  # return the content which you would like to display.
  # Here is an example of a simple dashboard section
  #
  #   section "Recent Posts" do
  #     ul do
  #         li link_to(post.title, admin_post_path(post))
  #     end
  
  # The block is rendered within the context of the view, so you can
  # easily render a partial rather than build content in ruby.
  #
  #     end
  #   end
  # == Section Ordering
  # priority it will be sorted higher. For example:
  #

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

  section "Finalization", :namespace => :admin do
    table do
      tr do
        td do "Orders Ready for Delivery" end
        td do link_to "#{Order.ready_for_delivery.count}", "admin/orders?scope=ready_for_delivery" end
      end
      tr do
        td do "Burn Orders to DVD" end
        td do link_to "#{Order.ready_for_delivery.has_dvd_delivery.count}", "admin/orders?scope=ready_for_dvd_burning" end
      end
      tr do
        td do "Unfinished Units of Partially Finalized Orders" end
        td do link_to "", "" end
      end
    end
    # div do
    #   link_to "Orders Ready for Delivery (#{Order.ready_for_delivery.count})", "admin/orders?scope=ready_for_delivery"
    # end
  end

  section "Unfinished Units of Partially Finalized Orders" do

  end

  section "Burn to DVD" do

  end

  section "Recent DL Items", :namespace => :admin do
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