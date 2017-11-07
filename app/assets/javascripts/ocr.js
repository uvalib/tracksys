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
      var btn = $(this);
      var textType = "transcription";
      if (btn.hasClass("ocr")) {
         textType = "ocr";
      }
      var data = {id: id, type: textType, transcription: $("textarea.transcription").val() };
      btn.addClass("disabled");
      $.ajax({
         url: "/admin/ocr/save",
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
