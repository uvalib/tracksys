$(document).ready(function () {
  $("span.as-lookup").on("click", function() {
    if ($("span.as-lookup").hasClass("disabled") ) return;
    var url = $("#as-url").val();
    if (url === "") return;

    $("span.as-lookup").addClass("disabled");

    $.ajax({
       url: "/admin/archivesspace?uri="+url,
       method: "GET",
       complete: function(jqXHR, textStatus) {
          $("span.as-lookup").removeClass("disabled");
          if ( textStatus === "success" ) {
            $("#as-collection").text(jqXHR.responseJSON.collection);
            $("#as-title").text(jqXHR.responseJSON.title);
            $("#as-id").text(jqXHR.responseJSON.id);
            $("#tgt-as-uri").text(jqXHR.responseJSON.uri);
          } else {
            $("#as-collection").text("Unable to find specified URL");
            $("#as-title").text("");
            $("#as-id").text("");
            $("#tgt-as-uri").text("");
          }
       }
    });
  });

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
        url: "/admin/archivesspace",
        method: "POST",
        data: { as_url: $("#as_url").val(),
                publish: $("#as_publish").prop('checked') },
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
