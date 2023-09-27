"""
Run this script from shell as
#  julia <script-name.jl>

or within REPL

julia> include("script-name.jl")
"""

using Agents
using Plots

include("./simspec.jl")

#=
properties can be accessed in models.jl
Other clock options: Monthly, Hourly
=#
const properties = DemographicABMProp{Daily}(initialPop = 10_000)
const model = UKDemographicABM(properties)

seed!(model,floor(Int,time()))  # really random
declare_population!(model)
init_kinship!(model) # the kinship among population
init_housing!(model) # housing assoication to population

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
num_deads(model) = length([person for person in allagents(model) if !isalive(person)])

num_living(model) = length([person for person in allagents(model) if isalive(person)])
num_living_males(model) = length([person for person in allagents(model) if isalive(person) && ismale(person)])
ratio_males(model) = num_living_males(model) / num_living(model)

mean_living_age(model) = sum([age(person) for person in allagents(model) if isalive(person)]) / num_living(model)

num_children(model) = length([person for person in allagents(model) if isalive(person) && ischild(person)])
ratio_children(model) = num_children(model) / num_living(model)

num_singles(model) = length([person for person in allagents(model) if isalive(person) && issingle(person)])
ratio_singles(model) = (num_singles(model) - num_children(model))/ num_living(model)

adata = [(isalive,sum), (ismale,sum,isalive), (age,mean,isalive), (age,maximum),(age,maximum,isalive)]
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
    run!(model,agent_steps!,model_steps!,365*10; adata, mdata)

#=
plot as follows from REPL
plot(model_df.currstep, model_df.mean_living_age,title=dataname(modelData[3]))
plot(model_df.currstep, model_df.ratio_males, title="Ratio of males", reuse = false)
=#
