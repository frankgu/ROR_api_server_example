class Api::V1::StudentsController < Api::ApiController
  prepend_before_action :authenticate_student_request,
    :only => [:show, :edit, :reset_password, :get_status,
              :send_verification_code, :destroy, :activate_account]
  before_action :activation_check,
    :only => [:show, :edit, :reset_password, :get_status,
              :send_verification_code, :destroy]

  attr_reader :current_student

  # Student sign up function
  api :POST, '/students/signup', 'student sign up'
  param :student, Hash, :desc => 'student parameters' do
    param :name, String, :desc => 'student name', :required => true
    param :phoneNumber, String, :desc => 'student phone number',
          :required => true
    param :password, String, :desc => 'password', :required => true
    param :password_confirmation, String, :desc => 'confirmation of password',
          :required => true    
    param :country_code, [86, 1], :desc => '86/1 China/America & anada',
          :required => true
    param :gender, ['male', 'female'], :required => true
    param :picture, String, :desc => 'picture url'
  end
  formats ['JSON']
  error 400, 'parameter missing'
  error 403, 'invalid parameter'
  error 422, 'parameter value error'
  def create
    unless params && params[:student] && params[:student][:password] &&
        params[:student][:password_confirmation] && params[:student][:name] &&
        params[:student][:phoneNumber] && params[:student][:gender] &&
        params[:student][:country_code]
      return render_params_missing_error 
    else
      # Create a new student
      student = Core::Student.new(student_signup_params)

      return save_model_error student unless student.save
      # used to send an activation email to user / disabled for demo purpose
      # @student.send_activation_email
      # student.activate

      # send the verification code sms to the student
      student.send_verification_sms
      render :json => { :message => I18n.t('students.create.success'),
                        :student_id => student.id }, :status => :ok
    end
  end

  # Activate student account according to the verification code
  api :POST, '/students/activate_account', 'activate student'
  param :verification_code, String, :desc => "verification code", required: true
  header 'Authorization', "authentication token has to be passed as part
    of the request.", required: true
  formats ['JSON']
  error 400, 'parameter missing'
  error 401, 'unauthorized, account not found'
  error 401, 'verification code is wrong'
  def activate_account
    unless params && params[:verification_code]
      return render_params_missing_error
    else
      code = current_student.verification_code
      # error handler
      return render_error(I18n.t('students.errors.verification_code.missing'),
                          :not_found) if code.nil?
      # If the verification code doesn't match
      return render_error(I18n.t('students.errors.verification_code.invalid'),
                          :unauthorized) if !code.to_i.eql?(params[:verification_code].to_i)
      # activate the account
      current_student.activate
      render_message(I18n.t 'students.activate_account.success')
    end
  end

  # Edit the student information
  api :PATCH, '/students/info', 'edit the student information'
  param :student, Hash, :desc => 'student parameters' do
    param :name, String, :desc => 'student name'
    param :email, String, :desc => 'student email'
    param :device_token, String, :desc => 'device token'
    param :picture, String, :desc => 'student picture url'
    param :prioritized_tutor, Integer, :desc => 'student favourate tutor id'
    param :gender, ['male', 'female'], :desc => 'student gender'
    param :state, ['available', 'unavailable'], :desc => 'options: available unavailable'
  end
  header 'Authorization', "authentication token has to be passed as part
    of the request.", required: true
  error 400, 'parameter missing'
  error 401, 'unauthorized, account not found'
  error 412, 'account not activate'
  error 422, 'parameter value error'
  def edit
    if params && params[:student]
      return save_model_error current_student unless 
        current_student.update_attributes(student_edit_params)
      render_message(I18n.t 'students.edit.success')
    else
      return render_params_missing_error
    end
  end

  # Get student information
  api :GET, '/students/info', 'get the information of a single student'
  header 'Authorization', "authentication token has to be passed as part
   of the request.", required: true
  error 401, 'unauthorized, account not found'
  error 412, 'account not activate'
  def show
    render json: current_student, :status => :ok
  end

  # Update the password once the verification process has done
  api :POST, '/students/reset_password', '[(step 2,3) for resetting the password],
    you need to call send_verification_code first to send an sms message to student,
    verify the verification code only if password and password confirmation absent'
  header 'Authorization', "authentication token has to be passed as part
   of the request.", required: true
  param :verification_code, String, :desc => 'authentication code for password reset',
    :required => true
  param :password, String, :desc => 'new password'
  param :password_confirmation, String, :desc => 'new password confirmation'
  formats ['JSON']
  error 404, 'doesn\'t request for reset password first'
  error 401, 'verification code doesn\'t match'
  error 401, 'unauthorized, account not found'
  error 400, 'parameter missing'
  error 412, 'account not activate'
  error 422, 'parameter value error'
  def reset_password
    unless params && params[:verification_code]
      return render_params_missing_error
    else
      code = current_student.verification_code
      # error handler
      return render_error(I18n.t('students.errors.verification_code.missing'),
                          :not_found) if code.nil?
      return render_error(I18n.t('students.errors.verification_code.invalid'),
                          :unauthorized) if !code.to_i.eql?(params[:verification_code].to_i)
      if params[:password] && params[:password_confirmation]
        # update the password
        password_params = params.permit(:password, :password_confirmation)
        return save_model_error current_student unless current_student.\
          update_attributes(password_params)
        current_student.clear_verification_code
        # return success message
        render_message(I18n.t 'students.reset_password.success')
      else
        render_message(I18n.t 'students.reset_password.verification')
      end
    end
  end

  # Student request to send a new verification_code for account activation and
  # password reset
  api :GET, '/students/send_verification_code', '[(step 1) for resetting the
    password] request to send a new verification_code for account activation
    and password reset'
  header 'Authorization', "authentication token has to be passed as part
   of the request.", required: true
  error 401, 'unauthorized, account not found'
  error 412, 'account not activate'
  def send_verification_code
    current_student.send_verification_sms
    render_message(I18n.t 'students.send_verification_code.success')
  end

  # Get student status
  api :GET, '/students/status', 'get the student status'
  header 'Authorization', "authentication token has to be passed as part
   of the request.", required: true
  error 401, 'unauthorized, account not found'
  error 412, 'account not activate'
  def get_status
    render :json => current_student.get_current_status, :status => :ok
  end

  # Student signout
  api :DELETE, '/students/signout', 'signout students, clean the device token'
  header 'Authorization', "authentication token has to be passed as part
   of the request.", required: true
  error 401, 'unauthorized, account not found'
  error 412, 'account not activate'
  def destroy
    # clear the device token
    if current_student.update_attribute(:device_token, nil)
      render_message(I18n.t 'students.destroy.success')
    else
      save_model_error current_student
    end
  end

  # (This is a test for action cable function)
  def send_messages 
    ActionCable.server.broadcast 'messages',
      message: 'test messages from actioncable broadcasting'
    head :ok
  end

################################################################################ 
# Following code Need to be updated
################################################################################ 

  # student can modify and appointment(for now used for rating & feedback)
  def rate_feedback
    if params
      if @student && @student.remember_expiry > Time.now
        #  find certain appointment by appointment id
        ap = @student.appointments.find_by_id(rate_feedback_params[:id])

        if @student.state.eql? 'rating'
          if ap && ap.update_attributes(rate_feedback_params)
            # student finished rating , change the state to available
            @student.change_state 'available' if @student.state.eql? 'rating'
            # set up the prioritized tutor
            if rate_feedback_set_prioritized_tutor_params[:set_prioritized_tutor] == 'true'
              ap.student.set_prioritized_tutor(ap.tutor.id)
            elsif ap.student_rating < 1 && ap.student.prioritized_tutor == ap.tutor.id
              ap.student.set_prioritized_tutor(nil)
            end
            render :json => {:message => (I18n.t 'success.messages.rating')},
                   :status => 200
            return
          else
            json_error_message 401, (I18n.t 'error.messages.rating')
            # not sure why code 204 is not working???
          end
        else
          json_error_message 400, (I18n.t 'error.messages.unpaid_appointment')
        end
      else
        json_error_message 401, (I18n.t 'error.messages.login')
      end
    else
      json_error_message 400, (I18n.t 'error.messages.parameters')
    end
  end

  # This student is now looking for a tutor
  def request_look_for_tutors
    if params && params[:plan_id]
      if @student && @student.remember_expiry > Time.now
        # change the student state to matching
        @student.change_state 'matching' if @student.state.eql? 'available'
        # whenever the student start a new request the session counter will increase by one
        @student.increment!(:session_count)
        # student start to look for a tutor
        params[:topic_id] = 1;
        rv = @student.request_look_for_tutors params[:topic_id], params[:plan_id]
        if rv == 'success'
          # begin the timer for 90 seconds search period
          job_id = RequestCancelWorker.perform_in((Settings.Reservation.look_for_tutor_time +
              Settings.Reservation.delta)
                                                      .seconds, @student.id, @student.session_count)
          # save job id to db
          @student.update_attributes(remark1: job_id)
          render :json => {:message => (I18n.t 'success.messages.request')},
                 :status => 200
        else
          # change the student states back to available if it fails to request a tutor
          @student.change_state 'available'
          json_error_message 409, (I18n.t 'error.messages.request', reason: rv)
        end
      else
        json_error_message 401, (I18n.t 'error.messages.login')
      end
    else
      json_error_message 400, (I18n.t 'error.messages.parameters')
    end
  end

  # This student is now looking for a prioritized tutor
  def request_look_for_prioritized_tutor
    if params && params[:plan_id]
      if @student && @student.remember_expiry > Time.now
        # change the student state to matching
        @student.change_state 'matching' if @student.state.eql? 'available'
        # student start to look for prioritized tutor
        params[:topic_id] = 1;
        rv = @student.request_look_for_prioritized_tutor params[:topic_id], params[:plan_id]
        if rv == 'success'
          render :json => {:message => (I18n.t 'success.messages.request')},
                 :status => 200
        else
          @student.change_state 'available' if @student.state.eql? 'matching'
          json_error_message 409, (I18n.t 'error.messages.request', reason: rv)
        end
      else
        json_error_message 401, (I18n.t 'error.messages.login')
      end
    else
      json_error_message 400, (I18n.t 'error.messages.parameters')
    end
  end

  # This student is cancelling this request
  def request_cancel_look_for_tutors
    if params
      if @student && @student.remember_expiry > Time.now
        rv = @student.request_cancel_look_for_tutors(request_cancel_look_for_tutors_params[:session_id])
        if rv == 'success'
          render :json => {:message => (I18n.t 'success.messages.cancel_request')},
                 :status => 200
        else
          json_error_message 409, (I18n.t 'error.messages.cancel_request', reason: rv)
        end
      else
        json_error_message 401, (I18n.t 'error.messages.login')
      end
    else
      json_error_message 400, (I18n.t 'error.messages.parameters')
    end
  end

  # Check if the currently logged user has valid token
  def verify_token
    if @student && @student.remember_expiry > Time.now
      render :json => {:message => (I18n.t 'success.messages.token')},
             :status => 200
    else
      json_error_message 401, (I18n.t 'error.messages.login')
    end
  end

  # Get the number of tutors online
  def tutors_online_count
    if params && params[:plan_id]
      c = Core::Tutor.where(["state = ? and level >= ?", "available", params[:plan_id]]).count
      render :json => {:message => "#{c}"}, :status => 200
    else
      json_error_message 400, (I18n.t 'error.messages.parameters')
    end
  end

  # Request to get the info of the reserved tutor
  def request_get_tutor
    if params
      if @student && @student.remember_expiry > Time.now
        rv = @student.requests.find_by_id(request_get_tutor_params[:id])
        if rv
          render :json => rv.tutor, :status => 200
        else
          json_error_message 401, (I18n.t 'error.messages.no_tutor')
        end
      else
        json_error_message 401, (I18n.t 'error.messages.login')
      end
    else
      json_error_message 400, (I18n.t 'error.messages.parameters')
    end
  end

  # Check if the student's email has been resisted or not
  def check_email
    if params && params[:email]
      if Core::Student.find_by(email: params[:email])
        render :json => {:message => 'false'}, :status => 200
      else
        render :json => {:message => 'true'}, :status => 200
      end
    else
      json_error_message 400, (I18n.t 'error.messages.parameters')
    end
  end

  # Get all the appointment of this student
  def get_all_appointments
    if @student && @student.remember_expiry > Time.now
      # Only get the appointments with specific state
      appointments = @student.appointments.sort_by(&:start_time).reverse
      message = []
      appointments.each do |appointment|
        message << appointment.student_all_appointment_to_json
      end

      message.each { |msg|
        if msg['pay_state'].eql? 'paid'
          msg['pay_state'] = I18n.t 'term.pay.finished'
        else
          msg['pay_state'] = I18n.t 'term.pay.unfinished'
        end
      }

      if message.empty?
        json_error_message 204, (I18n.t 'error.messages.no_appointment')
      else
        render :json => message, :status => 200
      end
    else
      json_error_message 401, (I18n.t 'error.messages.login')
    end
  end

  private

  # (Updated) Only get the require information for student register
  def student_signup_params
    params[:student][:balance] = 0
    params[:student][:state] = 'available'
    params.require(:student).permit(:name, :password, :email, :gender,
                                    :password_confirmation, :balance,
                                    :phoneNumber, :picture, :country_code,
                                    :state)
  end

  # (Updated) Only get the required information for the tutor editing
  def student_edit_params
    params.require(:student).permit(:email, :name, :prioritized_tutor,
                                    :device_token, :picture, :gender,
                                    :state)
  end

  def tutor_state_params
    params.require(:tutor).permit(:id)
  end

  # Define the require params for edit the appointment for student
  def rate_feedback_params
    params.require(:appointment).permit(:id, :student_rating, :student_feedback)
  end

  # Define the require params for edit the appointment for student
  def rate_feedback_set_prioritized_tutor_params
    params.permit(:set_prioritized_tutor)
  end

  # Only get the required information for the set prioritized tutor
  def student_set_prioritized_tutor_params
    params.require(:student).permit(:prioritized_tutor)
  end

  # Only get the required information for the request get tutor
  def request_get_tutor_params
    params.require(:request).permit(:id)
  end

  # Only get the required information for the request cancel look for tutors
  def request_cancel_look_for_tutors_params
    params.permit(:session_id)
  end

  # (updated) Check whether the student account has been activated or not
  def activation_check
    if !current_student.activated?
      render :json => {:error => I18n.t('students.errors.activation')},
             :status => :precondition_failed
    end
  end

  # (updated) Authenticate the student accourding to the auth_token in the header
  def authenticate_student_request
    @current_student = AuthorizeApiRequest.call('student', request.headers).result
    render :json => {:error => I18n.t('students.errors.credential')},
           :status => :unauthorized unless @current_student
  end
end