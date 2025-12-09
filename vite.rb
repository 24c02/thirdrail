# frozen_string_literal: true

unless options[:skip_javascript]
  say "    [vite] WARNING: you're also installing the standard importmap/asset pipeline.", :yellow
  say '    [vite] you might not want to do that!', :yellow
end

use_yarn = default_yes?('    [vite] use Yarn instead of npm for package management?')
@use_sass = default_yes?('    [vite] set up SASS for CSS?')

say '    [vite] adding vite_rails gem...', :green
gem 'vite_rails'

after_bundle do
  say '    [vite] installing vite...', :green
  run 'bundle exec vite install'

  if use_yarn
    say '    [vite] playing with a ball of yarn...', :green
    gsub_file 'config/vite.json', '"packageManager": "npm"', '"packageManager": "yarn"'
    remove_file 'package-lock.json'
    run 'yarn install'
  end

  if @use_sass
    cmd = if use_yarn
            'yarn add -D sass-embedded'
          else
            'npm install -D sass-embedded'
          end
    say '    [vite] installing sass-embedded...', :green
    run cmd

    gsub_file 'app/views/layouts/application.html.erb',
              '<%= stylesheet_link_tag :app %>', '<%= vite_stylesheet_tag "application.scss" %>'
    gsub_file 'app/views/layouts/application.html.erb',
              '<%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>', '<%= vite_stylesheet_tag "application.scss" %>'

    inside 'app/frontend' do
      inside 'styles' do
        file 'dark_mode.scss', <<~SCSS
          html {
            color-scheme: light dark;
          }
        SCSS
      end
      inside 'entrypoints' do
        file 'application.scss', <<~SCSS
          @use "@/styles/dark_mode";
          
        SCSS
      end
    end
  end
end
