import Base: isempty

struct HouseTP{TownType,PersonType}
    town::TownType
    location::NTuple{2,Int}
    occupants::Vector{PersonType}

    function HouseTP{TownType,PersonType}(town,location) where {TownType,PersonType}
        house = new{TownType,PersonType}(town,location,PersonType[])
        push!(town.houses,house)
        return house
    end
end

occupants(house) = house.occupants
isempty(house::HouseTP) = isempty(house.occupants)
remove_occupant!(house::HouseTP,person) =
    splice!(house.occupants, findfirst(x -> x == person, house.occupants))
function add_occupant!(house::HouseTP,person)
    @assert person.pos == house
    @assert !(person in house.occupants)
    push!(house.occupants,person)
end

function oldest_house_occupant(house)
    maxage = -1
    ret = noperson(typeof(house))
    for person in occupants(house)
        if age(person) > maxage
            ret = person
            maxage = age(person)
        end
    end
    return ret
end

function Base.show(io::IO, house::HouseTP)
    println(io,"house @ location $(house.location) @ town $(house.town.name)")
    if isempty(house)
        println(io,"\twith no occupants")
    else
        print(io,"\t with occupant ids:")
        for person in house.occupants
            print(io,"\t$(person.id)")
        end
    end
end
