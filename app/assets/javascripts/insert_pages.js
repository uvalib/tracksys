$(function() {
   $("#insert-pages").on("click", function() {
      $("#insert-pages").addClass("disabled");
      var origUrl = window.location.href;
      var bits = origUrl.split("/");
      var unit = bits[bits.length -1 ];
      var resp = confirm("Insert pages from digiserv-production/unit_update/"+unit+" into unit?");
      if (resp) {
         var url = origUrl + "/insert"
         $.ajax({
            url: url,
            method: "POST",
            complete: function(jqXHR, textStatus) {
               $("#insert-pages").removeClass("disabled");
               if (textStatus != "success" ) {
                  alert("Unable to insert pages: "+jqXHR.responseText);
                  return;
               } else {
                  alert("Insert started. Check job status page for more information")
               }
            }
         });
      } else {
         $("#insert-pages").removeClass("disabled");
      }
   });
});
