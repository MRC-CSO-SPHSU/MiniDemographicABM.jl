"""
common functions applied on Agents.jl-ABM typically defined as:

ABM(Person,space;properties=DemographyPars(initialPop=100))

functions with argument model are expected to be found here.
"""

using Agents
using Parameters

import Agents: random_position, add_agent_to_space!, remove_agent_from_space!,
    positions, ids_in_position, has_empty_positions, random_empty,
    add_agent!, move_agent!

include("util.jl")
include("basictypes.jl")
include("spaces.jl")

###############
#  other model-based functions & types
################

@with_kw mutable struct DemographyPars
    initialPop::Int = 10000
    startProbMarried::Float64 = 0.8
end

#=
UKDemographicABM(parameters) =
    ABM(Person,space;properties=DemographyPars(initialPop=100))
# forward delegations could be useful from model.space
=#

empty_positions(model) = allhouses(model.space.towns,EmtpyHouses())
random_town(model::ABM{CountryMap}) = random_town(model.space.towns)
random_house(model) = rand(positions(model))
random_empty_house(model) = rand(empty_positions(model))
add_newhouse!(model) = add_newhouse!(model.space)
create_empty_houses!(model,nhouses) = create_empty_houses!(model.space,nhouses)


##############################
# extended Agents.jl functions
##############################

#
# The following is needed by add_agent!(agent,model)
#
function add_agent_to_space!(person, model::ABM{CountryMap})
    @assert !ishomeless(person)
    @assert hometown(person) in model.space.towns
    @assert home(person) in hometown(person).houses
    # also possible
    # push!(hometown(person).population,person)
    # push!(space.population,person)
    # push!(space.population[town[person.town]],person)
end

"overloaded add_agent!, otherwise won't work"
function add_agent!(person::Person,house::House,model::ABM{CountryMap})
    reset_person_house!(person)
    set_person_house!(person,house)
    add_agent_pos!(person,model)
end

# needed by add_agent!(model)
add_agent!(house,::Type{Person},model::ABM{CountryMap}) =
    add_agent_pos!(Person(nextid(model),house),model)

# needed by add_agent!(house,model)
add_agent!(house::House,model::ABM{CountryMap}) =
    add_agent!(house,Person,model)

# needed by move_agent!(person,model)
function move_agent!(person,house,model::ABM{CountryMap})
    reset_person_house!(person)
    set_person_house!(person,house)
end

# needed by kill_agent
function remove_agent_from_space!(person, model::ABM{CountryMap})
    reset_person_house!(person)
end

positions(model::ABM{CountryMap}) = allhouses(model.space.towns)
has_empty_positions(model::ABM{CountryMap}) = length(empty_positions(model)) > 0

notneeded() = error("not needed")
function ids_in_position(house::House,model::ABM{CountryMap})
    @warn "ids_in_position(*) was called"
    notneeded()
end
ids_in_position(person::Person,model::ABM{CountryMap}) = ids_in_position(person.pos,model)

"Shallow implementation subject to improvement by considering town densities"
function random_position(model::ABM{CountryMap})
    town = random_town(model)
    house = rand(town.houses)
    return house # bluestyle :/
end
random_empty(model::ABM{CountryMap}) = rand(empty_positions(model))
