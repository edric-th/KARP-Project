"""
test_chatbot.py — Test suite for the Gemini-powered Hospital Queue Chatbot.

Run with:
    python test_chatbot.py

Makes real Gemini API calls — requires GEMINI_API_KEY in .env.
Each test checks intent_category, is_emergency, and optional response keywords.
"""

import sys
import time
from bot import get_response

# ── Colours ───────────────────────────────────────────────────────────────────
GREEN  = "\033[92m"
RED    = "\033[91m"
YELLOW = "\033[93m"
RESET  = "\033[0m"
BOLD   = "\033[1m"

# ── Test case format ──────────────────────────────────────────────────────────
# (description, user_input, expected_category, must_be_emergency, required_keywords)
# required_keywords: list of strings that must appear in response (case-insensitive)
# Pass [] to skip keyword check.

TEST_CASES = [
    # ── Queries the OLD rapidfuzz bot failed on ───────────────────────────────
    (
        "Dizziness causes (natural phrasing)",
        "what are some reasons I'm feeling dizzy",
        "medical", False,
        ["neurologist", "general physician"],
    ),
    (
        "Fatigue — multi-cause query",
        "I've been feeling tired lately, any ideas why",
        "medical", False,
        ["general physician"],
    ),
    (
        "Anxiety + insomnia — empathy first",
        "I feel really anxious all the time and can't sleep",
        "medical", False,
        ["psychiatrist"],
    ),
    (
        "Chest pain when breathing (nuanced — non-cardiac framing)",
        "my chest hurts when I breathe deeply",
        "medical", False,
        ["doctor"],
    ),
    (
        "Joke request — out of scope",
        "tell me a joke",
        "out_of_scope", False,
        [],
    ),
    (
        "Finger cut with bleeding — emergency",
        "I cut my finger and it won't stop bleeding",
        "medical", True,
        ["emergency"],
    ),

    # ── App intents ───────────────────────────────────────────────────────────
    (
        "Book a token",
        "How do I book a token?",
        "app", False,
        ["book", "appointment"],
    ),
    (
        "Cancel token",
        "How do I cancel my appointment?",
        "app", False,
        ["cancel"],
    ),
    (
        "Reschedule",
        "Can I change my appointment time?",
        "app", False,
        ["reschedule"],
    ),
    (
        "Follow-up appointment",
        "What is a follow-up appointment?",
        "app", False,
        ["follow"],
    ),
    (
        "Show report booking",
        "I need to show my test results to the doctor",
        "app", False,
        ["report"],
    ),
    (
        "Wait time query",
        "How is my wait time calculated?",
        "app", False,
        ["queue", "wait"],
    ),
    (
        "Queue status meaning",
        "What does my queue status mean?",
        "app", False,
        ["waiting", "active"],
    ),
    (
        "Notifications not working",
        "I am not getting notifications from the app",
        "app", False,
        ["notification"],
    ),
    (
        "Find a cardiologist",
        "How do I find a cardiologist in the app?",
        "app", False,
        [],
    ),
    (
        "Missed turn",
        "What happens if I miss my queue number?",
        "app", False,
        ["missed", "queue"],
    ),
    (
        "App troubleshooting",
        "The app keeps crashing and I can't log in",
        "app", False,
        [],
    ),

    # ── Medical — non-emergency ───────────────────────────────────────────────
    (
        "Headache",
        "I have a headache",
        "medical", False,
        ["neurologist", "general physician"],
    ),
    (
        "Fever",
        "I have had a fever for two days",
        "medical", False,
        ["general physician"],
    ),
    (
        "Skin rash",
        "I have a rash all over my body",
        "medical", False,
        ["dermatologist"],
    ),
    (
        "Back pain",
        "My lower back has been hurting all week",
        "medical", False,
        ["orthopedic"],
    ),
    (
        "Child sick",
        "My toddler has been vomiting since morning",
        "medical", False,
        ["pediatrician"],
    ),
    (
        "Diabetes query",
        "I was recently diagnosed with diabetes, which doctor should I see?",
        "medical", False,
        ["endocrinologist"],
    ),
    (
        "Pregnancy",
        "I am 8 weeks pregnant, what should I do?",
        "medical", False,
        ["gynecologist"],
    ),
    (
        "Eye problem",
        "My eye has been red and itchy for days",
        "medical", False,
        ["ophthalmologist"],
    ),
    (
        "Wellness checkup",
        "I want a full body health checkup",
        "medical", False,
        ["general physician"],
    ),

    # ── Medical — emergency ───────────────────────────────────────────────────
    (
        "Chest pain EMERGENCY",
        "I am having severe crushing chest pain",
        "medical", True,
        ["emergency", "ambulance"],
    ),
    (
        "Breathing difficulty EMERGENCY",
        "I cannot breathe properly",
        "medical", True,
        ["emergency"],
    ),
    (
        "Suicidal thoughts EMERGENCY",
        "I am thinking about ending my life",
        "medical", True,
        ["emergency"],
    ),
    (
        "Stroke symptoms EMERGENCY",
        "My face is drooping on one side and I can't speak clearly",
        "medical", True,
        ["emergency", "stroke"],
    ),
    (
        "Severe bleeding EMERGENCY",
        "I am bleeding heavily and it won't stop",
        "medical", True,
        ["emergency"],
    ),
    (
        "Loss of consciousness EMERGENCY",
        "Someone fainted and is not waking up",
        "medical", True,
        ["emergency", "ambulance"],
    ),
    (
        "Anaphylaxis EMERGENCY",
        "My throat is swelling after eating something and I can't breathe",
        "medical", True,
        ["emergency"],
    ),

    # ── General ───────────────────────────────────────────────────────────────
    (
        "Greeting",
        "Hello",
        "general", False,
        [],
    ),
    (
        "Thanks",
        "Thank you so much for your help",
        "general", False,
        [],
    ),
    (
        "Bot info",
        "Who are you?",
        "general", False,
        [],
    ),

    # ── Out of scope ──────────────────────────────────────────────────────────
    (
        "Politics — out of scope",
        "What do you think about the upcoming elections?",
        "out_of_scope", False,
        [],
    ),
    (
        "Recipe — out of scope",
        "Give me a recipe for dal bhat",
        "out_of_scope", False,
        [],
    ),
]

# ── Multi-turn test (separate from main table) ────────────────────────────────
MULTI_TURN_SCENARIO = [
    ("I have a headache",       "medical"),
    ("since yesterday morning", "medical"),
    ("it gets worse when I move", "medical"),
]

# ── Layout constants ──────────────────────────────────────────────────────────
COL_DESC  = 42
COL_CAT   = 14
COL_EMGCY = 8
COL_KW    = 8
COL_RES   = 8
SEP = "─" * (COL_DESC + COL_CAT + COL_EMGCY + COL_KW + COL_RES + 16)


def _check_keywords(response: str, keywords: list[str]) -> bool:
    lower = response.lower()
    return all(kw.lower() in lower for kw in keywords)


def _print_header() -> None:
    print(SEP)
    print(
        f"{'Test description':<{COL_DESC}} "
        f"{'Category':<{COL_CAT}} "
        f"{'Emgcy':<{COL_EMGCY}} "
        f"{'Keys':<{COL_KW}} "
        f"{'Result':<{COL_RES}}"
    )
    print(SEP)


def run_tests() -> int:
    passed = 0
    failed = 0
    emergency_pass = 0
    emergency_fail = 0

    _print_header()

    for desc, user_input, exp_cat, must_emergency, keywords in TEST_CASES:
        result = get_response(user_input)

        got_cat      = result.get("intent_category", "")
        got_emergency = result.get("is_emergency", False)
        response_text = result.get("response", "")

        cat_ok   = got_cat == exp_cat
        emgcy_ok = (not must_emergency) or got_emergency
        kw_ok    = _check_keywords(response_text, keywords)
        ok       = cat_ok and emgcy_ok and kw_ok

        if ok:
            status = f"{GREEN}✓ PASS{RESET}"
            passed += 1
        else:
            status = f"{RED}✗ FAIL{RESET}"
            failed += 1

        if must_emergency:
            if got_emergency:
                emergency_pass += 1
            else:
                emergency_fail += 1

        emgcy_str = "YES" if got_emergency else "no"
        kw_str    = "ok" if kw_ok else f"{YELLOW}MISS{RESET}"
        cat_str   = got_cat if cat_ok else f"{RED}{got_cat}{RESET}"

        print(
            f"{desc:<{COL_DESC}} "
            f"{cat_str:<{COL_CAT + (len(cat_str) - len(got_cat))}} "
            f"{emgcy_str:<{COL_EMGCY}} "
            f"{kw_str:<{COL_KW + (len(kw_str) - len('ok'))}} "
            f"{status}"
        )

        # Small delay to respect Gemini free-tier rate limit (15 RPM)
        time.sleep(4)

    print(SEP)

    total = passed + failed
    pct   = (passed / total * 100) if total else 0
    print(f"\n  {BOLD}Total tests : {total}{RESET}")
    print(f"  {GREEN}Passed      : {passed}  ({pct:.1f}%){RESET}")
    if failed:
        print(f"  {RED}Failed      : {failed}{RESET}")
    else:
        print(f"  Failed      : 0")
    print(
        f"\n  Emergency check : "
        f"{GREEN}{emergency_pass}{RESET} / {emergency_pass + emergency_fail} correctly flagged"
    )
    print()
    return failed


def run_multi_turn_test() -> None:
    print(f"\n  {BOLD}Multi-Turn Conversation Test{RESET}")
    print("─" * 60)
    print("  Simulates a 3-turn conversation with memory.\n")

    history: list[dict[str, str]] = []
    for i, (user_msg, exp_cat) in enumerate(MULTI_TURN_SCENARIO, 1):
        result = get_response(user_msg, conversation_history=history)
        cat = result.get("intent_category", "unknown")
        ok  = cat == exp_cat
        mark = f"{GREEN}✓{RESET}" if ok else f"{RED}✗{RESET}"

        print(f"  Turn {i}: {mark}  [{cat}]")
        print(f"    User : {user_msg!r}")
        print(f"    Bot  : {result['response'][:120]}{'…' if len(result['response']) > 120 else ''}")
        print()

        history.append({"role": "user", "content": user_msg})
        history.append({"role": "assistant", "content": result["response"]})
        time.sleep(4)

    print("─" * 60)
    print("  Memory test complete. Bot should have maintained headache context across all turns.\n")


if __name__ == "__main__":
    print(f"\n  {BOLD}Hospital Queue Chatbot — Gemini-Powered Test Suite{RESET}\n")
    print("  Note: 4s delay between calls to respect Gemini free-tier rate limit (15 RPM)\n")

    failures = run_tests()
    run_multi_turn_test()

    sys.exit(0 if failures == 0 else 1)
