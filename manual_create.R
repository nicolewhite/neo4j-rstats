### Prototyping data models.
library(RNeo4j)

# Connect to the graph.
graph = startGraph("http://localhost:2259/db/data/")

# Delete everything.
clear(graph)

# Add uniqueness constraint.
addConstraint(graph, "Person", "name")

# Create people.
nicole = createNode(graph, "Person", name = "Nicole", male = F)
kenny = createNode(graph, "Person", name = "Kenny", male = T)
greta = createNode(graph, "Person", name = "Greta", male = F)
hank = createNode(graph, "Person", name = "Hank", male = T)

# Add more uniqueness constraints.
addConstraint(graph, "BoardGame", "name")
addConstraint(graph, "ComputerGame", "name")

# Create games.
risk = createNode(graph, "BoardGame", name = "RISK", max_players = c(5,6))
settlers = createNode(graph, "BoardGame", name = "Settlers of Catan", max_players = 4)

lol = createNode(graph, "ComputerGame", name = "League of Legends", max_players = 10)
sc = createNode(graph, "ComputerGame", name = "Starcraft", max_players = 8)

# Create relationships.
rel = createRel(greta, "PLAYS", risk, color = "Red")

rels_h = lapply(list(risk, lol), function(g) createRel(hank, "PLAYS", g))
rels_k = lapply(list(risk, lol, sc), function(g) createRel(kenny, "PLAYS", g))

all_games = getNodes(graph, "MATCH n WHERE n:BoardGame OR n:ComputerGame RETURN n")
rels_n = lapply(all_games, function(g) createRel(nicole, "PLAYS", g))

# Open the browser.
browse(graph)