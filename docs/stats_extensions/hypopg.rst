.. _hypopg:


hypopg
======

A hypothetical index is an index that doesn't exists on disk. It's therefore almost instant to create and doesn't add any IO cost, 
whether at creation time or at maintenance time. The goal is obviously to check if an index is useful before spending too much time, 
I/O and disk space to create it.

With this extension, you can create hypothetical indexes, and then with EXPLAIN check if PostgreSQL would use them or not.
