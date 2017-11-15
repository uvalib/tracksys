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
});
