/*
    Loads the CloudFront function frontend-routes.js.
    Evaluates it in an isolated node:vm context.
    Tests seven URI cases.
    Confirms SPA routes rewrite to /index.html.
    Confirms assets and API routes remain unchanged.
    Confirms the handler returns the original request object and preserves its query string.

    node --test ./scripts/test-cloudfront.cjs
*/

const { readFileSync } = require("node:fs");
const { runInNewContext } = require("node:vm");
const assert = require("node:assert/strict");
const { test } = require("node:test");
const source = readFileSync(
  new URL(
    "../modules/promptgpt-stack/cloudfront/frontend-routes.js",
    `file://${__filename}`,
  ),
  "utf8",
);

const handler = runInNewContext(`${source}\nhandler`);

for (const [uri, expected] of [
  ["/", "/index.html"],
  ["/chat/thread", "/index.html"],
  ["/chat/", "/index.html"],
  ["/assets/app.js", "/assets/app.js"],
  ["/favicon.ico", "/favicon.ico"],
  ["/api/v1/threads", "/api/v1/threads"],
  ["/api/v1", "/api/v1"],
]) {
  test(`rewrites ${uri} to ${expected}`, () => {
    const request = {
      uri,
      method: "GET",
      querystring: { code: { value: "login-code" } },
      headers: {},
    };
    const result = handler({ request });
    assert.equal(result, request);
    assert.equal(result.uri, expected);
    assert.equal(result.querystring.code.value, "login-code");
  });
}
