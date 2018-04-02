module Return3
    exposing
        ( Return
        , addCmd
        , addCmds
        , cmd
        , incorp
        , mapCmd
        , mapModel
        , mapReply
        , model
        , reply
        , withNoReply
        , withNothing
        , withReply
        , withTuple
        )

import Return2 as R2


type alias Return model msg reply =
    ( model, Cmd msg, Maybe reply )


withReply : reply -> ( model, Cmd msg ) -> Return model msg reply
withReply reply ( model, cmd ) =
    ( model, cmd, Just reply )


withNoReply : ( model, Cmd msg ) -> Return model msg reply
withNoReply ( model, cmd ) =
    ( model, cmd, Nothing )


withTuple : ( model, Cmd msg ) -> reply -> Return model msg reply
withTuple ( model, cmd ) reply =
    ( model, cmd, Just reply )


withNothing : model -> Return model msg reply
withNothing model =
    ( model, Cmd.none, Nothing )


model : Return model msg reply -> model
model ( model, _, _ ) =
    model


cmd : Return model msg reply -> Cmd msg
cmd ( _, cmd, _ ) =
    cmd


reply : Return model msg reply -> reply
reply ( _, _, reply ) =
    reply


addCmd : Cmd msg -> Return model msg reply -> Return model msg reply
addCmd newCmd ( model, cmd, reply ) =
    ( model, Cmd.batch [ newCmd, cmd ], reply )


addCmds : List (Cmd msg) -> Return model msg reply -> Return model msg reply
addCmds newCmds ( model, cmd, reply ) =
    ( model, Cmd.batch [ Cmd.batch newCmds, cmd ], reply )


mapModel : (a -> b) -> Return a msg reply -> Return b msg reply
mapModel f ( model, cmd, reply ) =
    ( f model, cmd, reply )


mapCmd : (a -> b) -> Return model a reply -> Return model b reply
mapCmd f ( model, cmd, reply ) =
    ( model, Cmd.map f cmd, reply )


mapReply : (Maybe reply -> Maybe reply) -> Return model cmd reply -> Return model cmd reply
mapReply f ( model, cmd, reply ) =
    ( model, cmd, f reply )


incorp : (subModel -> Maybe reply -> model -> ( model, Cmd msg )) -> model -> Return subModel msg reply -> ( model, Cmd msg )
incorp f model ( subModel, cmd, reply ) =
    f subModel reply model
        |> R2.addCmd cmd
