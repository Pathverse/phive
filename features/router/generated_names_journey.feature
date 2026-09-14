Feature: Generated storage names survive release compilation

  @proof_generated_store_names
  Scenario: Generated names reopen records in both native routers
    Given a bound integration proof exists for this scenario
    When the bound integration proof is executed
    Then it passes

  @proof_release_store_names
  Scenario: A later minified release reopens named primary and relationship stores
    Given the minified release naming proof is available
    When the minified release naming proof is executed
    Then it passes
