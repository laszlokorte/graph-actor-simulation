<?php
// src/Controller/LuckyController.php
namespace App\Controller;

use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Form\FormFactoryInterface;
use Symfony\Component\HttpFoundation\RedirectResponse;
use Doctrine\ORM\EntityManagerInterface ;

use Symfony\Component\Routing\Generator\UrlGeneratorInterface;
use Sensio\Bundle\FrameworkExtraBundle\Configuration\Template;
use Symfony\Component\Routing\Annotation\Route;
use App\Form\Type\CreateNodeType;
use App\Form\Type\CreateEdgeType;
use App\Form\Type\CreateMessageType;
use App\Form\Type\CreateNodeMessageType;
use App\Form\Type\CreateNodeEdgeType;
use App\Form\Type\CreateTimestepType;
use App\Form\Type\DeleteTimestepType;
use App\Form\Type\GraphClearType;
use App\Form\Type\SimulationResetType;
use App\Form\Type\SimulationStepType;
use App\Repository\NodeRepository;
use App\Repository\EdgeRepository;
use App\Repository\MessageRepository;
use App\Entity;

class GraphController
{
    /**
     * @Route("/", name="graph_index")
     * @Template
     */
    public function index(NodeRepository $nodeRepo, MessageRepository $messageRepo, EdgeRepository $edgeRepo, FormFactoryInterface $formFactory, UrlGeneratorInterface $urlGenerator)
    {
        $node = new Entity\Node();
        $createNodeForm = $formFactory->create(CreateNodeType::class, $node, [
            'action' => $urlGenerator->generate('graph_create_node'),
            'method' => 'POST',
        ]);

        $edge = new Entity\Edge();
        $createEdgeForm = $formFactory->create(CreateEdgeType::class, $edge, [
            'action' => $urlGenerator->generate('graph_create_edge'),
            'method' => 'POST',
        ]);

        $message = new Entity\Message();
        $createMessageForm = $formFactory->create(CreateMessageType::class, $message, [
            'action' => $urlGenerator->generate('graph_create_message'),
            'method' => 'POST',
        ]);

        $simulationResetForm = $formFactory->create(SimulationResetType::class, null, [
            'action' => $urlGenerator->generate('simulation_reset'),
            'method' => 'POST',
        ]);

        $graphClearForm = $formFactory->create(GraphClearType::class, null, [
            'action' => $urlGenerator->generate('graph_clear'),
            'method' => 'POST',
        ]);

        $simulationStepForm = $formFactory->create(SimulationStepType::class, null, [
            'action' => $urlGenerator->generate('simulation_step'),
            'method' => 'POST',
        ]);

        return [
            'nodes' => $nodeRepo->findAll(),
            'edges' => $edgeRepo->findAll(),
            'messages' => $messageRepo->findAll(),
            'createNodeForm' => $createNodeForm->createView(),
            'createEdgeForm' => $createEdgeForm->createView(),
            'simulationResetForm' => $simulationResetForm->createView(),
            'graphClearForm' => $graphClearForm->createView(),
            'simulationStepForm' => $simulationStepForm->createView(),
            'createMessageForm' => $createMessageForm->createView(),
        ];
    }

    /**
     * @Route("/node/{uuid}", name="graph_node")
     * @Template
     */
    public function nodeDetail(NodeRepository $nodeRepo, EdgeRepository $edgeRepo, FormFactoryInterface $formFactory, UrlGeneratorInterface $urlGenerator, Entity\Node $node)
    {
        $edge = new Entity\Edge();
        $edge->setSource($node);

        $createEdgeForm = $formFactory->create(CreateNodeEdgeType::class, $edge, [
            'action' => $urlGenerator->generate('graph_create_node_edge', ['uuid' => $node->getUuid()]),
            'method' => 'POST',
        ]);

        $message = new Entity\Message();
        $message->setSender($node);

        $createMessageForm = $formFactory->create(CreateNodeMessageType::class, $message, [
            'action' => $urlGenerator->generate('graph_create_node_message', ['uuid' => $node->getUuid()]),
            'method' => 'POST',
        ]);

        return [
            'node' => $node,
            'nodes' => $nodeRepo->findAll(),
            'edges' => $edgeRepo->findAll(),
            'createEdgeForm' => $createEdgeForm->createView(),
            'createMessageForm' => $createMessageForm->createView(),
        ];
    }

    /**
     * @Route("/edge/{uuid}", name="graph_edge")
     * @Template
     */
    public function edgeDetail(NodeRepository $nodeRepo, EdgeRepository $edgeRepo, FormFactoryInterface $formFactory, UrlGeneratorInterface $urlGenerator, Entity\Edge $edge)
    {
        $reverse = $edgeRepo->findReverse($edge);

        return [
            'edge' => $edge,
            'reverse' => $reverse,
            'nodes' => $nodeRepo->findAll(),
            'edges' => $edgeRepo->findAll(),
        ];
    }


    /**
     * @Route("/message/{uuid}", name="graph_message")
     * @Template
     */
    public function messageDetail(NodeRepository $nodeRepo, EdgeRepository $edgeRepo, FormFactoryInterface $formFactory, UrlGeneratorInterface $urlGenerator, Entity\Message $message)
    {

        return [
            'message' => $message,
            'nodes' => $nodeRepo->findAll(),
            'edges' => $edgeRepo->findAll(),
        ];
    }


    /**
     * @Route("/node", methods={"POST"}, name="graph_create_node")
     * @Template
     */
    public function createNode(Request $request, NodeRepository $nodeRepo, FormFactoryInterface $formFactory, UrlGeneratorInterface $urlGenerator, EntityManagerInterface  $entityManager)
    {
        $node = new Entity\Node();
        $createNodeForm = $formFactory->create(CreateNodeType::class, $node, [
            'action' => $urlGenerator->generate('graph_create_node'),
            'method' => 'POST',
        ]);

        $createNodeForm->handleRequest($request);

        if ($createNodeForm->isSubmitted() && $createNodeForm->isValid()) {
            $node = $createNodeForm->getData();

            $entityManager->persist($node);
            $entityManager->flush();
        }

        return new RedirectResponse($urlGenerator->generate('graph_index'));
    }


    /**
     * @Route("/edge", methods={"POST"}, name="graph_create_edge")
     * @Template
     */
    public function createEdge(Request $request, NodeRepository $nodeRepo, FormFactoryInterface $formFactory, UrlGeneratorInterface $urlGenerator, EntityManagerInterface  $entityManager)
    {
        $edge = new Entity\Edge();
        $createEdgeForm = $formFactory->create(CreateEdgeType::class, $edge, [
            'action' => $urlGenerator->generate('graph_create_edge'),
            'method' => 'POST',
        ]);

        $createEdgeForm->handleRequest($request);

        if ($createEdgeForm->isSubmitted() && $createEdgeForm->isValid()) {
            $edge = $createEdgeForm->getData();

            $entityManager->persist($edge);
            $entityManager->flush();
        }

        return new RedirectResponse($urlGenerator->generate('graph_index'));
    }

    /**
     * @Route("/edge/{uuid}/reverse", methods={"POST"}, name="graph_create_edge_reverse")
     * @Template
     */
    public function createEdgeReverse(Request $request, NodeRepository $nodeRepo, FormFactoryInterface $formFactory, EdgeRepository $edgeRepo,UrlGeneratorInterface $urlGenerator, EntityManagerInterface  $entityManager, Entity\Edge $edge)
    {
        $reverse = $edgeRepo->findReverse($edge);

        if($reverse) {
            return new RedirectResponse($urlGenerator->generate('graph_edge',['uuid' => $reverse->getUuid()]));
        } else {
            $reverse = new Entity\Edge();
            $reverse->setSource($edge->getTarget());
            $reverse->setTarget($edge->getSource());


            $entityManager->persist($reverse);
            $entityManager->flush();
        }
        

        return new RedirectResponse($urlGenerator->generate('graph_edge',['uuid' => $edge->getUuid()]));
    }

    /**
     * @Route("/edges/reverse", methods={"POST"}, name="graph_create_edges_reverse_all")
     * @Template
     */
    public function createEdgeReverseAll(Request $request, NodeRepository $nodeRepo, FormFactoryInterface $formFactory, EdgeRepository $edgeRepo,UrlGeneratorInterface $urlGenerator, EntityManagerInterface  $entityManager)
    {
        $connection = $entityManager->getConnection();

        $timestepSQL = "INSERT INTO edge(uuid, source, target, delay) SELECT randomblob(16), edge.target, edge.source, edge.delay FROM edge LEFT JOIN edge rev ON rev.source = edge.target WHERE rev.uuid IS NULL";
        $timestepStmt = $connection->prepare($timestepSQL);
        $timestepStmt->execute();
        

        return new RedirectResponse($urlGenerator->generate('graph_index'));
    }


    /**
     * @Route("/message", methods={"POST"}, name="graph_create_message")
     * @Template
     */
    public function createMessage(Request $request, NodeRepository $nodeRepo, FormFactoryInterface $formFactory, UrlGeneratorInterface $urlGenerator, EntityManagerInterface  $entityManager)
    {
        $message = new Entity\Message();
        $createMessageForm = $formFactory->create(CreateMessageType::class, $message, [
            'action' => $urlGenerator->generate('graph_create_message'),
            'method' => 'POST',
        ]);

        $createMessageForm->handleRequest($request);

        if ($createMessageForm->isSubmitted() && $createMessageForm->isValid()) {
            $message = $createMessageForm->getData();

            $entityManager->persist($message);
            $entityManager->flush();
        }

        return new RedirectResponse($urlGenerator->generate('graph_index'));
    }

    /**
     * @Route("/node/{uuid}/edge", methods={"POST"}, name="graph_create_node_edge")
     */
    public function createNodeEdge(Request $request, NodeRepository $nodeRepo, FormFactoryInterface $formFactory, UrlGeneratorInterface $urlGenerator, EntityManagerInterface  $entityManager, Entity\Node $node)
    {

        $edge = new Entity\Edge();
        $edge->setSource($node);

        $createEdgeForm = $formFactory->create(CreateNodeEdgeType::class, $edge, [
            'action' => $urlGenerator->generate('graph_create_node_edge', ['uuid' => $node->getUuid()]),
            'method' => 'POST',
        ]);

        $createEdgeForm->handleRequest($request);

        if ($createEdgeForm->isSubmitted() && $createEdgeForm->isValid()) {
            $edge = $createEdgeForm->getData();

            $entityManager->persist($edge);
            $entityManager->flush();
        }

        return new RedirectResponse($urlGenerator->generate('graph_node', ['uuid' => $node->getUuid()]));
    }

    /**
     * @Route("/node/{uuid}/message", methods={"POST"}, name="graph_create_node_message")
     */
    public function createNodeMessage(Request $request, NodeRepository $nodeRepo, FormFactoryInterface $formFactory, UrlGeneratorInterface $urlGenerator, EntityManagerInterface  $entityManager, Entity\Node $node)
    {

        $message = new Entity\Message();
        $message->setSender($node);

        $createMessageForm = $formFactory->create(CreateNodeMessageType::class, $message, [
            'action' => $urlGenerator->generate('graph_create_node_message', ['uuid' => $node->getUuid()]),
            'method' => 'POST',
        ]);

        $createMessageForm->handleRequest($request);

        if ($createMessageForm->isSubmitted() && $createMessageForm->isValid()) {
            $message = $createMessageForm->getData();

            $entityManager->persist($message);
            $entityManager->flush();
        }

        return new RedirectResponse($urlGenerator->generate('graph_node', ['uuid' => $node->getUuid()]));
    }

    /**
     * @Route("/graph/clear", methods={"POST"}, name="graph_clear")
     */
    public function graphClear(Request $request, NodeRepository $nodeRepo, FormFactoryInterface $formFactory, UrlGeneratorInterface $urlGenerator, EntityManagerInterface  $entityManager)
    {

        $resetForm = $formFactory->create(GraphClearType::class, null, [
            'action' => $urlGenerator->generate('graph_clear'),
            'method' => 'POST',
        ]);

        $resetForm->handleRequest($request);

        if ($resetForm->isSubmitted() && $resetForm->isValid()) {
            $connection = $entityManager->getConnection();

            $connection->beginTransaction();
            $connection->exec("DELETE FROM acknowledgment");
            $connection->exec("DELETE FROM signal");
            $connection->exec("DELETE FROM message");
            $connection->exec("DELETE FROM timestep");
            $connection->exec("DELETE FROM edge");
            $connection->exec("DELETE FROM node_position");
            $connection->exec("DELETE FROM node");
            $connection->commit();
        }

        return new RedirectResponse($urlGenerator->generate('graph_index'));
    }


    /**
     * @Route("/simulation/reset", methods={"POST"}, name="simulation_reset")
     */
    public function simulationReset(Request $request, NodeRepository $nodeRepo, FormFactoryInterface $formFactory, UrlGeneratorInterface $urlGenerator, EntityManagerInterface  $entityManager)
    {

        $resetForm = $formFactory->create(SimulationResetType::class, null, [
            'action' => $urlGenerator->generate('simulation_reset'),
            'method' => 'POST',
        ]);

        $resetForm->handleRequest($request);

        if ($resetForm->isSubmitted() && $resetForm->isValid()) {
            $connection = $entityManager->getConnection();

            $connection->beginTransaction();
            $connection->exec("DELETE FROM acknowledgment");
            $connection->exec("DELETE FROM signal");
            $connection->exec("DELETE FROM message");
            $connection->exec("DELETE FROM timestep");
            $connection->commit();
        }

        return new RedirectResponse($urlGenerator->generate('simulation_next'));
    }

    /**
     * @Route("/simulation/step", methods={"POST"}, name="simulation_step")
     */
    public function simulationStep(Request $request, NodeRepository $nodeRepo, FormFactoryInterface $formFactory, UrlGeneratorInterface $urlGenerator, EntityManagerInterface  $entityManager)
    {
        $form = $formFactory->create(CreateTimestepType::class, new Entity\Message(), [
            'action' => $urlGenerator->generate('simulation_step'),
            'method' => 'POST',
        ]);

        $form->handleRequest($request);

        if ($form->isSubmitted() && $form->isValid()) {
            $connection = $entityManager->getConnection();

            $timestepSQL = "INSERT INTO timestep(time) SELECT COALESCE(MAX(time), 0)+1 FROM timestep";
            $timestepStmt = $connection->prepare($timestepSQL);
            $timestepStmt->execute();
        }


        return new RedirectResponse($urlGenerator->generate('simulation_next'));
    }

    /**
     * @Route("/simulation/back", methods={"POST"}, name="simulation_back")
     */
    public function simulationBack(Request $request, NodeRepository $nodeRepo, FormFactoryInterface $formFactory, UrlGeneratorInterface $urlGenerator, EntityManagerInterface  $entityManager)
    {
        $form = $formFactory->create(DeleteTimestepType::class, new Entity\Message(), [
            'action' => $urlGenerator->generate('simulation_back'),
            'method' => 'POST',
        ]);

        $form->handleRequest($request);

        if ($form->isSubmitted() && $form->isValid()) {
            $connection = $entityManager->getConnection();
            $connection->beginTransaction();

            $connection->exec("DELETE FROM acknowledgment WHERE acked_at >= (SELECT MAX(time) FROM timestep)");
            $connection->exec("DELETE FROM signal WHERE transmitted_at >= (SELECT MAX(time) FROM timestep)");
            $connection->exec("DELETE FROM message WHERE created_at >= (SELECT MAX(time) FROM timestep)");
            $connection->exec("DELETE FROM timestep WHERE time >= (SELECT MAX(time) FROM timestep)");
            $connection->commit();
        }


        return new RedirectResponse($urlGenerator->generate('simulation_next'));
    }

    /**
     * @Route("/simulation/next", methods={"GET"}, name="simulation_next")
     * @Template
     */
    public function simulationNext(Request $request, NodeRepository $nodeRepo, EdgeRepository $edgeRepo, MessageRepository $messageRepo, FormFactoryInterface $formFactory, UrlGeneratorInterface $urlGenerator, EntityManagerInterface  $entityManager)
    {
        $connection = $entityManager->getConnection();

        $timestepSQL = "SELECT MAX(time) FROM timestep";
        $timestepStmt = $connection->prepare($timestepSQL);
        $timestepStmt->execute();
        $timestep = $timestepStmt->fetchColumn();

        $newMessagesSQL = "SELECT * FROM available_dispatch WHERE NOT trapped";
        $newMessagesStmt = $connection->prepare($newMessagesSQL);
        $newMessagesStmt->execute();
        $newMessages = $newMessagesStmt->fetchAll();

        $trappedMessagesSQL = "SELECT * FROM available_dispatch WHERE trapped";
        $trappedMessagesStmt = $connection->prepare($trappedMessagesSQL);
        $trappedMessagesStmt->execute();
        $trappedMessages = $trappedMessagesStmt->fetchAll();

        $transitMessagesSQL = "SELECT * FROM available_redirect";
        $transitMessagesStmt = $connection->prepare($transitMessagesSQL);
        $transitMessagesStmt->execute();
        $transitMessages = $transitMessagesStmt->fetchAll();

        $messageHealthSQL = "SELECT * FROM global_message_health";
        $messageHealthStmt = $connection->prepare($messageHealthSQL);
        $messageHealthStmt->execute();
        $messageHealth = $messageHealthStmt->fetchAll();



        $pendingAcknowledgmentsSQL = "SELECT * FROM available_response";
        $pendingAcknowledgmentsStmt = $connection->prepare($pendingAcknowledgmentsSQL);
        $pendingAcknowledgmentsStmt->execute();
        $pendingAcknowledgments = $pendingAcknowledgmentsStmt->fetchAll();

        $form = $formFactory->create(CreateTimestepType::class, new Entity\Message(), [
            'action' => $urlGenerator->generate('simulation_step'),
            'method' => 'POST',
        ]);


        $backForm = $formFactory->create(DeleteTimestepType::class, new Entity\Message(), [
            'action' => $urlGenerator->generate('simulation_back'),
            'method' => 'POST',
        ]);


        $simulationResetForm = $formFactory->create(SimulationResetType::class, null, [
            'action' => $urlGenerator->generate('simulation_reset'),
            'method' => 'POST',
        ]);

        return [
            'timestep' => $timestep,
            'nodes' => $nodeRepo->findAll(),
            'edges' => $edgeRepo->findAll(),
            'messageHealth' => $messageHealth,
            'messages' => $messageRepo->findAll(),
            'newMessages' => $newMessages,
            'trappedMessages' => $trappedMessages,
            'transitMessages' => $transitMessages,
            'pendingAcknowledgments' => $pendingAcknowledgments,
            'timestepForm' =>  $form->createView(),
            'backForm' =>  $backForm->createView(),
            'simulationResetForm' =>  $simulationResetForm->createView(),
        ];

//         INSERT INTO signal(transmitted_at, uuid, message, edge)
// SELECT message.created_at+2 AS createdAt, 
// message.uuid AS uuid_hex,
// message.uuid AS uuid_hex,
// MAX(edge.uuid) AS edge_hex
// FROM message LEFT JOIN signal ON signal.message = message.uuid LEFT JOIN edge ON edge.source = message.sender AND edge.source <> edge.target WHERE signal.uuid IS NULL AND edge.uuid IS NOT NULL GROUP BY message.uuid
// LIMIT 1
    }

    /**
     * @Route("/simulation/message", methods={"POST"}, name="simulation_message")
     * @Template
     */
    public function simulationMessage(Request $request, NodeRepository $nodeRepo, EdgeRepository $edgeRepo, FormFactoryInterface $formFactory, UrlGeneratorInterface $urlGenerator, EntityManagerInterface  $entityManager)
    {
        $connection = $entityManager->getConnection();

        $timestepSQL = "INSERT INTO message (uuid, created_at, sender, receiver) SELECT  :uuid, time, sender, receiver FROM node_pair_time LIMIT 1";
        $timestepStmt = $connection->prepare($timestepSQL);
        $timestepStmt->bindValue(':uuid', (new \Symfony\Component\Uid\UuidV4())->toBinary());
        $timestepStmt->execute();

        return new RedirectResponse($urlGenerator->generate('simulation_next'));
    }

    /**
     * @Route("/simulation/message-discard-trapped", methods={"POST"}, name="simulation_message_discard_trapped")
     * @Template
     */
    public function simulationMessageTrapped(Request $request, NodeRepository $nodeRepo, EdgeRepository $edgeRepo, FormFactoryInterface $formFactory, UrlGeneratorInterface $urlGenerator, EntityManagerInterface  $entityManager)
    {
        $connection = $entityManager->getConnection();

        $timestepSQL = "DELETE FROM message WHERE uuid IN (SELECT uuid FROM available_dispatch WHERE trapped)";
        $timestepStmt = $connection->prepare($timestepSQL);
        $timestepStmt->execute();

        return new RedirectResponse($urlGenerator->generate('simulation_next'));
    }

    /**
     * @Route("/simulation/message-dispatch", methods={"POST"}, name="simulation_message_dispatch")
     * @Template
     */
    public function simulationMessageDispatch(Request $request, NodeRepository $nodeRepo, EdgeRepository $edgeRepo, FormFactoryInterface $formFactory, UrlGeneratorInterface $urlGenerator, EntityManagerInterface  $entityManager)
    {
        $connection = $entityManager->getConnection();

        $timestepSQL = "INSERT INTO signal SELECT :uuid AS signal_uuid, uuid as message, edge as edge, timeStep AS time FROM available_dispatch WHERE current_load < max_load AND NOT trapped ORDER BY createdAt ASC, RANDOM() LIMIT 1";
        $timestepStmt = $connection->prepare($timestepSQL);
        $timestepStmt->bindValue(':uuid', (new \Symfony\Component\Uid\UuidV4())->toBinary());

        $timestepStmt->execute();

        return new RedirectResponse($urlGenerator->generate('simulation_next'));
    }

    /**
     * @Route("/simulation/message-forward", methods={"POST"}, name="simulation_message_forward")
     * @Template
     */
    public function simulationMessageForward(Request $request, NodeRepository $nodeRepo, EdgeRepository $edgeRepo, FormFactoryInterface $formFactory, UrlGeneratorInterface $urlGenerator, EntityManagerInterface  $entityManager)
    {
        $connection = $entityManager->getConnection();

        $timestepSQL = "INSERT INTO signal(uuid, message, edge, transmitted_at) 
            SELECT :uuid, message, outgoing_edge, time FROM available_redirect 
            WHERE ready and current_load < max_load AND NOT trapped ORDER BY RANDOM() LIMIT 1";
        $timestepStmt = $connection->prepare($timestepSQL);
        $timestepStmt->bindValue(':uuid', (new \Symfony\Component\Uid\UuidV4())->toBinary());
        $timestepStmt->execute();

        return new RedirectResponse($urlGenerator->generate('simulation_next'));
    }

    /**
     * @Route("/simulation/message-ack", methods={"POST"}, name="simulation_message_ack")
     * @Template
     */
    public function simulationMessageAcknowledge(Request $request, NodeRepository $nodeRepo, EdgeRepository $edgeRepo, FormFactoryInterface $formFactory, UrlGeneratorInterface $urlGenerator, EntityManagerInterface  $entityManager)
    {
        $connection = $entityManager->getConnection();

        $timestepSQL = "INSERT INTO acknowledgment(uuid, signal, acked_at, state) 
SELECT :uuid, signal, time, state FROM available_response
WHERE current_load < max_load AND ready_at <= time
ORDER BY RANDOM() LIMIT 1";
        $timestepStmt = $connection->prepare($timestepSQL);
        $timestepStmt->bindValue(':uuid', (new \Symfony\Component\Uid\UuidV4())->toBinary());
        $timestepStmt->execute();

        return new RedirectResponse($urlGenerator->generate('simulation_next'));
    }
}