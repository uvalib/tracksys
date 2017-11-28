$(function() {
   var discardItem = function(itemDiv) {
      var itemId = itemDiv.data("item-id");
      $.ajax({
         url: "/admin/items/"+itemId,
         method: "DELETE",
         complete: function(jqXHR, textStatus) {
            if (textStatus != "success") {
               var title = itemDiv.find(".item-title").text();
               alert("Unable to delete '"+title+"'. Please try again later");
            } else {
               itemDiv.remove();
            }
         }
      });
   };

   $(".btn.discard-item").on("click", function() {
      var item = $(this).closest(".order-item");
      var title = item.find(".item-title").text();
      resp = confirm("Discard item '"+title+"'? It will be permanently removed from the system. Are you sure?");
      if (resp) {
         discardItem(item);
      }
   });

   $(".btn.create-unit").on("click", function() {
      $("#dimmer").show();
      var itemDiv = $(this).closest(".order-item");
      var itemId = itemDiv.data("item-id");

      $("#source_item_id").val( itemId );
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

      // ajax call to lookup metadata by callnumber or title
      $("#metadata_id").val("");
      $("#metadata_id").attr("disabled", "disabled");
      $("#lookup-metadata").addClass("disabled");
      $("#metadata-title").text("Searching...");
      $.getJSON("/api/metadata/search?q="+query, function ( data, textStatus, jqXHR ){
         if (textStatus == "success" ) {
            if ( data.length > 0 ) {
               var val = data[0];
               $("#metadata_id").val(val.id);
               $("#metadata-title").text("Metadata Title: "+val.title);
            } else {
               $("#metadata-title").text("Automated metadata lookup was unsuccessful");
            }
         }
         $("#metadata_id").removeAttr("disabled");
         $("#lookup-metadata").removeClass("disabled");
      });
   });

   $("#cancel-unit-create").on("click", function() {
      $("#dimmer").hide();
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


   // Ajax form submission hooks; handle before submit, success and error
   //
   $("form#convert_item").bind('ajax:before', function(){
      $("#ok-unit-create").addClass("disabled");
      $("div.flash_type_error").text("");
   });
   $("form#convert_item").bind('ajax:error', function(event, jqxhr){
      $("div.flash_type_error").text(jqxhr.responseJSON.message);
      $("#ok-unit-create").removeClass("disabled");
   });
   $("form#convert_item").bind('ajax:success', function(event, jqxhr) {
      var cnt = parseInt($("#order-units-link").text(),10);
      $("#order-units-link").text(cnt+1);
      $("#dimmer").hide();
      $("#ok-unit-create").removeClass("disabled");
      if (jqxhr.responseJSON.approve_enabled) {
         $("#approve-order-btn").removeClass("disabled");
      }
   });

   // HACK: This class is getting added to the label by rails (I think). It conflicts
   // with the colorbox js library causing a click on the lable to bring up a
   // blank colorbox window. Remove the class to prevent.
   $("#create-unit-modal label.inline").removeClass("cboxElement");
});
