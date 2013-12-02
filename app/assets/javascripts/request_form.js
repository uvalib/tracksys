$(function() {
  $('#datepicker').datepicker({ 
    minDate: "+28d",
    beforeShowDay: $.datepicker.noWeekends,
    numberOfMonths: 3,
    dateFormat: "yy-mm-dd",
    showOptions: {direction: 'down'}
  });
});

$("form").bind("nested:fieldAdded", function(event) {
  $('.intended_use_select').change(function() {
    var intended_use_id = $(this).closest('.intended_use_select').val();
    // JPEG Intended Use Values
    if(intended_use_id == 100 || intended_use_id == 103 || intended_use_id == 104 || intended_use_id == 106 || intended_use_id == 109 || intended_use_id == 111) {
      $(this).parent().parent().siblings('#intended_use_watermarked_jpg').attr("style","display: block;");
      $(this).parent().parent().siblings('#intended_use_highest_tif').attr("style","display: none;");
    }
    // TIF Intended Use Values
    if(intended_use_id == 101 || intended_use_id == 102 || intended_use_id == 105 || intended_use_id == 107 || intended_use_id == 108 || intended_use_id == 110) {
      $(this).parent().parent().siblings('#intended_use_watermarked_jpg').attr("style","display: none;");
      $(this).parent().parent().siblings('#intended_use_highest_tif').attr("style","display: block;");
    }
  });
});

