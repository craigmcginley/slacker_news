require 'sinatra'
require 'csv'
require 'pry'

def get_articles
  articles = []
  CSV.foreach('articles.csv', headers: true, header_converters: :symbol) do |row|
    articles << row.to_hash
  end
  articles
end

get '/' do
  @articles = get_articles
  @no_articles = "No articles to display yet. Submit one!"

  erb :index
end

get '/submit' do

  erb :submit
end

post '/submit' do
  article_info = [params["title"], params["url"], params["user"], Time.now, params["description"]]

  CSV.open('articles.csv', 'a+') do |csv|
    csv << article_info
  end

  redirect '/'
end
