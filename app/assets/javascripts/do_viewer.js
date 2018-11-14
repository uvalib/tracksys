$(function() {
   $(".do-viewer-enabled").on("click", function() {
      $("#dimmer").show();
      $("#do-viewer-modal").show();
      var clickedPage = parseInt($(this).data("page"),10);
      var curioURL =  $(this).data("curio-url");
      var mfPid = $(this).data("metadata-pid");
      var url = curioURL+"/view/"+mfPid+"?page="+clickedPage;
      url = encodeURIComponent(url);
      var oembed = curioURL+"/oembed?url="+url+"&format=json&maxwidth=800&maxheight=600";
      $.getJSON(oembed, function ( data, textStatus, jqXHR ){
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
