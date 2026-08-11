// Import and register all your controllers from the importmap under controllers/*controller.js
import { application } from "controllers/application"
import ChatController from "controllers/chat_controller"
application.register("chat", ChatController)

import HelloController from "controllers/hello_controller"
application.register("hello", HelloController)
