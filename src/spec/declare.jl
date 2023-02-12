"""
Collection of methods for declaring the main components of a demographic model:
    - a demographic map
    - initial population
"""

using Distributions

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
    agedist = abs.(rand(dist,model.initialPop))

    # Create population with agedist
    for age in agedist
        person = Person(nextid(model),UNDEFINED_HOUSE,random_gender(),age)
        add_agent_pos!(person,model)
    end

    return allagents(model)
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

    # Establish partners
    # distribute kids among partners

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

end

function init_demography!(model) end
