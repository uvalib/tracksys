$(function() {
   /* EDIT WORKFLOWS */
   $(".step-toolbar.up").on("click", function() {

   });

   $(".step-toolbar.down").on("click", function() {

   });

   $(".step-toolbar.edit").on("click", function() {

   });

   $(".step-toolbar.trash").on("click", function() {

   });

   $(".workflow_button.project").on("click", function() {
      var btn = $(this).find(':submit');
      setTimeout(function() {
         btn.attr("disabled", true);
         btn.addClass("disabled");
      }, 50);
   });

   $("#assign-to").chosen({
       no_results_text: "Sorry, no matches found",
       width: "100%"
   });
   $(".assign-menu").on("click", function() {
      $("#assign-staff").data("project", $(this).data("project"));
      $("#assign-staff").show();
      var pos = $(this).offset();
      $("#assign-staff").css({top: pos.top, left: pos.left});
      $(".owner-dd").hide();
   });
   $("#cancel-assign").on("click", function() {
      $("#assign-staff").hide();
   });
   $("#ok-assign").on("click", function() {
      alert($("#assign-staff").data("project"));
      $("#assign-staff").hide();
   });

   $(".owner").on("mouseover", function() {
      var dd = $(this).closest(".project-footer").find(".owner-dd");
      dd.show();
   });
   $(".owner-dd").on("mouseover", function() {
      $(this).show();
   });
   $(".owner-dd").on("mouseout", function() {
      $(this).hide();
   });
   $(".owner").on("mouseout", function() {
      var dd = $(this).closest(".project-footer").find(".owner-dd");
      dd.hide();
   });

   // Reject submit; first require the creation of a problem note-card
   var submitRejection = function() {
      $.ajax({
         url: window.location.href+"/reject_assignment",
         method: "PUT",
         complete: function(jqXHR, textStatus) {
            if ( textStatus == "success" ) {
               window.location.reload();
            } else {
               alert("Unable to reject assignment. Please try again later.");
            }
         }
      });
   };
   $('#reject-button').on("click", function() {
      if ( $(this).find(".reject").hasClass("disabled") ) return;
      $("#note-modal .reject-instruct").show();
      $("#note-modal").data("rejection", true);
      $("#dimmer").show();
      $("#note-modal").show();
      $("#note-modal textarea").val("");
      $("#type-select").val(2);
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
      var btn = $("#reject-button").find(":submit");
      btn.attr("disabled", false);
      btn.removeClass("disabled");
   });
   $('#create-note').submit(function() {
      $(this).ajaxSubmit({
         complete: function(jqXHR, textStatus) {
            if (textStatus == "success" ) {
               $("#dimmer").hide();
               $("#note-modal").hide();
               $("div.panel.notes .panel_contents").prepend( $(jqXHR.responseJSON.html) );
               if ( $("#note-modal").data("rejection") === true ) {
                  submitRejection();
               }
            } else {
               alert("Unable to create note: "+jqXHR.responseText);
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

   // Edit Camera / condition
   // NOTES: there are two sets of edit / readonly controls.
   //        all have same classes with the exception of one that
   //        differentiates camera vs condition
   $(".project.edit-btn").on("click", function() {
      var tgtClass = "camera";
      if ( $(this).hasClass("condition")) {
         tgtClass= "condition";
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
      if ( $(this).hasClass("condition")) {
         tgtClass= "condition";
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
      if ( $(this).hasClass("condition")) {
         tgtClass = "condition";
         data = {condition: $("#condition-edit").val() };
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
               } else {
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
