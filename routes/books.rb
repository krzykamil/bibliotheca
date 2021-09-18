# frozen_string_literal: true

class Bibliotheca
  # plugin :json

  hash_routes.on 'books' do |r|
    r.is do
      r.get do
        # TODO: add filters for attributes
        genres = "#{request.params["genre"]}".empty? ? DB.from(:books).select(:genre).map(:genre).uniq : "#{request.params["genre"]}"
        @books = Book.where(Sequel.lit('books.name ILIKE ? AND books.genre IN ?', "%#{request.params["search"]}%", genres)).eager_graph(:authors).map(&:to_hash)
        # @genres = @books.map(&:genre).uniq.compact
        # @genres_size = @genres.count
        response['Content-Type'] = 'application/json'
        @books.to_json
      end
    end
  end
end
