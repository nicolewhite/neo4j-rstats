KEYWORD = Sys.getenv("KEYWORD")

library(d3Network)

plotSimpleCypher = function(data) {
  dir <- tempfile()
  dir.create(dir)
  htmlFile <- file.path(dir, "index.html")
  
  sink(file=htmlFile)
  d3SimpleNetwork(data, opacity=1, fontsize=10)
  sink()
  
  rstudio::viewer(htmlFile)
}

query = "
MATCH (h1:Hashtag)-[:TAGS]->(:Tweet)<-[:TAGS]-(h2:Hashtag)
WHERE h1.name <> {keyword} AND (ID(h1) < ID(h2))
RETURN h1.name AS source, h2.name AS target, COUNT(*) AS weight
"

data = cypher(graph, query, keyword=KEYWORD)

plotSimpleCypher(data)

query = "
MATCH (u1:User)-[:POSTS]->(:Tweet)<-[:TAGS]-(h:Hashtag)-[:TAGS]->(:Tweet)<-[:POSTS]-(u2:User)
WHERE (ID(u1) < ID(u2))
RETURN u1.username AS source, u2.username AS target, COUNT(*) AS weight
"

data = cypher(graph, query)

plotSimpleCypher(data)