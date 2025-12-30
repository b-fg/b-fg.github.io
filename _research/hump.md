---
layout: article
title: Machine learning-augmented computational models for wall-bounded turbulence
date: 2026-01-01
tags: turbulence wall-model GPU SOD2D PhD Pedro
cover: /assets/images/research/hump/hump.png
aside:
  toc: true
---

*by [Pedro Muñoz Hoyos](https://www.linkedin.com/in/pedro-munoz-hoyos/)*

Computational Fluid Dynamics (CFD) has complemented experiments for many years throughout the design process of machinery associated with the aerospace, naval, automotive, or energy industries, among many other disciplines. Yet the intrinsically complex nature of the turbulent flows characterizing these kinds of engineering applications, featuring a wide range of length and time scales that grow with the Reynolds number, has historically led CFD practitioners to settle for a trade-off between numerical fidelity and computational cost.

Typically, the three main approaches used to resolve a given flow configuration have been Reynolds-Averaged Navier-Stokes (RANS) equations, Large Eddy Simulation (LES), and Direct Numerical Simulation (DNS). Each of these effectively dictates how turbulence is treated at the mathematical level, either via a temporally averaged, spatially filtered, or direct formulation of the Navier-Stokes equations, respectively. In this manner, heading towards a more unaltered formulation of the Navier-Stokes equations would increase the physical rigor of the simulation at the expense of a higher computational cost.

As a result, employing any of the three aforementioned approaches has been largely influenced by the computational resources available during the design process. Due to the complex geometries and high Reynolds numbers of most industrial flow configurations, RANS has been the preferred choice for industrially oriented CFD, while LES and DNS have only been within reach of academic CFD for very geometrically simplistic canonical cases at much lower Reynolds numbers.

Unfortunately, despite the remarkable advancements in High-Performance Computing (HPC) of the last decades, driven by Moore's law, the harsh scaling of the grid requirements necessary to capture the multiscale nature of turbulent boundary layers with the Reynolds number keeps preventing the transition from RANS towards scale-resolving LES simulations of industrial-like turbulent flows.

### Wall modeling in large eddy simulation

To circumvent this computational barrier, CFD practitioners have historically opted for modeling the turbulence confined within the innermost part of the boundary layer while resolving the larger energy-containing turbulence in the outermost part in a classical LES manner. This strategy is best known in the literature as wall-modeled LES (WMLES).

Although there exist different families of wall modeling approaches, my research focuses on those derived from wall-stress formulations. These employ a standard LES approach all the way down to the wall, but maintain the grid sizing of the outermost region of the boundary layer across its innermost part adjacent to the wall. Furthermore, rather than imposing a no-slip velocity boundary condition at the wall, a wall-shear stress boundary condition is provided to the LES instead. In this manner, a so-called wall model fed with information from the LES solution at some distance away from the wall, ideally at the edge between the innermost and outermost regions, solves either a set of partial differential equations (PDE), ordinary differential equations (ODE), or algebraic equations for the wall-shear stress boundary condition.

### Modern challenges in wall modeling

Despite the maturity of this technique after arguably five decades since the pioneering ideas behind wall modeling were conceived, there are still many aspects of WMLES that require further investigation, such as the complex implementation on unstructured numerical solvers, typically required to resolve industrial-like geometries, or the fact that most wall models are based on equilibrium assumptions that do not hold well in non-equilibrium regimes of the boundary layer, like separation, transition, or reattachment.

These aspects, together with the notable recent advancements in artificial intelligence (AI), have motivated the exploration of machine learning (ML) strategies for augmenting or even replacing existing wall-stress models. ML has been proven to be an excellent tool for recognizing patterns and correlations in complex datasets, making it a promising tool to augment wall-stress models even under non-equilibrium flow regimes.

Nevertheless, in contrast to other disciplines of fluid dynamics where these type of methodologies have already been well established, such as active flow control (AFC), in which cost functions are straightforward to define, e.g., drag minimization, lift maximization, or aerodynamic efficiency maximization, defining these functions in the context of WMLES is by no means straightforward, thus making the adoption of these strategies a challenging task.

### Research goals

In light of the current state of the discipline, my research aims to leverage recent advancements in ML methodologies, in the context of fluid dynamics, to augment current wall-stress models, propose newer formulations able to handle non-equilibrium boundary layer regimes, and ease their implementation into unstructured numerical solvers. Therefore, the end goal of my research is to provide CFD practitioners with a tool capable of achieving more accurate numerical solutions of turbulent flows at a lower computational cost, thus promoting the design of better, more efficient machinery that consumes less fuel or has a wider operational range.

{:.text-align-center}
![test](/assets/images/research/hump/hump.png#center){:width="90%"}

Figure 1. Instantaneous Q-criterion isosurfaces colored by velocity magnitude.
{: style="color:gray; font-size: 80%; text-align: center;"}

### The role of high-fidelity data

The field of turbulence modeling has long sought accurate measures, either numerical or experimental, in order to formulate, improve, or validate its hypotheses. As introduced earlier, historically, these measures have been limited to very canonical cases at low Reynolds numbers, in the case of numerical simulations, and, in the case of experiments, datasets that could fall short for turbulence modeling purposes.

To address this issue, one of the first phases of my research has consisted of generating a high-fidelity LES dataset of the NASA Wall-Mounted Hump. This benchmark case, first proposed in 2004, features the relaminarization, separation, and reattachment of an incoming boundary layer over an infinite-span Glauert-Goldschmied profile. Thus, it provides direct exposure to several non-equilibrium boundary layer dynamics within a relatively simple geometrical setup, which is a very appealing trait from a wall modeling perspective.

After conducting a grid convergence study, the high-fidelity dataset was generated over a grid of approximately 2.2 billion nodes, ensuring the incoming boundary layer was properly resolved so that its near-the-wall dynamics could be studied. Besides the direct benefit that such a resolved simulation could be used to train a ML wall model in the future, the analysis of the near-the-wall dynamics helped shed light on critical aspects of non-equilibrium wall modeling.

A great example of such insights would be those about the consistency requirements mentioned several times in the literature between the pressure and convective terms of the boundary layer equations. These equations have been used extensively to construct both equilibrium and non-equilibrium wall models, the main difference between the two being the number of terms retained during their derivation. In this context, the results from this simulation proved that there exists indeed a balancing mechanism between pressure gradient and convection effects above the viscous wall region of the boundary layer when subjected to non-equilibrium conditions.

Consequently, it could be concluded that non-equilibrium models that only retain the pressure-gradient term while neglecting the convective term of the equations can be seen as physically inconsistent. Therefore, either both or none of these terms, as with equilibrium wall models, should be retained upon the construction of the models.

### Supercomputing facilities
One of the key benefits of the collaboration my research belongs to, between the Barcelona Supercomputing Center and TU Delft, is that I have direct access to supercomputing resources, allowing me to tackle such high-fidelity LES simulations as that of the NASA Wall-Mounted Hump.

In that particular case, a total of 100 NVIDIA H100 GPUs were accessed from the accelerated partition of the MareNostrum V supercomputer. Considering an average time step of the physical solution of 5.8 microseconds, these resources, combined with the accelerated CFD solver SOD2D, allowed the solution to converge at a rate of 1.5 physical seconds per day. This computation speed allowed conducting the simulation in a time horizon of several weeks, the exact duration depending on the queuing times of the MareNostrum V.

Additionally, a requirement that can sometimes be overlooked, high-fidelity simulations also involve massive amounts of disk storage. To put matters into perspective, the grid file of the NASA Wall-Mounted Hump was already over 280 gigabytes. In this manner, the storage provided by the Barcelona Supercomputing Center proved to be critical, allowing the extraction of instantaneous and time-averaged flow quantities on the order of 100 terabytes.

### Closing remarks
To summarize, my research focuses on bringing more accurate scale-resolving simulations to higher Reynolds number flows with a particular orientation towards industrial CFD. To achieve this, it aims to augment, or even substitute, current wall-modeling techniques by leveraging recent advancements in ML methodologies. Nevertheless, prior to the actual introduction of these methodologies into the wall-modeling paradigm, my research focused on the generation of high-fidelity datasets that can be used to train or better inform the design of such augmentation strategies. Lastly, as for the next steps of my research, I will start comparing the performance of current wall-stress models against this high-fidelity dataset to identify major improvement points for ML strategies.

{:.text-align-center}
![staggered grid](/assets/images/research/hump/MNV.jpg#center){:width="40%"}

Figure 2. MareNostrum V accelerated partition.
{: style="color:gray; font-size: 80%; text-align: center;"}