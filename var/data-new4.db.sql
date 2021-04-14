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
	FOREIGN KEY("sender") REFERENCES "node"("uuid"),
	FOREIGN KEY("created_at") REFERENCES "timestep"("time") ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY("receiver") REFERENCES "node"("uuid"),
	PRIMARY KEY("uuid")
);
DROP TABLE IF EXISTS "edge";
CREATE TABLE IF NOT EXISTS "edge" (
	"uuid"	TEXT NOT NULL UNIQUE,
	"source"	TEXT NOT NULL,
	"target"	TEXT NOT NULL,
	"delay"	INTEGER NOT NULL DEFAULT 1,
	CHECK("source" <> "target"),
	FOREIGN KEY("source") REFERENCES "node"("uuid") ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY("target") REFERENCES "node"("uuid") ON DELETE CASCADE ON UPDATE CASCADE,
	PRIMARY KEY("uuid"),
	UNIQUE("source","target")
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
	FOREIGN KEY("transmitted_at") REFERENCES "timestep"("time") ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY("message") REFERENCES "message"("uuid") ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY("edge") REFERENCES "edge"("uuid") ON UPDATE CASCADE ON DELETE CASCADE,
	PRIMARY KEY("uuid"),
	UNIQUE("edge","transmitted_at")
);
DROP TABLE IF EXISTS "acknowledgment";
CREATE TABLE IF NOT EXISTS "acknowledgment" (
	"uuid"	TEXT NOT NULL UNIQUE,
	"signal"	TEXT NOT NULL UNIQUE,
	"acked_at"	INTEGER NOT NULL,
	"state"	INTEGER NOT NULL,
	FOREIGN KEY("acked_at") REFERENCES "timestep"("time") ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY("signal") REFERENCES "signal"("uuid") ON UPDATE CASCADE ON DELETE CASCADE,
	PRIMARY KEY("uuid")
);
DROP TABLE IF EXISTS "node_position";
CREATE TABLE IF NOT EXISTS "node_position" (
	"uuid"	TEXT NOT NULL,
	"node"	TEXT NOT NULL UNIQUE,
	"x"	INTEGER NOT NULL,
	"y"	INTEGER NOT NULL,
	FOREIGN KEY("node") REFERENCES "node"("uuid") ON DELETE CASCADE ON UPDATE CASCADE,
	PRIMARY KEY("uuid")
);
INSERT INTO "timestep" ("time") VALUES (1),
 (2),
 (3),
 (4),
 (5);
INSERT INTO "message" ("uuid","created_at","sender","receiver") VALUES ('��CO܂)O��%',4,'��Xx�JON��?C��U','�W�{O����Kb���'),
 ('v�7���O~����O�k',4,'����+Oְ�j�b/','�W�{O����Kb���');
INSERT INTO "edge" ("uuid","source","target","delay") VALUES ('6a�cYO�������$V','����+Oְ�j�b/','��Xx�JON��?C��U',1);
INSERT INTO "node" ("uuid","capacity") VALUES ('����+Oְ�j�b/',1),
 ('��Xx�JON��?C��U',1),
 ('+ɓ��O+�U.8�
��',1),
 ('�W�{O����Kb���',1);
INSERT INTO "signal" ("uuid","message","edge","transmitted_at") VALUES ('�+ՠC�O��h�	#�f''','v�7���O~����O�k','6a�cYO�������$V',4);
INSERT INTO "acknowledgment" ("uuid","signal","acked_at","state") VALUES ('Vvq(Q�O��=R�"��','�+ՠC�O��h�	#�f''',5,3);
INSERT INTO "node_position" ("uuid","node","x","y") VALUES ('�!�
�YOo��G�S#�','����+Oְ�j�b/',-87,133),
 ('�v��OOV�����z!','��Xx�JON��?C��U',-2,-89),
 ('��x�OՔ�U_$Q�8','+ɓ��O+�U.8�
��',-82,169),
 ('��#�i�Oߎu^x�r','�W�{O����Kb���',-35,-22);
DROP VIEW IF EXISTS "node_pair_time";
CREATE VIEW node_pair_time AS SELECT MAX(time) AS time, sender.uuid AS sender, receiver.uuid AS receiver FROM timestep INNER JOIN node sender INNER JOIN node receiver WHERE sender.uuid <> receiver.uuid GROUP BY sender.uuid, receiver.uuid ORDER BY RANDOM();
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
DROP VIEW IF EXISTS "available_dispatch";
CREATE VIEW available_dispatch AS 
SELECT message.created_at AS created_at,
message.uuid AS uuid, 
message.sender AS sender, 
message.receiver AS receiver, 
outgoing_edge.uuid AS edge,
outgoing_edge.uuid IS NULL AS trapped,
message.created_at AS createdAt,
sender.capacity AS max_load,
node_workload.current_load AS current_load,
current_timestep.time AS timeStep,
hex(outgoing_edge.uuid),
hex(old_outgoing_edge.uuid)
FROM message 
INNER JOIN (SELECT MAX(time) AS time FROM timestep) current_timestep
INNER JOIN node sender ON sender.uuid = message.sender 
LEFT JOIN edge outgoing_edge ON outgoing_edge.source = message.sender
LEFT JOIN signal outgoing_signal ON (outgoing_signal.edge, outgoing_signal.message) = (outgoing_edge.uuid, message.uuid)

LEFT JOIN edge old_outgoing_edge ON old_outgoing_edge.source = message.sender
LEFT JOIN signal old_outgoing_signal ON (old_outgoing_signal.edge, old_outgoing_signal.message) = (old_outgoing_edge.uuid, message.uuid)
LEFT JOIN acknowledgment old_outgoing_ack ON old_outgoing_ack.signal = old_outgoing_signal.uuid

LEFT JOIN node_workload ON (node_workload.uuid, node_workload.time) = (sender.uuid, current_timestep.time)
WHERE outgoing_signal.uuid IS NULL
GROUP BY message.uuid, outgoing_edge.uuid
HAVING SUM((old_outgoing_signal.uuid IS NOT NULL AND (old_outgoing_ack.state IS NOT 3 AND old_outgoing_ack.state IS NOT 2))) = 0
ORDER BY trapped ASC;
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
COUNT(DISTINCT outgoing_edge.uuid) < 1 AS trapped,
COUNT(DISTINCT outgoing_signal.uuid),
current_timestep.time AS time
FROM message 
INNER JOIN (SELECT MAX(time) AS time FROM timestep) current_timestep
INNER JOIN signal incoming_signal ON incoming_signal.message = message.uuid 
LEFT JOIN acknowledgment incoming_ack ON incoming_ack.signal = incoming_signal.uuid
INNER JOIN edge incoming_edge ON incoming_edge.uuid = incoming_signal.edge 
INNER JOIN node current_node ON incoming_edge.target = current_node.uuid
LEFT JOIN node_workload ON (node_workload.uuid, node_workload.time) = (current_node.uuid, current_timestep.time)
LEFT JOIN edge outgoing_edge ON outgoing_edge.source = current_node.uuid 
LEFT JOIN signal outgoing_signal ON (outgoing_signal.message, outgoing_signal.edge) = (incoming_signal.message, outgoing_edge.uuid) 
LEFT JOIN acknowledgment outgoing_ack ON outgoing_ack.signal = outgoing_signal.uuid
LEFT JOIN edge old_outgoing_edge ON old_outgoing_edge.source = current_node.uuid 
LEFT JOIN signal old_outgoing_signal ON (old_outgoing_signal.message, old_outgoing_signal.edge) = (incoming_signal.message, old_outgoing_edge.uuid) 
LEFT JOIN acknowledgment old_outgoing_ack ON old_outgoing_ack.signal = old_outgoing_signal.uuid
WHERE message.receiver <> current_node.uuid AND outgoing_edge.target <> incoming_edge.source AND incoming_ack.uuid IS NULL AND (outgoing_signal.uuid IS NULL) AND (old_outgoing_ack.state IS NOT 3 AND old_outgoing_ack.state IS NOT 2)
GROUP BY message.uuid, current_node.uuid, outgoing_edge.uuid
HAVING COUNT(DISTINCT old_outgoing_signal.uuid) < 1
ORDER BY current_node.uuid, message.uuid, trapped ASC;
DROP VIEW IF EXISTS "global_message_health";
CREATE VIEW global_message_health AS
SELECT message.*, 
COUNT(DISTINCT ack_ok.uuid) > 0 AS progress,
COUNT(DISTINCT initial_signal.uuid) AS trys,
COUNT(DISTINCT ack_ok.uuid) AS ack_ok,
COUNT(DISTINCT ack_trapped.uuid) AS ack_trapped,
COUNT(DISTINCT ack_cyclic.uuid) AS ack_cyclic,
COUNT(DISTINCT all_signal.uuid) AS signal_count,
COUNT(DISTINCT all_ack.uuid) AS ack_count,
MIN(all_signal.transmitted_at) AS first_trans,
MAX(all_signal.transmitted_at) AS last_trans
FROM message
LEFT JOIN edge initial_edge ON initial_edge.source = message.sender
LEFT JOIN signal initial_signal On (initial_signal.edge, initial_signal.message) = (initial_edge.uuid, message.uuid)
LEFT JOIN signal all_signal ON all_signal.message = message.uuid
LEFT JOIN acknowledgment all_ack ON all_ack.signal = all_signal.uuid
LEFT JOIN acknowledgment ack_ok On (ack_ok.signal, ack_ok.state) = (initial_signal.uuid, 1)
LEFT JOIN acknowledgment ack_trapped On (ack_trapped.signal, ack_trapped.state) = (initial_signal.uuid, 3)
LEFT JOIN acknowledgment ack_cyclic On (ack_cyclic.signal, ack_cyclic.state) = (initial_signal.uuid, 2)
GROUP BY message.uuid
ORDER BY message.created_at ASC, message.uuid ASC;
COMMIT;
