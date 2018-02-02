$(function() {
   $("#q_desc_metadata_input select").attr("disabled", "disabled");

   $(".order.mf-action-button.reset-btn").on("click", function() {
      var resp = confirm('Reset all order delivery dates? This cannot be undone.');
      if ( !resp) return;

      $.ajax({
         url: window.location.href+"/reset_dates",
         method: "POST",
         complete: function(jqXHR, textStatus) {
            window.location.reload();
         }
      });
   });

   $(".recent-error.trash.ts-icon").on("click", function() {
      var resp = confirm('Delete recent error?');
      if (!resp) return;

      var box = $(this).closest("div.error");
      $.ajax({
         url: "/admin/job_statuses/"+box.data("job-id"),
         method: "DELETE",
         complete: function(jqXHR, textStatus) {
            box.hide();
         }
      });
   });

   $("input").not($(":button")).keypress(function (evt) {
      var filterForm = $(this).closest(".filter_form");
      if (evt.keyCode === 13 && filterForm.length === 0) {
         iname = $(this).val();
         if (iname !== 'Submit') {
            var fields = $(this).parents('form:eq(0),body').find('button, input, textarea, select');
            var index = fields.index(this);
            if (index > -1 && (index + 1) < fields.length) {
               fields.eq(index + 1).focus();
            }
            return false;
         }
      }
   });

   // Audit Log display
   $(".audit-button").on("mouseover", function() {
      var pos = $(".audit-button").offset();
      if ( !$(".audit-log").data("positioned") ) {
         $(".audit-log").offset({top: pos.top+$(".audit-button").outerHeight()+5, left: pos.left});
         $(".audit-log").data("positioned", true);
      }
      $(".audit-log").show();
   });
   $(".audit-button").on("mouseout", function() {
      $(".audit-log").hide();
   });

   // Colorbox
   $("a[rel='colorbox']").colorbox({width:"100%", maxHeight:"100%"});

   // Inline HTML via colorbox
   $('.inline').colorbox({inline:true, width:"50%"});

   // Chosen javascript library
   $('.chosen-select').chosen();

   $("#add-attachment").on("click", function() {
      $('#upload-attachment').clearForm();
      $("#dimmer").show();
      $("#attachment-modal").show();
   });
   $("#cancel-attach").on("click", function() {
      $("#dimmer").hide();
   });
   $('#upload-attachment')
   .submit(function() {
      $(this).ajaxSubmit({
         complete: function(jqXHR, textStatus) {
            if (textStatus == "success" ) {
               window.location.reload();
            } else {
               alert("Unable to add attachment: "+jqXHR.responseText);
            }
         }
      });
      return false;
   });

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
   };

   $('#desc_meta_div').click( anobj );

   // show deaccession modal
   $("#deaccession-btn").on("click", function(event) {
      event.stopPropagation();
      $("#dimmer").show();
      $("#deaccession-modal").show();
   });
   $("#cancel-deaccession").on("click", function() {
      $("#dimmer").hide();
      $("#deaccession-modal").hide();
   });
   $("#submit-deaccession").on("click", function() {
      resp = confirm("This master file will be permanently removed.\n\nAre you sure?");
      if (!resp) {
         return;
      }
      var note = $("#deaccession-note").val();
      if (note.length === 0) {
         $("#note-required").show();
         $("#deaccession-note").focus();
         return;
      }
      $("#note-required").hide();
      $("#dimmer").hide();
      $("#deaccession-modal").hide();
      var url = "/admin/master_files/"+$("#deaccession-modal").data("id")+"/deaccession";
      $.ajax({
         url: url,
         method: "POST",
         data: {note: note},
         complete: function(jqXHR, textStatus) {
            if ( textStatus != "success" ) {
               alert("Unable to deaccession master file: "+jqXHR.responseText);
            } else {
               window.location.reload();
            }
         }
      });
   });

   // Begin JS for Updating Sirsi Records
   var updateMetadataFields = function(metadata) {
      var empty = "<span class='empty'>Empty</span>";
      $(".attributes_table .sirsi-data").each( function() {
         var id = $(this).attr("id");
         if ( metadata[id] ) {
            $(this).text( metadata[id] );
         } else {
            $(this).html( empty );
         }
      });
      $("#sirsi_metadata_catalog_key").val( metadata.catalog_key );
      $("#sirsi_metadata_barcode").val( metadata.barcode );
      $("#sirsi_metadata_title").val( metadata.title );
      $("#sirsi_metadata_creator_name").val( metadata.creator_name );
      $("#sirsi_metadata_call_number").val( metadata.call_number );
      if ( $("#sirsi_metadata_collection_id").val().length === 0 ) {
         $("#sirsi_metadata_collection_id").val( metadata.collection_id);
      }

      // auto-set the is_manuscript flag id call number looks like MSS or RG-
      if ( metadata.call_number.trim().indexOf("MSS") === 0 || metadata.call_number.trim().indexOf("RG-") === 0) {
         $("#sirsi_metadata_is_manuscript_true").prop("checked", true);
      } else {
         $("#sirsi_metadata_is_manuscript_false").prop("checked", true);
      }

      // See if year is proipr to 1923
      if ( metadata.year && parseInt(metadata.year, 10) < 1923 ) {
         $("#sirsi_metadata_availability_policy_id").val("1");
      } else {
         $("#sirsi_metadata_availability_policy_id").val("");
      }
   };

   $("#sirsi_metadata_barcode").change( function(event) {
      var v = $("#sirsi_metadata_barcode").val();
      var tv = $.trim(v) ;
      $("#sirsi_metadata_barcode").val( tv);
   });
   $("#sirsi_metadata_barcode").on("keypress", function (e) {
       if (e.keyCode == 13) {
           return false;
       }
   });

   $('#refresh-metadata').click(function(e) {
      var btn = $(this);
      if (btn.hasClass("disabled")) {
         return;
      }
      btn.addClass("disabled");
      var sirsi_catalog_key = $('#sirsi_metadata_catalog_key').val();
      var sirsi_barcode = $('#sirsi_metadata_barcode').val();
      var new_url = "/admin/sirsi_metadata/external_lookup?catalog_key=" + sirsi_catalog_key + "&barcode=" + sirsi_barcode;
      $.ajax({
         url: new_url,
         method: "GET",
         complete: function(jqXHR, textStatus) {
            btn.removeClass("disabled");
            if ( textStatus != "success" ) {
               $("p.sirsi-error").html(jqXHR.responseJSON.message);
               $("p.sirsi-error").show();
            } else {
               $("p.sirsi-error").hide();
               metadata = jqXHR.responseJSON;
               updateMetadataFields(metadata);
            }
         }
      });
   });
});
