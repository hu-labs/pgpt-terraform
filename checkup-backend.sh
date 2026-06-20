echo "--- Backend STABLE Alias & Version ---"
aws lambda get-alias \
  --function-name "$(terraform output -raw lambda_function_name)" \
  --name "$(terraform output -raw lambda_stable_alias)" \
  --region eu-west-2 \
  --query '{Alias:Name,FunctionVersion:FunctionVersion}' \
  --output table

echo "--- Backend test stage \$LATEST works ---"
curl -i -X POST "$(terraform output -raw api_gateway_test_url)" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $(terraform output -raw api_key_value)" \
  -d '{"threadId":"preview-direct-test-001","messages":[{"role":"user","content":"Say Hello test and nothing else."}]}' ; echo
  
echo "--- Backend public URL works ---"
curl -i -X POST "$(terraform output -raw public_api_url)" \
  -H "Content-Type: application/json" \
  -d '{"threadId":"preview-public-test-001","messages":[{"role":"user","content":"Say Hello test and nothing else."}]}' ; echo

