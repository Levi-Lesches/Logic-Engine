# Logic-Engine
A Propositional Theorem Prover written in Dart

It's much easier to explain this project with an example: 

```
(p --> q) ^ (r --> s)
(q --> t) ^ (s --> u)
~(t ^ u)
x --> r
p
--------------------
∴ ~x
```

The theorem prover will output: 

```
1. (p --> q) ^ (r --> s) -- Given
2. (q --> t) ^ (s --> u) -- Given
3. ~(t ^ u) -- Given
4. x --> r -- Given
5. p -- Given
6. ~t V ~u -- De Morgan's Law (3)
7. r --> s -- Conjunctive Inference (1)
8. s --> u -- Conjunctive Inference (2)
9. q --> t -- Conjunctive Inference (2)
10. p --> q -- Conjunctive Inference (1)
11. q -- Detachment (10, 5)
12. t -- Detachment (9, 11)
13. ~u -- Disjunctive Inference (6, 12)
14. ~s -- Modus Tollens (8, 13)
15. ~r -- Modus Tollens (7, 14)
16. ~x -- Modus Tollens (4, 15)
```

### Coming Soon
- Indirect proofs
- A* search to guarantee the shortest proof
- Support for the chain rule
