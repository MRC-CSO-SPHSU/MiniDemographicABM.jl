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

"leaving dead people in population"
function death_step!(person, model)
    if !alive(person) return false end
    ageDieProb  = ismale(person) ?
                        exp(age(person) / model.maleAgeScaling)  * model.maleAgeDieProb :
                        exp(age(person) / model.femaleAgeScaling) * model.femaleAgeDieProb
    rawRate = model.baseDieProb + ageDieProb
    deathInstProb = instantaneous_probability(rate,model.clock)
    if rand() < deathInstProb
        set_dead!(person)
        return true
    end
    return false
end

# Births

# Marriages

# Divorces
