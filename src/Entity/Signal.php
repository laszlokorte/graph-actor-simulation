<?php

namespace App\Entity;

use App\Repository\NodeRepository;
use Doctrine\ORM\Mapping as ORM;

/**
 * @ORM\Entity
 */
class Signal
{
    /**
     * @ORM\Id
     * @ORM\Column(type="uuid")
     */
    private $uuid;

    /**
     * @ORM\ManyToOne(targetEntity="App\Entity\Message", inversedBy="signals")
     * @ORM\JoinColumn(name="message", referencedColumnName="uuid")
     */
    private $message;

    /**
     * @ORM\ManyToOne(targetEntity="App\Entity\Edge", inversedBy="signals")
     * @ORM\JoinColumn(name="edge", referencedColumnName="uuid")
     */
    private $edge;

    /**
     * @ORM\Column(type="integer")
     */
    private $transmittedAt;

    /**
     * @ORM\OneToOne(targetEntity="App\Entity\Acknowledgment", mappedBy="signal")
     */
    private $acknowledgment;

    public function getUuid(): ?string
    {
        return $this->uuid;
    }

    public function getEdge()
    {
        return $this->edge;
    }

    public function getMessage()
    {
        return $this->message;
    }

    public function getTransmittedAt()
    {
        return $this->transmittedAt;
    }

    public function getAcknowledgment()
    {
        return $this->acknowledgment;
    }
}