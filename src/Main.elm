module Main exposing (main, view, update)

import Browser
import Json.Decode as Json
import Html exposing (Html, text, div, table, thead, tr, th, td, ul)
import Http
import Json.Decode as JD exposing (field, Decoder, int, string, maybe)

-- MAIN

main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }

-- MODEL

type Model
  = Failure
  | Loading
  | Success (List Book)

type alias Books =
    { books : List Book,
      pages : Int,
      current_page : Int
    }

type alias Book =
    { name: String,
      rack: Int,
      shelf: Int,
      genre: String,
      note: Maybe String,
      subcategory: Maybe String
    }

init : () -> (Model, Cmd Msg)
init _ =
  ( Loading, getBooks )

-- UPDATE

type Msg
  = GotBooks (Result Http.Error (List Book))

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    GotBooks result ->
      case result of
        Ok fullBooks ->

          (Success fullBooks, Cmd.none)

        Err e ->
            Debug.log(String.concat([ "Stuff", Debug.toString(e), " unread messages" ]))
          (Failure, Cmd.none)

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

-- VIEW

view : Model -> Html Msg
view model =
  case model of
    Failure ->
      text "I was unable to load your book."

    Loading ->
      text "Loading..."

    Success fullBooks ->
        table
                []
                ([ thead []
                    [ th [] [ text "Name" ]
                    , th [] [ text "Rack" ]
                    , th [] [ text "Shelf" ]
                    , th [] [ text "Genre" ]
                    , th [] [ text "Sub Genre" ]
                    , th [] [ text "Note" ]
                    ]
                 ]
                    ++ List.map toTableRow fullBooks
                )
toTableRow : Book -> Html Msg
toTableRow book =
  tr []
     [
     td[][text book.name],
     td[][text (String.fromInt book.rack) ],
     td[][text (String.fromInt book.shelf) ],
     td[][text book.genre ],
     td[][text (Maybe.withDefault "" book.subcategory) ],
     td[][text (Maybe.withDefault "" book.note) ]
     ]

-- HTTP

getBooks : Cmd Msg
getBooks =
    Http.get
    { url = "http://localhost:9292/books"
    , expect = Http.expectJson GotBooks booksListDecoder
    }

bookDecoder : Decoder Book
bookDecoder =
    JD.map6 Book
        (field "name" string)
        (field "rack" int)
        (field "shelf" int)
        (field "genre" string)
        (maybe (field "note" string))
        (maybe (field "subcategory" string))

booksListDecoder : Decoder (List Book)
booksListDecoder =
    JD.list bookDecoder



