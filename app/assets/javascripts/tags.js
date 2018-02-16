$(function() {
   $("#tag-finder").chosen({
       no_results_text: "Sorry, no matches found",
       width: "250px",
       placeholder_text_multiple: "Select existing tags"
   });

   var enableTagControls = function(enabled) {
      if (enabled === false) {
         $(".add-tags input").attr("disabled","disabled");
         $(".add-tags select").attr("disabled","disabled").trigger("chosen:updated");
         $(".add-tags .mf-action-button").addClass("disabled");
      } else {
         $(".add-tags input").removeAttr("disabled");
         $(".add-tags select").removeAttr("disabled").trigger("chosen:updated");
         $(".add-tags .mf-action-button").removeClass("disabled");
      }
   };

   $("#add-tag").on("click", function() {
      if ( $(this).hasClass("disabled")) return;
      var sels = $("#tag-finder").val();
      if (sels.length == 0) return;

      enableTagControls(false);
      $.ajax({
         url: window.location.href+"/add_tags",
         method: "POST",
         data: {tags: sels},
         complete: function(jqXHR, textStatus) {
            enableTagControls(true);
            if (textStatus != "success") {
               alert("Add tags failed: "+jqXHR.responseText);
            } else {
               $("li.search-choice").remove();
               var sels = $("#tag-finder").val("").trigger("chosen:updated");
               $("div.mf-tag-list").append( $(jqXHR.responseJSON.html) );
            }
         }
      });
   });

   $("div.mf-tag-list").on("click", ".del-tag", function() {
      var id = $(this).data("id");
      var tagUI = $(this).closest(".tag");
      $.ajax({
         url: window.location.href+"/remove_tag",
         method: "POST",
         data: {tag: id},
         complete: function(jqXHR, textStatus) {
            if (textStatus != "success") {
               alert("Remove tag failed: "+jqXHR.responseText);
            } else {
               tagUI.remove();
            }
         }
      });
   });

   $("#add-new-tag").on("click", function() {
      if ( $(this).hasClass("disabled")) return;
      var tag = $("#new-tag").val();
      if (tag.length == 0) return;
      if (tag.length > 255 ) {
         alert("Tags are limited to 255 characters. This one has "+tag.length+".");
         return;
      }

      enableTagControls(false);
      $.ajax({
         url: window.location.href+"/add_new_tag",
         method: "POST",
         data: {tag: tag},
         complete: function(jqXHR, textStatus) {
            enableTagControls(true);
            if (textStatus != "success") {
               alert("Add tag failed: "+jqXHR.responseText);
            } else {
               $("div.mf-tag-list").append( $(jqXHR.responseJSON.html) );
               $("#new-tag").val("");
            }
         }
      });
   });
});
