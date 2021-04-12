<?php

namespace App\Repository;

use App\Entity\Signal;
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\EntityRepository;

final class SignalRepository
{
    private EntityRepository $repository;

    public function __construct(EntityManagerInterface $entityManager)
    {
        $this->repository = $entityManager->getRepository(Signal::class);
    }

    public function find(string $id): ?Signal
    {
        return $this->repository->find($id);
    }
}