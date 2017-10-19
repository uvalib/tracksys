class Api::ReportsController < ApplicationController

   # Generate the JSON data used to drive a report
   #
   def generate
      if params[:type] == "avg_time"
         render json: Report.avg_times(params[:workflow], params[:start], params[:end]) and return
      elsif params[:type] == "problems"
         render json: Report.problems(params[:workflow], params[:start], params[:end]) and return
      elsif params[:type] == "rejections"
         render json: Report.rejections(
            params[:workflow], params[:start], params[:end],
            params[:sort], params[:dir]) and return
      elsif params[:type] == "productivity"
         render json: Report.productivity(params[:workflow], params[:start], params[:end]) and return
      elsif params[:type] == "deliveries"
         render json: Report.deliveries(params[:year]) and return
      end

      render plain: "Unsupported report type", status: :error
   end
end
