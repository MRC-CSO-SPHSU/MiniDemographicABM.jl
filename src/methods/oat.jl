"""
Given an ABM model with a set of uncertain model parameters each associated with a
    uniform distribution (Subject to generalization to other sort of distributions),
    compute:
    - the time-dependent approximated derivative trajectories
    - the normalized time-dependent approximated derivatives trajectories
    about their nominal values
"""


struct OATProblem <: LSAProblem end

"approximation of parameter sensitivities for a vector- (single-valued) function"
function ΔfΔp(f,p,δ::Float64,::RunMode=SingleRun();seednum)
    seednum == 0 ? Random.seed!(floor(Int,time())) : Random.seed!(seednum)
    y = f(p)
    @assert typeof(y) == Vector{Float64} || typeof(y) == Float64
    ny = length(y)
    np = length(p)
    ΔyΔp = Array{Float64,2}(undef, ny, np)
    pδ = copy(p)
    for i in 1:np
      pδ[i] += p[i] * δ
      seednum == 0 ? Random.seed!(floor(Int,time())) : Random.seed!(seednum)
      yδ = f(pδ)
      ΔyΔp[:,i] = ( yδ - y ) / δ
      pδ[i] = p[i]
    end
    return ΔyΔp, y
end

ΔfΔp(f,p,δ::Float64,::MultipleRun;seednum) = notimplemented()

"normalized parameter sensitivities"
function ΔfΔp_normalized(f,p,δ::Float64,::RunMode=SingleRun(); seednum)
    ΔyΔpNorm , y = ΔfΔp(f,p,δ,seednum)
    for i in 1:length(y)
        ΔyΔpNorm[i,:] =  p .* ( ΔyΔpNorm[i,:] / y[i] )
    end
    return ΔyΔpNorm, y
end

"normalized parameter sensitivities with multiple runs"
function ΔfΔp_normalized(f,p,δ::Float64, ::MultipleRun; seednum, nruns)
    ΔyΔpNorm, y =  ΔfΔp_normalized(f,p,δ;seednum)
    ny = length(y)
    yall = Array{Float64,2}(undef,ny,nruns)
    yall[:,1] = y
    for i in 2:nruns
        tmp, yall[:,i] = ΔfΔp_normalized(f,p,δ;seednum = seednum+i-1)
        ΔyΔpNorm += tmp
    end
    yavg = sum(yall,dims = 2) / nruns
    ΔyΔpNorm /= nruns
    return ΔyΔpNorm, yall, yavg
end

# approximated normalized derivatives with standard diviation ...


function ΔftΔp(ft,p,δ) end

"""
OAT Result contains:
- pnom  : nominal parameter values
- ytnom : associated output trajectories of size nt x ny where
    nt: number of points
    ny: number of outputs

"""
struct OATResult
    pnom::Vector{Float64}       # nominal parameter values
    ytnom::Matrix{Float64}      # trajectories of the output
    ∂yt∂p::Array{Float64,3}     # trajectories of approximated partial derivatives
    ∂yt∂pNom::Array{Float64,3}  # normalized

    function OATResult(ft,actpars,δ)
        pnom = nominal_values(actpars)
        yt = ft(pnom)
        # ΔytΔp  = _compute_dytdp(ft,ytnon,pnom,δ)
        # ΔytΔpNom = _compute_dytdp(ft,ytnom,pnom)
        new(pnom,nothing,nothing,nothing)
    end
end