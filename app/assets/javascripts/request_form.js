$(function() {
  $('#datepicker').datepicker({ 
    minDate: "+28d",
    beforeShowDay: $.datepicker.noWeekends,
    numberOfMonths: 3,
    showOptions: {direction: 'down'}
  });
});