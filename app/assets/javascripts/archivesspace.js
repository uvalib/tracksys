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
    var unitID = $(this).data("unit-id");

    $.ajax({
        url: "/admin/archivesspace",
        method: "POST",
        data: { unit_id: unitID, as_url: $("#as_url").val() },
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
