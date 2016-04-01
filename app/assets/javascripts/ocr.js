$(function() {

   var pollOcrJobStatus = function(jobId) {
      //var intervalId = setInterval( function() {
         $.getJSON( "/admin/ocr/status?job="+jobId, function( data ) {
            if ( data.status == 'success' ) {
               clearInterval(intervalId);
               $("textarea.transcription").val(data.transcription);
               $("#ocr-status-message").text("");
               $("#start-ocr").removeClass("disabled");
            } else if (data.status == 'failure' ) {
               clearInterval(intervalId);
               $("#ocr-status-message").addClass("error");
               $("#ocr-status-message").text(data.error);
               $("#start-ocr").removeClass("disabled");
            }
         }).fail(function( jqxhr, textStatus, error ) {
            var err = textStatus + ", " + error;
            console.log( "Request Failed: " + err );
         });
      //}, 2000);
   };

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
         data: {type: "MasterFile", id: id},
         method: "POST",
         complete: function( jqXHR, textStatus ) {
            if ( jqXHR.status != "200") {
               $("#ocr-status-message").removeClass("error");
               $("#ocr-status-message").text("Uable to perform OCR: "+textStatus);
               btn.removeClass("disabled");
            } else {
               $("#ocr-status-message").text("OCR in progress...");
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
