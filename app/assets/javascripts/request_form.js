$(document).ready(function () {

   $('#datepicker').datepicker({
      startDate: "+28d",
      daysOfWeekDisabled: "0,6",
      title: "Select Due Date",
      format: "yyyy-mm-dd",
      orientation: "bottom"
   });

   $("#intended_use_id").on("change", function() {
      var useId = parseInt( $(this).val(), 10);
      $("div.intended-use-info").hide();

      // Watermarked JPEGs?
      if ( useId == 100 ||  useId == 104 || useId == 106 ) {
         $("#intended-use-watermarked-jpg").show();
         $("blockquote.copyright-note").hide();
         if(useId == 100 ) {
            $("blockquote.classroom").show();
         } else {
            $("blockquote.research").show();
         }
      } else if ( useId == 103 || useId == 109) {
         // NON-watermarked jpegs: per Brandon, online exhibit and web publication images
         // don't need a watermark
         $("#intended-use-non-watermarked-jpg").show();

      } else if( useId == 101 || useId == 102 || useId == 105 ||
                 useId == 107 || useId == 108 || useId == 110 || useId >= 112) {
        // TIF Intended Use Values
        $("#intended-use-tif").show();
      }
   });
});
