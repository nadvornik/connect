@slow_process
Feature: SUSEConnect full stack integration testing
  In order to deliver the best possible quality of SUSEConnect package we have to do a full stack integration testing
  This means we have to register a test machine against production server and examine all relevant data

  ### SUSEConnect cmd checks ###
  Scenario: System registration
    When I call SUSEConnect with '--regcode VALID' arguments
    Then the exit status should be 0

    And a file named "/etc/zypp/credentials.d/SCCcredentials" should exist
    And the file "/etc/zypp/credentials.d/SCCcredentials" should contain "SCC_"

    And a file named "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Server_12_x86_64" should exist
    And the file "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Server_12_x86_64" should contain "SCC_"

    And zypper should contain a service for base product
    And zypper should contain a repositories for base product

  Scenario: Extension activation with regcode
    When I call SUSEConnect with '--regcode VALID --product sle-sdk/12/x86_64' arguments
    Then the exit status should be 0

    And a file named "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64" should exist
    And the file "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64" should contain "SCC_"

    And zypper should contain a service for sdk product
    And zypper should contain a repositories for sdk product

  Scenario: API response language check
    Given I set the environment variables to
      | variable | value |
      | LANG     | de    |
    When I call SUSEConnect with '--regcode INVALID' arguments
    Then the exit status should be 67

    And the output should contain "Keine Subscription mit diesem Registrierungscode gefunden"

  ### SUSE::Connect library checks ###
  Scenario: Free extension activation
    When SUSEConnect library should be able to activate a free extension without regcode
    Then zypper should contain a service for wsm product
    And zypper should contain a repositories for wsm product

  Scenario: Product information (extensions)
    When SUSEConnect library should be able to retrieve the product information

  Scenario: API version check
    When SUSEConnect library should respect API headers

  # De-register the system at the end of the feature
  Scenario: System de-registration
    When SUSEConnect library should be able to de-register the system
    Then a file named "/etc/zypp/credentials.d/SCCcredentials" should not exist

  # This doesn't work because the above de-register also removed credentials, duh
  # To test this behaviour, we need to de-register the system on SCC only, but keep the credentials.
  # How to set up a separate integration test that does this?
  # 1 Register
  # 2 De-register by calling api.deregister only (simulates manual system deletion on SCC)
  # 3 Test
  # 4 Remove credentials

  @ignore
  Scenario: Error cleanly if system de-registered on SCC
    When I call SUSEConnect with '--regcode VALID' arguments
    Then I delete the registered system on SCC only
    And I call SUSEConnect with '--status true' arguments
    Then the exit status should be 67
    And the output should contain:
    """
    Not authorised. If using existing SCC credentials
    """
    Then I remove local credentials


