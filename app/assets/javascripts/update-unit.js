$(function() {
   $("#add-pages").on("click", function() {
      var btn = $(this);
      btn.addClass("disabled");
      var origUrl = window.location.href;
      var bits = origUrl.split("/");
      var unit = bits[bits.length -1 ];
      var resp = confirm("Add .tif master files from 'digiserv-production/unit_update/"+unit+"' to unit?");
      if (resp) {
         $.ajax({
            url: origUrl + "/add",
            method: "POST",
            complete: function(jqXHR, textStatus) {
               btn.removeClass("disabled");
               if (textStatus != "success" ) {
                  alert("Unable to add pages: "+jqXHR.responseText);
                  return;
               } else {
                  alert("Update started. Check job status page for more information")
               }
            }
         });
      } else {
         btn.removeClass("disabled");
      }
   });
});
