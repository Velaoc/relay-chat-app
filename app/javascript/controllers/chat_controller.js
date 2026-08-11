import { Controller } from "@hotwired/stimulus"

// Streams assistant replies from the messages endpoint as they arrive.
// Uses fetch + ReadableStream against the SSE-shaped response so the
// POST body (the message) is preserved — EventSource can't POST.
export default class extends Controller {
  static targets = ["thread", "form", "input", "submit"]

  connect() {
    this.abortController = null
    if (this.hasThreadTarget) {
      this.scrollThread()
    }
  }

  submit(event) {
    event.preventDefault()
    const form = this.formTarget
    const input = this.inputTarget
    const content = input.value.trim()
    if (!content) return

    // Optimistically render the user message.
    this.appendMessage("user", content)
    input.value = ""
    this.resizeInput()
    this.setBusy(true)

    const formData = new FormData(form)
    const url = form.action

    this.abortController = new AbortController()

    fetch(url, {
      method: "POST",
      headers: { "Accept": "text/event-stream" },
      body: formData,
      signal: this.abortController.signal,
      credentials: "same-origin"
    })
      .then((response) => {
        if (!response.ok || !response.body) {
          throw new Error(`Request failed: ${response.status}`)
        }
        const reader = response.body.getReader()
        const decoder = new TextDecoder()
        const assistant = this.appendMessage("assistant", "")
        let buffer = ""

        const pump = () => {
          return reader.read().then(({ done, value }) => {
            if (done) {
              this.finish(assistant)
              return
            }
            buffer += decoder.decode(value, { stream: true })
            // SSE events end with a blank line; a data: line is one event.
            const events = buffer.split("\n\n")
            buffer = events.pop()
            events.forEach((event) => this.handleEvent(event, assistant))
            this.scrollThread()
            return pump()
          })
        }

        return pump().catch((error) => {
          if (error.name !== "AbortError") this.fail(assistant, error)
        })
      })
      .catch((error) => {
        if (error.name !== "AbortError") this.fail(null, error)
      })
  }

  handleEvent(eventText, assistant) {
    const dataLine = eventText.split("\n").find((l) => l.startsWith("data: "))
    if (!dataLine) return
    const data = dataLine.slice(6).trim()
    if (!data) return

    if (data.startsWith("{") || data.startsWith("\"")) {
      try {
        const parsed = JSON.parse(data)
        if (typeof parsed === "string") {
          assistant.dataset.content = (assistant.dataset.content || "") + parsed
          this.renderAssistant(assistant)
        } else if (parsed && typeof parsed.content === "string") {
          // user_message event with the persisted message JSON
          if (parsed.role === "user") {
            // already rendered optimistically; nothing to do
          }
        }
      } catch (e) {
        // not JSON — treat as plain text chunk
        assistant.dataset.content = (assistant.dataset.content || "") + data
        this.renderAssistant(assistant)
      }
    } else {
      assistant.dataset.content = (assistant.dataset.content || "") + data
      this.renderAssistant(assistant)
    }
  }

  renderAssistant(assistant) {
    const bubble = assistant.querySelector(".chat-msg__bubble")
    if (bubble) bubble.textContent = assistant.dataset.content || ""
    else assistant.textContent = assistant.dataset.content || ""
  }

  appendMessage(role, content) {
    const thread = this.threadTarget
    const article = document.createElement("article")
    article.className = `chat-msg chat-msg--${role}`
    article.dataset.role = role
    article.dataset.content = content
    const avatar = document.createElement("div")
    avatar.className = "chat-msg__avatar"
    avatar.setAttribute("aria-hidden", "true")
    avatar.textContent = role === "user" ? "You" : "R"
    const bubble = document.createElement("div")
    bubble.className = "chat-msg__bubble"
    bubble.textContent = content
    article.appendChild(avatar)
    article.appendChild(bubble)
    thread.appendChild(article)
    this.scrollThread()
    return article
  }

  finish(assistant) {
    this.setBusy(false)
    this.abortController = null
    this.scrollThread()
  }

  fail(assistant, error) {
    if (assistant) {
      const bubble = assistant.querySelector(".chat-msg__bubble")
      if (bubble) bubble.textContent = `⚠ ${error.message}`
    }
    this.setBusy(false)
    this.abortController = null
  }

  setBusy(busy) {
    if (this.hasSubmitTarget) this.submitTarget.disabled = busy
    if (this.hasInputTarget) this.inputTarget.disabled = busy
  }

  scrollThread() {
    if (this.hasThreadTarget) {
      this.threadTarget.scrollTop = this.threadTarget.scrollHeight
    }
  }

  resizeInput() {
    // minimal auto-grow
    if (this.hasInputTarget) {
      this.inputTarget.style.height = "auto"
      this.inputTarget.style.height = `${Math.min(this.inputTarget.scrollHeight, 160)}px`
    }
  }
}
