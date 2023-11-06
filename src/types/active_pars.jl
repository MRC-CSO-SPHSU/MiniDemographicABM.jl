"""
Basic data type for declaring active parameters to which particular analysis is sought s.a.
    sensitivity analysis, uncertainity quantification, calibration, surrogate modeling
    among others
"""

mutable struct ActiveParameter{ValType}
    lowerbound::ValType
    upperbound::ValType
    name::Symbol
    function ActiveParameter{ValType}(low,upp,id) where ValType
        @assert low <= upp
        new(low,upp,id)
    end
end

set_par_value!(model,activePar::ActiveParameter{T},val::T)  where T =
    setfield!(model, activePar.name, val)

"produce a sample parameter set from a set of active parameters"
function sample_parameters(apars)
    pars = zeros(length(apars))
    for (i,ap) in enumerate(apars)
        pars[i] =  rand(Uniform(ap.lowerbound,ap.upperbound))
    end
    return pars
end
