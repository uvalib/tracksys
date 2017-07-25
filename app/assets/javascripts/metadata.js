$(function() {
   $("#find-metadata").on("click", function() {
      $("#dimmer").show();
      $("#metadata-finder").show();
      $("#search-text").focus();
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
            var template = "<tr class='hit' data-metadata-id='MID'><td>MID</td><td>PID</td><td>BARCODE</td><td>TITLE</td></tr>";
            $.each(data, function(idx,val) {
               var line = template.replace(/MID/g, val.id);
               line = line.replace("PID", val.pid);
               line = line.replace("BARCODE", val.barcode);
               line = line.replace("TITLE", val.title);
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

      $("#dimmer").hide();
      $("#metadata-finder").hide();
   });
});
