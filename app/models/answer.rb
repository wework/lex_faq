# == Schema Information
#
# Table name: answers
#
#  id         :integer          not null, primary key
#  utterances :jsonb
#  response   :text
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Answer < ApplicationRecord

  validates_presence_of :name, :response, :utterances # Better to put this in the PG index, but whatever
  before_validation :check_max_intents # Amazon only allows 100 intents per bot, so raise an error if you have more than 98 answers in this database
  before_validation :encode_up_utterances # Make sure that utterances have only allowed values in them, check the method for more deets
  # after_commit :push_to_lex

  MAX_INTENTS     = 99.freeze # Amazon only allows 100 intents per bot
  ID_ALPHA_MAPPER = %w(x a b c d e f g h j k l m n o p).freeze # Its the alphabet, more explanation forthcoming
  INTENT_PREFIX   = "XANS".freeze # A simple, short prefix used to identify intents created by this application, vs. manually this could be any short alphabetical string
  CLIENT          = Aws::LexModelBuildingService::Client.new(region: ENV["LEX_FAQ_AWS_REGION"],
                                                    access_key_id: ENV["LEX_FAQ_AWS_ACCESS_ID"], 
                                                    secret_access_key: ENV["LEX_FAQ_AWS_SECRET_ACCESS_KEY"])

  def check_max_intents
    # Called in the before_validation code hook, Amazon only allows 100 intents per bot, so raise an error if you have more than 98 answers in this database
    raise "AWS Lex only allows 100 intents per bot, delete some of the intents in your lex bot and delete some Answers from this DB." if Answer.count >= MAX_INTENTS
  end

  def encode_up_utterances # Called in the before_validation code hook
    uts = []
    utterances.each do |u| # iterate through all the potential utterances
      uts << u.gsub(/[^0-9a-z {}]/i, '').strip # remove any potential offending characters, Amazon is very fussy about this stuff.
    end
    self.utterances = uts.uniq
  end

  def lex_mapped_intent_name
    # This is where some of the magic happens. 
    # Since intents in Lex must be named using ONLY ALPHA characters
    # We use the primary key and the INTENT_PREFIX to generate the name for the intent
    id_to_map = self.id.to_s.split("") # Take the ID turn it into a string and then an array. So id: 32 becomes ["3", "2"]
    
    good_id   = [] # Create an array to store the mapped values
    
    id_to_map.each do |article_id_as_string|
      good_id << ID_ALPHA_MAPPER[article_id_as_string.to_i] # if article_id_as_string equals "3" then the ID_ALPHA_MAPPER will map to "c"
    end

    good_id = good_id.join("")

    "#{INTENT_PREFIX}#{good_id}" # if the id was 32 this would return "ANScb"
  end

  def push_to_lex # called after the instance is saved, this pushes the answer to the lex bot
    begin
      data = { # construct the payload to push to lex
        name: self.lex_mapped_intent_name,
        description: self.name, # Use the "Name" of the answer to fill in the description
        sample_utterances: self.utterances, # A simple array ["Where are the crackers?", "Where are the cookies?"]
        fulfillment_activity: {
          type: "ReturnIntent"
        },
      }

      resp = CLIENT.get_intent({ # if we've already created a Lex intent with this go grab it so we can extract the checksum
        version: "$LATEST", 
        name: self.lex_mapped_intent_name
      }) rescue nil

      checksum = resp.try(:checksum)

      if checksum.present?
        data[:checksum] = checksum
      end
      # add the checksum to the payload if it exits 

      CLIENT.put_intent(data)

      bot = Lex::Bot.current
      bot.attach_answer_as_intent!(self)
    rescue => error
      puts ">>>>>>>>>>>>>>> #{error.inspect}"
    end
  end

  def self.find_by_mapped_lex_name(lex_name)
    encoded_id = lex_name.split(INTENT_PREFIX)[1].split("")
    decoded_id = []

    encoded_id.each do |letter|
      decoded_id << ID_ALPHA_MAPPER.index(letter)
    end

    id = decoded_id.join("").to_i

    self.find_by(id: id)
  end

end
