ActiveAdmin::Dashboards.build do

  section "Order Processing", :namespace => :patron, :priority => 1, :width => '50%' do
    table do
      tr do
        td do "Requests Awaiting Approval" end
        td do link_to "#{Order.awaiting_approval.not_from_fine_arts.count}", patron_orders_path(:scope => 'awaiting_approval') end
      end
      tr do
        td do "Deferred Requests" end
        td do link_to "#{Order.deferred.not_from_fine_arts.count}", patron_orders_path(:scope => 'deferred') end
      end
      tr do
        td do "Units Awaiting Copyright Approval" end
        td do link_to "#{Unit.awaiting_copyright_approval.count}", patron_units_path(:scope => 'awaiting_copyright_approval') end
      end
      tr do
        td do "Units Awaiting Condition Approval" end
        td do link_to "#{Unit.awaiting_condition_approval.count}", patron_units_path(:scope => 'awaiting_condition_approval') end
      end
    end
  end

  section "Digitization Services Checkouts", :namespace => :patron, :priority => 2, :width => '50%' do
    table do
      tr do
        td do "Unreturned Material" end
        td do link_to "#{Unit.overdue_materials.count}", patron_units_path(:scope => 'overdue_materials') end
      end
      tr do
        td do "Materials Currently in Digitization Services" end
        td do link_to "#{Unit.checkedout_materials.count}", patron_units_path(:scope => 'checkedout_materials') end
      end
    end
  end
  
  # section "Requests Awaiting Approval (#{Order.awaiting_approval.count})", :namespace => :patron, :priority => 1, :width => '33%', :toggle => 'hide' do
  #   table_for Order.awaiting_approval do
  #     column :id do |order|
  #       link_to order.id, patron_order_path(order)
  #     end
  #     column (:date_due) {|order| format_date(order.date_due)}
  #     column :agency
  #     column "Name" do |order|
  #       link_to order.customer_full_name, patron_customer_path(order.customer)
  #     end
  #   end
  # end

  # section "Deferred Requets (#{Order.deferred.count})", :width => '33%', :namespace => :patron, :toggle => 'hide' do
  #   table_for Order.deferred do
  #     column :id do |order|
  #       link_to order.id, patron_order_path(order)
  #     end
  #     column (:date_due){|order| format_date(order.date_due)}
  #     column (:date_deferred) {|order| format_date(order.date_deferred)}
  #     column :agency
  #     column "Name" do |order|
  #       link_to order.customer_full_name, patron_customer_path(order.customer)
  #     end
  #   end
  # end

  # section "Units Awaiting Condition Approval (#{Unit.awaiting_copyright_approval.count})", :width => '33%', :namespace => :patron, :toggle => 'hide' do
  #   table_for Unit.awaiting_condition_approval do
  #     column ("Unit ID") {|unit| link_to unit.id, patron_unit_path(unit)}
  #     column (:order_date_due) {|unit| format_date(unit.order_date_due)}
  #     column :bibl_title
  #     column :bibl_call_number
  #   end
  # end

  # section "Units Awaiting Copyright Approval (#{Unit.awaiting_copyright_approval.count})", :width => '33%', :namespace => :patron, :toggle => 'hide' do
  #   table_for Unit.awaiting_copyright_approval do
  #     column ("Unit ID") {|unit| link_to unit.id, patron_unit_path(unit)}
  #     column (:order_date_due) {|unit| format_date(unit.order_date_due)}
  #     column :bibl_title
  #     column :bibl_call_number
  #   end
  # end

  # section "Materials Currently in Digitization Services (#{Unit.checkedout_materials.count})", :width => '33%', :namespace => :patron, :toggle => 'hide' do
  #   table_for Unit.checkedout_materials do
  #     column("Unit ID") {|unit| link_to unit.id, patron_unit_path(unit)}
  #     column("Date Checked Out") {|unit| format_date(unit.date_materials_received)}
  #     column :bibl_title
  #     column :bibl_call_number
  #   end
  # end

  # section "Unreturned Material (#{Unit.overdue_materials.count})", :width => '33%', :namespace => :patron, :toggle => 'hide' do
  #   table_for Unit.overdue_materials do
  #     column("Unit ID") {|unit| link_to unit.id, patron_unit_path(unit)}
  #     column("Date Checked Out") {|unit| format_date(unit.date_materials_received)}
  #     column :bibl_title
  #     column :bibl_call_number
  #   end
  # end
end
