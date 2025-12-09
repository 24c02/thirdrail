# frozen_string_literal: true

after_bundle do
  columns = [
    ('hca_id:string:uniq' if @use_hca),
    'email:string',
    'name:string',
    'is_admin:boolean'
  ].compact

  generate :model, 'user', *columns

  # Add default value for is_admin
  migration_file = Dir.glob('db/migrate/*_create_users.rb').first
  gsub_file migration_file, 't.boolean :is_admin', 't.boolean :is_admin, default: false, null: false'

  file 'app/models/user.rb', <<~MODEL, force: true
    # frozen_string_literal: true

    class User < ApplicationRecord
      #{if @use_public_ids
        <<~PUBLIC_ID.chomp
          include PublicIdentifiable
          set_public_id_prefix :usr

        PUBLIC_ID
      else
        ''
      end}
      scope :admins, -> { where(is_admin: true) }

      #{if @use_hca
        <<~HCA_SECTION.chomp
          validates :hca_id, presence: true, uniqueness: true

          def self.find_or_create_from_omniauth(auth)
            find_or_create_by!(hca_id: auth.uid) do |user|
              user.email = auth.info.email
              user.name = auth.info.name
            end
          end

          #{@hca_use_api ? 'def hca_profile(access_token) = HCAService.new(access_token).me' : ''}
        HCA_SECTION
      else
        ''
      end}
    end
  MODEL
end

inject_into_file 'app/controllers/application_controller.rb',
                 after: "class ApplicationController < ActionController::Base\n" do
  <<~HELPERS
  before_action :require_authentication!

  helper_method :current_user, :signed_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def signed_in? = current_user.present?

  def require_authentication!
    redirect_to login_path, alert: "Please sign in to continue." unless signed_in?
  end

  HELPERS
end

if @use_hca
  inject_into_file 'app/controllers/sessions_controller.rb', after: "auth = request.env[\"omniauth.auth\"]\n" do
    <<~CREATE
    user = User.find_or_create_from_omniauth(auth)
    session[:user_id] = user.id

    CREATE
  end
end

inject_into_file 'app/helpers/application_helper.rb', after: "module ApplicationHelper\n" do
  <<~HELPERS
  def admin_tool(class_name: "", element: "div", **options, &block)
    return unless current_user&.is_admin?
    concat content_tag(element, class: "admin-tool #\{class_name}", **options, &block)
  end

  HELPERS
end
