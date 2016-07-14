$(function() {

   setTimeout( function() {

      $("#src-img").panzoom({
         minScale: 1,
         maxScale: 10,
         transition: true,
         duration: 100,
         increment: 0.5,
         $zoomIn: $(".zoom-in"),
         $zoomOut: $(".zoom-out"),
         $zoomRange: $(".zoom-range"),
         $reset: $(".reset"),
         onPan: function() {
            $(".img-box").css("background-image", "none");
         }
      });

   }, 500);

   var updateUnitOcrStatus = function(statusObj) {
      $(".exclude").each( function(idx) {
         if ( !$(this).is(":checked") ) {
            var id = parseInt($(this).data("id"),10);
            var statusIcon = $(this).closest("tr").find("span.status");
            if (statusObj.status == 'failure') {
               $(statusIcon).removeClass().addClass("status").addClass("error");
            } else if (statusObj.status == 'success') {
               $(statusIcon).removeClass().addClass("status").addClass("success");
            } else {
               if ( $.inArray(id, statusObj.complete) > -1 ) {
                  $(statusIcon).removeClass().addClass("status").addClass("success");
               } else {
                  $(statusIcon).removeClass().addClass("status").addClass("working");
               }
            }
         }
      });
   };

   var pollOcrJobStatus = function(jobId) {
      var intervalId = setInterval( function() {
         $.ajax({
            url: "/admin/ocr/status?job="+jobId,
            method: "GET",
            complete: function( jqXHR, textStatus ) {
               if ( jqXHR.status == 200) {
                  if ( jqXHR.responseJSON.status == 'success' ) {
                     clearInterval(intervalId);
                     $("#ocr-spinner").hide();
                     $("textarea.transcription").val(jqXHR.responseJSON.transcription);
                     $("#ocr-status-message").text("");
                     $("#start-ocr").removeClass("disabled");
                     $("#start-unit-ocr").removeClass("disabled");
                     if (jqXHR.responseJSON.type == "Unit") {
                        updateUnitOcrStatus( jqXHR.responseJSON );
                     }
                  } else if (jqXHR.responseJSON.status == 'failure' ) {
                     clearInterval(intervalId);
                     $("#ocr-spinner").hide();
                     $("#ocr-status-message").addClass("error");
                     $("#ocr-status-message").text(jqXHR.responseJSON.error);
                     $("#start-ocr").removeClass("disabled");
                     $("#start-unit-ocr").removeClass("disabled");
                     if (jqXHR.responseJSON.type == "Unit") {
                        updateUnitOcrStatus( jqXHR.responseJSON );
                     }
                  } else if (jqXHR.responseJSON.status == 'running' ) {
                     if (jqXHR.responseJSON.type == "Unit") {
                        updateUnitOcrStatus( jqXHR.responseJSON );
                     }
                  }
               } else {
                  $("#ocr-spinner").hide();
                  clearInterval(intervalId);
                  $("#ocr-status-message").addClass("error");
                  $("#ocr-status-message").text(textStatus);
                  $("#start-ocr").removeClass("disabled");
                  $("#start-unit-ocr").removeClass("disabled");
               }
            }
         })
      }, 2000);
   };

   $(".ocr-button.transcription").on("click", function() {
      var url = window.location.href;
      var id = url.split("=")[1];
      var btn = $(this);
      btn.addClass("disabled");
      $.ajax({
         url: "/admin/ocr/save",
         data: {id: id, transcription: $("textarea.transcription").val() },
         method: "POST",
         complete: function( jqXHR, textStatus ) {
            btn.removeClass("disabled");
            if ( jqXHR.status != 200) {
               alert("Save transcription failed: "+textStatus);
            } else {
               alert("Transcription saved");
            }
         }
      });
   });

   /**
    * Start OCR for master files owned by a unit
    */
   $("#start-unit-ocr").on("click", function() {
      if ( $(this).hasClass("disabled")) {
         return;
      }

      var exclude = [];
      $(".exclude").each( function(idx) {
         if ( $(this).is(":checked")) {
            var id = $(this).data("id");
            exclude.push(id);
         }
      });

      $("#ocr-status-message").removeClass("error");
      $("#ocr-status-message").text("");
      $(this).addClass("disabled");
      var btn = $(this);
      var url = window.location.href;
      var id = url.split("=")[1];
      $.ajax({
         url: "/admin/ocr/start",
         data: {type: "Unit", id: id, lang: $("#language").val(), exclude: exclude },
         method: "POST",
         complete: function( jqXHR, textStatus ) {
            if ( jqXHR.status != 200) {
               $("#ocr-status-message").removeClass("error");
               $("#ocr-status-message").text("Uable to perform OCR: "+textStatus);
               btn.removeClass("disabled");
            } else {
               $("#ocr-status-message").text("OCR in progress...");
               $("input.exclude").each( function(idx) {
                  $(this).attr("disabled", "disabled");
                  var statusIcon = $(this).closest("tr").find("span.status")
                  if ( !$(this).is(":checked") ) {
                     $(statusIcon).removeClass().addClass("status").addClass("pending");
                  }
               });

               var jobId = jqXHR.responseText;
               pollOcrJobStatus(jobId);
            }
         }
      });
   });

   /**
    * Start OCR for a single master file
    */
   $("#start-ocr").on("click", function() {
      if ( $(this).hasClass("disabled")) {
         return;
      }
      $("#ocr-status-message").removeClass("error");
      $("#ocr-status-message").text("");
      $(this).addClass("disabled");
      var btn = $(this);
      var url = window.location.href;
      var id = url.split("=")[1];
      $.ajax({
         url: "/admin/ocr/start",
         data: {type: "MasterFile", id: id, lang: $("#language").val() },
         method: "POST",
         complete: function( jqXHR, textStatus ) {
            if ( jqXHR.status != 200) {
               $("#ocr-status-message").removeClass("error");
               $("#ocr-status-message").text("Uable to perform OCR: "+textStatus);
               btn.removeClass("disabled");
            } else {
               $("#ocr-status-message").text("OCR in progress...");
               $("#ocr-spinner").show();
               var jobId = jqXHR.responseText;
               pollOcrJobStatus(jobId);
            }
         }
      });
   });

   $("td.check").on("click", function() {
      $(this).find(".exclude").trigger("click");
   });

   $(".exclude").on("change", function() {
      var excluded = 0;
      var total = 0;
      $(".exclude").each( function(idx) {
         total += 1;
         var img = $(this).closest("tr").find("img");
         if ( $(this).is(":checked")) {
            excluded += 1;
            img.css("opacity", "0.25");
         } else {
            img.css("opacity", "1");
         }
      });
      $("#ocr-count").text(total-excluded);
   });

   var showUnitOcrStatus = function(job) {
      var params = JSON.parse(job.params)
      $(".exclude").each( function(idx) {
         var id = parseInt($(this).data("id"),10);
         if ( $.inArray(id, params.exclude) > -1) {
            $(this).trigger("click");
         } else {
             $(this).closest("tr").find("span.status").removeClass("none").addClass("pending");
         }
         $(this).attr("disabled", "disabled");
      });
   };

   // When page loads, see if there is an OCR job in progress for this
   // unit or master file. If so, show some status and start polling
   var job_json =$("#ocr-status-message").data("job-json");
   if ( job_json  ) {
      if (job_json.originator_type == "Unit") {
         showUnitOcrStatus(job_json);
      } else {
         $("#ocr-spinner").show();
      }
      pollOcrJobStatus( job_json.id );
   }
});
