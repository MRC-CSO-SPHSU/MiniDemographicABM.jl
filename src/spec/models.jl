"""
common functions applied on Agents.jl-ABM typically defined as:

ABM(Person,space;properties=DemographyPars(initialPop=100))

functions with argument model are expected to be found here.
"""

using Parameters
include("../util.jl")

import Agents: add_agent_to_space!, remove_agent_from_space!,
    ids_in_position, add_agent!, move_agent!

include("spaces.jl")

#######################################
#  other model-based functions & types
#######################################

@with_kw mutable struct DemographyPars{T <: Clock}
    # basic fields
    clock::T = T()
    initialPop::Int = 100
    # Initialization parameters
    startProbMarried::Float64 = 0.8  # Probability of an adult man is being married
    maxNumberOfMarriageCand::Int64 = 100
    # death parameters / yearly comulative (adhoc no model identification conducted)
    baseDieProb::Float64            = 0.0001
    maleAgeDieProb::Float64         = 0.00021
    maleAgeScaling::Float64         = 14.0
    femaleAgeDieProb::Float64       = 0.00019
    femaleAgeScaling::Float64       = 15.5
    # birth parameters

end

# MetaProperties (clock, start_year, currstep, nsteps)
# data.fertility

#@delegate_onefield(DemographyPars, clock, [num_ticks_year, dt])
# num_ticks_year(pars::DemographyPars) = num_ticks_year(pars.clock)
# dt(pars::DemographyPars) = dt(pars.clock)


const DemographicABM = ABM{DemographicMap}
DemographicABM(space::DemographicMap, parameters::DemographyPars) =
    ABM(Person, space; properties = parameters)

@delegate_onefield(DemographicABM, space,
    [random_town, positions, empty_positions,
        empty_houses, houses,
        random_house, random_empty_house, has_empty_positions, random_position, random_empty,
        add_empty_house!, add_empty_houses!])

dt(model::DemographicABM) = dt(model.clock)

##############################
# extended Agents.jl functions
##############################

#
# The following is needed by add_agent!(agent,model)
#
function add_agent_to_space!(person, model::DemographicABM)
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
