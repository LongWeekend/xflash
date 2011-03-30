COOKIE_KEY = "gcCDEyuU0Qt8I7EhC11is6ZmRUXsesakgPgCxBKyjSl"
from gaesessions import SessionMiddleware
import os
  
def webapp_add_wsgi_middleware(app):
  app = SessionMiddleware(app, cookie_key=COOKIE_KEY)
  return app