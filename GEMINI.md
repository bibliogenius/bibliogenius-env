# Gemini CLI Agent - No Regression Policy

This document outlines the policy and process for ensuring no functional regressions occur when the Gemini CLI Agent implements changes to the codebase.

## Objective

To guarantee that any modifications, feature implementations, or bug fixes introduced by the agent do not inadvertently break existing, previously functional parts of the application.

## Policy

Before completing any task that involves modifying code, the agent *must* formulate a plan for verifying that core functionalities related to the changes remain intact. This includes:

1.  **Identifying Affected Areas:** Determining which existing features might be impacted by the proposed changes.
2.  **Maintaining Core Functionality:** Ensuring that the primary purpose of existing features continues to operate as designed.
3.  **Providing Verification Instructions:** Clearly communicating to the user the steps required to manually or automatically test the affected functionalities.

## Verification Process (Agent's Workflow)

When implementing changes, the agent will adhere to the following steps:

1.  **Initial Analysis:** Understand the user's request and identify direct and indirect impacts on existing features.
2.  **Pre-computation of Verification:** Before making significant code changes, anticipate which existing functionalities will require re-verification.
3.  **Test Identification:** Look for existing unit, integration, or end-to-end tests that cover the affected functionalities. If no such tests exist, the agent will note this and, if appropriate and within scope, propose creating new tests.
4.  **Runtime Environment Assessment:** Identify how to build and run the application (e.g., `flutter run`, `npm start`, `cargo run`). This often involves consulting `README.md` files or project configuration.
5.  **Instruction Generation:** Prepare comprehensive, step-by-step instructions for the user to verify the non-regression of critical features. These instructions will detail:
    *   **Navigation:** How to reach the affected part of the application.
    *   **Interaction:** How to trigger the relevant functionalities.
    *   **Expected Outcome:** What behavior the user should observe to confirm success.
6.  **Post-Implementation Summary:** After all code changes are applied, the agent will provide the user with the generated verification instructions and await confirmation.

## Example of Verification Instructions (from a previous session)

**Scenario:** UI/UX changes to a "Network" screen involving an "Add Connection" flow.

**Verification Steps Provided to User:**

1.  **Navigate to the Network Screen.**
2.  **Verify the UI:**
    *   Confirm that specific nested tabs are no longer present.
    *   Confirm that a new `FloatingActionButton` is visible.
3.  **Test the "Add Connection" Flow:**
    *   Tap the `FloatingActionButton`. A modal bottom sheet should appear.
    *   Test each option ("Scan QR Code," "Show My Code," "Enter Manually"), verifying navigation and expected behavior (e.g., camera view, QR code dialog, contact form).
4.  **Verify Functional Regression (Add Contact):**
    *   Confirm newly added contacts appear in the list.
    *   Confirm existing contacts are still present and interactable.
5.  **Verify Functional Regression (QR Code Scan & Display):**
    *   Test scanning a QR code with another device.
    *   Confirm the displayed QR code is scannable by another device.

This policy ensures a structured approach to quality assurance, relying on both automated checks (where available) and explicit user verification for critical functionalities.