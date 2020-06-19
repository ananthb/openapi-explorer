module Components exposing
    ( activate
    , apiDoc
    , ariaExpanded
    , ariaLabel
    , index
    , navTree
    , role
    , serversModal
    )

import Api
import Html exposing (Attribute, Html, a, div, text)
import Html.Attributes as Attr exposing (attribute, class, href)
import Html.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)
import Markdown.Parser as Markdown
import Markdown.Renderer as MdRenderer
import RemoteData



-- HELPERS


role : String -> Attribute msg
role =
    attribute "role"


activate : Bool -> Attribute msg
activate active =
    Attr.classList [ ( "is-active", active ) ]


ariaLabel : String -> Attribute msg
ariaLabel =
    attribute "aria-label"


ariaExpanded : Bool -> Attribute msg
ariaExpanded b =
    attribute "aria-expanded" <|
        if b then
            "true"

        else
            "false"



-- NAV


navTree :
    Maybe String
    -> (Maybe String -> msg)
    -> Maybe String
    -> List Api.Entry
    -> List (Html msg)
navTree hoverGroup hovered parent =
    List.map
        (\e ->
            case e of
                Api.Directory name entries ->
                    navGroup hoverGroup hovered parent ( name, entries )

                Api.File title ->
                    navItem parent title
        )


navItem : Maybe String -> String -> Html msg
navItem grp title =
    let
        base =
            grp
                |> Maybe.map (\x -> "/" ++ x ++ "/")
                |> Maybe.withDefault "/"
    in
    a
        [ "/doc" ++ base ++ title |> Api.dropExtension |> href
        , class "navbar-item"
        ]
        [ title
            |> Api.dropExtension
            |> Api.reCase
            |> text
        ]


navGroup :
    Maybe String
    -> (Maybe String -> msg)
    -> Maybe String
    -> ( String, List Api.Entry )
    -> Html msg
navGroup hoverGroup hovered parent ( name, entries ) =
    let
        qualifiedName =
            case parent of
                Just p ->
                    p ++ "/" ++ name

                Nothing ->
                    name

        active =
            case hoverGroup of
                Just h ->
                    h == qualifiedName

                Nothing ->
                    False
    in
    div
        [ class "navbar-item has-dropdown"
        , activate active
        , onMouseEnter (hovered (Just qualifiedName))
        , onMouseLeave (hovered Nothing)
        ]
        [ a
            [ class "navbar-link"
            , role "button"
            , "/" ++ qualifiedName |> href
            ]
            [ name |> Api.reCase >> text ]
        , div
            [ class "navbar-dropdown" ]
            (navTree hoverGroup hovered (Just name) entries)
        ]



--SERVERS


type alias ServersModal msg =
    { active : Bool
    , modalClosed : msg
    , inputValue : Maybe String
    , servers : Api.Servers
    , inputChanged : String -> msg
    , serverAdded : msg
    , serversCleared : msg
    }


serversModal : ServersModal msg -> Html msg
serversModal m =
    let
        serversBlocks =
            List.map serverField m.servers
    in
    div
        [ class "modal", activate m.active ]
        [ div [ class "modal-background", onClick m.modalClosed ] []
        , Html.form
            [ class "modal-card"
            , ariaLabel "Add API servers"
            , Events.onSubmit m.serverAdded
            ]
            [ Html.header
                [ class "modal-card-head" ]
                [ Html.p [ class "modal-card-title" ] [ text "API Servers" ]
                , Html.button
                    [ class "delete"
                    , ariaLabel "close"
                    , role "button"
                    , Attr.type_ "button"
                    , onClick m.modalClosed
                    ]
                    []
                ]
            , Html.section
                [ class "modal-card-body" ]
                [ addServerField m.inputValue m.inputChanged
                , div
                    [ class "field is-horizontal" ]
                    [ div
                        [ class "field-label is-normal" ]
                        [ Html.label [ class "label" ] [ text "Servers" ] ]
                    , div
                        [ class "field-body" ]
                        [ div
                            [ class "field" ]
                            (List.map serverField m.servers)
                        ]
                    ]
                ]
            , Html.footer
                [ class "modal-card-foot" ]
                (serversButtons m.serversCleared)
            ]
        ]


addServerField : Maybe String -> (String -> msg) -> Html msg
addServerField currentVal changed =
    div [ class "field is-horizontal" ]
        [ div [ class "field-label is-normal" ]
            [ Html.label [ class "label" ] [ text "URL" ] ]
        , div [ class "field-body" ]
            [ div [ class "field" ]
                [ div
                    [ class "control" ]
                    [ Html.input
                        [ class "input"
                        , Attr.type_ "text"
                        , Attr.placeholder "Server URL with scheme"
                        , Attr.pattern "^\\s*http(s?):\\/\\/.*"
                        , Attr.required True
                        , Attr.value <| Maybe.withDefault "" currentVal
                        , Events.onInput changed
                        ]
                        []
                    ]
                ]
            ]
        ]


serversButtons : msg -> List (Html msg)
serversButtons cleared =
    [ Html.button
        [ class "button is-primary"
        , Attr.type_ "submit"
        ]
        [ text "Add" ]
    , Html.button
        [ class "button is-danger is-outlined"
        , role "button"
        , Attr.type_ "button"
        , onClick cleared
        ]
        [ text "Clear" ]
    ]


serverField : String -> Html msg
serverField url =
    div
        [ class "control has-icons-left" ]
        [ Html.input
            [ class "input is-static"
            , attribute "readonly" ""
            , Attr.value url
            ]
            []
        , Html.span
            [ class "icon is-left" ]
            [ text "🖥" ]
        ]



-- INDEX


index : Api.IndexData -> Html msg
index idx =
    case idx of
        RemoteData.NotAsked ->
            text "not asked"

        RemoteData.Loading ->
            text "loading"

        RemoteData.Failure _ ->
            text "failure"

        RemoteData.Success data ->
            Html.section
                [ class "section" ]
                [ div
                    [ class "container" ]
                    [ markdown data ]
                ]


markdown : String -> Html msg
markdown marked =
    case
        marked
            |> Markdown.parse
            |> Result.mapError deadEndsToString
            |> Result.andThen
                (\ast -> MdRenderer.render MdRenderer.defaultHtmlRenderer ast)
    of
        Ok rendered ->
            Html.article [ class "content" ] rendered

        Err errors ->
            Html.text errors


deadEndsToString deadEnds =
    deadEnds
        |> List.map Markdown.deadEndToString
        |> String.join "\n"



-- DOC


apiDoc : Api.Servers -> String -> Html msg
apiDoc servers api =
    let
        urls =
            List.map (attribute "server-url") servers

        attrs =
            (api ++ ".yaml" |> attribute "spec-url")
                :: attribute "show-header" "false"
                :: attribute "theme" "dark"
                :: urls
    in
    Html.node "rapi-doc" attrs []
