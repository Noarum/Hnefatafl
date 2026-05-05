:- consult('../Hnefatafl.pl').

test_initial_board :-
    initial_board(9, B9), length(B9, 9),
    initial_board(11, B11), length(B11, 11),
    write('test_initial_board: passed'), nl.

test_get_set_piece :-
    initial_board(9, B),
    get_piece(B, 4, 4, k),  % Center is king
    set_piece(B, 0, 0, x, B1),
    get_piece(B1, 0, 0, x),
    write('test_get_set_piece: passed'), nl.

test_win_conditions :-
    initial_board(9, B),
    \+ check_win(B, w),
    \+ check_win(B, b),
    % Defender win
    set_piece(B, 0, 0, k, B1),
    check_win(B1, w),
    % Attacker win (no king)
    set_piece(B, 4, 4, e, B2),
    check_win(B2, b),
    write('test_win_conditions: passed'), nl.

test_king_surrounded :-
    initial_board(9, B),
    \+ king_surrounded(B, 4, 4),
    % Surround king with 4 attackers
    set_piece(B, 3, 4, b, B1),
    set_piece(B1, 5, 4, b, B2),
    set_piece(B2, 4, 3, b, B3),
    set_piece(B3, 4, 5, b, B4),
    king_surrounded(B4, 4, 4),
    write('test_king_surrounded: passed'), nl.

run_hnefatafl_tests :-
    test_initial_board,
    test_get_set_piece,
    test_win_conditions,
    test_king_surrounded.
