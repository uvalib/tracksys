$(function() {
   $("#find-metadata").on("click", function() {
      $("#dimmer").show();
      $("#metadata-finder").show();
      $("#search-text").focus();
   });

   $(".btn.aptrust-resubmit").on("click", function() {
      if ( $(this).hasClass("disabled") ) return;

      var btn = $(this);
      btn.addClass("disabled");
      var metaID = $(this).data("metadata");
      btn.text("Submitting...");
      $.ajax({
         url: "/api/aptrust/"+metaID,
         method: "PUT",
         complete: function(jqXHR, textStatus) {
            btn.removeClass("disabled");
            btn.text("Resubmit");
            if (textStatus != "success") {
               alert("Resubmission failed: "+jqXHR.responseText);
            } else {
               alert("This item has been resubmitted to APTrust. Check the Job Status page for progress.")
            }
         }
      });
   });

   $(".btn.generate-qdc").on("click", function() {
      if ( $(this).hasClass("disabled") ) return;

      var btn = $(this);
      btn.addClass("disabled");
      btn.text("Generating...");
      var metaID = $(this).data("metadata");
      $.ajax({
         url: "/api/qdc/"+metaID,
         method: "POST",
         complete: function(jqXHR, textStatus) {
            btn.removeClass("disabled");
            btn.text("Generate QDC");
            if (textStatus != "success") {
               alert("Unable to generate QDC: "+jqXHR.responseText);
            } else {
               var tgt = $("span.qdc-date");
               tgt.removeClass("empty");
               tgt.text( jqXHR.responseText );
            }
         }
      });
   });

   $("span.metadata-finder.cancel").on("click", function() {
      $("#dimmer").hide();
      $("#metadata-finder").hide();
   });

   var doSearch = function() {
      if ( $("span.metadata-finder.find").hasClass("disabled") ) return;

      $("p.error").hide();
      var val = $("#search-text").val();
      if (val.length < 3) {
         $("p.error").text("Please enter a search string of at least 3 characters.");
         $("p.error").show();
         return;
      }

      $("span.metadata-finder.find").addClass("disabled");
      $.getJSON("/api/metadata/search?q="+val, function ( data, textStatus, jqXHR ){
         if (textStatus == "success" ) {
            $("tr.hit").remove();
            $("span.metadata-finder.find").removeClass("disabled");
            $("p.error").text("");
            if ( data.length > 0) {
               $("p.error").hide();
            } else {
               $("p.error").text("No matching metadata records found");
               $("p.error").show();
            }
            var template = "<tr class='hit' data-full-title=\"FULL\" data-metadata-id='MID'><td>PID</td><td>BARCODE</td><td>CALL</td><td>TITLE</td></tr>";
            $.each(data, function(idx,val) {
               var line = template.replace(/MID/g, val.id);
               line = line.replace("PID", val.pid);
               line = line.replace("BARCODE", val.barcode);
               line = line.replace("CALL", val.call_number);
               line = line.replace("TITLE", val.title);
               var escaped = $('<div/>').text(val.full).html();
               escaped = escaped.replace(/\"/g, "'");
               line = line.replace("FULL", escaped);
               $("div.results-panel table").append( $(line) );
            });
         } else {
            $("p.error").text("Search failed! Please try again later.");
            $("p.error").show();
         }
      });
   };

   $("#search-text").keypress(function (evt) {
      if (evt.keyCode === 13 ) {
         evt.stopPropagation();
         doSearch();
      }
   });

   $("span.metadata-finder.find").on("click", function() {
      doSearch();
   });

   $("div.results-panel table").on("click", "tr.hit", function() {
      var sel = $(this);
      $("tr.hit").removeClass("selected");
      sel.addClass("selected");
   });

   $("span.metadata-finder.select").on("click", function() {
      $("p.error").hide();
      if ( $("tr.selected").length === 0) {
         $("p.error").text("Please select a metadata record.");
         $("p.error").show();
         return;
      }

      // only one or the other will ever be on screen at a time. One will fail,
      // the other will succeed. This covers edit of all types of metadata
      $("#sirsi_metadata_parent_metadata_id").val( $("tr.selected").data("metadata-id"));
      $("#xml_metadata_parent_metadata_id").val( $("tr.selected").data("metadata-id"));
      $("#unit_metadata_id").val( $("tr.selected").data("metadata-id"));
      $("#master_file_metadata_id").val( $("tr.selected").data("metadata-id"));

      $("#dimmer").hide();
      $("#metadata-finder").hide();
   });
});
