% secondary encoding: make use of previously calculated plan to adjust to malfunction
#include "connections_nswe.lp". % includes track types and transition definitions

%% Environment Set-up
% future time steps
time(T_mal+1..T):- track_malfunction((_,_), _, T_mal), global(T).

%% Past Time Steps

% Create actions before malfunction
% Rely on past constraint rules we get from the malfunction
past_time(0..T):- track_malfunction((_,_), _, T).

% translates current_position into position 
position(ID, P, T, D) :- current_position(ID, P, T, D).

% translate action constraints (from base encoding) into action atoms
{action(train(ID), Act, T)} :- train(ID), possible_action(Act), past_time(T).

% only one action per train an time step allowed
:- past_time(T), train(ID), {action(train(ID), ACT, T)} > 1.


%% Unstarted Trains
% Initialize trains that didn't start before the malfunction occurred
position(ID, P, T, D) :- train(ID), start(ID, P, T, D), time(T), not current_position(ID, _, _, _).
position(ID, P, T+1, D) :- train(ID), start(ID, P, T, D), time(T), not current_position(ID, _, _, _).
action(train(ID), move_forward, T) :- start(ID, (_,_), T, _), not current_position(ID, _, _, _).
action(train(ID), wait, T) :- start(ID, (_,_), T1, _), time(T), T_mal < T < T1, track_malfunction((_, _), _, T_mal), not current_position(ID, _, _, _).


%% Train Replanning Behaviour
% Decide if a train needs replanning or keeps its original schedule

% Consequence: train is affected by a track malfunction and has to be recalculated
consequence(train(ID), P, T) :- planned_position(ID, P, T, _), track_malfunction(P, Dur_mal, T_mal), Dur_mal + T_mal >= T.

% planned is a train that is not affected by the malfunction and we don't want to reroute it
{planned(ID)}:- train(ID), not consequence(train(ID), _, _).
% Prioritize planned trains when solving
#heuristic planned(ID): train(ID). [100, true]


%% No Consequences
% For trains which do not have a consequence (if train is planned, copy to action)
action(train(ID), Act, T+T_mal+1) :- planned(ID), planned_action(train(ID), Act, T), track_malfunction((_, _), _, T_mal), not consequence(train(ID), (_, _), _).

% Create positions from planned_position (if train is planned, copy to position)
position(ID, P, T, D) :- planned(ID), planned_position(ID, P, T, D), not consequence(train(ID), (_, _), _).


%% Consquence (not all trains are planned)

% signifiers whether train has to be recalculated
% if we a consequence in a train, we have to reroute
calculate(ID) :- consequence(train(ID), _, _).
% if calculated train collides with planned train, we have to reroute planned train
calculate(ID) :- train(ID), not planned(ID).

%% Base Encoding (only for rescheduled agents)
% TODO: optional add adjacent, trainjacent as facts from initial encoding.
adjacent((X,Y), D, (X',Y')) :-  cell((X,Y), _), cell((X', Y'), _), move(D, DX, DY), X'=X+DX, Y'=Y+DY, calculate(_).

trainjacent(P, In, Out, P') :- cell(P, TY), adjacent(P, Out, P'), connection(TY, (In, Out)), calculate(_).

% move a train or wait
{position(ID, P', T+1, Out)} :- position(ID, P, T, D), inverse(D,In), trainjacent(P, In, Out, P'), time(T+1), calculate(ID).

{position(ID, P, T+1, D)} :- position(ID, P, T, D), time(T+1), calculate(ID).

% end train when it reaches its destination
finish(ID, T) :- position(ID, P, T, D), end(ID, P, _), calculate(ID).

% translate train moves into action

action(train(ID), move_left, T) :- position(ID, (X,Y), T, Dir),  position(ID, (X+DX,Y+DY), T+1, Dir2), cell((X,Y), TY), choice(TY, Dir), move_left(Dir, Dir2), move(Dir2, DX, DY), calculate(ID).

action(train(ID), move_right, T) :- position(ID, (X,Y), T, Dir),  position(ID, (X+DX,Y+DY), T+1, Dir2), cell((X,Y), TY), choice(TY, Dir), move_right(Dir, Dir2), move(Dir2, DX, DY), calculate(ID).

action(train(ID), move_forward, T) :- not finish(ID, T), position(ID, (_,_), T, _), not action(train(ID), wait, T), not action(train(ID), move_left, T), not action(train(ID), move_right, T), calculate(ID).

action(train(ID), wait, T) :- position(ID, P, T, _),  position(ID, P, T+1, _), not start(ID, _, T, _), calculate(ID).


%% SINGLE TRAIN CONSTRAINTS

% we can't have ONE train in two positions at any time step
:- time(T), train(ID), {position(ID, _, T, _)} > 1, calculate(ID).

% we can't have multiple finishes for one train
% train must stop after finish
:- finish(ID, T), position(ID, _, T', _), time(T), time(T'), T' > T, calculate(ID).

% all trains must finish
:- train(ID), not finish(ID, _), calculate(ID).

%% TRAIN COORDINATION CONSTRAINTS

% trains are not allowed to pass through e.o.
:- trainjacent(P', _, D', P), position(ID, P', T, D), position(ID', P, T, D'), inverse(D, D'), ID < ID'. 

% trains can't be in the same cell at the same time
:- cell(P, _), time(T), 2 { position(ID, P, T, _) : train(ID) }.

%% OBJECTIVES

% we want as many OG train plans as possible
#maximize { 1@3, ID : planned(ID)}.

% Finish as early as possible
% Using action instead of finish(ID, T) decreased running time from 180 seconds to 2.2 seconds.
#minimize { 1@2, ID, T : action(train(ID), _, T) }.

% Prefer fewer distinct waiting episodes
% prefer wait, wait, go over go, wait, go wait
wait_start(ID, T) :- action(train(ID), wait, T), action(train(ID), A, T-1), A != wait.
#minimize { 1@1, ID, T : wait_start(ID, T) }.


#show consequence/3.
#show planned/1.
#show calculate/1.

