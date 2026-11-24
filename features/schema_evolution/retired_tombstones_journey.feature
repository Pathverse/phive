Feature: Retired identifiers report typed schema drift

  @proof_retired_tombstones
  Scenario: Retired identifiers report typed schema drift
    Given a bound integration proof exists for this scenario
    When the bound integration proof is executed
    Then it passes
