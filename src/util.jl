using Plots

"convert date in rational representation to (years, months) as tuple"
function date2yearsmonths(date::Rational{Int})
    #date < 0 ? throw(ArgumentError("Negative age")) : nothing
    12 % denominator(date) != 0 ? throw(ArgumentError("$(date) not in date/age format")) : nothing
    years  = trunc(Int, numerator(date) / denominator(date))
    months = trunc(Int, numerator(date) % denominator(date) * 12 / denominator(date) )
    return (years , months)
end

notimplemented(msg = "") = error("not implemeented" * msg)
notneeded(msg = "") = error("not needed" * msg)

invalid_id() = 0
has_invalid_id(agent::AbstractAgent) = agent.id == invalid_id()

function show_number_of_kids_per_distribution(model)
    population = allagents(model)
    marriedMen = [man for man in population if ismale(man) &&
        (!issingle(man) || has_children(man)) ]
    numOfKidsDist = [ length(children(man)) for man in marriedMen ]
    histogram(numOfKidsDist,bins=0:15)
end

show_age_distribution(model) = histogram([ person.age for person in allagents(model) ])

function show_agediff_of_married_dist(model)
    agediff = [age(man)-age(partner(man)) for man in allagents(model) if
                !issingle(man) && ismale(man)]
    histogram(agediff)
end

"before initializing housing of a population"
function verify_homeless_population(model)
    for person in allagents(model)
        if !undefined(home(person))
            return false
        end
    end
    return true
end

function verify_all_have_home(model)
    for person in allagents(model)
        if ishomeless(person) return false end
    end
    return true
end

function verify_housing_consistency(model)
    for person in allagents(model)
        if !ishomeless(person)
            if !(person in occupants(home(person)))
                return false
            end
        end
    end
    return true
end

function verify_singles_live_alone(model)
    singles = [single for single in allagents(model) if issingle(single)]
    for single in singles
        @assert single in home(single).occupants
        if length(occupants(home(single))) != 1 return false end
    end
    return true
end

"with the assumption that there is no sinlge parent"
function verify_families_live_together(model)
    married = [m for m in allagents(model) if !issingle(m)]
    for person in married
        if isfemale(person)
            @assert partner(person) in married
            continue
        end
        if home(person) !== home(partner(person)) return false end
        for child in children(person)
            if home(child) !== home(person) return false end
        end
    end
    return true
end

"verify that all kids have parents"
function verify_children_parents(model)
    kids = [kid for kid in allagents(model) if ischild(kid)]
    for child in kids
        if father(child) === noperson(child) || mother(child) === noperson(child)
            return false
        end
        if !(child in children(father(child)) && child in children(mother(child)))
            return false
        end
    end

    parents = [parent for parent in allagents(model) if has_children(parent)]
    for parent in parents
        if ischild(parent)
            @warn "$parent is a child"
            return false
        end
        if !(issubset(children(parent),kids))
            @warn "children of $parent not in model agents"
            for child in children(parent)
                @warn child
            end
            return false
        end
    end

    return true
end

"verify that adults of initial population have no parents"
function verify_parentless_adults(model)
    adults = [adult for adult in allagents(model) if isadult(adult)]
    for adult in adults
        if father(adult) !== noperson(adult) || mother(adult) !== noperson(adult)
            return false
        end
    end
    return true
end

"verify consistency of partnership relations"
function verify_partnership(model)
    for person in allagents(model)
        if !issingle(person)
            if !(partner(person) in allagents(model)) return false end
            if issingle(partner(person)) return false end
            if partner(partner(person)) !== person return false end
        end
    end
    return true
end
