PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname TEXT NOT NULL,
  lname TEXT NOT NULL
);

DROP TABLE IF EXISTS questions;

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  author_id INTEGER NOT NULL,
  FOREIGN KEY (author_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS question_follows;

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  questions_id INTEGER NOT NULL,
  users_id INTEGER NOT NULL,
  FOREIGN KEY (questions_id) REFERENCES questions(id),
  FOREIGN KEY (users_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS reply;

CREATE TABLE reply (
  id INTEGER PRIMARY KEY,
  questions_id INTEGER NOT NULL,
  parent_reply_id INTEGER,
  users_id INTEGER NOT NULL,
  body TEXT NOT NULL,
  FOREIGN KEY (questions_id) REFERENCES questions(id),
  -- Reference to parent reply, could be null if top-level
  FOREIGN KEY (parent_reply_id) REFERENCES reply(id),
  FOREIGN KEY (users_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS question_likes;

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  questions_id INTEGER NOT NULL,
  users_id INTEGER NOT NULL,
  FOREIGN KEY (questions_id) REFERENCES questions(id),
  FOREIGN KEY (users_id) REFERENCES users(id)
);

INSERT INTO
 users(fname, lname)
VALUES
  ('Arthur', 'Miller'),
  ('Boaty', 'McBoatface'),
  ('Ronald', 'McDonald'),
  ('Andrew', 'Chan');

INSERT INTO
  questions(title, body, author_id)
VALUES
  ('Do you exist?', 'Do you really exist.', 
    (SELECT id FROM users WHERE fname = 'Boaty')
  ),
  ('pls don''t like, follow, or answer this question', 'pretty please :)', 
    (SELECT id FROM users WHERE fname = 'Boaty')
  ),
  ('How are you?', 'I hope it''s good.',
    (SELECT id FROM users WHERE fname = 'Ronald')
  ),
  ('Where are you from?', 'Name of country.',
    (SELECT id FROM users WHERE fname = 'Arthur')
  ),
  ('What is your favorite food?', 'Could be any cuisine',
    (SELECT id FROM users WHERE fname = 'Andrew')
  );

INSERT INTO
  question_follows(questions_id, users_id)
VALUES
  (
    (SELECT id FROM questions WHERE title = 'Do you exist?'),
    (SELECT id FROM users WHERE fname = 'Ronald')
  ),
  (
    (SELECT id FROM questions WHERE title = 'Do you exist?'),
    (SELECT id FROM users WHERE fname = 'Boaty')
  ),
  (
    (SELECT id FROM questions WHERE title = 'Do you exist?'),
    (SELECT id FROM users WHERE fname = 'Arthur')
  ),
  (
    (SELECT id FROM questions WHERE title = 'Do you exist?'),
    (SELECT id FROM users WHERE fname = 'Andrew')
  ),
  (
    (SELECT id FROM questions WHERE title = 'How are you?'),
    (SELECT id FROM users WHERE fname = 'Boaty')
  ),
  (
    (SELECT id FROM questions WHERE title = 'Where are you from?'),
    (SELECT id FROM users WHERE fname = 'Ronald')
  ),
  (
    (SELECT id FROM questions WHERE title = 'Where are you from?'),
    (SELECT id FROM users WHERE fname = 'Arthur')
  ),
  (
    (SELECT id FROM questions WHERE title = 'What is your favorite food?'),
    (SELECT id FROM users WHERE fname = 'Andrew')
  );

INSERT INTO 
  reply(questions_id, parent_reply_id, users_id, body)
VALUES
  (
    (SELECT id FROM questions WHERE title='Do you exist?'),
    NULL,
    (SELECT id FROM users WHERE fname='Boaty'),
    'I''m not quite sure.'
  ),
  (
    (SELECT id FROM questions WHERE title='Do you exist?'),
    1,
    (SELECT id FROM users WHERE fname='Ronald'),
    'No, you don''t.'
  ),
  (
    (SELECT id FROM questions WHERE title='How are you?'),
    NULL,
    (SELECT id FROM users WHERE fname='Andrew'),
    ':)'
  ),
  (
    (SELECT id FROM questions WHERE title='Where are you from?'),
    NULL,
    (SELECT id FROM users WHERE fname='Ronald'),
    'McDonald''s'
  ),
  (
    (SELECT id FROM questions WHERE title='Where are you from?'),
    4,
    (SELECT id FROM users WHERE fname='Arthur'),
    'I don''t care.'
  ),
  (
    (SELECT id FROM questions WHERE title='What is your favorite food?'),
    NULL,
    (SELECT id FROM users WHERE fname='Andrew'),
    'Sushi, of course.'
  ),
  (
    (SELECT id FROM questions WHERE title='What is your favorite food?'),
    6,
    (SELECT id FROM users WHERE fname='Boaty'),
    'Fish.'
  ),
  (
    (SELECT id FROM questions WHERE title='What is your favorite food?'),
    6,
    (SELECT id FROM users WHERE fname='Ronald'),
    'Definitely not KFC.'
  );

INSERT INTO
  question_likes(users_id, questions_id)
VALUES
  (
    (SELECT id FROM users WHERE fname='Arthur'),
    (SELECT id FROM questions WHERE title='Where are you from?')
  ),
  (
    (SELECT id FROM users WHERE fname='Arthur'),
    (SELECT id FROM questions WHERE title='What is your favorite food?')
  ),
  (
    (SELECT id FROM users WHERE fname='Boaty'),
    (SELECT id FROM questions WHERE title='Do you exist?')
  ),
  (
    (SELECT id FROM users WHERE fname='Boaty'),
    (SELECT id FROM questions WHERE title='Where are you from?')
  ),
  (
    (SELECT id FROM users WHERE fname='Ronald'),
    (SELECT id FROM questions WHERE title='What is your favorite food?')
  ),
  (
    (SELECT id FROM users WHERE fname='Ronald'),
    (SELECT id FROM questions WHERE title='Where are you from?')
  ),
  (
    (SELECT id FROM users WHERE fname='Ronald'),
    (SELECT id FROM questions WHERE title='Do you exist?')
  ),
  (
    (SELECT id FROM users WHERE fname='Andrew'),
    (SELECT id FROM questions WHERE title='What is your favorite food?')
  ),
  (
    (SELECT id FROM users WHERE fname='Andrew'),
    (SELECT id FROM questions WHERE title='How are you?')
  ),
  (
    (SELECT id FROM users WHERE fname='Andrew'),
    (SELECT id FROM questions WHERE title='Do you exist?')
  ),
  (
    (SELECT id FROM users WHERE fname='Andrew'),
    (SELECT id FROM questions WHERE title='Where are you from?')
  );