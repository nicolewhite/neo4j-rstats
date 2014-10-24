graphs_r_cool
=============

Download a zip file of the Neo4j database [here](https://www.dropbox.com/s/csponqu0c1wsgf1/rstats_tweets.db.zip?dl=0).

Or, if you want to create your own Neo4j graph of Twitter data:

Get a [bearer token](https://dev.twitter.com/docs/auth/application-only-auth):

```
curl -XPOST -u customer_id:customer_secret 'https://api.twitter.com/oauth2/token?grant_type=client_credentials'
export TWITTER_BEARER=the twitter bearer returned from the previous line
```

Install py2neo:

```
pip install py2neo
# OR
easy_install py2neo
```

Start neo4j, taking note of which port you're running it on. If you're running at http://localhost:7474/db/data/, you can start populating the database with:

```
python collect_keyword.py 7474 rstats
```

The first argument, 7474, is which port you're running neo4j on and the second argument, rstats, is the keyword by which you want to search for tweets.

<a href="http://i.imgur.com/1wLGqs6.png" target="_blank"><img src="http://i.imgur.com/1wLGqs6.png" width="100%" height="100%"></a>
