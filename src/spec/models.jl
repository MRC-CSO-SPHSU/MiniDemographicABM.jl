"""
common functions applied on Agents.jl-ABM typically defined as:

ABM(Person,space;properties=DemographicABMProps(initialPop=100))

functions with argument model are expected to be found here.
"""

using Parameters
using Mixers
using CSV
using Tables

include("../util.jl")

import Agents: remove_agent_from_space!,
    ids_in_position, add_agent!, move_agent!, add_agent_to_space!
#import ABMSim: add_agent_to_space!

include("spaces.jl")

#######################################
#  other model-based functions & types
#######################################

@mix @with_kw struct DemogPars
    # basic fields
    initialPop::Int = 10000
    # Initialization parameters
    startMarriedRate::Float64 = 0.8  # Probability of an adult man is being married
    maxNumberOfMarriageCand::Int64 = 100
    # death parameters / yearly comulative (adhoc no model identification conducted)
    baseDieRate::Float64            = 0.0001
    maleAgeDieRate::Float64         = 0.00021
    maleAgeScaling::Float64         = 14.0
    femaleAgeDieRate::Float64       = 0.00019
    femaleAgeScaling::Float64       = 15.5
    # divorce parametes
    basicDivorceRate :: Float64       = 0.06
    divorceModifierByDecade :: Vector{Float64} =
        [0.0, 1.0, 0.9, 0.5, 0.4, 0.2, 0.1, 0.03,
         0.01, 0.001, 0.001, 0.001, 0.0, 0.0, 0.0, 0.0]
    # marriage parameters
    basicMaleMarriageRate :: Float64  = 0.7
    maleMarriageModifierByDecade :: Vector{Float64} =
        [ 0.0, 0.16, 0.5, 1.0, 0.8, 0.7, 0.66, 0.5,
          0.4, 0.2, 0.1, 0.05, 0.01, 0.0, 0.0, 0.0 ]
end
@DemogPars struct DemographyPars end

@mix @with_kw struct DemogData
    fertfile :: String = "../data/babyrate.txt.csv"
    fertility :: Matrix{Float64} = CSV.File(fertfile, header=0) |> Tables.matrix
end
@DemogData struct DemographyData end

@mix @with_kw mutable struct ABMTimer{T <: Clock}
    clock :: T = T()
    starttime :: Rational{Int} = 2020 // 1
    nsteps :: Int = 0
end

@DemogPars @DemogData @ABMTimer mutable struct DemographicABMProp{T<:Clock} end

# MetaProperties (clock, start_year, currstep, nsteps)
# data.fertility

#@delegate_onefield(DemographyPars, clock, [num_ticks_year, dt])
# num_ticks_year(pars::DemographyPars) = num_ticks_year(pars.clock)
# dt(pars::DemographyPars) = dt(pars.clock)


const DemographicABM = ABM{DemographicMap}
DemographicABM(space::DemographicMap, props::DemographicABMProp) =
    ABM(Person, space; properties = props)

@delegate_onefield(DemographicABM, space,
    [random_town, positions, empty_positions,
        empty_houses, houses,
        random_house, random_empty_house, has_empty_positions, random_position, random_empty,
        add_empty_house!, add_empty_houses!])

dt(model::DemographicABM) = dt(model.clock)
currstep(model::DemographicABM) = model.starttime // 1 + model.nsteps * dt(model.clock)
metastep!(model::DemographicABM) = model.nsteps += 1

##############################
# extended Agents.jl functions
##############################

#
# The following is needed by add_agent!(agent,model)
#
function add_agent_to_space!(person, model)
    # @assert !ishomeless(person)
    @assert ishomeless(person) || hometown(person) in model.space.towns
    @assert home(person) in hometown(person).houses
    # also possible
    # push!(hometown(person).population,person)
    # push!(space.population,person)
    # push!(space.population[town[person.town]],person)
end

"overloaded add_agent!, otherwise won't work"
function add_agent!(person::Person,house::House,model::DemographicABM)
    reset_house!(person)
    set_house!(person,house)
    add_agent_pos!(person,model)
end

# needed by add_agent!(model)
add_agent!(house,::Type{Person},model::DemographicABM;age,gender=random_gender()) =
    add_agent_pos!(Person(nextid(model),house,gender=gender,age=age),model)

# needed by add_agent!(house,model)
add_agent!(house::House,model::DemographicABM;age,gender=random_gender()) =
    add_agent!(house,Person,model;age=age,gender=gender)

# needed by move_agent!(person,model)
function move_agent!(person,house,model::DemographicABM)
    reset_house!(person)
    set_house!(person,house)
end

# needed by kill_agent
function remove_agent_from_space!(person, model::DemographicABM)
    reset_house!(person)
end

function ids_in_position(house::House,model::DemographicABM)
    @warn "ids_in_position(*) was called"
    notneeded()
end
ids_in_position(person::Person,model::DemographicABM) = ids_in_position(person.pos,model)

######################
# allocation routines
######################

"move to an empty house in the same town"
function move_to_empty_house!(person,model)
    town = hometown(person)
    ehouse = has_empty_house(town) ? rand(empty_houses(town)) : add_empty_house!(model,town)
    set_house!(person,ehouse)
end
