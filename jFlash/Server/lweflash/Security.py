import logging
from gaesessions import get_current_session
    
def check_session(request):
    session = get_current_session()
    if session.is_active():
      user = session.get('me')
      if user is None: # this shouldn't be possible but check anyway
        logging.critical("A user was able to have a session but no user object. WTF!?!")
        session.terminate()
        request.error(401)
        logging.debug("Not Logged In")
        return None
      return session
    else:
      request.error(401)
      logging.debug("Not Logged In")
      return None
      # the use is not authenticated so we don't want to do anything else