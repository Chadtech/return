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

{-| This package makes it easier to build `(module, Cmd msg, reply)` a common return value for big sub-modules. See the readme for an explanation of what `Return3` is all about.


# Return

@docs Return


# With

@docs withReply, withNoReply, withTuple, withNothing


# Add

@docs addCmd, addCmds


# Map

@docs mapModel, mapCmd, mapReply


# Get

@docs model, cmd, reply


# Incorporate

@docs incorp

-}

import Return2 as R2


{-| This alias formalizes that this particular triple is our return value.
-}
type alias Return model msg reply =
    ( model, Cmd msg, Maybe reply )


{-| Add a reply to your tuple.

    model
        |> R2.withNoCmd
        |> R3.withReply UserNameChanged

-}
withReply : reply -> ( model, Cmd msg ) -> Return model msg reply
withReply reply_ ( model_, cmd_ ) =
    ( model_, cmd_, Just reply_ )


{-| Dont add a reply to your tuple.

    FetchingData
        |> R2.withCmd getLocalStorage
        |> R3.withNoReply

-}
withNoReply : ( model, Cmd msg ) -> Return model msg reply
withNoReply ( model_, cmd_ ) =
    ( model_, cmd_, Nothing )


{-| If building your reply takes a lot of work, use this function.

    calculate width height x y
        |> center model.size
        |> UpdateSpace
        |> R3.withTuple
            (model |> R2.withNoCmd)

-}
withTuple : ( model, Cmd msg ) -> reply -> Return model msg reply
withTuple ( model_, cmd_ ) reply_ =
    ( model_, cmd_, Just reply_ )


{-| Return the model with no cmd and no reply

    model
        |> withNothing

-}
withNothing : model -> Return model msg reply
withNothing model_ =
    ( model_, Cmd.none, Nothing )


{-| Ideally you wouldnt have to deconstruct a `Return`, but if you need to, this function does it.

    Return3.model (model, cmd, Nothing) == model

-}
model : Return model msg reply -> model
model ( model_, _, _ ) =
    model_


{-| Get the cmd of an already packed `Return`.

    Return3.cmd (model, cmd, reply) == cmd

-}
cmd : Return model msg reply -> Cmd msg
cmd ( _, cmd_, _ ) =
    cmd_


{-| Get the reply of an already packed `Return`, if it exists

    Return3.reply (model, cmd, maybeReply) == maybeReply

-}
reply : Return model msg reply -> Maybe reply
reply ( _, _, reply_ ) =
    reply_


{-| Sometimes you need to add a cmd to an already packaged `Return`

    (model, cmd0, reply)
        |> addCmd cmd1

        -- == (model, Cmd.batch [ cmd1, cmd0 ], reply)

-}
addCmd : Cmd msg -> Return model msg reply -> Return model msg reply
addCmd newCmd ( model_, cmd_, reply_ ) =
    ( model_, Cmd.batch [ newCmd, cmd_ ], reply_ )


{-| Add many cmds to an already packaged `Return`

    (model, cmd0, reply)
        |> addCmds [ cmd1, cmd2 ]

        -- == (model, Cmd.batch [ cmd0, cmd1, cmd2 ], reply)

-}
addCmds : List (Cmd msg) -> Return model msg reply -> Return model msg reply
addCmds newCmds ( model_, cmd_, reply_ ) =
    ( model_, Cmd.batch [ Cmd.batch newCmds, cmd_ ], reply_ )


{-| If you need to transform just the model in a `Return`, such as if you need to pack a submodel into the main model

    loginModel
        |> Login.update subMsg
        |> mapModel (setPage model Page.Login)

-}
mapModel : (a -> b) -> Return a msg reply -> Return b msg reply
mapModel f ( model_, cmd_, reply_ ) =
    ( f model_, cmd_, reply_ )


{-| If you need to transform just the cmd in a `Return`, such as if you need to wrap a sub-modules msg type

    loginModel
        |> Login.update subMsg
        |> mapCmd LoginMsg

-}
mapCmd : (a -> b) -> Return model a reply -> Return model b reply
mapCmd f ( model_, cmd_, reply_ ) =
    ( model_, Cmd.map f cmd_, reply_ )


{-| -}
mapReply : (Maybe a -> Maybe b) -> Return model msg a -> Return model msg b
mapReply f ( model_, cmd_, reply_ ) =
    ( model_, cmd_, f reply_ )


{-| `Return`s contain a reply, and that reply needs to be handled much like a `msg` does in an update function.

    loginModel
        |> Login.update loginMsg
        |> R3.mapCmd LoginMsg
        |> incorp handleLoginReply model


    handleLoginReply : Login.Model -> Maybe Reply -> Model -> (Model, Cmd Msg)
    handleLoginreply loginModel maybeReply model =
        case maybeReply of
            Nothing ->
                { model | page = Login loginModel }
                    |> R2.withNoCmd

            Just (LoggedIn user) ->
                { model
                    | page = Home Home.init
                    , user = Just user
                }
                    |> R2.withNoCmd

-}
incorp : (subModel -> Maybe reply -> model -> ( model, Cmd msg )) -> model -> Return subModel msg reply -> ( model, Cmd msg )
incorp f model_ ( subModel, cmd_, reply_ ) =
    f subModel reply_ model_
        |> R2.addCmd cmd_
