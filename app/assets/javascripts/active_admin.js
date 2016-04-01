//= require jquery
//= require jquery.ui.all
//= jquery.colorbox
//= active_admin/application
//= chosen-jquery
//= pinterest
//= pinit
//= twitter
//= rainbow.min
//= generic
//= html
//= tracksys


$(function() {

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
                  } else if (jqXHR.responseJSON.status == 'failure' ) {
                     clearInterval(intervalId);
                     $("#ocr-spinner").hide();
                     $("#ocr-status-message").addClass("error");
                     $("#ocr-status-message").text(jqXHR.responseJSON.error);
                     $("#start-ocr").removeClass("disabled");
                  }
               } else {
                  $("#ocr-spinner").hide();
                  clearInterval(intervalId);
                  $("#ocr-status-message").addClass("error");
                  $("#ocr-status-message").text(textStatus);
                  $("#start-ocr").removeClass("disabled");
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

   var jobId = parseInt( $("#ocr-status-message").data("job-id"), 10);
   if ( jobId > 0  ) {
      $("#ocr-spinner").show();
      pollOcrJobStatus(jobId);
   }
});
