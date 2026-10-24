// SPA route fallback for the frontend
// Rewrites a path whose last segment doesn't contain a dot (.) to /index.html
// Preserves API paths

function handler(event) {
  var request = event.request;
  var uri = request.uri;

  // API paths must retain their status even if a request reaches this behavior.
  if (uri === "/api/v1" || uri.indexOf("/api/v1/") === 0) return request;
  // Extract the last segment of the URI.
  var lastSegment = uri.substring(uri.lastIndexOf("/") + 1);
  // The last segment doesn't contain a dot, so it's a SPA route.
  if (lastSegment.indexOf(".") === -1) request.uri = "/index.html";

  return request;
}
