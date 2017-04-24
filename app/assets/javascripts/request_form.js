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
         var parentDiv = sel.parent().parent();
         var val =  sel.val();
         if ( val.length === 0) {
            parentDiv.find('.intended_use_watermarked_jpg').hide();
            parentDiv.find('.intended_use_highest_tif').hide();
            parentDiv.find('.intended_use_non_watermarked_jpg').hide();
         }
         var intended_use_id = parseInt(sel.val(), 10);

         // Watermarked JPEGs?
         if ( intended_use_id == 100 ||  intended_use_id == 104 || intended_use_id == 106 ) {
            parentDiv.find('.intended_use_watermarked_jpg').show();
            parentDiv.find('.intended_use_highest_tif').hide();
            parentDiv.find('.intended_use_non_watermarked_jpg').hide();
            if(intended_use_id == 100 ) {
               parentDiv.find('.intended_use_watermarked_jpg .classroom').show();
               parentDiv.find('.intended_use_watermarked_jpg .research').hide();
            } else {
               parentDiv.find('.intended_use_watermarked_jpg .classroom').hide();
               parentDiv.find('.intended_use_watermarked_jpg .research').show();
            }
         } else if ( intended_use_id == 103 || intended_use_id == 109) {
            // NON-watermarked jpegs, per Brandon, online exhibit and web publication images
            // don't need a watermark
            parentDiv.find('.intended_use_watermarked_jpg').hide();
            parentDiv.find('.intended_use_highest_tif').hide();
            parentDiv.find('.intended_use_non_watermarked_jpg').show();
         } else if( intended_use_id == 101 || intended_use_id == 102 || intended_use_id == 105 ||
                    intended_use_id == 107 || intended_use_id == 108 || intended_use_id == 110 || intended_use_id >= 112) {
            // TIF Intended Use Values
            parentDiv.find('.intended_use_watermarked_jpg').hide();
            parentDiv.find('.intended_use_highest_tif').show();
            parentDiv.find('.intended_use_non_watermarked_jpg').hide();
         } else {
            // Shouldn't get here. If somethow we do, just don't show anything
            parentDiv.find('.intended_use_watermarked_jpg').hide();
            parentDiv.find('.intended_use_highest_tif').hide();
            parentDiv.find('.intended_use_non_watermarked_jpg').hide();
         }
      });
   });
});
