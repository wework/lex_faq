class Api::V1::AnswersController < ApiController

  def get
    lex_client = Aws::Lex::Client.new(
                    region: ENV["LEX_FAQ_AWS_REGION"], 
                    access_key_id: ENV["LEX_FAQ_AWS_ACCESS_ID"], 
                    secret_access_key: ENV["LEX_FAQ_AWS_SECRET_ACCESS_KEY"])

    resp = lex_client.post_text({
      bot_name: Lex::Bot::NAME,
      bot_alias: Lex::Bot::VERSION,
      user_id: params[:user_id],
      session_attributes: {},
      input_text: params[:text]
    })

    sleep(1);

    if resp.dialog_state == "ElicitIntent"
      render json: { 
        answer: "Sorry, I don't know how to respond to that.", 
        dialog_action_type: "Close",
        fulfillment_state: "Fulfilled",
        status: 404
        } and return
    end

    @answer = Answer.find_by_mapped_lex_name(resp.intent_name)

    render json: { 
      answer: @answer.response, 
      dialog_action_type: "Close",
      fulfillment_state: "Fulfilled",
      status: 200
      } and return
    
  rescue => e
    status = @answer.present? ? 500 : 404 
    render json: { 
      answer: "OH NO! Something went wrong: #{e.inspect}",
      fulfillment_state: 'Fulfilled',
      dialog_action_type: "Close",
      status: status
    } and return
  end


end