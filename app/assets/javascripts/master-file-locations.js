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
    $("#location-message").text("");
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

  $("#container-name").on("change", function() {
    var locs = $("#location-finder-panel").data("locations");
    var nameVal = $(this).val();
    $("#folder-name").removeAttr("disabled", "disabled");
    var folders = [];
    $.each(locs, function(idx, val) {
      if (val.container_id == nameVal && folders.includes(val.folder_id)===false ) {
        folders.push(val.folder_id);
        $("#folder-name").append("<option value="+val.folder_id+">"+val.folder_id+"</option>");
      }
    });
    $("#folder-name").find('option:first').attr('selected', 'selected');
  });

  $("#select-location").on("click", function() {
    $("#location-error").hide();
    var folder = $("#folder-name").val();
    var boxName = $("#container-name").val();
    var containerType = parseInt($("#container-type").val(),10);
    var goodFolder = (containerType > 3 || containerType < 4 && folder != "" );
    if ( boxName === "" || containerType === "" || !goodFolder ) {
      $("#location-error").text("Please select a value for all entries");
      $("#location-error").show();
      return;
    }

    // find the ID of the location matching the selections...
    var locs = $("#location-finder-panel").data("locations");
    var locId = -1;
    $.each(locs, function(idx, val) {
      if (val.container_type_id == containerType && val.container_id == boxName) {
        if ( val.has_folders ) {
          if (val.folder_id == folder) {
            locId = val.id;
            return false;
          }
        } else {
          locId = val.id;
          return false;
        }
      }
    });

    var url = window.location.href;
    url = url.replace("edit", "update_location");
    $.ajax({
       url: url,
       method: "PUT",
       data: {location: locId },
       complete: function(jqXHR, textStatus) {
          if (textStatus != "success") {
             $("#location-error").text("Update failed: "+jqXHR.responseText);
             $("#location-error").show();
          } else {
             $("#master_file_container_type_id").val(containerType);
             $("#master_file_container_id").val(boxName);
             $("#master_file_folder_id").val(folder);
             $(".edit-location-panel").show();
             $("#location-finder-panel").hide();
             $("#location-message").text("Location has been updated");
          }
       }
    });
  });
});
