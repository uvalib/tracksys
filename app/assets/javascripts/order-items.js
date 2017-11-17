$(function() {
   $(".btn.discard-item").on("click", function() {
      var itemId = $(this).data("item-id");
      var item = $(this).closest(".order-item");
      var title = $(this).closest(".order-item").find(".item-title").text();
      resp = confirm("Discard item '"+title+"'? It will be permanently removed from the system. Are you sure?");
      if (resp) {
         $.ajax({
            url: "/admin/items/"+itemId,
            method: "DELETE",
            complete: function(jqXHR, textStatus) {
               if (textStatus != "success") {
                  alert("Unable to delete '"+title+"'. Please try again later");
               } else {
                  item.remove();
               }
            }
         });
      }
   });

   $(".btn.create-unit").on("click", function() {
      $("#dimmer").show();
      var itemDiv = $(this).closest(".order-item");
      $("#intended_use_id").val( $("#item-intended-use-id").text() );
      if ( itemDiv.find(".item-source-url").length > 0 ) {
         $("#patron_source_url").val(itemDiv.find(".item-source-url").text());
      } else {
         $("#patron_source_url").val("");
      }
      var metadata = null;
      var si = "Title: "+itemDiv.find(".item-title").text();
      var query = itemDiv.find(".item-title").text();
      si += "\nPages to Digitize: "+itemDiv.find(".item-pages").text();
      if ( itemDiv.find(".item-call-number").length > 0 ) {
         var cn = itemDiv.find(".item-call-number").text();
         si += "\nCall Number: "+cn;
         query = cn; // prefer callnumber lookups over title
      }
      if ( itemDiv.find(".item-author").length > 0 ) {
         si += "\nAuthor: "+itemDiv.find(".item-author").text();
      }
      if ( itemDiv.find(".item-year").length > 0 ) {
         si += "\nYear: "+itemDiv.find(".item-year").text();
      }
      if ( itemDiv.find(".item-location").length > 0 ) {
         si += "\nLocation: "+itemDiv.find(".item-location").text();
      }
      if ( itemDiv.find(".item-description").length > 0 ) {
         si += "\nDescription: "+itemDiv.find(".item-description").text();
      }
      $("#special_instructions").val(si);

      // ajax call to lookup metadata by callnumber
      $("#metadata_id").val("");
      $("#metadata-title").text("");
      $.getJSON("/api/metadata/search?q="+query, function ( data, textStatus, jqXHR ){
         if (textStatus == "success" ) {
            var val = data[0];
            $("#metadata_id").val(val.id);
            $("#metadata-title").text("Metadata Title: "+val.title);
         }
      });
   });

   $("#cancel-unit-create").on("click", function() {
      $("#dimmer").hide();
   });

   $("#ok-unit-create").on("click", function() {

   });

   $("#lookup-metadata").on("click", function() {
      $("#create-unit-panel").hide();
      $("#metadata-finder").show();
   });
   $("span.cancel-metadata").on("click", function() {
      $("#create-unit-panel").show();
      $("#metadata-finder").hide();
   });
   $("span.select-metadata").on("click", function() {
      $("p.error").hide();
      if ( $("tr.selected").length === 0) {
         $("p.error").text("Please select a metadata record.");
         $("p.error").show();
         return;
      }

      var id = $("tr.selected").data("metadata-id");
      var title = $("tr.selected").data("full-title");
      $("#metadata_id").val(id);
      $("#metadata-title").text("Metadata Title: "+title);

      $("#create-unit-panel").show();
      $("#metadata-finder").hide();
   });
});
