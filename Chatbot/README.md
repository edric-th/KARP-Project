# Hospital Queue Chatbot

An AI-powered chatbot for the **Hospital Queue Management App** (Nepal). It answers patient questions about using the app and provides medical triage guidance by routing patients to the right specialist.

Built with **FastAPI** + **Google Gemini** LLM.

---

## What it does

| Category | Coverage |
|---|---|
| **App & Queue** | Booking tokens, cancelling, rescheduling, queue status, wait times, notifications, finding doctors/hospitals, profile management, troubleshooting |
| **Medical Guidance** | Multi-cause symptom explanations, routes to the right specialist, identifies emergency situations and urges immediate ER/ambulance |
| **General** | Greetings, thanks, goodbye, help, chatbot info |
| **Out of Scope** | Politely declines unrelated topics (cooking, jokes, politics) |

> **Medical Disclaimer:** This chatbot provides *general guidance only* and does not constitute medical advice. For any health concern, always consult a qualified doctor. In an emergency, call an ambulance immediately (102 / 101).

---

## Architectural shift: fuzzy matching → LLM

### The old approach (rapidfuzz)

The previous version matched user messages against pre-written example phrases in each intent's JSON file using `fuzz.token_set_ratio`. It worked well for exact or near-exact phrasing but failed on:

- **Natural questions**: `"what are the reasons I'm feeling dizzy"` scored poorly because none of the intent examples phrased it that way.
- **Partial overlap**: symptoms that shared words with multiple intents (e.g., "chest" appearing in both chest pain and breathing intents) caused incorrect matches.
- **Follow-up turns**: each message was matched independently — there was no memory of what was said before.
- **Nuance**: it couldn't distinguish between "my chest hurts when I breathe deeply" (likely musculoskeletal) and "I have crushing chest pain" (cardiac emergency).

### The new approach (Google Gemini)

The intent JSON files are now **embedded as reference material in Gemini's system prompt** rather than hard matching rules. Gemini:

1. Reads the full app knowledge base (all 18 app intents with responses) to answer booking/queue questions accurately.
2. Uses its medical knowledge to explain multi-cause symptoms in natural language.
3. Maintains conversation context across turns via a rolling 5-turn history.
4. Returns structured JSON for every response, so the API contract is unchanged.

The system prompt enforces strict guardrails (see Safety Architecture below) that Gemini must follow on every response.

---

## Getting a Gemini API Key

1. Go to [Google AI Studio](https://aistudio.google.com/)
2. Sign in with a Google account
3. Click **Get API key** → **Create API key**
4. Copy the key and add it to your `.env` file:

```env
GEMINI_API_KEY=your_key_here
```

### Free tier limits

| Limit | Value |
|---|---|
| Requests per minute | 15 RPM |
| Requests per day | 1,500 RPD |
| Tokens per minute | 1,000,000 TPM |

**What happens if exceeded:** The Gemini SDK raises an exception. The chatbot catches it and returns a graceful fallback message: *"I'm having trouble processing that right now. Please try again or contact reception directly."* No crash, no data loss.

The test suite adds a 4-second delay between calls to stay within the 15 RPM limit.

---

## Safety architecture

The system prompt enforces the following guardrails on **every** Gemini call:

| Guardrail | Implementation |
|---|---|
| No diagnosis | Explicitly instructed never to name specific conditions |
| No medication advice | Explicitly prohibited from recommending drugs or dosages |
| Always refer to doctor | Every medical response must end with the disclaimer |
| Emergency detection | 11 explicit emergency trigger patterns → `is_emergency=true` + ER/ambulance instruction |
| Out-of-scope handling | Off-topic requests get a polite refusal with `intent_category="out_of_scope"` |
| Structured output | `response_mime_type="application/json"` enforces JSON-only replies |
| Low temperature | `temperature=0.3` keeps responses consistent and factual |

This is safer than a raw chatbot because the guardrails are part of the system prompt that Gemini receives on every call — they cannot be bypassed by user input alone.

---

## Project structure

```
Chatbot/
├── intents/
│   ├── app_intents.json        ← 18 app/queue intents (embedded in system prompt)
│   ├── medical_intents.json    ← 24 medical intents (reference + emergency list)
│   └── general_intents.json    ← 6 general intents
├── bot.py                      ← Gemini-powered response engine
├── main.py                     ← FastAPI application with session memory
├── demo.html                   ← Browser-based chat UI demo
├── test_chatbot.py             ← Test suite with Gemini API calls
├── chatbot_log.txt             ← Auto-created query/response log
├── requirements.txt
├── .env                        ← GEMINI_API_KEY goes here
└── README.md
```

---

## Installation

```bash
# Activate the virtual environment
source venv/bin/activate          # macOS/Linux

# Install dependencies
pip install -r requirements.txt

# Add your Gemini API key
echo "GEMINI_API_KEY=your_key_here" > .env
```

---

## Running the server

```bash
uvicorn main:app --reload --port 8001
```

The API will be live at **http://localhost:8001**

Interactive API docs: **http://localhost:8001/docs**

---

## Running the tests

```bash
python test_chatbot.py
```

Makes real Gemini API calls. Includes a 4-second inter-call delay to respect the free-tier rate limit. Covers:

- 6 queries the old rapidfuzz bot failed on (natural phrasing, multi-cause, nuance)
- App intent coverage
- Emergency detection (7 scenarios)
- Out-of-scope refusal
- Multi-turn conversation memory test

---

## Running the demo

1. Start the server
2. Open `demo.html` in any browser

Features:
- Example query chips on first load
- Session-based conversation memory (reset button in top bar)
- Animated typing indicator
- Red warning styling for emergency responses
- Intent name and confidence score shown under each bot reply

---

## API endpoints

### `POST /chatbot/query`

Send a message and receive a response. Optionally include a `session_id` for multi-turn memory.

**Request:**
```json
{
  "message": "what are the reasons I might be feeling dizzy?",
  "session_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response:**
```json
{
  "response": "Dizziness can have many causes — dehydration, inner ear issues...",
  "matched_intent_name": "dizziness_causes",
  "intent_category": "medical",
  "confidence_score": 90.0,
  "is_emergency": false,
  "disclaimer_added": true
}
```

### `POST /chatbot/reset`

Clear the conversation history for a session.

**Request:**
```json
{ "session_id": "550e8400-e29b-41d4-a716-446655440000" }
```

**Response:**
```json
{ "cleared": true, "session_id": "550e8400-e29b-41d4-a716-446655440000" }
```

### `GET /chatbot/health`

```json
{ "status": "ok", "intents_loaded": 48, "version": "2.0.0" }
```

### `GET /chatbot/intents`

Lists all intent names from the JSON files. These are now context for Gemini, not hard matching rules.

---

## Tech stack

| Package | Purpose |
|---|---|
| `fastapi` | Web framework & auto-generated API docs |
| `uvicorn` | ASGI server |
| `google-generativeai` | Google Gemini SDK |
| `python-dotenv` | Load `GEMINI_API_KEY` from `.env` |
| `pydantic` | Request/response validation |
