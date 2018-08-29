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

  $("#container-type").on("change", function() {
    var locs = $("#location-finder-panel").data("locations");
    var typeVal =  parseInt($(this).val(),10);
    $("#folder-selector").show();
    if ( typeVal > 3 ) {
      $("#folder-selector").hide();
    }

    // reset all container name options to match container
    $("#container-name").removeAttr("disabled");
    $("#folder-name").attr("disabled", "disabled");

    $("#container-name").find("option").remove();
    $("#container-name").append("<option>Select a name</option>");
    $("#folder-name").find("option").remove();
    $("#folder-name").append("<option>Select a folder</option>");
    var containers = [];
    $.each(locs, function(idx, val) {
      if (val.container_type_id == typeVal && containers.includes(val.container_id)===false ) {
        containers.push(val.container_id);
        $("#container-name").append("<option value="+val.container_id+">"+val.container_id+"</option>");
      }
    });

    $("#container-name").find('option:first').attr('selected', 'selected');
    $("#folder-name").find('option:first').attr('selected', 'selected');
  });
});
