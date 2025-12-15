# frozen_string_literal: true

# Opinionated: OIDC is simpler and sufficient for most apps.
# API mode is only needed if you need to make server-side calls to HCA.
@hca_use_api = yes?('[hca] need server-side API access? (adds HCAService) [y/N]')

gem 'omniauth'

if @hca_use_api
  gem 'omniauth-hack_club'
  gem 'faraday'
else
  gem 'omniauth_openid_connect'
end

initializer 'hack_club_auth.rb', <<~INITIALIZER
  Rails.application.config.hack_club_auth = ActiveSupport::OrderedOptions.new
  Rails.application.config.hack_club_auth.client_id = ENV.fetch("HACKCLUB_CLIENT_ID", nil)
  Rails.application.config.hack_club_auth.client_secret = ENV.fetch("HACKCLUB_CLIENT_SECRET", nil)
  Rails.application.config.hack_club_auth.base_url = ENV.fetch("HACKCLUB_AUTH_URL") { Rails.env.production? ? "https://auth.hackclub.com" : "https://hca.dinosaurbbq.org" }
INITIALIZER

append_to_file '.env.development', <<~ENV
  HACKCLUB_CLIENT_ID=
  HACKCLUB_CLIENT_SECRET=
ENV

if @hca_use_api
   append_to_file 'config/initializers/inflections.rb', <<~INFLECTIONS

     ActiveSupport::Inflector.inflections(:en) do |inflect|
       inflect.acronym "HCA"
     end
   INFLECTIONS

   initializer 'omniauth.rb', <<~OMNIAUTH
     Rails.application.config.middleware.use OmniAuth::Builder do
       provider :hack_club, 
         Rails.application.config.hack_club_auth.client_id,
         Rails.application.config.hack_club_auth.client_secret,
         scope: "openid email name slack_id verification_status",
         staging: !Rails.env.production?
     end
   OMNIAUTH

  file 'app/services/hca_service.rb', <<~SERVICE
    # frozen_string_literal: true

    class HCAService
      BASE_URL = Rails.application.config.hack_club_auth.base_url

      def initialize(access_token)
        @conn = Faraday.new(url: BASE_URL) do |f|
          f.request :json
          f.response :json, parser_options: { symbolize_names: true }
          f.response :raise_error
          f.headers["Authorization"] = "Bearer \#{access_token}"
        end
      end

      def me = @conn.get("/api/v1/me").body

      def check_verification(idv_id: nil, email: nil, slack_id: nil)
        params = { idv_id:, email:, slack_id: }.compact
        raise ArgumentError, "Provide one of: idv_id, email, or slack_id" if params.empty?

        @conn.get("/api/external/check", params).body
      end
    end
  SERVICE
else
   initializer 'omniauth.rb', <<~OMNIAUTH
     Rails.application.config.middleware.use OmniAuth::Builder do
       provider :openid_connect,
         name: :hack_club,
         issuer: Rails.application.config.hack_club_auth.base_url,
         discovery: true,
         client_options: {
           identifier: Rails.application.config.hack_club_auth.client_id,
           secret: Rails.application.config.hack_club_auth.client_secret,
           redirect_uri: "\#{ENV.fetch('APP_URL', 'http://localhost:3000')}/auth/hack_club/callback"
         },
         scope: %i[openid profile email verification_status],
         response_type: :id_token,
         response_mode: :form_post
     end
   OMNIAUTH
end

file 'app/controllers/sessions_controller.rb', <<~CONTROLLER
  # frozen_string_literal: true

  class SessionsController < ApplicationController
    skip_before_action :require_authentication!, only: %i[create failure]

    def create
      auth = request.env["omniauth.auth"]

      redirect_to root_path, notice: "Signed in successfully!"
    end

    def destroy
      reset_session
      redirect_to root_path, notice: "Signed out successfully!"
    end

    def failure
      redirect_to root_path, alert: "Authentication failed: \#{params[:message]}"
    end
  end
CONTROLLER

route <<~ROUTES
  post "/auth/hack_club", as: :hack_club_auth
  get "/auth/hack_club/callback", to: "sessions#create"
  get "/auth/failure", to: "sessions#failure"
ROUTES

append_to_file 'config/initializers/omniauth.rb', <<~OMNIAUTH
  OmniAuth.config.allowed_request_methods = [:post]
  OmniAuth.config.request_validation_phase = OmniAuth::AuthenticityTokenProtection.new(key: :_csrf_token)
OMNIAUTH

say "✅ Hack Club Auth configured (#{@hca_use_api ? 'with API access' : 'OIDC only'})"
