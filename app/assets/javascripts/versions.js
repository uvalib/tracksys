$(function () {
  $(".btn.diff").on("click", function () {
    var btn = $(this);
    if ( btn.hasClass("disabled")) return;
    btn.addClass("disabled");
    var tag = btn.data("tag");

    $("#diff-header").text("Diff of current version vs. "+tag);
    $("#tagged-btn").text(tag);
    $(".tab-btn").removeClass("selected");
    $("#diff-btn").addClass("selected");
    $("#diff-tab").show();
    $("#curr-tab").hide();
    $("#tagged-tab").hide();
    $("#diff").text("");
    $("#curr").text( "");
    $("#tagged").text("");
    $.ajax({
      url: window.location.href+"/diff?tag=" + tag,
      complete: function (jqXHR, textStatus) {
        if (textStatus != "success") {
          alert("Unable to get diff: "+jqXHR.responseText);
        } else {
          $("#diff").text( jqXHR.responseJSON.diff);
          $("#curr").text( jqXHR.responseJSON.curr);
          $("#tagged").text( jqXHR.responseJSON.tagged);
        }
        btn.removeClass("disabled");
      }
    });
    $("#diff-viewer-modal").show();
    $("#dimmer").show();
  });

  $(".tab-btn").on("click", function() {
    var tab = $(this).attr("id").split("-")[0];
    $(".tab-btn").removeClass("selected");
    $(this).addClass("selected");
    $(".diff-scroller").hide();
    $("#"+tab+"-tab").show();
  });

  $("#close-diff-viewer").on("click", function () {
    $("#diff-viewer-modal").hide();
    $("#dimmer").hide();
  });

  $(".btn.restore").on("click", function () {
    alert("restore " + $(this).data("tag"));
  });

  $(".btn.restore-all").on("click", function () {
    alert("restore all")
  });
});