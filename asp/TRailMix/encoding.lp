% clingo basic encoding
#include "connections_nswe.lp". % includes track types and transition definitions

%% SET-UP
time(0..N) :- global(N).

% define grid with all adjacent cells
% taken from kep's grid-functions.lp
% adjacent(OGcell, dir, Dcell) 
adjacent((X,Y),D,(X',Y')) :-  cell((X,Y),_), cell((X',Y'),_),
   move(D,DX,DY), X'=X+DX, Y'=Y+DY.

% define which adjacent cells can be reached
% can_dir(cell, dir) - cell directs from D to D'
can_dir((X,Y), D, D') :- cell((X,Y), TY), connection(TY, (D,D')).

% define which cell is reachable by train
% trainjacent(OGcell, InOG, OutOG, Dcell) - OGcell can direct a train to Dcell
% eg. trainjacent(A,In,Out,B) - if a train enters A from dir In it can exit A to dir Out and enter into cell B
trainjacent((X,Y), In, Out, (X', Y')) :- cell((X,Y), TY), adjacent((X,Y),Out,(X',Y')), 
   can_dir((X,Y), In, Out).
%trainjacent((X,Y),In, Out, (X', Y')) :- cell((X,Y), TY), adjacent((X,Y),Out,(X',Y')), 
%   connection(TY, (In, Out)).
% set train in "Fahrtrichtung"
position(ID, (X,Y), T, D) :- train(ID), start(ID, (X,Y), T, D), time(T).
position(ID, (X,Y), T+1, D) :- train(ID), start(ID, (X,Y), T, D), time(T).


%% GENERATORS

% move a train
% Add position(ID, (X,Y), T_Start + 1, Out)
{position(ID, (X',Y'), T', Out)} :- position(ID, (X,Y), T, D),
   inverse(D,In), trainjacent((X,Y), In, Out, (X',Y')), 
   time(T), time(T'), T' = T+1.

% allow train to wait
{position(ID, POS, T', D)} :- position(ID, POS, T, D), time(T), time(T'),
    T'= T+1.

% end train when it reaches its destination
finish(ID, T) :- position(ID,(X,Y),T,D), end(ID,(X,Y),T'), 
   T<=T'.

% translate train moves into action

% On t_start we move forward
action(train(ID), move_forward, T):- start(ID, (_,_), T, _).

action(train(ID), move_left, T) :- position(ID, (X,Y), T, Dir),  position(ID, (X+DX,Y+DY), 
			T+1, Dir2), cell((X,Y), TY), choice(TY, Dir), 
			move_left(Dir, Dir2), move(Dir2, DX, DY).

action(train(ID), move_right, T) :- position(ID, (X,Y), T, Dir),  position(ID, (X+DX,Y+DY), T+1, Dir2), cell((X,Y), TY), choice(TY, Dir), move_right(Dir, Dir2), move(Dir2, DX, DY).

% On t_start we do not wait
action(train(ID), wait, T) :- position(ID, (X,Y), T, _),  position(ID, (X,Y), T+1, _), not start(ID, (_,_), T, _).
% wait action for time that before the t_start of a train
action(train(ID), wait, T) :- start(ID, (_,_), T1, _), time(T), T < T1.

action(train(ID), move_forward, T) :- not finish(ID, T), position(ID, (_,_), T, _), not action(train(ID), wait, T), not action(train(ID), move_left, T), not action(train(ID), move_right, T).


%% SINGLE TRAIN CONSTRAINTS

% trains are not allowed to do a U-turn
:- position(ID, (X,Y), T, D), position(ID, (X',Y'), T', DI), inverse(D,DI),
   T'=T+1.

% we can't have ONE train in two positions at any time step
:- time(T), train(ID), {position(ID, _, T, _)} > 1.


% we can't have multiple finishes for one train
% train must stop after finish
:- finish(ID,T), position(ID, (X,Y), T', D), time(T), time(T'), T'>T.

% all trains must finish
:- train(ID), not finish(ID,_).

%% TRAIN COORDINATION CONSTRAINTS

% trains are not allowed to pass through e.o.
:- trainjacent(A, _, D', B), position(ID,A,T,D), position(ID',B,T,D'),
   inverse(D,D'), ID<ID'. 

% trains can't be in the same cell at the same time
:- position(ID,K,T,_), position(ID',K,T,_), ID>ID'.

%% OBJECTIVES
% Finish as many trains as possible 
#maximize { 1@4, ID, T : finish(ID, T) }.	% maybe not needed

% Finish as early as possible
#minimize { T@3, ID : finish(ID, T) }.

% Reduce unnecessary waiting
#minimize { 1@2, ID, T : action(train(ID), wait, T) }.		% maybe not needed

% Prefer fewer distinct waiting episodes
% prefer wait, wait, go over go, wait, go wait
wait_start(ID, T) :- action(train(ID), wait, T), not action(train(ID), wait, T-1).
#minimize { 1@1, ID, T : wait_start(ID, T) }.

%#show finish/2.
%#show position/4.
#show action/3.
%#show trainjacent/4.
%#show adjacent/3.
