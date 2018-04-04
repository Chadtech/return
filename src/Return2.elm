module Return2
    exposing
        ( addCmd
        , addCmds
        , cmd
        , mapCmd
        , mapModel
        , model
        , withCmd
        , withCmds
        , withModel
        , withNoCmd
        )

{-| This package makes it easier to build `(module, Cmd msg)`, the typical result of an update function


# With

@docs withCmd, withCmds, withNoCmd, withModel


# Add

@docs addCmd, addCmds


# Map

@docs mapModel, mapCmd


# Get

@docs model, cmd

-}


{-| Pack a cmd with your model

    model
        |> withCmd cmd

-}
withCmd : Cmd msg -> model -> ( model, Cmd msg )
withCmd cmd model =
    ( model, cmd )


{-| Pack multiple cmds with your model

    model
        |> withCmds [ cmd0, cmd1 ]

-}
withCmds : List (Cmd msg) -> model -> ( model, Cmd msg )
withCmds cmds model =
    ( model, Cmd.batch cmds )


{-| Pack a model with your cmd. This is useful if the business logic for your command is more complicated than the business logic for your model

    Close ->
        model.sessionId
            |> Ports.Close
            |> Ports.send
            |> withModel model

-}
withModel : model -> Cmd msg -> ( model, Cmd msg )
withModel =
    (,)


{-| Pack your model with no cmd

    model
        |> withNoCmd

-}
withNoCmd : model -> ( model, Cmd msg )
withNoCmd model =
    ( model, Cmd.none )


{-| Sometimes you need to add a cmd to an already packaged model and cmd.

    (model, cmd0)
        |> addCmd cmd1

        -- == (model, Cmd.batch [ cmd1, cmd0 ])

-}
addCmd : Cmd msg -> ( model, Cmd msg ) -> ( model, Cmd msg )
addCmd newCmd ( model, cmd ) =
    ( model, Cmd.batch [ newCmd, cmd ] )


{-| Add many cmds to an already packaged model and cmd.

    (model, cmd0)
        |> addCmds [ cmd1, cmd2 ]

        -- == (model, Cmd.batch [ cmd0, cmd1, cmd2 ])

-}
addCmds : List (Cmd msg) -> ( model, Cmd msg ) -> ( model, Cmd msg )
addCmds newCmds ( model, cmd ) =
    ( model, Cmd.batch [ Cmd.batch newCmds, cmd ] )


{-| Ideally you wouldnt have to deconstruct a tupled model and cmd, but if you need to, this function does it.

    Return2.model (model, cmd) == model

-}
model : ( model, Cmd msg )
model =
    Tuple.first


{-| Get the cmd of an already tupled model and cmd.

    Return2.cmd (model, cmd) == cmd

-}
cmd : ( model, Cmd msg )
cmd =
    Tuple.second


{-| If you need to transform just the cmd in a tuple, such as if you need to wrap a sub-modules msg type

    loginModel
        |> Login.update subMsg
        |> mapCmd LoginMsg

-}
mapCmd : (a -> b) -> ( model, Cmd a ) -> ( model, Cmd b )
mapCmd f =
    Tuple.mapSecond (Cmd.map f)


{-| If you need to transform just the model in a tuple, such as if you need to pack a submodel into the main model

    loginModel
        |> Login.update subMsg
        |> mapModel (setPage model Page.Login)

-}
mapModel : (a -> b) -> ( a, Cmd msg ) -> ( b, Cmd msg )
mapModel =
    Tuple.mapFirst
