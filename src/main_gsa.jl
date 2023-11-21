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
# Step 1 - Global variables
#############################################
=#

const _CLOCK = Monthly
const _STARTTIME = 1951
const _NUMSTEPS = 12 * 100  # 100 year
const _INITIALPOP = 3000
const _SEEDNUM = 1

# Global variable to be accessed by a typical analysis
const _ACTIVEPARS::Vector{ActiveParameter{Float64}} = []

function _reset_ACTIVEPARS!(actpars::Vector{ActiveParameter{Float64}})
    empty!(_ACTIVEPARS)
    for ap in actpars
        push!(_ACTIVEPARS,ap)
    end
    nothing
end

function _reset_glbvars!(;clock = _CLOCK,
    initialpop = _INITIALPOP,
    numsteps = _NUMSTEPS,
    seednum = _SEEDNUM,
    starttime = _STARTTIME, kwargs...)

    global _CLOCK = clock
    global _INITIALPOP = initialpop
    global _NUMSTEPS = numsteps
    global _STARTTIME = starttime
    global _SEEDNUM = seednum

    _SEEDNUM == 0 ? Random.seed!(floor(Int,time())) : Random.seed!(_SEEDNUM)

    return nothing
end

##############################
# Step II - active parameters
##############################
# Define potential active parameters w.r.t. which Analysis is sought
# cf. /types/activePars.jl for definition of the type active parameters


# Potential candidates for parameters w.r.t. which analysis is sought
const startMarriedRate = ActiveParameter{Float64}(:startMarriedRate,0.25,0.9,0.8)
const baseDieRate = ActiveParameter{Float64}(:baseDieRate,0.00005,0.00015,0.0001)
const femaleAgeDieRate = ActiveParameter{Float64}(:femaleAgeDieRate,0.0001,0.0003,0.00019)
const femaleAgeScaling = ActiveParameter{Float64}(:femaleAgeScaling,15.1,16.1,15.5)
const maleAgeDieRate = ActiveParameter{Float64}(:maleAgeDieRate,0.0001,0.0003,0.00021)
const maleAgeScaling = ActiveParameter{Float64}(:maleAgeScaling,13.5,14.5,14.0)
const basicDivorceRate = ActiveParameter{Float64}(:basicDivorceRate,0.01,0.09,0.06)
const basicMaleMarriageRate = ActiveParameter{Float64}(:basicMaleMarriageRate,0.4,0.9,0.7)


#=
#############################################
# Step III - which computation task is desired
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

_solve(prob::GSAProblem, f, lbs, ubs;kwargs...) = notimplemented(pr)

# Specialized for GlobalSensitivity.jl
function _solve(prob::GSAProblem, f, actpars::Vector{ActiveParameter{Float64}};kwargs...)

    lbs = [ ap.lowerbound for ap in actpars ]
    ubs = [ ap.upperbound for ap in actpars ]
    for i in 1:length(ubs)
        @assert lbs[i] < ubs[i]
    end

    return _solve(prob, f, lbs, ubs; kwargs...)
end

function solve(prob::ComputationProblem, f, actpars::Vector{ActiveParameter{Float64}};
    kwargs...)     # method specific keyword arguments

    _reset_glbvars!(;kwargs...)
    _reset_ACTIVEPARS!(actpars)
    return _solve(prob,f,actpars;kwargs...)
end



#=
###########################################
# Step IV - model and simulation definitions
###########################################
For defining simulation-based functions:
model declaration, initializtaion and stepping definitions can be accessed in simspec.jl
via the calls
   declare_initialized_UKModel(..)
   agent_steps()
   model_steps()

   How to execute an ABM simulation based on Agents.jl, see main.jl
=#



##################################
# Step V - Input/Output function
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
    res = Array{Float64,2}(undef,4,size(pmatrix)[2])
    pr = Progress(size(pmatrix)[2];desc= "Evaluating f(pmatrix)...")
    @threads for i in 1 : size(pmatrix)[2]
        @inbounds res[:,i] = fabm(@view pmatrix[:,i])
        next!(pr)
    end
    return res
end


###################################################
# Step VI - Wrapper for GlobalSensitivty.jl methods
###################################################


#############################################
# Step VI.1 - API for GSA using Morris method
#############################################

function _solve(pr::MorrisProblem, f, lbs, ubs;
    batch = true,
    relative_scale = false,
    num_trajectory = 10,
    total_num_trajectory = 5 * num_trajectory,
    len_design_mat = 10,
    kwargs...)

    @time morrisInd = gsa(f,
        Morris(;relative_scale, num_trajectory, total_num_trajectory, len_design_mat),
        [ [lbs[i],ubs[i]] for i in 1:length(ubs) ];
        batch)
    return morrisInd
end


########################################
# Step VI.2 - API for GSA using Sobol method
#########################################


function _solve(pr::SobolProblem, f, lbs, ubs;
    batch = true,
    samples = 10,
    kwargs...)

    sobolInd = gsa(f, Sobol(), [ [lbs[i],ubs[i]] for i in 1:length(ubs) ]; batch, samples)
end

#=
To compute sobol indices, this can be done as follows:

either
sobolInd = gsa(outputs, Sobol(), [ [lbs[i],ubs[i]] for i in 1:length(ubs) ], samples = 100)

or

A = sample(100,ACTIVEPARS,SobolSample()) ;
B = sample(100,ACTIVEPARS,SobolSample()) ;

sobolInd = gsa(outputs, Sobol(), A, B)

=#


########################################
# Step VI.3 - API for OFAT using
#########################################

function _compute_ofat_p(actpars,pnom,n)
    pmat = Array{Float64,2}(undef,length(actpars),(n*length(actpars)))

    for i in 1:length(actpars)
        pmat[i,:] .= pnom[i]
        lb = actpars[i].lowerbound
        ub = actpars[i].upperbound
        for j in 1 + (i-1)*n : i*n
            pmat[i,j] = lb + ((j-1)%n) * ((ub - lb) / (n - 1))
        end
    end

    return pmat
end


function _compute_ofat_y(f, pmatrix, nruns)
    pr = Progress(nruns;desc= "Evaluating OFAT ...")
    global _SEEDNUM
    seednum = _SEEDNUM
    ysum = f(pmatrix)
    for _ in 2:nruns
        _SEEDNUM += _SEEDNUM == 0 ? 0 : 1
        y = f(pmatrix)
        ysum += y
        next!(pr)
    end
    _SEEDNUM = seednum
    return ysum / nruns
end

"""
OFAT Result containts:
- pmatrix a design matrix of size: p x s
    where p is number of active parameters
    and s the number of steps
- y the simulation results of size: n x p x s
"""
struct OFATResult

    pmatrix::Matrix{Float64}
    pnom::Vector{Float64}
    y::Matrix{Float64}
    ynom::Vector{Float64}

    function OFATResult(actpars,f,n,nruns)
        pnom = nominal_values(actpars)
        pmatrix = _compute_ofat_p(actpars,pnom,n)
        for i in 1:length(actpars)
            @assert actpars[i] === _ACTIVEPARS[i]
        end
        ynom = f(pnom)
        y = _compute_ofat_y(f, pmatrix,nruns)
        #y = reshape(tmp,(length(ynom), length(actpars),n))
        new(pmatrix,pnom,y,ynom)
    end

end

"Visualize OFAT results"
function plot_ofatres(res::OFATResult, actpars, ylabels)

    ny = length(res.ynom)
    np = length(res.pnom)
    n = Int(size(res.pmatrix)[2] / length(res.pnom))

    plts = Matrix{Any}(undef, np, ny)
    @assert np == length(actpars)
    plabels = [ string(ap.name) for ap in actpars ]

    plbs = [ap.lowerbound for ap in actpars]
    pubs = [ap.upperbound for ap in actpars]

    ylbs = fill(Inf,ny)
    yubs = fill(-1.0,ny)
    for i in 1:ny
        @inbounds ylbs[i] = min((@view res.y[i,:])...)
        @inbounds yubs[i] = max((@view res.y[i,:])...)
    end

    for yind in 1:ny
        for pind in 1:length(actpars)
            plts[pind,yind] = plot()
            scatter!(plts[pind,yind] ,
                res.pmatrix[pind, (pind-1)*n+1:pind*n] ,
                res.y[yind,(pind-1)*n+1:pind*n],
                title = " $(plabels[pind]) vs. $(ylabels[yind]) ")
            xlims!(plts[pind,yind],plbs[pind],pubs[pind])
            ylims!(plts[pind,yind],ylbs[yind],yubs[yind])
        end
    end

    return plts
end

_solve(pr::OFATProblem, f, actpars; n=11, nruns, kwargs...) =
    OFATResult(actpars,f,n,nruns)


#=
reshaping for making use of fabm(::Matrix) is like that :

a = [ i + j-1 +  (j-1) * 3  + 3*4* (k-1) for k = 1:z  for j in 1:x for i in 1:y ]
B = reshape(a,(p * s, n))
y = fabm(B)
=#





#########################################################
# Step VII - Documentation for execution and visualization
#########################################################


#########################################################
# Step VII.1 Executing and visualizing Morris Indices
#########################################################

#=
how to execute and visualize:

actpars =
    [ startMarriedRate, baseDieRate, femaleAgeDieRate, femaleAgeScaling,
      maleAgeDieRate, maleAgeScaling, basicDivorceRate, basicMaleMarriageRate ];
# cf. GlobalSensitivity.jl documnetation for Morris method arguments
morrisInd = solve(MorrisProblem(),
          fabm,
          actpars;
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


#########################################################
# Step VII.3 Executing and visualizing OFAT
#########################################################

#=

actpars = ... ;
res = solve(OFATProblem(), fabm, actpars; n = 11, initialpop = 3_000, nruns = 10);

ylabels = [ "ratio(singles)" , "mean_livings_age", "ratio(males)", "ratio(children)" ] ;
plts = plot_ofatres(res,actpars,ylabels) ;

=#
