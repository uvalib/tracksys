$(document).ready(function () {
  $("#show-as-link-popup").on("click", function() {
    $("#dimmer").show();
    $("#as-modal").show();
  });

  $("#cancel-as").on("click", function() {
    $("#dimmer").hide();
    $("#as-modal").hide();
  });

  // validate URL on new/edit form
  $("#validate-as-url").on("click", function() {
    $("#new-ext-err").text("");

    if ( $("#external_metadata_external_system_id").val() != "1" ) {
      alert("Validate is only used for ArchivesSpace metadata");
      return;
    }
    $.ajax({
      url: "/admin/archivesspace/validate",
      method: "POST",
      data: { as_url: $("#external_metadata_external_uri").val() },
      complete: function(jqXHR, textStatus) {
        if ( textStatus != "success" ) {
          $("#new-ext-err").text(jqXHR.responseText);
        } else {
          $("#external_metadata_external_uri").val(jqXHR.responseText);
          alert("External URL is valid")
        }
      }
    });

  });

  $("#validate-as").on("click", function() {
    if ( $("#validate-as-link").hasClass("disabled")) return;

    $("#create-as-link").addClass("disabled");
    $("#validate-as").addClass("disabled");
    $("#as_error").text("");
    $("#as-valid").removeClass("yes");
    $("#as-valid").removeClass("no");
    $("#as-valid").html("&#10004;");

    $.ajax({
      url: "/admin/archivesspace/validate",
      method: "POST",
      data: { as_url: $("#as_url").val() },
      complete: function(jqXHR, textStatus) {
        $("#validate-as").removeClass("disabled");
        if ( textStatus != "success" ) {
          $("#as_error").text(jqXHR.responseText);
          $("#as-valid").addClass("no");
          $("#as-valid").html("&#10008;");
        } else {
          $("#as_url").val(jqXHR.responseText);
          $("#as-valid").addClass("yes");

          $("#create-as-link").removeClass("disabled");
        }
      }
    });
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
