:- consult('../moves.pl').
:- consult('../Hnefatafl.pl').

run_tests([]).
run_tests([T|Rest]) :-
    ( call(T) -> format('[PASSED] ~w~n', [T]) ; format('[FAILED] ~w~n', [T]) ),
    run_tests(Rest).

test_rook_movement :-
    initial_board(11, B),
    % Attacker at (3,0) can move to (3,1), (3,2) etc.
    valid_move(B, 3, 0, 3, 1, attacker),
    valid_move(B, 3, 0, 4, 0, attacker).

test_path_blocking :-
    initial_board(11, B),
    % King at (5,5) blocked by (5,4) (w) if moving towards (5,0)
    \+ valid_move(B, 5, 5, 0, 5, defender).

test_restricted_squares :-
    initial_board(11, B),
    % Attacker at (3,0) cannot move to corner (0,0)
    \+ valid_move(B, 3, 0, 0, 0, attacker),
    % King can move to corner (if empty)
    set_piece(B, 5, 4, e, B1),
    set_piece(B1, 5, 3, e, B2),
    set_piece(B2, 5, 2, e, B3),
    set_piece(B3, 5, 1, e, B4),
    set_piece(B4, 5, 0, e, B5),
    set_piece(B5, 4, 0, e, B6),
    set_piece(B6, 3, 0, e, B7),
    set_piece(B7, 2, 0, e, B8),
    set_piece(B8, 1, 0, e, B9),
    valid_move(B9, 5, 5, 0, 0, defender).

test_all_moves_generation :-
    initial_board(11, B),
    all_valid_moves(B, attacker, AMoves),
    AMoves \= [],
    all_valid_moves(B, defender, DMoves),
    DMoves \= [].

run_moves_tests :-
    format('--- Moves Tests ---~n'),
    run_tests([
        test_rook_movement,
        test_path_blocking,
        test_restricted_squares,
        test_all_moves_generation
    ]).
