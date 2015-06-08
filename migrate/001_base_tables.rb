Sequel.migration do
  change do
    create_table(:books) do
      primary_key :id
      String :genre
      String :subcategory
      String :note
      String :name, null: false
      Integer :shelf
      Integer :rack
      Boolean :comic_book
    end
    create_table(:authors) do
      primary_key :id
      String :name, null: false
    end
  end
end
