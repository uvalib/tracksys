$(document).ready(function () {

   $('#datepicker').datepicker({
      startDate: "+28d",
      daysOfWeekDisabled: "0,6",
      title: "Select Due Date",
      format: "yyyy-mm-dd",
      });

   $("form").bind("nested:fieldAdded", function(event) {
      $('.intended_use_select').change(function() {
         var sel = $(this).closest('.intended_use_select');
         var intended_use_id = parseInt(sel.val(), 10);
         var parentDiv = sel.parent().parent();

         // JPEG Intended Use Values
         if(intended_use_id == 100 || intended_use_id == 103 || intended_use_id == 104 || intended_use_id == 106 || intended_use_id == 109 || intended_use_id == 111) {
            parentDiv.find('.intended_use_watermarked_jpg').attr("style","display: block;");
            parentDiv.find('.intended_use_highest_tif').attr("style","display: none;");
         }
         // TIF Intended Use Values
         if(intended_use_id == 101 || intended_use_id == 102 || intended_use_id == 105 || intended_use_id == 107 || intended_use_id == 108 || intended_use_id == 110) {
            parentDiv.find('.intended_use_watermarked_jpg').attr("style","display: none;");
            parentDiv.find('.intended_use_highest_tif').attr("style","display: block;");
         }
         // Select the Blank Menu Option
         if(intended_use_id == "") {
            parentDiv.find('.intended_use_watermarked_jpg').attr("style","display: none;");
            parentDiv.find('.intended_use_highest_tif').attr("style","display: none;");
         }
      });
   });
});
