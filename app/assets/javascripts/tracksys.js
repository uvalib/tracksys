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
      $("#sirsi_metadata_title").val( metadata.title );
      $("#sirsi_metadata_creator_name").val( metadata.creator_name );
      $("#sirsi_metadata_call_number").val( metadata.call_number );
   };

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

   if ( $("#xml_metadata_desc_metadata").length > 0 ) {
      var cm = CodeMirror.fromTextArea( $("#xml_metadata_desc_metadata")[0], {
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
      cm.setSize("100%", 600);
      $("#validate-xml").on("click", function() {
         var btn = $(this);
         if (btn.hasClass("diabled")) return;
         btn.addClass("disabled");
         var id = $("#record-id").attr("id");
         var xml = cm.doc.getValue();
         $.ajax({
            method: "POST",
            url: "/admin/xml_metadata/validate",
            data: { id: id, xml: xml},
            complete: function(jqXHR, textStatus) {
               btn.removeClass("disabled");
               if ( textStatus != "success" ) {
                  alert("Validation failed: \n\n"+jqXHR.responseText);
               } else {
                  alert("Validation succeeded");
               }
            }
         });

      });
   }
});
