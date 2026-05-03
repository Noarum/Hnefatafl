:- consult('moves.pl').
:- use_module(library(random)).

% just placeholder to use for testing.
% should replace this logic with alpha-beta 

choose_ai_move(Board, Player, _Difficulty, Move) :-
	all_valid_moves(Board, Player, Moves),
	Moves \== [],
	random_member(Move, Moves).

