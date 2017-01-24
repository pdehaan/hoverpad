port module Main exposing (..)

import Time
import Html
import Html.Attributes
import Html.Events
import Json.Decode
import Json.Encode


-- Model


type Msg
    = NewEmail String
    | NewPassphrase String
    | NewData String
    | NewError String
    | GetData
    | Lock
    | SetData String
    | DataSaved String
    | DataNotSaved String
    | UnStored Time.Time
    | BlurSelection


type alias Model =
    { lock : Bool
    , email : String
    , passphrase : String
    , content : String
    , stored : Bool
    , error : String
    }


init : ( Model, Cmd msg )
init =
    Model True "" "" "" False "" ! []



-- Handle contenteditable events


innerHtmlDecoder =
    Json.Decode.at [ "target", "innerHtml" ] Json.Decode.string



-- Update


update : Msg -> Model -> ( Model, Cmd msg )
update message model =
    case message of
        UnStored time ->
            { model | stored = False } ! []

        NewEmail email ->
            { model | email = email } ! []

        NewPassphrase passphrase ->
            { model | passphrase = passphrase } ! []

        GetData ->
            { model | error = "" } ! [ getData (model.email ++ "," ++ model.passphrase) ]

        BlurSelection ->
            model ! [ blurSelection "" ]

        NewData content ->
            { model | content = content, lock = False } ! []

        NewError error ->
            { model | lock = True, content = "", passphrase = "", error = "Wrong passphrase" } ! []

        Lock ->
            { model | lock = True, content = "", passphrase = "" } ! []

        SetData content ->
            { model | content = content } ! [ setData content ]

        DataSaved _ ->
            { model | stored = True } ! []

        DataNotSaved error ->
            { model | error = (Debug.log "" error) } ! []



-- View


formView : Model -> Html.Html Msg
formView model =
    Html.div
        [ Html.Attributes.class <|
            if model.lock then
                "form"
            else
                "hidden"
        ]
        [ Html.div []
            [ Html.text model.error ]
        , Html.div []
            [ Html.label [ Html.Attributes.for "email" ] [ Html.text "Email" ]
            , Html.input
                [ Html.Attributes.id "email"
                , Html.Attributes.type_ "text"
                , Html.Attributes.placeholder "joe.bart@team.tld"
                , Html.Attributes.value model.email
                , Html.Events.onInput NewEmail
                ]
                []
            ]
        , Html.div []
            [ Html.label [ Html.Attributes.for "password" ] [ Html.text "Passphrase" ]
            , Html.input
                [ Html.Attributes.id "password"
                , Html.Attributes.type_ "password"
                , Html.Attributes.placeholder "Passphrase"
                , Html.Attributes.value model.passphrase
                , Html.Events.onInput NewPassphrase
                ]
                []
            ]
        , Html.div []
            [ Html.button
                [ Html.Events.onClick GetData ]
                [ Html.text "Login and unlock" ]
            ]
        ]


controlBar : Model -> Html.Html Msg
controlBar mode =
    Html.div
        [ Html.Attributes.class "control-bar"
        , Html.Events.onClick BlurSelection
        ]
        [ Html.button [ Html.Attributes.id "sel" ] [ Html.text "Blur selection" ] ]


padView : Model -> Html.Html Msg
padView model =
    Html.div
        [ Html.Attributes.class <|
            if model.lock then
                "hidden"
            else
                "pad"
        ]
        [ controlBar model
        , Html.div
            [ Html.Attributes.class <|
                if model.stored then
                    "stored"
                else
                    ""
            , Html.Attributes.contenteditable True
            , Html.Attributes.property "innerHTML" (Json.Encode.string model.content)
            ]
            []
        ]


view : Model -> Html.Html Msg
view model =
    let
        title =
            case model.lock of
                True ->
                    "Universal Notepad"

                False ->
                    model.email
    in
        Html.div [ Html.Attributes.class "outer-wrapper" ]
            [ Html.h1 [] [ Html.text title ]
            , Html.a
                [ Html.Attributes.id "lock"
                , Html.Attributes.href "#"
                , Html.Attributes.class <|
                    if model.lock then
                        "hidden"
                    else
                        ""
                , Html.Events.onClick Lock
                ]
                [ Html.text "Lock" ]
            , formView model
            , padView model
            , Html.span [] [ Html.text "Available everywhere with your Email and Passphrase!" ]
            ]



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ newData NewData
        , newError NewError
        , dataSaved DataSaved
        , dataNotSaved DataNotSaved
        , input SetData
        , Time.every (Time.millisecond * 200) UnStored
        ]



-- Main


main =
    Html.program
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }



-- Ports


port getData : String -> Cmd msg


port newData : (String -> msg) -> Sub msg


port newError : (String -> msg) -> Sub msg


port setData : String -> Cmd msg


port dataSaved : (String -> msg) -> Sub msg


port dataNotSaved : (String -> msg) -> Sub msg


port input : (String -> msg) -> Sub msg


port blurSelection : String -> Cmd msg
