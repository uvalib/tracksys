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
      $("#metadata_id").val(id);

      $("#create-unit-panel").show();
      $("#metadata-finder").hide();
   });
});
