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
            if neighbor.status == green && rand(Uniform(1,100)) < model.probability_of_spread
                neighbor.status = burning
            end
        end
        tree.status = burnt
    end
end

#Density = Cantidad de agentes
function forest_fire(; density = 0.90, initialize = 5, griddims = (20, 20), probability_of_spread = 0)
    println("Received density: ", density)
    space = GridSpaceSingle(griddims; periodic = false, metric = :manhattan)
    forest = StandardABM(TreeAgent, space; agent_step! = forest_step, scheduler = Schedulers.Randomly(), properties = Dict(:probability_of_spread => probability_of_spread, :density => density, :initialize => initialize))
    for pos in positions(forest)
        if rand(Uniform(0,1)) < density
            tree = add_agent!(pos, forest)
            #Pos => Fila, == => Columna
            if pos[2] == initialize
                tree.status = burning
            end
        end
    end
    return forest
end
