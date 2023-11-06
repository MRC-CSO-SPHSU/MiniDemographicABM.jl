"""
Basic data types for Agent-based model including Person agents and space-related data types
"""

include("types/active_pars.jl")
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

const UNDEFINED_LOCATION = (-1,-1)
const UNDEFINED_TOWN = Town("",0,UNDEFINED_LOCATION)
const UNDEFINED_HOUSE = House(UNDEFINED_TOWN,UNDEFINED_LOCATION)
const NOPERSON = Person(invalid_id(),UNDEFINED_HOUSE,male,-1//1)
noperson(::Type{House}) = NOPERSON

############################
# allocation functionalities
############################

undefined(town::Town) = town == UNDEFINED_TOWN
undefined(house::House) = house == UNDEFINED_HOUSE
ishomeless(person) = undefined(home(person))
