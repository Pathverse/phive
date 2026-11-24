Feature: Enum cases survive schema evolution

  @proof_enum_adapters
  Scenario: Enum cases survive schema evolution
    Given a bound integration proof exists for this scenario
    When the bound integration proof is executed
    Then it passes
