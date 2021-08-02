# frozen_string_literal: true
class Author < Sequel::Model
  many_to_many :books
end
