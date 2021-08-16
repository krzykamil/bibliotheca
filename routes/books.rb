require 'forme'
class Bibliotheca
  hash_routes.on 'books' do |r|

    set_view_subdir 'books'
    r.is do
      r.get do
        #TODO add filters for attributes

        @books = Book.where(Sequel.lit('books.name ILIKE ?', "%#{request.params["search"]}%")).eager_graph(:authors)
        @genres = @books.map(:genre).uniq.compact
        @books = @books.all
        @genres_size = @genres.count
        view("index")
      end
    end
  end
end
