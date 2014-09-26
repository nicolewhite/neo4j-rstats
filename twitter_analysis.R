### Twitter dataset.
library(RNeo4j)

# Connect to graph and explore.
graph = startGraph("http://localhost:2794/db/data/")
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
