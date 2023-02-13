"convert date in rational representation to (years, months) as tuple"
function date2yearsmonths(date::Rational{Int})
    date < 0 ? throw(ArgumentError("Negative age")) : nothing
    12 % denominator(date) != 0 ? throw(ArgumentError("$(date) not in date/age format")) : nothing
    years  = trunc(Int, numerator(date) / denominator(date))
    months = trunc(Int, numerator(date) % denominator(date) * 12 / denominator(date) )
    return (years , months)
end

notimplemented(msg = "") = error("not implemeented" * msg)
notneeded(msg = "") = error("not needed" * msg)

invalid_id() = 0
has_invalid_id(agent::AbstractAgent) = agent.id == invalid_id()

function show_number_of_kids_per_man_distribution(model)
    population = allagents(model)
    marriedMen = [man for man in pop2 if !issingle(man) && ismale(man)]
    numOfKidsDist = [ length(children(man)) for man in marriedMen ]
    histogram(numOfKidsDist,bins=0:15)
end

function show_age_distribution(model)
    population = allagents(model)
    agedist = [ person.age for person in pop2 ]
    histogram(agedist)
end
