<?php

namespace App\Repository;

use App\Entity\Node;
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\EntityRepository;

final class NodeRepository
{
    private EntityRepository $repository;

    public function __construct(EntityManagerInterface $entityManager)
    {
        $this->repository = $entityManager->getRepository(Node::class);
    }

    public function find(string $id): ?Node
    {
        return $this->repository->find($id);
    }

    public function findAll() 
    {
        return $this->repository->findAll();
    }
}