<?php

namespace App\Entity;

use App\Repository\MessageRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Bridge\Doctrine\IdGenerator\UuidV4Generator;

/**
 * @ORM\Entity
 */
class Message
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
    private $createdAt;

    /**
     * @ORM\ManyToOne(targetEntity="App\Entity\Node", inversedBy="outgoingMessages")
     * @ORM\JoinColumn(name="sender", referencedColumnName="uuid")
     */
    private $sender;

    /**
     * @ORM\ManyToOne(targetEntity="App\Entity\Node", inversedBy="incomingMessages")
     * @ORM\JoinColumn(name="receiver", referencedColumnName="uuid")
     */
    private $receiver;

    /**
     * @ORM\OneToMany(targetEntity="App\Entity\Signal", mappedBy="message")
     */
    private $signals;

    public function getUuid(): ?string
    {
        return $this->uuid;
    }

    public function getCreatedAt()
    {
        return $this->createdAt;
    }

    public function getSender(): ?\App\Entity\Node
    {
        return $this->sender;
    }

    public function getReceiver(): ?\App\Entity\Node
    {
        return $this->receiver;
    }

    public function getSignals()
    {
        return $this->signals;
    }

    public function setSender(?\App\Entity\Node $node)
    {
        $this->sender = $node;
    }

    public function setReceiver(?\App\Entity\Node $node)
    {
        $this->receiver = $node;
    }
}