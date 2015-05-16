library(RNeo4j)

neo4j = startGraph("http://localhost:7474/db/data/")

clear(graph)

addConstraint(graph, "Person", "name")

alice = createNode(neo4j, "Person", name = "Alice")
bob = createNode(neo4j, "Person", name = "Bob")
charles = createNode(neo4j, "Person", name = "Charles")
david = createNode(neo4j, "Person", name = "David")
elaine = createNode(neo4j, "Person", name = "Elaine")

r1 = createRel(alice, "KNOWS", bob, weight = 0.5)
r2 = createRel(bob, "KNOWS", charles, weight = 0.5)
r3 = createRel(bob, "KNOWS", david, weight = 1.5)
r4 = createRel(charles, "KNOWS", david, weight = 0.5)
r5 = createRel(alice, "KNOWS", elaine, weight = 2)
r6 = createRel(elaine, "KNOWS", david, weight = 0.5)

browse(graph)

p = shortestPath(alice, "KNOWS", david, max_depth = 4)
p = dijkstra(alice, "KNOWS", david, cost_property="weight")
