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

   $("#source-unit").chosen().change( function() {
      var selectedUnit = $(this).val();
      $("#source-masterfile-list").data("page", "1");
         $.getJSON("/admin/units/"+selectedUnit+"/master_files?page=1", function ( data, textStatus, jqXHR ) {

         });
   } );
});
