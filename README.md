Codes for "[A Generalized Scalarization Method for Evolutionary Multi-objective Optimization](https://arxiv.org/abs/2212.01545)" (AAAI-23 Oral).

MOEA/D-GGR are implemented on the PlatEMO platform (version 3.x). Please place the codes in path "PlatEMO\Algorithms\Multi-objective optimization\MOEADGGR".

---

### 04/2024:
We develop a generational version of MOEA/D-GGR (denoted as gMOEA/D-GGR), whose framework is similar to gMOEA/D-AGR of "Adaptive Replacement Strategies for MOEA/D". gMOEA/D-GGR could perform better when the reference point changes frequently.

### 01/2025:
We integrate a weight vector adjustment strategy, similar to that proposed in AdaW, into gMOEA/D-GGR. Furthermore, cone dominance is employed to replace Pareto dominance during the archive updating process in AdaW. The new algorithm is denoted as gMOEA/D-GGRAW.
> Ref:
> "What Weights Work for You? Adapting Weights for Any Pareto Front Shape in Decomposition-Based Evolutionary Multiobjective Optimisation" (AdaW)
> "Knee Point Based Evolutionary Multi-Objective Optimization for Mission Planning Problems" (cone dominance)