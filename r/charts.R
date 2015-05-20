KEYWORD = Sys.getenv("KEYWORD")

### Twitter dataset.
library(RNeo4j)

# Connect to graph and explore.
graph = startGraph("http://localhost:7474/db/data/")
summary(graph)

# Calculate correlation between # of hashtags and # of retweets.
query = "
MATCH (t:Tweet)
OPTIONAL MATCH (h:Hashtag)-[:TAGS]->(t)
OPTIONAL MATCH (ret:Tweet)-[:RETWEETS]->(t)
RETURN t.id, COUNT(DISTINCT h) AS hashtags, COUNT(DISTINCT ret) AS retweets
"

data = cypher(graph, query)

cor(data$hashtags, data$retweets)

## Charts.
library(googleVis)

# Top 10 mentioned users.
query = "
MATCH (:Tweet)-[:MENTIONS]->(u:User)
RETURN u.username AS User, COUNT(*) AS Mentions
ORDER BY Mentions DESC
LIMIT 10
"

top_users = cypher(graph, query)

plot(gvisColumnChart(top_users, options=list(height=500,width=500)))

# Hashtag co-occurrence.
query = "
MATCH (h:Hashtag)-[:TAGS]->(:Tweet)
WHERE h.name <> {keyword}
WITH h, COUNT(*) AS Count
ORDER BY Count DESC
LIMIT 50

WITH COLLECT(h) AS hashtags
UNWIND hashtags AS h1
UNWIND hashtags AS h2

MATCH (h1)-[:TAGS]->(t:Tweet)<-[:TAGS]-(h2)
WHERE (ID(h1) < ID(h2))
RETURN h1.name, h2.name, COUNT(*) AS count
"

hashtags = cypher(graph, query, keyword=KEYWORD)

plot(gvisSankey(hashtags, from = "h1.name", to = "h2.name", weight = "count", 
                options=list(height=500,width=500,sankey="{node:{label:{fontSize: 16}}}")))

sankeyForHashtag = function(hashtag) {
  query = "
  MATCH (h1:Hashtag {name:{hashtag}})-[:TAGS]->(:Tweet)<-[:TAGS]-(h2:Hashtag)
  RETURN h1.name, h2.name, COUNT(*) AS count
  ORDER BY count DESC LIMIT 10
  "
  
  hashtags = cypher(graph, query, hashtag=hashtag)
  
  plot(gvisSankey(hashtags, from = "h1.name", to = "h2.name", weight = "count", 
                  options=list(height=500,width=500,sankey="{node:{label:{fontSize: 16}}}")))
}

sankeyForHashtag('arlanda')
sankeyForHashtag('avengers')
sankeyForHashtag('redbull')

## Word cloud.
library(wordcloud)
library(tm)
library(RColorBrewer)
library(stringr)

tweets = getNodes(graph, "MATCH (t:Tweet) WHERE HAS(t.text) AND NOT (t)-[:RETWEETS]->() RETURN t")
tweet_text = sapply(tweets, function(t) t$text)
tweet_text <- iconv(tweet_text, to="utf-8-mac", sub="")
tweet_text = sapply(tweet_text, tolower)

tweet_text = sapply(tweet_text, function(t) str_replace_all(t, perl("http.+?(?=(\\s|$))"), ""))
tweet_text = sapply(tweet_text, function(t) str_replace_all(t, KEYWORD, ""))
tweet_text = sapply(tweet_text, function(t) str_replace_all(t, "rt", ""))
tweet_text <- (tweet_text[!is.na(tweet_text)])

tweet_corpus = Corpus(VectorSource(tweet_text))
tweet_corpus = tm_map(tweet_corpus, removePunctuation)
tweet_corpus = tm_map(tweet_corpus, function(x) removeWords(x, c(stopwords("english"))))

tdm = TermDocumentMatrix(tweet_corpus)
m = as.matrix(tdm)
v = sort(rowSums(m),decreasing=TRUE)
d = data.frame(word = names(v),freq=v)

pal = brewer.pal(7,"Dark2")

wordcloud(words = d$word, 
          freq = d$freq,
          min.freq = 3,
          scale = c(8,.3), 
          random.order = F,
          colors = pal)
