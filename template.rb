# frozen_string_literal: true

say '🚃 welcome to thirdrail!', :cyan

TEMPLATE_ROOT = if __FILE__.start_with?("http")
                  File.dirname(__FILE__)
                else
                  __dir__
                end

@post_install_tasks = []

def apply_template(template_name, tasks = [])
  apply File.join(TEMPLATE_ROOT, "#{template_name}.rb")
  @post_install_tasks.concat(tasks)
end

@just_trust_me_bro = !no?("blindly trust nora's judgement? [Y/n]", :cyan)

def default_yes?(question)
  return say("#{question}: yes", :cyan) || true if @just_trust_me_bro

  !no?("#{question} [Y/n]")
end

gem 'jb'
gem 'pry-rails', group: :development
gem 'awesome_print'
gem 'dotenv-rails', groups: %i[development test]

file '.env.development', ""

gsub_file 'app/controllers/application_controller.rb',
          /^\s*# Only allow modern browsers.*\n\s*allow_browser versions: :modern\n?/m,
          ''

@use_public_ids = default_yes?('use public IDs (hashid-rails)?')
apply_template('public_identifiable') if @use_public_ids
apply_template('vite', ['run `bin/vite dev` alongside your Rails server']) if default_yes?('use Vite?')
apply_template('phlex') if default_yes?('use Phlex?')

@use_hca = default_yes?('set up Hack Club Auth?')
apply_template('hack_club_auth', ['set HACKCLUB_CLIENT_ID and HACKCLUB_CLIENT_SECRET in .env.development']) if @use_hca

@user_model = default_yes?('generate a User model?')
apply_template('user', ['run `bin/rails db:migrate`']) if @user_model

@use_airctiverecord = yes?('set up AirctiveRecord? [y/N]')
apply_template('airctiverecord', ['set AIRTABLE_PAT in .env.development']) if @use_airctiverecord

apply_template('bonus_stuff') if @user_model && default_yes?('install bonus content?')

say "\n📋 next steps:", :yellow
@post_install_tasks.uniq.each { |task| say "   • #{task}" }
say ''
