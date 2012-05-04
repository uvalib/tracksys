// Toggle show panels and form sections
$(function(){
  $('.panel[toggle] h3, fieldset[toggle] legend span').live('click', function(e) {
    var $target = $(e.target);
    if ($target.is('.panel[toggle] h3')) {
      $target.next('.panel_contents').slideToggle("fast");
      return false;
    }
    if ($target.is('span')) {
      // alert($target.parent().next().is('ol'));
      $target.parent().next('ol').slideToggle("fast");
      return false;
    }
  $(e.target).next('.panel_contents', 'ol').slideToggle("fast");
    return false;
  });

});