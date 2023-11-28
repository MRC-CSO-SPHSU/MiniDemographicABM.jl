#=
Simplified API for GlobalSensitivity.jl
=#

using GlobalSensitivity: MorrisResult, SobolResult

struct MorrisProblem <: GSAProblem end
struct SobolProblem <: GSAProblem end

_solve(prob::GSAProblem, f, lbs, ubs;kwargs...) = notimplemented(pr)

# Specialized for GlobalSensitivity.jl
function _solve(prob::GSAProblem, f, actpars::Vector{ActiveParameter{T}};kwargs...) where T

    lbs = [ ap.lowerbound for ap in actpars ]
    ubs = [ ap.upperbound for ap in actpars ]
    for i in 1:length(ubs)
        @assert lbs[i] < ubs[i]
    end

    return _solve(prob, f, lbs, ubs; kwargs...)
end

function solve(prob::GSAProblem, f, actpars::Vector{ActiveParameter{T}};
    kwargs...) where T    # method specific keyword arguments
    return _solve(prob,f,actpars;kwargs...)
end


#############################################
# Step VI.1 - API for GSA using Morris method
#############################################

function _solve(pr::MorrisProblem, f, lbs, ubs;
    batch = true,
    relative_scale = false,
    num_trajectory = 10,
    total_num_trajectory = 5 * num_trajectory,
    len_design_mat = 10,
    kwargs...)

    morrisInd = gsa(f,
        Morris(;relative_scale, num_trajectory, total_num_trajectory, len_design_mat),
        [ [lbs[i],ubs[i]] for i in 1:length(ubs) ];
        batch)
    return morrisInd
end


function visualize(morrind::MorrisResult)
    ny, np = size(morrind.means_star)
    plts = Vector{Any}(undef,ny)
    plabels = ["p"*string(i) for i in 1:np]
    for i in 1:ny
        plts[i] = plot()
        scatter!(plts[i], log.(morrind.means_star[i,:]), log.(morrind.variances[i,:]),
            series_annotations=plabels,
            label="y_$(i)(log(mean*) , log(sigma))")
    end
    return plts
end

########################################
# Step VI.2 - API for GSA using Sobol method
#########################################


function _solve(pr::SobolProblem, f, lbs, ubs;
    batch = true,
    samples = 10,
    order = [0,1],   # order = [0,1,2] computes the 2nd order indices
    conf_level = 0.95,
    kwargs...)

    sobolInd = gsa(f,
                    Sobol(;order, conf_level),
                    [ [lbs[i],ubs[i]] for i in 1:length(ubs) ];
                    batch, samples)
    return sobolInd
end

function visualize(sobolind::SobolResult, ylabels)
    ny, np = size(sobolind.S1)
    s1plts = Vector{Any}(undef,ny)
    stplts = Vector{Any}(undef,ny)
    plabels = ["p"*string(i) for i in 1:np]
    for i in 1:ny
        s1plts[i] = plot()
        bar!(s1plts[i],plabels, sobolind.S1[i,:],
            title = "First order indicies of $(ylabels[i])")
        stplts[i] = plot()
        bar!(stplts[i],plabels, sobolind.ST[i,:],
            title = "Total order indicies of $(ylabels[i])")
    end
    return s1plts, stplts
end

#=
another way to compute sobol indices

or

A = sample(100,ACTIVEPARS,SobolSample()) ;
B = sample(100,ACTIVEPARS,SobolSample()) ;

sobolInd = gsa(outputs, Sobol(), A, B)
=#
