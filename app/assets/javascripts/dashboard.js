$(function () {
  $(".close-published-popup").on("click", function () {
    $(".published.modal").hide();
    $("#dimmer").hide();
  });
  $("#view-virgo-published").on("click", function () {
    $("#virgo-published").show();
    $("#as-published").hide();
    $("#dimmer").show();
  });
  $("#view-as-published").on("click", function () {
    $("#as-published").show();
    $("#virgo-published").hide();
    $("#dimmer").show();
  });
});