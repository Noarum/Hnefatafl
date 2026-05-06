% =========================
% PIECE OWNERSHIP
% =========================

piece_belongs_to(b, b).
piece_belongs_to(w, w).
piece_belongs_to(w, k).
piece_belongs_to(attacker, b).
piece_belongs_to(defender, w).
piece_belongs_to(defender, k).

% =========================
% RESTRICTED CELLS
% =========================

is_restricted(X, Y, Board) :-
    length(Board, S),
    Max is S - 1,
    Center is S // 2,
    (
        (X=:=0, Y=:=0) ;
        (X=:=Max, Y=:=0) ;
        (X=:=0, Y=:=Max) ;
        (X=:=Max, Y=:=Max) ;
        (X=:=Center, Y=:=Center)
    ).

% =========================
% PATH CHECK
% =========================

path_clear(Board, X1, Y1, X2, Y2) :-
    DX is sign(X2 - X1),
    DY is sign(Y2 - Y1),
    NextX is X1 + DX,
    NextY is Y1 + DY,
    (
        (NextX =:= X2, NextY =:= Y2)
    ->
        true
    ;
        get_piece(Board, NextX, NextY, e),
        path_clear(Board, NextX, NextY, X2, Y2)
    ).

% =========================
% MOVE VALIDATION
% =========================

valid_move(Board, X1, Y1, X2, Y2, Player) :-
    within_bounds(Board, X1, Y1),
    within_bounds(Board, X2, Y2),
    get_piece(Board, X1, Y1, Piece),
    piece_belongs_to(Player, Piece),
    get_piece(Board, X2, Y2, Dest),
    % Destination must be empty, or a special square the king is moving to
    (
        Dest == e ;
        (Piece == k, (Dest == t ; Dest == c))
    ),
    % Non-king pieces cannot land on restricted squares (already handled by Dest check above mostly)
    (
        is_restricted(X2, Y2, Board)
    ->  Piece == k
    ;   true
    ),
    ( X1 =:= X2 ; Y1 =:= Y2 ),
    \+ (X1 =:= X2, Y1 =:= Y2),
    path_clear(Board, X1, Y1, X2, Y2),
    % Requirement: pieces may not stop inside a sandwich.
    \+ landing_in_sandwich(Board, X2, Y2, Player, Piece).

is_hostile(Board, X, Y, _) :- \+ within_bounds(Board, X, Y), !.
is_hostile(Board, X, Y, Player) :-
    get_piece(Board, X, Y, Piece),
    (
        % Attacker cannot use the king as part of a sandwich capture.
        ((Player == attacker ; Player == b), (Piece == w ; Piece == t ; Piece == c)) ;
        ((Player == defender ; Player == w), (Piece == b ; Piece == t ; Piece == c))
    ).

landing_in_sandwich(Board, X, Y, Player, PieceMoved) :-
    PieceMoved \== k, % King is exempt from 2-sided sandwich rule
    (
        (H1 is X-1, H2 is X+1, is_hostile(Board, H1, Y, Player), is_hostile(Board, H2, Y, Player)) ;
        (V1 is Y-1, V2 is Y+1, is_hostile(Board, X, V1, Player), is_hostile(Board, X, V2, Player))
    ).

% =========================
% RAY-BASED GENERATION
% =========================

ray(Board, SX, SY, X, Y, DX, DY, Piece, Moves) :-
    NX is X + DX,
    NY is Y + DY,
    (
        within_bounds(Board, NX, NY),
        get_piece(Board, NX, NY, Cell),
        (
            Cell == e
        ->  Moves = [move(SX,SY,NX,NY)|Rest],
            ray(Board, SX, SY, NX, NY, DX, DY, Piece, Rest)
        ;
            (Piece == k, (Cell == t ; Cell == c))
        ->  Moves = [move(SX,SY,NX,NY)], !
        ;   
            Moves = [], !
        )
    ;   
        Moves = [], !
    ).

% =========================
% MOVE GENERATION
% =========================

moves_from_piece(Board, X, Y, Player, Moves) :-
    get_piece(Board, X, Y, Piece),
    piece_belongs_to(Player, Piece),
    findall(M,
        (
            member((DX,DY), [(1,0),(-1,0),(0,1),(0,-1)]),
            ray(Board, X, Y, X, Y, DX, DY, Piece, RayMoves),
            member(M, RayMoves)
        ),
        Moves).

all_valid_moves(Board, Player, Moves) :-
    findall(M,
        (
            nth0(Y, Board, Row),
            nth0(X, Row, Piece),
            piece_belongs_to(Player, Piece),
            moves_from_piece(Board, X, Y, Player, Ms),
            member(M, Ms)
        ),
        Moves).

% =========================
% WRAPPERS FOR BRIDGE
% =========================

get_valid_moves(Board, X, Y, Player, Moves) :-
    moves_from_piece(Board, X, Y, Player, Moves).

get_all_moves(Board, Player, Moves) :-
    all_valid_moves(Board, Player, Moves).