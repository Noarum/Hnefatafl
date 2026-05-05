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
% BOARD SETUP
% =========================

test_initial_king_position :-
    initial_board(11, B),
    get_piece(B, 5, 5, k).

test_corners_empty :-
    initial_board(11, B),
    get_piece(B, 0, 0, c),
    get_piece(B, 10, 0, c),
    get_piece(B, 0, 10, c),
    get_piece(B, 10, 10, c).


% =========================
% MOVEMENT
% =========================

test_horizontal_move :-
    initial_board(11, B),
    valid_move(B, 3, 0, 3, 2, b).

test_vertical_move :-
    initial_board(11, B),
    valid_move(B, 0, 3, 2, 3, b).

test_blocked_path :-
    initial_board(11, B),
    \+ valid_move(B, 5, 5, 5, 0, w).

test_no_jump :-
    initial_board(11, B),
    set_piece(B, 2, 2, b, B1),
    set_piece(B1, 2, 4, w, B2),
    \+ valid_move(B2, 2, 2, 2, 6, b).

test_only_king_corner :-
    initial_board(11, B),
    \+ valid_move(B, 3, 0, 0, 0, b).

test_king_can_corner :-
    initial_board(11, B),
    set_piece(B, 5, 5, e, B1),
    set_piece(B1, 1, 0, k, B2),
    valid_move(B2, 1, 0, 0, 0, w).


% =========================
% CAPTURE
% =========================

test_capture_horizontal :-
    initial_board(11, B),
    set_piece(B, 3, 3, b, B1),
    set_piece(B1, 3, 4, w, B2),
    set_piece(B2, 3, 5, b, B3),
    apply_captures(B3, 3, 5, b, F),
    get_piece(F, 3, 4, e).

test_capture_vertical :-
    initial_board(11, B),
    set_piece(B, 3, 3, b, B1),
    set_piece(B1, 4, 3, w, B2),
    set_piece(B2, 5, 3, b, B3),
    apply_captures(B3, 5, 3, b, F),
    get_piece(F, 4, 3, e).

test_capture_throne :-
    initial_board(11, B),
    set_piece(B, 5, 5, t, B1),
    set_piece(B1, 5, 4, w, B2),
    set_piece(B2, 5, 3, b, B3),
    apply_captures(B3, 5, 3, b, F),
    get_piece(F, 5, 4, e).

test_king_not_capture_3_sides :-
    initial_board(11, B),
    set_piece(B, 5, 5, k, B1),
    set_piece(B1, 4, 5, b, B2),
    set_piece(B2, 5, 4, b, B3),
    set_piece(B3, 6, 5, b, B4),
    apply_captures(B4, 6, 5, b, F),
    get_piece(F, 5, 5, k).

test_king_capture_4_sides :-
    initial_board(11, B),
    set_piece(B, 5, 5, k, B1),
    set_piece(B1, 4, 5, b, B2),
    set_piece(B2, 5, 4, b, B3),
    set_piece(B3, 6, 5, b, B4),
    set_piece(B4, 5, 6, b, B5),
    apply_captures(B5, 5, 6, b, F),
    \+ find_king(F, _, _).

test_king_safe_on_edge :-
    initial_board(11, B),
    set_piece(B, 0, 5, k, B1),
    set_piece(B1, 0, 4, b, B2),
    set_piece(B2, 0, 6, b, B3),
    set_piece(B3, 1, 5, b, B4),
    apply_captures(B4, 1, 5, b, F),
    get_piece(F, 0, 5, k).


% =========================
% WIN CONDITIONS
% =========================

test_king_corner_win :-
    initial_board(11, B),
    set_piece(B, 0, 0, k, B1),
    check_win(B1, w).

test_king_capture_win :-
    initial_board(11, B),
    set_piece(B, 5, 5, e, B1),
    \+ (member(Row, B1), member(k, Row)),
    check_win(B1, b).

test_no_moves_loss :-
    initial_board(11, B),
    set_piece(B, 1, 1, k, B1),
    set_piece(B1, 0, 1, b, B2),
    set_piece(B2, 1, 0, b, B3),
    set_piece(B3, 1, 2, b, B4),
    set_piece(B4, 2, 1, b, B5),
    \+ get_valid_moves(B5, 1, 1, w, _).


% =========================
% MASTER RUNNER
% =========================

run_all_tests :-
    run_tests([
        test_initial_king_position,
        test_corners_empty,
        test_horizontal_move,
        test_vertical_move,
        test_blocked_path,
        test_no_jump,
        test_only_king_corner,
        test_king_can_corner,
        test_capture_horizontal,
        test_capture_vertical,
        test_capture_throne,
        test_king_not_capture_3_sides,
        test_king_capture_4_sides,
        test_king_safe_on_edge,
        test_king_corner_win,
        test_king_capture_win,
        test_no_moves_loss
    ]),
    format('~nTests completed.~n').