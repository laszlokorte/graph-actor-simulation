<?php

namespace App\Repository;

use App\Entity\Edge;
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\EntityRepository;

final class EdgeRepository
{
    private EntityRepository $repository;

    public function __construct(EntityManagerInterface $entityManager)
    {
        $this->repository = $entityManager->getRepository(Edge::class);
    }

    public function find(string $id): ?Edge
    {
        return $this->repository->findOne($id);
    }

    public function findReverse(Edge $edge): ?Edge
    {
        return $this->repository->findOneBy(['source' => $edge->getTarget(), 'target' => $edge->getSource()]);
    }

    public function findAll() 
    {
        return $this->repository->findAll();
    }
}