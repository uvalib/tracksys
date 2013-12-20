class IndexDestination < ActiveRecord::Base
  attr_accessible :nickname, :hostname, :context, :port, :protocol
  alias_attribute :name, :nickname

  #------------------------------------------------------------------
  # relationships
  #------------------------------------------------------------------
  has_many :bibls
  has_many :components
  has_many :units

  #------------------------------------------------------------------
  # validations
  #------------------------------------------------------------------
  validates :nickname, :hostname, :context, :port, :protocol, :presence => true
  validates :protocol, :format => {:with => /^https?$/ }
 
  def url
    "#{protocol}://#{hostname}:#{port}/#{context}"
  end

  def bibls
    []
  end

  def components
    []
  end

  def master_files
    []
  end

  def units
    []
  end
end
