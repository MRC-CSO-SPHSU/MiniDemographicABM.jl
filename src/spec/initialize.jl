function _marriage_agediff_weight(man,woman)
    @assert gender(man) == male && gender(woman) == female
    agediff = age(man) - age(woman)
    ageindex = 1.0
    if agediff >= 5
        ageindex = 1.0 / (agediff-5+1)
    elseif ageindex <= -2
        ageindex = -1.0 / (agediff+2-1)
    end
    @assert ageindex > 0
    return ageindex
end

function _init_kinship!(model,pars)
    @assert nagents(model) > 0

    adultWomen = Person[] ; adultMen = Person[] ; kids = Person[]
    for person in allagents(model)
        if ischild(person)
            push!(kids,person)
        else
            ismale(person) ? push!(adultMen,person) : push!(adultWomen,person)
        end
    end

    ncandidates = min(pars.maxNumberOfMarriageCand,floor(Int,length(adultWomen) / 10))
    weight = Weights(zeros(ncandidates))

    # Establish partners
    for man in adultMen
        if rand() < pars.startMarriedRate
            wives = sample(adultWomen,ncandidates,replace=false)
            for idx in 1:ncandidates
                weight[idx] = !issingle(wives[idx]) ? 0.0 :
                _marriage_agediff_weight(man,wives[idx])
            end
            woman = sample(wives,weight)
            set_partnership!(man,woman)
        end
    end

    marriedMen = [man for man in adultMen if !issingle(man)]
    for child in kids
        fathers = [ father for father in marriedMen if
            min(age(father),age(partner(father))) - age(child) > 18 + 9 //12 &&
            age(partner(father)) - age(child) < 45 ]
        father = rand(fathers)
        set_parentship!(child,father)
        set_parentship!(child,partner(father))
    end

    return nothing
end

"""
Simplified model for an initial population kinship
Assumptions:
- No single parents
- No orphans
- ages of siblings may be inconsistent (few months difference)
"""
init_kinship!(model) = _init_kinship!(model,parameters(model))

"""
assign housing to a population.
Assumptions:
- the population is homeless
- no single parents
- no orphans
"""
function init_housing!(model)
    population = allagents(model)

    for person in population
        if ischild(person) continue end
        if issingle(person)
            house = add_empty_house!(model)
            move_agent!(person,house,model)
            continue
        end
        if ismale(person)
            house = add_empty_house!(model)
            move_agent!(person,house,model)
            @assert undefined(home(partner(person)))
            move_agent!(partner(person),house,model)
            for child in children(person)
                move_agent!(child,house,model)
            end
        end
    end

    nothing
end
