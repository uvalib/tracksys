class CreateOrderItem < ActiveRecord::Migration[5.1]
  def change
     create_table :order_items do |t|
        t.references :order, index: true
        t.references :intended_use, index: true
        t.string :title
        t.text :pages
        t.string :call_number
        t.string :author
        t.string :year
        t.string :location
        t.string :source_url
        t.text :description
        t.boolean :converted, default: false
     end
  end
end
