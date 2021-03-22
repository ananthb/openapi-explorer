port module Api exposing
    ( Apis
    , Data
    , Entry(..)
    , IndexData
    , Servers
    , apisDecoder
    , directory
    , dropExtension
    , getApis
    , getIndex
    , reCase
    , saveServers
    , serversDecoder
    )

import Http
import Json.Decode as Decode exposing (Decoder, field, string)
import RemoteData



{- APIs directory -}


directory : String
directory =
    "apis"


dropExtension : String -> String
dropExtension =
    splitExtensions >> Tuple.first


splitExtensions : String -> ( String, String )
splitExtensions path =
    case String.split "." path of
        [] ->
            ( "", "" )

        [ a ] ->
            ( a, "" )

        x :: xs ->
            ( x, String.join "." xs )


{-| Convert a string from dash-case to title-case.

    reCase "foo-bar"
    -- "Foo Bar"

-}
reCase : String -> String
reCase =
    String.split "-"
        >> List.map (\w -> (String.left 1 w |> String.toUpper) ++ String.dropLeft 1 w)
        >> String.join " "



-- APIS


type alias Apis =
    { title : String
    , contents : List Entry
    }


type alias Data =
    RemoteData.WebData Apis


getApis : (Data -> msg) -> Cmd msg
getApis got =
    Http.get
        { url = directory ++ "/index.json"
        , expect =
            Http.expectJson
                (RemoteData.fromResult >> got)
                apisDecoder
        }


apisDecoder : Decoder Apis
apisDecoder =
    Decode.map2 Apis
        (field "title" string)
        (field "contents" (Decode.list entryDecoder))


type Entry
    = Directory String (List Entry)
    | File String


entryDecoder : Decoder Entry
entryDecoder =
    field "type" string
        |> Decode.andThen
            (\typ ->
                case typ of
                    "file" ->
                        Decode.map File
                            (field "name" string)

                    "directory" ->
                        Decode.map2 Directory
                            (field "name" string)
                            (field "contents" (Decode.list entryDecoder))

                    _ ->
                        Decode.fail <| typ ++ " is not a valid entry type"
            )



-- SERVERS


type alias Servers =
    List String


port saveServers : Servers -> Cmd msg


serversDecoder : Decoder Servers
serversDecoder =
    Decode.list Decode.string



-- INDEX


type alias IndexData =
    RemoteData.WebData String


getIndex : String -> (IndexData -> msg) -> Cmd msg
getIndex idx gotIdx =
    let
        indexFile =
            directory ++ "/README.md"
    in
    Http.get
        { url =
            if idx == "index" then
                "/" ++ indexFile

            else
                "/" ++ idx ++ "/" ++ indexFile
        , expect = Http.expectString (RemoteData.fromResult >> gotIdx)
        }
