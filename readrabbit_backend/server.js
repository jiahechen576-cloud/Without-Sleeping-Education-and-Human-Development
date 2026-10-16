
require("dotenv").config();

console.log(
  "GROQ_API_KEY loaded:",
  Boolean(process.env.GROQ_API_KEY)
);

const express = require("express");
const cors = require("cors");

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json({ limit: "1mb" }));

// Main instructions for ReadRabbit Buddy.
const systemPrompt = `
You are ReadRabbit Buddy, a friendly reading assistant
for students and people who benefit from dyslexia-friendly support.

YOUR GOAL:
Help users understand words, sentences and stories.

LANGUAGE:
- Reply in the same language as the user's question.
- Support Bahasa Melayu and English.
- Use natural, simple Bahasa Melayu.
- If the user mixes languages, respond naturally.

EXPLAINING WORDS:
For Bahasa Melayu, use:
📖 Maksud
Explain the word using simple, familiar words.

💡 Contoh
Give one short example sentence.

🌱 Senang faham
Explain the idea in an even simpler way.

For English, use:
📖 Meaning
💡 Example
🌱 In simple words

SIMPLIFICATION:
When asked to simplify an answer:
- Rewrite the answer using easier words.
- Use shorter sentences.
- Preserve the original meaning and important facts.
- Make the result noticeably easier to understand.
- Do not repeat the original answer word for word.
- Do not answer the original question from scratch.
- Do not add the original answer before the simplified version.
- Return only the simplified answer.
- Keep the same language as the supplied answer.

READING SUPPORT:
- Use short paragraphs and clear headings.
- Avoid unnecessary jargon.
- Give simple examples when useful.
- Be concise unless the user requests more detail.

CONVERSATION:
- Use the recent conversation when it is provided.
- Understand follow-up questions.
- Never assume you know an earlier answer if it was not provided.

IMPORTANT:
- Be kind, patient and encouraging.
- Never make fun of reading or spelling mistakes.
- Do not diagnose dyslexia.
- Do not invent facts when unsure.
`;

// Check that the backend is running.
app.get("/", (req, res) => {
  res.json({
    message: "ReadRabbit Buddy backend is running!",
  });
});

// Chat endpoint.
app.post("/chat", async (req, res) => {
  try {
    const {
      message,
      history = [],
      preferences = {},
      action = "chat",
      textToSimplify = "",
    } = req.body ?? {};

    // Validate the requested action.
    if (!["chat", "simplify"].includes(action)) {
      return res.status(400).json({
        error: "Unknown action. Use chat or simplify.",
      });
    }

    // Normal chat requires a message.
    if (
      action === "chat" &&
      (typeof message !== "string" || !message.trim())
    ) {
      return res.status(400).json({
        error: "Please provide a message.",
      });
    }

    // Simplification requires the actual answer.
    if (
      action === "simplify" &&
      (typeof textToSimplify !== "string" ||
        !textToSimplify.trim())
    ) {
      return res.status(400).json({
        error: "Please provide the answer to simplify.",
      });
    }

    // Check the Groq API key.
    if (!process.env.GROQ_API_KEY) {
      console.error("GROQ_API_KEY is missing from .env.");

      return res.status(500).json({
        error: "The AI service is not configured.",
      });
    }

    // Keep only valid conversation messages.
    const conversationHistory = Array.isArray(history)
      ? history
          .filter(
            (item) =>
              item &&
              ["user", "assistant"].includes(item.role) &&
              typeof item.content === "string"
          )
          .slice(-10)
          .map((item) => ({
            role: item.role,
            content: item.content.slice(0, 4000),
          }))
      : [];

    // Accessibility preferences.
    const fontSize = Number(preferences.fontSize);
    const letterSpacing = Number(preferences.letterSpacing);
    const lineSpacing = Number(preferences.lineSpacing);

    const preferencesPrompt = `
ACCESSIBILITY PREFERENCES:
- Font size: ${
      Number.isFinite(fontSize) ? fontSize : "not provided"
    }
- Letter spacing: ${
      Number.isFinite(letterSpacing)
        ? letterSpacing
        : "not provided"
    }
- Line spacing: ${
      Number.isFinite(lineSpacing)
        ? lineSpacing
        : "not provided"
    }
- High contrast: ${preferences.highContrast === true}
- Dyslexia-friendly layout: ${
      preferences.dyslexiaLayout === true
    }

Use short paragraphs and simple vocabulary.
Do not claim to change the app's visual settings.
`;

    // Build the request differently for chat and simplify.
    const messages =
      action === "simplify"
        ? [
            {
              role: "system",
              content: systemPrompt,
            },
            {
              role: "system",
              content: preferencesPrompt,
            },
            {
              role: "user",
              content: `
Simplify the following answer.

Rewrite it using easier words and shorter sentences.
Keep its original meaning and important information.
Do not repeat the original wording unnecessarily.
Do not answer the original question from scratch.
Return only the simplified answer.
Use the same language as the original answer.

ANSWER:
${textToSimplify.trim().slice(0, 4000)}
`,
            },
          ]
        : [
            {
              role: "system",
              content: systemPrompt,
            },
            {
              role: "system",
              content: preferencesPrompt,
            },
            ...conversationHistory,
            {
              role: "user",
              content: message.trim().slice(0, 4000),
            },
          ];

    console.log(`ReadRabbit Buddy action: ${action}`);

    // Send the request to Groq.
    const groqResponse = await fetch(
      "https://api.groq.com/openai/v1/chat/completions",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${process.env.GROQ_API_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "openai/gpt-oss-20b",
          messages,
          temperature: action === "simplify" ? 0.3 : 0.6,
          max_completion_tokens: 800,
        }),
      }
    );

    const data = await groqResponse.json();

    // Handle errors from Groq.
    if (!groqResponse.ok) {
      console.error(
        "Groq API error:",
        data.error?.message || groqResponse.statusText
      );

      return res.status(502).json({
        error: "The AI service could not generate a response.",
      });
    }

    const reply = data.choices?.[0]?.message?.content;

    if (typeof reply !== "string" || !reply.trim()) {
      console.error("Groq returned an empty response.");

      return res.status(502).json({
        error: "No answer was generated. Please try again.",
      });
    }

    // Keep the response compatible with Flutter.
    return res.json({
      reply: reply.trim(),
    });
  } catch (error) {
    console.error("Chat endpoint error:", error.message);

    return res.status(500).json({
      error: "Something went wrong while processing your message.",
    });
  }
});

/* ==========================================
   AI STORY ADVENTURE
   Separate endpoint — keeps /chat unchanged
========================================== */

app.post("/story", async (req, res) => {
  try {
const {
  topic,
  language = "English",
  difficulty = "Easy",
  questionCount = 5,
} = req.body ?? {};

// Validate the requested number of questions.
if (![3, 5, 10].includes(questionCount)) {
  return res.status(400).json({
    error: "Question count must be 3, 5, or 10.",
  });
}

    // Validate topic.
    if (
      typeof topic !== "string" ||
      !topic.trim() ||
      topic.trim().length > 120
    ) {
      return res.status(400).json({
        error: "Please provide a topic of up to 120 characters.",
      });
    }

    // Validate language.
    if (!["English", "Bahasa Melayu"].includes(language)) {
      return res.status(400).json({
        error: "Language must be English or Bahasa Melayu.",
      });
    }

    // Validate difficulty.
    if (!["Easy", "Medium", "Advanced"].includes(difficulty)) {
      return res.status(400).json({
        error: "Difficulty must be Easy, Medium, or Advanced.",
      });
    }

    // Check that the AI service is configured.
    if (!process.env.GROQ_API_KEY) {
      console.error("GROQ_API_KEY is missing from .env.");

      return res.status(500).json({
        error: "The AI service is not configured.",
      });
    }

    const storyPrompt = `
You are ReadRabbit Story Adventure, a friendly
story creator for children, students, and people
who benefit from dyslexia-friendly reading support.

Create an original, engaging and age-appropriate story.

STORY SETTINGS:
- Topic: ${topic.trim()}
- Language: ${language}
- Difficulty: ${difficulty}

DIFFICULTY GUIDANCE:
- Easy: Short sentences, familiar words, simple events.
- Medium: Slightly longer sentences and a clear plot.
- Advanced: Richer vocabulary and more complex events,
  while remaining accessible and age-appropriate.

ACCESSIBILITY:
- Use clear language and short paragraphs.
- Avoid unnecessarily complicated sentence structures.
- Use a positive, encouraging tone.
- Do not diagnose dyslexia.
- Do not include frightening or graphic content.

LANGUAGE:
- Write the entire story in the selected language.
- If Bahasa Melayu is selected, use natural Bahasa Melayu.
- Keep the questions and answer options in that language too.

RETURN FORMAT:
Return ONLY valid JSON. Do not use Markdown fences.

Use exactly this structure:
{
  "title": "Story title",
  "story": "The complete story, with paragraphs separated by newline characters.",
  "questions": [
    {
      "question": "A question about the story",
      "options": [
        "First answer",
        "Second answer",
        "Third answer",
        "Fourth answer"
      ],
      "correctAnswer": 0,
      "explanation": "A short explanation of the correct answer."
    }
  ]
}

QUESTION RULES:
- Create exactly ${questionCount} questions.
- Each question must have exactly 4 answer options.
- correctAnswer must be an integer from 0 to 3,
  representing the correct option's zero-based index.
- Questions must be answerable from the story.
- Include a brief explanation for each answer.
- Make the story complete, with a clear ending.
`;

 console.log(
  `AI Story Adventure: ${language}, ${difficulty}, ` +
  `${questionCount} questions`
);

    // Use the same Groq API connection as ReadRabbit Buddy.
    const groqResponse = await fetch(
      "https://api.groq.com/openai/v1/chat/completions",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${process.env.GROQ_API_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "openai/gpt-oss-20b",
          messages: [
            {
              role: "system",
              content:
                "You generate accessible stories and valid JSON. Follow the requested schema exactly.",
            },
            {
              role: "user",
              content: storyPrompt,
            },
          ],
          temperature: 0.7,
          max_completion_tokens: 2500,
        }),
      }
    );

    const data = await groqResponse.json();

    if (!groqResponse.ok) {
      console.error(
        "Groq story error:",
        data.error?.message || groqResponse.statusText
      );

      return res.status(502).json({
        error: "The AI could not generate a story. Please try again.",
      });
    }

    const content = data.choices?.[0]?.message?.content;

    if (typeof content !== "string" || !content.trim()) {
      return res.status(502).json({
        error: "The AI returned an empty story.",
      });
    }

    // Parse and validate the generated JSON.
    let storyData;

    try {
      const cleanedContent = content
        .trim()
        .replace(/^```(?:json)?\s*/i, "")
        .replace(/\s*```$/, "");

      storyData = JSON.parse(cleanedContent);
    } catch (error) {
      console.error("Invalid story JSON:", error.message);

      return res.status(502).json({
        error: "The AI returned an invalid story format. Please try again.",
      });
    }

    // Check the required story fields.
    if (
      typeof storyData.title !== "string" ||
      !storyData.title.trim() ||
      typeof storyData.story !== "string" ||
      !storyData.story.trim() ||
      !Array.isArray(storyData.questions) ||
      storyData.questions.length !== questionCount
    ) {
      return res.status(502).json({
        error: "The generated story was incomplete. Please try again.",
      });
    }

    // Validate all comprehension questions.
    const validQuestions = storyData.questions.every((question) =>
      question &&
      typeof question.question === "string" &&
      question.question.trim() &&
      Array.isArray(question.options) &&
      question.options.length === 4 &&
      question.options.every(
        (option) =>
          typeof option === "string" && option.trim()
      ) &&
      Number.isInteger(question.correctAnswer) &&
      question.correctAnswer >= 0 &&
      question.correctAnswer <= 3 &&
      typeof question.explanation === "string" &&
      question.explanation.trim()
    );

    if (!validQuestions) {
      return res.status(502).json({
        error: "The generated questions were incomplete. Please try again.",
      });
    }

    // Return a predictable response for Flutter.
    return res.json({
      title: storyData.title.trim(),
      story: storyData.story.trim(),
      language,
      difficulty,
      questions: storyData.questions.map((question) => ({
        question: question.question.trim(),
        options: question.options.map((option) => option.trim()),
        correctAnswer: question.correctAnswer,
        explanation: question.explanation.trim(),
      })),
    });
  } catch (error) {
    console.error("Story endpoint error:", error.message);

    return res.status(500).json({
      error: "Something went wrong while generating the story.",
    });
  }
});

// Start the server.
app.listen(PORT, "0.0.0.0", () => {
  console.log(`ReadRabbit Buddy is running on port ${PORT}`);
});
