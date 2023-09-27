"""
Stepping functions for evolving

    potential improvement is to have a type indicating the feature of the population, e.g.
    AlivePopulation, MalePopulation, etc. and follow traits to apply stepping functions only
    to concerned subpopulations, see e.g. SocioEconomics.jl (to appear)
    or to use agent-specific schudlers as well
"""

function _age_step!(person, model, inc)
    if !(isalive(person)) return nothing end
    person.age += inc
    if person.age == 18
        if oldest_house_occupant(home(person)) !== person
            move_to_empty_house!(person,model)
        end
    end
    return nothing
end
_dt(sim) = sim.parameters.dt
age_step!(person, model) = _age_step!(person, model, dt(model.clock))
age_step!(person, model, sim) = _age_step!(person, model,_dt(sim))

function population_age_step!(model)
    for person in allagents(model)
        age_step!(person,model)
    end
    nothing
end

function _death!(person, pars, numTicksYear)
    if !isalive(person) return false end
    ageDieRate  = ismale(person) ?
                        exp(age(person) / pars.maleAgeScaling)  * pars.maleAgeDieRate :
                        exp(age(person) / pars.femaleAgeScaling) * pars.femaleAgeDieRate
    rawRate = pars.baseDieRate + ageDieRate
    @assert rawRate < 1
    deathInstProb = instantaneous_probability(rawRate,numTicksYear)
    if rand() < deathInstProb
        set_dead!(person)
        return true
    end
    return false
end

"applying death probability to an agent"
death!(person, model) = _death!(person,model,num_ticks_year(model.clock))
death!(person, model, sim) = _death!(person, model.parameters, _num_ticks_year(sim))

# Births

function _birth!(woman, model) # should not be used an agent_step!
    curryear, = date2yearsmonths(currstep(model))
    yearsold, = date2yearsmonths(age(woman))
    birthRate =  model.fertility[yearsold-16,curryear-1950]
    # @show birthRate
    # @show instantaneous_probability(birthRate,model.clock)
    if rand() < instantaneous_probability(birthRate,model.clock)
        baby = Person(nextid(model);mother=woman)
        add_agent_pos!(baby,model)
        return true
    end
    return false
end

function birth!(person,model) # might be used as an agent_step!
    if !can_give_birth(person) return false end
    return _birth!(person,model)
end

function dobirths!(model)
    people = allagents(model)
    cnt = 0
    for rwoman in people
        if birth!(rwoman, model)
           cnt += 1
        end
    end
    return cnt
end

# Divorces
# do adult children need to move to an empty_house? probably yes!

function _divorce!(man, model)
    agem = age(man)
    rawRate = model.basicDivorceRate  * model.divorceModifierByDecade[ceil(Int, agem / 10 )]
    if rand() < instantaneous_probability(rawRate,model.clock)
        wife = partner(man)
        reset_partnership!(man, wife)
        if has_alive_children(man) && age_youngest_alive_child(man) < 3
            personToMove = man
        else
            personToMove = rand((wife,man))
        end
        move_to_empty_house!(personToMove, model)
        # children shall not move
        return true
    end
    return false
end

function divorce!(person, model)
    if !isalive(person) || !ismale(person) || issingle(person) return false  end
    return _divorce!(person,model)
end

function dodivorces!(model)
    people = allagents(model)
    cnt = 0
    for man in people
        if divorce!(man, model)
            cnt += 1
        end
    end
    return cnt
end

# Marriages

_age_class(person) = trunc(Int, age(person)/10)

# how about singles living with parents
function _join_husbands_family(husband)
    wife = partner(husband)
    @assert husband === oldest_house_occupant(home(husband))
    @assert wife === oldest_house_occupant(home(wife))
    (decider , follower) =
        length(occupants(home(husband))) > length(occupants(home(wife))) ?
            (husband , wife) : (wife , husband)
    for personToMove in occupants(home(follower))
        move_to_house!(personToMove,decider)
        @assert personToMove in occupants(home(decider))
        @assert home(personToMove) === home(decider)
    end
    move_to_house!(follower,decider)
    @assert home(follower) === home(decider)
    @assert follower in occupants(home(decider))
end

function _join_couple!(man, woman)
    @assert ismale(man) && isfemale(woman) && arepartners(man,woman)
    _join_husbands_family(man)
end

_geo_distance_factor(m, w, model) =
    manhattan_distance(hometown(m), hometown(w)) / (model.space.maxTownGridDim)

function _marry_weight(man, woman, model)::Float64
    if !issingle(man) || !issingle(woman) return 0.0 end
    geoFactor = 1/exp(4*_geo_distance_factor(man, woman, model))
    ageFactor = _marriage_agediff_weight(man,woman)
    # singles w. children are luckly to marry singles with children
    numChildrenWithWoman = num_children_living_with(woman)
    numChildrenWithMan   = num_children_living_with(man)
    childrenFactor = 1/exp(numChildrenWithWoman) * 1/exp(numChildrenWithMan) *
        exp(numChildrenWithMan * numChildrenWithWoman)
    @assert childrenFactor > 0 && geoFactor > 0 && ageFactor > 0
    return geoFactor * ageFactor * childrenFactor
end

function domarriages!(model)
    cnt = 0
    singleMen = [man for man in allagents(model) if
        is_eligible_marriage(man) && ismale(man)]
    singleWomen = [woman for woman in allagents(model) if
        is_eligible_marriage(woman) && isfemale(woman)]
    ncandidates = min(model.maxNumberOfMarriageCand,floor(Int,length(singleWomen) / 10))
    weight = Weights(zeros(ncandidates))
    for man in singleMen
        manMarriageRate =
            model.basicMaleMarriageRate * model.maleMarriageModifierByDecade[_age_class(man)]
        if rand() < instantaneous_probability(manMarriageRate,model.clock)
            @assert length(singleWomen) >= ncandidates
            wives = sample(singleWomen,ncandidates,replace=false)
            for idx in 1:ncandidates
                weight[idx] = _marry_weight(man,wives[idx],model)
            end
            wife = sample(wives,weight)
            set_partnership!(man,wife)
            _join_couple!(man,wife)
            cnt += 1
        end
    end
    return cnt
end
