$(function() {
  $("#change-location").on("click", function() {
    $(".edit-location-panel").hide();
    $("#location-finder-panel").show();
  });

  $("#new-location").on("click", function() {
    $(".edit-location-panel").hide();
    $("#new-location-panel").show();
  });

  $(".cancel-location").on("click", function() {
    $(".edit-location-panel").show();
    $("#location-finder-panel").hide();
    $("#new-location-panel").hide();
  });
});
