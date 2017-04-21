require 'logger'
require 'dotenv'
require 'twitter'
require 'httparty'
require 'json'

Dotenv.load

@logger = Logger.new(STDOUT)
@logger.info "Starting the daily Starrlett Poem run..."

def fetch_quotes
  @logger.info "Polling osber.bt.gs for quotes..."
  response = HTTParty.get(ENV["SOURCE"])
  @logger.debug "osber.bt.gs responded with a #{response.code}."

  raise "Osber API Error" if response.code < 200 || response.code > 299

  parsed = JSON.parse response.body
  quotes = parsed["quotes"].map { |e| e["quote"] }

  @logger.info "Got #{quotes.size} quotes from Osber."

  quotes
end

def filter_quotes raw_quotes
  raw_quotes.map do |e|
    text = /\"(.*)\"/.match(e)[1]
    text += "." unless [ ",", ".", "!", "?"].include? text[-1]
    text
  end
end

def generate_poem quotes
  length = 0

  parts = []

  while length < 1 || length > 140 do
    parts = []

    3.times do
      parts << quotes.sample
    end

    length = parts.map { |e| e.length  }.reduce(:+)
  end

  parts
end

def quote_to_twitter quote_parts
  made_quote = quote_parts.join("\n")
  @logger.info "Tweeting..."

  begin
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["CONSUMER_KEY"]
      config.consumer_secret     = ENV["CONSUMER_SECRET"]
      config.access_token        = ENV["ACCESS_TOKEN"]
      config.access_token_secret = ENV["ACCESS_SECRET"]
    end

    #client.update made_quote

    @logger.info "Tweeted!"
  rescue Exception => e
    @logger.error "Failed to tweet! #{e}"
  end
end

def sync_to_osber quote_parts
  made_quote = quote_parts.join(" ")
  @logger.info "Syncing to Osber!"

  begin

    @logger.info "Synced!"
  rescue Exception => e
    @logger.error "Failed to sync! #{e}"
  end
end

def debug_output parts
  @logger.info "Poem:"

  parts.each do |p|
    @logger.info "- #{p}"
  end
end

raw_quotes = fetch_quotes
filtered = filter_quotes raw_quotes
parts = generate_poem filtered
debug_output parts
quote_to_twitter parts
sync_to_osber parts
