"""
Basic data type for declaring active parameters to which particular analysis is sought s.a.
    sensitivity analysis, uncertainity quantification, calibration, surrogate modeling
    among others
"""

using QuasiMonteCarlo, Distributions
import StatsBase: sample, std

"""
A data type for uncertain model parameter w.r.t. which computational analysis task  is
    sought, e.g. sensitivity analysis or calibration. It is assumed that such an uncertain
    parameter is derived from a uniform distribution (subject to generalization by need)
"""
mutable struct ActiveParameter{ValType}
    name::Symbol
    lowerbound::ValType
    upperbound::ValType
    nomval::ValType # nominal value
    function ActiveParameter{ValType}(id,low,upp,nv) where ValType
        @assert low <= nv <= upp
        new(id,low,upp,nv)
    end
end

set_par_value!(model,activePar::ActiveParameter{T},val::T)  where T =
    setfield!(model, activePar.name, val)

nominal_values(actpars::Vector{ActiveParameter{T}}) where T =
    [ ap.nomval for ap in actpars ]

"produce a sample parameter set via a uniform distributioin from a set of active parameters"
sample(apars::Vector{ActiveParameter{T}}) where T =
    [ rand(Uniform(ap.lowerbound,ap.upperbound)) for ap in apars ]

"""
generate n sample parameters using given sampling algorithm
possible choices of sampling algorithms include Uniform, GridSample, SobolSample,
    FaureSample, LatinHybercubeSample, ..., cf. QuasieMonteCarlo.jl documentation for
    all options.
"""
sample(n,apars::Vector{ActiveParameter{T}}, sampleAlg  ) where T =
    QuasiMonteCarlo.sample(n,
        [ ap.lowerbound for ap in apars ],
        [ ap.upperbound for ap in apars ] ,
        sampleAlg)


"standard diviation of uncertain parameter derived from a uniform distribution"
std(apar::ActiveParameter{T}) where T = (apar.upperbound - apar.lowerbound)^2 / 12
std(apars::Vector{ActiveParameter{T}}) where T =  [std(ap) for ap in apars]

"Evaluate stdandard diviation of function inputs and outputs"
function std(f, ny, actpars::Vector{ActiveParameter{T}}, seednum,
                n=length(actpars)*length(actpars), sampleAlg = SobolSample()) where T

    σp = std(actpars)
    pmatrix = sample(n,actpars,sampleAlg)  # design matrix
    ymatrix = Array{Float64}(undef,ny,n)
     # compute σ_y
    @threads for i in 1:n
        myseed!(seednum)
        @inbounds ymatrix[:,i] = f(pmatrix[:,i])
    end
    σy = [std(ymatrix[i,:]) for i in 1:ny]
    return σp, σy, pmatrix, ymatrix
end
