$(function() {
   $(".assign-equipment").on("click", function(){
      if ( $(this).hasClass("disabled") ) return;
      var picks = {bodies: null, backs: null, lenses: null, scanners: null};
      var ids = [];
      var failed = false;
      var camera = false;
      for (var className in picks) {
         if ( !picks.hasOwnProperty(className)) continue;
         $("table."+className+" .sel-cb:checked").each( function(idx, ele) {
            if ( picks[className] ) {
               alert("Only one of each type of equipment may be assigned to a workstation");
               failed = true;
               return false;
            } else {
               picks[className] = $(this).data("id");
               ids.push($(this).data("id"));
               if ( className != "scanners") {
                  camera = true;
               } else {
                  if (camera) {
                     alert("A workstation can only have a camera assembly or a scanner, not both");
                     failed = true;
                     return false;
                  }
               }
            }
         });
      }
      if ( failed ) {
         return;
      }

      var data = {workstation: $(this).data("workstation"), equipment: ids, camera: camera};
      var btn = $(this);
      btn.addClass("disabled");
      var setup = btn.closest(".ws-card").find(".setup");
      $.ajax({
         url: "/admin/equipment/assign",
         method: "POST",
         data: data,
         complete: function(jqXHR, textStatus) {
            btn.removeClass("disabled");
            if (textStatus != "success") {
               alert("Unable to assign equipment. Please try again later");
            } else {
               setup.empty();
               $( jqXHR.responseJSON.html ).prependTo(setup);
            }
         }
      });
   });
});
