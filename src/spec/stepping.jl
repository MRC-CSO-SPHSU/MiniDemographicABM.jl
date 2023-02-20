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
function death!(person, model)
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

function _birth!(woman, model) # should not be used an agent_step!
    curryear, = date2yearsmonths(currstep(model))
    yearsold, = date2yearsmonths(age(woman))
    birthProb =  model.fertility[yearsold-16,curryear-1950]
    # @show birthProb
    # @show instantaneous_probability(birthProb,model.clock)
    if rand() < instantaneous_probability(birthProb,model.clock)
        baby = Person(nextid(model);mother=woman)
        add_agent_pos!(baby,model)
        return true
    end
    return false
end

function birth!(woman,model) # might be used as an agent_step!
    if !can_give_birth(woman) return false end
    return _birth!(woman,model)
end

function dobirths!(model)
    people = allagents(model)
    len = length(people)
    cnt = 0
    for rwoman in people
        if birth!(rwoman, model)
           cnt += 1
        end
    end
    return cnt
end

# Marriages

# Divorces
