#--
#
# Copyright 2009, 2010, 2011, 2012 University of Oslo
# Copyright 2009, 2010, 2011, 2012 Marius L. Jøhndal
#
# This file is part of the PROIEL web application.
#
# The PROIEL web application is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# version 2 as published by the Free Software Foundation.
#
# The PROIEL web application is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the PROIEL web application.  If not, see
# <http://www.gnu.org/licenses/>.
#
#++

class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable,
    :encryptable

  attr_accessible :login, :first_name, :last_name, :email,
    :password, :password_confirmation, :role,
    :graph_method, :graph_format

  has_many :assigned_sentences, :class_name => 'Sentence', :foreign_key => 'assigned_to'
  has_many :audits, :class_name => 'Audited::Adapters::ActiveRecord::Audit'
  has_many :notes, :as => :originator

  validates_presence_of :login, :message => 'cannot be blank.'
  validates_uniqueness_of :login, :case_sensitive => false, :message => 'already exists. Please choose a different login.'
  validates_length_of :login, :within => 3..40
  validates_presence_of :first_name, :message => 'cannot be blank.'
  validates_presence_of :last_name, :message => 'cannot be blank.'

  store :preferences, accessors: [:graph_format, :graph_method]

  # Returns the user's full name.
  def full_name
    "#{first_name} #{last_name}"
  end

  # Tests whether the user has a particular role.
  def has_role?(r)
    case r.to_sym
    when :reader
      true # All users are readers
    when :annotator
      role == 'annotator' || role == 'reviewer' || role == 'administrator'
    when :reviewer
      role == 'reviewer' || role == 'administrator'
    when :administrator
      role == 'administrator'
    else
      raise ArgumentError, 'invalid role'
    end
  end

  # Create a new, confirmed administrator user.
  def self.create_confirmed_administrator!(attrs)
    u = User.new attrs
    u.confirmed_at = Time.now
    u.role = 'administrator'
    u.save!
  end

  def first_assigned_sentence
    assigned_sentences.
      includes(:source_division).
      order("source_divisions.position, sentences.sentence_number").
      first
  end

  def shift_assigned_sentence!
    s = first_assigned_sentence
    s.update_attributes! assigned_to:  nil
  end

  def to_s
    login
  end
end
