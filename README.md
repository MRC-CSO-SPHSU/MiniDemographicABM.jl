[![Open Code Badge](https://www.comses.net/static/images/icons/open-code-badge.png)](https://www.comses.net/codebases/e4727972-7bf7-4a30-9682-5c366e2ae067/releases/1.3.0/)

# MiniDemographicABM.jl 
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

### Title 
MiniDemographicABM.jl: A simplified agent based model of UK demography based on the Agents.jl Julia package   

### Description

This package implements a simplified artificial agent-based demographic model of the UK. Individuals of an initial population are subject to ageing, deaths, births, divorces and marriages. A specific case-study simulation is progressed with a user-defined simulation fixed step size on a hourly, daily, weekly, monthly basis or even an arbitrary user-defined clock rate.
While the model can serve as a base model to be adjusted to realistic large-scale socio-economics, pandemics or social interactions-based studies mainly within a demographic context, the main purpose of the model is to explore and exploit capabilities of the state-of-the-art Agents.jl Julia package as well as other ecosystem of Julia packages like GlobalSensitivity.jl. Code includes examples for evaluating global sensitivity analysis using Morris and Sobol methods and local sensitivity analysis using OFAT and OAT methods. Multi-threaded parallelization is enabled for improved runtime performance. 
  

### Author(s) 
[Atiyah Elsheikh](https://www.gla.ac.uk/schools/healthwellbeing/staff/atiyahelsheikh/)

### Contributor(s)  
Atiyah Elsheikh (V1.0-V2.2)  

### Release Notes 
- **V1.0** (22.2.2023) : First initial implementation exploring various capabilities of Agents.jl as a demonstration of how to implement an abstract demographic ABM, not yet calibrated. A space type was implemented as a demonstration. A comprehensive set of unit tests is included. Blue style coding convetions are followed. 
    - V1.0.1 (14.7.23) : updating ReadMe with usually demanded information
- **V1.1** (28.7.23): Model documentation as a pdf and unified naming convention of model parameters
- **V1.2** (27.9.23): Equaivalent simulation program based on ABMSim Version 0.7
    - V1.2.1 (11.10.23): ABMSim V0.7.2 for removing the cause of Agents.jl performance drop when using ABMSim
- **V1.3**(23.10.23): improved specification / documentation  
- **V2.0**(6.11.23): Global Sensitivity Analysis with Morris Index, bugs resolved due to expansion of the parameter space
- **V2.1**(24.11.23): GSA with Sobol indices, parallelizaztion multi-threading, OFAT local sensitivity analysis algorithm 
- **v2.2**(12.12.23): OAT Local SA, SA of non-determistic function by multiple exeuction of methods or functions each with different seed number, multi-level multi-threading (33% speedup)   

### License
MIT License

Copyright (c) 2023 Atiyah Elsheikh, MRC/CSO Social & Public Health Sciences Unit, School of Health and Wellbeing, University of Glasgow, Cf. [License](https://github.com/MRC-CSO-SPHSU/MiniDemographicABM.jl/blob/master/LICENSE) for further information

### Platform 
This code was developed and experimented on 
- Ubuntu 22.04.2 LTS
- VSCode V1.71.2
- Julia language V1.9.1
- Agents.jl V5.14.0
- [ABMSim.jl](https://github.com/MRC-CSO-SPHSU/ABMSim.jl) V0.7.2 (Optional) 

### URL 
Check for updates here: 
- **V1.0-V2.2** at least till 12.12.2023: [MiniDemographicABM.jl](https://github.com/MRC-CSO-SPHSU/MiniDemographicABM.jl)

### Exeution 
Within Shell:

`$ julia <script-name.jl>`

`$ julia --threads 8 <script-name.jl>` # for multi-threading 

Within REPL: 

`> include <script-name.jl>`

where script names are 
- main.jl : for executing the simulation program
- main-gsa.jl : for activating routines for performing GSA, cf. documentation within the script
- runalltests.jl: for running unit tests. 

### References

Specification: 

[1] Atiyah Elsheikh, Specification of MiniDemographicABM.jl: A simplified agent-based demographic model of the UK. Technical report, arXiv:2307.16548, 2023

[2] Atiyah Elsheikh, Formal specification terminology for demographic agent-based models of fixed-step single-clocked simulations. Technical report, arXiv.2308.13081, 2023

The underlying model is inspired by the model given in the following paper:   

[3] Umberto Gostoli and Eric Silverman Social and child care provision in kinship networks: An agent-based model. PLoS ONE 15(12): 2020 (https://doi.org/10.1371/journal.pone.0242779)

The packages Agents.jl: 

[4] George Datseris, Ali R. Vahdati, Timothy C. DuBois: Agents.jl: a performant and feature-full agent-based modeling software of minimal code complexity. SIMULATION. 2022. doi:10.1177/00375497211068820

The package GlobalSenstivity.jl

[5] Vaibhav Kumar Dixit and Christopher Rackauckas: GlobalSensitivity.jl: Performant and Parallel Global Sensitivity Analysis with Julia, Journal of Open Source Software, 2022

Morris index algorithm via

[6] F. Campolongo, J. Cariboni & A. Saltelli (2007). An effective screening design for sensitivity
analysis of large models. Environmental Modelling & Software, 22(10), 1509–1518.

Sobol index algorithm via 

[7] A. Saltelli, Making best use of model evaluations to compute sensitivity indices, Computer Physics Communications 145, 2002

OFAT Algorithm 

[8] G. ten Broeke, G. van Voorn & A. Ligtenberg. Which sensitivty analysis method should I use for my agent-based model?, Journal of Artificial Societes and Social Simulation 19(1) 5, 2016

OAT Algorithm

[9] J. Cariboni a b, D. Gatelli a, R. Liska a and A. Saltelli, The role of sensitivity analysis in ecological modelling, Ecological Modelling 2007

### Acknowledgements  
- [Dr. Martin Hinsch](https://www.gla.ac.uk/schools/healthwellbeing/staff/martinhinsch/) for Scientific Exchange
- [Dr. Eric Silverman](https://www.gla.ac.uk/schools/healthwellbeing/staff/ericsilverman/) Principle Invistigator 

For the purpose of open access, the author(s) has applied a Creative Commons Attribution (CC BY) licence to any Author Accepted Manuscript version arising from this submission.

### Cite as 

Atiyah Elsheikh. MiniDemographicABM.jl: A simplified agent-based demographic model of the UK. CoMSES Computational Model Library, Nov. 2023. (V2.1)

#### bibtex
@Software{MiniDemographicABMjl,
  author  = {Atiyah Elsheikh},
  comment = {CoMSES Computational Model Library},
  month   = Oct,
  title   = {{MiniDemographicABM.jl}: {A} simplified agent-based demographic model of the {UK}},
  url     = { https://www.comses.net/codebases/e4727972-7bf7-4a30-9682-5c366e2ae067/releases/2.1/ },
  version = {2.1},
  year    = {2023},
}

### Fundings 
[Dr. Atyiah Elsheikh](https://www.gla.ac.uk/schools/healthwellbeing/staff/atiyahelsheikh/), by the time of publishing Version 1.0 of this software, is a Research Software Engineer at MRC/CSO Social & Public Health Sciences Unit, School of Health and Wellbeing, University of Glasgow. He is in the Complexity in Health programme. He is supported  by the Medical Research Council (MC_UU_00022/1) and the Scottish Government Chief Scientist Office (SPHSU16). 
