$(function() {
   $("#tag-finder").chosen({
       no_results_text: "Sorry, no matches found",
       width: "250px"
   });

   $("#add-tag").on("click", function() {
      $(".add-tags").show();
      $("#add-done").show();
      $("#add-tag").hide();
   });

   $("#add-done").on("click", function() {
      $(".add-tags").hide();
      $("#add-done").hide();
      $("#add-tag").show();
   });
});
