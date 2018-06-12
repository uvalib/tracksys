$(function() {
  $("#recipient").chosen({
      no_results_text: "Sorry, no matches found",
      width: "100%"
  });

  $(".msg-button.read").on("click", function() {
    var id = $(this).data("msg-id");
    var row = $(this).closest("tr");
    $.ajax({
       url: "/admin/messages/"+id+"/read",
       method: "POST",
       complete: function(jqXHR, textStatus) {
          if (textStatus != "success") {
             alert("Unable to read message: "+jqXHR.responeText);
          } else {
             populateMessage(row, jqXHR.responseJSON);
          }
       }
    });
  });

  var populateMessage = function(row, json) {
    $("#reader-modal .content").empty();
    $("#reader-modal .content").append(json.html);
    $("#dimmer").show();
    $("#reader-modal").show();

    var icon = row.find("td.col.icon .email");
    if (icon.hasClass("opened") === false ) {
      icon.removeClass("closed").addClass("opened");
      var cntEle = $(".message-cnt");
      var cnt = parseInt(cntEle.text(),10);
      $(".message-cnt").text(cnt-1);
    }
  };

  $("#close-reader").on("click", function() {
    $("#dimmer").hide();
    $("#reader-modal").hide();
  });

  $("#compose").on("click", function() {
    $("#recipient").val("");
    $("#subject").val("");
    $("#message").val("");
    $("#compose-err").hide();
    $("#dimmer").show();
    $("#compose-modal").show();
  });

  $("#close-compose").on("click", function() {
    $("#dimmer").hide();
    $("#compose-modal").hide();
  });
  $("#send-message").on("click", function() {
    var data = {
      to: $("#recipient").val(),
      subject: $("#subject").val(),
      message: $("#message").val()
    };
    if ( data.to.length === 0 || data.subject.length === 0 || data.message.length === 0) {
      $("#compose-err").show();
      return;
    }
    $("#compose-err").hide();
    // $("#dimmer").hide();
    // $("#reader-modal").hide();
  });

  $(".message-panel .msg-button.delete").on("click", function() {
    resp = confirm("Delete this message?");
    if (!resp) return;

    var id = $(this).data("msg-id");
    $.ajax({
       url: "/admin/messages/"+id,
       method: "DELETE",
       complete: function(jqXHR, textStatus) {
          if (textStatus != "success") {
             alert("Unable to delete message: "+jqXHR.responeText);
          } else {
             window.location.reload();
          }
       }
    });
  });
});
