#encoding: utf-8
class Message
  include Mongoid::Document
  include Mongoid::Timestamps

  field :text
  field :read, type: Boolean, default: false

  belongs_to :user

  validates_presence_of :user
  validates_length_of :text, maximum: 10240
end

class ReceivedMessage < Message
  field :from

  validates_presence_of :from
  validates_length_of :from, minimum: 2, maximum: 32
end

class SentMessage < Message
  field :to
  field :read, type: Boolean, default: true

  validates_presence_of :to
  validates_length_of :to, minimum: 2, maximum: 32
end

class Mention < Message
  field :type
  field :event
  field :triggers, type: Array, default: []

  def deliver
    case type
    when 'post'
      post = Post.find(event)
      self.text = %Q{#{users_tag(triggers)}回复了你的文章#{post_tag(post)}.}
      post.user.messages << self
      post.user.save
    when 'reply'
      post = Post.find(event)
      post.comments.each do |c|
        next if c.user.nick == triggers.first
        self.text = %Q{#{post_tag(post)}有了新的回复.}
        c.user.messages << self
        c.user.save
      end
    when 'unfollow'
      user = User.find(event)
      self.text = %Q{#{user_tag(triggers.first)}对你取消了关注.}
      user.messages << self
      user.save
    when 'unsubscribe'
      board = Board.find(event)
      self.text = %Q{#{user_tag(triggers.first)}对你的#{board_tag(board)}小姐取消了关注.}
      board.user.messages << self
      board.user.save
    when 'founder'
      board = Board.unscoped.find(event)
      self.text = %Q{恭喜你成为了#{board_tag(board)}小姐的创始人.}
      board.user.messages << self
      board.user.save
    when 'achievement' then
    else
    end
  end
  
  private
  
  def users_tag triggers
    triggers[0..2].map{|t| %Q{<a href="/user/#{t}">#{t}</a>} }.join(',')
  end
  
  def user_tag trigger
    %Q{<a href="/user/#{trigger}">#{trigger}</a>}
  end
  
  def board_tag board
    %Q{<a href="/board/#{board.name}">#{board.name}</a>}
  end
  
  def post_tag post
    %Q{<a href="/post/#{post.token}">#{post.title}</a>}
  end
end

