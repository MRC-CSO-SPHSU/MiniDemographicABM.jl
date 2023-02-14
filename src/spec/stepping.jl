age_step!(person,model) = person.age += model.dt

function population_age_step!(model)
    for person in allagents(model)
        age_step!(person,model)
    end
    nothing
end
