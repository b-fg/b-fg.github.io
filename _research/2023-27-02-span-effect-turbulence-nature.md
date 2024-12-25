---
layout: article
title: From 3D to 2D turbulence in the wake of a circular cylinder
date: 2023-02-27 14:0:00+0100
tags: turbulence cylinder jfm
cover: /assets/images/2023-27-02-span-effect-turbulence-nature/vorticity_cover.svg
aside:
  toc: false
---


<!--more-->
In this post, I will briefly cover the work we published with my former PhD supervisors about the span effect of a circular cylinder on the turbulence nature of its wake.
The paper containing all the details is available [here](https://arxiv.org/pdf/2008.08933).

The main research question we tried to tackle was wether a critical cylinder span exists such that the wake turbulence statistics shift from 3D (classical -5/3 direct TKE spectra decay) to 2D (inverse energy cascade at -3 decay, or steeper).
And, if that was the case, why was that.

To do so, we conducted a series of simulations of incompressible flow past a circular cylinder at $Re=10^4$ with different span lengths, ranging from $L_z=10$ (span length non-dimensionalised with the cylinder diameter $D$) to pure 2-D simulations.
Below, an instantaneous snapshot of the vorticity field for each case is displayed.

![image-title-here](/assets/images/2023-27-02-span-effect-turbulence-nature/vorticity.svg){:class="img-responsive"}

Figure 1. Instantaneous vorticity $\omega_z$ (red is positive, blue is negative) at the $z=L_z/2$ plane for: $(a)$ $L_z=0$, $(b)$ $L_z=0.1$, $(c)$ $L_z=0.25$, $(d)$ $L_z=0.5$, $(e)$ $L_z=1$, $(f)$ $L_z=\pi$.
{: style="color:gray; font-size: 80%; text-align: center;"}


It is easy to observe that, as the span is reduced, small vortices get rearranged into larger coherent structures which also contain more energy. This is a visual example of the inverse energy cascade commonly found in 2D fluid flow systems.

To quantify the turbulence nature of the wake, different analysis were done in terms of energy spectra, TKE spatial plots, lift and drag forces, separation points, among others.
The most striking results were observed for the two-point correlation plots, displayed in Figure 2 together with the energy spectra.
It shows that the correlation of the velocity $v$ component along the span always decays with increasing distance $(d)$, except when the span is larger than 1 diameter.
In this case, a local correlation maxima is found near $d/D=1$ which indicates the presence of a large-scale structure.
At this wavelength, the Mode-B structures of the circular cylinder wake, naturally present at $Re=10^4$, have enough room to develop in the spanwise direction, differently from the other cases.
At the same time, the spectra of the $L_z=\pi$ case is the only one displaying a purely -5/3 decaying TKE far from the cylinder (c), further assuring the presence of a 3D large-scale structure which is able to feed the inertial and viscous scales of the energy cascade.

![image-title-here](/assets/images/2023-27-02-span-effect-turbulence-nature/energy_spectas_and_two-points_correlations.svg){:class="img-responsive"}

Figure 2.
Left: vertical velocity component temporal power spectra (PS) at different $(x, y)$ locations on the wake. (a): (2, 0.8), (b): (4, 0.8), (c): (8, 0.8).
The PS lines of each case are shifted a factor of 10 for clarity and the vertical axis ticks correspond to the $L_z=\pi$ case.
The dashed lines have a −11/3 slope and the dotted lines have a −5/3 slope.
Right: Two-point correlations along $z$ at the same $(x, y)$ locations as the left figures respectively.
{: style="color:gray; font-size: 80%; text-align: center;"}

To further assess this observation, the vertically-averaged TKE along the wake was computed as well as the lift coefficient, as displayed in Figure 3.
It can be observed that increasing the span from $L_z=\pi$ to $L_z=10$ did not yield significant differences in the TKE nor in the $C_L$.
On the other hand, the rest of the tested spans showed different results with increasing significance as the span was constricted.

![image-title-here](/assets/images/2023-27-02-span-effect-turbulence-nature/TKE_and_CL.svg){:class="img-responsive"}

Figure 3.
Left: Total TKE along the wake, where the TKE is computed from the normal Reynolds stresses and averaged on the vertical direction.
Right: TKE to $C_L$
Note that, in both plots, there is no significant difference between $L_z=\pi$ and $L_z=10$.
{: style="color:gray; font-size: 80%; text-align: center;"}

To summarise, a span of $L_z=\pi$ was enough to fully capture the 3D turbulence behaviour while smaller spans led to somewhat two-dimensionalised results.
This effect was attributed to the fact that the $L_z=\pi$ case was the only case allowing for Mode-B wake structures to develop, which are naturally present at $Re=10^4$.
Hence, if you are going to perform scale-resolving simulations of this test case, be sure to have a sufficiently long span.

:wink: