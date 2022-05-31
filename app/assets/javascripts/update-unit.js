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
               window.location.reload();
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
      $("#ocr-pages, #pdf-pages, #del-pages, #renumber-pages, #assign-metadata").removeClass("disabled");

      var pdfButtonExists = $("#pdf-pages").length > 0;
      var url = "";

      if ( pdfButtonExists ) {
         // Grab the current base URL of the PDF service (withiout the token)
         url = $("#pdf-pages").attr("href");
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
            $("#pdf-pages").attr("href", url);
         }
      } else {
         // nothing selected; disable all buttons
         $("#ocr-pages, #pdf-pages, #del-pages, #renumber-pages", "#assign-metadata").addClass("disabled");
      }
      $("#del-pages").data("filenames", filenames);
      $("#renumber-pages").data("filenames", filenames);
      $("#assign-metadata").data("ids", ids);
      if ( $("#ocr-pages").length > 0 ) {
         $("#ocr-pages").data("ids", ids);
      }
   });

   $("#ocr-pages").on("click", function() {
      var msg = "OCR all selected master files?";
      $("#confirm-msg").html(msg);
      $("#confirm-update").data("action", "ocr");
      $("div.update-confirm").show();
      $("div.unit-mf-action-panel").hide();
   });

   $("#del-pages").on("click", function() {
      var msg = "Permanently delete all data associated with selected master files? This action cannot be reversed.<br/>Continue?";
      $("#confirm-msg").html(msg);
      $("#confirm-update").data("action", "delete");
      $("div.update-confirm").show();
      $("div.unit-mf-action-panel").hide();
   });

   $("#replace-pages").on("click", function() {
      var updateDir = $("#confirm-msg").data("update-dir");
      var msg = "Replace master files with .tif files from '"+updateDir+"'?";
      $("#confirm-msg").text(msg);
      $("#confirm-update").data("action", "replace");
      $("div.update-confirm").show();
      $("div.unit-mf-action-panel").hide();
   });

   $("#add-pages").on("click", function() {
      var btn = $(this);
      btn.addClass("disabled");
      var updateDir = $("#confirm-msg").data("update-dir");
      var msg = "Add .tif master files from '"+updateDir+ "' to unit?";
      $("#confirm-msg").text(msg);
      $("div.update-confirm").show();
      $("#confirm-update").data("action", "add");
      $("div.unit-mf-action-panel").hide();
   });

   $("#assign-metadata").on("click", function() {
      var btn = $(this);
      btn.addClass("disabled");
      $("div.assign-metadata").show();
      $("div.unit-mf-action-panel").hide();
   });
   $("#cancel-metadata").on("click", function() {
      $("div.assign-metadata").hide();
      $("div.unit-mf-action-panel").show();
      $("#assign-metadata").removeClass("disabled");
   });
   $("#confirm-assign-md").on("click", function(){
      var origURL = window.location.href.split("?")[0];
      $("#working-message").show();
      $("div.update-confirm").hide();
      var tgtURL = origURL + "/metadata";
      var ids = $("#assign-metadata").data("ids");
      data = { metadata: $("#metadata-id").val(), ids: ids };
      $.ajax({
         url: tgtURL,
         method: "POST",
         data: data,
         complete: function(jqXHR, textStatus) {
            if (textStatus != "success") {
               alert("Assign metadata failed: " + jqXHR.responseText);
               $("#working-message").hide();
               $("div.unit-mf-action-panel").show();
               $("#assign-metadata").removeClass("disabled");
            } else {
               alert("Metadata has been assigned")
               $("#working-message").hide();
               $("div.unit-mf-action-panel").show();
               $("#assign-metadata").removeClass("disabled");
            }
         }
      });
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
      if (action === "ocr") {
         data = { ids: $("#ocr-pages").data("ids") };
      }
      var tgtURL = origUrl + "/" + action;
      $.ajax({
         url: tgtURL,
         method: "POST",
         data: data,
         complete: function(jqXHR, textStatus) {
            if (textStatus != "success") {
               alert("Update failed: " + jqXHR.responseText);
               $("#working-message").hide();
               $("div.unit-mf-action-panel").show();
               $("#add-pages").removeClass("disabled");
            } else {
               if (action === "ocr") {
                  alert("OCR has been started on the selected master files. Check the Job Status page for updates.");
                  $("#working-message").hide();
                  $("div.unit-mf-action-panel").show();
               } else {
                  awaitUpdateComplete(jqXHR.responseText);
               }
            }
         }
      });
   });

   var awaitUpdateComplete = function(jobId) {
      var url =  window.location.href.split("?")[0];
      var action = $("#confirm-update").data("action");
      var tgtURL =  url+"/job_status?job="+jobId+"&type="+action;
      var tid = setInterval(function() {
         $.ajax({
            url: tgtURL,
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
                  } else if (jqXHR.responseText == "finished" || jqXHR.responseText == "success") {
                     clearInterval(tid);
                     window.location.reload();
                  }
               }
            }
         });
      }, 1000);
   };
});
