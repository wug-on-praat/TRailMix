% clingo basic encoding
#include "connections_nswe.lp". % includes track types and transition definitions

%% SET-UP
time(0..N) :- global(N).

% define grid with all adjacent cells
% taken from kep's grid-functions.lp
% adjacent(OGcell, dir, Dcell) 
adjacent((X,Y), D, (X',Y')) :-  cell((X,Y), _), cell((X', Y'), _), move(D, DX, DY), X'=X+DX, Y'=Y+DY.

% define which cell is reachable by train
% trainjacent(OGcell, InOG, OutOG, Dcell) - OGcell can direct a train to Dcell
% eg. trainjacent(A,In,Out,B) - if a train enters A from dir In it can exit A to dir Out and enter into cell B
trainjacent(P, In, Out, P') :- cell(P, TY), adjacent(P, Out, P'), connection(TY, (In, Out)).

% set train in "Fahrtrichtung"
% starting the train at timestep=0 created a problem, clingo rerouted the train correctly but flatland did not visualize it properly
position(ID, P, T, D) :- train(ID), start(ID, P, T, D), time(T).
position(ID, P, T+1, D) :- train(ID), start(ID, P, T, D), time(T).


%% GENERATORS

% move a train
% Add position(ID, (X,Y), T_Start + 1, Out)
{position(ID, P', T+1, Out)} :- position(ID, P, T, D), inverse(D,In), trainjacent(P, In, Out, P'), time(T+1).

% allow train to wait
{position(ID, P, T+1, D)} :- position(ID, P, T, D), time(T+1).

% end train when it reaches its destination
finish(ID, T) :- position(ID, P, T, _), end(ID, P, _).

% translate train moves into action

% On t_start we move forward
action(train(ID), move_forward, T) :- start(ID, (_,_), T, _).

action(train(ID), move_left, T) :- position(ID, (X,Y), T, Dir),  position(ID, (X+DX,Y+DY), T+1, Dir2), cell((X,Y), TY), choice(TY, Dir), move_left(Dir, Dir2), move(Dir2, DX, DY).

action(train(ID), move_right, T) :- position(ID, (X,Y), T, Dir),  position(ID, (X+DX,Y+DY), T+1, Dir2), cell((X,Y), TY), choice(TY, Dir), move_right(Dir, Dir2), move(Dir2, DX, DY).

% On t_start we do not wait
action(train(ID), wait, T) :- position(ID, P, T, _),  position(ID, P, T+1, _), not start(ID, _, T, _).
% wait action for time that before the t_start of a train
action(train(ID), wait, T) :- start(ID, (_,_), T1, _), time(T), T < T1.

action(train(ID), move_forward, T) :- not finish(ID, T), position(ID, (_,_), T, _), not action(train(ID), wait, T), not action(train(ID), move_left, T), not action(train(ID), move_right, T).


%% SINGLE TRAIN CONSTRAINTS

% we can't have ONE train in two positions at any time step
:- time(T), train(ID), 2 {position(ID, _, T, _)}.

% we can't have multiple finishes for one train
% train must stop after finish
% Changing (X,Y) to _ decreased grounding time from 80 seconds to 8 seconds
:- finish(ID, T), position(ID, _, T', _), time(T), time(T'), T' > T.

% all trains must finish
:- train(ID), not finish(ID, _).

%% TRAIN COORDINATION CONSTRAINTS

% trains are not allowed to pass through e.o.
:- trainjacent(P, _, D', P'), position(ID, P, T, D), position(ID', P', T, D'), inverse(D, D'), ID < ID'. 

% trains can't be in the same cell at the same time
:- cell(P, _), time(T), 2 { position(ID, P, T, _) : train(ID) }.

%% OBJECTIVES
% Finish as many trains as possible 
%#maximize { 1@4, ID : finish(ID, T) }.	% maybe not needed

% Finish as early as possible
#minimize { 1@3, ID, T : action(train(ID), _, T) }.

% Prefer waiting over moving
%#maximize { 1@2, ID, T : action(train(ID), wait, T) }.		% maybe not needed

% Prefer fewer distinct waiting episodes
% prefer wait, wait, go over go, wait, go wait
wait_start(ID, T) :- action(train(ID), wait, T), action(train(ID), A, T-1), A != wait.
#minimize { 1@1, ID, T : wait_start(ID, T) }.

#show finish/2.
%#show position/4.
%#show action/3.
%#show trainjacent/4.
%#show adjacent/3.
