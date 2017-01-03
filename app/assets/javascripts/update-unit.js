$(function() {

   $("#replace-pages").on("click", function() {
      var origUrl = window.location.href;
      var bits = origUrl.split("/");
      var unit = bits[bits.length -1 ];
      var msg = "Replace master files with .tif files from 'digiserv-production/unit_update/"+unit+"'?";
      $("#confirm-msg").text(msg);
      $("#confirm-update").data("action", "replace");
      $("div.update-confirm").show();
      $("div.unit-mf-action-panel").hide();
   });

   var awaitUpdateComplete = function( jobId ) {
      var tid = setInterval( function() {
         $.ajax({
            url: window.location.href+"/update_status?job="+jobId,
            method: "GET",
            complete: function(jqXHR, textStatus) {
               if (textStatus != "success") {
                  clearInterval(tid);
                  $("#working-message").hide();
                  $("div.unit-mf-action-panel").show();
                  alert("Unable to verify update status. Please check the job status page for more information.");
               } else {
                  if (jqXHR.responseText == "failure") {
                     clearInterval(tid);
                     $("#working-message").hide();
                     $("div.unit-mf-action-panel").show();
                     alert("Update failed. Please check the job status page for more information.")
                  } else if (jqXHR.responseText == "success") {
                     clearInterval(tid);
                     window.location.reload();
                  }
               }
            }
         });
      }, 1000);
   };

   $("#confirm-update").on("click", function() {
      var origUrl = window.location.href;
      $("#working-message").show();
      $("div.update-confirm").hide();
      var action = $("#confirm-update").data("action");
      $.ajax({
         url: origUrl + "/" + action,
         method: "POST",
         complete: function(jqXHR, textStatus) {
            if (textStatus != "success" ) {
               alert("Update failed: "+jqXHR.responseText);
               $("#working-message").hide();
               $("div.update-confirm").show();
            } else {
               awaitUpdateComplete( jqXHR.responseText );
            }
         }
      });
   });

   $("#cancel-update").on("click", function() {
      $("div.update-confirm").hide();
      $("div.unit-mf-action-panel").show();
   });

   $("#add-pages").on("click", function() {
      var btn = $(this);
      btn.addClass("disabled");
      var origUrl = window.location.href;
      var bits = origUrl.split("/");
      var unit = bits[bits.length -1 ];
      var msg = "Add .tif master files from 'digiserv-production/unit_update/"+unit+"' to unit?";
      $("#confirm-msg").text(msg);
      $("div.update-confirm").show();
      $("#confirm-update").data("action", "add");
      $("div.unit-mf-action-panel").hide();
   });
});
