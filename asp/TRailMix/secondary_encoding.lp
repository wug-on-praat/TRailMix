% secondary encoding: make use of previously calculated plan to adjust to malfunction
#include "connections_nswe.lp". % includes track types and transition definitions

% Create actions before malfunction
% Rely on past constraint rules we get from the malfunction
past_time(0..T):- track_malfunction((_,_), _, T).

time(T_mal..T):- track_malfunction((_,_), _, T_mal), global(T).

possible_action(move_forward).
possible_action(wait).
possible_action(move_left).
possible_action(move_right).

{action(train(ID), ACT, T)} :- train(ID), possible_action(ACT), past_time(T).

:- past_time(T), train(ID), {action(train(ID), ACT, T)} > 1.

% Create actions after malfunction
% Consequence denotes of trains ride over a track malfunction
consequence(train(ID), (X, Y), T) :- planned_position(ID, (X, Y), T, _), track_malfunction((X, Y), Dur_mal, T_mal), Dur_mal + T_mal >= T.

action(train(ID), ACT, T+Time+1) :- planned_action(train(ID), ACT, T), track_malfunction((_, _), _, Time), not consequence(train(ID), (_, _), _).

% Create positions from planned_position
position(ID, (X,Y), T, D) :- planned_position(ID, (X,Y), T, D), not consequence(train(ID), (_, _), _).

% Next step: if there is a consequence, reschedule only these trains
% There is at least one consequence
% TODO: optional add adjacent, can_dir, trainjacent as facts from initial encoding.
adjacent((X,Y),D,(X',Y')) :-  cell((X,Y),_), cell((X',Y'),_),
   move(D,DX,DY), X'=X+DX, Y'=Y+DY, consequence(train(_), (_, _), _).

can_dir((X,Y), D, D') :- cell((X,Y), TY), connection(TY, (D,D')), consequence(train(_), (_, _), _).

trainjacent((X,Y), In, Out, (X', Y')) :- cell((X,Y), TY), adjacent((X,Y),Out,(X',Y')), 
   can_dir((X,Y), In, Out), consequence(train(_), (_, _), _).


{position(ID, (X',Y'), T', Out)} :- position(ID, (X,Y), T, D),
   inverse(D,In), trainjacent((X,Y), In, Out, (X',Y')), 
   time(T), time(T'), T' = T+1, consequence(train(ID), (_, _), _).

% allow train to wait
{position(ID, POS, T', D)} :- position(ID, POS, T, D), time(T), time(T'),
    T'= T+1, consequence(train(ID), (_, _), _).

% end train when it reaches its destination
finish(ID, T) :- position(ID,(X,Y),T,D), end(ID,(X,Y),T'), 
   T<=T', consequence(train(ID), (_, _), _).

% translate train moves into action


action(train(ID), move_left, T) :- position(ID, (X,Y), T, Dir),  position(ID, (X+DX,Y+DY), 
			T+1, Dir2), cell((X,Y), TY), choice(TY, Dir), 
			move_left(Dir, Dir2), move(Dir2, DX, DY), consequence(train(ID), (_, _), _).

action(train(ID), move_right, T) :- position(ID, (X,Y), T, Dir),  position(ID, (X+DX,Y+DY), T+1, Dir2), cell((X,Y), TY), choice(TY, Dir), move_right(Dir, Dir2), move(Dir2, DX, DY), consequence(train(ID), (_, _), _).

action(train(ID), move_forward, T) :- not finish(ID, T), position(ID, (_,_), T, _), not action(train(ID), wait, T), not action(train(ID), move_left, T), not action(train(ID), move_right, T), consequence(train(ID), (_, _), _).

action(train(ID), wait, T) :- position(ID, (X,Y), T, _),  position(ID, (X,Y), T+1, _), consequence(train(ID), (_, _), _).


%% SINGLE TRAIN CONSTRAINTS

% trains are not allowed to do a U-turn
:- position(ID, (X,Y), T, D), position(ID, (X',Y'), T', DI), inverse(D,DI), consequence(train(ID), (_, _), _),
   T'=T+1.

% we can't have ONE train in two positions at any time step
:- time(T), train(ID), {position(ID, _, T, _)} > 1, consequence(train(ID), (_, _), _).


% we can't have multiple finishes for one train
% train must stop after finish
:- finish(ID,T), position(ID, (X,Y), T', D), time(T), time(T'), T'>T, consequence(train(ID), (_, _), _).

% all trains must finish
:- train(ID), not finish(ID,_), consequence(train(ID), (_, _), _).

%% TRAIN COORDINATION CONSTRAINTS

% trains are not allowed to pass through e.o.
%:- trainjacent(A, _, D', B), position(ID,A,T,D), position(ID',B,T,D'),
 %  inverse(D,D'), ID<ID'. 

% trains can't be in the same cell at the same time
%:- position(ID,K,T,_), position(ID',K,T,_), ID>ID'.


% Loop: Next next step: if there is a collision, reschedule only these trains 
% Idea: if there is a consequence, reschedule everything after N rescheduled trains 

#show action/3.
#show planned_position/4.
#show position/4.
