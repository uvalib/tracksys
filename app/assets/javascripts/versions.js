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
    var btn = $(this);
    if ( btn.hasClass("disabled")) return;
    var tag = btn.data("tag");

    var msg = "Restore version "+tag+"?"
    msg += "\nNOTE: All versions between current and the restored version will be permanently removed."
    msg += "\n\nContinue?";
    var resp = confirm(msg);
    if ( !resp) return;

    btn.addClass("disabled");
    
    $.ajax({
      url: window.location.href+"/revert?tag=" + tag,
      method: "post",
      complete: function (jqXHR, textStatus) {
        if (textStatus != "success") {
          alert("Unable to restore diff: "+jqXHR.responseText);
        } else {
          alert(jqXHR.responseJSON.message);
          window.location.reload();
        }
        btn.removeClass("disabled");
      }
    });
  });

  $(".btn.restore-all").on("click", function () {
    var btn = $(this);
    if ( btn.hasClass("disabled")) return;
    var tag = btn.data("tag");
    
    var msg = "Revert all affected files to "+tag+"?"
    msg += "\n\nAll versions between current and the restored version will be permanently removed."
    msg += "\n\nContinue?";
    var resp = confirm(msg);
    if ( !resp) return;

    btn.addClass("disabled");

    $.ajax({
      url: window.location.href+"/revert?tag=" + tag+"&all=true",
      method: "post",
      complete: function (jqXHR, textStatus) {
        if (textStatus != "success") {
          alert("Unable to restore diff: "+jqXHR.responseText);
        } else {
          alert(jqXHR.responseJSON.message);
          window.location.reload();
        }
        btn.removeClass("disabled");
      }
    });
  });
});