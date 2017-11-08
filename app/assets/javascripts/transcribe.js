$(function() {

   if ($("#src-img").length > 0 ) {
      $("#src-img").panzoom({
         minScale: 1,
         maxScale: 20,

         $zoomIn: $(".zoom-in"),
         $zoomOut: $(".zoom-out"),
         $zoomRange: $(".zoom-range"),
         $reset: $(".reset"),
         onPan: function() {
            $(".img-box").css("background-image", "none");
         }
      });
   }

   $(".ocr-button.transcription").on("click", function() {
      var url = window.location.href;
      var id = url.split("=")[1];
      var data = {transcription: $("textarea.transcription").val() };
      btn.addClass("disabled");
      $.ajax({
         url: "/admin/master_files/"+id+"/save_transcription",
         data: data,
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
});
