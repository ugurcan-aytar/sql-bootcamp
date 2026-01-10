function CopyToClipboard(containerid) {
  if (document.selection) {
    var range = document.body.createTextRange();
    range.moveToElementText(document.getElementById(containerid));
    range.select().createTextRange();
    document.execCommand("copy");
  } else if (window.getSelection) {
    var range = document.createRange();
    range.selectNode(document.getElementById(containerid));
    window.getSelection().addRange(range);
    document.execCommand("copy");
  }

  // Show notification
  var notification = document.getElementById("copyNotification");
  notification.style.display = "block";
  // Hide notification after 2 seconds
  setTimeout(function () {
    notification.style.display = "none";
  }, 2000);
}
