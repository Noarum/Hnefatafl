% ai.pl
% Alpha-Beta Pruning AI for Hnefatafl

:- consult('moves.pl').
:- consult('utility.pl').
:- use_module(library(random)).

% =========================
% AI ENTRY
% =========================

% Convert board piece notation (b/w/k) to player side (attacker/defender)
normalize_player(b, attacker) :- !.
normalize_player(w, defender) :- !.
normalize_player(attacker, attacker) :- !.
normalize_player(defender, defender) :- !.

choose_ai_move(Board, Player, easy, BestMove) :-
    normalize_player(Player, NormalizedPlayer),
    all_valid_moves(Board, NormalizedPlayer, Moves),
    Moves \= [],
    random_member(BestMove, Moves).

choose_ai_move(Board, Player, medium, BestMove) :-
    normalize_player(Player, NormalizedPlayer),
    all_valid_moves(Board, NormalizedPlayer, Moves),
    Moves \= [],
    greedy_move(Board, NormalizedPlayer, Moves, BestMove).

choose_ai_move(Board, Player, hard, BestMove) :-
    normalize_player(Player, NormalizedPlayer),
    depth(hard, D),
    all_valid_moves(Board, NormalizedPlayer, Moves),
    Moves \= [],
    alpha_beta(Board, D, -1000001, 1000001, NormalizedPlayer, BestMove, _).

depth(hard, 2).

% Greedy one-ply move selection for medium difficulty.
greedy_move(Board, Player, Moves, BestMove) :-
    evaluate_moves(Moves, Board, Player, ScoreMoves),
    select_best_moves(Player, ScoreMoves, BestMoves),
    random_member(BestMove, BestMoves).

evaluate_moves([], _, _, []).
evaluate_moves([move(X1,Y1,X2,Y2)|Rest], Board, Player, [Score-move(X1,Y1,X2,Y2)|Tail]) :-
    apply_move(Board, X1, Y1, X2, Y2, Player, NewBoard),
    utility(NewBoard, defender, Score),
    evaluate_moves(Rest, Board, Player, Tail).

select_best_moves(defender, ScoreMoves, BestMoves) :-
    max_score_moves(ScoreMoves, BestMoves).
select_best_moves(attacker, ScoreMoves, BestMoves) :-
    min_score_moves(ScoreMoves, BestMoves).

max_score_moves([Score-Move|Rest], BestMoves) :-
    max_score_moves(Rest, Score, [Move], _BestScore, BestMoves).

max_score_moves([], BestScore, BestMoves, BestScore, BestMoves).
max_score_moves([Score-Move|Rest], CurrentBest, CurrentMoves, BestScore, BestMoves) :-
    ( Score > CurrentBest ->
        NextBest = Score,
        NextMoves = [Move]
    ; Score == CurrentBest ->
        NextBest = CurrentBest,
        append(CurrentMoves, [Move], NextMoves)
    ;   NextBest = CurrentBest,
        NextMoves = CurrentMoves
    ),
    max_score_moves(Rest, NextBest, NextMoves, BestScore, BestMoves).

min_score_moves([Score-Move|Rest], BestMoves) :-
    min_score_moves(Rest, Score, [Move], _BestScore, BestMoves).

min_score_moves([], BestScore, BestMoves, BestScore, BestMoves).
min_score_moves([Score-Move|Rest], CurrentBest, CurrentMoves, BestScore, BestMoves) :-
    ( Score < CurrentBest ->
        NextBest = Score,
        NextMoves = [Move]
    ; Score == CurrentBest ->
        NextBest = CurrentBest,
        append(CurrentMoves, [Move], NextMoves)
    ;   NextBest = CurrentBest,
        NextMoves = CurrentMoves
    ),
    min_score_moves(Rest, NextBest, NextMoves, BestScore, BestMoves).

order_moves(Moves, Board, defender, OrderedMoves) :-
    findall(Score-move(X1,Y1,X2,Y2),
        (
            member(move(X1,Y1,X2,Y2), Moves),
            apply_move(Board, X1, Y1, X2, Y2, defender, NewBoard),
            utility(NewBoard, defender, Score)
        ),
        ScoreMoves),
    keysort(ScoreMoves, Sorted),
    reverse(Sorted, Reversed),
    extract_moves(Reversed, OrderedMoves).

order_moves(Moves, Board, attacker, OrderedMoves) :-
    findall(Score-move(X1,Y1,X2,Y2),
        (
            member(move(X1,Y1,X2,Y2), Moves),
            apply_move(Board, X1, Y1, X2, Y2, attacker, NewBoard),
            utility(NewBoard, defender, Score)
        ),
        ScoreMoves),
    keysort(ScoreMoves, Sorted),
    extract_moves(Sorted, OrderedMoves).

extract_moves([], []).
extract_moves([_-Move|Rest], [Move|Tail]) :-
    extract_moves(Rest, Tail).

% =========================
% ALPHA-BETA
% =========================

% Terminal state: Win/Loss
alpha_beta(Board, _, _, _, _, none, Score) :-
    ( check_win(Board, w) ; check_win(Board, b) ),
    utility(Board, defender, Score), !.

% Leaf node: Max depth reached
alpha_beta(Board, 0, _, _, _, none, Score) :-
    utility(Board, defender, Score), !.

% Internal node
alpha_beta(Board, Depth, Alpha, Beta, Player, BestMove, BestScore) :-
    all_valid_moves(Board, Player, Moves),
    ( Moves == [] ->
        % No moves available: loss for the player whose turn it is
        ( Player == defender -> BestScore = -1000000 ; BestScore = 1000000 ),
        BestMove = none
    ;
        NewDepth is Depth - 1,
        ( Player == defender ->
            % Maximizing
            evaluate_max(Moves, Board, NewDepth, Alpha, Beta, none, -1000002, BestMove, BestScore)
        ;
            % Minimizing
            evaluate_min(Moves, Board, NewDepth, Alpha, Beta, none, 1000002, BestMove, BestScore)
        )
    ).

% =========================
% MAXIMIZER (Defender)
% =========================

evaluate_max([], _, _, _, _, BestMove, BestScore, BestMove, BestScore).
evaluate_max([move(X1,Y1,X2,Y2)|Rest], Board, Depth, Alpha, Beta, CurBestMove, CurBestScore, BestMove, BestScore) :-
    apply_move(Board, X1, Y1, X2, Y2, defender, NewBoard),
    alpha_beta(NewBoard, Depth, Alpha, Beta, attacker, _, Score),
    
    ( Score > CurBestScore ->
        NextBestScore = Score,
        NextBestMove = move(X1,Y1,X2,Y2)
    ;
        NextBestScore = CurBestScore,
        NextBestMove = CurBestMove
    ),
    
    NewAlpha is max(Alpha, NextBestScore),
    ( Beta =< NewAlpha ->
        % Pruning
        BestMove = NextBestMove,
        BestScore = NextBestScore
    ;
        evaluate_max(Rest, Board, Depth, NewAlpha, Beta, NextBestMove, NextBestScore, BestMove, BestScore)
    ).

% =========================
% MINIMIZER (Attacker)
% =========================

evaluate_min([], _, _, _, _, BestMove, BestScore, BestMove, BestScore).
evaluate_min([move(X1,Y1,X2,Y2)|Rest], Board, Depth, Alpha, Beta, CurBestMove, CurBestScore, BestMove, BestScore) :-
    apply_move(Board, X1, Y1, X2, Y2, attacker, NewBoard),
    alpha_beta(NewBoard, Depth, Alpha, Beta, defender, _, Score),
    
    ( Score < CurBestScore ->
        NextBestScore = Score,
        NextBestMove = move(X1,Y1,X2,Y2)
    ;
        NextBestScore = CurBestScore,
        NextBestMove = CurBestMove
    ),
    
    NewBeta is min(Beta, NextBestScore),
    ( NewBeta =< Alpha ->
        % Pruning
        BestMove = NextBestMove,
        BestScore = NextBestScore
    ;
        evaluate_min(Rest, Board, Depth, Alpha, NewBeta, NextBestMove, NextBestScore, BestMove, BestScore)
    ).