<?php

namespace App\Entity;

use App\Repository\NodeRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Bridge\Doctrine\IdGenerator\UuidV4Generator;

/**
 * @ORM\Entity
 */
class Timestep
{

    /**
     * @ORM\Id
     */
    private $time;

}