Feature: Router container journey
  As a library consumer
  I want to access and cascade-delete a parent's children through a container handle
  So that parent-child relationships are traversable and cleanly removable

  @proof_router_container
  Scenario: A consumer traverses and cascade-deletes a parent's children through a container handle
    Given a bound integration proof exists for this scenario
    When the bound integration proof is executed
    Then it passes
