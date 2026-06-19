Feature: Router reset journey
  As a library consumer
  I want to clear all stored data without losing my router registration
  So that I can reset app state (e.g. on logout) without rebuilding the router

  @proof_router_reset
  Scenario: A consumer clears all stored data and the router remains usable without re-registration
    Given a bound integration proof exists for this scenario
    When the bound integration proof is executed
    Then it passes
