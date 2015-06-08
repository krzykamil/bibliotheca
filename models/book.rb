# frozen_string_literal: true
class Book < Sequel::Model
  many_to_many :authors, join_table: :authors_books
end
