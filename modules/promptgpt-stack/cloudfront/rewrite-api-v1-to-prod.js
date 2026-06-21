/*
    Viewer request:
    /api/v1/chat

    Origin request:
    /prod/chat
*/
function handler(event) {
  var request = event.request;
  var prefix = "/api/v1";

  if (request.uri === prefix || request.uri.indexOf(prefix + "/") === 0) {
    request.uri = request.uri.replace(prefix, "/prod");
  }

  return request;
}
