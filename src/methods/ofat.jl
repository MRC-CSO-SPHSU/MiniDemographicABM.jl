"""
Implementation of OFAT method
"""

struct OFATProblem <: LSAProblem end

function _compute_ofat_p(actpars,pnom,n)
    pmat = Array{Float64,2}(undef,length(actpars),(n*length(actpars)))

    for i in 1:length(actpars)
        pmat[i,:] .= pnom[i]
        lb = actpars[i].lowerbound
        ub = actpars[i].upperbound
        for j in 1 + (i-1)*n : i*n
            pmat[i,j] = lb + ((j-1)%n) * ((ub - lb) / (n - 1))
        end
    end

    return pmat
end


function _compute_ofat_y(f, pmatrix, nruns, seednum)
    println("Evaluating OFAT with $(nruns) runs ...")
    println("Evaluation with seed # : $(seednum) ... ")
    seednum == 0 ? Random.seed!(floor(Int,time())) : Random.seed!(seednum)
    ysum = f(pmatrix)
    for _ in 2:nruns
        seednum += seednum == 0 ? 0 : 1
        seednum == 0 ? Random.seed!(floor(Int,time())) : Random.seed!(seednum)
        println("Evaluation with seed # : $(seednum) ... ")
        y = f(pmatrix)
        ysum += y
    end
    return ysum / nruns
end

"""
OFAT Result containts:
- pmatrix a design matrix of size: p x s
    where p is number of active parameters
    and s the number of steps
- y the simulation results of size: n x p x s
"""
struct OFATResult

    pmatrix::Matrix{Float64}
    pnom::Vector{Float64}
    y::Matrix{Float64}
    ynom::Vector{Float64}

    function OFATResult(f,actpars,n,nruns,seednum)
        pnom = nominal_values(actpars)
        pmatrix = _compute_ofat_p(actpars,pnom,n)
        ynom = f(pnom)
        y = _compute_ofat_y(f, pmatrix,nruns,seednum)
        new(pmatrix,pnom,y,ynom)
    end

end


"Visualize OFAT results"
function visualize(res::OFATResult,
    actpars::Vector{ActiveParameter{T}}, ylabels::Vector{String}) where T

    ny = length(res.ynom)
    np = length(res.pnom)
    n = Int(size(res.pmatrix)[2] / length(res.pnom))

    plts = Matrix{Any}(undef, np, ny)
    @assert np == length(actpars)
    plabels = [ string(ap.name) for ap in actpars ]

    plbs = [ap.lowerbound for ap in actpars]
    pubs = [ap.upperbound for ap in actpars]

    ylbs = fill(Inf,ny)
    yubs = fill(-1.0,ny)
    for i in 1:ny
        @inbounds ylbs[i] = min((@view res.y[i,:])...)
        @inbounds yubs[i] = max((@view res.y[i,:])...)
    end

    for yind in 1:ny
        for pind in 1:np
            plts[pind,yind] = plot()
            scatter!(plts[pind,yind] ,
                res.pmatrix[pind, (pind-1)*n+1:pind*n] ,
                res.y[yind,(pind-1)*n+1:pind*n],
                title = " $(plabels[pind]) vs. $(ylabels[yind]) ",
                label = "")
            xlims!(plts[pind,yind],plbs[pind],pubs[pind])
            ylims!(plts[pind,yind],ylbs[yind],yubs[yind])
        end
    end

    return plts
end

solve(pr::OFATProblem, f, actpars::Vector{ActiveParameter{Float64}};
    n=11, nruns, seednum, kwargs...) =
    OFATResult(f,actpars,n,nruns,seednum)
