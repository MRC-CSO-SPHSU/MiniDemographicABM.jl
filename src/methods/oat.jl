"""
Given an ABM model with a set of uncertain model parameters each associated with a
    uniform distribution (Subject to generalization to other sort of distributions),
    compute:
    - the time-dependent approximated derivative trajectories
    - the normalized time-dependent approximated derivatives trajectories
    about their nominal values
"""

using LinearAlgebra: I

struct OATProblem <: LSAProblem end

"""
Parameter sensitivities can not be compared to each other directly without scaling
their quantities. This can be done by direct scaling or standard diviation of parameters
and outputs. Below are trait types that distinguish the methods to be used for rescaling
"""
abstract type NormalizationAlg end
struct NoNormalization  <: NormalizationAlg end
struct ValNormalization <: NormalizationAlg end
struct StdNormalization <: NormalizationAlg end

ΔfΔp(f,p,δ,
        nalg::NormalizationAlg=NoNormalization(),rmode ::RunMode = SingleRun(); #default
        kwargs...) =
    notimplemented("ΔfΔp with run mode $typeof(rmode) and normalization alg $typeof(nalg) not implemented")

"approximation of parameter sensitivities for a vector- (single-valued) function"
function ΔfΔp(f,pnom,δ::Float64,
                ::NoNormalization=NoNormalization(), ::SingleRun=SingleRun();  #default
                seednum)

    myseed!(seednum)
    ynom = f(pnom)
    @assert typeof(ynom) == Vector{Float64} || typeof(ynom) == Float64
    ny = length(ynom)
    np = length(pnom)
    ΔyΔp = Array{Float64,2}(undef, ny, np)
    yδall = Array{Float64,2}(undef, ny, np)
    @threads for i in 1:np
      myseed!(seednum)
      @inbounds yδ = f(pnom + pnom[i] * I[1:np,i] * δ)
      @inbounds ΔyΔp[:,i] = ( yδ - ynom ) / δ
      @inbounds yδall[:,i] = yδ
    end
    return ΔyΔp, ynom, yδall
end

function _normalize(ΔyΔp, pnom, ynom, ::ValNormalization)
    ΔyΔpNorm = copy(ΔyΔp)
    ny = length(ynom)
    @simd for i in 1:ny
        @inbounds ΔyΔpNorm[i,:] =  pnom .* ( ΔyΔpNorm[i,:] / ynom[i] )
    end
    return ΔyΔpNorm
end

"value normalized parameter sensitivities"
function ΔfΔp(f,pnom,δ::Float64,::ValNormalization,rmode::SingleRun=SingleRun(); seednum)
    ΔyΔp , ynom, yδall = ΔfΔp(f,pnom,δ;seednum)
    ΔyΔpNorm = _normalize(ΔyΔp,pnom,ynom,ValNormalization())
    return ΔyΔpNorm, ΔyΔp, ynom, yδall
end

"normalization with standard diviation of outputs and parameters"
function _normalize(ΔyΔp,σp,σy,::StdNormalization)
    ΔyΔpNor = copy(ΔyΔp)
    ny = size(ΔyΔpNor)[1]
    @simd for i in 1:ny
        @inbounds ΔyΔpNor[i,:] =  σp .* ( ΔyΔpNor[i,:] / σy[i] )
    end
    return ΔyΔpNor
end

"""
parameter sensitivities normalized with standard diviations
    - of parameters derived from a uniform distribution
    - of model outputs computed via a design matrix
"""
function ΔfΔp(f,pnom,δ::Float64,::StdNormalization, rmode::SingleRun=SingleRun();
    seednum, σp, σy)

    # approximate derivatives
    ΔyΔp, ynom, yδall = ΔfΔp(f,pnom,δ;seednum)
    # normalization
    ΔyΔpNor = _normalize(ΔyΔp,σp,σy,StdNormalization())
    return  ΔyΔpNor, ΔyΔp, ynom, yδall
end


"""
OAT Result contains:
- pnom  : nominal parameter values
- ytnom : associated output trajectories of size nt x ny where
    nt: number of points
    ny: number of outputs

"""
mutable struct OATResult
    pnom::Vector{Float64}      # nominal parameter values
    ynom::Vector{Float64}      # trajectories of the output
    yδall::Matrix{Float64}      # trajectories of the outputs with deviated parameters
    ΔyΔp::Matrix{Float64}     # trajectories of approximated partial derivatives
    ΔyΔpNor::Matrix{Float64}  # normalized

    function OATResult(f, actpars, δ, ::NoNormalization=NoNormalization(); kwargs...)
        pnom = nominal_values(actpars)
        ΔyΔp, ynom, yδall  = ΔfΔp(f,pnom,δ;kwargs...)
        new(pnom,ynom,yδall,ΔyΔp,zeros(1,1))
    end

    function OATResult(f, actpars, δ, ::ValNormalization; kwargs...)
        oatres = OATResult(f,actpars,δ;kwargs...)
        normalize!(oatres,ValNormalization())
        return oatres
    end

    function OATResult(f, actpars, δ, ::StdNormalization; σp, σy, kwargs...)
        oatres = OATResult(f,actpars,δ; kwargs...)
        normalize!(oatres,σp,σy,StdNormalization())
        return oatres
    end

end # OATResult

function normalize!(oatres::OATResult,::ValNormalization)
    oatres.ΔyΔpNor = _normalize(oatres.ΔyΔp, oatres.pnom,  oatres.ynom, ValNormalization())
    return nothing
end

function normalize!(oatres::OATResult, σp, σy, ::StdNormalization)
    oatres.ΔyΔpNor = _normalize(oatres.ΔyΔp, σp, σy, StdNormalization())
    return nothing
end

solve(::OATProblem, f, actpars::Vector{ActiveParameter{Float64}}, ::SingleRun;
    δ, normAlg::NormalizationAlg = NoNormalization(), kwargs...) =
        OATResult(f, actpars, δ, normAlg; kwargs...)

# another possible interface :
# solve(::OATProblem,f,actpars,::StdNormalization,::MultiRun;
#       seednum,sampleAlg=SobolSample(),n=length(p)*length(p))
