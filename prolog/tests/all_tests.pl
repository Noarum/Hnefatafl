:- consult('../Hnefatafl.pl').
:- consult('../moves.pl').
:- consult('../utility.pl').
:- consult('../ai.pl').
:- consult('../controller.pl').

% =========================
% TEST RUNNER
% =========================

run_tests([]).
run_tests([T|Rest]) :-
    ( call(T) -> format('[PASSED] ~w~n', [T]) ; format('[FAILED] ~w~n', [T]) ),
    run_tests(Rest).


% =========================
% ORIGINAL TESTS
% =========================

test_board_setup :-
    initial_board(11, B),
    get_piece(B, 5, 5, k).

test_custodial_capture :-
    initial_board(11, B),
    set_piece(B, 2, 2, w, B1),
    set_piece(B1, 1, 2, b, B2),
    set_piece(B2, 3, 2, b, B3),
    apply_captures(B3, 3, 2, b, Final),
    get_piece(Final, 2, 2, e).

test_capture_against_throne :-
    initial_board(11, B),
    set_piece(B, 5, 5, t, B1),
    set_piece(B1, 5, 4, w, B2),
    set_piece(B2, 5, 3, b, B3),
    apply_captures(B3, 5, 3, b, Final),
    get_piece(Final, 5, 4, e).

test_king_capture_4_sides :-
    initial_board(11, B),
    set_piece(B, 4, 5, b, B1),
    set_piece(B1, 6, 5, b, B2),
    set_piece(B2, 5, 4, b, B3),
    set_piece(B3, 5, 6, b, B4),
    apply_captures(B4, 5, 6, b, Final),
    \+ find_king(Final, _, _).

test_win_defender_corner :-
    initial_board(11, B),
    set_piece(B, 0, 0, k, B1),
    check_win(B1, w).

test_king_escape_full_flow :-
    init_game(11),
    retractall(current_player(_)),
    assertz(current_player(defender)),
    current_board(B),
    set_piece(B, 5, 5, t, B1),
    set_piece(B1, 1, 0, k, B2),
    set_piece(B2, 0, 0, c, B3),
    commit_state(B3, defender, ongoing),
    make_human_move(0, 1, 0, 0),
    game_status(defender_won).

test_rook_movement :-
    initial_board(11, B),
    valid_move(B, 3, 0, 3, 2, b).

test_path_blocking :-
    initial_board(11, B),
    \+ valid_move(B, 5, 5, 5, 0, w).

test_restricted_squares :-
    initial_board(11, B),
    \+ valid_move(B, 3, 0, 0, 0, b).

test_material_score :-
    initial_board(11, B),
    material_score(B, -12).

test_utility_values :-
    initial_board(11, B),
    utility(B, defender, S1),
    set_piece(B, 5, 5, e, B1),
    set_piece(B1, 1, 1, k, B2),
    utility(B2, defender, S2),
    S2 > S1.

test_utility_near_win :-
    initial_board(11, B),
    set_piece(B, 5, 5, e, B1),
    set_piece(B1, 1, 0, k, B2),
    utility(B2, defender, S),
    S > 1900.

test_king_unarmed :-
    initial_board(11, B),
    set_piece(B, 1, 1, k, B1),
    set_piece(B1, 2, 1, b, B2),
    set_piece(B2, 3, 1, w, B3),
    apply_captures(B3, 3, 1, w, Final),
    get_piece(Final, 2, 1, b).

test_no_suicide_move :-
    initial_board(11, B),
    set_piece(B, 1, 1, b, B1),
    set_piece(B1, 3, 1, b, B2),
    \+ valid_move(B2, 5, 4, 2, 1, w).

test_ai_escape :-
    initial_board(11, B),
    set_piece(B, 5, 5, e, B1),
    set_piece(B1, 1, 0, k, B2),
    choose_ai_move(B2, w, easy, move(1, 0, 0, 0)).

test_ai_move :-
    initial_board(11, B),
    choose_ai_move(B, b, easy, Move),
    Move \= none.


% =========================
% STRICT / EDGE TESTS
% =========================

test_out_of_bounds :-
    initial_board(11, B),
    \+ valid_move(B, 0, 0, -1, 0, b),
    \+ valid_move(B, 0, 0, 0, 11, b).

test_no_diagonal :-
    initial_board(11, B),
    \+ valid_move(B, 3, 0, 4, 1, b).

test_no_overlap :-
    initial_board(11, B),
    \+ valid_move(B, 3, 0, 4, 0, b).

test_zero_move :-
    initial_board(11, B),
    \+ valid_move(B, 3, 0, 3, 0, b).

test_capture_against_corner :-
    initial_board(11, B),
    set_piece(B, 0, 0, c, B1),
    set_piece(B1, 1, 0, w, B2),
    set_piece(B2, 2, 0, b, B3),
    apply_captures(B3, 2, 0, b, Final),
    get_piece(Final, 1, 0, e).


test_king_capture_3_sides_wall :-
    initial_board(11, B),
    set_piece(B, 5, 5, t, B0), % Remove original king
    set_piece(B0, 0, 5, k, B1),
    set_piece(B1, 1, 5, b, B2),
    set_piece(B2, 0, 4, b, B3),
    set_piece(B3, 0, 6, b, B4),
    apply_captures(B4, 1, 5, b, Final),
    \+ find_king(Final, _, _).

test_king_capture_2_sides_corner :-
    initial_board(11, B),
    set_piece(B, 5, 5, t, B0), % Remove original king
    set_piece(B0, 0, 0, k, B1),
    set_piece(B1, 1, 0, b, B2),
    set_piece(B2, 0, 1, b, B3),
    apply_captures(B3, 1, 0, b, Final),
    \+ find_king(Final, _, _).

test_turn_order :-
    init_game(11),
    current_player(attacker),
    switch_player,
    current_player(defender).

test_ai_valid_move :-
    initial_board(11, B),
    choose_ai_move(B, b, easy, move(X1,Y1,X2,Y2)),
    valid_move(B, X1, Y1, X2, Y2, b).

test_no_capture_without_sandwich :-
    initial_board(11, B),
    set_piece(B, 2, 2, w, B1),
    set_piece(B1, 3, 2, b, B2),
    apply_captures(B2, 3, 2, b, Final),
    get_piece(Final, 2, 2, w).

test_no_capture_diagonal :-
    initial_board(11, B),
    set_piece(B, 2, 2, w, B1),
    set_piece(B1, 3, 3, b, B2),
    set_piece(B2, 1, 1, b, B3),
    apply_captures(B3, 3, 3, b, Final),
    get_piece(Final, 2, 2, w).

test_no_capture_if_not_opposite :-
    initial_board(11, B),
    set_piece(B, 2, 2, w, B1),
    set_piece(B1, 3, 2, b, B2),
    set_piece(B2, 4, 2, b, B3),
    apply_captures(B3, 4, 2, b, Final),
    get_piece(Final, 2, 2, w).

test_no_capture_through_empty :-
    initial_board(11, B),
    set_piece(B, 2, 2, w, B1),
    set_piece(B1, 4, 2, b, B2),
    apply_captures(B2, 4, 2, b, Final),
    get_piece(Final, 2, 2, w).

test_invalid_move_blocked :-
    initial_board(11, B),
    \+ valid_move(B, 5, 5, 5, 0, w).

test_invalid_move_not_your_piece :-
    initial_board(11, B),
    \+ valid_move(B, 3, 0, 3, 2, w).

test_invalid_move_occupied :-
    initial_board(11, B),
    \+ valid_move(B, 3, 0, 4, 0, b).

test_invalid_move_restricted :-
    initial_board(11, B),
    \+ valid_move(B, 3, 0, 0, 0, b).

test_invalid_move_diagonal :-
    initial_board(11, B),
    \+ valid_move(B, 3, 0, 4, 1, b).

test_invalid_move_no_movement :-
    initial_board(11, B),
    \+ valid_move(B, 3, 0, 3, 0, b).

test_apply_invalid_move_fails :-
    initial_board(11, B),
    \+ apply_move(B, 3, 0, 4, 1, b, _).

test_apply_valid_move_succeeds :-
    initial_board(11, B),
    apply_move(B, 3, 0, 3, 2, b, NB),
    NB \= B.

test_no_extra_removal :-
    initial_board(11, B),
    set_piece(B, 2, 2, w, B1),
    set_piece(B1, 1, 2, b, B2),
    set_piece(B2, 3, 2, b, B3),
    set_piece(B3, 4, 4, w, B4),
    apply_captures(B4, 3, 2, b, Final),
    get_piece(Final, 4, 4, w).


% =========================
% MASTER RUNNER
% =========================

run_all_tests :-
    run_tests([
        test_board_setup,
        test_custodial_capture,
        test_capture_against_throne,
        test_king_capture_4_sides,
        test_win_defender_corner,
        test_king_escape_full_flow,
        test_rook_movement,
        test_path_blocking,
        test_restricted_squares,
        test_material_score,
        test_utility_values,
        test_utility_near_win,
        test_king_unarmed,
        test_no_suicide_move,
        test_ai_escape,
        test_ai_move,
        test_out_of_bounds,
        test_no_diagonal,
        test_no_overlap,
        test_zero_move,
        test_capture_against_corner,
        test_king_capture_3_sides_wall,
        test_king_capture_2_sides_corner,
        test_turn_order,
        test_ai_valid_move,
        test_no_capture_without_sandwich,
        test_no_capture_diagonal,
        test_no_capture_if_not_opposite,
        test_no_capture_through_empty,
        test_invalid_move_blocked,
        test_invalid_move_not_your_piece,
        test_invalid_move_occupied,
        test_invalid_move_restricted,
        test_invalid_move_diagonal,
        test_invalid_move_no_movement,
        test_apply_invalid_move_fails,
        test_apply_valid_move_succeeds,
        test_no_extra_removal
    ]),
    format('~nTests completed.~n').