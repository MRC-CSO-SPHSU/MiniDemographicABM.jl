# Draft Report  

Motivation 
==========

This package implements a simplified demographic model in the Julia language [Bezanson2015]. The model is inspired by the demographic portion of the Lone Parent Model implemented 
in the Python language [Gostoli2020]. 

The Julia language elegantly combines scripting capabilities featured by common interpreted lanaguages s.a. Python, R and Matlab with the run time performance 
distinguishing common procedural langauges s.a. C/C++ and Fortran.  In this way, novel methods in - and insightful knowledge out of computational sciences can 
emerge in a way that was not even possible before [Roesch2023]. 

Particularly, Software Engineering concepts behind the Julia language are highly distinguishable in facilitating software maintainability, code reuse 
and extensibility [Karpinski2019]. This enables and encourages excellent opportunities for rapid comprehesnive development and progress of highly-sophisticated 
computational tools. This can be possibly accomplished from a high number of programmers each may contribute, modify and improve a piece of code upon his/her specialized skills 
and domain of expertises, e.g. Agents.jl [Datseris2022] and ModellingToolkits.jl [Ma2021]. 

Aims
====

While the model can serve as a base for constructing sophisticated demographic-based ABMs in Socioeconomics, Healtheconomics, Social interactions etc., 
the main aim is to provide demosntrative practical examples for utilization of the existing ecosystem of state-of-the-art Julia packages.
With these examples, signficant learning overhead can be saved whether for new Julia programmers or modellers seeking a quick dive into the world of agent-based modelling 
within demographic-based computational social sciences.

When accomplishing a modelling task together with the associated necessary computational analysis s.a. the necessarily required model-based Sensitivity Analysis [Saltelli2020], 
it is recommended to invistigate the already existing state-of-the-art ecosystem of existing packages related to that computational modelling task. 
When a particular feature is not present or subject to tuning to cope with the requirements of specific case study, 
this provides an opportunity to either further contribute to that software or build upon this software another new software tool 
without excessive duplicated efforts. Meanwhile, this benefits the rapid growth of the ecosystem of Julia packages and the community.     

In the context of Sensitivity Analysis of ABMs, dozens of software packages exist that can be highly beneficial. 
Whatever package that looks reliable and worth to try to my knowledge, they are listed as checkboxes 
under [issue # 22](https://github.com/MRC-CSO-SPHSU/MiniDemographicABM.jl/issues/22). The usage of these packages is naturally accompained by technical issues 
in the code that need to be simulatenosuly resolved, e.g. simulation determinisms with fixed seed numbers within multi-threading environments. 
A list of such technical issues is given under [issue #18](https://github.com/MRC-CSO-SPHSU/MiniDemographicABM.jl/issues/18).  

Summary of Releses
==================

**Version 1** of this package highlighted 

1. the construction, modelling, simulation of demographic-based models using the highly recognized Agents.jl package [Datseris2022]. 
2. the extension of built-in space types with another space type identical to that used in the Lone Parent Model
3. the realization of unit tests for incermental rapid development

examples and links to specific code are highlighted in the technical part given below.   

**Version 2** demonstrates the utlization of existing state-of-the-art tools for local and global sensitivity analysis of simulation models, and 
particularly GlobalSensitivity.jl [Daxit2022]. Such tools correspond to generic code that are applicable to arbitrary simualtion functions, e.g. via calling 
the function: 

> gsa(f,...) # ... represents method specific arguments 

where $f$ is any arbitary function that is based upon 
- a simulation of an ABM or a system model or even 
- a function written in another programming langauge
Due to known limitations of common GSA methods s.a. Sobol [Saltili2002] and Morris indices [Campolomgp2007] in the context of ABM, straightforward implementation of LSA methods
recommended from the literatures, s.a. OFAT [Broeke2016] and derivative-inspired OAT [Cariboni2007] are included. 

Multithreading parallelization for effortless speedup is included. Particularly, multi-level multi-threading paralellization seems
to improve the runtime performance. Routines for visualizing and iterpreting GSA and LSA results are provided.     

Technical Highlights V1.x 
=========================

How to understand / dive into the code .. 
To Do  

Technical Highlights V2.x
=========================

To Do  

Remarks
=======

- The links provided above are corresponding to [MiniDemographicABM V2.1](https://github.com/MRC-CSO-SPHSU/MiniDemographicABM.jl/tree/V2.1)  

References
==========

- [Bezanson2015] Bezanson, J., Edelman, A., Karpinski, S., and Shah, V. B. Julia: A fresh approach to numerical computing. SIAM Review, 59(1):65–98, 2015 
- [Broeke2016] G. ten Broeke, G. van Voorn & A. Ligtenberg. Which sensitivty analysis method should I use for my agent-based model?, Journal of Artificial Societes and Social Simulation 19(1) 5, 2016
- [Campolongo2007] F. Campolongo, J. Cariboni & A. Saltelli. An effective screening design for sensitivity analysis of large models. Environmental Modelling & Software, 22(10), 1509–1518, 2007
- [Cariboni2007] J. Cariboni a b, D. Gatelli a, R. Liska a, A. Saltelli. The role of sensitivity analysis in ecological modelling. Ecological Modelling, 2007
- [Datseris2022] George Datseris, Ali R. Vahdati, Timothy C. DuBois: Agents.jl: a performant and feature-full agent-based modeling software of minimal code complexity. SIMULATION. 2022. doi:10.1177/00375497211068820
- [Dixit2022] Vaibhav Kumar Dixit and Christopher Rackauckas: GlobalSensitivity.jl: Performant and Parallel Global Sensitivity Analysis with Julia, Journal of Open Source Software, 2022
- [Gostoli2020] Umberto Gostoli and Eric Silverman Social and child care provision in kinship networks: An agent-based model. PLoS ONE 15(12): 2020 (https://doi.org/10.1371/journal.pone.0242779)
- [Karpinski2019] [Stefan Karpinski, The Unreasonable Effectiveness of Multiple Dispatch, JuliaCon 2019, 2019](https://www.youtube.com/watch?v=kc9HwsxE1OY)
- [Ma2021] Yingbo Ma and Shashi Gowda and Ranjan Anantharaman and Chris Laughman and Viral Shah and Chris Rackauckas, ModelingToolkit: A Composable Graph Transformation System For Equation-Based Modeling,
arXiv, 2021
- [Roesch2023] Elisabeth Roesch, Joe G. Greener, Adam L. MacLean, Huda Nassar, Christopher Rackauckas, Timothy E. Holy & Michael P. H. Stumpf. Julia for Biologists, Nature Methods 20, 2023  
- [Saltelli2002] A. Saltelli, Making best use of model evaluations to compute sensitivity indices, Computer Physics Communications 145, 2002
- [Saltelli2020] A. Saltelli et al., Five ways to ensure that models serve society: a manifesto, Nature 2020. 
