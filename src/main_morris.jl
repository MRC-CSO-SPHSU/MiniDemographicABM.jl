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

# TODO abstract the following as a task / problem

const CLOCK = Monthly
const STARTTIME = 1951
const NUMSTEPS = 12 * 100  # 100 year
const INITIALPOP = 10000
const SEEDNUM = 1
SIMCNT::Int = 0
LASTPAR::Vector{Float64} = []

function outputs(pars)
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
        set_par_value!(properties,ACTIVEPARS[i],p)
    end
    model = declare_initialized_UKmodel(Monthly,properties)
    run!(model,agent_steps!,model_steps!,NUMSTEPS)
    if num_living(model) == 0
        @warn "no living people"
        return [ 100.0, 0.5, 0.0, 0.0]
    end
    return [ ratio_singles(model),
             float(mean_living_age(model)) ,
             ratio_males(model),
             ratio_children(model) ]
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

@time res = gsa(outputs,
            Morris(relative_scale=true, num_trajectory=30),
            [ [lbs[i],ubs[i]] for i in 1:length(ubs) ])

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
