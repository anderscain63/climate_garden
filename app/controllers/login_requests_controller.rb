# frozen_string_literal: true

require 'sms_client'

class LoginRequestsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[new create]

  def new; end

  # TODO: Rate limit
  def create
    phone = login_request_params[:phone]
    user = User.find_by(phone:)

    if user
      otp = create_otp(user)
      send_sms(user, otp)
      redirect_to new_session_path(phone:)
    else
      flash.now[:alert] = 'No user exists with that phone'
      render :new, status: :unprocessable_entity
    end
  end

  private

  def create_otp(user)
    user.one_time_passwords.create
  end

  # TODO: Handle failure
  def send_sms(user, otp)
    SmsClient.new.send(
      to: user.phone,
      message: "Code: #{otp.value}"
    )
  end

  def login_request_params
    params.permit(:phone)
  end
end
