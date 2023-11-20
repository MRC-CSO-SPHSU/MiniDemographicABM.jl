"""
Run this script from shell as
#  julia <script-name.jl>

with multi-threading
#  julia --threads 8 <script-name.jl>

or within REPL

julia> include("script-name.jl")
"""

using GlobalSensitivity
using Random
using ProgressMeter
using Base.Threads
using Random

include("./simspec.jl")


#=
#############################################
# Step 1 - which computation task is desired
#############################################
=#

abstract type ComputationProblem end
abstract type SAProblem <: ComputationProblem end
abstract type GSAProblem <: SAProblem end
abstract type LSAProblem <: SAProblem end

struct MorrisProblem <: GSAProblem end
struct SobolProblem <: GSAProblem end

struct OFATProblem <: LSAProblem end

notimplemented(prob::ComputationProblem) = error("$(typeof(pr)) not implemented")

_solve(prob::ComputationProblem, f, lbs, ubs;
    kwargs...) = notimplemented(pr)

function _solve(prob::ComputationProblem, f, actpars::Vector{ActiveParameter{Float64}};
    clock, initialpop, numsteps, seednum, starttime, kwargs...)

    global _CLOCK = clock
    global _INITIALPOP = initialpop
    global _NUMSTEPS = numsteps
    global _STARTTIME = starttime
    global _SEEDNUM = seednum
    _SEEDNUM == 0 ? Random.seed!(floor(Int,time())) : Random.seed!(_SEEDNUM)

    lbs = [ ap.lowerbound for ap in actpars ]
    ubs = [ ap.upperbound for ap in actpars ]
    for i in 1:length(ubs)
        @assert lbs[i] < ubs[i]
    end

    empty!(_ACTIVEPARS)
    for ap in actpars
        push!(_ACTIVEPARS,ap)
    end
    return _solve(prob, f, lbs, ubs; kwargs...)
end

solve(prob::ComputationProblem,
    f,
    actpars::Vector{ActiveParameter{Float64}};
    kwargs...) =     # method specific keyword arguments
        _solve(prob,f,actpars;kwargs...)

#=
###########################################
# Step II - model and simulation definitions
###########################################
For defining simulation-based functions:
model declaration, initializtaion and stepping definitions can be accessed in simspec.jl
via the calls
   declare_initialized_UKModel(..)
   agent_steps()
   model_steps()

   How to execute an ABM simulation based on Agents.jl, see jl
=#


##############################
# Step III - active parameters
##############################
# Define potential active parameters w.r.t. which SA is sought
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



##################################
# Step IV - Input/Output function
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

const _CLOCK = Monthly
const _STARTTIME = 1951
const _NUMSTEPS = 12 * 100  # 100 year
const _INITIALPOP = 3000
const _SEEDNUM = 1

# Global variable to be accessed by a typical analysis
const _ACTIVEPARS::Vector{ActiveParameter{Float64}} = []

function fabm(pars)
    #global SIMCNT += 1  # does not work with multi-threading
    @assert length(pars) == length(_ACTIVEPARS)
    properties = DemographicABMProp{_CLOCK}(starttime = _STARTTIME,
        initialPop = _INITIALPOP,
        seednum = _SEEDNUM)
    _SEEDNUM == 0 ? Random.seed!(floor(Int,time())) : Random.seed!(_SEEDNUM)
    for (i,p) in enumerate(pars)
        @assert _ACTIVEPARS[i].lowerbound <= p <= _ACTIVEPARS[i].upperbound
        set_par_value!(properties,_ACTIVEPARS[i],p)
    end
    model = declare_initialized_UKmodel(_CLOCK,properties)
    run!(model,agent_steps!,model_steps!,_NUMSTEPS)
    if num_living(model) == 0
        @warn "no living people"
        return [ 1e-3, 100.0, 0.5, 1e-3]
    end
    return [ ratio_singles(model),
             float(mean_living_age(model)) ,
             ratio_males(model),
             max(ratio_children(model),1e-3) ]
end

function fabm(pmatrix::Matrix{Float64})
    @assert size(pmatrix)[1] == length(_ACTIVEPARS)
    res = zeros(4,size(pmatrix)[2])
    pr = Progress(size(pmatrix)[2];desc= "Evaluating ...")
    @threads for i in 1 : size(pmatrix)[2]
        res[:,i] = fabm(pmatrix[:,i])
        next!(pr)
    end
    return res
end



###################################################
# Step V - Wrapper for GlobalSensitivty.jl methods
###################################################


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


########################################
# Step V.2 - API for GSA using Sobol method
#########################################


function _solve(pr::SobolProblem, f, lbs, ubs;
    seednum = 0,  # totally random
    batch = true,
    samples = 10)

    sobolInd = gsa(f, Sobol(), [ [lbs[i],ubs[i]] for i in 1:length(ubs) ]; batch, samples)
end


########################################
# Step V.2 - API for LSA using
#########################################

#=
"""
OFAT Result containts:
- pmatrix a design matrix of size: p x s
    where p is number of active parameters
    and s the number of steps
- y the simulation results of size: n x p x s
"""
struct OFATResult
    pmatrix::Matrix{Float64}
    y::Array{Float64,3}
    #function OFATResult(actpars,f,s)
        # initialize pmatirx and y
    #end
end

reshaping for making use of fabm(::Matrix) is like that :

a = [ i + j-1 +  (j-1) * 3  + 3*4* (k-1) for k = 1:z  for j in 1:x for i in 1:y ]
B = reshape(a,(p * s, n))
y = fabm(B)
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


#########################################################
# Step VI - Documentation for execution and visualization
#########################################################

#=
how to execute and visualize:

# cf. GlobalSensitivity.jl documnetation for Morris method arguments
morrisInd = solve(MorrisProblem(),
          fabm,
          [ startMarriedRate, baseDieRate, femaleAgeDieRate,femaleAgeScaling,maleAgeDieRate, maleAgeScaling, basicDivorceRate, basicMaleMarriageRate ];
           clock = Monthly,
           initialpop = 3000,
           numsteps = 100 * 12,
           starttime = 1951,
           batch = true , # for parallelization
           seednum = 1,
           relative_scale = true,
           num_trajectory = 10,
           total_num_trajectory = 500)

# Visualize the result w.r.t. the variable mean_living_age
scatter(log.(morrisInd.means_star[2,:]), morrisInd.variances[2,:],
    series_annotations=[string(i) for i in 1:length(ACTIVEPARS)],
    label="(log(mean*),sigma)")

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
