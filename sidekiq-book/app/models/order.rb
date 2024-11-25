#---
# Excerpted from "Ruby on Rails Background Jobs with Sidekiq",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/dcsidekiq for more book information.
#---
class Order < ApplicationRecord
  belongs_to :product
  belongs_to :user

  validates :email, presence: true
  validates :address, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }

  attribute :quantity, :integer, default: 1

  class QuantityMustBeAvailable < ActiveModel::Validator
    def validate(record)
      if record.product.present? && record.quantity.present? && record.quantity > 0
        if record.quantity > record.product.quantity_remaining
          record.errors.add(:quantity,"is more than what is in stock")
        end
      end
    end
  end

  validates_with QuantityMustBeAvailable
end
