KEYWORD = Sys.getenv("KEYWORD")

library(igraph)

# Users are connected if they've tweeted the same hashtag.
# Edges are weighted by how many times the users have tweeted the same hashtag.
# Undirected.
query = "
MATCH (u1:User)-[:POSTS]->(:Tweet)<-[:TAGS]-(h:Hashtag)-[:TAGS]->(:Tweet)<-[:POSTS]-(u2:User)
WHERE h.name <> {keyword} AND (ID(u1) < ID(u2))
RETURN u1.username, u2.username, COUNT(*) AS weight
"

# Hashtags are connected if they've been tweeted together.
# Edged are weighted by how many times they've been tweeted together.
# Undirected.
query = "
MATCH (h1:Hashtag)-[:TAGS]->(:Tweet)<-[:TAGS]-(h2:Hashtag)
WHERE h1.name <> {keyword} AND (ID(h1) < ID(h2))
RETURN h1.name, h2.name, COUNT(*) AS weight
"

##################################################################################
data = cypher(graph, query, keyword=KEYWORD)
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