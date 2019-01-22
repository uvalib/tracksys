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
    var metadataID = $(this).data("metadata-id");

    $.ajax({
        url: "/admin/archivesspace/convert",
        method: "POST",
        data: { metadata_id: metadataID, as_url: $("#as_url").val() },
        complete: function(jqXHR, textStatus) {
           $("#create-as-link").removeClass("disabled");
           $("#cancel-as").removeClass("disabled");
           if ( textStatus != "success" ) {
              alert("Conversion failed: "+jqXHR.responseText);
           } else {
              window.location.reload();
           }
        }
    });
  });

  $(".btn.as-publish").on("click", function() {
    if ( $(".btn.as-publish").hasClass("disabled")) return;
    $(".btn.as-publish").addClass("disabled");
    $.ajax({
      url: window.location.href+"/as_publish",
      method: "POST",
      complete: function(jqXHR, textStatus) {
        $(".btn.as-publish").removeClass("disabled");
        if ( textStatus == "success" ) {
          window.location.reload();
        } else {
          alert(jqXHR.responseText);
        }
      }
    });
  });
});
