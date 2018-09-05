$(document).ready(function () {

   $('#datepicker').datepicker({
      startDate: "+28d",
      daysOfWeekDisabled: "0,6",
      title: "Select Due Date",
      format: "yyyy-mm-dd",
      orientation: "bottom",
      forceParse: false,
      autoclose: true
   });

   /**
    * Show correct copyright notice when intended use changes
    */
   $("#intended_use_id").on("change", function() {
      var useId = parseInt( $(this).val(), 10);
      $("div.intended-use-info").hide();

      // Watermarked JPEGs?
      if ( useId == 100 ||  useId == 104 || useId == 106 ) {
         $("#intended-use-watermarked-jpg").show();
         $("blockquote.copyright-note").hide();
         if(useId == 100 ) {
            $("blockquote.classroom").show();
         } else {
            $("blockquote.research").show();
         }
      } else if ( useId == 103 || useId == 109) {
         // NON-watermarked jpegs: per Brandon, online exhibit and web publication images
         // don't need a watermark
         $("#intended-use-non-watermarked-jpg").show();

      } else if( useId == 101 || useId == 102 || useId == 105 ||
                 useId == 107 || useId == 108 || useId == 110 || useId == 112) {
        // TIF Intended Use Values
        $("#intended-use-tif").show();
      } else if( useId == 113 ) {
        $("#intended-use-pdf").show();
      }
   });

   /**
    * NEXT clicked on initial request info screen. Verify date and intended use,
    * then progress to order item screens
    */
   $("#request-next").on("click", function() {
      var due = $("input[name=date_due]").val();
      var use = $("#intended_use_id").val();
      $("div.request-error").hide();
      if ( due.length == 0 ) {
         $("div.request-error").text("Due date is required");
         $("div.request-error").show();
         return;
      }
      if (!due.match(/[\d]{4}-[\d]{2}-[\d]{2}/) ) {
         $("div.request-error").text("Due date must be of the form YYYY-MM-DD");
         $("div.request-error").show();
         return;
      }
      if ( !use ) {
         $("div.request-error").text("Intended Use is required");
         $("div.request-error").show();
         return;
      }
      $("#general-info").hide();
      $("#order-item").show();
      $("#request-next").hide();
      $("#request-add").show();
      $("#request-complete").show();
      $("#request_title").focus();
   });

   /**
    * Pull data from the order item fields into an order object. Validate
    * necessary fields. If successful, add the object to an array of order order items
    * and return true. If non-negative index is passed, this is an edit to an
    * existing item. In this case, replace the item at the specified array index.
    */
   var getItemData = function() {
      return {
          title: $("#request_title").val(),
          pages: $("#request_pages_to_digitize").val(),
          callNumber:  $("#request_call_number").val(),
          author:  $("#request_author").val(),
          year:  $("#request_year").val(),
          location:  $("#request_location").val(),
          sourceUrl:  $("#request_source_url").val(),
          description:  $("#request_description").val()
      };
   };

   var validateItem = function(index) {
      var item = getItemData();
      if ( item.title.length === 0 ) {
         $("div.request-error").text("Title is required");
         $("div.request-error").show();
         return false;
      }
      if ( item.pages.length === 0 ) {
         $("div.request-error").text("Image or page numbers are required");
         $("div.request-error").show();
         return false;
      }

      var items = $("#order_items").val();
      if (items.length === 0) {
         items = [];
      } else {
         items = JSON.parse(items);
      }
      if (index < 0) {
         items.push(item);
      } else {
         items[index] = item;
         var itemReview = $("div.item-review[data-item-idx='"+index+"']");
         itemReview.find(".item-title").text( item.title );
         itemReview.find(".item-pages").text( item.pages );
         itemReview.find(".item-call-number").text( item.callNumber );
         itemReview.find(".item-author").text( item.author );
         itemReview.find(".item-year").text( item.year );
         itemReview.find(".item-location").text( item.location );
         itemReview.find(".source-url").text( item.sourceUrl );
         itemReview.find(".special-instructions").text( item.description );
      }
      $("#order_items").val( JSON.stringify(items));
      return true;
   };

   // For adding new items from the review screen...
   $("#create-item").on("click", function() {
      var items = JSON.parse($("#order_items").val());
      var item = getItemData();
      $.ajax({
         url: "/requests/add_item",
         method: "POST",
         data: { item: item, index:  items.length },
         complete: function(jqXHR, textStatus) {
            if (textStatus == "success") {
               items.push(item);
               $(jqXHR.responseJSON.html).insertAfter($("div.review .item-review").last());
               toggleItemUpdate(false);
               $("#order_items").val( JSON.stringify(items) );
            } else {
               $("div.request-error").text(jqXHR.responseJSON.message);
               $("div.request-error").show();
            }
         }
      });
   });

   // For viewing the add/update item from the review screen
   $("#review-add-item").on("click", function() {
      var items = JSON.parse($("#order_items").val());
      $("#item-number").text(items.length+1);
      $("#request_title").val("");
      $("#request_pages_to_digitize").val("");
      $("#request_call_number").val("");
      $("#request_author").val("");
      $("#request_year").val("");
      $("#request_location").val("");
      $("#request_source_url").val("");
      $("#request_description").val("");
      $("#request_title").focus();

      $("#cancel-update").data("mode", "add");
      toggleItemUpdate(true);
   });

   $("#request-add").on("click", function() {
      if (validateItem(-1) === false) return;
      var num = parseInt($("#item-number").text(), 10);
      num += 1;
      $("#item-number").text(num);
      $("#request_title").val("");
      $("#request_pages_to_digitize").val("");
      $("#request_call_number").val("");
      $("#request_author").val("");
      $("#request_year").val("");
      $("#request_location").val("");
      $("#request_source_url").val("");
      $("#request_description").val("");
      $("#request_title").focus();
   });

   $("#request-complete").on("click", function() {
      if (validateItem(-1) === false) return;
      $("#order-form").submit();
   });

   // prevent enter key from submitting form when datepicker has focus
   $("#datepicker").keydown(function(event){
      if(event.keyCode == 13) {
         event.preventDefault();
         return false;
      }
   });

   $("#submit-order").on("click", function() {
      $("#order-review").submit();
   });

   var toggleItemUpdate = function( show ) {
      var mode = $("#cancel-update").data("mode");
      if ( show ) {
         // show item fields / buttons
         $("#update-item").show();
         $("#order-item").show();
         $("#cancel-update").show();

         // hide order review form and buttons
         $("#order-review").hide();
         $("#cancel-order").hide();
         $("#submit-order").hide();
         $("#review-add-item").hide();

         if ( mode === "add") {
            $("#create-item").show();
            $("#update-item").hide();
         }
      } else {
         $("#update-item").hide();
         $("#order-item").hide();
         $("#cancel-update").hide();
         $("#create-item").hide();
         $("#hide-item").show();
         $("#order-review").show();
         $("#cancel-order").show();
         $("#submit-order").show();
         $("#review-add-item").show();
      }
   };

   $("div.review").on("click", ".action.edit", function() {
      var itemIndex = $(this).closest(".item-review").data("item-idx");
      $("#update-item").data("item-idx", itemIndex);
      var items = JSON.parse($("#order_items").val());
      var item = items[itemIndex];

      // populate update item form
      $("#request_title").val(item.title);
      $("#request_pages_to_digitize").val(item.pages);
      $("#request_call_number").val(item.callNumber);
      $("#request_author").val(item.author);
      $("#request_year").val(item.year);
      $("#request_location").val(item.location);
      $("#request_source_url").val(item.sourceUrl);
      $("#request_description").val(item.description);

      // show it (in update mode)...
      $("#cancel-update").data("mode", "update");
      toggleItemUpdate(true);
   });

   $("#cancel-update").on("click", function() {
      toggleItemUpdate(false);
   });
   $("#update-item").on("click", function() {
      var idx = $("#update-item").data("item-idx");
      if ( validateItem(idx) === false) return;
      toggleItemUpdate(false);
   });

   $("div.review").on("click", ".action.delete", function() {
      var itemIndex = $(this).closest(".item-review").data("item-idx");
      var items = JSON.parse($("#order_items").val());
      if (items.length === 1) {
         alert("An order must have at least one item.");
         return;
      }
      resp = confirm("Remove item "+(itemIndex+1)+" from your order?");
      if (resp ) {
         items.splice(itemIndex,1);
         $("#order_items").val( JSON.stringify(items) );
         $(this).closest(".item-review").remove();
      }
   });
});
