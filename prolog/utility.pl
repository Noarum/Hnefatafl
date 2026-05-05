% utility.pl
% Heuristic and utility functions for Hnefatafl

:- consult('Hnefatafl.pl').
:- consult('moves.pl').

% =========================
% HELPERS
% =========================

board_size(Board, S) :-
    length(Board, S).

get_king_pos(Board, KR, KC) :-
    nth0(KR, Board, Row),
    nth0(KC, Row, k), !.

% =========================
% KING CAPTURE LOGIC (PDF compliant)
% =========================

% A king is captured if surrounded on 4 sides by attackers, walls, or corners.
% PDF: "If the king is against a wall... surrounding the other three sides."
% PDF: "If the king is against a corner... surrounding the other two sides."
is_king_captured(Board, KR, KC) :-
    board_size(Board, S),
    Max is S - 1,
    findall(1,
        (
            member((DR,DC), [(1,0),(-1,0),(0,1),(0,-1)]),
            NR is KR + DR,
            NC is KC + DC,
            (
                \+ within_bounds(Board, NC, NR) ; % Wall is hostile
                is_corner_cell(NC, NR, Max) ;     % Corner is hostile
                (within_bounds(Board, NC, NR), get_piece(Board, NC, NR, b)) % Attacker
            )
        ),
        L),
    length(L, Count),
    Count >= 4.

is_corner_cell(0, 0, _).
is_corner_cell(0, Max, Max).
is_corner_cell(Max, 0, Max).
is_corner_cell(Max, Max, Max).

% =========================
% HEURISTICS
% =========================

% Manhattan distance to nearest corner (lower is better for defender)
king_min_corner_distance(Board, KR, KC, MinDist) :-
    board_size(Board, S),
    Max is S - 1,
    D1 is KR + KC,
    D2 is KR + (Max - KC),
    D3 is (Max - KR) + KC,
    D4 is (Max - KR) + (Max - KC),
    MinDist is min(min(D1, D2), min(D3, D4)).

% Number of squares the king can move to
king_mobility(Board, KR, KC, Score) :-
    moves_from_piece(Board, KC, KR, defender, Moves),
    length(Moves, Score).

% Material balance
material_score(Board, Score) :-
    findall(1, (nth0(_, Board, Row), member(P, Row), P == w), Def),
    findall(1, (nth0(_, Board, Row), member(P, Row), P == b), Att),
    length(Def, Dn),
    length(Att, An),
    Score is Dn - An.

% Check if the king has a clear straight path to any corner
king_escape_routes(Board, KR, KC, Count) :-
    board_size(Board, S),
    Max is S - 1,
    findall(1,
        (
            member((TR, TC), [(0,0), (0, Max), (Max, 0), (Max, Max)]),
            (KR == TR ; KC == TC), % Must be in same row or column
            path_clear(Board, KC, KR, TC, TR)
        ),
        L),
    length(L, Count).

% =========================
% UTILITY
% =========================

% Always return score from the defender's perspective (Maximizer)
utility(Board, _, Score) :-
    ( check_win(Board, w) -> Score = 1000000 ;
      check_win(Board, b) -> Score = -1000000 ;
      get_king_pos(Board, KR, KC) ->
        ( king_surrounded(Board, KC, KR) -> Score = -1000000 ;
          calculate_utility(Board, KR, KC, Score)
        )
      ;
      Score = -1000000 % King missing
    ).

calculate_utility(Board, KR, KC, Score) :-
    board_size(Board, S),
    Max is S - 1,
    king_min_corner_distance(Board, KR, KC, Dist),
    king_mobility(Board, KR, KC, Mob),
    material_score(Board, Mat),
    king_escape_routes(Board, KR, KC, Routes),
    
    % Heuristic weighting
    CornerScore   is (Max * 2 - Dist) * 50,
    MobilityScore is Mob * 20,
    MaterialScore is Mat * 100,
    RouteScore    is Routes * 2000, % Very high priority for escape paths
    
    Score is CornerScore + MobilityScore + MaterialScore + RouteScore.