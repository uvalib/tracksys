$(function() {
   $(".do-viewer-enabled").on("click", function() {
      $("#dimmer").show();
      $("#do-viewer-modal").show();
      var clickedPage = parseInt($(this).data("page"),10);
      var mfId = $(this).attr("id");
      var url = "/admin/master_files/"+mfId+"/viewer?page="+clickedPage;
      $.getJSON(url, function ( data, textStatus, jqXHR ){
         if (textStatus == "success" ) {
            $("#do-viewer-modal .content").append(data.html);
         }
      });

      // Example use of calling the oEmbed enpoint
      // var mfPid = $(this).data("metadata-pid");
      // var url = "https://doviewer.lib.virginia.edu/images/"+mfPid+"?page="+clickedPage;
      // url = encodeURIComponent(url);
      // var oembed = "https://doviewer.lib.virginia.edu/oembed?url="+url+"&format=json&maxwidth=800&maxheight=600";
      // $.getJSON(oembed, function ( data, textStatus, jqXHR ){
      //    if (textStatus == "success" ) {
      //       $("#do-viewer-modal .content").append(data.html);
      //    }
      // });
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
