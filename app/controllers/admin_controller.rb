class AdminController < ApplicationController
  http_basic_authenticate_with name: ENV['LEX_FAQ_ADMIN_NAME'], password: ENV['LEX_FAQ_ADMIN_PASSWORD'] unless Rails.env.development? 
end