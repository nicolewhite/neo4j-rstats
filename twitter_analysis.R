### Twitter dataset.

# Connect to graph and explore.
graph = startGraph("NEO4J_URL")
summary(graph)

getConstraint(graph)

user = getNodes(graph, "MATCH (u:User) RETURN u LIMIT 1")
tweet = getNodes(graph, "MATCH (t:Tweet) RETURN t LIMIT 1")

# Calculate correlation between # of hashtags and # of retweets.
query = "
MATCH (t:Tweet)
OPTIONAL MATCH (h:Hashtag)-[:TAGS]->(t)
OPTIONAL MATCH (ret:Tweet)-[:RETWEETS]->(t)
RETURN t.id, COUNT(DISTINCT h) AS hashtags, COUNT(DISTINCT ret) AS retweets
"

data = cypher(graph, query)

cor(data$hashtags, data$retweets)

# Build predictive model: RETWEETS = X0 + X1 * FOLLOWERS
query = "
MATCH (u:User)-[:POSTS]->(t:Tweet)
OPTIONAL MATCH (t2:Tweet)-[:RETWEETS]->(t)
WITH u, COUNT(t2) AS retweets
RETURN u.screen_name AS user, u.followers AS followers, retweets
"

data = cypher(graph, query)

model = lm(retweets ~ followers, data)

summary(model)

## Charts.
library(googleVis)

# Top 10 mentioned users.
query = "
MATCH (:Tweet)-[:MENTIONS]->(u:User)
RETURN u.screen_name AS User, COUNT(*) AS Mentions
ORDER BY Mentions DESC
LIMIT 10
"

top_users = cypher(graph, query)

plot(gvisColumnChart(top_users, options=list(height=500,width=500)))

# Hashtag co-occurrence.
query = "
MATCH (h:Hashtag)-[:TAGS]->(:Tweet)
WHERE h.name <> 'rstats'
WITH h, COUNT(*) AS Count
ORDER BY Count DESC
LIMIT 10

MATCH (h)-[:TAGS]->(t:Tweet)<-[:TAGS]-(h2:Hashtag)
WHERE (ID(h) < ID(h2))
RETURN h.name, h2.name, COUNT(*) AS count
"

hashtags = cypher(graph, query)

plot(gvisSankey(hashtags, from = "h.name", to = "h2.name", weight = "count", 
                options=list(height=500,width=500,sankey="{node:{label:{fontSize: 16}}}")))

## Word cloud.
library(wordcloud)
library(tm)
library(RColorBrewer)
library(stringr)

tweets = getNodes(graph, "MATCH (t:Tweet) WHERE HAS(t.text) RETURN t")
tweet_text = sapply(tweets, function(t) t$text)

# Remove links and convert to lowercase.
tweet_text = sapply(tweet_text, function(t) str_replace_all(t, perl("http.+?(?=(\\s|$))"), ""))
tweet_text = tolower(tweet_text)

# Remove stopwords, punctuation, etc.
tweet_corpus = Corpus(VectorSource(tweet_text))
tweet_corpus = tm_map(tweet_corpus, removePunctuation)
tweet_corpus = tm_map(tweet_corpus, function(x) removeWords(x, c(stopwords("english"), "rstats", "rt")))

# Get term-document matrix and then a term-frequency data frame.
tdm = TermDocumentMatrix(tweet_corpus)
m = as.matrix(tdm)
v = sort(rowSums(m),decreasing=TRUE)
d = data.frame(word = names(v),freq=v)

# Get color palette and create the word cloud.
pal = brewer.pal(9,"Dark2")

wordcloud(words = d$word, 
          freq = d$freq,
          min.freq = 5,
          scale = c(8,.3), 
          random.order = F,
          colors = pal)

### igraph
library(igraph)

# Graph algos.
query = "
MATCH (u1:User)-[:POSTS]->(:Tweet)<-[:TAGS]-(h:Hashtag)-[:TAGS]->(:Tweet)<-[:POSTS]-(u2:User)
WHERE h.name <> 'rstats' AND (ID(u1) < ID(u2))
RETURN u1.screen_name, u2.screen_name, COUNT(*) AS weight
"

users = cypher(graph, query)

g = graph.data.frame(users, directed = F)

# Remove text labels and plot.
V(g)$label = NA
V(g)$size = 4
V(g)$color = "cyan"
plot(g)

# Make size of node a function of its betweenness.
V(g)$size = betweenness(g) / 100
plot(g)

# Clustering.
cluster = edge.betweenness.community(g, directed = F)$membership

colors = rainbow(max(cluster))

V(g)$color = colors[cluster]
V(g)$size = 4
plot(g)

# Linear algebra things.
lap = as.matrix(graph.laplacian(g))
lap[1:5, 1:5]
eigens = eigen(lap)$values