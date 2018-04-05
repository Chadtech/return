# Return

This package is for handling the subtle architectural problems associated with nested update functions in big Elm applications. There are no simple principles at work here; this package is just a product of my cumulated experience from writing a lot Elm and paying attention to what other people do when they write Elm. Immediately below is a code example, and further below is an explanation of how I got here.

## Example

```elm
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

import Return3 as R3 exposing (Return)
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

In Elm, our update functions return a tuple containing our `Model` and whatever side effects we want to occur outside the Elm run-time.
```elm
( Model, Cmd Msg )
```
In practice, that means we have to type stuff like this.
```elm
    ( editThing model, thingCmd (getData model))
```
Unfortunately this turns out to be not so nice. We have to type this tuple a lot, and doing so is a hassle because there are characters on the left, right, and center of the tuple you have to type. It would be much easier if you only had to put your cursor in one spot rather than jump around. As an alternative some of us began using our own infix operators; most notably the folks at NoRedInk use the ["rocket" operator](http://package.elm-lang.org/packages/NoRedInk/rocket-update/latest).
```elm
    model => thingCmd

(=>) : a -> b -> (a, b)
(=>) model cmd =
    (model, cmd)
```
Thats pretty good. But as I write this, the expectation is that the upcoming Elm 0.19 wont allow custom infix operators (which is probably for the best). We will need a new solution. I really like [Janiczek/cmd-extra](http://package.elm-lang.org/packages/Janiczek/cmd-extra/latest). His package exposes some extremely readable functions, like `withCmd`.
```elm
    model 
        |> withCmd cmd

withCmd : Cmd msg -> model -> (model, Cmd msg)
```
Its a little bit more verbose, but it reads really nice and it plays well with whatever else is going on in your update function. If this were the end of the story, I would just settle on Janiczek's package, but its not. Big Elm applications usually have sub-update functions, sub-models, and sub-msgs. The communication between parent and child update functions can be kind of complicated, and often we need to transform values after they have been bundled into tuples. Our update function technique has to work well in the broader context of what update functions are doing in our application. 

Richard Feldman uses the `ExternalMsg` type for communication from child update functions to parent update functions. His update functions result in something that looks like this.
```elm
    ((Model, Cmd Msg), ExternalMsg)
```
The `ExternalMsg` carries information from the sub module to its parent module. The best example of this is having a login page with its own update function, that needs to tell the main update function who the user is once they successfully log in. The sub update function in your login page doesnt just return a sub-model and sub-cmds, it also returns information that the application as a whole needs to know, like that the user session has changed.

That works very well. One criticism I have however, is nested tuples are kind of hard to work with. The model is in a tuple in a tuple. So if you want to access it- say to transform it- you need to do `Tuple.first >> Tuple.first`. Flat data structures are nicer, so I have learned to do triples instead.
```elm
    (Model, Cmd Msg, ExternalMsg)
```
Also, I found that the name `ExternalMsg` didnt make much sense. Regular `Msg`s reflect external events that actually happened in your application that have indeterminate consequence. Stuff like mouse clicks, or http responses; your application just knows what happened and thereafter needs to figure out what to do. `ExternalMsg`s arent the same kind of thing despite what the name implies. They represent interal results from within your application which usually have explicit consequence. I instead started calling them `Reply` since they are like replies to the news sub-modulereceive from the parent-modules. Also I made it into a `Maybe Reply`, so you can consider the possibility of no reply abstractly, without assuming any particular `Reply` type.
```elm
    (Model, Cmd Msg, Maybe Reply)
```
Improvements from this point are harder and more tenuous, but I have also learned a bit from [Fresheyeball/elm-return](http://package.elm-lang.org/packages/Fresheyeball/elm-return/6.0.3/) as well. Sub-models need to be incorporated back into their parent-models, and usually in very regular and predictable ways, such as just being a field inside a record. Fresheyeball's package exposes functions that simplify that incorporation process. Unfortunately, I think Fresheyeball's package indulges a lot of functional programming stuff beyond its usefulness (and it uses infix operators, so its usefulness wont last into 0.19). But regardless, his approach to formalizing and mutating return results is a good one that I have tried to reproduce in this package.
