neo4j_python_r
=============

Examples of using Neo4j with Python and R.

## Twitter Dataset

If you want to create your own Neo4j graph of Twitter data:

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

If you have auth enabled, set your username and password:

```
export NEO4J_USERNAME=neo4j
export NEO4J_PASSWORD=password
```

Then, collect tweets with keyword `keyword`:

```
python collect_keyword.py keyword
```