% Facts
% passengers(ID, Passengers)
passengers(0, 100).
passengers(1, 200).

% Allocate cost per train from weights and passengers
% total_driving_time(ID, Total_driving_time)
total_driving_time(ID, T * P) :- finish(ID, T), passengers(ID, P).

% Minimize cost
#minimize { Total_driving_time@2, ID, Total_driving_time : total_driving_time(ID, Total_driving_time) }.



% TBD Add train stops and distribution of passengers per destination
% For now adding passengers to the train is not considered
% in flatland V4 there will be a waypoint(ID, Order, (X, Y), Direction, Min_Arrival, Max_Departure).
% For now changing trains is not considered.

% Facts
% passengers(ID, End_station, Passengers)
passengers(0, (10,15), 100).
passengers(0, (20,25), 300).
passengers(1, (20, 25), 200).
passengers(1, (10, 15), 400).

% Allocate cost per train from weights and passengers
% total_driving_time(ID, Total_driving_time)
total_driving_time(ID, S) :- train(ID), S = #sum {T * P, X, Y : finish(ID, (X, Y), T), passengers(ID, (X, Y), P)}.

% Minimize cost
#minimize { Total_driving_time@2, ID, Total_driving_time : total_driving_time(ID, Total_driving_time) }.
