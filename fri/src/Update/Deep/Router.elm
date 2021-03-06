module Update.Deep.Router exposing (Msg(..), State, component, init, redirect, setRoute, update)

import Browser exposing (UrlRequest)
import Browser.Navigation as Navigation
import Update.Deep exposing (..)
import Url exposing (Url)


type Msg
    = UrlChange Url
    | UrlRequest UrlRequest


type alias State route =
    { route : Maybe route
    , key : Navigation.Key
    , fromUrl : Url -> Maybe route
    , basePath : String
    }


component : (Msg -> msg) -> Wrap { b | router : State route } msg (State route) Msg a
component msg =
    wrapState
        { get = .router
        , set = \state router -> { state | router = router }
        , msg = msg
        }


setRoute : Maybe route -> State route -> Update (State route) msg a
setRoute route state =
    save { state | route = route }


init : (Url -> Maybe route) -> String -> Navigation.Key -> Update (State route) msg a
init fromUrl basePath key =
    save State
        |> andMap (save Nothing)
        |> andMap (save key)
        |> andMap (save fromUrl)
        |> andMap (save basePath)


redirect : String -> State route -> Update (State route) msg a
redirect href state =
    state
        |> addCmd (Navigation.replaceUrl state.key (state.basePath ++ href))


update : { onRouteChange : Url -> Maybe route -> a } -> Msg -> State route -> Update (State route) Msg a
update { onRouteChange } msg state =
    let
        stripPathPrefix url =
            { url | path = String.dropLeft (String.length state.basePath) url.path }

        insertPathPrefix url =
            { url | path = state.basePath ++ url.path }
    in
    case msg of
        UrlChange url ->
            let
                route =
                    state.fromUrl (stripPathPrefix url)
            in
            state
                |> setRoute route
                |> andApplyCallback (onRouteChange url route)

        UrlRequest (Browser.Internal url) ->
            state
                |> addCmd (Navigation.pushUrl state.key (Url.toString (insertPathPrefix url)))

        UrlRequest (Browser.External "") ->
            state
                |> save

        UrlRequest (Browser.External href) ->
            state
                |> addCmd (Navigation.load href)
