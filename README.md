Codes for "[A Generalized Scalarization Method for Evolutionary Multi-objective Optimization](https://arxiv.org/abs/2212.01545)" (AAAI-23 Oral).

MOEA/D-GGR are implemented on the PlatEMO platform (version 3.x). Please place the codes in path "PlatEMO\Algorithms\Multi-objective optimization\MOEADGGR".

---

### 04/2024:
We develop a generational version of MOEA/D-GGR (denoted as `gMOEA/D-GGR`), whose framework is similar to [gMOEA/D-AGR](https://ieeexplore.ieee.org/abstract/document/7070748/). gMOEA/D-GGR could perform better when the reference point changes frequently. Moreover, we employ a greedy trick in the replacement procedure of the algorithm, which enhances its convergence performance. This trick is highlighted as follows:
```matlab
% index_Pt(i) = i;  % Pt should not be shuffled since we assume the i-th solution of Pt corresponds to the original solution of i-th subproblem.
[~,index_Pt(i)] = min(g(:,i));  % improve the convergence by this greedy method; it is helpful to find the boundary of the concave PF when p=1
```

### 01/2025:
We integrate a weight vector adjustment strategy, similar to that proposed in [AdaW](https://direct.mit.edu/evco/article-abstract/28/2/227/94991/What-Weights-Work-for-You-Adapting-Weights-for-Any), into gMOEA/D-GGR. Specifically, [cone dominance](https://dl.acm.org/doi/abs/10.1145/3071178.3071319) is employed to replace Pareto dominance during the archive updating process in AdaW. The new algorithm is denoted as `gMOEA/D-GGRAW`.