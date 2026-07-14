% secondary encoding: make use of previously calculated plan to adjust to malfunction

% Create actions before malfunction
% Rely on past constraint rules we get from the malfunction
time(0..T):- track_malfunction((_,_), _, T).

possible_action(move_forward).
possible_action(wait).
possible_action(move_left).
possible_action(move_right).

{action(train(ID), ACT, T)} :- train(ID), possible_action(ACT), time(T).

:- time(T), train(ID), {action(train(ID), ACT, T)} > 1.

% Create actions after malfunction
% Consequence denotes of trains ride over a track malfunction
consequence(train(ID), (X, Y), T) :- planned_position(train(ID), (X, Y), T, _), track_malfunction((X, Y), _, T).

:- consequence(train(_), (_, _), _).

action(train(ID), ACT, T+Time+1) :- planned_action(train(ID), ACT, T), track_malfunction((_, _), _, Time).

% Create positions from planned_position
position(ID, (X,Y), T, D) :- planned_position(ID, (X,Y), T, D).

% Next step: if there is a consequence, reschedule only these trains 
% Loop: Next next step: if there is a collision, reschedule only these trains 
% Idea: if there is a consequence, reschedule everything after N rescheduled trains 

#show action/3.
#show planned_position/4.
#show position/4.
