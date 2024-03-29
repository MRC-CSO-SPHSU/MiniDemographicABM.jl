"""
Run this script from shell as
#  julia <script-name.jl>

or within REPL

julia> include("script-name.jl")
"""

using Agents
using Plots
using Random

include("./simspec.jl")

#=
properties can be accessed in models.jl
clock options: Monthly, Daily, Hourly
Other model parameters :
    startMarriedRate=0.8, maxNumberOfMarriageCand=100, baseDieRate = 0.0001,
    maleAgeDieRate = 0.00021, maleAgeScaling = 14.0, femaleAgeDieRate = 0.00019,
    femaleAgeScaling = 15.5, basicDivorceRate = 0.06, basicMaleMarriageRate = 0.7
=#
properties = DemographicABMProp{Monthly}(initialPop = 10_000,
                                         starttime = 1951//1,
                                         seednum = 0)
numSimSteps = 12 * 100 # 365 * 10   # or 12 * 10 for Monthly

const model = UKDemographicABM(properties)

# if model seednum is 0 choose a random seed for model initialization, otherwise
#   apply seeding with the given seed number
myseed!(model.seednum)

declare_population!(model)
init_kinship!(model) # the kinship among population
init_housing!(model) # housing assoication to population

function _agent_steps!(person,model)
    age_step!(person,model)
    death!(person,model)
    divorce!(person,model)
end

function _model_steps!(model)
    metastep!(model) # incrementing time
    dobirths!(model)
    domarriages!(model)
end

#=
Execute a simulation for 10 years &
collect the following statistics:
A. via agentData:
    1- sum living people
    2- sum of alive males  (ratio of males to females can be computed from 1)
    3- mean age of living people
    4. maximum age of any person (alive or dead)
    5. maximum age of a living person
B. via modelData:
    1. # of dead people since the start of simulation
    2. ratio of living males / living females (it is easier)
    3. mean age of living people
    4. ratio of living singles / married
    5. ratio of living children / adult
agent accessory functions can be accessed in person.jl
Data collection is conducted via the DataFrame.jl work package.
=#

# the entries of the vectors below are referring to built-in or
#   functions in /basictypes/person.jl
adata = [(isalive,sum), (ismale,sum,isalive), (age,mean,isalive), (age,maximum),(age,maximum,isalive)]

# The entries below correspond to functions defined in /spec/models.jl
mdata = [num_deads, ratio_males, mean_living_age, ratio_singles, ratio_children, currstep]

#=
to check perfomrance without data collection, execute:
=#
# @time run!(model,agent_steps!,model_steps!,365*10)

#=
Some stats
deadpeople = [ p for p in allagents(model) if !isalive(p) ]
@show length(deadpeople)

singleParents = [ p for p in allagents(model) if issingle(p) && has_children(p) ] ;
@show length(singleParents)

marriedParents = [ p for p in allagents(model) if !issingle(p) && has_children(p) ] ;
@show length(marriedParents)
=#


@time agent_df, model_df =
    run!(model,_agent_steps!,_model_steps!,numSimSteps; adata, mdata)

#=
plot as follows from REPL
plot(model_df.currstep, model_df.mean_living_age,title=dataname(modelData[3]))
plot(model_df.currstep, model_df.ratio_males, title="Ratio of males", reuse = false)
=#
