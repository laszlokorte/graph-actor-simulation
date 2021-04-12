BEGIN TRANSACTION;
DROP TABLE IF EXISTS "timestep";
CREATE TABLE IF NOT EXISTS "timestep" (
	"time"	INTEGER NOT NULL UNIQUE,
	PRIMARY KEY("time" AUTOINCREMENT)
);
DROP TABLE IF EXISTS "message";
CREATE TABLE IF NOT EXISTS "message" (
	"uuid"	TEXT NOT NULL UNIQUE,
	"created_at"	INTEGER NOT NULL,
	"sender"	TEXT NOT NULL,
	"receiver"	TEXT NOT NULL,
	FOREIGN KEY("receiver") REFERENCES "node"("uuid"),
	FOREIGN KEY("sender") REFERENCES "node"("uuid"),
	FOREIGN KEY("created_at") REFERENCES "timestep"("time") ON DELETE CASCADE ON UPDATE CASCADE,
	PRIMARY KEY("uuid")
);
DROP TABLE IF EXISTS "edge";
CREATE TABLE IF NOT EXISTS "edge" (
	"uuid"	TEXT NOT NULL UNIQUE,
	"source"	TEXT NOT NULL,
	"target"	TEXT NOT NULL,
	"delay"	INTEGER NOT NULL DEFAULT 1,
	FOREIGN KEY("source") REFERENCES "node"("uuid") ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY("target") REFERENCES "node"("uuid") ON DELETE CASCADE ON UPDATE CASCADE,
	PRIMARY KEY("uuid"),
	UNIQUE("source","target"),
	CHECK("source" <> "target")
);
DROP TABLE IF EXISTS "node";
CREATE TABLE IF NOT EXISTS "node" (
	"uuid"	TEXT NOT NULL UNIQUE,
	"capacity"	INTEGER NOT NULL DEFAULT 1,
	PRIMARY KEY("uuid")
);
DROP TABLE IF EXISTS "signal";
CREATE TABLE IF NOT EXISTS "signal" (
	"uuid"	TEXT NOT NULL UNIQUE,
	"message"	TEXT NOT NULL,
	"edge"	TEXT NOT NULL,
	"transmitted_at"	INTEGER NOT NULL,
	FOREIGN KEY("message") REFERENCES "message"("uuid") ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY("edge") REFERENCES "edge"("uuid") ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY("transmitted_at") REFERENCES "timestep"("time") ON UPDATE CASCADE ON DELETE CASCADE,
	PRIMARY KEY("uuid"),
	UNIQUE("edge","transmitted_at")
);
DROP TABLE IF EXISTS "acknowledgment";
CREATE TABLE IF NOT EXISTS "acknowledgment" (
	"uuid"	TEXT NOT NULL UNIQUE,
	"signal"	TEXT NOT NULL UNIQUE,
	"acked_at"	INTEGER NOT NULL,
	FOREIGN KEY("acked_at") REFERENCES "timestep"("time") ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY("signal") REFERENCES "signal"("uuid") ON UPDATE CASCADE ON DELETE CASCADE,
	PRIMARY KEY("uuid")
);
DROP VIEW IF EXISTS "pending_message";
CREATE VIEW pending_message AS 
SELECT message.created_at AS createdAt,
message.uuid AS uuid, 
message.sender AS sender, 
message.receiver AS receiver, 
edge.uuid AS edge,
edge.uuid IS NULL AS trapped,
hex(message.uuid) AS uuid_hex,
MAX(hex(edge.uuid)) AS edge_hex,
message.created_at AS createdAt,
sender.capacity AS senderMaxCapacity,
node_workload.total_occupation AS senderUsedCapacity,
node_workload.capacity > node_workload.total_occupation AS inCapacity,
current_timestep.time AS timeStep
FROM message 
INNER JOIN (SELECT MAX(time) AS time FROM timestep) current_timestep
INNER JOIN node sender ON sender.uuid = message.sender LEFT JOIN signal ON signal.message = message.uuid LEFT JOIN edge ON edge.source = message.sender
LEFT JOIN edge outgoing_edge ON outgoing_edge.source = message.sender
LEFT JOIN node_workload ON (node_workload.uuid, node_workload.time) = (sender.uuid, current_timestep.time)
 WHERE signal.uuid IS NULL GROUP BY message.uuid, edge.uuid ORDER BY trapped ASC;
DROP VIEW IF EXISTS "transit_message";
CREATE VIEW transit_message AS 
SELECT message.uuid AS uuid,
edge.source AS source, 
edge.target AS target, 
signal.uuid AS signal, 
signal.transmitted_at AS transmittedAt, 
edge.delay AS delay, signal.transmitted_at + edge.delay AS readyAt, 
next_edge.uuid AS nextEdge,
next_edge.uuid IS NULL AS trapped,
target.capacity AS targetMaxCapacity,
node_workload.total_occupation AS targetUsedCapacity,
node_workload.capacity > node_workload.total_occupation inCapacity,
signal.transmitted_at + edge.delay <= current_timestep.time AS ready,
current_timestep.time AS timestep
FROM message 
INNER JOIN (SELECT MAX(time) AS time FROM timestep) current_timestep
INNER JOIN signal ON signal.message = message.uuid INNER JOIN edge ON edge.uuid = signal.edge 
INNER JOIN node target ON edge.target = target.uuid
LEFT JOIN edge next_edge ON next_edge.source = edge.target 
LEFT JOIN signal next_signal ON (next_signal.message, next_signal.edge) = (signal.message, next_edge.uuid) 
LEFT JOIN edge out_edge ON out_edge.source = edge.target 
LEFT JOIN signal out_signal ON (out_signal.message, out_signal.edge) = (signal.message, out_edge.uuid) 
LEFT JOIN node_workload ON (node_workload.uuid, node_workload.time) = (edge.target , current_timestep.time)
LEFT JOIN acknowledgment ON acknowledgment.signal = signal.uuid
WHERE acknowledgment.uuid IS NULL AND message.receiver != edge.target  AND next_edge.source <> next_edge.target
GROUP BY message.uuid, target.uuid, next_edge.uuid
HAVING COUNT(out_signal.uuid) = 0
ORDER BY target.uuid, message.uuid, trapped ASC;
DROP VIEW IF EXISTS "node_pair_time";
CREATE VIEW node_pair_time AS SELECT MAX(time) AS time, sender.uuid AS sender, receiver.uuid AS receiver FROM timestep INNER JOIN node sender INNER JOIN node receiver WHERE sender.uuid <> receiver.uuid GROUP BY sender.uuid, receiver.uuid ORDER BY RANDOM();
DROP VIEW IF EXISTS "pending_ack";
CREATE VIEW pending_ack AS 
SELECT 
 edge.delay,
        signal.uuid AS signal,
        signal.message AS message,
        edge.source AS source,
        edge.target AS target,
		edge.delay AS delay,
        signal.transmitted_at as transmittedAt,
		current_timestep.time AS time,
		CASE edge.target WHEN message.receiver THEN signal.transmitted_at + edge.delay ELSE successor_ack.acked_at + edge.delay END AS readyAt,
        ((edge.target = message.receiver AND signal.transmitted_at + edge.delay <= current_timestep.time) OR successor_ack.acked_at + edge.delay <= current_timestep.time) AS ready ,
		node_workload.capacity > node_workload.total_occupation AS inCapacity,
		node_workload.capacity,
		node_workload.total_occupation
        FROM signal
        INNER JOIN (SELECT MAX(time) AS time FROM timestep) current_timestep
        INNER JOIN message ON signal.message = message.uuid
        INNER JOIN edge ON signal.edge = edge.uuid
		INNER JOIN node_workload ON (edge.target, current_timestep.time) = (node_workload.uuid, node_workload.time)
        LEFT JOIN edge successor_edge ON edge.target = successor_edge.source
        LEFT JOIN signal sucessor_signal ON (sucessor_signal.edge, sucessor_signal.message) = (successor_edge.uuid, signal.message)
        LEFT JOIN acknowledgment successor_ack ON successor_ack.signal = sucessor_signal.uuid
        LEFT JOIN acknowledgment ON acknowledgment.signal = signal.uuid
        WHERE acknowledgment.uuid IS NULL
        GROUP BY signal.uuid;
DROP VIEW IF EXISTS "node_workload";
CREATE VIEW node_workload AS
SELECT timestep.time, node.uuid, node.capacity AS capacity, COUNT(signal.uuid) + COUNT(acknowledgment.uuid) as total_occupation,  COUNT(signal.uuid) AS signal_count, COUNT(acknowledgment.uuid) AS ack_count
FROM node 
INNER JOIN timestep 
LEFT JOIN edge out_edge ON out_edge.source = node.uuid
LEFT JOIN edge in_edge ON in_edge.target = node.uuid
LEFT JOIN signal ON (signal.edge, signal.transmitted_at) = (out_edge.uuid, timestep.time)
LEFT JOIN signal ack_signal ON ack_signal.edge = in_edge.uuid
LEFT JOIN acknowledgment ON (acknowledgment.signal, acknowledgment.acked_at) = (ack_signal.uuid,  timestep.time)
GROUP BY node.uuid, timestep.time
ORDER BY timestep.time, node.uuid;
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
COMMIT;
