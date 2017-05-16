$(document).ready(function () {

   $('#master_file_unit_id').autocomplete({
       serviceUrl: '/admin/units/autocomplete',
       deferRequestBy: 250,
       showNoSuggestionNotice: true
   });
   $('#mf_metadata_selector').autocomplete({
       serviceUrl: '/admin/'+$('#mf_metadata_selector').data("queryuri")+'/autocomplete',
       deferRequestBy: 250,
       showNoSuggestionNotice: true,
       onSelect: function (suggestion) {
          $('#master_file_metadata_id').val(suggestion.data);
       }
   });

   $('#unit_order_id').autocomplete({
       serviceUrl: '/admin/orders/autocomplete',
       deferRequestBy: 250,
       showNoSuggestionNotice: true
   });
   $('#unit_metadata_selector').autocomplete({
       serviceUrl: '/admin/'+$('#unit_metadata_selector').data("queryuri")+'/autocomplete',
       deferRequestBy: 250,
       showNoSuggestionNotice: true,
       onSelect: function (suggestion) {
          $('#unit_metadata_id').val(suggestion.data);
       }
   });

   $("#unit_metadata_selector").keyup( function() {
      // when the selector is cleared, also clear the hidden
      // input field that holds the ID  of the chosen metadata
      if ( $(this).val().length === 0) {
         $("#unit_metadata_id").val("");
      }
   });

   // Toggle between Sirsi/Xml metadata
   $("#metadata-type-picker").on("change", function() {
      var metadataType = $(this).val();
      $('#unit_metadata_selector').autocomplete().setOptions( {serviceUrl: '/admin/'+metadataType+'/autocomplete'} );
      $("#unit_metadata_selector").val("");
      $('#unit_metadata_id').val("");
   });
   $("#mf-metadata-type-picker").on("change", function() {
      var metadataType = $(this).val();
      $('#mf_metadata_selector').autocomplete().setOptions( {serviceUrl: '/admin/'+metadataType+'/autocomplete'} );
      $("#mf_metadata_selector").val("");
      $("#master_file_metadata_id").val("");
   });
});
