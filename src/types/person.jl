using Agents
include("../util.jl")

@enum Gender male female
#@enum Status married single
random_gender() = rand((male,female))

mutable struct PersonH{HouseType} <: AbstractAgent
    id::Int
    pos::HouseType
    const gender::Gender
    #status::Status
    age::Rational{Int}

    function PersonH{HouseType}(id,pos,gender,age) where HouseType
        person = new{HouseType}(id,pos,gender,age)
        add_occupant!(pos,person)
        return person
    end
end

PersonH{HouseType}(id, pos) where HouseType =
    PersonH{HouseType}(id, pos, random_gender(), rand(20:30) + rand(0:11)//12)

home(person) = person.pos
hometown(person) = person.pos.town
age(person) = person.age
ismale(person) = person.gender == male
isfemale(person) = person.gender == female
isadult(person) = person.age >= 18
ischild(person) = person.age < 18
age2yearsmonths(person) = date2yearsmonths(person.age)

function Base.show(io::IO, person::PersonH)
    println(io,"person $(person.id) " *
            "living in house @ $(home(person).location) " *
            "@town $(hometown(person).name) " *
            "of age $(age2yearsmonths(person))")
end
