Feature: Static router layout journey
  As a library consumer targeting web
  I want a single BoxCollection database with multiple named stores
  So that my app opens one IndexedDB database rather than one per registered type

  @proof_router_static_layout
  Scenario: A consumer configures a static router that locks its schema on first open
    Given a bound integration proof exists for this scenario
    When the bound integration proof is executed
    Then it passes
