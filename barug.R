library(igraph)
library(RNeo4j)

graph = startGraph("http://localhost:2794/db/data/")

# Users are connected if they've tweeted the same hashtag.
# Edges are weighted by how many times the users have tweeted the same hashtag.
# Undirected.
query = "
MATCH (u1:User)-[:POSTS]->(:Tweet)<-[:TAGS]-(h:Hashtag)-[:TAGS]->(:Tweet)<-[:POSTS]-(u2:User)
WHERE h.name <> 'rstats' AND (ID(u1) < ID(u2))
RETURN u1.screen_name, u2.screen_name, COUNT(*) AS weight
"

# Hashtags are connected if they've been tweeted together.
# Edged are weighted by how many times they've been tweeted together.
# Undirected.
query = "
MATCH (h1:Hashtag)-[:TAGS]->(:Tweet)<-[:TAGS]-(h2:Hashtag)
WHERE h1.name <> 'rstats' AND h2.name <> 'rstats' AND (ID(h1) < ID(h2))
RETURN h1.name, h2.name, COUNT(*) AS weight
"

##################################################################################
data = cypher(graph, query)

g = graph.data.frame(data, directed = F)

# Remove text labels and plot.
V(g)$label = NA
V(g)$size = 4
V(g)$color = "cyan"
plot(g)

# Top 5 betweenness.
sort(betweenness(g), decreasing = T)[1:5]

# Make size of node a function of its betweenness.
V(g)$size = betweenness(g) / (max(betweenness(g)) * .1)
plot(g)

# Clustering.
cluster = edge.betweenness.community(g)$membership

colors = rainbow(max(cluster))
colors = colors[sample(length(colors))]

V(g)$color = colors[cluster]
V(g)$size = 4
plot(g)