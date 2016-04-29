class IndexDestination < ActiveRecord::Base
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
  validates :protocol, :format => {:with => /\Ahttps?\z/ }

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
# == Schema Information
#
# Table name: index_destinations
#
#  id               :integer(4)      not null, primary key
#  nickname         :string(255)
#  hostname         :string(255)     default("localhost")
#  port             :string(255)     default("8080")
#  protocol         :string(255)     default("http")
#  context          :string(255)     default("solr")
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#  bibls_count      :integer(4)
#  units_count      :integer(4)
#  components_count :integer(4)
#
