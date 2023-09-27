using ABMSim: ABMPDVS

include("./simspec.jl")

const DemographicABMSim =
    ABMPDVS{Person,DemographyPars,DemographyData,Nothing,DemographicMap}
parameters(model) = model.parameters

@delegate_onefield(DemographicABMSim, space,
    [random_town, positions, empty_positions,
        empty_houses, houses,
        random_house, random_empty_house, has_empty_positions, random_position, random_empty,
        add_empty_house!, add_empty_houses!])
