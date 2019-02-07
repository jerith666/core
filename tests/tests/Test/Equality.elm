module Test.Equality exposing (tests)

import Basics exposing (..)
import Maybe exposing (..)
import Test exposing (..)
import List
import Expect


type Different
    = A String
    | B (List Int)


tests : Test
tests =
    let
        diffTests =
            describe "ADT equality"
                [ test "As eq" <| \() -> Expect.equal True (A "a" == A "a")
                , test "Bs eq" <| \() -> Expect.equal True (B [ 1 ] == B [ 1 ])
                , test "A left neq" <| \() -> Expect.equal True (A "a" /= B [ 1 ])
                , test "A right neq" <| \() -> Expect.equal True (B [ 1 ] /= A "a")
                ]

        recordTests =
            describe "Record equality"
                [ test "empty same" <| \() -> Expect.equal True ({} == {})
                , test "ctor same" <| \() -> Expect.equal True ({ field = Just 3 } == { field = Just 3 })
                , test "ctor same, special case" <| \() -> Expect.equal True ({ ctor = Just 3 } == { ctor = Just 3 })
                , test "ctor diff" <| \() -> Expect.equal True ({ field = Just 3 } /= { field = Nothing })
                , test "ctor diff, special case" <| \() -> Expect.equal True ({ ctor = Just 3 } /= { ctor = Nothing })
                ]
    in
        describe "Equality Tests" [ diffTests, recordTests, nestingThreshold ]

{-https://github.com/elm/core/issues/1011-}
nestingThreshold : Test
nestingThreshold =
    let
        oneThing = True
        someThings n = List.repeat n oneThing
        dangerousThreshold = 100 --keep in sync with ... TODO
        buffer = 2
        range = List.range (dangerousThreshold - buffer) (dangerousThreshold + buffer)
        lengthPairsToTest = List.concatMap (\i -> List.map (\j -> ( i, j )) range) range
        check (l1, l2) =
            test ("compare lists of length " ++ String.fromInt l1 ++ " and " ++ String.fromInt l2) <| \() ->
                Expect.equal
                    (l1 == l2)
                    (someThings l1 == someThings l2)
    in
    describe "Nesting Threshold" <|
        List.map check lengthPairsToTest
