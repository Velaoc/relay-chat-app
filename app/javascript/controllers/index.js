// Import and register all your controllers from the importmap under controllers/*controller.js
import { application } from "controllers/application"

// Eager load all controllers defined in the import map under controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

// Chat (Relay) — registered explicitly so it works even though its name
// doesn't end in _controller.
import ChatController from "controllers/chat_controller"
application.register("chat", ChatController)
