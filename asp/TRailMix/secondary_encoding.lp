% secondary encoding: make use of previously calculated plan to adjust to malfunction

time(1..T):- track_malfunction((_,_), _, T).

possible_action(move_forward).
possible_action(wait).
possible_action(move_left).
possible_action(move_right).

action(train(ID), ACT, T+Time+1):- planned_action(train(ID), ACT, T), track_malfunction((_,_),_, Time). 

{action(train(ID), ACT, T)} :- train(ID), possible_action(ACT), time(T).

:- time(T), train(ID), {action(train(ID), ACT, T)}>1.
 


%consequence() :- position, track_malfunction