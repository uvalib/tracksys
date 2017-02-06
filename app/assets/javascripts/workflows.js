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

   // Task Note creation
   $("#add-note").on("click", function() {
      $("#dimmer").show();
      $("#note-modal").show();
   });
   $("#cancel-note").on("click", function() {
      $("#dimmer").hide();
      $("#note-modal").hide();
   });
   $('#create-note').submit(function() {
      $(this).ajaxSubmit({
         complete: function(jqXHR, textStatus) {
            if (textStatus == "success" ) {
               $("#dimmer").hide();
               $("#note-modal").hide();
               // TODO
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
      if (sel !== "problem") {
         $("#problem-select").addClass("invisible");
      }
   });


   // Edit Camera / condition
   // NOTES: there are two sets of edit / readonly controls.
   //        all have same classes with the exception of one that
   //        differentiates camera vs condition
   $(".task.edit-btn").on("click", function() {
      var tgtClass = "camera";
      if ( $(this).hasClass("condition")) {
         tgtClass= "condition";
      }
      $(".task.edit-btn."+tgtClass).addClass("hidden");
      $(".task.cancel-btn."+tgtClass).removeClass("hidden");
      $(".task.save-btn."+tgtClass).removeClass("hidden");
      $(".edit-"+tgtClass).removeClass("hidden");
      $(".disp-"+tgtClass).addClass("hidden");
   });

   $(".task.cancel-btn").on("click", function() {
      var tgtClass = "camera";
      if ( $(this).hasClass("condition")) {
         tgtClass= "condition";
      }
      $(".task.edit-btn."+tgtClass).removeClass("hidden");
      $(".task.cancel-btn."+tgtClass).addClass("hidden");
      $(".task.save-btn."+tgtClass).addClass("hidden");
      $(".edit-"+tgtClass).addClass("hidden");
      $(".disp-"+tgtClass).removeClass("hidden");
   });

   $(".task.save-btn").on("click", function() {
      var tgtClass = "camera";
      if ( $(this).hasClass("condition")) {
         tgtClass = "condition";
         data = {condition: $("#condition-edit").val() };
      } else {
         data =  { camera: $("#camera-edit").val(), lens: $("#lens-edit").val(), resolution: $("#resolution-edit").val() };
      }
      $(".task.cancel-btn."+tgtClass).addClass("hidden");
      $(".task.save-btn."+tgtClass).addClass("hidden");

      $.ajax({
         url: window.location.href+"/settings",
         method: "PUT",
         data: data,
         complete: function(jqXHR, textStatus) {
            $(".task.edit-btn."+tgtClass).removeClass("hidden");
            $(".edit-"+tgtClass).addClass("hidden");
            $(".disp-"+tgtClass).removeClass("hidden");
            if ( textStatus != "success" ) {
               alert("Update "+tgtClass+" failed: "+jqXHR.responseText);
            } else {
               if (tgtClass === "camera") {
                  $("#camera").text( data.camera );
                  $("#lens").text( data.lens );
                  $("#resolution").text( data.resolution );
               } else {
                  $("#condition").text( $("#condition-edit option:selected").text() );
               }
            }
         }
      });
   });

   // Create tasks
   $("#show-create-digitization-task").on("click", function() {
      $("#dimmer").show();
      $("#task-modal").show();
   });
   $("#cancel-task-create").on("click", function() {
      $("#dimmer").hide();
      $("#task-modal").hide();
   });
   $("#ok-task-create").on("click", function() {
      if ( $("#ok-task-create").hasClass("disabled")) return;
      $("#ok-task-create").addClass("disabled");
      $("#cancel-task-create").addClass("disabled");
      $.ajax({
         url: window.location.href+"/task",
         method: "POST",
         data: { workflow: $("#workflow").val(),
                 category: $("#category").val(),
                 priority: $("#priority").val(),
                 due: $("#due_on").val()
         },
         complete: function(jqXHR, textStatus) {
            $("#ok-task-create").removeClass("disabled");
            $("#cancel-task-create").removeClass("disabled");
            if ( textStatus != "success" ) {
               alert("Unable to create task failed: "+jqXHR.responseText);
            } else {
               alert("A new task has been created");
               $("#dimmer").hide();
               $("#task-modal").hide();
               $("#show-create-digitization-task").hide();
            }
         }
      });
   });
});
