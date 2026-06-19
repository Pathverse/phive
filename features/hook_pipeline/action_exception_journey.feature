Feature: Hook action exception journey
  As a PHive hook author
  I want an expiring entry to be cleaned on read when its adapter signals expiry
  So that stale data is self-healing without explicit cache-eviction logic in app code

  @proof_hook_action_exception
  Scenario: An expiring entry is cleaned and returns null when the adapter signals expiry
    Given a bound integration proof exists for this scenario
    When the bound integration proof is executed
    Then it passes
