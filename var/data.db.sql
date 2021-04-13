BEGIN TRANSACTION;

# List of discrete timesteps counting from 0 upwards
DROP TABLE IF EXISTS "timestep";
CREATE TABLE IF NOT EXISTS "timestep" (
	"time"	INTEGER NOT NULL UNIQUE, # timestep number
	PRIMARY KEY("time" AUTOINCREMENT)
);

# A message is a package to be send from a sender to a receiver
DROP TABLE IF EXISTS "message";
CREATE TABLE IF NOT EXISTS "message" (
	"uuid"	TEXT NOT NULL UNIQUE, # message id
	"created_at"	INTEGER NOT NULL, # timestep the message was created
	"sender"	TEXT NOT NULL, # sender address
	"receiver"	TEXT NOT NULL, # receiver address
	PRIMARY KEY("uuid"),
	FOREIGN KEY("created_at") REFERENCES "timestep"("time") ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY("sender") REFERENCES "node"("uuid"),
	FOREIGN KEY("receiver") REFERENCES "node"("uuid")
);

# a directed connection between two nodes of which a message can be routed
DROP TABLE IF EXISTS "edge";
CREATE TABLE IF NOT EXISTS "edge" (
	"uuid"	TEXT NOT NULL UNIQUE, # id of the edge
	"source"	TEXT NOT NULL, # source node id
	"target"	TEXT NOT NULL, # target node id
	"delay"	INTEGER NOT NULL DEFAULT 1, # delay in number of timesteps a messages takes to travel this edge
	CHECK("source" <> "target"), # no reflexive edges!
	PRIMARY KEY("uuid"),
	FOREIGN KEY("target") REFERENCES "node"("uuid") ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY("source") REFERENCES "node"("uuid") ON DELETE CASCADE ON UPDATE CASCADE,
	UNIQUE("source","target") # only one edge between two nodes
);

# a node can send an receive messages
DROP TABLE IF EXISTS "node";
CREATE TABLE IF NOT EXISTS "node" (
	"uuid"	TEXT NOT NULL UNIQUE, # id of the node
	"capacity"	INTEGER NOT NULL DEFAULT 1, # number of messages the node can process per timestep
	PRIMARY KEY("uuid")
);

# a signal represents the transmission of a message along an edge over one or more timesteps
DROP TABLE IF EXISTS "signal";
CREATE TABLE IF NOT EXISTS "signal" (
	"uuid"	TEXT NOT NULL UNIQUE, # signal id
	"message"	TEXT NOT NULL, # message id
	"edge"	TEXT NOT NULL, # id of the edge the signal travels along
	"transmitted_at"	INTEGER NOT NULL, # timestep at which the signal is send. (it can be received as soon as transmitted_at + edge.delay)
	PRIMARY KEY("uuid"),
	FOREIGN KEY("message") REFERENCES "message"("uuid") ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY("edge") REFERENCES "edge"("uuid") ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY("transmitted_at") REFERENCES "timestep"("time") ON UPDATE CASCADE ON DELETE CASCADE,
	UNIQUE("edge","transmitted_at") # maybe remove this? only allow one signal per timestep per edge?
);

# An acknowledgement is the reponse to a signal
DROP TABLE IF EXISTS "acknowledgment";
CREATE TABLE IF NOT EXISTS "acknowledgment" (
	"uuid"	TEXT NOT NULL UNIQUE, # id of the acknowledgement
	"signal"	TEXT NOT NULL UNIQUE, # id of the signal to be acknowledged
	"acked_at"	INTEGER NOT NULL, # timestep at which the acknowledgment is triggered
	"state"	INTEGER NOT NULL, # state of the acknowledgment (1=ok,2=cyclic,3=deadend)
	# ok if the message has reached the receiver, 
	# cyclic if the signal reached a node that already received the message via an earlier signal
	# deadend if the signal reached a node that could not transmit it any further
	PRIMARY KEY("uuid"),
	FOREIGN KEY("acked_at") REFERENCES "timestep"("time") ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY("signal") REFERENCES "signal"("uuid") ON UPDATE CASCADE ON DELETE CASCADE
);

# available_dispatch are messages that have been created but not send yet
DROP VIEW IF EXISTS "available_dispatch";
CREATE VIEW available_dispatch AS 
SELECT message.created_at AS created_at,
message.uuid AS uuid, 
message.sender AS sender, 
message.receiver AS receiver, 
edge.uuid AS edge,
edge.uuid IS NULL AS trapped,
message.created_at AS createdAt,
sender.capacity AS max_load,
node_workload.current_load AS current_load,
current_timestep.time AS timeStep
FROM message 
INNER JOIN (SELECT MAX(time) AS time FROM timestep) current_timestep
INNER JOIN node sender ON sender.uuid = message.sender LEFT JOIN signal ON signal.message = message.uuid LEFT JOIN edge ON edge.source = message.sender
LEFT JOIN edge outgoing_edge ON outgoing_edge.source = message.sender
LEFT JOIN node_workload ON (node_workload.uuid, node_workload.time) = (sender.uuid, current_timestep.time)
 WHERE signal.uuid IS NULL GROUP BY message.uuid, edge.uuid ORDER BY trapped ASC;

# node_pair_time are all possible pairs of nodes and the current time step
DROP VIEW IF EXISTS "node_pair_time";
CREATE VIEW node_pair_time AS SELECT MAX(time) AS time, sender.uuid AS sender, receiver.uuid AS receiver FROM timestep INNER JOIN node sender INNER JOIN node receiver WHERE sender.uuid <> receiver.uuid GROUP BY sender.uuid, receiver.uuid ORDER BY RANDOM();

# edges and their respective reverse (if available)
DROP VIEW IF EXISTS "reverse_edge";
CREATE VIEW reverse_edge AS
SELECT 
edge.uuid AS uuid, 
reverse.uuid AS reverse_uuid, 
edge.source AS source, 
edge.target AS target, 
edge.delay AS delay, 
reverse.delay AS reverse_delay
FROM edge 
LEFT JOIN edge reverse
ON (edge.target, edge.source) = (reverse.source, reverse.target);

# the load and capacity of each node at each timestep, calculated by summing the amount of
# signals processed per timestep
DROP VIEW IF EXISTS "node_workload";
CREATE VIEW node_workload AS
SELECT timestep.time, 
node.uuid, 
node.capacity AS max_load, 
COUNT(DISTINCT signal.uuid) + COUNT(DISTINCT acknowledgment.uuid) as current_load, 
COUNT(DISTINCT signal.uuid) AS current_load_signal, 
COUNT(DISTINCT acknowledgment.uuid) AS current_load_ack
FROM node 
INNER JOIN timestep 
LEFT JOIN edge out_edge ON out_edge.source = node.uuid
LEFT JOIN edge in_edge ON in_edge.target = node.uuid
LEFT JOIN signal ON (signal.edge, signal.transmitted_at) = (out_edge.uuid, timestep.time)
LEFT JOIN signal ack_signal ON ack_signal.edge = in_edge.uuid
LEFT JOIN acknowledgment ON (acknowledgment.signal, acknowledgment.acked_at) = (ack_signal.uuid,  timestep.time)
GROUP BY node.uuid, timestep.time
ORDER BY timestep.time, node.uuid;

# signals that have not been ackowledged yet but might be
DROP VIEW IF EXISTS "available_response";
CREATE VIEW available_response AS 
SELECT *, 
CASE WHEN deadend OR cycle_detected OR goal THEN self_ready_at ELSE outgoing_ready_at END AS ready_at,
CASE WHEN goal THEN 1 WHEN cycle_detected THEN 2 WHEN deadend THEN 3 ELSE outgoing_state END AS state
FROM (
SELECT 
message.uuid AS message,
current_node.uuid AS node,
incoming_signal.uuid AS signal,
node_workload.current_load AS current_load,
node_workload.max_load AS max_load,
current_node.uuid = message.receiver AS goal,
outgoing_ack.acked_at + outgoing_edge.delay AS outgoing_ready_at,
incoming_signal.transmitted_at AS transmitted_at,
incoming_signal.transmitted_at + incoming_edge.delay AS self_ready_at,
SUM(COALESCE(incoming_signal.transmitted_at >= outgoing_signal.transmitted_at, 0)) AS cycle_detected,
COUNT(DISTINCT outgoing_edge.uuid) < 1 AS deadend,
MIN(outgoing_ack.state) AS outgoing_state,
current_timestep.time AS time
FROM message 
INNER JOIN (SELECT MAX(time) AS time FROM timestep) current_timestep
INNER JOIN signal incoming_signal ON incoming_signal.message = message.uuid 
LEFT JOIN acknowledgment incoming_ack ON incoming_ack.signal = incoming_signal.uuid 
INNER JOIN edge incoming_edge ON incoming_edge.uuid = incoming_signal.edge 
INNER JOIN node current_node ON incoming_edge.target = current_node.uuid
LEFT JOIN node_workload ON (node_workload.uuid, node_workload.time) = (current_node.uuid, current_timestep.time)
LEFT JOIN edge outgoing_edge ON outgoing_edge.source = current_node.uuid AND current_node.uuid IS NOT message.receiver AND outgoing_edge.target IS NOT incoming_edge.source
LEFT JOIN signal outgoing_signal ON (outgoing_signal.message, outgoing_signal.edge) = (incoming_signal.message, outgoing_edge.uuid) 
LEFT JOIN acknowledgment outgoing_ack ON outgoing_ack.signal = outgoing_signal.uuid
WHERE incoming_ack.uuid IS NULL
GROUP BY message.uuid, incoming_signal.uuid
) i;

# signals that can be further redirected to the next node
DROP VIEW IF EXISTS "available_redirect";
CREATE VIEW available_redirect AS
SELECT 
incoming_signal.uuid AS signal,
message.uuid AS message,
current_node.uuid AS node,
incoming_edge.uuid AS incoming_edge,
outgoing_edge.uuid AS outgoing_edge,
incoming_signal.transmitted_at AS transmitted_at,
incoming_edge.delay AS delay,
incoming_signal.transmitted_at + incoming_edge.delay AS ready_at,
incoming_signal.transmitted_at + incoming_edge.delay <= current_timestep.time AS ready,
node_workload.current_load AS current_load,
node_workload.max_load AS max_load,
COUNT(outgoing_edge.uuid) < 1 AS trapped,
COUNT (DISTINCT outgoing_signal.uuid),
current_timestep.time AS time
FROM message 
INNER JOIN (SELECT MAX(time) AS time FROM timestep) current_timestep
INNER JOIN signal incoming_signal ON incoming_signal.message = message.uuid 
INNER JOIN edge incoming_edge ON incoming_edge.uuid = incoming_signal.edge 
INNER JOIN node current_node ON incoming_edge.target = current_node.uuid
LEFT JOIN node_workload ON (node_workload.uuid, node_workload.time) = (current_node.uuid, current_timestep.time)
LEFT JOIN edge outgoing_edge ON outgoing_edge.source = current_node.uuid 
LEFT JOIN signal outgoing_signal ON (outgoing_signal.message, outgoing_signal.edge) = (incoming_signal.message, outgoing_edge.uuid) 
LEFT JOIN acknowledgment outgoing_ack ON outgoing_ack.signal = outgoing_signal.uuid
LEFT JOIN edge old_outgoing_edge ON old_outgoing_edge.source = current_node.uuid 
LEFT JOIN signal old_outgoing_signal ON (old_outgoing_signal.message, old_outgoing_signal.edge) = (incoming_signal.message, old_outgoing_edge.uuid) 
LEFT JOIN acknowledgment old_outgoing_ack ON old_outgoing_ack.signal = old_outgoing_signal.uuid
WHERE message.receiver <> current_node.uuid AND (outgoing_signal.uuid IS NULL) AND (old_outgoing_ack.state IS NOT 3 AND old_outgoing_ack.state IS NOT 2)
GROUP BY message.uuid, current_node.uuid, outgoing_edge.uuid
HAVING COUNT (DISTINCT old_outgoing_signal.uuid) < 1
ORDER BY current_node.uuid, message.uuid, trapped ASC;
COMMIT;
