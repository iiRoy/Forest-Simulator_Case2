using Agents, Random, Distributions

# green = 0, burning = 1, burnt = 0
@enum TreeStatus green burning burnt

@agent struct TreeAgent(GridAgent{2})
    status::TreeStatus = green
end

function forest_step(tree::TreeAgent, model)
    #Solo si se está "quemando", puede quemar otros agentes
    if tree.status == burning
        #Identifica árboles alrededor del agente
        for neighbor in nearby_agents(tree, model)
            if neighbor.status == green 
                spread_adjustment = 0
                
                # Dirección del vecino
                dx = neighbor.pos[1] - tree.pos[1]
                dy = neighbor.pos[2] - tree.pos[2]
                if dy < 0  # Norte
                    spread_adjustment += model.south_wind_speed
                elseif dy > 0  # Sur
                    spread_adjustment += -model.south_wind_speed
                end
                if dx < 0  # Este
                    spread_adjustment += model.west_wind_speed
                elseif dx > 0  # Oeste
                    spread_adjustment += -model.west_wind_speed
                end
                # Asegurar que la probabilidad sea de 0% - 100%
                adjusted_spread_prob = model.probability_of_spread + spread_adjustment*1.5
                if rand(Uniform(1,100)) < adjusted_spread_prob
                    neighbor.status = burning
                neighbor.status = burning
                end
            end
        end
        tree.status = burnt
    end
end

#Density = Cantidad de agentes
function forest_fire(; density = 0.90, initialize = 5, griddims = (20, 20), probability_of_spread = 0, south_wind_speed = 0, west_wind_speed = 0)
    println("Received density: ", density)
    space = GridSpaceSingle(griddims; periodic = false, metric = :manhattan)
    forest = StandardABM(TreeAgent, space; agent_step! = forest_step, scheduler = Schedulers.Randomly(), properties = Dict(:probability_of_spread => probability_of_spread, :density => density, :south_wind_speed => south_wind_speed, :west_wind_speed => west_wind_speed))
    for pos in positions(forest)
        if rand(Uniform(0,1)) < density
            tree = add_agent!(pos, forest)
            #Pos => Fila, == => Columna
            if pos[1] == 20
                tree.status = burning
            end
        end
    end
    return forest
end
