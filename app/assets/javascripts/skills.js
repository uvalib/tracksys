$(function() {
   $("#category").on("change", function() {
      var id = $(this).val();
      $("div.staff-skills").empty();
      $("p.staff").show();
      $("p.staff").removeClass("selected");
      $.getJSON("/admin/staff_skills/staff?skill="+id, function ( data, textStatus, jqXHR ){
         if (textStatus == "success" ) {
            var template = "<p data-id='ID' class='skilled'>NAME</p>";
            $.each(data, function(idx,val) {
               var row = template.replace("ID", val.id).replace("NAME", val.name);
               $("div.staff-skills").append( $(row) );
               $("p.staff[data-id='"+val.id+"']").hide();
            });
         } else {
            alert("Unable to retrieve staff with selected skill. Please try again later");
         }
      });
   });

   $(".scroller").on("click",".skilled, .staff", function() {
      if ( $(this).hasClass("selected") ) {
         $(this).removeClass("selected");
      } else {
         $(this).addClass("selected");
      }
   });

   $("#assign-skill").on("click", function() {
      if ( $("#category").val() === "Select a category" ) {
         alert("Please select a category.");
         return;
      }
      if ( $("p.staff.selected").length === 0) {
         alert("Please select staff members to assign to the current category.");
         return;
      }

      var ids=[];
      $("p.staff.selected").each( function() {
         ids.push( $(this).data("id"));
      });
      $.ajax({
         url: "/admin/staff_skills/add",
         method: "POST",
         data: {ids: ids, category: $("#category").val() },
         complete: function(jqXHR, textStatus) {
            if (textStatus != "success") {
               alert("Unable to assign staff to a category. Please try again later.");
            } else {
               var template = "<p data-id='ID' class='skilled'>NAME</p>";
               $("p.staff.selected").each( function() {
                  var ele = $(this);
                  var row = template.replace("ID", ele.data("id")).replace("NAME", ele.text());
                  $("div.staff-skills").append( $(row) );
               });
               $("p.staff.selected").hide();
               $("p.staff.selected").removeClass("seleted");
            }
         }
      });
   });

   $("#unassign-skill").on("click", function() {
      if ( $("#category").val() === "Select a category" ) {
         alert("Please select a category.");
         return;
      }
      if ( $("p.skilled.selected").length === 0) {
         alert("Please select staff members to un-assign from the current category.");
         return;
      }
   });

});
