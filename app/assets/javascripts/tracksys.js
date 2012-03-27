$(function(){
  $('.panel[toggle] h3').live('click', function(e) {
  $(e.target).next('.panel_contents').slideToggle("fast");
    return false;
  });

});