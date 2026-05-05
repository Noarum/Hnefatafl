% ai.pl
% Alpha-Beta Pruning AI for Hnefatafl

:- consult('moves.pl').
:- consult('utility.pl').

% =========================
% AI ENTRY
% =========================

choose_ai_move(Board, Player, Difficulty, BestMove) :-
    depth(Difficulty, D),
    % Bounds should be slightly outside the range of win/loss scores
    alpha_beta(Board, D, -1000001, 1000001, Player, BestMove, _).

depth(easy, 1).
depth(medium, 3).
depth(hard, 5).

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