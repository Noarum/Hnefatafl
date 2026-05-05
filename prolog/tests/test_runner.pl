:- consult('test_board.pl').
:- consult('test_moves.pl').
:- consult('test_utility.pl').
:- consult('test_ai.pl').

run_all_tests :-
    run_board_tests,
    run_moves_tests,
    run_utility_tests,
    run_ai_tests,
    format('~nTests completed.~n').
