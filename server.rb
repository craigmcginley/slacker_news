require 'sinatra'
require 'csv'

def get_articles
  articles = []
  CSV.foreach('articles.csv', headers: true, header_converters: :symbol) do |row|
    articles << row.to_hash
  end
  articles
end

get '/' do
  @articles = get_articles

  erb :index
end

get '/new' do

  erb :new
end

post '/new' do


end
