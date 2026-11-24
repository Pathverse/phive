Feature: Tolerant layout opt-in journey
  As a PHive consumer with existing positional records
  I want to adopt the tolerant layout in place
  So that records written before the switch stay readable

  @proof_tolerant_opt_in
  Scenario: Positional records restore after adopting TolerantLayout and are rewritten as tagged records
    Given a bound integration proof exists for this scenario
    When the bound integration proof is executed
    Then it passes
