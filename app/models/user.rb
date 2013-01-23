require 'digest/sha1'

class User < ActiveRecord::Base

  has_many :sites
  has_many :site_stats

  attr_accessor :plain_password

  validates_presence_of :email
  validates_uniqueness_of :email
#  validates_length_of :plain_password, :minimum => 5


  def self.authenticate(email, plain)
    logger.debug "user auth:\n#{email}\n#{plain}"
    if u = User.find_by_email(email)
      logger.debug "yo"
      return u if u.match(plain)
      logger.debug "no match"
      return false
    else
      return nil
    end
  end

  def name
    return ((n = self[:name]) && (n.size > 0) ? self[:name] : email )
  end

  # alias for Site.find(id) - but only finds a site
  # when it belongs to the user
  def site(id)
    s = SiteStat.find(id)
    return nil if s.user != self
    s
  end

  # assign plaintext password and convert to SHA-1-hash
  def password=(plain)
    @old_password = self[:password]
    raise "password has to be a string ... was #{plain.class}" unless plain.kind_of?(String)
    self.plain_password = plain
    return false if plain.size < 5
    generate_salt
    self[:password] = encrypt(plain)
  end

  def forget_password!
    self[:password] = ''
    self[:salt] = ''
  end
  
  def match(plain)
    encrypt(plain) == self.password
  end

  protected

  def validate
    if (plain_password && plain_password.size < 5)
#    unless (@old_password && self.plain_password && self.plain_password.size == 0) ||
#       (self.plain_password && self.plain_password.size > 4)
      errors.add("password", "is too short (min 5 chars)") 
    end
  end

  def encrypt(plain)
    Digest::SHA1.hexdigest(self.salt.to_s + plain.to_s)
  end

  def generate_salt(len=8)
    s = ''
    len.times do |i|
      s << (rand(95)+32).chr
    end
    self[:salt] = s
    return s    
  end

end
