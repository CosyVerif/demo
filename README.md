Demonstration of CosyVerif
==========================

Scenario
--------

1.  Administrator create users A & B
2.  User A creates project P
3.  User A sets project P as private
4.  User B tries to access project B
    (failure)
5.  User A sets project B as public
6.  User A creates model M in project P
7.  User A edits model M
8.  User B edits model M
    [failure]
9.  User A executes generator on model M
    User B sees the changes
10. User A adds user B to project P
11. User B executes simulator on model M
12. Users A & B use the simulator concurrently
13. User A creates model N
14. User A executes burst on model N
15. User A updates model N to show unpatching

