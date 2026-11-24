Feature: Positional collection decoding journey
  As a PHive consumer with positional models
  I want typed collection fields to restore from storage
  So that lists of models and typed maps read back instead of failing

  @proof_positional_collections
  Scenario: Positional collections restore, including records written by 0.8.1, and wrong types are drift
    Given a bound integration proof exists for this scenario
    When the bound integration proof is executed
    Then it passes
