% controller.pl
% M3: Game Controller - Manages game flow, turns, and state updates.

:- consult('Hnefatafl.pl').
:- consult('ai.pl').

:- dynamic current_board/1.
:- dynamic current_player/1.
:- dynamic game_status/1.
:- dynamic ai_difficulty/1.

% GAME INITIALIZATION
opponent(attacker, defender).
opponent(defender, attacker).

switch_player :-
    current_player(P),
    opponent(P, Opp),
    retractall(current_player(_)),
    assertz(current_player(Opp)).
player_piece(attacker, b).
player_piece(defender, w).
terminal_status(attacker, attacker_won).
terminal_status(defender, defender_won).

init_game(Size) :-
    initial_board(Size, Board),
    commit_state(Board, attacker, ongoing). % Attacker always starts

commit_state(Board, Player, Status) :-
    retractall(current_board(_)),
    retractall(current_player(_)),
    retractall(game_status(_)),
    assertz(current_board(Board)),
    assertz(current_player(Player)),
    assertz(game_status(Status)).

get_current_player(Player) :- current_player(Player).
get_game_status(Status) :- game_status(Status).

% Support for GUI valid destination highlighting
get_valid_moves_for_piece(Row, Col, Moves) :-
    current_board(Board),
    current_player(Player),
    % GUI uses (row, col), bridge uses (row, col), so we pass (Col, Row) to moves.pl
    moves_from_piece(Board, Col, Row, Player, RawMoves),
    % Convert move(SX, SY, NX, NY) to move(NewRow, NewCol) for GUI
    findall(move(NY, NX), member(move(_, _, NX, NY), RawMoves), Moves).

% API FOR GUI (M5)
get_board(Board) :- current_board(Board).

is_valid_human_move(FR, FC, TR, TC) :-
    game_status(ongoing),
    current_player(Player),
    player_piece(Player, BoardPlayer),
    current_board(Board),
    valid_move(Board, FC, FR, TC, TR, BoardPlayer).

% MOVE EXECUTION
make_human_move(FR, FC, TR, TC) :-
    game_status(ongoing),
    current_player(Player),
    current_board(Board),
    player_piece(Player, BoardPlayer),
    ( valid_move(Board, FC, FR, TC, TR, BoardPlayer)
    ->  perform_move(Player, FC, FR, TC, TR)
    ;   format("Invalid move. Try again.~n"), fail
    ).

make_ai_move(Difficulty) :-
    game_status(ongoing),
    current_player(Player),
    current_board(Board),
    player_piece(Player, BoardPlayer),
    ( choose_ai_move(Board, BoardPlayer, Difficulty, move(X1, Y1, X2, Y2))
    ->  perform_move(Player, X1, Y1, X2, Y2)
    ;   % AI has no moves, forfeit
        opponent(Player, Opponent),
        terminal_status(Opponent, Status),
        commit_state(Board, Player, Status),
        format("~w has no moves. ~w wins!~n", [Player, Opponent])
    ).

apply_move(Board, X1, Y1, X2, Y2, Player, FinalBoard) :-
    valid_move(Board, X1, Y1, X2, Y2, Player),
    get_piece(Board, X1, Y1, Piece),
    % Determine what cell was there before (throne, corner, or empty)
    length(Board, S), Max is S - 1, Center is S // 2,
    ( (X1=:=Center, Y1=:=Center) -> Empty = t
    ; ( (X1=:=0, Y1=:=0) ; (X1=:=Max, Y1=:=0) ; (X1=:=0, Y1=:=Max) ; (X1=:=Max, Y1=:=Max) ) -> Empty = c
    ; Empty = e
    ),
    set_piece(Board, X1, Y1, Empty, B1),
    set_piece(B1, X2, Y2, Piece, B2),
    apply_captures(B2, X2, Y2, Player, FinalBoard).

perform_move(Player, X1, Y1, X2, Y2) :-
    player_piece(Player, BoardPlayer),
    current_board(Board),
    apply_move(Board, X1, Y1, X2, Y2, BoardPlayer, NextBoard),
    update_after_move(NextBoard, Player).

% STATE UPDATES & WIN CHECKS
update_after_move(Board, Player) :-
    ( check_win(Board, w) ->
        commit_state(Board, Player, defender_won),
        format("Defender wins! The King has escaped.~n")
    ; check_win(Board, b) ->
        commit_state(Board, Player, attacker_won),
        format("Attacker wins! The King has been captured.~n")
    ; opponent(Player, NextPlayer),
        commit_state(Board, NextPlayer, ongoing)
    ).

check_no_moves_loss :-
    game_status(ongoing),
    current_player(Player),
    current_board(Board),
    player_piece(Player, BoardPlayer),
    \+ (all_valid_moves(Board, BoardPlayer, Moves), Moves \= []),
    opponent(Player, Opponent),
    terminal_status(Opponent, Status),
    commit_state(Board, Player, Status),
    format("~w has no legal moves. ~w wins!~n", [Player, Opponent]).
check_no_moves_loss. % Succeed silently if moves exist

% MAIN GAME LOOP (Terminal)
play :-
    init_game,
    format("=== Hnefatafl ===~n"),
    format("Select AI Difficulty (easy, medium, hard): "),
    read(Diff),
    retractall(ai_difficulty(_)),
    assertz(ai_difficulty(Diff)),
    format("You are the DEFENDER (white). AI is the ATTACKER (black).~n"),
    format("Enter moves as: move(FromRow, FromCol, ToRow, ToCol).~n~n"),
    print_current_board,
    game_loop.

game_loop :-
    game_status(Status),
    Status \= ongoing,
    !,
    format("~n=== Game Over: ~w ===~n", [Status]).

game_loop :-
    check_no_moves_loss,
    game_status(ongoing),
    !,
    current_player(Player),
    format("~n--- ~w turn ---~n", [Player]),
    ( Player == defender
    -> human_turn
    ;  ai_difficulty(Diff), ai_turn(Diff)
    ),
    print_current_board,
    game_loop.

human_turn :-
    format("Your move: "),
    read(move(FR, FC, TR, TC)),
    ( make_human_move(FR, FC, TR, TC) -> true ; human_turn ).

ai_turn(Difficulty) :-
    format("AI is thinking (~w)...~n", [Difficulty]),
    make_ai_move(Difficulty).

% BOARD PRINTING
print_current_board :-
    current_board(Board),
    nl, print_board_rows(Board, 0).

print_board_rows([], _).
print_board_rows([Row|Rest], RowIdx) :-
    format("~`0t~w~2|  ", [RowIdx]),
    print_row(Row), nl,
    NextIdx is RowIdx + 1,
    print_board_rows(Rest, NextIdx).

print_row([]).
print_row([Cell|Rest]) :-
    format("~w ", [Cell]),
    print_row(Rest).