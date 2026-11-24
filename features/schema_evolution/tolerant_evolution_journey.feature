Feature: Tolerant record evolution journey
  As a PHive consumer persisting generated API models
  I want stored records to survive field changes
  So that a server-side schema change does not corrupt or silently misread my cache

  @proof_tolerant_evolution
  Scenario: Tolerant records survive reordered, removed and added fields and report incompatible changes as drift
    Given a bound integration proof exists for this scenario
    When the bound integration proof is executed
    Then it passes
