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
using ProgressMeter
using Base.Threads

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
# Define active parameters w.r.t. which SA is sought
# cf. /types/activePars.jl for definition of the type active parameters


const startMarriedRate = ActiveParameter{Float64}(0.25,0.9,:startMarriedRate)
const baseDieRate = ActiveParameter{Float64}(0.00005,0.00015,:baseDieRate)
const femaleAgeDieRate = ActiveParameter{Float64}(0.0001,0.0003,:femaleAgeDieRate)
const femaleAgeScaling = ActiveParameter{Float64}(15.1,16.0,:femaleAgeScaling)
const maleAgeDieRate = ActiveParameter{Float64}(0.0001,0.0003,:maleAgeDieRate)
const maleAgeScaling = ActiveParameter{Float64}(14.0,15.0,:maleAgeScaling)
const basicDivorceRate = ActiveParameter{Float64}(0.01,0.09,:basicDivorceRate)
const basicMaleMarriageRate = ActiveParameter{Float64}(0.1,0.9,:basicMaleMarriageRate)

const ACTIVEPARS = [ startMarriedRate, baseDieRate, femaleAgeDieRate,femaleAgeScaling,
    maleAgeDieRate, maleAgeScaling, basicDivorceRate, basicMaleMarriageRate ]

##################################
# Step III - Input/Output function
##################################
## Define a simple simulation-based function of the form y = f(x)
##  outputs : vector of model outputs
##    1. ratio of singles
##    2. average ago of living population
##    3. ratio males
##    4. ratio of children
##
##  input   : selected model parameters w.r.t. SA is sought
##
##  using the following global constants below
##

#=
# TODO abstract the following as a task / problem
# For example

abstract type CompProblem end

mutable struct type ABMSAProb <: CompProblem
    apars::Vector{ActiveParameter}
    fixedpars::Dict{Symbol,Any}
    simpars::Dict{Symbol,Any}
    simcnt::Int
    lastpar::Vector{Float64}

    ABMSAProb(aps::vector{ActivePars}, mpars, spars) =
        new(aps, spars, mpars, 0, zeros(length(aps)))
end
=#
# const _MORRIS = ABMSAProb

const CLOCK = Monthly
const STARTTIME = 1951
const NUMSTEPS = 12 * 100  # 100 year
const INITIALPOP = 10000
const SEEDNUM = 1
SIMCNT::Int = 0
LASTPAR::Vector{Float64} = []

function outputs(pars)
    #global SIMCNT += 1
    #SIMCNT % 10 == 0 ? println("simulation # $(SIMCNT) ") : nothing
    #global LASTPAR = pars
    # @assert length(pars) == length(ACTIVEPARS)
    if length(pars) != length(ACTIVEPARS)
        @show size(pars)
        error()
    end
    for (i,p) in enumerate(pars)
        @assert ACTIVEPARS[i].lowerbound <= p <= ACTIVEPARS[i].upperbound
    end
    properties = DemographicABMProp{CLOCK}(starttime = STARTTIME,
        initialPop = INITIALPOP,
        seednum = SEEDNUM)
    for (i,p) in enumerate(pars)
        set_par_value!(properties,ACTIVEPARS[i],p)
    end
    model = declare_initialized_UKmodel(Monthly,properties)
    run!(model,agent_steps!,model_steps!,NUMSTEPS)
    if num_living(model) == 0
        @warn "no living people"
        return [ 1e-3, 100.0, 0.5, 1e-3]
    end
    return [ ratio_singles(model),
             float(mean_living_age(model)) ,
             ratio_males(model),
             max(ratio_children(model),1e-3) ]
end

# TODO , parallelization requires the following API, executable when batch = true
function outputs(pmatrix::Matrix{Float64})
    @assert size(pmatrix)[1] == length(ACTIVEPARS)
    res = zeros(4,size(pmatrix)[2])
    pr = Progress(size(pmatrix)[2];desc= "Evaluating ...")
    @threads for i in 1 : size(pmatrix)[2]
        res[:,i] = outputs(pmatrix[:,i])
        next!(pr)
    end
    return res
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


# cf. GlobalSensitivity.jl documnetation for documentation of the Morris method arguments
@time morrisInd = gsa(outputs,
            Morris(relative_scale=true, num_trajectory=20, total_num_trajectory=500),
            [ [lbs[i],ubs[i]] for i in 1:length(ubs) ],
            batch = true) # for parallelization

#=
Results regarding the output mean_living_age can be accessed via

res.means[2,i] : the overall influence of the i-th parameter on the output
res.means_star [2,i] : the mean of the absolute influence of the i-th parameter
res.variances [2,i] : the ensemble of the i-th parameter higer order effects

As expected,
* the most important parameters w.r.t. the output mean_living_age and the parameter space :
    - maleAgeDieRate, femaleAgeDieRate, baseDieRate (order depends on parameter space)

* the least influentiable
    - maleAgeScaling, femaleAgeScaling
=#

# Visualize the result w.r.t. the variable mean_living_age
scatter(log.(res.means_star[2,:]), res.variances[2,:],
    series_annotations=[string(i) for i in 1:length(ACTIVEPARS)],
    label="(log(mean*),sigma)")
=#

#=
To compute sobol indices, this can be done as follows:

either
sobolInd = gsa(outputs, Sobol(), [ [lbs[i],ubs[i]] for i in 1:length(ubs) ], samples = 100)

or

A = sample(100,ACTIVEPARS,SobolSample()) ;
B = sample(100,ACTIVEPARS,SobolSample()) ;

sobolInd - gsa(outputs, Sobol(), A, B)

=#
