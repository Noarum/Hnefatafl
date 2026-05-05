:- consult('../ai.pl').
:- consult('../controller.pl').

run_tests([]).
run_tests([T|Rest]) :-
    ( call(T) -> format('[PASSED] ~w~n', [T]) ; format('[FAILED] ~w~n', [T]) ),
    run_tests(Rest).

test_ai_move_easy :-
    initial_board(11, B),
    choose_ai_move(B, attacker, easy, Move),
    Move \= none.

test_ai_escape :-
    initial_board(11, B),
    % King at (1,1), corner at (0,0) is open
    set_piece(B, 5, 5, e, B1),
    set_piece(B1, 1, 1, k, B2),
    choose_ai_move(B2, defender, medium, Move),
    Move \= none.

run_ai_tests :-
    format('--- AI Tests ---~n'),
    run_tests([
        test_ai_move_easy,
        test_ai_escape
    ]).
