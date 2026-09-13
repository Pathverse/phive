Feature: Router child reparenting
  As a library consumer
  I want stored children to belong only to their current parent
  So that deleting a former container cannot delete a moved child

  @proof_router_reparenting
  Scenario: Both routers isolate moved children and preserve them during former-parent deletion
    Given a bound integration proof exists for this scenario
    When the bound integration proof is executed
    Then it passes
