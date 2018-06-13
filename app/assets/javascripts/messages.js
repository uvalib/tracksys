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

  var reduceMessageCount = function() {
    var cntEle = $(".message-cnt");
    var cnt = parseInt(cntEle.text(),10);
    $(".message-cnt").text(cnt-1);
  };

  var populateMessage = function(row, json) {
    $("#reader-modal .content").empty();
    $("#reader-modal .content").append(json.html);
    $("#dimmer").show();
    $("#reader-modal").show();

    var icon = row.find("td.col.icon .email");
    if (icon.hasClass("opened") === false ) {
      icon.removeClass("closed").addClass("opened");
      reduceMessageCount();
    }
  };

  $("#close-reader").on("click", function() {
    $("#dimmer").hide();
    $("#reader-modal").hide();
  });

  var clearFields = function() {
    $("#recipient").val("").trigger('chosen:updated');
    $("#subject").val("");
    $("#message").val("");
  };

  $("#compose").on("click", function() {
    clearFields();
    $("#send-message").removeClass("disabled");
    $("#compose-err").hide();
    $("#sending").hide();
    $("#dimmer").show();
    $("#compose-modal").show();
  });

  $("#close-compose").on("click", function() {
    $("#dimmer").hide();
    $("#compose-modal").hide();
  });
  $("#send-message").on("click", function() {
    if ( $(this).hasClass("disabled") ) return;

    var data = {
      to: $("#recipient").val(),
      subject: $("#subject").val(),
      message: $("#message").val()
    };
    if ( data.to.length === 0 || data.subject.length === 0 || data.message.length === 0) {
      $("#compose-err").show();
      $("#sending").hide();
      return;
    }

    $("#sending").text("Sending message...");
    $("#sending").show();
    $("#send-message").addClass("disabled");
    $("#compose-err").hide();
    $.ajax({
       url: "/admin/messages/",
       method: "POST",
       data: data,
       complete: function(jqXHR, textStatus) {
          if (textStatus != "success") {
             alert("Unable to send message: "+jqXHR.responeText);
          } else {
             $("#sending").text("Your message has been sent");
             clearFields();
          }
          $("#send-message").removeClass("disabled");
       }
    });
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

  $("#close-popup-reader").on("click", function() {
    var id = $("#message-body").data("msg-id");
    $.ajax({
       url: "/admin/messages/"+id+"/read",
       method: "POST",
       complete: function(jqXHR, textStatus) {
         $("#msg-reader-dimmer").hide();
         reduceMessageCount();
       }
     });
  });
});
