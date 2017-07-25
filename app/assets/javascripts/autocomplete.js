$(document).ready(function () {
   $('#unit_order_id').autocomplete({
       serviceUrl: '/admin/orders/autocomplete',
       deferRequestBy: 250,
       showNoSuggestionNotice: true
   });
});
