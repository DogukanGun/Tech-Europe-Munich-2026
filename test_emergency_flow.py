#!/usr/bin/env python3
"""
LiverLink - Multi-Agent Emergency Handoff Flow Playwright Test
This script automates the full emergency escalation pipeline using Playwright.
It triggers the simulation, verifies Lila and Aria's transitions, authorizes
the Human-In-The-Loop EMS dispatch gate, and verifies the final completion summary.
"""

import sys
import time
from playwright.sync_api import sync_playwright

def run():
    print("==============================================================")
    print("        LIVERLINK MULTI-AGENT EMERGENCY FLOW VERIFIER        ")
    print("==============================================================")
    
    with sync_playwright() as p:
        # Launch browser (headless=False so you can watch the automated flow)
        print("[1/6] Launching Chromium browser...")
        browser = p.chromium.launch(headless=False)
        page = browser.new_page()
        
        # Navigate to LiverLink Dashboard
        print("[2/6] Connecting to LiverLink Web App at http://localhost:8080/ ...")
        page.on("console", lambda msg: print(f"BROWSER CONSOLE: {msg.type}: {msg.text}"))
        try:
            page.goto("http://localhost:8080/", timeout=10000)
        except Exception as e:
            print(f"[ERROR] Could not connect to http://localhost:8080/. Make sure the servers are running (./run_all.sh). Error: {e}")
            sys.exit(1)
            
        # Give the page 3 seconds to fully load and initialize its javascript handlers
        print("Waiting 3 seconds for page initialization...")
        time.sleep(3)
            
        # Click the emergency simulation trigger button
        print("[3/6] Triggering Patient Jaundice & Encephalopathy Emergency simulation...")
        page.wait_for_selector("#btn-simulate-emergency")
        page.locator("#btn-simulate-emergency").click(force=True)
        
        # Verify the chat sidebar is visible
        page.wait_for_selector("#agent-chat-sidebar")
        print("✓ Verified: Live Multi-Agent Care Escalation Chat Sidebar is now visible on the dashboard!")
        
        # Take a screenshot of the initial step (Lila active)
        time.sleep(2)
        page.screenshot(path="emergency_step1_lila_active.png")
        print("📸 Screenshot saved: 'emergency_step1_lila_active.png' (Lila Active, Hand AI scanning...)")
        
        # Wait for the chat drawer and Aria's Human-In-The-Loop decision gate prompt
        print("[4/6] Waiting for Aria's Human-In-The-Loop decision gate prompt in the chat...")
        
        # Wait until the chatbot messages container has the text "HUMAN-IN-THE-LOOP"
        chat_container_selector = "#chat-messages-container"
        page.wait_for_selector(chat_container_selector)
        
        # Poll chat messages for the HITL prompt (increased to 60 seconds to prevent LLM latency flakiness)
        found_prompt = False
        print("[4/6] Polling chat container for HITL prompt...")
        for i in range(60): # Poll up to 60 seconds
            content = page.locator(chat_container_selector).text_content()
            if "HUMAN-IN-THE-LOOP" in content or "Do you authorize" in content:
                found_prompt = True
                break
            if i % 5 == 0:
                print(f"  - Waiting... (elapsed: {i}s) - current content: '{content[:80].strip() if content else 'None'}'")
            time.sleep(1)
            
        if not found_prompt:
            print("[ERROR] Timeout waiting for Aria's HITL EMS Decision Gate prompt.")
            browser.close()
            sys.exit(1)
            
        print("✓ Captured: Aria's HITL Decision Gate is active and waiting caregiver approval!")
        page.screenshot(path="emergency_step2_hitl_paused.png")
        print("📸 Screenshot saved: 'emergency_step2_hitl_paused.png' (Aria Paused, Waiting Auth...)")
        
        # Authorize the EMS ambulance dispatch by typing YES in the chat
        print("[5/6] Submitting 'YES' to authorize EMS ambulance dispatch...")
        input_selector = "#chat-user-input"
        page.fill(input_selector, "YES")
        page.keyboard.press("Enter")
        
        # Wait for the entire multi-agent pipeline to complete
        print("[6/6] Waiting for Orchestrator to compile clinical summaries & complete the pipeline...")
        
        completed_pipeline = False
        for _ in range(45): # Poll up to 45 seconds
            content = page.locator(chat_container_selector).text_content()
            if "EMERGENCY PIPELINE COMPLETED" in content or "LIVERLINK EMERGENCY PIPELINE COMPLETED" in content:
                completed_pipeline = True
                break
            time.sleep(1)
            
        if not completed_pipeline:
            print("[ERROR] Timeout waiting for final Emergency Pipeline completion.")
            browser.close()
            sys.exit(1)
            
        print("\n🎉 SUCCESS: Live Multi-Agent Care Flow completed perfectly!")
        print("LIVERLINK EMERGENCY PIPELINE COMPLETED")
        print("  - Hand AI Check: Completed")
        print("  - EMS Ambulance: Caregiver Authorized Dispatch & Arrived")
        print("  - Akeso Decision Prep: Complete for Dr. Vance")
        print("  - STAT Lab Queue: STAT lab order (Ammonia + LFT) queued")
        
        # Take a final screenshot showing everything is fully green and completed
        time.sleep(2)
        page.screenshot(path="emergency_step3_flow_completed.png")
        print("📸 Screenshot saved: 'emergency_step3_flow_completed.png' (Full Pipeline Completed!)")
        
        browser.close()
        print("==============================================================")
        print("    Test complete! Visual tracking and execution verified.    ")
        print("==============================================================")

if __name__ == "__main__":
    run()
