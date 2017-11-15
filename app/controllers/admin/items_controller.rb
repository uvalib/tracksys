class Admin::ItemsController < ApplicationController
   def destroy
      OrderItem.find(params[:id]).destroy()
      render plain: "OK"
   end
end
