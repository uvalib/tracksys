$(function() {
  $(".btn.diff").on("click", function() {
    $("#diff-viewer-modal").show();
    $("#dimmer").show();
  });

  $("#close-diff-viewer").on("click", function() {
    $("#diff-viewer-modal").hide();
    $("#dimmer").hide();
  });

  $(".btn.restore").on("click", function() {
    alert("restore "+$(this).data("tag"));
  });

  $(".btn.restore-all").on("click", function() {
    alert("restore all")
  });
});