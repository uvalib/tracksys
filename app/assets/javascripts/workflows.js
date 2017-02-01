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

   // Edit Camera
   $("#edit-camera").on("click", function() {
      $("#edit-camera").addClass("hidden");
      $("#cancel-camera").removeClass("hidden");
      $("#save-camera").removeClass("hidden");
      $("input.camera").removeClass("hidden");
      $("span.camera").addClass("hidden");
   });
   $("#cancel-camera").on("click", function() {
      $("#edit-camera").removeClass("hidden");
      $("#cancel-camera").addClass("hidden");
      $("#save-camera").addClass("hidden");
      $("input.camera").addClass("hidden");
      $("span.camera").removeClass("hidden");
   });
   $("#save-camera").on("click", function() {
      $("#cancel-camera").addClass("hidden");
      $("#save-camera").addClass("hidden");

      var c = $("#camera-edit").val();
      var l = $("#lens-edit").val();
      var r = $("#resolution-edit").val();
      $.ajax({
         url: window.location.href+"/settings",
         method: "PUT",
         data: { camera: c, lens: l, resolution: r },
         complete: function(jqXHR, textStatus) {
            $("#edit-camera").removeClass("hidden");
            $("input.camera").addClass("hidden");
            $("span.camera").removeClass("hidden");
            if ( textStatus != "success" ) {
               alert("Unable to update equipment: "+jqXHR.responseText);
            } else {
               $("#camera").text(c);
               $("#lens").text(l);
               $("#resolution").text(r);
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
