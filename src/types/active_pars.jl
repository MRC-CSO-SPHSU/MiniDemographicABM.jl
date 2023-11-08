"""
Basic data type for declaring active parameters to which particular analysis is sought s.a.
    sensitivity analysis, uncertainity quantification, calibration, surrogate modeling
    among others
"""

using QuasiMonteCarlo, Distributions
import StatsBase: sample

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

"produce a sample parameter set via a uniform distributioin from a set of active parameters"
function sample(apars::Vector{ActiveParameter{T}}) where T
    pars = zeros(length(apars))
    for (i,ap) in enumerate(apars)
        pars[i] =  rand(Uniform(ap.lowerbound,ap.upperbound))
    end
    return pars
end

"""
generate n sample parameters using given sampling algorithm
possible choices of sampling algorithms include Uniform, GridSample, SobolSample,
    FaureSample, LatinHybercubeSample, ..., cf. QuasieMonteCarlo.jl documentation for
    all options.
"""
function sample(n,apars::Vector{ActiveParameter{T}}, sampleAlg  ) where T
    lbs = [ ap.lowerbound for ap in ACTIVEPARS ]
    ubs = [ ap.upperbound for ap in ACTIVEPARS ]
    return QuasiMonteCarlo.sample(n,lbs,ubs,sampleAlg)
end
