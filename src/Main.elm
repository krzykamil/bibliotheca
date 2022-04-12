
module Main exposing (main, view, update)

import Browser
import Json.Decode as Json
import Http
import Json.Decode as JD exposing (field, Decoder, int, string, maybe)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Events as Events
import Html exposing (Html)
import Html.Attributes


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

init : () ->  (Model, Cmd Msg )
init _ =
  ( Loading, getBooks )

-- UPDATE

type Msg
  = GotBooks ( Result Http.Error (List Book) )

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    GotBooks result ->
      case result of
        Ok fullBooks ->

          ( Success fullBooks, Cmd.none )

        Err e ->
            Debug.log( String.concat([ "Stuff", Debug.toString(e), " wahterver messages" ]) )
          ( Failure, Cmd.none )
-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

-- VIEW

booksTable : (List Book) -> Element msg
booksTable books =
    column
        [ width <| maximum 1300 fill
        , height <| maximum 800 fill
        , centerX
        , spacing 10
        , padding 10
        , scrollbarY
        , Border.width 2
        , Border.rounded 6
        , Border.color colors.blue
        ]
        [ row [ width (maximum 1300 fill) ] [
            Element.table
                [ centerX
                , scrollbarY
                , spacing 10
                , padding 5
                ]
                { data = books
                , columns =
                    [ { header = el (((width (fill |> maximum 345 |> minimum 345)) :: headerAttrs)) <|  ( Element.text "Name" )
                      , width = Element.shrink
                      , view =
                            \book ->
                                el (cellAttrs 345 345) <| Element.text book.name
                      }
                    , { header = el (((width (fill |> maximum 170 |> minimum 170)) :: headerAttrs)) <|  ( Element.text "Genre" )
                      , width = Element.shrink
                      , view =
                            \book ->
                                el (cellAttrs 170 170) <| Element.text book.genre
                      }
                      , { header = el (((width (fill |> maximum 170 |> minimum 170)) :: headerAttrs)) <|  ( Element.text "Subcategory" )
                        , width = Element.shrink
                        , view =
                              \book ->
                                  el (cellAttrs 170 170) <| Element.text (Maybe.withDefault "" book.subcategory)
                        }
                      , { header = el (((width (fill |> maximum 340 |> minimum 340)) :: headerAttrs)) <|  ( Element.text "Note" )
                        , width = Element.shrink
                        , view =
                              \book ->
                                  el (cellAttrs 340 340) <| Element.text (Maybe.withDefault "" book.note)
                        }
                      , { header = el (((width (fill |> maximum 90 |> minimum 90)) :: headerAttrs)) <|  ( Element.text "Shelf" )
                        , width = Element.shrink
                        , view =
                              \book ->
                                  el (cellAttrs 90 90) <| Element.text (String.fromInt book.rack)
                        }
                      , { header = el (((width (fill |> maximum 90 |> minimum 90)) :: headerAttrs)) <|  ( Element.text "Rack" )
                        , width = Element.shrink
                        , view =
                              \book ->
                                  el (cellAttrs 90 90) <| Element.text (String.fromInt book.shelf)
                        }
                      ]
                      }]
        ]

cellAttrs : Int -> Int -> List(Attr () msg)
cellAttrs max min =
    [ Font.color colors.darkCharcoal
    , padding 10
    , height fill
    , width (fill |> maximum max |> minimum min)
    , clipX
    , mouseOver [ Background.color (rgb 0 1 0) ]
    ]

sayHi = Debug.log( "hi" )

headerAttrs =
    [ centerX
    , centerY
    , Font.bold
    , Font.color colors.darkCharcoal
    , Border.widthEach { bottom = 2, top = 0, left = 0, right = 0 }
    , Border.color colors.blue
    ]


view : Model -> Html Msg
view model =
  case model of
    Failure ->
        main_layout (el [] ( text "I was unable to load your book." ))
    Loading ->
        main_layout (el [] ( text "Loading..." ))
    Success fullBooks ->
        main_layout (booksTable fullBooks)

main_layout : Element msg -> Html msg
main_layout state_layout = layout [ Background.color (colors.lightGrey)
                                   , width fill
                                   , height fill
                                   , padding 50
                                   ] <|
                                   column
                                     [ width fill
                                     , spacing 10
                                     , height fill
                                     ]
                                     [ header
                                     , state_layout
                                     , footer
                                     ]

header : Element msg
header = row [ paddingXY 20 10
             , width fill
             ]
             [ text "Bibliotheca"
             , el [ alignRight ] ( text "MenuButton" )
             ]

footer : Element msg
footer = text "Footer"

colors =
    { blue = rgb255 0x72 0x9F 0xCF
    , darkCharcoal = rgb255 0x2E 0x34 0x36
    , green = rgb255 0x20 0xBF 0x55
    , lightBlue = rgb255 0xC5 0xE8 0xF7
    , lightGrey = rgb255 0xE0 0xE0 0xE0
    , orange = rgb255 0xF2 0x64 0x19
    , red = rgb255 0xAA 0x00 0x00
    , white = rgb255 0xFF 0xFF 0xFF
    }

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



