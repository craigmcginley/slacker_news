require 'sinatra'
require 'time'
require 'uri'
require 'pg'
require_relative 'lib/time'

##### CONNECTION METHODS #####

configure :production do
  set :db_connection_info, {
    host: ENV['DB_HOST'],
    dbname: ENV['DB_NAME'],
    user: ENV['DB_USER'],
    password: ENV['DB_PASSWORD']
  }
end

configure :development do
  set :db_connection_info, {dbname: 'slacker_news'}
end

def db_connection
  begin
    connection = PG.connect(settings.db_connection_info)
    yield(connection)
  ensure
    connection.close
  end
end

##### SQL METHODS #####

def get_articles
  db_connection do |conn|
    conn.exec("SELECT * FROM articles")
  end
end

def save_article(title, url, username, description)
   db_connection do |conn|
    conn.exec_params("INSERT INTO articles (link, title, description, username, submitted_at)
    VALUES ($1, $2, $3, $4, NOW());", [url, title, description, username])
  end
end

def get_comments(id)
  db_connection do |conn|
    conn.exec_params('SELECT articles.link, articles.title, comments.username, comments.submitted_at, comments.comment
      FROM articles
      JOIN comments ON articles.id = comments.article_id WHERE articles.id = $1', [id])
  end
end

def save_comment(article_id, username, comment)
  db_connection do |conn|
    conn.exec_params("INSERT INTO comments (article_id, username, comment, submitted_at)
    VALUES ($1, $2, $3, NOW());", [article_id, username, comment])
  end
end

##### ERROR CHECK METHODS #####

def check_url(url)
  db_connection do |conn|
    conn.exec_params("SELECT * FROM articles WHERE link = $1", [url])
  end
end

def present?(value)
  value != nil && value != ""
end

def check_errors(params)
  errors = []
  articles = get_articles

  params.each do |key, val|
    unless present?(val)
      errors << "#{key.capitalize} is required"
    end
  end

  if params[:url] != "" && (params[:url] =~ URI::regexp) != 0
    errors << "Please enter a valid URL"
  end

  if !check_url(params[:url]).to_a.empty?
    errors << "This article has already been submitted."
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

def comment_errors(comment, username)
 errors = []

  if comment == ""
      errors << "Please enter a comment."
  end
  if username == ""
      errors << "Please enter a username."
  end

  errors
end

##### REQUEST METHODS #####

get '/' do
  redirect '/articles'
end

get '/articles' do
  @articles = get_articles
  @no_articles = "No articles yet. Submit one!"

  erb :'/articles/show'
end

get '/articles/new' do
  erb :'/articles/new'
end

post '/articles/new' do
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

  if @errors.empty?
    save_article(title, url, username, description)
    redirect '/articles'
  else
    erb :'/articles/new'
  end
end

get '/articles/:article_id/comments' do
  @id = params[:article_id]
  @errors = []
  @comments = get_comments(@id).to_a
  @no_comments = "No comments yet. Add one!"
  erb :'/comments/show'
end

post '/articles/:article_id/comments' do
  @id = params[:article_id]
  username = params[:username]
  comment = params[:comment]
  @comments = get_comments(@id).to_a
  @errors = []
  @errors = comment_errors(comment, username)
  if @errors.empty?
    save_comment(@id, username, comment)
    redirect "/articles/#{@id}/comments"
  else
    erb :'comments/show'
  end
end
