<?php

namespace App\Entity;

use App\Repository\NodeRepository;
use Doctrine\ORM\Mapping as ORM;

/**
 * @ORM\Entity
 */
class Acknowledgment
{
    /**
     * @ORM\Id
     * @ORM\Column(type="uuid")
     */
    private $uuid;

    /**
     * @ORM\OneToOne(targetEntity="App\Entity\Signal", inversedBy="acknowledgment")
     * @ORM\JoinColumn(name="signal", referencedColumnName="uuid")
     */
    private $signal;

    /**
     * @ORM\Column(type="integer")
     */
    private $ackedAt;

    /**
     * @ORM\Column(type="integer")
     */
    private $state;

    public function getUuid(): ?string
    {
        return $this->uuid;
    }

    public function getSignal()
    {
        return $this->signal;
    }

    public function getAckedAt()
    {
        return $this->ackedAt;
    }

    public function getState() {
        return $this->state;
    }

    public function isOk() {
        return $this->state === 1;
    }

    public function isTrapped() {
        return $this->state === 3;
    }

    public function isCyclic() {
        return $this->state === 2;
    }
}