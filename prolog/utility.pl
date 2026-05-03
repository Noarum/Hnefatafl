% utility.pl
% M5: heuristic evaluation function.
% Consults board logic in Hnefatafl.pl and move logic in moves.pl.

:- consult('Hnefatafl.pl').
:- consult('moves.pl').

% --- Predicates ---
manhattan_distance(_R1, _C1, _R2, _C2, _D) :-
    % TODO: compute Manhattan distance between two cells.
    fail.

king_min_corner_distance(_KR, _KC, _MinDist) :-
    % TODO: compute minimum king distance to any corner.
    fail.

king_threat_count(_Board, _KR, _KC, _Count) :-
    % TODO: count attacking threats around the king.
    fail.

king_mobility(_Board, _KR, _KC, _Score) :-
    % TODO: estimate king legal mobility from current square.
    fail.

material_score(_Board, _Score) :-
    % TODO: evaluate material balance (defenders vs attackers).
    fail.

open_escape_routes(_Board, _KR, _KC, _Count) :-
    % TODO: count open routes from king to escape corners.
    fail.

utility(_Board, _Player, _Score) :-
    % Terminal checks first:
    %   king surrounded on all relevant sides -> -10000 (attacker wins)
    %   king on corner -> +10000 (defender wins)
    % Weighted heuristic:
    %   CornerScore   = (20 - CornerDist) * 50
    %   ThreatScore   = -(Threats * 150)
    %   MobilityScore = Mobility * 30
    %   MaterialScore = Material * 40
    %   RouteScore    = Routes * 80
    % Negate final score if Player = attacker.
    fail.
