Feature: Hook metadata journey
  As a PHive hook author
  I want metadata written during store to be restored during get
  So that hooks can persist side-channel state (nonces, expiry times) alongside field values

  @proof_hook_metadata
  Scenario: Generated adapters restore field overrides and global defaults from stored bytes
    Given a bound integration proof exists for this scenario
    When the bound integration proof is executed
    Then it passes
