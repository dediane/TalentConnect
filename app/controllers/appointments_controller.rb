class AppointmentsController < ApplicationController
  include AppointmentHelper
  # Before executing certain methods we find the right appointment to operate on
  before_action :set_appointment, only: [:show, :destroy, :update]
  before_action :authenticate_user!
  before_action :authenticate_user!, :user_have_info?, only: [:new]
  before_action :is_user_both_apprentice_and_mentor?
  

  def index
    @appointments = Appointment.all
  end

  def show
    @talent = Talent.find(@appointment.talent_id)
  end

  def new
    @appointment = Appointment.new
    @talent = Talent.find(params[:talent_id])
    @duration_hour = (@talent.duration / 60).round
    paid_appointments_as_mentor = Appointment.where(mentor_id: @talent.user_id, is_mentor_validate: true, is_paid: true) 
    mentor_validate_appointments_as_mentor = Appointment.where(mentor_id: @talent.user_id, is_mentor_validate: true, is_paid: false)
    paid_appointments_as_apprentice = Appointment.where(apprentice_id: @talent.user_id, is_mentor_validate: true, is_paid: true)
    mentor_validate_appointments_as_apprentice = Appointment.where(apprentice_id: @talent.user_id, is_mentor_validate: true, is_paid: false)
    
    @user_agenda = paid_appointments_as_mentor || mentor_validate_appointments_as_mentor || paid_appointments_as_apprentice || mentor_validate_appointments_as_apprentice
  end

  def create
    @talent = Talent.find(params[:talent_id])
    @appointment = Appointment.new(appointment_params)
    @appointment.talent_id = @talent.id
    @appointment.apprentice_id = current_user.id
    @appointment.mentor_id = @talent.user_id
    @appointment.place_id = @talent.place_id
    if @appointment.save
      flash[:success] = "La séance a bien été proposée au mentor !"
      redirect_to talent_path(@talent)
    else
      flash.now[:danger] = "La séance n'a pas été créée."
      render :new
    end
  end
  
  def update
    @appointment.update(appointment_params_update)
    if @appointment.is_mentor_validate
      validation_by_mentor_send(@appointment)
    end
    redirect_to mentor_show_user_path(current_user.id)
  end

  def destroy
    @appointment.destroy
    appointment_rejected_send(@appointment)
    redirect_to mentor_show_user_path(current_user.id)
  end
  
  private
  # find the appointment using the id
  def set_appointment
    @appointment = Appointment.find(params[:id])
  end

  # let throught and define the Appointement params that were sent from the view
  def appointment_params
    params.require(:appointment).permit(:start_time, :is_mentor_validate)
  end

  def appointment_params_update
    params.permit(:is_mentor_validate)
  end

  def validation_by_mentor_send(appointment)
    UserMailer.validation_by_mentor_confirmation(appointment).deliver_now
  end

  def appointment_rejected_send(appointment)
    UserMailer.appointment_rejected_confirmation(appointment).deliver_now
  end

end
