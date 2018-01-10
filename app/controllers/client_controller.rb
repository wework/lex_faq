class ClientController < ApplicationController
  
  def index
    @utterances = Answer.pluck(:utterances).flatten
  end

end