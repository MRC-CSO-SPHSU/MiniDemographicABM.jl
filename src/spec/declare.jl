"""
Collection of methods for declaring the main components of a demographic model:
    - a demographic map
    - initial population
"""

using Distributions
using StatsBase

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

# TODO nice to have
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

function _declare_population!(model,numTicksYear,initialPop)
    @assert nagents(model) == 0
    dist = Normal(0,0.25*100*numTicksYear)
    agedist = floor.(Int,abs.(rand(dist,initialPop)))
    # Create population with agedist
    for a in agedist
        person = Person(nextid(model),UNDEFINED_HOUSE,random_gender(),
                        a // numTicksYear)
        add_agent_pos!(person,model)
    end
    return allagents(model)
end

"""
Simplified model for an initial population
    assumed that that the start of the simulation is in times where significiant portions of
    adults constitutes families and the population pyramid takes a normal distribution form,
    i.e. the number of people for each age category decreases with increasing age

    The model is subject to improvement by parameterizing the employed primative
    distribution for computing age
"""
declare_population!(model) =
    _declare_population!(model,num_ticks_year(model.clock),model.initialPop)

_num_ticks_year(sim) = sim.parameters.dt == 1 // 1 ? 365 : notimplemented()

declare_population!(model,simulator) =
    _declare_population!(model,_num_ticks_year(simulator),10000)
