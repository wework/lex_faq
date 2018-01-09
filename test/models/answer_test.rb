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

require 'test_helper'

class AnswerTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
