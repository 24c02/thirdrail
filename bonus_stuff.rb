# frozen_string_literal: true

after_bundle do
  say "🎁 installing bonus content...", :green

  generate :controller, "static_pages"

  inject_into_file "app/controllers/static_pages_controller.rb", after: "class StaticPagesController < ApplicationController\n" do
    <<~CONTROLLER
      skip_before_action :require_authentication!, only: [:login]

      def home
      end

      def login
        redirect_to home_path if signed_in?
      end
    CONTROLLER
  end

  route "root 'static_pages#home', as: :root"

  file "app/views/static_pages/home.html.erb", <<~ERB
    <h1>Home</h1>
    #{if @use_hca
      '<%= button_to "Logout", logout_path, method: :delete, data: { turbo: false } if signed_in? %>'
    else
      ""
    end}
  ERB

  file "app/views/static_pages/login.html.erb", <<~ERB
    <h1>Login</h1>
    #{if @use_hca
      <<~HCA_BUTTON.chomp
        <%= button_to 'Sign in with Hack Club', '/auth/hackclub', method: :post, class: "hca-button", data: { turbo: false } %>
      HCA_BUTTON
    else
      ""
    end}
  ERB

  if @use_sass
    if @use_hca
      inside "app/frontend" do
        inside "styles" do
          file "hca.scss", <<~SCSS
            .hca-button {
              background: linear-gradient(to bottom, #ff4d64 0%, #ec3750 50%, #d42f45 100%);
              color: #fff;
              border: 1px solid #a82438;
              border-radius: 6px;
              padding: 0.7rem 1.4rem;
              font-weight: 600;
              cursor: pointer;
              text-shadow: 0 -1px 0 rgba(0, 0, 0, 0.3);
              box-shadow:
                inset 0 1px 0 rgba(255, 255, 255, 0.25),
                0 2px 3px rgba(0, 0, 0, 0.2);
              transition: box-shadow 0.1s ease;

              &:hover {
                background: linear-gradient(to bottom, #ff5a6e 0%, #f04058 50%, #db3448 100%);
              }

              &:active {
                background: linear-gradient(to bottom, #c92a3e 0%, #d42f45 50%, #ec3750 100%);
                box-shadow:
                  inset 0 2px 4px rgba(0, 0, 0, 0.3),
                  0 1px 0 rgba(255, 255, 255, 0.1);
              }
            }
          SCSS
        end
        inside "entrypoints" do
          append_to_file("application.scss") { '@use "@/styles/hca";' }
        end
      end
    end

    inside "app/frontend" do
      inside "styles" do
        file "admin_tool.scss", <<~SCSS
          .admin-tool {
            padding: 0.5rem;
            border-radius: 0.5rem;
            border: 1px dashed #ff8c37;
            background: rgba(#ff8c37, 0.125);
            overflow: auto;
          }
        SCSS
      end
    end
  end

  route "get '/login', to: 'static_pages#login', as: :login"
  route "delete '/logout', to: 'sessions#destroy', as: :logout" if @use_hca
end
