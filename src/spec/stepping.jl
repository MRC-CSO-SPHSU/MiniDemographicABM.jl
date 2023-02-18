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

# Marriages

# Divorces
