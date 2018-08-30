class UpdateOrderItemTitleLength < ActiveRecord::Migration[5.2]
   def up
       change_column :order_items, :title, :text
    end

    def down
       # create a temporary column to hold the truncated values
       add_column :order_items, :tmp_title, :string

       OrderItem.find_each do |oi|
          # get the current error and truncate down to 255 if needed
          working_title = oi.title
          if working_title.length > 255
             working_title = working_title[0,254]
          end

          # use #update_column because it skips validations AND callbacks
          oi.update_column(:tmp_title, working_title)
       end

       # Now delete the old and rename temp as it has the truncated data
       remove_column :order_items, :title
       rename_column :order_items, :tmp_title, :title
    end
end
