:- consult('../Hnefatafl.pl').
:- consult('../moves.pl').
:- consult('../utility.pl').
:- consult('../ai.pl').
:- consult('../controller.pl').

% --- TEST RUNNER ---
run_tests([]).
run_tests([T|Rest]) :-
    ( call(T) -> format('[PASSED] ~w~n', [T]) ; format('[FAILED] ~w~n', [T]) ),
    run_tests(Rest).

% --- BOARD TESTS ---
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
    % Set turn to defender
    retractall(current_player(_)),
    assertz(current_player(defender)),
    current_board(B),
    % Move king to (1,0) (adjacent to corner)
    set_piece(B, 5, 5, t, B1),
    set_piece(B1, 1, 0, k, B2),
    % Clear path to (0,0)
    set_piece(B2, 0, 0, c, B3),
    commit_state(B3, defender, ongoing),
    % Perform move k(1,0) -> (0,0)
    % make_human_move(FromRow, FromCol, ToRow, ToCol)
    make_human_move(0, 1, 0, 0),
    game_status(defender_won).

% --- MOVES TESTS ---
test_rook_movement :-
    initial_board(11, B),
    valid_move(B, 3, 0, 3, 2, b).

test_path_blocking :-
    initial_board(11, B),
    \+ valid_move(B, 5, 5, 5, 0, w). % Path to (5,0) is blocked by defenders

test_restricted_squares :-
    initial_board(11, B),
    \+ valid_move(B, 3, 0, 0, 0, b),
    % King can move to corner (if empty)
    set_piece(B, 5, 4, e, B1),
    set_piece(B1, 5, 3, e, B2),
    set_piece(B2, 5, 2, e, B3),
    set_piece(B3, 5, 1, e, B4),
    set_piece(B4, 5, 0, e, B5),
    valid_move(B5, 5, 5, 5, 0, w),
    set_piece(B5, 5, 5, e, B6),
    set_piece(B6, 5, 0, k, B7),
    set_piece(B7, 4, 0, e, B8),
    set_piece(B8, 3, 0, e, B9),
    set_piece(B9, 2, 0, e, B10),
    set_piece(B10, 1, 0, e, B11),
    valid_move(B11, 5, 0, 0, 0, w).

% --- UTILITY TESTS ---
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
    set_piece(B1, 1, 0, k, B2), % King at Row 0, Col 1 (next to corner 0,0)
    utility(B2, defender, S),
    S > 1900. % Includes RouteScore (2000) + ProximityScore minus MaterialPenalty

test_ai_escape :-
    initial_board(11, B),
    set_piece(B, 5, 5, e, B1),
    set_piece(B1, 1, 0, k, B2), % King at Row 0, Col 1
    choose_ai_move(B2, w, easy, move(1, 0, 0, 0)).

% --- AI TESTS ---
test_ai_move :-
    initial_board(11, B),
    choose_ai_move(B, b, easy, Move),
    Move \= none.

% --- MASTER RUNNER ---
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
        test_ai_escape,
        test_ai_move
    ]),
    format('~nTests completed.~n').
