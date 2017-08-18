$(function() {

   $(".mf-checkbox").on("change", function() {
      $("#download-select-pdf, #del-pages").removeClass("disabled");
      var pdfButtonExists = $("#download-select-pdf").length > 0;
      var url = "";

      if ( pdfButtonExists ) {
         url = $("#download-select-pdf").attr("href");
         url = url.split("&token")[0];
      }

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
            var token = "&token=" + Math.floor((new Date()).getTime() / 1000);
            url = url + token + "&pages=" + ids.join(",");
         }
      } else {
         $("#download-select-pdf, #del-pages").addClass("disabled");
      }
      $("#del-pages").data("filenames", filenames);

      if (pdfButtonExists) {
         $("#download-select-pdf").attr("href", url);
      }
   });

   $("#del-pages").on("click", function() {
      var msg = "Permanently delete all data associated with selected master files? This action cannot be reversed.<br/>Continue?";
      $("#confirm-msg").html(msg);
      $("#confirm-update").data("action", "delete");
      $("div.update-confirm").show();
      $("div.unit-mf-action-panel").hide();
   });

   $("#replace-pages").on("click", function() {
      var origUrl = window.location.href;
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
      var origUrl = window.location.href;
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
      var origUrl = window.location.href;
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
      var action = $("#confirm-update").data("action");
      var tid = setInterval(function() {
         $.ajax({
            url: window.location.href+"/status?job="+jobId+"&type="+action,
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
