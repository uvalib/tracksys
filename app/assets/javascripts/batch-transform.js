$(document).ready(function () {
  $("#global-transform").on("click", function() {
    $("#transform-modal").show();
    $("#dimmer").show();
  });

  $("#unit-xml-transform").on("click", function() {
    $("#transform-modal").show();
    $("#dimmer").show();
  });

  $("#close-transform").on("click", function() {
    $("#transform-modal").hide();
    $("#dimmer").hide();
  });

  $('#global-transform-form').submit(function() {
      $(this).ajaxSubmit({
         complete: function(jqXHR, textStatus) {
            if (textStatus == "success" ) {
              $("#transform-modal").hide();
              $("#dimmer").hide();
              alert("Transform submitted. Check the Job Status page for progress")
            } else {
               alert("Transform failed: "+jqXHR.responseText);
            }
         }
      });
      return false;
   });
});