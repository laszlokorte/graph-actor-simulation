<?php

namespace App\Repository;

use App\Entity\Message;
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\EntityRepository;

final class MessageRepository
{
    private EntityRepository $repository;

    public function __construct(EntityManagerInterface $entityManager)
    {
        $this->repository = $entityManager->getRepository(Message::class);
    }

    public function find(string $id): ?Message
    {
        return $this->repository->find($id);
    }

    public function findAll() 
    {
        return $this->repository->findAll();
    }
}