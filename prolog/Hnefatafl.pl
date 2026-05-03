:- consult('moves.pl').

initial_board_9([
    [c, e, e, b, b, b, e, e, c],
    [e, e, e, e, b, e, e, e, e],
    [e, e, e, e, w, e, e, e, e],
    [b, e, e, e, w, e, e, e, b],
    [b, b, w, w, k, w, w, b, b],  % <-- Changed 't' to 'k'
    [b, e, e, e, w, e, e, e, b],
    [e, e, e, e, w, e, e, e, e],
    [e, e, e, e, b, e, e, e, e],
    [c, e, e, b, b, b, e, e, c]
]).

initial_board_11([
    [c, e, e, b, b, b, b, b, e, e, c],
    [e, e, e, e, e, b, e, e, e, e, e],
    [e, e, e, e, e, w, e, e, e, e, e],
    [b, e, e, e, e, w, e, e, e, e, b],
    [b, e, e, e, e, w, e, e, e, e, b],
    [b, b, e, e, e, k, e, e, e, b, b],  % <-- Changed 't' to 'k'
    [b, e, e, e, e, w, e, e, e, e, b],
    [b, e, e, e, e, w, e, e, e, e, b],
    [e, e, e, e, e, w, e, e, e, e, e],
    [e, e, e, e, e, b, e, e, e, e, e],
    [c, e, e, b, b, b, b, b, e, e, c]
]).

initial_board(9, Board) :- initial_board_9(Board).
initial_board(11, Board) :- initial_board_11(Board).

% Get Piece
get_piece(Board, X, Y, Piece) :-
    nth0(Y, Board, Row),
    nth0(X, Row, Piece).

% Set Piece
set_piece(Board, X, Y, Piece, NewBoard) :-
    nth0(Y, Board, OldRow, RestRows),
    nth0(X, OldRow, _, RestCells),
    nth0(X, NewRow, Piece, RestCells),
    nth0(Y, NewBoard, NewRow, RestRows).

% Bounds
within_bounds(Board, X, Y) :-
    length(Board, Size),
    X >= 0, X < Size,
    Y >= 0, Y < Size.



% =========================
% CAPTURE LOGIC
% =========================

find_king(Board, X, Y) :-
    nth0(Y, Board, Row),
    nth0(X, Row, k), !.

king_surrounded(Board, KX, KY) :-
    length(Board, S),
    Max is S - 1,
    findall(1,
        (
            member((DX,DY), [(1,0),(-1,0),(0,1),(0,-1)]),
            AX is KX + DX,
            AY is KY + DY,
            within_bounds(Board, AX, AY),
            get_piece(Board, AX, AY, P),
            (
                P == b ;
                (AX=:=0, AY=:=0) ;
                (AX=:=Max, AY=:=0) ;
                (AX=:=0, AY=:=Max) ;
                (AX=:=Max, AY=:=Max)
            )
        ),
        Blockers),
    length(Blockers, N),
    N >= 4.

check_one_direction(Board, X, Y, DX, DY, Player, NewBoard) :-
    X1 is X + DX,
    Y1 is Y + DY,
    X2 is X + 2*DX,
    Y2 is Y + 2*DY,
    within_bounds(Board, X1, Y1),
    get_piece(Board, X1, Y1, Mid),

    Mid \== e,
    Mid \== t,
    Mid \== c,
    Mid \== k,
    \+ piece_belongs_to(Player, Mid),

    (
        within_bounds(Board, X2, Y2),
        get_piece(Board, X2, Y2, End),
        (
            piece_belongs_to(Player, End) ;
            is_restricted(X2, Y2, Board)
        )
    ->
        set_piece(Board, X1, Y1, e, NewBoard)
    ;
        NewBoard = Board
    ).

check_one_direction(Board, _, _, _, _, _, Board).

apply_captures(Board, X, Y, Player, FinalBoard) :-
    check_one_direction(Board, X, Y, 1, 0, Player, B1),
    check_one_direction(B1, X, Y, -1, 0, Player, B2),
    check_one_direction(B2, X, Y, 0, 1, Player, B3),
    check_one_direction(B3, X, Y, 0, -1, Player, B4),

    (
        Player == b,
        find_king(B4, KX, KY),
        king_surrounded(B4, KX, KY)
    ->
        set_piece(B4, KX, KY, e, FinalBoard)
    ;
        FinalBoard = B4
    ).



% =========================
% APPLY MOVE
% =========================

apply_move(Board, X1, Y1, X2, Y2, Player, FinalBoard) :-
    valid_move(Board, X1, Y1, X2, Y2, Player),

    get_piece(Board, X1, Y1, Piece),

    length(Board, S),
    Max is S - 1,
    Center is S // 2,

    (
        (X1=:=Center, Y1=:=Center) -> OldVal = t ;
        (X1=:=0, Y1=:=0) -> OldVal = c ;
        (X1=:=Max, Y1=:=0) -> OldVal = c ;
        (X1=:=0, Y1=:=Max) -> OldVal = c ;
        (X1=:=Max, Y1=:=Max) -> OldVal = c ;
        OldVal = e
    ),

    set_piece(Board, X1, Y1, OldVal, TempBoard),
    set_piece(TempBoard, X2, Y2, Piece, TempBoard2),

    apply_captures(TempBoard2, X2, Y2, Player, FinalBoard).



% =========================
% WIN CONDITIONS
% =========================

check_win(Board, w) :-
    length(Board, S),
    Max is S - 1,
    (
        get_piece(Board, 0, 0, k) ;
        get_piece(Board, Max, 0, k) ;
        get_piece(Board, 0, Max, k) ;
        get_piece(Board, Max, Max, k)
    ).

check_win(Board, b) :-
    \+ (member(Row, Board), member(k, Row)).



% =========================
% PRINT
% =========================

print_board([]).
print_board([H|T]) :-
    write(H), nl,
    print_board(T).
