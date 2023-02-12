"""
common functions applied on Agents.jl-ABM typically defined as:

ABM(Person,space;properties=DemographyPars(initialPop=100))

functions with argument model are expected to be found here.
"""

using Parameters

import Agents: add_agent_to_space!, remove_agent_from_space!,
    ids_in_position, add_agent!, move_agent!

include("spaces.jl")

#######################################
#  other model-based functions & types
#######################################

@with_kw mutable struct DemographyPars
    initialPop::Int = 100
    startProbMarried::Float64 = 0.8
end

const DemographicABM = ABM{DemographicMap}
DemographicABM(space::DemographicMap, parameters::DemographyPars) =
    ABM(Person, space; properties = parameters)

@delegate_onefield(DemographicABM, space,
    [random_town, positions, empty_positions,
        empty_houses, houses,
        random_house, random_empty_house, has_empty_positions, random_position, random_empty,
        add_empty_house!, add_empty_houses!])

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
    reset_person_house!(person)
    set_person_house!(person,house)
    add_agent_pos!(person,model)
end

# needed by add_agent!(model)
add_agent!(house,::Type{Person},model::DemographicABM) =
    add_agent_pos!(Person(nextid(model),house),model)

# needed by add_agent!(house,model)
add_agent!(house::House,model::DemographicABM) =
    add_agent!(house,Person,model)

# needed by move_agent!(person,model)
function move_agent!(person,house,model::DemographicABM)
    reset_person_house!(person)
    set_person_house!(person,house)
end

# needed by kill_agent
function remove_agent_from_space!(person, model::DemographicABM)
    reset_person_house!(person)
end

notneeded() = error("not needed")
function ids_in_position(house::House,model::DemographicABM)
    @warn "ids_in_position(*) was called"
    notneeded()
end
ids_in_position(person::Person,model::DemographicABM) = ids_in_position(person.pos,model)
