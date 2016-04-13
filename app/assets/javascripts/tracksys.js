$(function() {
   // Colorbox
   $("a[rel='colorbox']").colorbox({width:"100%", maxHeight:"100%"});

   // Inline HTML via colorbox
   $('.inline').colorbox({inline:true, width:"50%"})

   // Chosen javascript library
   $('.chosen-select').chosen();

   // Toggle show panels and form sections
   $('.panel[toggle] h3, fieldset[toggle] legend span').on('click', function(e) {
      var $target = $(e.target);
      if ($target.is('.panel[toggle] h3')) {
         $target.next('.panel_contents').slideToggle("fast");
         return false;
      }
      if ($target.is('span')) {
         $target.parent().next('ol').slideToggle("fast");
         console.log("slide toggle: ");
         return false;
      }
   });

   // toggle ead display field for components
   anobj = function resizeCode () {
      if ( $('#desc_meta').innerHeight() < 150 ) {
         $('#desc_meta').animate({height: '100%'}, "fast", "swing");
      } else {
         $('#desc_meta').animate({height: 100}, "fast", "swing");
      }
      return false;
   }

   $('#desc_meta_div').click( anobj );

   // Begin JS for Updating Bibl Records
   $('.bibl_update_button').click(function(e) {
      var bibl_catalog_key = $('#bibl_catalog_key').val();
      var bibl_barcode = $('#bibl_barcode').val();
      var new_url = "/admin/bibls/external_lookup?catalog_key=" + bibl_catalog_key + "&barcode=" + bibl_barcode
      $(this).attr('href', new_url );
   });

   // when the #bibl_catalog_key field changes
   $('#bibl_catalog_key, #bibl_barcode').change(function() {
      // replace the content of an anchor when an input field changes
      var bibl_catalog_key = $('#bibl_catalog_key').val();
      var bibl_barcode = $('#bibl_barcode').val();
      var new_url = "/admin/bibls/external_lookup?catalog_key=" + bibl_catalog_key + "&barcode=" + bibl_barcode
      // update the href attribute with the new_url variable
      $('.bibl_update_button').attr('href', new_url);
      console.log("changed url to: " + new_url);
   });
   //end Begin JS for Updating Bibl Records
});
