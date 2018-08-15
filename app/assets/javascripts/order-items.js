$(function() {
   $("#alt-email").on("click", function(e)  {
      e.preventDefault();
      var f = $(this).closest("form");
      var act = f.attr("action");
      var email = prompt("Enter the email address that will receive the order notification: ");
      if (email) {
         f.attr("action", act+"?email="+email);
         f.submit();
      }
   });

   $("#alt-est-email").on("click", function(e)  {
      e.preventDefault();
      var f = $(this).closest("form");
      var act = f.attr("action");
      var email = prompt("Enter the email address that will receive the order fee information: ");
      if (email) {
         f.attr("action", act+"?email="+email);
         f.submit();
      }
   });

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

   $("#metadata-type-selector").on("change", function() {
     var type = $(this).val();
     $("#metadata_type").val(type);
     if (type == "SirsiMetadata") {
       $("div.sirsi-metadata").show();
       $("div.archivesspace-metadata").hide();
     } else {
       $("div.sirsi-metadata").hide();
       $("div.archivesspace-metadata").show();
     }
   });

   var showUnitCreate = function() {
      $("#dimmer").show();

      // clear any prior data from fields
      $("span.metadata-display").text("");
      $("#metadata-status").text("");
      $("#create-unit-panel textarea").val("");
      $("#create-unit-panel input[type=checkbox]").prop("checked", false);
   };

   $(".btn.add-unit").on("click", function() {
      showUnitCreate();
   });

   $(".btn.create-unit").on("click", function() {
      showUnitCreate();

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
      $("#lookup-metadata").addClass("disabled");
      $("#metadata-status").text("Searching...");
      $("#metadata_id").val("");
      $("#metadata-pid").text("");
      $("#metadata-call-number").text("");
      $("#metadata-title").text("");
      $.getJSON("/api/metadata/search?q="+query, function ( data, textStatus, jqXHR ){
         if (textStatus == "success" ) {
            if ( data.length === 0 ) {
               $("#metadata-status").text("Automated metadata lookup was unsuccessful");
            } else if ( data.length === 1 ) {
               var val = data[0];
               $("#metadata_id").val(val.id);
               $("#metadata-pid").text(val.pid);
               $("#metadata-call-number").text(val.call_number);
               var title = val.full;
               if ( title.length > 255 ) {
                  title = title.substring(0,255)+"...";
               }
               $("#metadata-title").text( title );
               $("#metadata-status").text("");
            } else {
               $("#metadata-status").text("Automated metadata lookup found multiple matches");
            }
         } else {
            $("#metadata-status").text("Automated metadata lookup error");
         }
         $("#metadata_id").removeAttr("disabled");
         $("#lookup-metadata").removeClass("disabled");
      });
   });

   $("#cancel-unit-create").on("click", function() {
      $("#dimmer").hide();
   });

   $("#lookup-metadata").on("click", function() {
      var q = "";
      $.each($("#special_instructions").val().split("\n"), function(idx,val) {
         if (val.indexOf("Title:") > -1 || val.indexOf("Call Number:") > -1 ) {
            q = val.split(":")[1].trim();
         }
      });

      $("#search-text").val(q);
      if (q.length > 0  ) {
         $(".metadata-finder.find").trigger("click");
      }
      $("#create-unit-panel").hide();
      $("#metadata-finder").show();
   });

   $("#create-metadata").on("click", function() {
      $("#create-unit-panel").hide();
      $("#create_metadata input, select").each(function() {
        var inputID = $(this).attr("id");
         if (inputID != "ok-metadata-create" &&  inputID != "metadata-type") {
            $(this).val("");
            $(this).prop("checked", false);
         }
      });
      $("#ok-metadata-create").removeClass("disabled");
      $("#availability_policy_id").val("1");
      $("#metadata-builder").show();
   });

   $("#sirsi-lookup").on("click", function() {
      var btn = $(this);
      if (btn.hasClass("disabled")) return;
      btn.addClass("disabled");

      var err = $(".flash_type_error.sirsi");
      err.text("");
      var sirsi_catalog_key = $('#catalog_key').val();
      var sirsi_barcode = $('#barcode').val();
      var new_url = "/admin/sirsi_metadata/external_lookup?catalog_key=" + sirsi_catalog_key + "&barcode=" + sirsi_barcode;
      $.ajax({
         url: new_url,
         method: "GET",
         complete: function(jqXHR, textStatus) {
            btn.removeClass("disabled");
            if ( textStatus != "success" ) {
               err.text("No matches. Check that the catalog key and/or barcode are correct");
            } else {
               md = jqXHR.responseJSON;
               var currCK = $("#catalog_key").val();
               var currBC = $("#barcode").val();
               if (currBC.length > 0 && md.barcode != currBC ||
                   currCK.length > 0 && md.catalog_key != currCK) {
                  err.text("Barcode / catalog key mismatch. Clear one or the other and retry");
                  return;
               }
               $("#call_number").val(md.call_number);
               var title = md.title;
               if ( title.length > 50) {
                  title = title.substr(0,50)+"...";
               }
               $("#title").val(title);
               $("#catalog_key").val(md.catalog_key);
               $("#barcode").val(md.barcode);
               $("#creator_name").val(md.creator_name);
            }
         }
      });
   });

   $("span.cancel-metadata").on("click", function() {
      $("#create-unit-panel").show();
      $("#metadata-finder").hide();
      $("#metadata-builder").hide();
   });

   $("span.select-metadata").on("click", function() {
      $("p.error").hide();
      if ( $("tr.selected").length === 0) {
         $("p.error").text("Please select a metadata record.");
         $("p.error").show();
         return;
      }

      var tr = $("tr.selected");
      var id = tr.data("metadata-id");
      var title = tr.data("full-title");
      if ( title.length > 255 ) {
         title = title.substring(0,255)+"...";
      }
      $("#metadata_id").val(id);
      $("#metadata-title").text(title);
      $("#metadata-status").text("");
      $("#metadata-pid").text( tr.find("td:first-child").text() );
      $("#metadata-call-number").text( tr.find("td:nth-child(3)").text() );
      $("#create-unit-panel").show();
      $("#metadata-finder").hide();
   });

   // Ajax METADATA form submission hooks; handle before submit, success and error
   //
   $("form#create_metadata").bind('ajax:before', function(){
      $("#ok-metadata-create").addClass("disabled");
      $("div.flash_type_error.sirsi").text("");
   });
   $("form#create_metadata").bind('ajax:error', function(event, jqxhr){
      $("div.flash_type_error.sirsi").text(jqxhr.responseText);
      $("#ok-metadata-create").removeClass("disabled");
      $("#metadata-status").text("Lookup error");
   });
   $("form#create_metadata").bind('ajax:success', function(event, resp) {
      var title = $("#title").val();
      $("#metadata-title").text(title);
      $("#metadata-status").text("");
      $("#metadata_id").val(resp);
      $("#create-unit-panel").show();
      $("#metadata-builder").hide();
   });

   $("span.as-lookup").on("click", function() {
     if ($("span.as-lookup").hasClass("disabled") ) return;
     var url = $("#as-url").val();
     if (url === "") return;

     $("span.as-lookup").addClass("disabled");

     $.ajax({
        url: "/admin/archivesspace?uri="+url,
        method: "GET",
        complete: function(jqXHR, textStatus) {
           $("span.as-lookup").removeClass("disabled");
           if ( textStatus === "success" ) {
             $("#as-collection").text(jqXHR.responseJSON.collection);
             $("#as-title").text(jqXHR.responseJSON.title);
             $("#as-id").text(jqXHR.responseJSON.id);
             $("#tgt_as_uri").val(jqXHR.responseJSON.uri);
             $("#tgt_as_title").val(jqXHR.responseJSON.title);
           } else {
             $("#as-collection").text("Unable to find specified URL");
             $("#as-title").text("");
             $("#as-id").text("");
             $("#tgt_as_uri").val("");
             $("#tgt_as_title").val("");
           }
        }
     });
   });

   // Ajax CONVERT form submission hooks; handle before submit, success and error
   //
   $("#ok-unit-create").on('click', function(event){
      var asUri = $("#tgt_as_uri").val();
      if (asUri === "" && $("#metadata-type").val() == "ExternalMetadata") {
        $("div.flash_type_error").text("ArchivesSpace lookup is required");
        return;
      }
      $("#ok-unit-create").addClass("disabled");
      $("div.flash_type_error").text("");
      $("form#convert_item").submit();
   });
   $("form#convert_item").bind('ajax:error', function(event, jqxhr){
      $("div.flash_type_error").text(jqxhr.responseJSON.message);
      $("#ok-unit-create").removeClass("disabled");
   });
   $("form#convert_item").bind('ajax:success', function(event, resp) {
      // increase the unit count for the order
      var cnt = parseInt($("#order-units-link").text(),10);
      $("#order-units-link").text(cnt+1);

      // hide popup and restore buttons
      $("#dimmer").hide();
      $("#ok-unit-create").removeClass("disabled");
      if (resp.approve_enabled) {
         $("#approve-order-btn").removeAttr("disabled");
      }

      // find and show the used marker on the item div (if id is present)
      var id = resp.item_id;
      if (id.length > 0) {
         var itemDiv = $("div.order-item[data-item-id='"+id+"']");
         itemDiv.find(".item-used").removeClass("hidden");
      }
   });

   // HACK: This class is getting added to the label by rails (I think). It conflicts
   // with the colorbox js library causing a click on the lable to bring up a
   // blank colorbox window. Remove the class to prevent.
   $("#create-unit-modal label.inline").removeClass("cboxElement");
});
