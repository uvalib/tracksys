$(function() {
   $(".assign-equipment").on("click", function(){
      var picks = {bodies: [], backs: [], lenses: [], scanners: []};
      for (var className in picks) {
         if ( !picks.hasOwnProperty(className)) continue;
         $("table."+className+" .sel-cb").each( function(idx, ele) {

         });
      }
   });
});
