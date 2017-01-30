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
