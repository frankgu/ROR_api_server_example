class AuthenticationController < ApplicationController
  # Authenticate the student account
  api :POST, '/authenticate/student', 'authenticate the student account'
  api_version 'root'
  param :phone, String, :desc => 'student phone number', :required => true
  param :password, String, :desc => 'password', :required => true
  error 401, 'invalid credential'
  def authenticate_student
    if params && params[:phone] && params[:password]
      command = AuthenticateStudent.call(params[:phone], params[:password])

      if command.success?
        render json: { auth_token: command.result }, status: :ok
      else
        render json: { error: command.errors }, status: :unauthorized
      end
    else
      return render_params_missing_error
    end
  end

  # Authenticate the tutor account
  api :POST, '/authenticate/tutor', 'authenticate the tutor account'
  api_version 'root'
  param :phone, String, :desc => 'tutor phone number', :required => true
  param :password, String, :desc => 'password', :required => true
  error 401, 'invalid credential'
  def authenticate_tutor
    if params && params[:phone] && params[:password]
      command = AuthenticateTutor.call(params[:phone], params[:password])

      if command.success?
        render json: { auth_token: command.result }, status: :ok
      else
        render json: { auth_token: command.errors }, status: :unauthorized
      end
    else
      return render_params_missing_error
    end
  end
end