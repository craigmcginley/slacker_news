require 'sinatra'
require 'redis'
require 'pry'
require 'json'
require 'uri'
require 'csv'
require_relative 'lib/time'

def get_connection
  if ENV.has_key?("REDISCLOUD_URL")
    Redis.new(url: ENV["REDISCLOUD_URL"])
  else
    Redis.new
  end
end

def find_articles
  redis = get_connection
  serialized_articles = redis.lrange("slacker:articles", 0, -1)

  articles = []

  serialized_articles.each do |article|
    articles << JSON.parse(article, symbolize_names: true)
  end

  articles
end

def save_article(title, url, username, time, description)
  article = { title: title, url: url, username: username, time: time, description: description }

  redis = get_connection
  redis.rpush("slacker:articles", article.to_json)
end

# def get_articles
#   articles = []
#   CSV.foreach('articles.csv', headers: true, header_converters: :symbol) do |row|
#     articles << row.to_hash
#     articles.each do |article|
#       article[:time] = Time.parse(article[:time])
#     end
#   end
#   articles
# end

def present?(value)
  value != nil && value != ""
end

def check_errors(params)
  errors = []
  articles = find_articles

  params.each do |key, val|
    unless present?(val)
      errors << "#{key.capitalize} is required"
    end
  end

  if params[:url] != "" && (params[:url] =~ URI::regexp) != 0
    errors << "Please enter a valid URL"
  end

  articles.each do |article|
    if params[:url] == article[:url]
      errors << "This URL has already been submitted"
    end
  end

  if params[:description].length < 20 || params[:description].length > 140
    errors << "Please enter a description between 20-140 characters"
  end

  errors
end

get '/' do
  @articles = find_articles
  @no_articles = "No articles to display yet. Submit one!"

  erb :index
end

get '/submit' do
  erb :submit
end

post '/submit' do
  @params = {
    title: params["title"],
    username: params["username"],
    url: params["url"],
    description: params["description"]
  }

  title = params[:title]
  username = params[:username]
  url = params[:url]
  description = params[:description]

  @errors = check_errors(@params)

  # query = params.map {|key, val| "#{key}=#{val}"}.join("&")

  if @errors.empty?
    save_article(title, url, username, (Time.now), description)
    # article_info = [@params[:title], @params[:url], @params[:username], (Time.now), @params[:description]]

    # CSV.open('articles.csv', 'a+') do |csv|
    #   csv << article_info
    # end
    redirect '/'
  else
    erb :submit
  end
end
