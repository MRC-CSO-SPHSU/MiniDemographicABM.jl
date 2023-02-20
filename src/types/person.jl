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

"Cor relevant for establishing an initial population"
PersonH{HouseType}(id, pos; age, gender = random_gender()) where HouseType =
    PersonH{HouseType}(id, pos, gender, age)

"Cor for a new child"
function PersonH{HouseType}(id; mother) where HouseType
    @assert can_give_birth(mother)  # can give birth
    baby = PersonH{HouseType}(id, home(mother), age = 0//1)
    set_parentship!(baby,mother)
    set_parentship!(baby,partner(mother))
    return baby
end

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

function has_alive_children(person)
   for child in children(person)
       if isalive(child) return true end
   end
   return false
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

function set_partnership!(person1, person2)
    @assert gender(person1) != gender(person2)
    reset_partnership!(person1)
    reset_partnership!(person2)
    person1.partner = person2
    person2.partner = person1
    nothing
end

function set_parentship!(child,parent)
    @assert !(child in children(parent))
    @assert ischild(child) && isadult(parent)
    if ismale(parent)
        @assert father(child) === noperson(child)
        child.father = parent
    else
        @assert mother(child) === noperson(child)
        child.mother = parent
    end
    push!(parent.children,child)
end

############################################
### Other functions needed by step functions
############################################

function set_dead!(person)
    person.alive = false
    reset_house!(person)
    if !issingle(person)
        reset_partnership!(person)
    end
    nothing
end

function youngest_alive_child(person)
    for child in Iterators.reverse(children(person))
        if isalive(child) return child end
    end
    return noperson(person)
end

function age_youngest_alive_child(person)
    @assert has_alive_children(person)
    return age(youngest_alive_child(person))
end

can_give_birth(person) =
    isfemale(person) && isalive(person) &&   !issingle(person) &&          # basics
    isadult(person) && age(person) < 45 &&                                 # age constraints
    (!has_alive_children(person) || age_youngest_alive_child(person) > 1)  #
