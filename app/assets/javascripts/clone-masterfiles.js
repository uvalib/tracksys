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
            $("div.clone-controls.paging").show();
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
            var template = "<tr class='CLASS' data-id='MF_ID'>";
            template += "<td><input class='sel-cb' type='checkbox'/></td>";
            template += "<td class='mf-file'>MF_FILE</td><td class='mf-title'>MF_TITLE</td><td><img src='MF_IMAGE'/></td></tr>";
            $.each(json.masterfiles, function(idx,val) {
               var rowClass = "mf-row";
               if ( $("#clone-masterfile-list .sel-cb[data-id='"+val.id+"']").length > 0 ) {
                  rowClass += " cloned";
               }
               if ( $("#clone-masterfile-list .sel-cb[data-unit-id='"+selectedUnit+"']").length > 0 ) {
                  rowClass += " cloned";
               }
               var r = template;
               r = r.replace("CLASS",rowClass);
               r = r.replace(/MF_ID/g, val.id);
               r = r.replace(/MF_FILE/g, val.filename);
               r = r.replace(/MF_TITLE/g, val.title);
               r = r.replace("MF_IMAGE", val.thumb);
               $('#source-masterfile-list tbody').append(r);
            });
         } else {
            alert("Unable to retrieve unit master files: "+jqXHR.responseText);
         }
      });
   };

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

   $(".clone-btn.prev").on("click", function() {
      if ( $(this).hasClass("disabled") ) return;
      var pg = parseInt( $("#source-masterfile-list").data("page"), 10);
      pg -= 1;
      pg = Math.max(0, pg);
      getMasterFiles(pg);
   });
   $(".clone-btn.next").on("click", function() {
      if ( $(this).hasClass("disabled") ) return;
      var pg = parseInt( $("#source-masterfile-list").data("page"), 10);
      var max = parseInt($("#max-page").text(),10);
      pg += 1;
      pg = Math.min(max, pg);
      getMasterFiles(pg);
   });

   $("#source-masterfile-list, #clone-masterfile-list").on("click", ".mf-row", function(event) {
      if (  $(this).hasClass("cloned") ) return;
      if ( $(event.target).hasClass("sel-cb") ) return;

      var cb = $(this).find(".sel-cb");
      if ( cb.is(':checked')) {
         cb.prop('checked', false);
      } else {
         cb.prop('checked', true);
      }
   });

   var copyMasterFileToCloneList = function( mfRow ) {
      var selectedUnit = $("#source-unit").val();
      var r = "<tr class='mf-row'><td><input data-id='MF_ID' class='sel-cb' type='checkbox'/></td>";
      r +=    "<td>MF_FILE</td><td><span class='title'>MF_TITLE</span><span class='rename-btn'></span></td>";
      r +=    "<td class='sort'><span class='ts-icon down'></span><span class='ts-icon up'></span></td></tr>";
      r = r.replace("MF_ID", mfRow.data("id"));
      r = r.replace("MF_FILE", mfRow.find(".mf-file").text() );
      r = r.replace("MF_TITLE",  mfRow.find(".mf-title").text() );
      $('#clone-masterfile-list tbody').append(r);
   };

   $("#clone-masterfile-list").on("click", ".up", function(event) {
      event.stopPropagation();
      var thisRow = $(this).closest('tr');
      var prevRow = thisRow.prev();
      if (prevRow.length) {
         prevRow.before(thisRow);
      }
   });
   $("#clone-masterfile-list").on("click", ".down", function(event) {
      event.stopPropagation();
      var thisRow = $(this).closest('tr');
      var nextRow = thisRow.next();
      if (nextRow.length) {
         nextRow.after(thisRow);
      }
   });

   $("#clone-masterfile-list").on("click", ".rename-btn", function(event) {
      event.stopPropagation();
      var title = $(this).closest("td").find('.title');
      $("#new-title").val(title.text());
      $("#dimmer").show();
      $("#attachment-modal").hide();
      $("#title-modal").show();
      $("#title-modal").data("target", title);
   });
   $("#cancel-title").on("click", function() {
      $("#dimmer").hide();
      $("#title-modal").hide();
   });
   $("#ok-title").on("click", function() {
      $("#dimmer").hide();
      $("#title-modal").hide();
      var title = $("#title-modal").data("target");
      var txt = $("#new-title").val();
      title.text( txt );
   });

   $(".clone-btn.add-all").on("click", function() {
      $("#source-masterfile-list tbody tr").each( function()  {
         if ( $(this).hasClass("cloned") === false) {
            $(this).addClass("cloned");
         }
      });

      var uid = $("#source-unit").val();
      var allRow = "<tr class='mf-row'>";
      allRow += "<td><input  data-unit-id='"+uid+"' data-id='0' class='sel-cb' type='checkbox'/></td>";
      allRow += "<td colspan='3' class='clone-all'>All master files from unit "+uid+" will be cloned</td></tr>";
      $('#clone-masterfile-list tbody').append(allRow);
   });

   $(".clone-btn.add").on("click", function() {
      $("#source-masterfile-list .sel-cb:checked").each( function()  {
         var tr = $(this).closest("tr");
         if ( tr.hasClass("cloned") === false) {
            tr.addClass("cloned");
            copyMasterFileToCloneList( tr );
         }
      });
   });

   $(".clone-btn.remove").on("click", function() {
      $("#clone-masterfile-list .sel-cb:checked").each( function()  {
         var mfId = $(this).data("id");
         var uId = $(this).data("unit-id");
         var selUnit = $("#source-unit").val();
         $(this).closest(".mf-row").remove();
         if ( mfId === 0 && uId == selUnit) {
            $("#source-masterfile-list .cloned").removeClass("cloned");
            $("#source-masterfile-list .sel-cb").prop('checked', false);
         } else {
            var row = $("#source-masterfile-list .mf-row[data-id='"+mfId+"']");
            row.removeClass("cloned");
            row.find(".sel-cb").prop('checked', false);
         }
      });
   });

   $(".clone-btn.remove-all").on("click", function() {
      $("#clone-masterfile-list tbody").empty();
      $("#source-masterfile-list .cloned").removeClass("cloned");
      $("#source-masterfile-list .sel-cb").prop('checked', false);
   });

   var toggleCloneButtons = function( enabled ) {
      if ( !enabled ) {
         $("#clone").addClass("disabled");
         $(".clone-btn").addClass("disabled");
         $("#cancel-clone").addClass("disabled");
         $('#source-unit').prop('disabled', true).trigger("chosen:updated");
         $("#clone-panel").addClass("working");
         $("#cloning-message").show();
      } else {
         $("#clone").removeClass("disabled");
         $(".clone-btn").removeClass("disabled");
         $("#cancel-clone").removeClass("disabled");
         $('#source-unit').prop('disabled', false).trigger("chosen:updated");
         $("#clone-panel").removeClass("working");
         $("#cloning-message").hide();
      }
   };

   var awaitCloneComplete = function(jobId) {
      var tid = setInterval( function() {
         $.ajax({
            url: window.location.href+"/clone_status?job="+jobId,
            method: "GET",
            complete: function(jqXHR, textStatus) {
               if (textStatus != "success") {
                  clearInterval(tid);
                  toggleCloneButtons(true);
                  alert("Unable to verify clone status. Please check the job status page for more information.");
               } else {
                  if (jqXHR.responseText == "failure") {
                     clearInterval(tid);
                     toggleCloneButtons(true);
                     alert("Clone failed. Please check the job status page for more information.");
                  } else if (jqXHR.responseText == "success") {
                     clearInterval(tid);
                     window.location.reload();
                  }
               }
            }
         });
      }, 1000);
   };

   $("#clone").on("click", function() {
      var resp = confirm("Clone selected master files into this unit.\n\nAre you sure?");
      if (!resp) return;

      toggleCloneButtons(false);

      var list = [];
      $("#clone-masterfile-list .mf-row").each( function() {
         var cb = $(this).find(".sel-cb");
         var id =  cb.data("id");
         if ( id === 0) {
            list.push({unit: cb.data("unit-id")});
         } else {
            var rec = {};
            rec.id = $(this).find(".sel-cb").data("id");
            rec.title =  $(this).find(".title").text();
            list.push(rec);
         }
      });

      $.ajax({
         url: window.location.href+"/clone_master_files",
         method: "POST",
         dataType: 'json',
         contentType: 'application/json',
         data: JSON.stringify({ masterfiles: list}),
         complete: function(jqXHR, textStatus) {
            if ( textStatus != "success" ) {
               alert("Unable to clone master files: "+jqXHR.responseText);
               toggleCloneButtons(true);
            } else {
               awaitCloneComplete( jqXHR.responseText );
            }
         }
      });
   });
});
