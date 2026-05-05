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
depth(medium, 2).
depth(hard, 3).

% =========================
% MOVE ORDERING
% =========================

% Sort moves by heuristic value (higher = better for current player)
order_moves(Board, Player, Moves, OrderedMoves) :-
    findall(Score-Move,
        (member(Move, Moves), move_heuristic(Board, Player, Move, Score)),
        ScoredMoves),
    sort(ScoredMoves, Sorted),  % sort/2 sorts by first argument (Score)
    reverse(Sorted, Reversed),  % highest scores first
    findall(Move, member(_-Move, Reversed), OrderedMoves).

move_heuristic(Board, w, move(X1,Y1,X2,Y2), Score) :-
    % For defender: prioritize king moves toward corners
    (get_piece(Board, X1, Y1, k) ->
        board_size(Board, S), Max is S - 1,
        DistBefore is min(min(X1+Y1, X1+(Max-Y1)), min((Max-X1)+Y1, (Max-X1)+(Max-Y1))),
        DistAfter is min(min(X2+Y2, X2+(Max-Y2)), min((Max-X2)+Y2, (Max-X2)+(Max-Y2))),
        Score is (DistBefore - DistAfter) * 100  % Higher score for moves closer to corner
    ; Score = 0  % Non-king moves get neutral score
    ).

move_heuristic(Board, b, move(_,_,X2,Y2), Score) :-
    % For attacker: prefer moves toward the center (where king usually is)
    % Simple heuristic: distance to center
    board_size(Board, S),
    Center is S // 2,
    DistFromCenter is abs(X2 - Center) + abs(Y2 - Center),
    Score is 10 - DistFromCenter.  % Higher score for moves closer to center

% Terminal state: Win/Loss
alpha_beta(Board, _, _, _, _, none, Score) :-
    ( check_win(Board, w) ; check_win(Board, b) ),
    utility(Board, w, Score), !.

% Leaf node: Max depth reached
alpha_beta(Board, 0, _, _, _, none, Score) :-
    utility(Board, w, Score), !.

% Internal node
alpha_beta(Board, Depth, Alpha, Beta, Player, BestMove, BestScore) :-
    all_valid_moves(Board, Player, Moves),
    order_moves(Board, Player, Moves, OrderedMoves),
    ( OrderedMoves == [] ->
        % No moves available: loss for the player whose turn it is
        ( (Player == defender ; Player == w) -> BestScore = -1000000 ; BestScore = 1000000 ),
        BestMove = none
    ;
        NewDepth is Depth - 1,
        ( (Player == defender ; Player == w) ->
            % Maximizing
            evaluate_max(OrderedMoves, Board, NewDepth, Alpha, Beta, none, -1000002, BestMove, BestScore)
        ;
            % Minimizing
            evaluate_min(OrderedMoves, Board, NewDepth, Alpha, Beta, none, 1000002, BestMove, BestScore)
        )
    ).

% =========================
% MAXIMIZER (Defender)
% =========================

evaluate_max([], _, _, _, _, BestMove, BestScore, BestMove, BestScore).
evaluate_max([move(X1,Y1,X2,Y2)|Rest], Board, Depth, Alpha, Beta, CurBestMove, CurBestScore, BestMove, BestScore) :-
    apply_move(Board, X1, Y1, X2, Y2, w, NewBoard),
    alpha_beta(NewBoard, Depth, Alpha, Beta, b, _, Score),
    
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
    apply_move(Board, X1, Y1, X2, Y2, b, NewBoard),
    alpha_beta(NewBoard, Depth, Alpha, Beta, w, _, Score),
    
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