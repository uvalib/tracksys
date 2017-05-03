class AddStepToNote < ActiveRecord::Migration
  def change
     add_reference :notes, :step, index: true
  end
end
