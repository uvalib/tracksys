$(function() {
   $("#q_desc_metadata_input select").attr("disabled", "disabled");


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
               alert("Unable to refresh metadata. Check that the catalog key and/or barcode are correct");
            } else {
               metadata = jqXHR.responseJSON;
               updateMetadataFields(metadata);
            }
         }
      });
   });

   /**
    * XML EDITOR STUFF
    */
   function completeAfter(cm, pred) {
      var cur = cm.getCursor();
      if (!pred || pred()) setTimeout(function() {
         if (!cm.state.completionActive) {
            cm.showHint({completeSingle: false});
         }
      }, 100);
      return CodeMirror.Pass;
   }

   function completeIfAfterLt(cm) {
      return completeAfter(cm, function() {
         var cur = cm.getCursor();
         return cm.getRange(CodeMirror.Pos(cur.line, cur.ch - 1), cur) == "<";
      });
   }

   function completeIfInTag(cm) {
      return completeAfter(cm, function() {
         var tok = cm.getTokenAt(cm.getCursor());
         if (tok.type == "string" && (!/['"]/.test(tok.string.charAt(tok.string.length - 1)) || tok.string.length == 1)) return false;
         var inner = CodeMirror.innerMode(cm.getMode(), tok.state).state;
         return inner.tagName;
      });
   }

   if ( $(".desc-metadata-viewer").length > 0 ) {
      var cmv = CodeMirror.fromTextArea( $(".desc-metadata-viewer")[0], {
         mode: "xml",
         lineNumbers: true,
         lineWrapping: true,
         foldGutter: true,
         matchTags: true,
         gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"],
         readOnly: true
      });
      cmv.setSize("100%", "auto");
   }

   if ( $(".desc-metadata-editor").length > 0 ) {
      var cm = CodeMirror.fromTextArea( $(".desc-metadata-editor")[0], {
         mode: "xml",
         lineNumbers: true,
         lineWrapping: true,
         foldGutter: true,
         autoCloseBrackets: true,
         matchTags: true,
         autoCloseTags: true,
         gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"],
         extraKeys: {
            "'<'": completeAfter,
            "'/'": completeIfAfterLt,
            "' '": completeIfInTag,
            "'='": completeIfInTag,
            "Ctrl-Space": "autocomplete"
         },hintOptions: {schemaInfo: {}}
      } );
      cm.on("change", function(cm, change) {
         var btn = $(".xml-submit input");
         btn.prop('disabled', true);
         $("div.validate-msg").css("visibility", "visible");
         if (btn.hasClass("disabled") === false ) {
            btn.addClass("disabled");
            $("#tracksys_xml_editor").addClass("edited");
         }
      });
      cm.setSize("100%", "auto");

      $("span.xml-button.generate").on("click", function() {
         var btn = $(this);
         if (btn.hasClass("diabled")) return;
         if ( !confirm("This will replace all XML data currently present. Continue?") ) return;
         btn.addClass("disabled");
         var data = {
            title: $("#xml_metadata_title").val(),
            creator:  $("#xml_metadata_creator_name").val(),
            genre: $("#xml_metadata_genre").val(),
            type: $("#xml_metadata_resource_type").val()
         };

         $.ajax({
            method: "POST",
            url: "/api/xml/generate",
            data: data,
            complete: function(jqXHR, textStatus) {
               btn.removeClass("disabled");
               if ( textStatus != "success" ) {
                  alert("Validation failed: \n\n"+jqXHR.responseText);
               } else {
                  cm.doc.setValue(jqXHR.responseText);
               }
            }
         });
      });

      $("span.xml-button.validate").on("click", function() {
         var btn = $(this);
         var itemUrl = "xml_metadata";
         if (btn.hasClass("diabled")) return;
         btn.addClass("disabled");
         var subBtn = $(".xml-submit input");
         var id = $("#record-id").attr("id");
         var xml = cm.doc.getValue();
         $.ajax({
            method: "POST",
            url: "/api/xml/validate",
            data: { id: id, xml: xml},
            complete: function(jqXHR, textStatus) {
               btn.removeClass("disabled");
               if ( textStatus != "success" ) {
                  alert("Validation failed: \n\n"+jqXHR.responseText);
                  subBtn.prop('disabled', true);
                  if (subBtn.hasClass("disabled") === false ) {
                     subBtn.addClass("disabled");
                  }
               } else {
                  alert("Validation succeeded");
                  subBtn.prop('disabled', false);
                  subBtn.removeClass("disabled");
                  $("#tracksys_xml_editor").removeClass("edited");
                  $("div.validate-msg").css("visibility", "hidden");
               }
            }
         });

      });
   }
});
