class Api::ReportsController < ApplicationController

   # Generate the JSON data used to drive a report
   #
   def generate
      if params[:type] == "avg_time"
         render json: Report.avg_times(params[:start], params[:end]) and return
      end

      render plain: "Unsupported report type", status: :error
   end
end
