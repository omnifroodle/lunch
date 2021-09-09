create KEYSPACE lunch WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
create table lunch.lunchers ( location text, name text, time timestamp, thumbnail text, primary key(location, time, name) );


