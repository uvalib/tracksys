$(document).ready(function () {

   $('#datepicker').datepicker({
      startDate: "+28d",
      daysOfWeekDisabled: "0,6",
      title: "Select Due Date",
      format: "yyyy-mm-dd",
      orientation: "bottom"
   });

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
                 useId == 107 || useId == 108 || useId == 110 || useId >= 112) {
        // TIF Intended Use Values
        $("#intended-use-tif").show();
      }
   });

   $("#request-next").on("click", function() {
      var due = $("input[name=date_due]").val();
      var use = $("#intended_use_id").val();
      $("div.request-error").hide();
      if ( due.length == 0 ) {
         $("div.request-error").text("Due date is required");
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

   var validateItem = function() {
      var item = {
         title: $("#request_title").val(),
         pages: $("#request_pages_to_digitize").val(),
         callNumber:  $("#request_call_number").val(),
         author:  $("#request_author").val(),
         year:  $("#request_year").val(),
         location:  $("#request_location").val(),
         description:  $("#request_description").val()
      };
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
      items.push(item);
      $("#order_items").val( JSON.stringify(items));
      return true;
   };

   $("#request-add").on("click", function() {
      if (validateItem() === false) return;
      var num = parseInt($("#item-number").text(), 10);
      num += 1;
      $("#item-number").text(num);
      $("#request_title").val("");
      $("#request_pages_to_digitize").val("");
      $("#request_call_number").val("");
      $("#request_author").val("");
      $("#request_year").val("");
      $("#request_location").val("");
      $("#request_description").val("");
      $("#request_title").focus();
   });

   $("#request-complete").on("click", function() {
      if (validateItem() === false) return;
      $("#order-form").submit();
   });

   $(".item-review .action.delete").on("click", function() {
      var itemIndex = $(this).closest(".ctls").data("item-idx");
      var items = JSON.parse($("#order_items").val());
      if (items.length === 1) {
         alert("An order must have at least one item.");
         return;
      }
      resp = confirm("Remove item "+(itemIndex+1)+" from your order?");
      if (rep ) {
         items.splice(itemIndex,1);
         $("#order_items").val( JSON.stringify(items) );
         $(this).closest(".item-review").remove();
      }
   });
});
