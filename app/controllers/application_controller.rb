class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token

  respond_to :json

  include ActionView::Layouts
  include ActionController::RequestForgeryProtection

  before_action :process_token
  before_action :authenticate_user!

  # set Devise's current_user using decoded JWT instead of session
  def current_user
      @current_user ||= super || User.find(@current_user_id)
  end

  private
  # Check for auth headers - if present, decode or send unauthorized response (called always to allow current_user)
  def process_token
    token = request.headers['Authorization'] || (request.headers['referer']=="http://0.0.0.0:3001/" ? params["token"] : nil)
    puts "\n\n\n#{token} - TOKEN \n\n\n"
    if token
      begin
        jwt_payload = JWT.decode(token[1..-2], Rails.application.secrets.secret_key_base).first
        @current_user_id = jwt_payload['id']
      rescue JWT::ExpiredSignature, JWT::VerificationError, JWT::DecodeError
        head :unauthorized
      end
    end
    puts current_user
  end

  # If user has not signed in, return unauthorized response (called only when auth is needed)
  def authenticate_user!(options = {})
    head :unauthorized unless signed_in?
  end

  # check that authenticate_user has successfully returned @current_user_id (user is authenticated)
  def signed_in?
    @current_user_id.present?
  end

end
