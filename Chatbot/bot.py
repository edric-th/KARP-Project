"""
Hospital Queue Chatbot — Gemini-powered matching engine.

Replaces the rapidfuzz fuzzy-matching approach with a Gemini LLM call.
The intent JSON files are embedded in the system prompt as reference material
rather than rigid matching rules, allowing natural language understanding.

Spelling tolerance:
    A lightweight _preprocess_message() step runs before every Gemini call.
    It uses difflib (stdlib) to detect likely misspelled medical terms and
    appends correction hints to the message so Gemini can resolve ambiguity
    confidently.  No extra packages, no extra API calls.
"""

import difflib
import json
import logging
import os
import re
from datetime import datetime
from pathlib import Path
from typing import Any

from google import genai
from google.genai import types
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger(__name__)

# ── Constants ──────────────────────────────────────────────────────────────────
_INTENTS_DIR = Path(__file__).parent / "intents"
_LOG_FILE = Path(__file__).parent / "chatbot_log.txt"
_GEMINI_MODEL = "gemini-2.5-flash"
_MAX_HISTORY_TURNS = 5

_FALLBACK_RESPONSE: dict[str, Any] = {
    "response": (
        "I'm having trouble processing that right now. "
        "Please try again or contact reception directly."
    ),
    "matched_intent_name": None,
    "intent_category": "general",
    "confidence_score": 0.0,
    "is_emergency": False,
    "disclaimer_added": False,
}

# ── Medical vocabulary for spelling-tolerance pre-processing ──────────────────
# Covers diseases, symptoms, and body parts commonly mentioned by Nepali users.
# difflib fuzzy-matches user words against this list and attaches hints to the
# Gemini message so the LLM can resolve the correct term even if the user
# spelled it phonetically or partially.
_MEDICAL_VOCAB: list[str] = [
    # Diseases / conditions
    "diabetes", "hypertension", "migraine", "pneumonia", "tuberculosis",
    "typhoid", "malaria", "dengue", "jaundice", "cholera", "appendicitis",
    "hepatitis", "anemia", "anaemia", "arthritis", "eczema", "psoriasis",
    "conjunctivitis", "bronchitis", "sinusitis", "gastritis", "meningitis",
    "epilepsy", "vertigo", "anaphylaxis", "tonsillitis", "chickenpox",
    "measles", "mumps", "scabies", "ringworm", "asthma", "diarrhea",
    "diarrhoea", "dysentery", "malnutrition", "obesity", "osteoporosis",
    "hypothyroidism", "hyperthyroidism", "schizophrenia", "dementia",
    "parkinson", "alzheimer",
    # Symptoms
    "headache", "dizziness", "nausea", "vomiting", "constipation", "fatigue",
    "weakness", "trembling", "swelling", "itching", "bleeding", "breathlessness",
    "palpitation", "seizure", "unconscious", "insomnia", "depression", "anxiety",
    "fever", "cough", "rash", "infection", "inflammation", "dehydration",
    "numbness", "paralysis", "jaundice", "haemorrhage", "hemorrhage",
    "indigestion", "heartburn", "bloating", "cramps",
    # Body parts
    "stomach", "abdomen", "chest", "throat", "kidney", "liver", "heart",
    "lungs", "brain", "spine", "joints", "muscles", "tendons", "ligaments",
    "pancreas", "gallbladder", "intestine", "colon", "rectum", "uterus",
    "ovary", "prostate", "bladder", "appendix",
    # Specialisations (users sometimes try to name these)
    "cardiologist", "neurologist", "dermatologist", "gastroenterologist",
    "ophthalmologist", "orthopedic", "pulmonologist", "psychiatrist",
    "pediatrician", "gynecologist", "obstetrician", "endocrinologist",
    "dentist", "allergist", "immunologist",
]


def _preprocess_message(user_message: str) -> str:
    """
    Detect likely misspelled medical/symptom words and append correction hints
    so Gemini can resolve them confidently.

    Strategy
    --------
    * Split the message into tokens, strip punctuation from each.
    * Skip tokens that are stop-words, numbers, or very short.
    * Run difflib.get_close_matches against _MEDICAL_VOCAB with cutoff=0.78.
    * If the closest match differs from the token, record it as a hint.
    * Append a single bracketed note to the message (does not alter the
      original phrasing — Gemini still sees what the user typed).

    Returns the original message unchanged when no corrections are found.
    """
    # Very common words we don't want to fuzzy-match against medical terms
    _STOP = {
        "have", "from", "with", "that", "this", "been", "feel", "felt",
        "some", "when", "what", "your", "mine", "also", "just", "help",
        "like", "much", "many", "does", "will", "into", "about", "them",
        "they", "then", "than", "very", "more", "since", "days", "week",
        "friend", "name", "called", "person", "people", "told", "said",
        "pain", "ache", "hurt", "sick", "body", "blood", "head", "back",
        "nose", "hand", "foot", "face", "side", "legs", "arms", "left",
        "right", "both", "skin", "eyes", "ears", "teeth", "gums", "neck",
        "knee", "bone", "high", "lower", "upper", "long", "last", "past",
    }

    tokens = re.findall(r"[A-Za-z]+", user_message.lower())
    hints: list[str] = []
    seen: set[str] = set()

    for token in tokens:
        if len(token) < 5 or token in _STOP or token in seen:
            continue
        seen.add(token)

        # Skip if the token is already an exact vocab word
        if token in _MEDICAL_VOCAB:
            continue

        matches = difflib.get_close_matches(token, _MEDICAL_VOCAB, n=1, cutoff=0.78)
        if matches:
            best = matches[0]
            # Guard: skip if the word lengths are too different (e.g. "ramesh" ≠ "rash").
            # Require the shorter word to be at least 75 % the length of the longer.
            length_ratio = min(len(token), len(best)) / max(len(token), len(best))
            if length_ratio >= 0.75:
                hints.append(f"'{token}' → '{best}'")

    if hints:
        note = " [spelling hints: " + ", ".join(hints) + "]"
        return user_message + note

    return user_message

# ── Intent loading (kept for /chatbot/intents endpoint) ───────────────────────
def _load_intents() -> dict[str, list[dict[str, Any]]]:
    result: dict[str, list[dict[str, Any]]] = {}
    for filename in ["app_intents.json", "medical_intents.json", "general_intents.json"]:
        filepath = _INTENTS_DIR / filename
        if filepath.exists():
            with filepath.open(encoding="utf-8") as fh:
                data = json.load(fh)
            result[data["category"]] = data.get("intents", [])
    return result


_ALL_INTENTS = _load_intents()


# ── Build system prompt (once at import) ──────────────────────────────────────
def _read_json(filename: str) -> str:
    p = _INTENTS_DIR / filename
    return p.read_text(encoding="utf-8") if p.exists() else "{}"


def _build_system_prompt() -> str:
    app_json = _read_json("app_intents.json")
    return f"""You are a helpful chatbot for a hospital queue management app in Nepal. \
You help users with the app and provide basic health guidance.

## WHAT YOU CAN DO
- Answer questions about booking tokens, queues, and app features
- Discuss symptoms in general terms (causes, when to worry)
- Route users to appropriate doctor specializations
- Provide general wellness information
- Have natural conversations about health concerns
- Acknowledge emotions empathetically before giving advice

## WHAT YOU MUST NOT DO
- Never diagnose specific conditions
- Never recommend specific medications or dosages
- Never tell users to skip seeing a doctor
- Never discuss topics unrelated to health or the app (cooking, sports, politics, jokes, etc.)

## LANGUAGE & SPELLING TOLERANCE — Nepal Context (VERY IMPORTANT)
This chatbot serves patients in Nepal. Many users speak English as a second or \
third language and may make spelling mistakes or write in broken English. \
You MUST handle all of the following gracefully:

**Spelling mistakes in medical terms** — always infer the most likely intended word:
- "dibetes" / "diabetis" / "diabettes" → diabetes
- "hpertension" / "hypertenshon" / "hi blood pressure" → hypertension
- "migrane" / "migren" / "migrayne" → migraine
- "pnemonia" / "neumonia" / "nuemonia" → pneumonia
- "diarhoea" / "diarrea" / "diarehea" → diarrhea
- "asma" / "ashma" / "asthma" → asthma
- "tubercolosis" / "tbculosis" / "TB" → tuberculosis
- "conjuctivitis" / "conjunctivitus" → conjunctivitis
- "apendix" / "appendicitus" → appendicitis
- "artritis" / "arthritus" → arthritis
- "exzema" / "eczima" → eczema
- "vertgio" / "vartigo" → vertigo
- "epilepsey" / "epilipsy" → epilepsy
- "hapatitis" / "hepatitus" → hepatitis
- "thayroid" / "thyrod" → thyroid
- "tonsilities" / "tonsillitis" → tonsillitis
When the message includes [spelling hints: …] tags, use those to confirm your \
interpretation — but NEVER include or mention the tags in your reply.

**Broken / non-native English** — always try to understand the intent:
- "my head is pain since 2 day" → "I've had a headache for 2 days"
- "since 3-4 days stomach is not good" → stomach issues for several days
- "I am having fever from morning" → has had a fever since this morning
- "my body is pain everywhere" → widespread body pain / aches
- "she is not eating from 2 days" → hasn't eaten for 2 days
- "he is doing vomit again and again" → repeated vomiting
- "urine is burning" → burning sensation during urination (UTI symptoms)
- Missing articles, wrong tenses, direct translations — interpret charitably

**Asking about someone else** — if the user says "my friend Ramesh has X" or \
"my mother is suffering from X", treat the health concern as real and respond \
with the same care as if the user themselves had X.

**Mixed / partial names** — accept phonetic spellings, partial names, or \
abbreviations: "TB" = tuberculosis, "BP" = blood pressure, "sugar" = diabetes, \
"gas" or "gas problem" = acidity/gastritis, "pressure" = blood pressure.

**Common Nepali-English patterns to understand:**
- "joro" = fever, "khansi" = cough, "tauko dukhyo" = headache,
  "pet dukhyo" = stomach ache, "rato aankhaa" = red eyes,
  "safaa faalnu" = vomiting, "neend naaunu" = insomnia,
  "chhati dukhyo" = chest pain, "sas pherna garo" = difficulty breathing
  Respond in English even if a Nepali word appears in the message.

**Rule:** Never ask the user to rephrase or re-spell. Always make your best \
effort to understand and respond helpfully.

## AVAILABLE DOCTOR SPECIALIZATIONS
Route symptoms to the appropriate specialist:
- General Physician: general symptoms, fatigue, flu, routine check-ups
- Cardiologist: heart issues, chest pain, blood pressure, palpitations
- Neurologist: headache, dizziness, seizures, stroke, numbness
- Dermatologist: skin rash, acne, eczema, psoriasis
- Gastroenterologist: stomach pain, digestive issues, vomiting, diarrhea
- Ophthalmologist: eye pain, vision problems, eye infections
- Orthopedic Specialist: bones, joints, back pain, sports injuries
- Pulmonologist: lungs, breathing difficulties, chronic cough
- Psychiatrist: mental health, anxiety, depression, sleep disorders
- Pediatrician: children's health (infants through teenagers)
- Gynecologist/Obstetrician: women's health, pregnancy, menstrual issues
- ENT Specialist: ear, nose, throat, sinuses
- Dentist: dental and gum problems
- Endocrinologist: diabetes, thyroid, hormones, metabolic issues

## EMERGENCY TRIGGERS — set is_emergency=true
Treat the following as emergencies:
- Severe chest pain or crushing/squeezing pressure
- Difficulty breathing at rest or severe breathlessness
- Stroke symptoms: face drooping, sudden arm weakness, slurred speech
- Uncontrolled or heavy bleeding that won't stop
- Loss of consciousness or unresponsiveness
- Severe allergic reaction (anaphylaxis): throat swelling, cannot breathe
- Suicidal thoughts or intent to self-harm
- Vomiting blood
- Sudden worst-ever headache ("thunderclap headache")
- Active seizures
- High fever with stiff neck (possible meningitis)

For all emergencies include: "This may need emergency care — please go to the nearest \
emergency room or call an ambulance immediately (102 / 101)."

## APP KNOWLEDGE
The following JSON contains all app-related intents — use this to answer any \
question about booking, queue management, notifications, profiles, etc.:

{app_json}

## TONE AND STYLE
- Empathetic, clear, conversational
- Use simple language suitable for patients in Nepal
- If someone expresses anxiety, fear, or distress — acknowledge their feelings first, \
then offer guidance
- Never be robotic. Respond like a caring health assistant who genuinely wants to help.

## HANDLING MULTI-CAUSE QUERIES
For questions like "what are the reasons for X" or "why am I feeling Y":
1. List 2–4 common causes in plain language
2. Recommend the appropriate specialist
3. Mention when it becomes an emergency

Example for dizziness:
"Dizziness can have many causes — dehydration, inner ear issues (like vertigo), \
low blood pressure, anxiety, or medication side effects. Most are manageable, but some \
need evaluation. I'd suggest seeing a Neurologist or General Physician if it persists \
or keeps coming back. Seek emergency care immediately if dizziness comes with chest pain, \
one-sided weakness, or difficulty speaking."

## DISCLAIMER RULE
Every response that touches on medical symptoms, health conditions, or physical wellbeing \
must end with: "Please consult a qualified doctor for proper evaluation."
Set disclaimer_added=true for those responses.

## OUT OF SCOPE
For cooking, sports, politics, jokes, entertainment, or any topic unrelated to health \
or the hospital app, respond:
"I'm focused on helping with hospital app questions and basic health guidance. \
Is there something I can help with on those topics?"
Set intent_category="out_of_scope".

## REQUIRED OUTPUT FORMAT
Respond with valid JSON ONLY — no markdown code fences, no extra text before or after:
{{
  "response": "the full reply to show the user",
  "matched_intent_name": "short_snake_case_topic_label",
  "intent_category": "app",
  "confidence_score": 85,
  "is_emergency": false,
  "disclaimer_added": false
}}

Field rules:
- intent_category: MUST be exactly one of "app", "medical", "general", "out_of_scope"
- confidence_score: integer 0–100 reflecting how clearly the query maps to a category
- is_emergency: true only for genuine life-threatening situations listed above
- disclaimer_added: true whenever the doctor consultation disclaimer is included
- matched_intent_name: concise snake_case label, e.g. "dizziness_causes", "book_token"
"""


_SYSTEM_PROMPT = _build_system_prompt()

# ── Configure Gemini client ────────────────────────────────────────────────────
_api_key = os.getenv("GEMINI_API_KEY", "")
_client: genai.Client | None = None

if _api_key:
    _client = genai.Client(
        api_key=_api_key,
        http_options=types.HttpOptions(timeout=10_000),  # 10-second timeout
    )
else:
    logger.warning("GEMINI_API_KEY not set — all responses will be fallback")

_gen_config = types.GenerateContentConfig(
    system_instruction=_SYSTEM_PROMPT,
    temperature=0.3,
    max_output_tokens=600,
    response_mime_type="application/json",
)


# ── Logging helper ─────────────────────────────────────────────────────────────
def _log(user_message: str, result: dict[str, Any]) -> None:
    try:
        ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        line = (
            f"[{ts}] USER: {user_message!r}\n"
            f"[{ts}] BOT : intent={result.get('matched_intent_name')} "
            f"category={result.get('intent_category')} "
            f"emergency={result.get('is_emergency')} "
            f"confidence={result.get('confidence_score')}\n"
            f"[{ts}] RESP: {str(result.get('response', ''))[:200]}\n"
            + "─" * 80 + "\n"
        )
        with _LOG_FILE.open("a", encoding="utf-8") as fh:
            fh.write(line)
    except Exception as exc:  # noqa: BLE001
        logger.warning("Log write failed: %s", exc)


# ── Public API ─────────────────────────────────────────────────────────────────
def get_response(
    user_message: str,
    conversation_history: list[dict[str, str]] | None = None,
) -> dict[str, Any]:
    """
    Send *user_message* to Gemini and return a structured response dict.

    Parameters
    ----------
    user_message:
        Raw text from the user.
    conversation_history:
        Optional list of ``{"role": "user"|"assistant", "content": "..."}`` dicts
        representing recent turns. Last 5 turns are passed to Gemini.

    Returns
    -------
    dict with keys:
        response            (str)
        matched_intent_name (str | None)
        intent_category     ("app" | "medical" | "general" | "out_of_scope")
        confidence_score    (float, 0–100)
        is_emergency        (bool)
        disclaimer_added    (bool)
    """
    if not user_message or not user_message.strip():
        return {**_FALLBACK_RESPONSE, "matched_intent_name": "fallback"}

    if _client is None:
        return {**_FALLBACK_RESPONSE}

    try:
        # ── Spelling tolerance: attach correction hints for Gemini ─────────────
        # _preprocess_message() never changes the displayed text — it only appends
        # a bracketed hint that Gemini uses internally to resolve ambiguous terms.
        # We log the original message so users always see what they actually typed.
        enriched_message = _preprocess_message(user_message.strip())

        # Build Gemini chat history from recent conversation turns
        history: list[types.Content] = []
        if conversation_history:
            for turn in conversation_history[-(_MAX_HISTORY_TURNS * 2):]:
                role = "model" if turn.get("role") == "assistant" else "user"
                history.append(
                    types.Content(role=role, parts=[types.Part(text=turn.get("content", ""))])
                )

        chat = _client.chats.create(
            model=_GEMINI_MODEL,
            config=_gen_config,
            history=history,
        )
        gemini_response = chat.send_message(enriched_message)

        parsed: dict[str, Any] = json.loads(gemini_response.text.strip())

        result: dict[str, Any] = {
            "response": str(parsed.get("response", "")),
            "matched_intent_name": parsed.get("matched_intent_name") or None,
            "intent_category": parsed.get("intent_category", "general"),
            "confidence_score": float(parsed.get("confidence_score", 0)),
            "is_emergency": bool(parsed.get("is_emergency", False)),
            "disclaimer_added": bool(parsed.get("disclaimer_added", False)),
        }

        valid_categories = {"app", "medical", "general", "out_of_scope"}
        if result["intent_category"] not in valid_categories:
            result["intent_category"] = "general"

        result["confidence_score"] = max(0.0, min(100.0, result["confidence_score"]))

        _log(user_message, result)
        return result

    except json.JSONDecodeError as exc:
        logger.error("Failed to parse Gemini JSON: %s", exc)
    except Exception as exc:  # noqa: BLE001
        logger.error("Gemini API error: %s", exc)

    _log(user_message, _FALLBACK_RESPONSE)
    return {**_FALLBACK_RESPONSE}


def get_all_intents() -> list[dict[str, Any]]:
    """Lightweight intent summary for the /chatbot/intents debug endpoint."""
    summaries: list[dict[str, Any]] = []
    for category, intents in _ALL_INTENTS.items():
        for intent in intents:
            summaries.append({
                "name": intent["name"],
                "category": category,
                "example_count": len(intent.get("examples", [])),
                "is_emergency": intent.get("is_emergency", False),
            })
    return summaries
