module Main exposing (..)

import Api
import Browser
import Browser.Navigation as Nav
import Components exposing (activate, ariaLabel, role)
import Html exposing (Html, a, div, text)
import Html.Attributes exposing (attribute, class, href, id)
import Html.Events
import Json.Decode
import Json.Encode as Encode
import RemoteData
import Url
import Url.Parser as Parser exposing ((</>), Parser)



-- MAIN


main : Program Encode.Value Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }



-- MODEL


type alias Model =
    { key : Nav.Key
    , burger : Bool
    , hoveredGroup : Maybe String
    , serverInput : Maybe String
    , servers : Api.Servers
    , serversModalOpen : Bool
    , page : Page
    , apiData : Api.Data
    , index : Api.IndexData
    }


type Page
    = Index String
    | Doc (List String)
    | NotFound


routes : Parser (Page -> Page) Page
routes =
    Parser.oneOf
        [ Parser.map (Index "index") Parser.top
        , Parser.map Index Parser.string
        , Parser.map Doc (Parser.s "doc" </> limitedRemainder 10)
        ]


limitedRemainder : Int -> Parser (List String -> a) a
limitedRemainder maxDepth =
    if maxDepth < 1 then
        Parser.map [] Parser.top

    else
        Parser.oneOf
            [ Parser.map [] Parser.top
            , Parser.map
                (\str li -> str :: li)
                (Parser.string </> limitedRemainder_ (maxDepth - 1))
            ]


limitedRemainder_ : Int -> Parser (List String -> a) a
limitedRemainder_ maxDepth =
    if maxDepth < 1 then
        Parser.map [] Parser.top

    else
        Parser.oneOf
            [ Parser.map [] Parser.top
            , Parser.map
                (\str li -> str :: li)
                (Parser.string </> limitedRemainder (maxDepth - 1))
            ]


stepUrl : Model -> Url.Url -> ( Model, Cmd Msg )
stepUrl model url =
    let
        page =
            Maybe.withDefault NotFound (Parser.parse routes url)

        ( ix, cmd ) =
            case page of
                Index idx ->
                    ( RemoteData.Loading
                    , Api.getIndex idx GotIndex
                    )

                _ ->
                    ( RemoteData.NotAsked, Cmd.none )
    in
    ( { model | page = page, burger = False, index = ix }, cmd )


init : Encode.Value -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        servers =
            Json.Decode.decodeValue Api.serversDecoder flags
                |> Result.withDefault []

        initialModel =
            { key = key
            , burger = False
            , hoveredGroup = Nothing
            , serverInput = Nothing
            , servers = servers
            , serversModalOpen = False
            , page = NotFound
            , apiData = RemoteData.Loading
            , index = RemoteData.NotAsked
            }

        ( model, cmd ) =
            stepUrl initialModel url
    in
    ( model
    , Cmd.batch
        [ Api.getApis GotApis
        , cmd
        ]
    )



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | BurgerClicked Bool
    | GroupHovered (Maybe String)
    | ServerInputChanged String
    | ServerAdded
    | ServersCleared
    | ServersModalToggled Bool
    | GotApis Api.Data
    | GotIndex Api.IndexData


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            stepUrl model url

        BurgerClicked b ->
            ( { model | burger = b }, Cmd.none )

        GroupHovered group ->
            ( { model | hoveredGroup = group }, Cmd.none )

        ServerInputChanged i ->
            let
                input =
                    if i == "" then
                        Nothing

                    else
                        Just i
            in
            ( { model | serverInput = input }, Cmd.none )

        ServerAdded ->
            let
                servers =
                    case model.serverInput of
                        Just s ->
                            s :: model.servers

                        Nothing ->
                            model.servers
            in
            ( { model
                | serverInput = Nothing
                , servers = servers
              }
            , Api.saveServers servers
            )

        ServersCleared ->
            ( { model | servers = [] }, Api.saveServers [] )

        ServersModalToggled b ->
            ( { model | serversModalOpen = b }, Cmd.none )

        GotApis data ->
            ( { model | apiData = data }, Cmd.none )

        GotIndex idx ->
            ( { model | index = idx }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
    model.apiData
        |> RemoteData.map (viewApis model)
        |> RemoteData.withDefault
            { title = "error", body = [ text "error loading apis.json" ] }


viewApis : Model -> Api.Apis -> Browser.Document Msg
viewApis model apis =
    let
        ( title, page ) =
            viewPage model

        modal =
            Components.serversModal
                { active = model.serversModalOpen
                , modalClosed = ServersModalToggled False
                , inputValue = model.serverInput
                , servers = model.servers
                , inputChanged = ServerInputChanged
                , serverAdded = ServerAdded
                , serversCleared = ServersCleared
                }
    in
    { title = title ++ apis.title
    , body =
        [ viewNav apis model
        , Html.main_ [] [ page ]
        , modal
        ]
    }


viewNav : Api.Apis -> Model -> Html Msg
viewNav apis { burger, page, hoveredGroup, serversModalOpen } =
    let
        burgerAttrs =
            [ href "#"
            , class "navbar-burger burger"
            , role "button"
            , ariaLabel "menu"
            , attribute "aria-controls" "menu"
            , attribute "aria-haspopup" "true"
            , Components.ariaExpanded burger
            , not burger |> BurgerClicked |> Html.Events.onClick
            , activate burger
            ]

        spans =
            Html.span [ attribute "aria-hidden" "true" ] [] |> List.repeat 3
    in
    Html.nav
        [ class "navbar is-dark"
        , role "navigation"
        , ariaLabel "main navigation"
        ]
        [ div
            [ class "navbar-brand" ]
            [ a
                [ class "navbar-item", href "/" ]
                [ text apis.title ]
            , a burgerAttrs spans
            ]
        , div
            [ id "menu", class "navbar-menu", activate burger ]
            [ div
                [ class "navbar-start" ]
                (Components.navTree hoveredGroup GroupHovered Nothing apis.contents)
            , div
                [ class "navbar-end" ]
                [ div
                    [ class "navbar-item" ]
                    [ Html.button
                        [ class "button is-link"
                        , not serversModalOpen
                            |> ServersModalToggled
                            |> Html.Events.onClick
                        ]
                        [ text "API Servers" ]
                    ]
                ]
            ]
        ]


viewPage : Model -> ( String, Html Msg )
viewPage model =
    case model.page of
        Index _ ->
            ( "OpenAPI Explorer "
            , Components.index model.index
            )

        Doc path ->
            path
                |> List.foldl
                    (\x acc ->
                        Tuple.mapBoth
                            (\a -> Api.reCase x ++ " | " ++ a)
                            (\b -> b ++ "/" ++ x)
                            acc
                    )
                    ( "", "" )
                |> Tuple.mapSecond (Components.apiDoc model.servers)

        NotFound ->
            ( "not found", text "" )
