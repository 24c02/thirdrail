# frozen_string_literal: true

gem 'airctiverecord'
gem 'faraday-net_http_persistent', '~> 2.0'

initializer 'norairrecord.rb', <<~INITIALIZER
  Norairrecord.api_key = ENV["AIRTABLE_PAT"]
INITIALIZER

file 'app/models/airpplication_record.rb', <<~MODEL
  class AirpplicationRecord < AirctiveRecord::Base
      # self.base_key = ENV["AIRTABLE_BASE_KEY"]
  end
MODEL
