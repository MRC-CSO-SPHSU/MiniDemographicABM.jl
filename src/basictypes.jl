"""
Basic data types for simulation of Agent-based models including Person agents
    and space-related data types
"""

include("types/clock.jl")
include("types/town.jl")
include("types/house.jl")
include("types/person.jl")

##############################
# concerete types
################################

const Town = TownH{HouseTP}
const House = HouseTP{Town,PersonH}
const Person = PersonH{House}

Town(density,location) = Town("",density,location,House[])
Town(name,density,location) = Town(name,density,location,House[])

global const UNDEFINED_LOCATION = Ref{Tuple{Int64,Int64}}((-1,-1))
undefined_location() = UNDEFINED_LOCATION[]
global const UNDEFINED_TOWN = Ref{Town}(Town("",0,undefined_location()))
undefined_town() = UNDEFINED_TOWN[]
global const UNDEFINED_HOUSE = Ref{House}(House(undefined_town(),undefined_location()))
undefined_house() = UNDEFINED_HOUSE[]
global const NOPERSON = Person(invalid_id(),undefined_house(),male,-1//1)
noperson(::Type{House}) = NOPERSON


############################
# allocation functionalities
############################

undefined(town::Town) = town == undefined_town()
undefined(house::House) = house == undefined_house()
ishomeless(person) = undefined(home(person))
