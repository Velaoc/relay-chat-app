// Import and register all your controllers from the importmap under controllers/*controller.js
import { application } from "controllers/application"

// Eager load all controllers defined in the import map under controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

// Chat (Relay) — the controller file is named chat_controller.js so eager
// loading already registers it as "chat"; the explicit register below is a
// harmless no-op safety net if eager loading ever changes.
import ChatController from "controllers/chat_controller"
if (!application.router.modulesByIdentifier.has("chat")) {
  application.register("chat", ChatController)
}
