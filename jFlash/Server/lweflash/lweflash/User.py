import model
from google.appengine.ext import db

def sign_in_user(identifier, name, email):
    """ returns the user object, creates a user if needed """
    # get the user's record
    query = model.User.gql("WHERE identifier = :1", identifier)
    user = query.get()
  
    # return none if it doesn't exist
    if user is None:
      try: # handle read only mode
        user = model.User()
        user.identifier = identifier
        user.email = email
        user.name = name
        user.put()
      except CapabilityDisabledError:
        # TODO: fail gracefully here
        pass
       
    return user