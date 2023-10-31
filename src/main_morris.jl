"""
Run this script from shell as
#  julia <script-name.jl>

or within REPL

julia> include("script-name.jl")
"""

using Agents
using Plots

include("./simspec.jl")

# properties can be accessed in models.jl

declare_model_properties(clock,starttime,initialPop;
    startMarriedRate=0.8,
    maxNumberOfMarriageCand=100,
    baseDieRate = 0.0001,
    maleAgeDieRate = 0.00021
    maleAgeScaling = 14.0
    femaleAgeDieRate = 0.00019
    femaleAgeScaling = 15.5
    basicDivorceRate = 0.06
    basicMaleMarriageRate = 0.7) =
        DemographicABMProp{clock}(starttime,initialPop;
            startMarriedRate,maxNumberOfMarriageCand,
            baseDieRate,maleAgeDieRate,maleAgeScaling,
            femaleAgeDieRate,femaleAgeScaling,
            basicDivorceRate,basicDivorceRate)

declare_initialized_model(clock,properties)
    model = UKDemographicABM(properties)
    seed!(model,floor(Int,time()))  # really random
    declare_population!(model)
    init_kinship!(model) # the kinship among population
    init_housing!(model) # housing assoication to population
    return model
end

function agent_steps!(person,model)
    age_step!(person,model)
    death!(person,model)
    divorce!(person,model)
end

function model_steps!(model)
    metastep!(model) # incrementing time
    dobirths!(model)
    domarriages!(model)
end


## Define a simple simulation function of the form y = f(x)
##  output  : the average death age
##  input   : common model parameters

## Problem definition lower and upper bound

## Perform sampling

## Perform SA using Morris method
