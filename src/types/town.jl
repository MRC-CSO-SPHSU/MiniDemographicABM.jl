using StatsBase
import Agents: positions, has_empty_positions, random_position, random_empty

"""
 Potentially possible: to maintain the following
    Two lists emptyhouses and occupiedhouses can be disjointly maintained
    population::Vector{PersonType}
 or to completely remove the vector of hosues and associate it to a space type
 In a realistic real-life large-scale model, it seems best to combine both
 approaches (i.e. redundant data to be cached in a space type)
"""
struct TownH{HouseType}
    name::String
    density::Float64
    location::NTuple{2,Int}
    houses::Vector{HouseType}
end

_weights(towns) = [ town.density for town in towns ]
random_town(towns) = sample(towns, Weights(_weights(towns)))

function add_empty_house!(town,location)
    house = House(town,location)
    return house
end

function Base.show(io::IO, town::TownH)
    println(io,"town $(town.name) @location $(town.location) with " *
                "$(length(town.houses)) houses")
end

abstract type HousesType end
struct AllHouses <: HousesType end
struct EmptyHouses <: HousesType end

const Towns = Union{TownH,Vector} # One town or list of towns

houses(town::TownH,::EmptyHouses) = [ house for house in town.houses if isempty(house) ]
houses(town::TownH,::AllHouses) = town.houses
houses(town::TownH) = houses(town,AllHouses())
function houses(towns::Vector,ret::HousesType)
    hs = House[]
    for town in towns
        hs = vcat(hs,houses(town,ret))
    end
    return hs
end
houses(towns::Vector) = houses(towns,AllHouses())

empty_houses(towns::Towns) = houses(towns,EmptyHouses())

has_empty_house(town::TownH) = length(empty_houses(town)) > 0
function has_empty_house(towns::Vector)
    for town in towns
        if has_empty_house(town)
            return true
        end
    end
    return false
end

##############################
# Further stuffs
##############################

empty_positions(towns::Towns) = houses(towns,EmptyHouses())
random_house(town::TownH) = rand(houses(town))
function random_house(towns)
    town = random_town(towns)
    house = rand(town.houses)
    return house # bluestyle :/
end
random_empty_house(towns::Towns) = rand(empty_positions(towns))


##############################
# Agents.jl API-like functions
##############################

positions(towns::Towns, ret::HousesType = AllHouses()) = houses(towns,ret)
has_empty_positions(towns::Towns) = has_empty_house(towns)
random_position(towns) = random_house(towns)
random_empty(towns) = rand(empty_positions(towns))
