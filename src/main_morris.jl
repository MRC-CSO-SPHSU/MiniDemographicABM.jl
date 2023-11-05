"""
Run this script from shell as
#  julia <script-name.jl>

or within REPL

julia> include("script-name.jl")
"""

using Agents
using GlobalSensitivity
using Distributions: Uniform
using Random

include("./simspec.jl")

#=
###########################################
# Step I - model and simulation definitions
###########################################
model declaration, initializtaion and stepping definitions can be accessed in simspec.jl
via the calls
   declare_initialized_UKModel(..)
   agent_steps()
   model_steps()

   How to execute an ABM simulation based on Agents.jl, see main.jl
=#

#############################
# Step II - active parameters
#############################
# Define active parameters to which SA is sought

mutable struct ActiveParameter{ValType}
    lowerbound::ValType
    upperbound::ValType
    name::Symbol
    function ActiveParameter{ValType}(low,upp,id) where ValType
        @assert low <= upp
        new(low,upp,id)
    end
end
setParValue!(model,activePar,val) = setfield!(model, activePar.name, val)
function sample_parameters(apars)
    pars = zeros(length(apars))
    for (i,ap) in enumerate(apars)
        pars[i] =  rand(Uniform(ap.lowerbound,ap.upperbound))
    end
    return pars
end

const startMarriedRate = ActiveParameter{Float64}(0.25,0.9,:startMarriedRate)
const baseDieRate = ActiveParameter{Float64}(0.00005,0.00015,:baseDieRate)
const femaleAgeDieRate = ActiveParameter{Float64}(0.0001,0.0003,:femaleAgeDieRate)
const femaleAgeScaling = ActiveParameter{Float64}(15.1,18.1,:femaleAgeScaling)
const maleAgeDieRate = ActiveParameter{Float64}(0.0001,0.0003,:maleAgeDieRate)
const maleAgeScaling = ActiveParameter{Float64}(12.0,15.0,:maleAgeScaling)
const basicDivorceRate = ActiveParameter{Float64}(0.01,0.09,:basicDivorceRate)
const basicMaleMarriageRate = ActiveParameter{Float64}(0.1,0.9,:basicMaleMarriageRate)


##################################
# Step III - Input/Output function
##################################
## Define a simple simulation-based function of the form y = f(x)
##  output  : the average age of the living population
##  input   : selected model parameters w.r.t. SA is sought
##
##  using the following global constants below


# TODO abstract the following as a task / problem
const ACTIVEPARS = [ startMarriedRate, baseDieRate, femaleAgeDieRate,femaleAgeScaling,
    maleAgeDieRate, maleAgeScaling, basicDivorceRate, basicMaleMarriageRate ]
const CLOCK = Monthly
const STARTTIME = 1951
const NUMSTEPS = 12 * 100  # 100 year
const INITIALPOP = 10000 # 10000
const SEEDNUM = 1
SIMCNT::Int = 0
LASTPAR::Vector{Float64} = []

num_living(model) = length([person for person in allagents(model) if isalive(person)])
mean_living_age(model) =
    sum([age(person) for person in allagents(model) if isalive(person)]) / num_living(model)

function avg_livings_age(pars)
    global SIMCNT += 1
    SIMCNT % 10 == 0 ? println("simulation # $(SIMCNT) ") : nothing
    global LASTPAR = pars
    @assert length(pars) == length(ACTIVEPARS)
    for (i,p) in enumerate(pars)
        @assert ACTIVEPARS[i].lowerbound <= p <= ACTIVEPARS[i].upperbound
    end
    properties = DemographicABMProp{CLOCK}(starttime = STARTTIME,
        initialPop = INITIALPOP,
        seednum = SEEDNUM)
    for (i,p) in enumerate(pars)
        setParValue!(properties,ACTIVEPARS[i],p)
    end
    model = declare_initialized_UKmodel(Monthly,properties)
    run!(model,agent_steps!,model_steps!,NUMSTEPS)
    if num_living(model) == 0
        @warn "no living people"
        return 0.0
    end
    return float(mean_living_age(model))
end

####################################
# Step IV - generate parameter sample
####################################
# Given the set of selected active parameters, their lower and upper bounds,
#  generate a sample parameter set using a uniform distribution / just for testing

# TODO .. this is left to the default conducted by the method implementation below

########################################
# Step V - Perform SA using Morris method
#########################################


lbs = [ ap.lowerbound for ap in ACTIVEPARS ]
ubs = [ ap.upperbound for ap in ACTIVEPARS ]

@time res = gsa(  avg_livings_age,
            Morris(relative_scale=true, num_trajectory=20),
            [ [lbs[i],ubs[i]] for i in 1:length(ubs) ] )

#=
Results can be accessed via

res.means[i] : the overall influence of the i-th parameter on the output
res.means_star [i]: the mean of the absolute influence of the i-th parameter
res.variances [i] : the ensemble of the i-th parameter higer order effects

As expected,
* the most important parameters w.r.t. the output mean_living_age and the parameter space :
    - maleAgeDieRate, femaleAgeDieRate, baseDieRate (order depends on parameter space)

* the least influentiable (may be due to correlation)
    - maleAgeScaling, femaleAgeScaling
=#


# Visualize the results
scatter(log.(res.means_star[:]), res.variances[1,:],
    series_annotations=[string(i) for i in 1:length(ACTIVEPARS)],
    label="(log(mean*),sigma)")
