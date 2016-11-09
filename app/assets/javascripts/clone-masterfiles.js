$(function() {
   $("#copy-existing").on("click", function() {
      $("#masterfile-list").hide();
      $("#clone-panel").show();
      $("#copy-existing").hide();
   });

   $("#cancel-clone").on("click", function() {
      $("#masterfile-list").show();
      $("#clone-panel").hide();
      $("#copy-existing").show();
   });

   var getMasterFiles = function( page ) {
      $("#source-masterfile-list").data("page", page );
      var selectedUnit = $("#source-unit").val();
      $("#curr-page").blur();
      $.getJSON("/admin/units/"+selectedUnit+"/master_files?page="+page, function ( data, textStatus, jqXHR ) {
         if (textStatus == "success" ) {
            json = jqXHR.responseJSON;
            $("div.paging-controls").show();
            $("#start-cnt").text(json.start);
            $("#end-cnt").text(json.end);
            $("#total-cnt").text(json.total);
            $("#max-page").text(json.maxpage);
            $("#curr-page").val(json.page);
            $(".page-buttons").show();
            if ( json.maxpage == 1) {
               $(".page-buttons").hide();
            }
            $(".paging.prev").removeClass("disabled");
            $(".paging.next").removeClass("disabled");
            if ( page == 1 ) {
               $(".paging.prev").addClass("disabled");
            } else if (page == json.maxpage) {
               $(".paging.next").addClass("disabled");
            }
            $("#source-masterfile-list tbody").empty();
            var template = "<tr class='mf-row'><td><input class='sel-cb' type='checkbox' data-id='MF_ID'/></td>";
            template +=    "<td>MF_FILE</td><td>MF_TITLE</td><td><img src='MF_IMAGE'/></td></tr>";
            $.each(json.masterfiles, function(idx,val) {
               var r = template;
               r = r.replace("MF_ID", val.id);
               r = r.replace("MF_FILE", val.filename);
               r = r.replace("MF_TITLE", val.title);
               r = r.replace("MF_IMAGE", val.thumb);
               $('#source-masterfile-list tbody').append(r);
            });
         } else {
            alert("Unable to retrieve unit master files: "+jqXHR.responseText);
         }
      });
   }

   $("#curr-page").on("keypress", function(event) {
      if (event.which == 13) {
         var pg = parseInt($("#curr-page").val(), 10);
         var max = parseInt($("#max-page").text(),10);
         if (pg >=1 && pg <= max) {
            getMasterFiles(pg);
         }
         event.stopPropagation();
      }
   });

   $("#source-unit").chosen().change( function() {
      getMasterFiles( 1);
   });

   $(".paging.prev").on("click", function() {
      if ( $(this).hasClass("disabled") ) return;
      var pg = parseInt( $("#source-masterfile-list").data("page"), 10);
      pg -= 1;
      pg = Math.max(0, pg);
      getMasterFiles(pg);
   });
   $(".paging.next").on("click", function() {
      if ( $(this).hasClass("disabled") ) return;
      var pg = parseInt( $("#source-masterfile-list").data("page"), 10);
      var max = parseInt($("#max-page").text(),10);
      pg += 1;
      pg = Math.min(max, pg);
      getMasterFiles(pg);
   });

   $("#source-masterfile-list").on("click", ".mf-row", function() {
      var cb = $(this).find(".sel-cb");
      if ( cb.is(':checked')) {
         cb.prop('checked', false);
      } else {
         cb.prop('checked', true);
      }
   });
});
