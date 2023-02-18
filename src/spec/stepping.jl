"""
Stepping functions for evolving

    potential improvement is to have a type indicating the feature of the population, e.g.
    AlivePopulation, MalePopulation, etc. and follow traits to apply stepping functions only
    to concerned subpopulations, see e.g. SocioEconomics.jl (to appear)
    or to use agent-specific schudlers as well
"""

age_step!(person,model) = person.age += isalive(person) ? dt(model.clock) : zero(person.age)

function population_age_step!(model)
    for person in allagents(model)
        age_step!(person,model)
    end
    nothing
end

"applying death probability to an agent"
function death_step!(person, model)
    # Subject to improvement by pre-storing the computation below in a table
    # age_in_float?
    if !isalive(person) return false end
    ageDieProb  = ismale(person) ?
                        exp(age(person) / model.maleAgeScaling)  * model.maleAgeDieProb :
                        exp(age(person) / model.femaleAgeScaling) * model.femaleAgeDieProb
    rawRate = model.baseDieProb + ageDieProb
    @assert rawRate < 1
    deathInstProb = instantaneous_probability(rawRate,model.clock)
    if rand() < deathInstProb
        set_dead!(person)
        return true
    end
    return false
end

# Births

##TODO
# currstep
# data
# simulation properties
function _birth_probability(rWoman,data,currstep)
    curryear, = date2yearsmonths(currstep)
    yearsold,  = date2yearsmonths(rWoman)
    rawRate = data.fertility[yearold-16,curryear-1950]
    return rawRate
end # computeBirthProb

function _subject_to_birth(woman, currstep, data)
    birthProb = _birth_probability(woman, data, currstep)
    if rand() < instantaneous_probability(birthProb)
        return true
    end # if rand()
    return false
end

function _birth!(woman, currstep, data)
    if _subject_to_birth(woman, currstep, data)
        _givesbirth!(woman) # new baby
        return true
    end
    return false
end

function population_birth_step!(model)
    data = data_of(model)
    people = allagents(model)
    time = currestep(model)
    for (ind,woman) in enumerate(Iterators.reverse(people))
        if ! can_give_birth(woman) continue end
        if _birth!(woman, time, data, birthpars)
           @assert people[len-ind+1] === woman
           add_person!(model,youngest_child(woman)::Person)
           ret = progress_return!(ret,(ind=len-ind+1,person=woman))
        end
    end # for woman
end
# Marriages

# Divorces
