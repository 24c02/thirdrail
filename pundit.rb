# frozen_string_literal: true

gem 'pundit'

file 'app/policies/application_policy.rb', <<~POLICY
  # frozen_string_literal: true

  class ApplicationPolicy
    attr_reader :user, :record

    def initialize(user, record)
      @user = user
      @record = record
    end

    def index? = false
    def show? = false
    def create? = false
    def new? = create?
    def update? = false
    def edit? = update?
    def destroy? = false

    class Scope
      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve = raise NotImplementedError, "You must define #resolve in \#{self.class}"

      private

      attr_reader :user, :scope
    end
  end
POLICY

inject_into_class 'app/controllers/application_controller.rb', 'ApplicationController', <<~RUBY
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back fallback_location: root_path
  end

RUBY

say '✅ Pundit configured'

