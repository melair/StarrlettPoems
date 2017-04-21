require 'logger'
require 'dotenv'
require 'twitter'
require 'httparty'
require 'json'

Dotenv.load

logger = Logger.new(STDOUT)

logger.info "Starting the daily Starrlett Poem run..."

logger.info "Polling osber.bt.gs for quotes..."
response = HTTParty.get(ENV["SOURCE"])
logger.debug "osber.bt.gs responded with a #{response.code}."

raise "Osber API Error" if response.code < 200 || response.code > 299

parsed = JSON.parse response.body
quotes = parsed["quotes"].map { |e| e["quote"] }

logger.info "Got #{quotes.size} quotes from Osber."

def filter quote
  text = /\"(.*)\"/.match(quote)[1]
  text += "." unless [ ",", ".", "!", "?"].include? text[-1]
  text
end

filtered = quotes.map { |e| filter(e)  }

parts = []

3.times do
  parts << filtered.sample
end

made_quote = parts.join("\n")

logger.info "Made: #{made_quote}"

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV["CONSUMER_KEY"]
  config.consumer_secret     = ENV["CONSUMER_SECRET"]
  config.access_token        = ENV["ACCESS_TOKEN"]
  config.access_token_secret = ENV["ACCESS_SECRET"]
end

client.update made_quote
