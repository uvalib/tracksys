$(function() {
   // Create projects
   $("#show-create-digitization-project").on("click", function() {
      if ( $(this).hasClass("disabled") ) return;
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
      var data = { workflow: $("#workflow").val(),
              category: $("#category").val(),
              priority: $("#priority").val(),
              condition: $("#item_condition").val(),
              notes: $("#condition_notes").val(),
              due: $("#due_on").val()
      };
      if ( $( "#workflow option:selected").text() === "Manuscript" ) {
        data.container_type = $("#container-type").val();
      }
      $.ajax({
         url: window.location.href+"/project",
         method: "POST",
         data: data,
         complete: function(jqXHR, textStatus) {
            $("#ok-project-create").removeClass("disabled");
            $("#cancel-project-create").removeClass("disabled");
            if ( textStatus != "success" ) {
               alert("Unable to create project failed: "+jqXHR.responseText);
            } else {
               window.location.reload();
            }
         }
      });
   });

})