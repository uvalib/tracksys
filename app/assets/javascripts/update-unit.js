$(function() {

   $("#renumber-pages").on("click", function() {
      var resp = prompt("Enter new starting page number for the selected range of pages.");
      if (!resp) return;

      var filenames = $("#renumber-pages").data("filenames");
      $("#working-message").show();
      $("div.update-confirm").hide();
      $("#confirm-update").data("action", "renumber");
      var origUrl = window.location.href.split("?")[0];
      $.ajax({
         url: origUrl + "/renumber",
         method: "POST",
         data: {filenames: filenames, new_start_num: resp},
         complete: function(jqXHR, textStatus) {
            if (textStatus != "success") {
               alert("Renumber failed: " + jqXHR.responseText);
               $("#working-message").hide();
               $("div.unit-mf-action-panel").show();
            } else {
               awaitUpdateComplete(jqXHR.responseText);
            }
         }
      });
   });

   $("#sel-all").on("click", function() {
      if ( $("#sel-all").text() === "Select All") {
         $(".mf-checkbox").prop("checked", true);
         $("#sel-all").text("Deselect All");
      } else {
         $(".mf-checkbox").prop("checked", false);
         $("#sel-all").text("Select All");
      }
      $( $(".mf-checkbox")[0] ).trigger("change");
   });

   $(".mf-checkbox").on("change", function() {
      // default to enabling all buttons. This will be updated based
      // on the status of checked checkboxes below
      $("#download-select-pdf, #del-pages, #renumber-pages").removeClass("disabled");

      var pdfButtonExists = $("#download-select-pdf").length > 0;
      var url = "";

      if ( pdfButtonExists ) {
         // Grab the current base URL of the PDF service (withiout the token)
         url = $("#download-select-pdf").attr("href");
         url = url.split("&token")[0];
      }

      // Grab the masterfile IDs/filenames from all of the selected checkboxes
      var ids = [];
      var filenames = [];
      $(".mf-checkbox").each(function(idx, val) {
         if ($(val).is(":checked")) {
            ids.push($(val).data("mf-id"));
            filenames.push( $(val).closest("tr").find(".col-filename").text() );
         }
      });

      if (ids.length > 0) {
         if ( pdfButtonExists ) {
            // generate a new timestamp token to identify this new set of pages
            var token = "&token=" + Math.floor((new Date()).getTime() / 1000);
            url = url + token + "&pages=" + ids.join(",");
            $("#download-select-pdf").attr("href", url);
         }
      } else {
         // nothing selected; disable all buttons
         $("#download-select-pdf, #del-pages, #renumber-pages").addClass("disabled");
      }
      $("#del-pages").data("filenames", filenames);
      $("#renumber-pages").data("filenames", filenames);
   });

   $("#del-pages").on("click", function() {
      var msg = "Permanently delete all data associated with selected master files? This action cannot be reversed.<br/>Continue?";
      $("#confirm-msg").html(msg);
      $("#confirm-update").data("action", "delete");
      $("div.update-confirm").show();
      $("div.unit-mf-action-panel").hide();
   });

   $("#replace-pages").on("click", function() {
      var origUrl = window.location.href.split("?")[0];
      var bits = origUrl.split("/");
      var unit = bits[bits.length - 1];
      var msg = "Replace master files with .tif files from '/digiserv-production/finalization/unit_update/" + unit + "'?";
      $("#confirm-msg").text(msg);
      $("#confirm-update").data("action", "replace");
      $("div.update-confirm").show();
      $("div.unit-mf-action-panel").hide();
   });

   $("#add-pages").on("click", function() {
      var btn = $(this);
      btn.addClass("disabled");
      var origUrl = window.location.href.split("?")[0];
      var bits = origUrl.split("/");
      var unit = bits[bits.length - 1];
      var msg = "Add .tif master files from '/digiserv-production/finalization/unit_update/" + unit + "' to unit?";
      $("#confirm-msg").text(msg);
      $("div.update-confirm").show();
      $("#confirm-update").data("action", "add");
      $("div.unit-mf-action-panel").hide();
   });

   $("#cancel-update").on("click", function() {
      $("div.update-confirm").hide();
      $("div.unit-mf-action-panel").show();
   });

   $("#confirm-update").on("click", function() {
      var origUrl = window.location.href.split("?")[0];
      $("#working-message").show();
      $("div.update-confirm").hide();
      var action = $("#confirm-update").data("action");
      var data = {};
      if (action === "delete") {
         data = { filenames: $("#del-pages").data("filenames") };
      }
      $.ajax({
         url: origUrl + "/" + action,
         method: "POST",
         data: data,
         complete: function(jqXHR, textStatus) {
            if (textStatus != "success") {
               alert("Update failed: " + jqXHR.responseText);
               $("#working-message").hide();
               $("div.unit-mf-action-panel").show();
            } else {
               awaitUpdateComplete(jqXHR.responseText);
            }
         }
      });
   });

   var awaitUpdateComplete = function(jobId) {
      var url =  window.location.href.split("?")[0];
      var action = $("#confirm-update").data("action");
      var tid = setInterval(function() {
         $.ajax({
            url: url+"/status?job="+jobId+"&type="+action,
            method: "GET",
            complete: function(jqXHR, textStatus) {
               if (textStatus != "success") {
                  clearInterval(tid);
                  $("#working-message").hide();
                  $("div.unit-mf-action-panel").show();
                  alert("Unable to verify update status. Please check the job status page for more information.");
               } else {
                  if (jqXHR.responseText === "failure") {
                     clearInterval(tid);
                     $("#working-message").hide();
                     $("div.unit-mf-action-panel").show();
                     alert("Update failed. Please check the job status page for more information.");
                  } else if (jqXHR.responseText == "success") {
                     clearInterval(tid);
                     window.location.reload();
                  }
               }
            }
         });
      }, 1000);
   };
});
