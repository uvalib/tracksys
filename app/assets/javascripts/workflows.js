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

   });
});
