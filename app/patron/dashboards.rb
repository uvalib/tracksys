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

  section "Deferred Requets", :namespace => :patron do
    table_for Order.deferred do
      column :id do |order|
        link_to order.id, patron_order_path(order)
      end
      column (:date_due){|order| format_date(order.date_due)}
      column (:date_deferred) {|order| format_date(order.date_deferred)}
      column :agency
      column "Name" do |order|
        link_to order.customer_full_name, patron_customer_path(order.customer)
      end
    end
  end

  section "Requests Awaiting Approval", :namespace => :patron, :priority => 1 do
    table_for Order.awaiting_approval do
      column :id do |order|
        link_to order.id, patron_order_path(order)
      end
      column (:date_due) {|order| format_date(order.date_due)}
      column :agency
      column "Name" do |order|
        link_to order.customer_full_name, patron_customer_path(order.customer)
      end
    end
  end
end
