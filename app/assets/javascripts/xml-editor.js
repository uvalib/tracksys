$(function() {
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
         $("div.validate-msg").removeClass("success");
         $("div.validate-msg").css("visibility", "visible");
         $("div.validate-msg").text("XML has changed and must be validated before saving");
         if (btn.hasClass("disabled") === false ) {
            btn.addClass("disabled");
            $("#tracksys_xml_editor").addClass("edited");
         }
      });
      cm.setSize("100%", "auto");
   }

   $("span.xml-button.generate").on("click", function() {
      var btn = $(this);
      if (btn.hasClass("disabled")) return;
      if ( !confirm("This will replace all XML data currently present. Continue?") ) return;
      btn.addClass("disabled");
      var data = {
         title: $("#xml_metadata_title").val(),
         creator:  $("#xml_metadata_creator_name").val()
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
      if (btn.hasClass("disabled")) return;

      $("#xml-validation-errors").text("");
      $("#xml-validation-errors").hide();
      btn.addClass("disabled");
      var subBtn = $(".xml-submit input");
      var id = $("#record-id").attr("id");
      var xml = cm.doc.getValue();
      $("div.validate-msg").text("Validating...");
      $("div.validate-msg").removeClass("success");
      $("div.validate-msg").css("visibility", "visible");
      $.ajax({
         method: "POST",
         url: "/api/xml/validate",
         data: { id: id, xml: xml},
         complete: function(jqXHR, textStatus) {
            btn.removeClass("disabled");
            if ( textStatus != "success" ) {
               subBtn.prop('disabled', true);
               if (subBtn.hasClass("disabled") === false ) {
                  subBtn.addClass("disabled");
               }
               $("div.validate-msg").text("Failed validation; XML must be corrected before saving.");
               $("#xml-validation-errors").text(jqXHR.responseText);
               $("#xml-validation-errors").show();
            } else {
               subBtn.prop('disabled', false);
               subBtn.removeClass("disabled");
               $("#tracksys_xml_editor").removeClass("edited");
               $("div.validate-msg").text("Validation succeeded!");
               $("div.validate-msg").addClass("success");
               setTimeout( function() {
                  $("div.validate-msg").removeClass("success");
                  $("div.validate-msg").css("visibility", "hidden");
               }, 3000);
            }
         }
      });
   });
});
