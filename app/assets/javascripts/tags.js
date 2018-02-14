$(function() {
   $("#tag-finder").chosen({
       no_results_text: "Sorry, no matches found",
       width: "250px",
       placeholder_text_multiple: "Select existing tags"
   });

   $("#start-add-tag").on("click", function() {
      $(".add-tags").show();
      $("#add-done").show();
      $("#start-add-tag").hide();
   });

   $("#add-done").on("click", function() {
      $(".add-tags").hide();
      $("#add-done").hide();
      $("#start-add-tag").show();
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
               var tpl = '<span class="tag">TG<span data-id="ID" title="Delete tag" class="del-tag">X</span></span>';
               $.each(jqXHR.responseJSON, function(idx, val) {
                  var h = tpl.replace("TG", val.tag);
                  h = h.replace("ID", val.id);
                  $("div.mf-tag-list").append( $(h) );
               });
            }
         }
      });
   });

   $("div.mf-tag-list").on("click", ".del-tag", function() {
      var id = $(this).data("id");
      var tagUI = $(this).closest("span.tag");
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
               var html = '<span class="tag">';
               html += tag;
               html += '<span data-id="'+jqXHR.responseText;
               html += '" title="Delete tag" class="del-tag">X</span></span>';
               $("div.mf-tag-list").append( $(html) );
               $("#new-tag").val("");
            }
         }
      });
   });
});
