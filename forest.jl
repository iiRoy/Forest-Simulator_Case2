using Agents, Random, Distributions

# green = 0, burning = 1, burnt = 0
@enum TreeStatus green burning burnt

@agent struct TreeAgent(GridAgent{2})
    status::TreeStatus = green
end

function forest_step(tree::TreeAgent, model)
    #Solo si se está "quemando", puede infectar otros agentes
    if tree.status == burning
        #Identifica árboles alrededor del agente
        for neighbor in nearby_agents(tree, model)
            if neighbor.status == green
                neighbor.status = burning
            end
        end
        tree.status = burnt
    end
end

#Density = Cantidad de agentes
function forest_fire(; density = 0.45, griddims = (20, 20))
    space = GridSpaceSingle(griddims; periodic = false, metric = :manhattan)
    forest = StandardABM(TreeAgent, space; agent_step! = forest_step, scheduler = Schedulers.Randomly())

    for pos in positions(forest)
        if rand(Uniform(0,1)) < density
            tree = add_agent!(pos, forest)
            #Pos => Fila, == => Columna
            if pos[2] == 5
                tree.status = burning
            end
        end
    end
    return forest
end
