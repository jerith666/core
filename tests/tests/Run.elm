module Run exposing (main)

{-| HOW TO RUN THESE TESTS

$ node test

Note that this always uses an initial seed of 902101337, since it can't do effects.

-}

import Basics exposing (..)
import List exposing ((::))
import Maybe exposing (Maybe(..))
import Result exposing (Result(..))
import String exposing (String)
import Char exposing (Char)
import Tuple

import Debug

import Platform exposing ( Program )
import Platform.Cmd as Cmd exposing ( Cmd )
import Platform.Sub as Sub exposing ( Sub )

import Array
import Dict
import Set

import Test exposing (Test)
import Test.Runner
import Random
import Expect
import Main exposing (tests)

type alias Summary =
    { passed : Int, autoFail : Maybe String }

main : Program () () msg
main =
    let
        summary =
            run tests

        _ =
            case summary.autoFail of
                Just reason ->
                    Debug.log "Auto failed" reason
                        |> (\_ -> Debug.todo "FAILED TEST RUN")
                Nothing ->
                    Debug.log "All tests passed, count" summary.passed
    in
    Platform.worker
        { init = \() -> ( (), Cmd.none )
        , update = \_ () -> ( (), Cmd.none )
        , subscriptions = \() -> Sub.none
        }


run : Test -> Summary
run test =
    let
        seededRunners =
            Test.Runner.fromTest 100 (Random.initialSeed 902101337) test

        _ =
            Debug.log "Running"  "Tests ..."
    in
    toOutput
        { passed = 0
        , autoFail = Just "no tests were run"
        }
        seededRunners


toOutput : Summary -> Test.Runner.SeededRunners -> Summary
toOutput summary seededRunners =
    let
        render =
            List.foldl toOutputHelp
    in
    case seededRunners of
        Test.Runner.Plain runners ->
            render { summary | autoFail = Nothing } runners

        Test.Runner.Only runners ->
            render { summary | autoFail = Just "Test.only was used" } runners

        Test.Runner.Skipping runners ->
            render { summary | autoFail = Just "Test.skip was used" } runners

        Test.Runner.Invalid message ->
            Debug.log "Invalid message" message
                |> Debug.todo "FAIL"


toOutputHelp : Test.Runner.Runner -> Summary -> Summary
toOutputHelp runner summary =
    runner.run ()
        |> List.foldl (fromExpectation runner.labels) summary


fromExpectation : List String -> Expect.Expectation -> Summary -> Summary
fromExpectation labels expectation summary =
    case Test.Runner.getFailureReason expectation of
        Nothing ->
            { summary | passed = summary.passed + 1 }

        Just { given, description, reason } ->
            let
                message =
                    description ++ ": " ++ Debug.toString reason

                prefix =
                    case given of
                        Nothing ->
                            ""

                        Just g ->
                            "Given " ++ g ++ "\n\n"

                labelString =
                    labels
                        |> List.reverse
                        |> String.join "\n"

                newOutput =
                    "\n\n" ++ labelString ++ "\n" ++ (prefix ++ message) ++ "\n"
            in
            Debug.todo newOutput
