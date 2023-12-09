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

ΔfΔp(f,p,δ::Float64,rmode ::RunMode,nalg::NormalizationAlg;seednum) =
    notimplemented("ΔfΔp with run mode $typeof(rmode) and normalization alg $typeof(nalg) not implemented")
ΔfΔp(f,p,δ::Float64,::MethodMultiRun,nalg::NormalizationAlg;seednum,mruns) =
    notimplemented("ΔfΔp with multiple run mode and normalization alg $typeof(nalg) not implemented")

"approximation of parameter sensitivities for a vector- (single-valued) function"
function ΔfΔp(f,pnom,δ::Float64,
        ::SingleRun=SingleRun(),::NoNormalization=NoNormalization();  #default
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

function _normalize(ΔyΔp, ynom, pnom, ::ValNormalization)
    ΔyΔpNorm = copy(ΔyΔp)
    ny = length(ynom)
    @simd for i in 1:ny
        @inbounds ΔyΔpNorm[i,:] =  pnom .* ( ΔyΔpNorm[i,:] / ynom[i] )
    end
    return ΔyΔpNorm
end

"value normalized parameter sensitivities"
function ΔfΔp(f,pnom,δ::Float64,::SingleRun,::ValNormalization; seednum)
    ΔyΔp , ynom, yδall = ΔfΔp(f,pnom,δ;seednum)
    ΔyΔpNorm = _normalize(ΔyΔp,ynom,pnom,ValNormalization())
    return ΔyΔpNorm, ΔyΔp, ynom, yδall
end

function _normalize_std!(ΔyΔpNorm,σp,σy)
    ny = size(ΔyΔpNorm)[1]
    @simd for i in 1:ny
        @inbounds ΔyΔpNorm[i,:] =  σp .* ( ΔyΔpNorm[i,:] / σy[i] )
    end
    nothing
end

"""
parameter sensitivities normalized with standard diviations
    - of parameters derived from a uniform distribution
    - of model outputs computed via a design matrix
"""
function ΔfΔp_normstd(f,p,δ,::RunMode=SingleRun();
                        seednum,sampleAlg=SobolSample(),n=length(p)*length(p))
    # compute derivatives
    ΔyΔpNorm, y = ΔfΔp(f,p,δ;seednum)
    ny = length(y)
    # normalization
    σp = std(actpars)
    pmatrix = sample(n,actpars,sampleAlg)  # design matrix
    ymatrix = Array{Float64}(undef,ny,n)
     # compute σ_y
    @threads for i in 1:n
        myseed!(seed!)
        @inbounds ymatrix[:,i] = f(pmatrix[:,i])
    end
    σy = [std(ymatrix[i,:]) for i in 1:ny]
    _normalize_std!(ΔyΔpNorm,σp,σy)
    return  ΔyΔpNorm, y, ymatrix, σy, σp
end


function ΔfΔp_normstd(f,p,δ,::MethodMultiRun;
    seednum,mruns,sampleAlg=SobolSample(),n=length(p)*length(p))

    ΔyΔpNorm, y, _, σy, σp = ΔfΔp_normstd(f,p,δ;seednum,sampleAlg,n)

    ny = length(y)
    yall = Array{Float64,2}(undef,ny,mruns)
    yall[:,1] = y

    # Multi-level multi-threading
    addlock = ReentrantLock()
    @threads for i in 2:mruns
        tmp, yall[:,i] = ΔfΔp(f,p,δ;seednum=seednum+i-1)
        _normalize_std!(tmp,σp,σy)
        @lock addlock ΔyΔpNorm += tmp
    end
    yavg = sum(yall,dims = 2) / mruns
    ΔyΔpNorm /= mruns

    return ΔyΔpNorm, yall, yavg, σy, σp
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
    yall::Matrix{Float64}      # trajectories of the outputs with deviated parameters
    ∂y∂p::Matrix{Float64}     # trajectories of approximated partial derivatives
    ∂y∂pNor::Matrix{Float64}  # normalized

    function OATResult(f,actpars,δ,::NoNormalization;kwargs...)
        pnom = nominal_values(actpars)
        ΔyΔp, ynom, yall  = ΔfΔp(f,pnom,δ;kwargs...)
        new(pnom,ynom,yall,ΔyΔp,zeros(1,1))
    end

    function OATResult(f, actpars, δ,::ValNormalization;kwargs...)
        oatres = OATResult(f,actpars,δ,NoNormalization();kwargs...)
        normalize!(oatres,ValNormalization())
        return oatres
    end
end # OATResult

function normalize!(oatres::OATResult,::ValNormalization)
    oatres.∂y∂pNor = _normalize(oatres.∂y∂p, oatres.ynom, oatres.pnom, ValNormalization())
    return nothing
end

solve(::OATProblem, f, actpars::Vector{ActiveParameter{Float64}}, ::SingleRun;
    δ, normAlg::NormalizationAlg = NoNormalization(), seednum) =
        OATResult(f, actpars, δ, normAlg; seednum)

# normalize!(::OATResult,::ValNormalization)
