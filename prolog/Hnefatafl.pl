:- consult('moves.pl').

initial_board_9([
    [c, e, e, b, b, b, e, e, c],
    [e, e, e, e, b, e, e, e, e],
    [e, e, e, e, w, e, e, e, e],
    [b, e, e, e, w, e, e, e, b],
    [b, b, w, w, k, w, w, b, b],
    [b, e, e, e, w, e, e, e, b],
    [e, e, e, e, w, e, e, e, e],
    [e, e, e, e, b, e, e, e, e],
    [c, e, e, b, b, b, e, e, c]
]).

initial_board_11([
    [c, e, e, b, b, b, b, b, e, e, c],
    [e, e, e, e, e, b, e, e, e, e, e],
    [e, e, e, e, e, e, e, e, e, e, e],
    [b, e, e, e, e, w, e, e, e, e, b],
    [b, e, e, e, w, w, w, e, e, e, b],
    [b, b, e, w, w, k, w, w, e, b, b],
    [b, e, e, e, w, w, w, e, e, e, b],
    [b, e, e, e, e, w, e, e, e, e, b],
    [e, e, e, e, e, e, e, e, e, e, e],
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
    nth0(Y, Board, OldRow),
    replace_nth(X, Piece, OldRow, NewRow),
    replace_nth(Y, NewRow, Board, NewBoard).

replace_nth(0, Val, [_|T], [Val|T]).
replace_nth(Index, Val, [H|T], [H|NewT]) :-
    Index > 0,
    NextIndex is Index - 1,
    replace_nth(NextIndex, Val, T, NewT).

within_bounds(Board, X, Y) :-
    length(Board, S),
    X >= 0, X < S,
    Y >= 0, Y < S.

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
            (
                \+ within_bounds(Board, AX, AY) -> true ; % Wall
                get_piece(Board, AX, AY, P),
                ( P == b ; P == t ; (AX=:=0, AY=:=0) ; (AX=:=Max, AY=:=0) ; (AX=:=0, AY=:=Max) ; (AX=:=Max, AY=:=Max) )
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
    Mid \== e, Mid \== t, Mid \== c, Mid \== k,
    \+ piece_belongs_to(Player, Mid),
    (
        within_bounds(Board, X2, Y2),
        get_piece(Board, X2, Y2, End),
        (
            % Attacker (b) can capture using another 'b' or a restricted square
            (Player == b, (End == b ; is_restricted(X2, Y2, Board))) ;
            % Defender (w) can capture using another 'w' or a restricted square,
            % but NOT the king (k) as the king is unarmed.
            (Player == w, (End == w ; (is_restricted(X2, Y2, Board), End \== k)))
        )
    ->  set_piece(Board, X1, Y1, e, NewBoard), !
    ;   NewBoard = Board, !
    ).
check_one_direction(Board, _, _, _, _, _, Board).

apply_captures(Board, X, Y, Player, FinalBoard) :-
    get_piece(Board, X, Y, MovedPiece),
    ( MovedPiece == k, Player == w ->
        % King is unarmed and does not capture when it moves.
        FinalBoard = Board
    ;
        check_one_direction(Board, X, Y, 1, 0, Player, B1),
        check_one_direction(B1, X, Y, -1, 0, Player, B2),
        check_one_direction(B2, X, Y, 0, 1, Player, B3),
        check_one_direction(B3, X, Y, 0, -1, Player, B4),
        (
            (Player == b ; Player == attacker),
            find_king(B4, KX, KY),
            king_surrounded(B4, KX, KY)
        ->  set_piece(B4, KX, KY, e, FinalBoard)
        ;   FinalBoard = B4
        )
    ).

check_win(Board, b) :- \+ find_king(Board, _, _).
check_win(Board, w) :-
    length(Board, S), Max is S - 1,
    find_king(Board, KX, KY),
    ( (KX=:=0, KY=:=0) ; (KX=:=Max, KY=:=0) ; (KX=:=0, KY=:=Max) ; (KX=:=Max, KY=:=Max) ).
