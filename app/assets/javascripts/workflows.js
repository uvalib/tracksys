$(function() {
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

   var menuHideTimerId=-1;
   var killHideTimeout = function() {
      if (menuHideTimerId == -1) return;
      clearTimeout(menuHideTimerId);
      menuHideTimerId = -1;
   };
   $(".owner").on("mouseover", function() {
      if ( $(this).hasClass("disabled") ) return;
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
   $(".cancel.time-entry").on("click", function() {
      $("#finish-assignment-btn").show();
      $("#reject-button").show();
      $("div.workflow.time-entry").hide();
   });

   $(".submit.time-entry").on("click", function() {
      $("p.error").hide();
      var mins = parseInt($("#duration-minutes").val(), 10);
      if ( !mins && mins !== "0" ) {
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
         // Just submit the duration and step finish
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
      showDurationEntry();
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

   // Edit Camera / item
   // NOTES: there are two sets of edit / readonly controls.
   //        all have same classes with the exception of one that
   //        differentiates camera vs item
   $(".project.edit-btn").on("click", function() {
      var tgtClass = "camera";
      if ( $(this).hasClass("item")) {
         tgtClass= "item";
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
         data = {condition: $("#condition-edit").val(), viu_number: $("#viu_number-edit").val() };
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
               alert("Update "+tgtClass+" failed: "+jqXHR.responseText);
            } else {
               if (tgtClass === "camera") {
                  $("tr.row.row-setup td").html(jqXHR.responseJSON.html );
                  $("#workstation").text( $("#workstation-edit option:selected").text() );
                  $("#capture_resolution").text( data.capture_resolution );
                  $("#resized_resolution").text( data.resized_resolution );
                  $("#resolution_note").text( data.resolution_note );
                  $("#finish-assignment-btn").removeClass("disabled");
                  $("div.equipment-note").hide();
               } else {
                  $("#viu_number").text( data.viu_number );
                  $("#condition").text( $("#condition-edit option:selected").text() );
               }
            }
         }
      });
   });

   // Create projects
   $("#show-create-digitization-project").on("click", function() {
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
      $.ajax({
         url: window.location.href+"/project",
         method: "POST",
         data: { workflow: $("#workflow").val(),
                 category: $("#category").val(),
                 priority: $("#priority").val(),
                 condition: $("#condition").val(),
                 notes: $("#condition_notes").val(),
                 due: $("#due_on").val()
         },
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
            }
         }
      });
   });
});
