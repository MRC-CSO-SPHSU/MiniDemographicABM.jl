#=
Simplified API for GlobalSensitivity.jl
=#

struct MorrisProblem <: GSAProblem end
struct SobolProblem <: GSAProblem end

_solve(prob::GSAProblem, f, lbs, ubs;kwargs...) = notimplemented(pr)

# Specialized for GlobalSensitivity.jl
function _solve(prob::GSAProblem, f, actpars::Vector{ActiveParameter{Float64}};kwargs...)

    lbs = [ ap.lowerbound for ap in actpars ]
    ubs = [ ap.upperbound for ap in actpars ]
    for i in 1:length(ubs)
        @assert lbs[i] < ubs[i]
    end

    return _solve(prob, f, lbs, ubs; kwargs...)
end

function solve(prob::GSAProblem, f, actpars::Vector{ActiveParameter{Float64}};
    kwargs...)     # method specific keyword arguments
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

    @time morrisInd = gsa(f,
        Morris(;relative_scale, num_trajectory, total_num_trajectory, len_design_mat),
        [ [lbs[i],ubs[i]] for i in 1:length(ubs) ];
        batch)
    return morrisInd
end


########################################
# Step VI.2 - API for GSA using Sobol method
#########################################


function _solve(pr::SobolProblem, f, lbs, ubs;
    batch = true,
    samples = 10,
    kwargs...)

    sobolInd = gsa(f, Sobol(), [ [lbs[i],ubs[i]] for i in 1:length(ubs) ]; batch, samples)
    return sobolInd
end

#=
To compute sobol indices, this can be done as follows:

either
sobolInd = gsa(outputs, Sobol(), [ [lbs[i],ubs[i]] for i in 1:length(ubs) ], samples = 100)

or

A = sample(100,ACTIVEPARS,SobolSample()) ;
B = sample(100,ACTIVEPARS,SobolSample()) ;

sobolInd = gsa(outputs, Sobol(), A, B)

=#
