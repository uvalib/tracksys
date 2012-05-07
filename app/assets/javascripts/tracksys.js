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

// Colorbox
jQuery(document).ready(function(){
  //Examples of how to assign the ColorBox event to elements
  jQuery("a[rel='colorbox']").colorbox({width:"100%", maxHeight:"100%"});
  
  // Chosen javascript library
  $('.chzn-select').chosen();

  //Example of preserving a JavaScript event for inline calls.
  jQuery("#click").click(function(){
    $('#click').css({"background-color":"#f00", "color":"#fff", "cursor":"inherit"}).text("Open this window again and this message will still be here.");
    return false;
  });
})


// Begin JS for Updating Bibl Records
jQuery(function() {
  // when the #bibl_catalog_key field changes
  $('#bibl_catalog_key, #bibl_barcode').change(function() {
    // replace the content of an anchor when an input field changes
    var bibl_catalog_key = $('#bibl_catalog_key').val();
    var bibl_barcode = $('#bibl_barcode').val();
  	var new_url = "/admin/bibls/external_lookup?catalog_key=" + bibl_catalog_key + "&barcode=" + bibl_barcode
    // update the href attribute with the new_url variable
  	$('.bibl_update_button').attr('href', new_url);
  });
return false;
})


$(document).ready(function() {
    $('.bibl_update_button').click(function(e) {
      e.preventDefault();
  		var bibl_catalog_key = $('#bibl_catalog_key').val();
      var bibl_barcode = $('#bibl_barcode').val();
  		var new_url = "/admin/bibls/external_lookup?catalog_key=" + bibl_catalog_key + "&barcode=" + bibl_barcode
  		$(this).attr('href', new_url );
    });
});
//end Begin JS for Updating Bibl Records

