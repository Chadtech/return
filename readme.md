# Return

This package is for handling the subtle architectural problems associated with update nested update functions. There are no simple principles at work here, this package is a product of my cumulated experience from writing a lot Elm and paying attention to what other people do when they write Elm.

## Example

```
-- Main.elm --
import Login
import Return2 as R2
import Return3 as R3


type alias Model =
    { page : Page 
    , user : Maybe User
    }


type Page
    = Login Login.Model
    | Home


type Msg
    = LoginMsg Login.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LoginMsg subMsg ->
            case model.page of
                Login subModel ->
                    subModel
                        |> Login.update subMsg 
                        |> R3.mapCmd LoginMsg
                        |> R3.incorp handleLoginReply model

                _ ->
                    model
                        |> R2.withNoCmd


handleLoginReply : Login.Model -> Maybe Login.Reply -> Model -> (Model, Cmd Msg)
handleLoginReply subModel maybeReply model =
    case maybeReply of
        Nothing ->
            model
                |> setPage Login subModel
                |> R2.withNoCmd

        Just (Login.UserLoggedIn user) ->
            { model
                | page = Home
                , user = Just user
            }
                |> R2.withNoCmd


setPage : (subModel -> Page) -> subModel -> Model -> Model
setPage pageCtor subModel model =
    { model | page = pageCtor subModel }


-- Login.Elm --

import Return3 as R3
import Return2 as R2


type alias Model =
    { field : String }


type Msg
    = FieldUpdated String
    | SubmitClicked
    | LoginSucceeded User


type Reply
    = UserLoggedIn User


update : Msg -> Model -> Return Model Msg Reply
update msg model =
    case msg of
        FieldUpdated str ->
            { model | field = str }
                |> R3.withNothing

        SubmitClicked ->
            model
                |> R2.withCmd (submitRequest model)
                |> R3.withNoReply

        LoginSucceeded user ->
            model
                |> R2.withNoCmd
                |> R3.withReply (UserLoggedIn user)
```

## Explanation

In Elm, our update functions return a tuple contain our `Model` and whatever side effects we want to occur.
```
( Model, Cmd Msg )
```
In practice, that means we have to type stuff like this
```elm
    ThingHappened ->
        ( model, thingCmd )
```
Unfortunately this turns out to be not so nice if you write a lot of Elm. We have to type this tuple a lot, and doing so is a hassle because there are characters on the left, right, and center of the tuple you have to type. It would be must easier if you only had to put your cursor in one spot. As an alternative, some of us began using our own infix operator, most notably the folks at NoRedInk used the "rocket" operator.
```elm
    model => thingCmd

(=>) : a -> b -> (a, b)
(=>) model cmd =
    (model, cmd)
```
Thats pretty good. But as I write this, the expectation is that 0.19 wont allow custom infix operators, which is probably for the best. We will need a new solution. I really like (Janiczek/cmd-extra)[http://package.elm-lang.org/packages/Janiczek/cmd-extra/latest]. His package exposes some extremely readable functions, like `withCmd`.
```elm
    model 
        |> withCmd cmd

withCmd : Cmd msg -> model -> (model, Cmd msg)
```
Its a little bit more verbose, but it reads really nice and it plays well with whatever else is going on in your update function. If this were the end of the story, I would just settle on Janiczek's package, but its not. Big Elm applications usually have sub-update functions, sub-models, and sub-msgs. The communication between parent and child update functions can be kind of complicated, and often we need to transform values after they have been bundled into tuples. Our update function technique has to work well in the broader context of what update functions are doing in our application. Richard Feldman uses the `ExternalMsg` type for communication from child to parent, and sneaks it into his update function return values. His update functions result in something that looks like this.

```elm
    ((model, cmd), externalMsg)
```
The `ExternalMsg` communicates something to the parent. The best example of this is having a login page with its own update function, but it needs to tell the main update function who the user is once they successfully log in. So the sub update function in your login page doesnt just return a sub model and sub cmds, its also returning information that the application as a whole needs to know, like that the user session has changed.

That works very well. One criticism I have however, is nested tuples are kind of hard to work with. The model is in a tuple in a tuple. So if you want to access it, say to transform it, you need to do `Tuple.first >> Tuple.first`. Flat data structures are nicer, so I have learned to do triples instead.
```elm
    (model, cmd, externalMsg)
```
Also, I found that the name `ExternalMsg` didnt make much sense. `Msg`s reflect external events that actually happened in your application that have indeterminate consequence. Stuff like mouse clicks, or http responses; your application just knows what happened, and thereafter it needs to figure out what to do. `ExternalMsg`s arent the same kind of thing, despite what the name implies. They represent interal results from within your application which usually have explicit consequence. So I started calling them `Reply` since they are like replies to the news sub-states receive from the parent application state. Also I made it into a `Maybe Reply`, so you can consider the possibility of no reply abstractly, without assuming any `Reply` type
```elm
    (model, cmd, Maybe reply)
```
Improvements from this point are harder and more tenuous, but I have also learned a bit from (Fresheyeball/elm-return)[http://package.elm-lang.org/packages/Fresheyeball/elm-return/6.0.3/] as well. Sub-models need to be incorporated back into their parent-models, and usually in very regular and predictable ways, such as just being a field inside a record. Fresheyeball's package exposes from functions that simplify that incorporation process. Unfortunately, I think Fresheyeball's package indulges a lot of functional programming stuff beyond its usefulness (and it uses infix operators, so its usefulness wont last into 0.19).
