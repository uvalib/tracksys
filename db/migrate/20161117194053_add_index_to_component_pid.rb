class AddIndexToComponentPid < ActiveRecord::Migration
  def change
     add_index  :components, :pid
  end
end
