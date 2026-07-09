% secondary encoding: make use of previously calculated plan to adjust to malfunction

time(0..T):- track_malfunction((_,_), _, T).

possible_action(move_forward).
possible_action(wait).
possible_action(move_left).
possible_action(move_right).

consequence(train(ID), (X, Y), T) :- planned_position(train(ID), (X, Y), T, _), track_malfunction((X, Y), _, T).

% TODO: actions might be missing, we need to check that all actions are added until the trains finish
action(train(ID), ACT, T+Time+1):- planned_action(train(ID), ACT, T), track_malfunction((_,_),_, Time), not consequence(train(ID), (_,_), T+Time+1). 

{action(train(ID), ACT, T)} :- train(ID), possible_action(ACT), time(T).

:- time(T), train(ID), {action(train(ID), ACT, T)}>1.
 

#show action/3.
