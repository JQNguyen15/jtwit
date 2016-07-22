class User < ApplicationRecord
  has_many :microposts, dependent: :destroy

  has_many :active_relationships, class_name:  "Relationship",
                                foreign_key: "follower_id",
                                dependent:   :destroy
  has_many :following, through: :active_relationships, source: :followed 
  # following -> list of users self is following

  has_many :passive_relationships, class_name: "Relationship",
                                  foreign_key: "followed_id",
                                  dependent:    :destroy
  has_many :followers, through: :passive_relationships, source: :follower 
  # followers -> users following self

  attr_accessor :remember_token, :activation_token, :reset_token
  before_save   :downcase_email 
  before_create :create_activation_token 
  
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, length: { maximum: 255 },
            format: { with: VALID_EMAIL_REGEX }, 
            uniqueness: { case_sensitive: false }
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

  # Returns the hash digest of the given string.
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  #return a random token
  def User.new_token
    SecureRandom.urlsafe_base64
  end

  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  # Returns true if the given token matches the digest.
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  def forget
    update_attribute(:remember_digest, nil)
  end

  # Activates an account.
  def activate
    update_columns(activated: true, activated_at: Time.zone.now)
  end

  # Sends activation email.
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  #sets the password reset attributes
  #reset_token isnt being saved to db so its a attr_accessor
  #digest the reset token so cant be read by unauthorized users who gain db access
  def create_reset_digest
    self.reset_token = User.new_token
    update_columns(reset_digest: User.digest(reset_token), reset_sent_at: Time.zone.now)
  end

  #sends pw reset email
  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  #returns true if a password reset has expired
  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  # Defines a proto-feed.
  # See "Following users" for the full implementation.
  def feed
    Micropost.where("user_id = ?", id)
  end

  # follows a user
  def follow(other_user)
    self.active_relationships.create(followed_id: other_user.id)
  end

  # unfollows a user
  def unfollow(other_user)
    self.active_relationships.find_by(followed_id: other_user.id).destroy
  end

  # returns true if a self is following other_user
  def following?(other_user)
    self.following.include?(other_user)
  end

  # returns a user's feed
  def feed
    following_ids = "SELECT followed_id FROM relationships
                    WHERE  follower_id = :user_id"
    Micropost.where("user_id IN (#{following_ids})
                     OR user_id = :user_id", user_id: id)
  end

  private

    #converts email to lower case
    def downcase_email
      self.email = email.downcase
    end

    #creates and assigns the activation token and digest
    def create_activation_token
      self.activation_token  = User.new_token
      self.activation_digest = User.digest(activation_token)
    end
end
