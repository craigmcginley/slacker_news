CREATE TABLE articles (
  id serial PRIMARY KEY,
  title VARCHAR (1000) NOT NULL,
  link VARCHAR (1000) NOT NULL,
  username VARCHAR (250) NOT NULL,
  submitted_at TIMESTAMP NOT NULL,
  description VARCHAR (1000) NOT NULL
);

CREATE TABLE comments (
  id serial PRIMARY KEY,
  article_id INTEGER NOT NULL,
  username VARCHAR (250) NOT NULL,
  submitted_at TIMESTAMP NOT NULL,
  comment VARCHAR (1000) NOT NULL
);
