$(function() {
   $(".do-viewer-enabled").on("click", function() {
      $("#dimmer").show();
      $("#do-viewer-modal").show();
      var clickedPage = parseInt($(this).data("page"),10)-1;
      var mfId = $(this).attr("id");
      var url = "/admin/master_files/"+mfId+"/viewer?page="+clickedPage;
      $.getJSON(url, function ( data, textStatus, jqXHR ){
         if (textStatus == "success" ) {
            $("#do-viewer-modal .content").append(data.html);
         }
      });

   });

   var closeDoViewer = function() {
      $("#dimmer").hide();
      $("#do-viewer-modal").hide();
      $("#do-viewer-modal .content").empty();
      window.embedScriptIncluded = false;
   };

   $("#close-do-viewer").on("click", function() {
      closeDoViewer();
   });

   if ( $("#do-viewer-modal").length > 0 ) {
      $(document).keyup(function(e) {
         if (e.keyCode == 27) {
            closeDoViewer();
         }
      });
   }
});
