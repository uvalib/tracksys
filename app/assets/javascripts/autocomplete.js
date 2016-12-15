$(document).ready(function () {
   $('#unit_order_id').autocomplete({
       serviceUrl: '/admin/orders/autocomplete',
       deferRequestBy: 250,
       showNoSuggestionNotice: true
   });
   $('#unit_metadata_id').autocomplete({
       serviceUrl: '/admin/'+$('#unit_metadata_id').data("queryuri")+'/autocomplete',
       deferRequestBy: 250,
       showNoSuggestionNotice: true
   });

   // Toggle between Sirsi/Xml metadata
   $("#metadata-type-picker").on("change", function() {
      var metadataType = $(this).val();
      $('#unit_metadata_id').autocomplete().setOptions( {serviceUrl: '/admin/'+metadataType+'/autocomplete'} );
      $("#unit_metadata_id").val("");
   });
});
