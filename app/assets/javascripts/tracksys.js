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
   var updateBiblFields = function(bibl) {
      var empty = "<span class='empty'>Empty</span>";
      $(".attributes_table .bibl-data").each( function() {
         var id = $(this).attr("id");
         if ( bibl[id] ) {
            $(this).text( bibl[id] );
         } else {
            $(this).html( empty );
         }
      });
      $("#bibl_title").val( bibl.title );
   };

   $('#refresh-metadata').click(function(e) {
      var btn = $(this);
      if (btn.hasClass("disabled")) {
         return;
      }
      btn.addClass("disabled");
      var bibl_catalog_key = $('#bibl_catalog_key').val();
      var bibl_barcode = $('#bibl_barcode').val();
      var new_url = "/admin/bibls/external_lookup?catalog_key=" + bibl_catalog_key + "&barcode=" + bibl_barcode;
      $.ajax({
         url: new_url,
         method: "GET",
         complete: function(jqXHR, textStatus) {
            btn.removeClass("disabled");
            if ( textStatus != "success" ) {
               alert("Unable to refresh metadata. Check that the catalog key and/or barcode are correct");
            } else {
               bibl = jqXHR.responseJSON;
               updateBiblFields(bibl);
            }
         }
      });
   });
});
