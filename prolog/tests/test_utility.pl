:- consult('../utility.pl').
:- consult('../Hnefatafl.pl').

run_tests([]).
run_tests([T|Rest]) :-
    ( call(T) -> format('[PASSED] ~w~n', [T]) ; format('[FAILED] ~w~n', [T]) ),
    run_tests(Rest).

test_material_score :-
    initial_board(11, B),
    material_score(B, -12). % 12 - 24 = -12

test_king_mobility :-
    initial_board(11, B),
    get_king_pos(B, KR, KC),
    king_mobility(B, KR, KC, Score),
    Score >= 0.

test_utility_values :-
    initial_board(11, B),
    utility(B, defender, S1),
    % King closer to corner should have higher score
    set_piece(B, 5, 5, e, B1),
    set_piece(B1, 1, 1, k, B2),
    utility(B2, defender, S2),
    S2 > S1.

run_utility_tests :-
    format('--- Utility Tests ---~n'),
    run_tests([
        test_material_score,
        test_king_mobility,
        test_utility_values
    ]).
