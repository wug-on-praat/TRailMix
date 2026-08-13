# Example Environments

- **env_016--3_2**
    - 20x20, 3 trains, small environment
    - good for testing for consequences (no collisions)
    - testing malfunctions:
        - simple reschedule: ((17,12), time=3, dur=5) - train 0 waits for 1 step
        - complex reschedule: ((6,13),time=14,dur=12) - recalculates trains 0 and 2
        - simple reschedule: ((8,14)time=15,dur=10) - reroutes train 0 (rightmost upper corner)

- **env_028--2_2**
    - 20x15, 2 trains, small environment
    - good for testing consequences with collisions
    - can create accidents
    - testing malfunctions:
        - simple reschedule: ((6, 1), 14, 5) - train 1 waits
        - complex reschedule: ((12, 1), 5, 9) - makes both trains wait

- **env_033--5_5**
    - 25x40, 5 trains, medium environment
    - good for testing consequences with collisions (maybe only simple consequence)
    - testing malfunctions:
        - simple reschedule: ((6, 15), 4, 5) - reroute train 2
        - simple reschedule: ((15, 11), 17, 20) - reroute train 3 via westmost track
        - complex reschedule: eastmost track, make two trains wait

- **env_035--10_8**
    - 25x40, 10 trains, large environment
    - testing malfunctions:
        - complex reschedule: 

## Extras

- env_027--2_2
    - 20x20, 2 trains, small environment
    - prob only for no consequence or no simple rescheduling

- env_030--20_4
    - 80x80, 20 trains, very large
    - not feasible for much testing (long running time)

- env_023--10_6
    - 50x50, 10 trains, large environment
    - very vacant, not ideal for paper

- why_doesnt_it
    - 25x40, 4 trains, medium environment
    - unclear why it doesn't work