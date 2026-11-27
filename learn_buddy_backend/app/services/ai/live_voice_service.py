import asyncio
import base64
import os
import json
from typing import Dict, Any, Optional
from fastapi import WebSocket, WebSocketDisconnect
from google import genai
from google.genai import types

from app.services.ai.gemini_service import get_gemini_client, SA_PATH, GCP_PROJECT_ID, GCP_LOCATION
from app.services.ai.rag_service import rag_service

class UnifiedLiveAudioSession:
    """
    Gemini Live Audio Session for Learn Buddy Voice Mentor:
    - Real-time bidirectional voice conversation
    - Pinecone Career Grounding tool access
    - Student details & subject context aware
    """
    def __init__(
        self,
        websocket: WebSocket,
        mode: str = "mentor",
        language: str = "hi",
        voice: str = "Puck",
        student_name: str = "Student",
        student_class: int = 10,
        stream: Optional[str] = None,
        category: str = "average",
    ):
        self.ws = websocket
        self.mode = mode
        self.language = language
        self.voice = voice
        self.student_name = student_name
        self.student_class = student_class
        self.stream = stream
        self.category = category
        self.live_model = "gemini-live-2.5-flash-native-audio"
        self.is_running = False

    async def run(self):
        client = get_gemini_client()

        # Tool 1: Pinecone Career Guidance Tool
        career_tool = types.Tool(
            function_declarations=[
                types.FunctionDeclaration(
                    name="get_career_guidance",
                    description="Call this whenever the student asks about careers, future jobs, college options, entrance exams, or streams. Returns real grounded career options from Pinecone database.",
                    parameters=types.Schema(
                        type=types.Type.OBJECT,
                        properties={
                            "query": types.Schema(
                                type=types.Type.STRING,
                                description="The specific career topic, stream, or question asked by the student."
                            )
                        },
                        required=["query"]
                    )
                )
            ]
        )

        sys_prompt = f"""You are Buddy, the personal Voice AI Study & Career Mentor for {self.student_name} (Class {self.student_class}, Stream: {self.stream or 'General'}, Performance Tier: {self.category}).
You have direct access to a verified Career Database via the 'get_career_guidance' tool. Whenever the student asks about career options, future jobs, colleges, or competitive exams (JEE, NEET, CUET, CA, NDA), call the 'get_career_guidance' tool silently to ground your answer in verified data.
Keep your voice responses warm, encouraging, conversational, and concise (under 2-3 clear sentences per turn).
Speak in natural {self.language.upper()} / Hinglish. Address {self.student_name} respectfully and helpfully."""

        config = types.LiveConnectConfig(
            response_modalities=[types.Modality.AUDIO],
            system_instruction=types.Content(
                parts=[types.Part.from_text(text=sys_prompt)]
            ),
            speech_config=types.SpeechConfig(
                voice_config=types.VoiceConfig(
                    prebuilt_voice_config=types.PrebuiltVoiceConfig(
                        voice_name=self.voice
                    )
                )
            ),
            tools=[career_tool]
        )

        try:
            async with client.aio.live.connect(model=self.live_model, config=config) as session:
                self.is_running = True
                await self.ws.send_json({
                    "type": "session_connected",
                    "mode": self.mode,
                    "model": self.live_model,
                })

                self.initial_greeting_done = False
                greeting_text = f"नमस्ते {self.student_name}! मैं आपका Study & Career Mentor Buddy हूँ। आज हम कौन सा टॉपिक या करियर पाथवे डिस्कस करें?" if self.language == "hi" else f"Hello {self.student_name}! I'm your Study & Career Mentor Buddy. What would you like to learn or explore today?"

                recv_task = asyncio.create_task(self._browser_to_gemini(session))
                send_task = asyncio.create_task(self._gemini_to_browser(session))

                # Greet user out loud
                await session.send(input=f"Say this exact greeting out loud to welcome {self.student_name}: '{greeting_text}'", end_of_turn=True)

                done, pending = await asyncio.wait(
                    [recv_task, send_task],
                    return_when=asyncio.FIRST_COMPLETED
                )

                for task in pending:
                    task.cancel()

        except Exception as e:
            print(f"[GeminiLive] Connection error: {e}")
            await self.ws.send_json({"type": "error", "message": f"Gemini Live session error: {str(e)}"})
        finally:
            self.is_running = False

    async def _browser_to_gemini(self, session):
        while self.is_running:
            try:
                data = await self.ws.receive_json()
                msg_type = data.get("type")

                if msg_type == "audio_chunk":
                    if not getattr(self, "initial_greeting_done", False):
                        continue
                    b64_audio = data.get("data", "")
                    if b64_audio:
                        pcm_bytes = base64.b64decode(b64_audio)
                        await session.send(
                            input=types.LiveClientRealtimeInput(
                                media_chunks=[
                                    types.Blob(
                                        mime_type="audio/pcm;rate=16000",
                                        data=pcm_bytes
                                    )
                                ]
                            )
                        )
                elif msg_type == "text_prompt":
                    text = data.get("text", "")
                    if text:
                        await session.send(input=text, end_of_turn=True)
                elif msg_type == "ping":
                    await self.ws.send_json({"type": "pong"})
            except WebSocketDisconnect:
                self.is_running = False
                break
            except Exception as e:
                print(f"[GeminiLive] Error forwarding audio to Gemini: {e}")
                break

    async def _gemini_to_browser(self, session):
        while self.is_running:
            try:
                async for response in session.receive():
                    server_content = response.server_content
                    tool_call = response.tool_call

                    # 1. Execute Pinecone Career Guidance Tool call
                    if tool_call is not None:
                        for call in tool_call.function_calls:
                            if call.name == "get_career_guidance":
                                query_val = str(call.args.get("query", "engineering"))
                                print(f"[GeminiLive] Querying Pinecone for: {query_val}")
                                matches = rag_service.query_namespace(query_val, namespace="careers", top_k=3)
                                result_text = ""
                                if matches:
                                    items = []
                                    for m in matches:
                                        meta = m.get("metadata", {})
                                        title = meta.get("career_title", meta.get("title", ""))
                                        desc = meta.get("description", meta.get("text", ""))
                                        exams = meta.get("entrance_exams", "")
                                        items.append(f"{title}: {desc} (Exams: {exams})")
                                    result_text = "\n".join(items)
                                else:
                                    result_text = "Standard paths: B.Tech, MBBS, B.Com, BA, CA, NDA."

                                await self.ws.send_json({
                                    "type": "tool_executed",
                                    "tool": "get_career_guidance",
                                    "query": query_val,
                                })

                                # Send tool response back to Gemini
                                await session.send(
                                    input=types.LiveClientToolResponse(
                                        function_responses=[
                                            types.FunctionResponse(
                                                name=call.name,
                                                id=call.id,
                                                response={"careers": result_text}
                                            )
                                        ]
                                    )
                                )

                    # 2. Audio & Transcript streaming to frontend
                    if server_content is not None:
                        if getattr(server_content, "interrupted", False):
                            await self.ws.send_json({"type": "interrupted"})

                        model_turn = server_content.model_turn
                        if model_turn is not None:
                            for part in model_turn.parts:
                                if part.inline_data and part.inline_data.data:
                                    audio_b64 = base64.b64encode(part.inline_data.data).decode("utf-8")
                                    await self.ws.send_json({
                                        "type": "audio_out",
                                        "mime": part.inline_data.mime_type or "audio/pcm;rate=24000",
                                        "data": audio_b64
                                    })
                                if part.text:
                                    await self.ws.send_json({
                                        "type": "transcript",
                                        "text": part.text
                                    })

                        if getattr(server_content, "turn_complete", False):
                            self.initial_greeting_done = True
                            await self.ws.send_json({
                                "type": "turn_complete",
                            })
            except asyncio.CancelledError:
                break
            except Exception as e:
                print(f"[GeminiLive] Error receiving from Gemini Live: {e}")
                break
