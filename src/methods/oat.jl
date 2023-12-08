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
function ΔfΔp(f,p,δ::Float64,
        ::SingleRun=SingleRun(),::NoNormalization=NoNormalization();  #default
        seednum)

    myseed!(seednum)
    y = f(p)
    @assert typeof(y) == Vector{Float64} || typeof(y) == Float64
    ny = length(y)
    np = length(p)
    ΔyΔp = Array{Float64,2}(undef, ny, np)
    yall = Array{Float64,2}(undef, ny, np)
    @threads for i in 1:np
      myseed!(seednum)
      @inbounds yδ = f(p + p[i] * I[1:np,i] * δ)
      @inbounds ΔyΔp[:,i] = ( yδ - y ) / δ
      @inbounds yall[:,i] = yδ
    end
    return ΔyΔp, y, yall
end

function ΔfΔp(f,p,δ::Float64,
    ::MethodMultiRun,::NoNormalization=NoNormalization();  #default
    seednum, mruns)

    ΔyΔp , y, yall = ΔfΔp(f, p, δ; seednum)

    addlock = ReentrantLock()
    @threads for i in 2:mruns
        ΔtmpΔp , tmp, tmpall = ΔfΔp(f, p, δ; seednum = seednum * i)
        @lock addlock begin
            ΔyΔp += ΔtmpΔp
            y += tmp
            yall += tmpall
        end
    end
    ΔyΔp /= mruns
    y /= mruns
    yall /= mruns

    return ΔyΔp , y, yall
end

"value normalized parameter sensitivities"
function ΔfΔp(f,p,δ::Float64,::SingleRun,::ValNormalization; seednum)
    ΔyΔp , y, yall = ΔfΔp(f,p,δ;seednum)
    ΔyΔpNorm = copy(ΔyΔp)
    ny = length(y)
    @simd for i in 1:ny
        @inbounds ΔyΔpNorm[i,:] =  p .* ( ΔyΔpNorm[i,:] / y[i] )
    end
    return ΔyΔpNorm, y, ΔyΔp, yall
end

"value normalized parameter sensitivities with multiple runs"
function ΔfΔp(f,p,δ::Float64, ::MethodMultiRun, ::ValNormalization; seednum, mruns)
    # just a first implementation, subject to tuning due to repititive computations
    ΔyΔpNorm, y =  ΔfΔp(f,p,δ,SingleRun(),ValNormalization();seednum)
    ny = length(y)
    yall = Array{Float64,2}(undef,ny,mruns)
    yall[:,1] = y
    # Multi-level multi-threading improves performance by ~ 30%
    addlock = ReentrantLock()
    @threads for i in 2:mruns
        @inbounds tmp, yall[:,i] =
            ΔfΔp(f,p,δ,SingleRun(),ValNormalization();seednum = seednum * i)
        @lock addlock ΔyΔpNorm += tmp
    end
    yavg = sum(yall,dims = 2) / mruns
    ΔyΔpNorm /= mruns
    return ΔyΔpNorm, yall, yavg
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

    function OATResult(f,actpars,δ,rmode::RunMode,::NoNormalization;kwargs...)
        pnom = nominal_values(actpars)
        ΔyΔp, ynom, yall  = ΔfΔp(f,pnom,δ,rmode;kwargs...)
        new(pnom,ynom,yall,ΔyΔp,zeros(1,1))
    end
end # OATResult

solve(::OATProblem, f, actpars::Vector{ActiveParameter{Float64}}, ::SingleRun;
    δ, normAlg::NormalizationAlg = NoNormalization(), seednum) =
        OATResult(f, actpars, δ, SingleRun(), normAlg; seednum)

# normalize!(::OATResult,::ValNormalization)