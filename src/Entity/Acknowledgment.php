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
}