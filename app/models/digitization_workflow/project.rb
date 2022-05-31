# == Schema Information
#
# Table name: projects
#
#  id                 :integer          not null, primary key
#  workflow_id        :integer
#  unit_id            :integer
#  owner_id           :integer
#  current_step_id    :integer
#  priority           :integer          default("normal")
#  due_on             :date
#  item_condition     :integer
#  added_at           :datetime
#  started_at         :datetime
#  finished_at        :datetime
#  category_id        :integer
#  viu_number         :string(255)
#  capture_resolution :integer
#  resized_resolution :integer
#  resolution_note    :string(255)
#  workstation_id     :integer
#  condition_note     :text(65535)
#  container_type_id  :bigint(8)
#

class Project < ApplicationRecord
   enum priority: [:normal, :high, :critical]
   enum item_condition: [:good, :bad]

   belongs_to :workflow
   belongs_to :unit
   belongs_to :owner, :class_name=>"StaffMember", optional: true
   belongs_to :current_step, :class_name=>"Step", optional: true
   belongs_to :category, counter_cache: true
   belongs_to :workstation, optional: true
   belongs_to :container_type, optional: true

   has_one :order, :through => :unit
   has_one :customer, :through => :order
   has_one :metadata, :through => :unit

   has_and_belongs_to_many :equipment, :join_table=>:project_equipment,  :dependent=>:destroy

   has_many :assignments,  :dependent=>:destroy
   has_many :notes,  :dependent=>:destroy

   validates :workflow,  :presence => true
   validates :unit,  :presence => true
   validates :due_on,  :presence => true
   validates :item_condition,  :presence => true
   validates :category,  :presence => true

   scope :active, ->{where(finished_at: nil).reorder(due_on: :asc) }
   scope :failed_qa, ->{ joins("inner join steps s on current_step_id = s.id" ).where("step_type = 2") }
   scope :overdue, ->{where("due_on < ? and finished_at is null", Date.today.to_s).reorder(due_on: :asc) }

   public
   def self.has_error
      q = "inner join"
      q << " (select * from assignments where status = 4 order by assigned_at desc limit 1) "
      q << " a on a.project_id = projects.id"
      Project.joins(q).where("projects.finished_at is null")
   end

   before_create do
      self.added_at = Time.now
      self.current_step = self.workflow.first_step
   end

   def started?
      return !self.started_at.nil?
   end

   def finished?
      return !self.finished_at.nil?
   end

   def project_name
      name = self.unit.metadata.title
      name = "" if name.nil?
      return name
   end

   def active_assignment
      return nil if self.assignments.count == 0
      return self.assignments.order(assigned_at: :asc).last
   end
end
