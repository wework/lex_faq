class Admin::AnswersController < AdminController

  def index
    @answers = Answer.all
  end

  def create
    answer = Answer.new(answer_params)
    answer.utterances = answer_params["utterances"].split(",")
    
    if answer.save
      answer.push_to_lex
      flash[:success] = "#{answer.name} successfully created!"
    else
      flash[:error] = answer.errors.full_messages.join(",")
    end

    redirect_to admin_answers_path
  end

  def update
    answer = Answer.find(params[:id])
    answer.utterances = answer_params["utterances"].split(",")
    
    if answer.save
      answer.push_to_lex
      flash[:success] = "#{answer.name} successfully updated!"
    else
      flash[:error] = answer.errors.full_messages.join(",")
    end

    redirect_to admin_answers_path
  end

  def edit
    @answer = Answer.find(params[:id])
  end

  def new
    @answer = Answer.new
  end

  private

  def answer_params
    params.require(:answer).permit(:name, :response, :utterances)
  end

end