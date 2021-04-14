<?php

namespace App\Entity;

use App\Repository\NodeRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Bridge\Doctrine\IdGenerator\UuidV4Generator;

/**
 * @ORM\Entity
 */
class NodePosition
{

    /**
     * @ORM\Id
     * @ORM\Column(type="uuid", unique=true)
     * @ORM\GeneratedValue(strategy="CUSTOM")
     * @ORM\CustomIdGenerator(class=UuidV4Generator::class)
     */
    private $uuid;

    /**
     * @ORM\OneToOne(targetEntity="App\Entity\Node", inversedBy="position")
     * @ORM\JoinColumn(name="node", referencedColumnName="uuid")
     */
    private $node;

    /**
     * @ORM\Column(type="integer")
     */
    private $x = 0;

    /**
     * @ORM\Column(type="integer")
     */
    private $y = 0;

    public function __construct($x = 0, $y = 0) 
    {
        $this->x = $x;
        $this->y = $y;
    }

    public function getNode(): ?Node
    {
        return $this->node;
    }

    public function setNode(?Node $node)
    {
        $this->node = $node;
    }

    public function getSignal()
    {
        return $this->signal;
    }

    public function getX()
    {
        return $this->x;
    }

    public function getY()
    {
        return $this->y;
    }

}