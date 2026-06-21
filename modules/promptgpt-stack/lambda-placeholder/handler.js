exports.handler = async (event) => {
  const allowedOrigin = event.stageVariables?.allowedOrigin || "http://localhost:5173";

  return {
    statusCode: 200,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": allowedOrigin,
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type,X-Api-Key",
    },
    body: JSON.stringify({
      message: "Hello from promptgpt-preview placeholder Lambda",
      stageVariables: event.stageVariables || {},
    }),
  };
};
