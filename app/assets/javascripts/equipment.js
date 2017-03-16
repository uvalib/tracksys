$(function() {

   $(".sel-cb").on("click", function() {
      // dont all select of equipment that has already been assigned
      var tr = $(this).closest("tr");
      if (tr.hasClass("assigned")) {
         $(this).prop('checked', false);
         return;
      }

      // If a piece of equipment is not active, don't allow it to be selected
      if (tr.find(".inactive").length > 0) {
         $(this).prop('checked', false);
         return;
      }

      // Allow multiple selects on lenses
      var equipType = $(this).closest("div.panel.equipment").data("type");
      if (equipType != "Lens") {
         // grab current checke state of CB checked, then clear
         // all other CB in this table. Finally, set this CB.
         // This is to ensure only 1 of each equipment type can be checked
         var checked = $(this).is(":checked");
         $(this).closest("table").find(".sel-cb").prop('checked', false);
         $(this).prop('checked', checked);
      }
   });

   var displayNewConfiguration = function(equipList) {
      $("table.setup").empty();
      var rows = "";
      $.each(equipList, function(idx,val) {
         rows += "<tr>";
         rows += "<td>"+val.type+"</td>";
         rows += "<td>"+val.name+"</td>";
         rows += "<td>"+val.serial_number+"</td>";
         rows += "</tr>";
      });
      $( rows ).prependTo( $("table.setup") );
   };

   $(".workstation.add").on("click", function() {
      var name = prompt("Enter a name for the new workstation");
      if ( name.length === 0) return;

      $.ajax({
         url: "/admin/workstations",
         method: "POST",
         data: {name: name},
         complete: function(jqXHR, textStatus) {
            if (textStatus != "success") {
               alert("Unable to create new workstation. Please try again later");
            } else {
               $( jqXHR.responseJSON.html ).prependTo( $("table.workstations") );
               $("tr.workstation").removeClass("selected");
               $("tr.workstation[data-id='"+jqXHR.responseJSON.id+"']").addClass("selected");
               displayNewConfiguration([]);
               $(".assign-equipment").removeClass("disabled");
               $(".clear-equipment").removeClass("disabled");
            }
         }
      });
   });

   $("table.workstations").on("click", ".equipment-status",  function(e) {
      e.stopPropagation();
      e.preventDefault();

      var statusIcon = $(this);
      var active = statusIcon.hasClass("active");
      var tr = $(this).closest("tr");
      $.ajax({
         url: "/admin/workstations/"+tr.data("id"),
         method: "PUT",
         data: {active: !active},
         complete: function(jqXHR, textStatus) {
            if (textStatus != "success") {
               alert("Unable to change workstation activation status:\n\n"+jqXHR.responseText);
            } else {
               if ( active ) {
                  statusIcon.removeClass("active");
                  statusIcon.addClass("inactive");
               } else {
                  statusIcon.addClass("active");
                  statusIcon.removeClass("inactive");
               }
            }
         }
      });
   });

   $("table.workstations").on("click", ".trash.ts-icon",  function(e) {
      var resp = confirm("Are you sure you want to retire this workstation?");
      if ( !resp ) return;
      e.stopPropagation();
      e.preventDefault();

      var tr = $(this).closest("tr");
      $.ajax({
         url: "/admin/workstations/"+tr.data("id"),
         method: "DELETE",
         complete: function(jqXHR, textStatus) {
            if (textStatus != "success") {
               alert("Unable to retire workstation:\n\n"+jqXHR.responseText);
            } else {
               tr.remove();
               displayNewConfiguration([]);
               $(".assign-equipment").removeClass("disabled");
               $(".assign-equipment").addClass("disabled");
               $(".clear-equipment").removeClass("disabled");
               $(".clear-equipment").addClass("disabled");
            }
         }
      });
   });

   $("table.workstations").on("click", "tr.workstation",  function() {
      $("tr.workstation").removeClass("selected");
      $(this).addClass("selected");
      var equipList = $(this).data("setup");
      displayNewConfiguration(equipList);
      $(".sel-cb").prop('checked', false);
      $.each(equipList, function(idx,val) {
         $(".sel-cb[data-id='"+val.id+"']").prop('checked', true);
      });
      $(".assign-equipment").removeClass("disabled");
      $(".clear-equipment").removeClass("disabled");
   });

   var styleUsedEquipment = function(wsId) {
      // first, find any other equipment that was previously assigned
      // to this workstation and remove styling
      var prior = $("table.equipment tr[data-workstation='"+wsId+"']");
      $("table.equipment tr").each(function() {
         currWsId = $(this).data("workstation");
         if (currWsId == wsId ) {
            $(this).removeClass("assigned");
            $(this).removeData("workstation");
            $(this).find(".assigned-ws").remove();
         }
      });

      $(".panel.equipment .sel-cb:checked").each( function() {
         var tr = $(this).closest("tr");
         tr.addClass("assigned");
         tr.data("workstation", wsId);
         var wsName=$("tr.workstation[data-id='"+wsId+"'] .name").text();
         var html = "<span class='assigned-ws'>"+wsName+"</span>";
         tr.find(".name").after( $(html) );
      });
   };

   $(".clear-equipment").on("click", function(){
      if ( $(this).hasClass("disabled") ) return;
      var wsId = $("tr.workstation.selected").data("id");
      var btn = $(this);
      btn.addClass("disabled");
      var setup = $("table.setup");
      $.ajax({
         url: "/admin/workstations/"+wsId+"/equipment",
         method: "DELETE",
         complete: function(jqXHR, textStatus) {
            btn.removeClass("disabled");
            if (textStatus != "success") {
               alert("Unable to clear setup:\n\n"+jqXHR.responseText);
            } else {
               $("table.setup").empty();
               var prior = $("table.equipment tr[data-workstation='"+wsId+"']");
               prior.removeClass("assigned");
               prior.removeData("workstation");
               prior.find(".assigned-ws").remove();
               $("tr.workstation.selected .equipment-status").removeClass("active").removeClass("inactive").addClass("inactive");
               $("tr.workstation.selected").data("setup", []);
            }
         }
      });
   });

   $(".assign-equipment").on("click", function(){
      if ( $(this).hasClass("disabled") ) return;

      var scanner = false;
      var ids = [];
      $(".panel.equipment .sel-cb:checked").each( function() {
         var type = $(this).closest(".panel.equipment").data("type");
         if (type === "Scanner") {
            scanner = true;
         }
         ids.push( $(this).data("id") );
      });
      if (scanner && ids.length > 1) {
         alert("A workstation can only have a camera assembly or a scanner, not both");
         return;
      }
      if (scanner === false && ids.length < 3) {
         alert("Incomplete camera assembly specified");
         return;
      }

      var wsId = $("tr.workstation.selected").data("id");
      var data = {workstation: wsId, equipment: ids, camera: !scanner};
      var btn = $(this);
      btn.addClass("disabled");
      var setup = $("table.setup");
      $.ajax({
         url: "/admin/equipment/assign",
         method: "POST",
         data: data,
         complete: function(jqXHR, textStatus) {
            btn.removeClass("disabled");
            if (textStatus != "success") {
               alert("Unable to assign equipment:\n\n"+jqXHR.responseText);
            } else {
               displayNewConfiguration(jqXHR.responseJSON);
               styleUsedEquipment(wsId);
               $("tr.workstation.selected").data("setup", jqXHR.responseJSON);
            }
         }
      });
   });

   var showEquipmentModal = function(button, mode) {
      $("#dimmer").show();
      var modal = $("#equipment-edit");
      var equipType = button.closest("div.panel.equipment").data("type");
      modal.show();
      modal.data("mode", mode);
      modal.data("type", equipType );
      if ( mode === "add" ) {
         modal.find("h1").text("Add Equipment");
         modal.find("input").val("");
         modal.removeData("id");
      } else {
         modal.find("h1").text("Edit Equipment");
         var row = button.closest("tr");
         modal.find("input.name").val( row.find("span.name").text() );
         modal.find("input.serial").val( row.find("span.serial").text()  );
         modal.data("id", row.data("id"));
      }
      modal.show();
      modal.find("input.name").focus();
   };

   $("div.panel.equipment").on("click", ".edit.ts-icon",  function() {
      showEquipmentModal( $(this), "update");
   });

   $("div.panel.equipment").on("click", ".trash.ts-icon",  function() {
      var resp = confirm("Are you sure you want to retire this equipment?");
      if ( !resp ) return;
      var tr = $(this).closest("tr");
      $.ajax({
         url: "/admin/equipment/"+tr.data("id"),
         method: "DELETE",
         complete: function(jqXHR, textStatus) {
            if (textStatus != "success") {
               alert("Unable to retire equipment:\n\n"+jqXHR.responseText);
            } else {
               tr.remove();
            }
         }
      });
   });

   $(".equipment.add").on("click", function() {
      showEquipmentModal( $(this), "add");
   });

   $(".equipment.cancel").on("click", function() {
      $("#dimmer").hide();
      $("#equipment-edit").hide();
   });

   $(".equipment.save").on("click", function() {
      var modal = $("#equipment-edit");
      var type = modal.data("type");
      var data = {
         type: type,
         name: modal.find("input.name").val(),
         serial: modal.find("input.serial").val()};
      var url =  "/admin/equipment";
      var method = "POST";
      if ( modal.data("mode") === "update") {
         url =  "/admin/equipment/"+modal.data("id");
         method = "PUT";
      }

      $.ajax({
         url: url,
         method: method,
         data: data,
         complete: function(jqXHR, textStatus) {
            if (textStatus != "success") {
               alert("Unable to create new equipment:\n\n"+jqXHR.responseText);
            } else {
               if ( modal.data("mode") === "update") {
                  var equipRow = $("tr[data-id='"+modal.data("id")+"']");
                  equipRow.find("span.name").text( modal.find(".name").val() );
                  equipRow.find("span.serial").text( modal.find(".serial").val() );
               } else {
                  $(".panel.equipment[data-type='"+type+"'] table.equipment").replaceWith( $(jqXHR.responseJSON.html) );
               }
               $("#dimmer").hide();
               $("#equipment-edit").hide();
            }
         }
      });
   });

   $("div.panel.equipment").on("click", ".equipment-status",  function(e) {
      var statusIcon = $(this);
      var active = !statusIcon.hasClass("active");
      var tr = $(this).closest("tr");
      var workstation = tr.data("workstation");
      $.ajax({
         url: "/admin/equipment/"+tr.data("id"),
         method: "PUT",
         data: {active: active},
         complete: function(jqXHR, textStatus) {
            if (textStatus != "success") {
               alert("Unable to update equipment:\n\n"+jqXHR.responseText);
            } else {
               if ( active ) {
                  statusIcon.addClass("active");
                  statusIcon.removeClass("inactive");
               } else {
                  statusIcon.removeClass("active");
                  statusIcon.addClass("inactive");
                  if ( workstation ) {
                     var wsRow = $("tr.workstation[data-id='"+workstation+"']");
                     var st = wsRow.find(".equipment-status");
                     if (st.hasClass("inactive") === false ) {
                        st.removeClass("active");
                        st.addClass("inactive");
                     }
                  }
               }
            }
         }
      });
   });
});
