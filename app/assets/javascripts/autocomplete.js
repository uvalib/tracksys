$(document).ready(function () {
   $('#unit_order_id').autocomplete({
       serviceUrl: '/admin/orders/autocomplete'
   });
   $('#unit_metadata_id').autocomplete({
       serviceUrl: '/admin/'+$('#unit_metadata_id').data("queryuri")+'/autocomplete'
   });

   // Toggle between Sirsi/Xml metadata
   $("#metadata-type-picker").on("change", function() {
      var metadataType = $(this).val();
      $('#autocomplete').autocomplete().setOptions( {serviceUrl: '/admin/'+metadataType+'/autocomplete'} );
      $("#unit_metadata_id").val("");
   });
});
