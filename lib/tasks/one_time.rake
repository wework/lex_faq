namespace :one_time do 
  
  task set_lex_lambda_permissions: :environment do
    # Set lambda permissions
    lambda_client = Aws::Lambda::Client.new(region: ENV["LEX_FAQ_AWS_REGION"], access_key_id: ENV["LEX_FAQ_AWS_ACCESS_ID"], secret_access_key: ENV["LEX_FAQ_AWS_SECRET_ACCESS_KEY"])
    opts = {
      source_arn: "arn:aws:lex:#{ENV["LEX_FAQ_AWS_REGION"]}:#{ENV["LEX_FAQ_AWS_LAMBDA_ARN_NUMBER"]}:intent:*",
      statement_id: SecureRandom.uuid,
      principal: "lex.amazonaws.com",
      action: "lambda:invokeFunction",
      function_name: Lex::Bot::FUNCTION_NAME
    }
    lambda_client.add_permission(opts)
  end

end