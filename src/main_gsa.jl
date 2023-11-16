"""
Run this script from shell as
#  julia <script-name.jl>

with multi-threading
#  julia --threads 8 <script-name.jl>

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
#############################################
# Step 0 - which computation task is desired
#############################################
=#

abstract type ComputationProblem end
abstract type SAProblem <: ComputationProblem end
abstract type GSAProblem <: SAProblem end
abstract type LSAProblem <: SAProblem end

struct MorrisProblem <: GSAProblem end
struct SobolProblem <: GSAProblem end

notimplemented(prob::ComputationProblem) = error("$(typeof(pr)) not implemented")

_solve(prob::ComputationProblem, f, lbs, ubs;
    batch, seednum, kwargs...) = notimplemented(pr)

function _solve(prob::ComputationProblem, f, actpars::Vector{ActiveParameter{Float64}};
    batch, seednum, kwargs...)
    lbs = [ ap.lowerbound for ap in actpars ]
    ubs = [ ap.upperbound for ap in actpars ]
    for i in 1:length(ubs)
        @assert lbs[i] < ubs[i]
    end
    global SEEDNUM = seednum
    SEEDNUM == 0 ? Random.seed!(floor(Int,time())) : Random.seed!(SEEDNUM)
    empty!(ACTIVEPARS)
    for ap in actpars
        push!(ACTIVEPARS,ap)
    end
    return _solve(prob, f, lbs, ubs; batch, seednum, kwargs...)
end

solve(prob::ComputationProblem,
    f,
    actpars::Vector{ActiveParameter{Float64}};
    batch = false,   # for parallelization
    seednum = 0  ,   # for random number generation, 0 : totally random
    kwargs...) =     # method specific keyword arguments
        _solve(prob,f,actpars;batch,seednum,kwargs...)

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


# Potential candidates for parameters w.r.t. which analysis is sought
const startMarriedRate = ActiveParameter{Float64}(0.25,0.9,:startMarriedRate)
const baseDieRate = ActiveParameter{Float64}(0.00005,0.00015,:baseDieRate)
const femaleAgeDieRate = ActiveParameter{Float64}(0.0001,0.0003,:femaleAgeDieRate)
const femaleAgeScaling = ActiveParameter{Float64}(15.1,16.0,:femaleAgeScaling)
const maleAgeDieRate = ActiveParameter{Float64}(0.0001,0.0003,:maleAgeDieRate)
const maleAgeScaling = ActiveParameter{Float64}(14.0,15.0,:maleAgeScaling)
const basicDivorceRate = ActiveParameter{Float64}(0.01,0.09,:basicDivorceRate)
const basicMaleMarriageRate = ActiveParameter{Float64}(0.1,0.9,:basicMaleMarriageRate)

# Global variable to be accessed by a typical analysis
const ACTIVEPARS::Vector{ActiveParameter{Float64}} = []
# An example choice:
#   [ startMarriedRate, baseDieRate, femaleAgeDieRate,femaleAgeScaling,
#     maleAgeDieRate, maleAgeScaling, basicDivorceRate, basicMaleMarriageRate ]

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
const INITIALPOP = 3000
const SEEDNUM = 1
SIMCNT::Int = 0
LASTPAR::Vector{Float64} = []

function outputs(pars)
    #global SIMCNT += 1  # does not work with multi-threading
    @assert length(pars) == length(ACTIVEPARS)
    properties = DemographicABMProp{CLOCK}(starttime = STARTTIME,
        initialPop = INITIALPOP,
        seednum = SEEDNUM)
    SEEDNUM == 0 ? Random.seed!(floor(Int,time())) : Random.seed!(SEEDNUM)
    for (i,p) in enumerate(pars)
        @assert ACTIVEPARS[i].lowerbound <= p <= ACTIVEPARS[i].upperbound
        set_par_value!(properties,ACTIVEPARS[i],p)
    end
    model = declare_initialized_UKmodel(CLOCK,properties)
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
# Step V.1 - API for GSA using Morris method
#########################################

function _solve(pr::MorrisProblem, f, lbs, ubs;
    seednum = 0,  # totally random
    batch = true,
    relative_scale = false,
    num_trajectory = 10,
    total_num_trajectory = 5 * num_trajectory,
    len_design_mat = 10)

    @time morrisInd = gsa(f,
        Morris(;relative_scale, num_trajectory, total_num_trajectory, len_design_mat),
        [ [lbs[i],ubs[i]] for i in 1:length(ubs) ];
        batch)
    return morrisInd

end

solve(pr::MorrisProblem, f, actpars::Vector{ActiveParameter{Float64}};
    batch = false, seednum = 0, kwargs...)  =
        _solve(pr,f,actpars;batch,seednum,kwargs...)

#=
how to execute and visualize:

model = ...
# cf. GlobalSensitivity.jl documnetation for Morris method arguments
morrisInd = solve(MorrisProb(), model,
    [ startMarriedRate, baseDieRate, femaleAgeDieRate,femaleAgeScaling,
    maleAgeDieRate, maleAgeScaling, basicDivorceRate, basicMaleMarriageRate ] ;
    batch = true , # for parallelization
    seednum = 1,   # fully determinstic computation
    relative_scale = true,
    num_trajectory = 20,
    total_num_trajectory = 500)


# Visualize the result w.r.t. the variable mean_living_age
scatter(log.(morrisInd.means_star[2,:]), morrisInd.variances[2,:],
    series_annotations=[string(i) for i in 1:length(ACTIVEPARS)],
    label="(log(mean*),sigma)")

=#


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




#=
To compute sobol indices, this can be done as follows:

either
sobolInd = gsa(outputs, Sobol(), [ [lbs[i],ubs[i]] for i in 1:length(ubs) ], samples = 100)

or

A = sample(100,ACTIVEPARS,SobolSample()) ;
B = sample(100,ACTIVEPARS,SobolSample()) ;

sobolInd - gsa(outputs, Sobol(), A, B)

=#
