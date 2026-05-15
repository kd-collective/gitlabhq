# frozen_string_literal: true

module Admin
  module Registrations
    class ProfilesController < Admin::ApplicationController
      skip_before_action :set_confirm_warning
      before_action :verify_available!

      layout 'minimal'

      feature_category :onboarding

      urgency :low, [:update]

      def new
        @user = current_user
      end

      def update
        result = ::Users::UpdateService.new(current_user, user: current_user, **profile_params).execute

        if result[:status] == :success
          redirect_to post_onboarding_redirect_path
        else
          @user = current_user
          flash.now[:alert] = result[:message]
          render :new, status: :unprocessable_entity
        end
      end

      def skip
        redirect_to post_onboarding_redirect_path
      end

      private

      def verify_available!
        render_404 unless Feature.enabled?(:self_managed_welcome_onboarding, :instance) &&
          !Gitlab::CurrentSettings.gitlab_dedicated_instance?
      end

      def post_onboarding_redirect_path
        project_id = pop_welcome_project_id
        project = Project.find_by_id(project_id) if project_id
        project ? project_path(project) : root_path
      end

      def pop_welcome_project_id
        session.delete(:sm_welcome_project_id)
      end

      def profile_params
        user_params[:name] = full_name
        user_params
      end

      def user_params
        @user_params ||= params.require(:user).permit(*user_params_attributes)
      end

      def full_name
        "#{user_params[:first_name]} #{user_params[:last_name]}"
      end

      def user_params_attributes
        [:first_name, :last_name, :email, { user_detail_attributes: user_detail_params_attributes }]
      end

      def user_detail_params_attributes
        [:company]
      end
    end
  end
end

Admin::Registrations::ProfilesController.prepend_mod_with('Admin::Registrations::ProfilesController')
