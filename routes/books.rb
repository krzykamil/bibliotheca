# frozen_string_literal: true

class Bibliotheca
  hash_routes.on 'books' do |r|
    r.is do
      r.get do
        # TODO: add filters for attributes

        # uncomment when done wih elm testing
        # @books = Book.where(Sequel.lit('books.name ILIKE ? AND books.genre IN (?)', "%#{request.params["search"]}%", "test")).eager_graph(:authors).all
        # @genres = @books.map(&:genre).uniq.compact
        # @genres_size = @genres.count
        @fakebooks = [OpenStruct.new(description: 'test', completed: true, editing: false, id: '1')]
      end
    end
  end
end
