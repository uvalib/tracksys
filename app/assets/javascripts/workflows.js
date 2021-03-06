$(function() {
   /* lines on the chart */
   var drawArrowhead=function(ctx, x, y, radians){
      ctx.save();
      ctx.beginPath();
      ctx.translate(x,y);
      ctx.rotate(radians);
      ctx.moveTo(0,0);
      ctx.lineTo(9,10);
      ctx.lineTo(-9,10);
      ctx.closePath();
      ctx.restore();
      ctx.fillStyle = "#1E90FF";
      ctx.fill();
   };
   if ( $("#workflow-canvas").length > 0 ) {
      var canvas = $("#workflow-canvas")[0];
      canvas.width  = canvas.offsetWidth;
      canvas.height = canvas.offsetHeight;
      var ctx = canvas.getContext("2d");
      ctx.lineWidth=4;
      ctx.lineCap='round';
      ctx.strokeStyle="#1E90FF";
      $(".workflow-step.error").each( function() {
         if ( $(this).hasClass("final") === false ) {
            var tgtId = $(this).data("next");
            var tgtStep = $(".workflow-step[data-id='"+tgtId+"']");
            var p0 = $(this).position();
            var l0 = p0.left;
            var t0 = p0.top+$(this).outerHeight();
            var p1 = tgtStep.position();
            var l1 =  p1.left+$(this).outerWidth()+2;
            var t1 = p1.top-2;
            ctx.beginPath();
            ctx.moveTo(l0, t0 );
            ctx.lineTo(l1, t1);
            ctx.stroke();

            var startRadians=Math.atan((t1-t0)/(l1-l0));
            startRadians+=((l1>l0)?-270:270)*Math.PI/180;
            drawArrowhead(ctx, l1-2, t1+2, startRadians);
         }
      });
   }
   $("#ocr-language-hint-edit").chosen({
      width: "200px"
   });
   $("#assign-to").chosen({
       no_results_text: "Sorry, no matches found",
       width: "100%"
   });
   $(".assign-menu, #assign-button").on("click", function() {
      var projectId = $(this).data("project");
      $("#assign-staff").data("project", projectId);
      $("#assign-staff").data("reload", $(this).attr("id") === "assign-button");
      $.ajax({
         url: "/admin/projects/"+projectId+"/assignable",
         method: "GET",
         complete: function(jqXHR, textStatus) {
            var sel = $("#assign-to");
            sel.empty();
            if ( textStatus === "success" ) {
               sel.append( $("<option value=''>Select Staff Member</option>") );
               $.each(jqXHR.responseJSON, function(idx, val) {
                  sel.append( $("<option value='"+val.id+"'>"+val.name+"</option>") );
               });
               sel.trigger("chosen:updated");
            }
            $("#assign-dimmer").show();
         }
      });

      $(".owner-dd").hide();
   });
   $("#cancel-assign").on("click", function() {
      $("#assign-dimmer").hide();
   });
   $("#ok-assign").on("click", function() {
      var userId = $("#assign-to").val();
      var projectId = $("#assign-staff").data("project");
      $.ajax({
         url: "/admin/projects/"+projectId+"/assign",
         method: "POST",
         data: { user: userId },
         complete: function(jqXHR, textStatus) {
            if ( textStatus != "success" ) {
               alert("Unable to assign project:"+jqXHR.responseText);
            } else {
               if ( $("#assign-staff").data("reload") ) {
                  window.location.reload();
               } else {
                  var json = jqXHR.responseJSON;
                  var html = "<a href='/admin/staff_members/"+json.id+"'>"+json.name+"</a>";
                  var ownerEle = $("span.owner-name[data-project='"+projectId+"']");
                  ownerEle.empty();
                  ownerEle.append( $(html) );
                  $("#assign-dimmer").hide();
               }
            }
         }
      });
   });
   $("#unassign-button").on("click", function() {
      var resp = confirm("Are you sure you want to clear the currently assigned staff for this project?");
      if (!resp) {
         return;
      }
      var projectId = $(this).data("project");
      $.ajax({
         url: "/admin/projects/"+projectId+"/unassign",
         method: "POST",
         complete: function(jqXHR, textStatus) {
            if ( textStatus != "success" ) {
               alert("Unable to clear assignment:"+jqXHR.responseText);
            } else {
               window.location.reload();
            }
         }
      });
   });

   var menuHideTimerId=-1;
   var killHideTimeout = function() {
      if (menuHideTimerId == -1) return;
      clearTimeout(menuHideTimerId);
      menuHideTimerId = -1;
   };
   $(".owner").on("mouseover", function() {
      if ( $(this).hasClass("disabled") ) return;
      if ( $(this).closest(".project-card").hasClass("finished") ) return;
      $(".owner-dd").hide();
      var dd = $(this).closest(".project-footer").find(".owner-dd");
      dd.show();
      killHideTimeout();
   });
   $(".owner-dd").on("mouseover", function() {
      $(this).show();
      killHideTimeout();
   });
   $(".owner-dd").on("mouseout", function() {
      var dd = $(this);
      menuHideTimerId = setTimeout(function() {
         dd.fadeOut();
      }, 250);
   });
   $(".owner").on("mouseout", function() {
      if ( $(this).hasClass("disabled") ) return;
      if ( $(this).closest(".project-card").hasClass("finished") ) return;
      var dd = $(this).closest(".project-footer").find(".owner-dd");
      menuHideTimerId = setTimeout(function() {
         dd.fadeOut();
      }, 500);
   });

   var toggleWorkflowButtons = function(enabled) {
      $(".workflow_button.project .admin-button").each( function() {
         if ( enabled ) {
            if ( $(this).hasClass("locked") === false ) {
               $(this).removeClass("disabled");
            }
         } else {
            if ( $(this).hasClass("disabled") === false ) {
               $(this).addClass("disabled");
            }
         }
      });
      $("#duration-minutes").prop('disabled', !enabled);
      if ( enabled ) {
         $(".time-entry.mf-action-button").removeClass("disabled");
      } else {
         $(".time-entry.mf-action-button").addClass("disabled");
      }
   };

   // Reject submit; first require the creation of a problem note-card
   var submitRejection = function( mins ) {
      $.ajax({
         url: window.location.href+"/reject_assignment",
         method: "PUT",
         data: {duration: mins},
         complete: function(jqXHR, textStatus) {
            if ( textStatus == "success" ) {
               window.location.reload();
            } else {
               alert("Unable to reject assignment. Please try again later.");
               toggleWorkflowButtons(true);
            }
         }
      });
   };

   $("#start-assignment-btn").on("click", function() {
      var btn = $(this);
      if ( btn.hasClass("disabled") ) return;
      toggleWorkflowButtons(false);
      $.ajax({
         url: window.location.href+"/start_assignment",
         method: "PUT",
         complete: function(jqXHR, textStatus) {
            if ( textStatus == "success" ) {
               window.location.reload();
            } else {
               alert("Unable to start assignment. Please try again later.");
               toggleWorkflowButtons(true);
            }
         }
      });
   });

   // Duration entry
   //
   var submitFinish = function(mins) {
      $.ajax({
         url: window.location.href+"/finish_assignment",
         method: "POST",
         data: { duration: mins },
         complete: function(jqXHR, textStatus) {
            if ( textStatus != "success" ) {
               alert("Unable to mark assignment as completed:"+jqXHR.responseText);
               toggleWorkflowButtons(true);
               $("#finish-assignment-btn").show();
               $("#reject-button").show();
               $("div.workflow.time-entry").hide();
            } else {
               window.location.reload();
            }
         }
      });
   };
   $("#duration-minutes").keypress(function (evt) {
      if (evt.keyCode === 13) {
         $(".submit.time-entry").click();
         return false;
      }
   });
   $(".cancel.time-entry").on("click", function() {
      $("#finish-assignment-btn").show();
      $("#reject-button").show();
      $("div.workflow.time-entry").hide();
   });

   $(".submit.time-entry").on("click", function() {
      $("p.error").hide();
      var rawMins = $("#duration-minutes").val();
      var mins = parseInt(rawMins, 10);
      if ( !mins && rawMins !== "0" ) {
         $("p.error").show();
         return;
      }
      toggleWorkflowButtons(false);

      if ( $("div.workflow.time-entry").data("rejection") === true ) {
         $("#note-modal .reject-instruct").show();
         $("#problem-select").removeClass("invisible");
         $("#note-modal").data("rejection", true);
         $("#note-modal").data("duration", mins);
         $("#dimmer").show();
         $("#note-modal").show();
         $("#note-modal textarea").val("");
         $("#type-select").val(2);
         $("div.workflow.time-entry").hide();
         $("#finish-assignment-btn").show();
         $("#reject-button").show();
      } else {
         submitFinish(mins);
      }
   });

   // Assigmnent completion button handling
   //
   var showDurationEntry = function() {
      $("#finish-assignment-btn").hide();
      $("#reject-button").hide();
      $("div.workflow.time-entry").show();
      $("p.error").hide();
      $("#duration-minutes").val("");
      $("#duration-minutes").focus();
   };
   $("#finish-assignment-btn").on("click", function() {
      if ( $(this).hasClass("disabled") ) return;
      if ( !$(this).data("duration") ) {
         showDurationEntry();
      } else {
         toggleWorkflowButtons(false);
         submitFinish( 0 );
      }

      $("div.workflow.time-entry").data("rejection", false);
   });

   $('#reject-button').on("click", function() {
      if ( $(this).hasClass("disabled") ) return;
      showDurationEntry();
      $("div.workflow.time-entry").data("rejection", true);
   });

   // Task Note creation
   $("#add-note").on("click", function() {
      $("#dimmer").show();
      $("#note-modal").show();
      $("#note-modal textarea").val("");
      $("#note-modal .reject-instruct").hide();
      $("#note-modal").data("rejection", false);
   });
   $("#cancel-note").on("click", function() {
      $("#dimmer").hide();
      $("#note-modal").hide();
      toggleWorkflowButtons(true);
   });
   $('#create-note').submit(function() {
      $(this).ajaxSubmit({
         complete: function(jqXHR, textStatus) {
            if (textStatus == "success" ) {
               $("#dimmer").hide();
               $("#note-modal").hide();
               $("div.panel.notes .panel_contents").prepend( $(jqXHR.responseJSON.html) );
               if ( $("#note-modal").data("rejection") === true ) {
                  submitRejection( $("#note-modal").data("duration") );
               } else {
                  toggleWorkflowButtons(true);
               }
            } else {
               alert("Unable to create note: "+jqXHR.responseText);
               toggleWorkflowButtons(true);
            }
         }
      });
      return false;
   });
   $("#type-select").on("change", function() {
      var sel = $("#type-select option:selected").text();
      $("#problem-select").removeClass("invisible");
      if (sel.toLowerCase() !== "problem") {
         $("#problem-select").addClass("invisible");
      }
   });

   // Edit Camera / item / OCR settings
   // NOTES: there are two sets of edit / readonly controls.
   //        all have same classes with the exception of one that
   //        differentiates camera vs item
   $(".project.edit-btn").on("click", function() {
      var tgtClass = "camera";
      if ( $(this).hasClass("item")) {
         tgtClass= "item";
      } else if ( $(this).hasClass("ocr")) {
         tgtClass= "ocr";
      } else {
         $("table.project-equipment-setup").hide();
      }
      $(".project.edit-btn."+tgtClass).addClass("hidden");
      $(".project.cancel-btn."+tgtClass).removeClass("hidden");
      $(".project.save-btn."+tgtClass).removeClass("hidden");
      $(".edit-"+tgtClass).removeClass("hidden");
      $(".disp-"+tgtClass).addClass("hidden");
   });

   $(".project.cancel-btn").on("click", function() {
      var tgtClass = "camera";
      if ( $(this).hasClass("item")) {
         tgtClass= "item";
      } else if ( $(this).hasClass("ocr")) {
         tgtClass= "ocr";
      } else {
         $("table.project-equipment-setup").show();
      }
      $(".project.edit-btn."+tgtClass).removeClass("hidden");
      $(".project.cancel-btn."+tgtClass).addClass("hidden");
      $(".project.save-btn."+tgtClass).addClass("hidden");
      $(".edit-"+tgtClass).addClass("hidden");
      $(".disp-"+tgtClass).removeClass("hidden");
   });

   $(".project.save-btn").on("click", function() {
      var tgtClass = "camera";
      if ( $(this).hasClass("item")) {
         tgtClass = "item";
         data = { container_type: $("#container-type-edit").val(),
            category: $("#category-edit").val(), viu_number: $("#viu_number-edit").val(),
            item_condition: $("#condition-edit").val(), condition_note: $("#condition_note-edit").val()
         };
      } else if ( $(this).hasClass("ocr")) {
         tgtClass= "ocr";
         data = {
            ocr_hint_id: $("#ocr-hint-edit").val(), ocr_language_hint: $("#ocr-language-hint-edit").val(),
            ocr_master_files: $("#ocr-master-files-edit").is(':checked')
         };
      } else {
         data =  { camera: true,
            workstation: $("#workstation-edit").val(), capture_resolution: $("#capture_resolution-edit").val(),
            resized_resolution: $("#resized_resolution-edit").val(), resolution_note: $("#resolution_note-edit").val()
         };
      }
      $(".project.cancel-btn."+tgtClass).addClass("hidden");
      $(".project.save-btn."+tgtClass).addClass("hidden");

      $.ajax({
         url: window.location.href+"/settings",
         method: "PUT",
         data: data,
         complete: function(jqXHR, textStatus) {
            $("table.project-equipment-setup").show();
            $(".project.edit-btn."+tgtClass).removeClass("hidden");
            $(".edit-"+tgtClass).addClass("hidden");
            $(".disp-"+tgtClass).removeClass("hidden");
            if ( textStatus != "success" ) {
               alert("Update "+tgtClass+" failed: "+jqXHR.responseJSON.error);
            } else {
               if (tgtClass === "camera") {
                  $("tr.row.row-setup td").html(jqXHR.responseJSON.html );
                  $("#workstation").text( $("#workstation-edit option:selected").text() );
                  $("#capture_resolution").text( data.capture_resolution );
                  $("#resized_resolution").text( data.resized_resolution );
                  $("#resolution_note").text( data.resolution_note );
               } else if ( tgtClass === "ocr") {
                  $("#ocr-hint").text( $("#ocr-hint-edit option:selected").text() );
                  $("#ocr-hint").removeClass("empty");
                  var ocrLang = [];
                  $("#ocr-language-hint").removeClass("empty");
                  $("#ocr-language-hint-edit option:selected").each( function() {
                     ocrLang.push( $(this).text());
                  });
                  if ( ocrLang.length > 0 ) {
                     $("#ocr-language-hint").text( ocrLang.join("+") );
                  } else {
                     $("#ocr-language-hint").text( "EMPTY" );
                     $("#ocr-language-hint").addClass("empty");
                  }
                  if ( $("#ocr-master-files-edit").is(':checked' ) ) {
                     $("#ocr-master-files").text("Yes");
                  } else {
                     $("#ocr-master-files").text("No");
                  }
               } else {
                  $("#viu_number").text( data.viu_number );
                  $("#container-type").text( $("#container-type-edit option:selected").text() );
                  $("#category").text( $("#category-edit option:selected").text() );
                  $("#condition").text( $("#condition-edit option:selected").text() );
                  $("#condition_note").text( data.condition_note  );
               }

               // if requirements met, enable finish and hide note
               if ( jqXHR.responseJSON.enable_finish ) {
                  if ( $("#start-assignment-btn").hasClass("disabled") ) {
                     $("#finish-assignment-btn").removeClass("disabled");
                  }
                  $("div.equipment-note").hide();
               } else {
                  if ($("#finish-assignment-btn").hasClass("disabled") === false ) {
                     $("#finish-assignment-btn").add("disabled");
                  }
               }
            }
         }
      });
   });

   // When Manuscript workflow is selected, display the container type options
   $("#workflow").on("change", function() {
     $("#container-type-row").hide();
     if ( $( "#workflow option:selected").text() === "Manuscript" ) {
       $("#container-type-row").show();
     }
   });

   // Create projects
   $("#show-create-digitization-project").on("click", function() {
      if ( $(this).hasClass("disabled") ) return;
      $("#dimmer").show();
      $("#project-modal").show();
   });
   $("#cancel-project-create").on("click", function() {
      $("#dimmer").hide();
      $("#project-modal").hide();
   });
   $("#ok-project-create").on("click", function() {
      if ( $("#ok-project-create").hasClass("disabled")) return;
      $("#ok-project-create").addClass("disabled");
      $("#cancel-project-create").addClass("disabled");
      var data = { workflow: $("#workflow").val(),
              category: $("#category").val(),
              priority: $("#priority").val(),
              condition: $("#condition").val(),
              notes: $("#condition_notes").val(),
              due: $("#due_on").val()
      };
      if ( $( "#workflow option:selected").text() === "Manuscript" ) {
        data.container_type = $("#container-type").val();
      }
      $.ajax({
         url: window.location.href+"/project",
         method: "POST",
         data: data,
         complete: function(jqXHR, textStatus) {
            $("#ok-project-create").removeClass("disabled");
            $("#cancel-project-create").removeClass("disabled");
            if ( textStatus != "success" ) {
               alert("Unable to create project failed: "+jqXHR.responseText);
            } else {
               alert("A new project has been created");
               $("#dimmer").hide();
               $("#project-modal").hide();
               $("#show-create-digitization-project").hide();
               var id = jqXHR.responseText;
               var projRow = $("tr.row-project");
               var empty = projRow.find("span.empty");
               var projTD = empty.closest("td");
               empty.remove();
               var link = "<a href='/admin/projects/"+id+"'>Project #"+id+"</a>";
               projTD.html(link);
            }
         }
      });
   });
});
