<?php

namespace App\Entity;

use App\Repository\EdgeRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;
use Symfony\Bridge\Doctrine\IdGenerator\UuidV4Generator;

/**
 * @ORM\Entity
 */
class Edge
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
    private $delay = 1;

    /**
     * @ORM\ManyToOne(targetEntity="App\Entity\Node", inversedBy="outgoingEdges")
     * @ORM\JoinColumn(name="source", referencedColumnName="uuid")
     * @Assert\NotEqualTo(propertyPath="target")
     */
    private $source;

    /**
     * @ORM\ManyToOne(targetEntity="App\Entity\Node", inversedBy="incomingEdges")
     * @ORM\JoinColumn(name="target", referencedColumnName="uuid")
     * @Assert\NotEqualTo(propertyPath="source")
     */
    private $target;

    /**
     * @ORM\OneToMany(targetEntity="App\Entity\Signal", mappedBy="edge")
     */
    private $signals;

    public function getUuid(): ?string
    {
        return $this->uuid;
    }

    public function getSource(): ?\App\Entity\Node
    {
        return $this->source;
    }

    public function getTarget(): ?\App\Entity\Node
    {
        return $this->target;
    }

    public function setSource(?\App\Entity\Node $node)
    {
        $this->source = $node;
    }

    public function setTarget(?\App\Entity\Node $node)
    {
        $this->target = $node;
    }

    public function getSignals()
    {
        return $this->signals;
    }

    public function getDelay()
    {
        return $this->delay;
    }
}