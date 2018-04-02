module Return2
    exposing
        ( addCmd
        , addCmds
        , cmd
        , incorp
        , mapCmd
        , mapModel
        , model
        , withCmd
        , withCmds
        , withModel
        , withNoCmd
        )


withCmd : Cmd msg -> model -> ( model, Cmd msg )
withCmd cmd model =
    ( model, cmd )


withCmds : List (Cmd msg) -> model -> ( model, Cmd msg )
withCmds cmds model =
    ( model, Cmd.batch cmds )


withModel : model -> Cmd msg -> ( model, Cmd msg )
withModel =
    (,)


addCmd : Cmd msg -> ( model, Cmd msg ) -> ( model, Cmd msg )
addCmd newCmd ( model, cmd ) =
    ( model, Cmd.batch [ newCmd, cmd ] )


addCmds : List (Cmd msg) -> ( model, Cmd msg ) -> ( model, Cmd msg )
addCmds newCmds ( model, cmd ) =
    ( model, Cmd.batch [ Cmd.batch newCmds, cmd ] )


withNoCmd : model -> ( model, Cmd msg )
withNoCmd model =
    ( model, Cmd.none )


model : ( model, Cmd msg )
model =
    Tuple.first


cmd : ( model, Cmd msg )
cmd =
    Tuple.second


mapCmd : (a -> b) -> ( model, Cmd a ) -> ( model, Cmd b )
mapCmd f =
    Tuple.mapSecond (Cmd.map f)


mapModel : (a -> b) -> ( a, Cmd msg ) -> ( b, Cmd msg )
mapModel =
    Tuple.mapFirst


incorp : model -> (subModel -> model -> model) -> ( subModel, Cmd msg ) -> ( model, Cmd msg )
incorp model f ( subModel, cmd ) =
    ( f subModel model, cmd )
