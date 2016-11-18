$(document).ready(function () {
   $("#update-dl-settings").on("click", function() {
      $("#dimmer").show();
      $("#attachment-modal").hide();
      $("#settings-modal").show();
   });

   $("#cancel-settings").on("click", function() {
      $("#dimmer").hide();
      $("#settings-modal").hide();
   });

   $("#ok-settings").on("click", function() {
      if ( $("#ok-settings").hasClass("disabled")) return;
      $("#ok-settings").addClass("disabled");
      $("#cancel-settings").addClass("disabled");
      $.ajax({
         url: window.location.href+"/bulk_settings_update",
         method: "POST",
         data: { discoverable: $("#discoverable").val(),
                 availability: $("#availability").val(),
                 rights: $("#rights").val()
         },
         complete: function(jqXHR, textStatus) {
            $("#ok-settings").removeClass("disabled");
            $("#cancel-settings").removeClass("disabled");
            if ( textStatus != "success" ) {
               alert("Update failed: "+jqXHR.responseText);
            } else {
               alert("All settings have been updated");
               $("#dimmer").hide();
               $("#settings-modal").hide();
            }
         }
      });
   });
});
