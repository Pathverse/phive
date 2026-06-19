Feature: Router CRUD journey
  As a library consumer
  I want to store, retrieve, and delete typed items through a configured router
  So that domain models persist without persistence concerns leaking into them

  @proof_router_crud
  Scenario: A consumer stores and retrieves typed items through a configured router
    Given a bound integration proof exists for this scenario
    When the bound integration proof is executed
    Then it passes
