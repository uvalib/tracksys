$(document).ready(function () {
   $("#show-as-link-popup").on("click", function() {
      $("#dimmer").show();
      $("#as-modal").show();
   });

   $("#cancel-as").on("click", function() {
      $("#dimmer").hide();
      $("#as-modal").hide();
   });

   $("#create-as-link").on("click", function() {
     if ( $("#create-as-link").hasClass("disabled")) return;

     $("#create-as-link").addClass("disabled");
     $("#cancel-as").addClass("disabled");

     $.ajax({
        url: window.location.href+"/archivesspace",
        method: "POST",
        data: { as_url: $("#as_url").val(),
                publish: $("#as_publish").prop('checked')
        },
        complete: function(jqXHR, textStatus) {
           $("#create-as-link").removeClass("disabled");
           $("#cancel-as").removeClass("disabled");
           if ( textStatus != "success" ) {
              alert("Link failed: "+jqXHR.responseText);
           } else {
              alert("Link created");
              window.location.reload();
           }
        }
     });
   });
 });
