<?php

namespace App\Entity;

use App\Repository\NodeRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Bridge\Doctrine\IdGenerator\UuidV4Generator;

/**
 * @ORM\Entity
 */
class Node
{

    /**
     * @ORM\Id
     * @ORM\Column(type="uuid", unique=true)
     * @ORM\GeneratedValue(strategy="CUSTOM")
     * @ORM\CustomIdGenerator(class=UuidV4Generator::class)
     */
    private $uuid;

    /**
     * @ORM\Column(type="integer")
     */
    private $capacity = 1;

    /**
     * @ORM\OneToMany(targetEntity="App\Entity\Edge", mappedBy="source")
     */
    private $outgoingEdges;

    /**
     * @ORM\OneToMany(targetEntity="App\Entity\Edge", mappedBy="target")
     */
    private $incomingEdges;

    /**
     * @ORM\OneToMany(targetEntity="App\Entity\Message", mappedBy="sender")
     */
    private $outgoingMessages;

    /**
     * @ORM\OneToMany(targetEntity="App\Entity\Message", mappedBy="receiver")
     */
    private $incomingMessages;

    /**
     * @ORM\OneToOne(targetEntity="App\Entity\NodePosition", mappedBy="node", cascade={"persist", "remove"})
     */
    private $position;

    public function __construct() {
        $this->position = new NodePosition(rand(-200, 200), rand(-200, 200));
        $this->position->setNode($this);
    }

    public function getUuid(): ?string
    {
        return $this->uuid;
    }

    public function getOutgoingEdges()
    {
        return $this->outgoingEdges;
    }

    public function getIncomingEdges()
    {
        return $this->incomingEdges;
    }

    public function getOutgoingMessages()
    {
        return $this->outgoingMessages;
    }

    public function getIncomingMessages()
    {
        return $this->incomingMessages;
    }

    public function getCapacity()
    {
        return $this->capacity;
    }

    public function getPosition()
    {
        return $this->position ?? new NodePosition();
    }
}