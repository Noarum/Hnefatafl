:- consult('../moves.pl').
:- consult('../Hnefatafl.pl').

% Test Helper: Create a sample board
sample_board([
    [c, e, e],
    [e, k, e],
    [c, e, c]
]).

test_all_valid_moves :-
    initial_board(9, B),
    all_valid_moves(B, attacker, AMoves),
    length(AMoves, AN),
    AN > 0,
    format('Attacker moves: ~w~n', [AN]),
    all_valid_moves(B, defender, DMoves),
    length(DMoves, DN),
    DN > 0,
    format('Defender moves: ~w~n', [DN]),
    write('test_all_valid_moves: passed'), nl.

run_moves_tests :-
    test_all_valid_moves.
