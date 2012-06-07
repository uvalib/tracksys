$(function() {
  $('#datepicker').datepicker({ 
    minDate: "+28d",
    beforeShowDay: $.datepicker.noWeekends,
    numberOfMonths: 3,
    dateFormat: "yy-mm-dd",
    showOptions: {direction: 'down'}
  });
});