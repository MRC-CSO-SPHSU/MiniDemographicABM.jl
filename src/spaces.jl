"""
space types for human populations
"""

abstract type PopulationSpace <: Agents.DiscreteSpace end
struct DemographicMap <: PopulationSpace
    countryname::String
    maxTownGridDim::Int
    towns::Vector{Town}
end

DemographicMap(name,mtgd) = DemographicMap(name,mtgd,Town[])

@delegate_onefield(DemographicMap, towns,
    [empty_positions, positions, empty_houses, houses,
        random_town, random_house, random_empty_house,
        empty_positions, positions ])

# could be useful to forward delegate functions with arguments of space.towns

function add_empty_house!(space::DemographicMap)
    town = random_town(space)
    location = (rand(1:space.maxTownGridDim),rand(1:space.maxTownGridDim))
    return add_empty_house!(town,location)
end

function add_empty_houses!(space::DemographicMap,nhouses)
    houses = House[]
    for _ in 1:nhouses
        house = add_empty_house!(space)
        push!(houses,house)
    end
    return houses
end
