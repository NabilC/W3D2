require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
  include Singleton
  
  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class User
  attr_accessor :id, :fname, :lname
  
  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM users")
    data.map { |datum| User.new(datum) }
  end
  
  def self.find_by_id(id)
    users_arr = QuestionsDatabase.instance.execute <<-SQL, id
    SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL
    return nil unless users_arr.length > 0
    User.new(users_arr.first)
  end

  def self.find_by_name(fname, lname)
    users_arr = QuestionsDatabase.instance.execute <<-SQL, fname, lname
    SELECT
      *
    FROM
      users
    WHERE
      fname = ? AND lname = ?
    SQL
    return nil unless users_arr.length > 0
    User.new(users_arr.first)
  end

  def authored_questions
    questions_arr = Question.find_by_author_id(id)
    return nil unless questions_arr.length > 0
    questions_arr
  end

  def authored_replies
    replies_arr = Reply.find_by_user_id(id)
    return nil unless replies_arr.length > 0
    replies_arr
  end

  def followed_questions
    QuestionFollow.followed_questions_for_user_id(id)
  end
end
  
class Question
  attr_accessor :id, :title, :body, :author_id
  
  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
    data.map { |datum| Question.new(datum) }
  end
  
  def self.find_by_id(id)
    questions_arr = QuestionsDatabase.instance.execute <<-SQL, id
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL
    return nil unless questions_arr.length > 0
    Question.new(questions_arr.first)
  end

  def self.find_by_author_id(author_id)
    questions_arr = QuestionsDatabase.instance.execute <<-SQL, author_id
    SELECT
      *
    FROM
      questions
    WHERE
      author_id = ?
    SQL
    return nil unless questions_arr.length > 0
    output_arr = []
    questions_arr.each do |question|
      output_arr << Question.new(question)
    end
    output_arr
  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  def author
    User.find_by_id(author_id)
  end

  def replies
    Reply.find_by_question_id(id)
  end

  def followers
    QuestionFollow.followers_for_question_id(id)
  end
end

class QuestionFollow
  attr_accessor :id, :questions_id, :users_id
  
  def initialize(options)
    @id = options['id']
    @questions_id = options['questions_id']
    @users_id = options['users_id']
  end

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM QuestionFollow")
    data.map { |datum| QuestionFollow.new(datum) }
  end
  
  def self.find_by_id(id)
    q_follows_arr = QuestionsDatabase.instance.execute <<-SQL, id
      SELECT
        *
      FROM
        question_follows
      WHERE
        id = ?
    SQL
    return nil unless q_follows_arr.length > 0
    QuestionFollow.new(q_follows_arr.first)
  end

  def self.followers_for_question_id(question_id)
    q_follows_arr = QuestionsDatabase.instance.execute <<-SQL, question_id
      SELECT
        users_id
      FROM
        questions
      JOIN
        question_follows ON question_follows.questions_id = questions.id
      WHERE
        questions.id = ?
    SQL
    q_follows_arr.map { |user| User.find_by_id(user['users_id']) }
  end

  def self.followed_questions_for_user_id(user_id)
    q_follows_arr = QuestionsDatabase.instance.execute <<-SQL, user_id
      SELECT
        questions_id
      FROM
        questions
      JOIN
        question_follows ON
        question_follows.questions_id = questions.id
      WHERE
        users_id = ?
    SQL
    q_follows_arr.map { |question| Question.find_by_id(question['questions_id']) }
  end

  def self.most_followed_questions(n)
    questions_arr = QuestionsDatabase.instance.execute <<-SQL, n
      SELECT
        questions_id
      FROM
        questions
      JOIN
        question_follows ON question_follows.questions_id = questions.id
      GROUP BY
        title
      ORDER BY
        COUNT(users_id) DESC
      LIMIT
        ?
    SQL
    questions_arr.map { |question| Question.find_by_id(question['questions_id']) }
  end
end

class Reply
  attr_accessor :id, :questions_id, :parent_reply_id, :users_id, :body
  
  def initialize(options)
    @id = options['id']
    @questions_id = options['questions_id']
    @parent_reply_id = options['parent_reply_id']
    @users_id = options['users_id']
    @body = options['body']
  end

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM reply")
    data.map { |datum| Reply.new(datum) }
  end
  
  def self.find_by_id(id)
    reply_arr = QuestionsDatabase.instance.execute <<-SQL, id
      SELECT
        *
      FROM
        reply
      WHERE
        id = ?
    SQL
    return nil unless reply_arr.length > 0
    Reply.new(reply_arr.first)
  end

  def self.find_by_user_id(id)
    reply_arr = QuestionsDatabase.instance.execute <<-SQL, id
      SELECT
        *
      FROM
        reply
      WHERE
        users_id = ?
    SQL
    return nil unless reply_arr.length > 0
    output_arr = []
    reply_arr.each do |reply|
      output_arr << Reply.new(reply)
    end
    output_arr
  end

  def self.find_by_question_id(id)
    reply_arr = QuestionsDatabase.instance.execute <<-SQL, id
      SELECT
        *
      FROM
        reply
      WHERE
        questions_id = ?
    SQL
    return nil unless reply_arr.length > 0
    output_arr = []
    reply_arr.each do |reply|
      output_arr << Reply.new(reply)
    end
    output_arr
  end

  def author
    User.find_by_id(users_id)
  end

  def question
    Question.find_by_id(questions_id)
  end

  def parent_reply
    unless parent_reply_id.nil?
      return Reply.find_by_id(parent_reply_id)
    else
      return self
    end
  end

  def child_replies
    replies = Reply.find_by_question_id(questions_id)
    replies.each do |reply|
      return reply unless reply.parent_reply_id.nil?
    end
    nil
  end
end

class QuestionLike
  attr_accessor :id, :questions_id, :users_id
  
  def initialize(options)
    @id = options['id']
    @questions_id = options['questions_id']
    @users_id = options['users_id']
  end

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM QuestionLike")
    data.map { |datum| QuestionLike.new(datum) }
  end
  
  def self.find_by_id(id)
    q_likes_arr = QuestionsDatabase.instance.execute <<-SQL, id
      SELECT
        *
      FROM
        question_likes
      WHERE
        id = ?
    SQL
    return nil unless q_likes_arr.length > 0
    QuestionLike.new(q_likes_arr.first)
  end

  def self.likers_for_question_id(question_id)
    users_arr = QuestionsDatabase.instance.execute <<-SQL, question_id
      SELECT
        users_id
      FROM
        questions
      JOIN 
        question_likes ON question_likes.questions_id = questions.id
      WHERE
        questions.id = ?
    SQL
    users_arr.map { |user| User.find_by_id(user['users_id'])}
  end

  def self.num_likes_for_question_id(question_id)
    num_likes_arr = QuestionsDatabase.instance.execute <<-SQL, question_id
      SELECT
        count(users_id)
      FROM
        questions
      JOIN 
        question_likes ON question_likes.questions_id = questions.id
      WHERE
        questions.id = ?
    SQL
    num_likes_arr.first['count(users_id)']
  end
end