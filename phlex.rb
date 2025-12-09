# frozen_string_literal: true

gem "phlex-rails"

after_bundle do
  generate "phlex:install"

  inject_into_file "app/components/base.rb", after: "class Components::Base < Phlex::HTML\n" do
    <<~HELPERS
      register_value_helper :admin_tool
      register_value_helper :current_user
    HELPERS
  end
  inside "app/components" do
    file "inspector.rb", <<~INSPECTOR
           # frozen_string_literal: true

           class Components::Inspector < Components::Base
               def initialize(object:)
                   @object = object
               end

               def view_template
                   admin_tool do
                       details class: "inspector" do
                           summary { record_id }
                           pre class: "inspector-content" do
                               unless @object.nil?
                                   raw safe(ap @object)
                               else
                                   plain "nil"
                               end
                           end
                       end
                   end
               end
                private

               def record_id
                   "\#{@object.class.name} \#{@object&.try(:public_id) || @object&.id}"
               end
           end
         INSPECTOR
  end
end
