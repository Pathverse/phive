Feature: Schema drift policy journey
  As a PHive consumer
  I want drift handling chosen per registration
  So that caches can refill while other data is never deleted by default

  @proof_drift_policy
  Scenario: Drift and retired type IDs propagate by default and become misses only when opted in
    Given a bound integration proof exists for this scenario
    When the bound integration proof is executed
    Then it passes
