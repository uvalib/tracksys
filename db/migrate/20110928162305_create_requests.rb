class CreateRequests < ActiveRecord::Migration
  def change
    create_table :requests do |t|

      t.timestamps
    end
  end
end
