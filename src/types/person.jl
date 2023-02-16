using Agents
include("../util.jl")

@enum Gender male female
random_gender() = rand((male,female))

noperson(::Type{HouseType}) where HouseType = notimplemented()

mutable struct PersonH{HouseType} <: AbstractAgent
    const id::Int
    pos::HouseType
    const gender::Gender
    age::Rational{Int}
    alive::Bool
    partner::PersonH{HouseType}
    father::PersonH{HouseType}
    mother::PersonH{HouseType}
    children::Vector{PersonH{HouseType}}
    function PersonH{HouseType}(id,pos,gender,age) where HouseType
        person = new{HouseType}(id,pos,gender,age,true)
        if has_invalid_id(person)
            return person
        end
        person.partner = person.father = person.mother = noperson(HouseType)
        person.children = PersonH{HouseType}[]
        add_occupant!(pos,person)
        return person
    end
end

PersonH{HouseType}(id, pos; age, gender = random_gender()) where HouseType =
    PersonH{HouseType}(id, pos, gender, age)

###############
## Accessories
###############

age(person) = person.age
gender(person) = person.gender
partner(person) = person.partner
father(person) = person.father
mother(person) = person.mother
children(person) = person.children

home(person) = person.pos
hometown(person) = person.pos.town

###############
### helpers
###############

housetype(p::PersonH{HouseType}) where HouseType = HouseType
noperson(person) = noperson(housetype(person))
ismale(person) = person.gender == male
isfemale(person) = person.gender == female
isadult(person) = person.age >= 18
ischild(person) = person.age < 18
isalive(person) = person.alive
isdead(person) = !person.alive
issingle(person) =  partner(person) === noperson(person)
has_children(person) = length(person.children) > 0
ischildless(person) = !has_children(person)
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

#############
### Kinship
#############

function reset_partnership!(person)
    if !issingle(person)
        p = partner(person)
        person.partner = noperson(person)
        p.partner = noperson(person)
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

function set_as_parent!(child,parent)
    @assert !(child in children(parent))
    if ismale(parent)
        @assert father(child) === noperson(child)
        child.father = parent
    else
        @assert mother(child) === noperson(child)
        child.mother = parent
    end
    push!(parent.children,child)
end

############
###
############

function set_dead!(person)
    person.alive = false
    reset_house!(person)
    if !issingle(person)
        reset_partnership!(partner(person),person)
    end
    nothing
end
