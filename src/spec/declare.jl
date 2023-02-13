"""
Collection of methods for declaring the main components of a demographic model:
    - a demographic map
    - initial population
"""

using Distributions
#using StatsBase

include("models.jl")

"""
The relative densitiy of each town w.r.t. the town of maximal population
"""
const UKDENSITY = [ 0.0 0.1 0.2 0.1 0.0 0.0 0.0 0.0;
                    0.1 0.1 0.2 0.2 0.3 0.0 0.0 0.0;
                    0.0 0.2 0.2 0.3 0.0 0.0 0.0 0.0;
                    0.0 0.2 1.0 0.5 0.0 0.0 0.0 0.0;
                    0.4 0.0 0.2 0.2 0.4 0.0 0.0 0.0;
                    0.6 0.0 0.0 0.3 0.8 0.2 0.0 0.0;
                    0.0 0.0 0.0 0.6 0.8 0.4 0.0 0.0;
                    0.0 0.0 0.2 1.0 0.8 0.6 0.1 0.0;
                    0.0 0.0 0.1 0.2 1.0 0.6 0.3 0.4;
                    0.0 0.0 0.5 0.7 0.5 1.0 1.0 0.0;
                    0.0 0.0 0.2 0.4 0.6 1.0 1.0 0.0;
                    0.0 0.2 0.3 0.0 0.0 0.0 0.0 0.0 ]

# TODO
# const UKTOWNNAMES = ...

function declare_UK_map()
    UKMap = DemographicMap("The United Kingdom",25)
    nrows, ncols = size(UKDENSITY)
    for x in 1:ncols
        for y in 1:nrows
            if UKDENSITY[y,x] > 0
                add_town!(UKMap, UKDENSITY[y,x], (y,x))
            end
        end
    end
    return UKMap
end

UKDemographicABM(pars) = DemographicABM(declare_UK_map(),pars)

"""
Simplified model for an initial population
    assumed that that the start of the simulation is in times where significiant portions of
    adults constitutes families and the population pyramid takes a normal distribution form,
    i.e. the number of people for each age category decreases with increasing age

    The model is subject to improvement by parameterizing the employed primative
    distribution for computing age
"""
function declare_population!(model)
    @assert nagents(model) == 0
    dist = Normal(0,0.25*100*12) # potentialMaxAge * 12 months
    agedist = floor.(Int,abs.(rand(dist,model.initialPop)))

    # Create population with agedist
    for a in agedist
        person = Person(nextid(model),UNDEFINED_HOUSE,random_gender(), a // 12)
        add_agent_pos!(person,model)
    end

    return allagents(model)
end

function _marriage_selection_weight(man,woman)
    @assert gender(man) == male && gender(woman) == female
    agediff = age(man) - age(woman)
    ageindex = 1.0
    if agediff > 5
        ageindex = 1.0 / (agediff-5+1)
    elseif ageindex < -2
        ageindex = 1.0 / (agediff+2-1)
    end
    return ageindex
end

"""
Simplified model for an initial population kinship
Assumptions:
- No single parents
- No orphans
"""
function init_kinship!(model)
    @assert nagents(model) > 0

    adultWomen = Person[] ; adultMen = Person[] ; kids = Person[]
    for person in allagents(model)
        if ischild(person)
            push!(kids,person)
        else
            ismale(person) ? push!(adultMen,person) : push!(adultWomen,person)
        end
    end

    ncandidates = floor(Int,length(adultWomen) / 10)
    weight = Weights(zeros(ncandidates))

    # Establish partners
    for man in adultMen
        @assert issingle(man)
        if rand() < model.startProbMarried
            wcandidates = sample(adultWomen,ncandidates,replace=false)
            for idx in 1:ncandidates
                weight[idx] = !issingle(wcandidates[idx]) ? 0.0 : _marriage_selection_weight(man,wcandidates[idx])
            end
            woman = sample(wcandidates,weight)
            set_as_partners!(man,woman)
        end
    end

    # distribute kids among partners

    nothing
end

    #=



    while nagents(model) < model.initialPop
        if rand() < model.startProbMarried  # create a family
            house = add_newhouse!(model)
            manage = NormalDist(model.startAverageAge,model.startAgeStdDiv)
            # create a man and a woman
            man = Person(nextid(model),)
            # create kids
            # move the family to houses
        else # consider two adults
            # create two houses
            # create two adults
            # move the adults to the houses
        end
    end
    =#
