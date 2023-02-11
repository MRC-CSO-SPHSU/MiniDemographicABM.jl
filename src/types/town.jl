using StatsBase
import Agents: positions

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

abstract type GetHouses end
struct AllHouses <: GetHouses end
struct EmptyHouses <: GetHouses end

const Towns = Union{TownH,Vector} # One town or list of towns

allhouses(town::TownH,::EmptyHouses) = [ house for house in town.houses if isempty(house) ]
allhouses(town::TownH,::AllHouses) = town.houses
allhouses(town::TownH) = allhouses(town,AllHouses())
function allhouses(towns::Vector,ret::GetHouses)
    houses = House[]
    for town in towns
        houses = vcat(houses,allhouses(town,ret))
    end
    return houses
end
allhouses(towns::Vector) = allhouses(towns,AllHouses())

empty_houses(towns::Towns) = allhouses(towns,EmptyHouses())

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
# Agents.jl API-like functions
##############################

positions(towns::Towns, ret::GetHouses = AllHouses()) = allhouses(towns,ret)

##############################
# Further stuffs
##############################

empty_positions(towns::Towns) = positions(towns,EmptyHouses())
random_house(towns::Towns) = rand(positions(towns))
random_empty_house(towns::Towns) = rand(empty_positions(towns))
