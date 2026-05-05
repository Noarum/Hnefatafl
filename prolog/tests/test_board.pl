:- consult('../Hnefatafl.pl').
:- consult('../moves.pl').

% Helper to run a list of tests
run_tests([]).
run_tests([T|Rest]) :-
    ( call(T) -> format('[PASSED] ~w~n', [T]) ; format('[FAILED] ~w~n', [T]) ),
    run_tests(Rest).

% --- TESTS ---

test_board_setup :-
    initial_board(11, B),
    length(B, 11),
    get_piece(B, 5, 5, k). % King on throne

test_custodial_capture :-
    initial_board(11, B),
    % Place white piece at (2,2)
    set_piece(B, 2, 2, w, B1),
    % Surround with black at (1,2) and (3,2)
    set_piece(B1, 1, 2, b, B2),
    set_piece(B2, 3, 2, b, B3),
    % Apply capture as attacker
    apply_captures(B3, 3, 2, attacker, Final),
    get_piece(Final, 2, 2, e).

test_capture_against_throne :-
    initial_board(11, B),
    % Empty center
    set_piece(B, 5, 5, t, B1),
    % Place black at (5,4) and white at (5,3)
    set_piece(B1, 5, 4, w, B2),
    set_piece(B2, 5, 3, b, B3),
    % Apply capture as attacker (white sandwiched between black at 5,3 and throne at 5,5)
    apply_captures(B3, 5, 3, attacker, Final),
    get_piece(Final, 5, 4, e).

test_king_capture_4_sides :-
    initial_board(11, B),
    % Surround king at (5,5) with attackers
    set_piece(B, 4, 5, b, B1),
    set_piece(B1, 6, 5, b, B2),
    set_piece(B2, 5, 4, b, B3),
    set_piece(B3, 5, 6, b, B4),
    apply_captures(B4, 5, 6, attacker, Final),
    \+ find_king(Final, _, _).

test_win_defender_corner :-
    initial_board(11, B),
    set_piece(B, 0, 0, k, B1),
    check_win(B1, w).

run_board_tests :-
    format('--- Board Tests ---~n'),
    run_tests([
        test_board_setup,
        test_custodial_capture,
        test_capture_against_throne,
        test_king_capture_4_sides,
        test_win_defender_corner
    ]).
