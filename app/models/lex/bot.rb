class Lex::Bot
  include ActiveModel::Model

  attr_accessor :name, :data

  VERSION = "alpha"
  NAME = "TestFAQ"
  LAMBDA_FUNCTION_NAME = "TestFAQFunction"
  CLIENT = Aws::LexModelBuildingService::Client.new(region: ENV["LEX_FAQ_AWS_REGION"], 
    access_key_id: ENV["LEX_FAQ_AWS_ACCESS_ID"], 
    secret_access_key: ENV["LEX_FAQ_AWS_SECRET_ACCESS_KEY"])

  def self.current
    data = CLIENT.get_bot({
      name: Lex::Bot::NAME,
      version_or_alias: "$LATEST", 
    })

    self.new(name: Lex::Bot::NAME, data: data)
  end

  def attach_answer_as_intent!(answer = nil)
    raise "You gotta give me an answer" unless answer.present?
    
    data_hash = self.data.to_h

    names = data_hash[:intents].to_a.collect{|i| i[:intent_name] }

    if names.include?(answer.lex_mapped_intent_name)
      return "This Article is already attached to the bot"
    end

    intents = data_hash[:intents].to_a << {
      intent_name: answer.lex_mapped_intent_name,
      intent_version: "$LATEST"
    }

    payload = {
      name: self.name, 
      abort_statement: data_hash[:abort_statement], 
      child_directed: false, 
      clarification_prompt: data_hash[:clarification_prompt], 
      description: data_hash[:description], 
      idle_session_ttl_in_seconds: data_hash[:idle_session_ttl_in_seconds], 
      intents: intents,
      locale: "en-US", 
      process_behavior: "SAVE",
      checksum: data_hash[:checksum],
      voice_id: data_hash[:voice_id]
    }

    CLIENT.put_bot(payload)
  end

  def build!
    data_hash = self.data.to_h

    paylod = {
      name: self.name, 
      abort_statement: data_hash[:abort_statement], 
      child_directed: false, 
      clarification_prompt: data_hash[:clarification_prompt], 
      description: data_hash[:description], 
      idle_session_ttl_in_seconds: data_hash[:idle_session_ttl_in_seconds], 
      intents: data_hash[:intents],
      locale: "en-US", 
      process_behavior: "BUILD",
      checksum: data_hash[:checksum],
      voice_id: data_hash[:voice_id]
    }

    CLIENT.put_bot(paylod)
  end

  def publish!
    resp = CLIENT.get_bot_alias({
      name: Lex::Bot::VERSION,
      bot_name: self.name,
    })

    data = {
      name: Lex::Bot::VERSION,
      description: "This is my bot.",
      bot_version: "$LATEST",
      bot_name: self.name,
    }

    checksum = resp.try(:checksum)

    if checksum.present?
      data[:checksum] = checksum
    end

    CLIENT.put_bot_alias(data)
  end

end