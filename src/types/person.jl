using Agents
include("../util.jl")

@enum Gender male female
random_gender() = rand((male,female))

function noperson(::Type{HouseType}) where HouseType end

mutable struct PersonH{HouseType} <: AbstractAgent
    id::Int
    pos::HouseType
    const gender::Gender
    age::Rational{Int}
    partner::PersonH{HouseType}
    #=father::PersonH{HouseType}
    mother::PersonH{HouseType}
    children::PersonH{HouseType}=#
    function PersonH{HouseType}(id,pos,gender,age) where HouseType
        person = new{HouseType}(id,pos,gender,age)
        person.partner = person.id == 0 ? person : noperson(HouseType)
        add_occupant!(pos,person)
        return person
    end
end

PersonH{HouseType}(id, pos; age, gender = random_gender()) where HouseType =
    PersonH{HouseType}(id, pos, gender, age)

age(person) = person.age
gender(person) = person.gender
#=father(person) = isdefined(person,:father) ? person.father : NOPERSON
mother(person) = isdefined(person,:mother) ? person.mother : NOPERSON=#


home(person) = person.pos
hometown(person) = person.pos.town

ismale(person) = person.gender == male
isfemale(person) = person.gender == female
isadult(person) = person.age >= 18
ischild(person) = person.age < 18
partner(person) = person.partner
issingle(person) =  partner(person) === NOPERSON # !isdefined(person,:partner) ||

function reset_partnership!(person)
    if !issingle(person)
        p = partner(person)
        person.partner = NOPERSON
        p.partner = NOPERSON
    end
    nothing
end

function set_as_partners!(person1, person2)
    @assert gender(person1) != gender(person2)
    reset_partnership!(person1)
    reset_partnership!(person2)
    person1.partner = person2
    person2.partner = person1
    nothing
end

age2yearsmonths(person) = date2yearsmonths(person.age)


function Base.show(io::IO, person::PersonH)
    print(io,"person $(person.id) " *
            "living in house @ $(home(person).location) " *
            "@town $(hometown(person).name) " *
            "of age $(age2yearsmonths(person))")
    if !issingle(person)
        println(io,"married to $(partner(person).id)")
    end
end
