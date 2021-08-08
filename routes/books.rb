require 'forme'
class Bibliotheca
  hash_routes.on 'books' do |r|

    set_view_subdir 'books'
    r.is do
      r.get do
        @books = Book.eager(:authors).order(:name)
        @books = @books.where(Sequel.ilike(:name, "%#{request.params["search"]}%"))
        view("index")
      end
    end
  end
end
