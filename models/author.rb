# frozen_string_literal: true
class Author < Sequel::Model
  many_to_many :books, join_table: :authors_books
end
