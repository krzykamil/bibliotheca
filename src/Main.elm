port module Main exposing (..)

{-| Book searching implemented in Elm, using plain HTML and CSS for rendering.
This application is broken up into three key parts:
  1. Model  - a full definition of the application's state
  2. Update - a way to step the application state forward
  3. View   - a way to visualize our application state with HTML
-}

import Browser
import Browser.Dom as Dom
import Html exposing (..)
import Html exposing (text, pre)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy, lazy2)
import Json.Decode as Json
import Task
import Http


main : Program (Maybe Model) Model Msg
main =
    Browser.document
        { init = init
        , view = \model -> { title = "Bibliotheca • Books", body = [view model] }
        , update = updateWithApi
        , subscriptions = \_ -> Sub.none
        }

port getFromApi : Model -> Cmd msg

{-| We want to `getFromApi` on every update. This function adds the getFromApi
command for every step of the update function.
-}
updateWithApi : Msg -> Model -> ( Model, Cmd Msg )
updateWithApi msg model =
    let
        ( newModel, cmds ) =
            update msg model
    in
        ( newModel
        , Cmd.batch [ getFromApi newModel, cmds ]
        )

-- MODEL

-- The full application state of our app.
type alias Model =
    { books : List Book
    , field : String
    , uid : Int
    , visibility : String
    }

type alias Book =
    { description : String
    , completed : Bool
    , editing : Bool
    , id : Int
    }

emptyModel : Model
emptyModel =
    { books = []
    , visibility = "All"
    , field = ""
    , uid = 0
    }

newBook : String -> Int -> Book
newBook desc id =
    { description = desc
    , completed = False
    , editing = False
    , id = id
    }

init : Maybe Model -> (Model, Cmd Msg)
init maybeModel =
  ( Loading
  , Http.get
      { url = "https://elm-lang.org/assets/public-opinion.txt"
      , expect = Http.expectString GotText
      }
  )

--init : Maybe Model -> ( Model, Cmd Msg )
--init maybeModel =
--  ( Maybe.withDefault emptyModel maybeModel
--  , Cmd.none
--  )

-- UPDATE

{-| Users of our app can trigger messages by clicking and typing. These
messages are fed into the `update` function as they occur, letting us react
to them.
-}
type Msg
    = NoOp
    | UpdateField String
    | EditingBook Int Bool
    | UpdateBook Int String
    | Add
    | Delete Int
    | DeleteComplete
    | Check Int Bool
    | CheckAll Bool
    | ChangeVisibility String
    | Loading String
    | GotText (Result Http.Error String)

-- How we update our Model on a given Msg?
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Add ->
            ( { model
                | uid = model.uid + 1
                , field = ""
                , books =
                    if String.isEmpty model.field then
                        model.books
                    else
                        model.books ++ [ newBook model.field model.uid ]
              }
            , Cmd.none
            )

        UpdateField str ->
            ( { model | field = str }
            , Cmd.none
            )

        EditingBook id isEditing ->
            let
                updateBook t =
                    if t.id == id then
                        { t | editing = isEditing }
                    else
                        t

                focus =
                    Dom.focus ("book-" ++ String.fromInt id)
            in
            ( { model | books = List.map updateBook model.books }
            , Task.attempt (\_ -> NoOp) focus
            )

        UpdateBook id task ->
            let
                updateBook t =
                    if t.id == id then
                        { t | description = task }
                    else
                        t
            in
            ( { model | books = List.map updateBook model.books }
            , Cmd.none
            )

        Delete id ->
            ( { model | books = List.filter (\t -> t.id /= id) model.books }
            , Cmd.none
            )

        DeleteComplete ->
            ( { model | books = List.filter (not << .completed) model.books }
            , Cmd.none
            )

        Check id isCompleted ->
            let
                updateBook t =
                    if t.id == id then
                        { t | completed = isCompleted }
                    else
                        t
            in
            ( { model | books = List.map updateBook model.books }
            , Cmd.none
            )

        CheckAll isCompleted ->
            let
                updateBook t =
                    { t | completed = isCompleted }
            in
            ( { model | books = List.map updateBook model.books }
            , Cmd.none
            )

        ChangeVisibility visibility ->
            ( { model | visibility = visibility }
            , Cmd.none
            )

-- VIEW

view : Model -> Html Msg
view model =
    case model of
        Loading ->
            text "Loading..."

        else
            div
                [ class "books-wrapper"
                , style "visibility" "hidden"
                ]
                [ section
                    [ class "bibliotheca-app" ]
                    [ lazy viewInput model.field
                    , lazy2 viewBooks model.visibility model.books
                    , lazy2 viewControls model.visibility model.books
                    ]
                , infoFooter
                ]


viewInput : String -> Html Msg
viewInput task =
    header
        [ class "header" ]
        [ h1 [] [ text "Bibliotheca - Books" ]
        , input
            [ class "search"
            , placeholder "Type to search by any attribute or author"
            , autofocus True
            , value task
            , name "search"
            , onInput UpdateField
            , onEnter Add
            ]
            []
        ]


onEnter : Msg -> Attribute Msg
onEnter msg =
    let
        isEnter code =
            if code == 13 then
                Json.succeed msg
            else
                Json.fail "not ENTER"
    in
        on "keydown" (Json.andThen isEnter keyCode)

-- VIEW ALL Books

viewBooks : String -> List Book -> Html Msg
viewBooks visibility books =
    let
        isVisible book =
            case visibility of
                "Completed" ->
                    book.completed

                "Active" ->
                    not book.completed

                _ ->
                    True

        allCompleted =
            List.all .completed books

        cssVisibility =
            if List.isEmpty books then
                "hidden"
            else
                "visible"
    in
        section
            [ class "main"
            , style "visibility" cssVisibility
            ]
            [ input
                [ class "toggle-all"
                , type_ "checkbox"
                , name "toggle"
                , checked allCompleted
                , onClick (CheckAll (not allCompleted))
                ]
                []
            , label
                [ for "toggle-all" ]
                [ text "Mark all as complete" ]
            , Keyed.ul [ class "book-list" ] <|
                List.map viewKeyedBook (List.filter isVisible books)
            ]

-- VIEW INDIVIDUAL Books

viewKeyedBook : Book -> ( String, Html Msg )
viewKeyedBook book =
    ( String.fromInt book.id, lazy viewBook book )

viewBook : Book -> Html Msg
viewBook book =
    li
        [ classList [ ( "completed", book.completed ), ( "editing", book.editing ) ] ]
        [ div
            [ class "view" ]
            [ input
                [ class "toggle"
                , type_ "checkbox"
                , checked book.completed
                , onClick (Check book.id (not book.completed))
                ]
                []
            , label
                [ onDoubleClick (EditingBook book.id True) ]
                [ text book.description ]
            , button
                [ class "destroy"
                , onClick (Delete book.id)
                ]
                []
            ]
        , input
            [ class "edit"
            , value book.description
            , name "title"
            , id ("book-" ++ String.fromInt book.id)
            , onInput (UpdateBook book.id)
            , onBlur (EditingBook book.id False)
            , onEnter (EditingBook book.id False)
            ]
            []
        ]

-- VIEW CONTROLS AND FOOTER

viewControls : String -> List Book -> Html Msg
viewControls visibility books =
    let
        booksCompleted =
            List.length (List.filter .completed books)

        booksLeft =
            List.length books - booksCompleted
    in
        footer
            [ class "footer"
            , hidden (List.isEmpty books)
            ]
            [ lazy viewControlsCount booksLeft
            , lazy viewControlsFilters visibility
            , lazy viewControlsClear booksCompleted
            ]


viewControlsCount : Int -> Html Msg
viewControlsCount booksLeft =
    let
        item_ =
            if booksLeft == 1 then
                " item"
            else
                " items"
    in
        span
            [ class "books-count" ]
            [ strong [] [ text (String.fromInt booksLeft) ]
            , text (item_ ++ " left")
            ]


viewControlsFilters : String -> Html Msg
viewControlsFilters visibility =
    ul
        [ class "filters" ]
        [ visibilitySwap "#/" "All" visibility
        , text " "
        , visibilitySwap "#/active" "Active" visibility
        , text " "
        , visibilitySwap "#/completed" "Completed" visibility
        ]


visibilitySwap : String -> String -> String -> Html Msg
visibilitySwap uri visibility actualVisibility =
    li
        [ onClick (ChangeVisibility visibility) ]
        [ a [ href uri, classList [ ( "selected", visibility == actualVisibility ) ] ]
            [ text visibility ]
        ]


viewControlsClear : Int -> Html Msg
viewControlsClear booksCompleted =
    button
        [ class "clear-completed"
        , hidden (booksCompleted == 0)
        , onClick DeleteComplete
        ]
        [ text ("Clear completed (" ++ String.fromInt booksCompleted ++ ")")
        ]


infoFooter : Html msg
infoFooter =
    footer [ class "info" ]
        [ p [] [ text "Search engine for my library" ]
        , p []
            [ text "Written by "
            , a [ href "https://github.com/krzykamil" ] [ text "Krzyszof Piotrowski" ]
            ]
        ]
