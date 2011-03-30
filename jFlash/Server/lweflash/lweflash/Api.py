#
#  Api.py
#  jFlash
#
#  Created by Ross Sharrott on 6/26/09.
#  Copyright 2011 LONG WEEKEND INC. All rights reserved.
#

from google.appengine.ext import webapp
from google.appengine.ext import db
from gaesessions import get_current_session
from Security import check_session
import logging
import urllib, urllib2
import json

class AuthorizeHandler(webapp.RequestHandler):
    """Receive the POST from a client with our user's login information."""
    """Takes providerType, providerSessionKey, providerID - since we trust the providers if this matches our info its as good as a password"""
    def post(self):
      # close any active session the user has since he is trying to login
      session = get_current_session()
      if session.is_active():
        session.terminate()

      token = self.request.get('token')
      
      # Step 2) Now that we have the token, we need to make the api call to auth_info.
      # auth_info expects an HTTP Post with the following paramters:
      api_params = 
      {
          'token': token,
          'apiKey': 'ae696162dff14837353041d488917172e30898aa',
          'format': 'json',
      }
      
      # make the api call
      http_response = urllib2.urlopen('https://rpxnow.com/api/v2/auth_info', urllib.urlencode(api_params))

      # read the json response
      auth_info_json = http_response.read()

      # Step 3) process the json response
      auth_info = json.loads(auth_info_json)

      # Step 4) use the response to sign the user in
      if auth_info['stat'] == 'ok':
          profile = auth_info['profile']
         
          # 'identifier' will always be in the payload
          # this is the unique idenfifier that you use to sign the user
          # in to your site
          identifier = profile['identifier']
         
          # these fields MAY be in the profile, but are not guaranteed. it
          # depends on the provider and their implementation.
          name = profile.get('displayName')
          email = profile.get('email')

          # actually sign the user in.  this implementation depends highly on your
          # platform, and is up to you.
          user = User.sign_in_user(identifier, name, email)         
          session['me'] = user
      else:
          print 'An error occured: ' + auth_info['err']['msg']


class Logout(webapp.RequestHandler):
  def get(self):
    session = get_current_session()
    if session.is_active():
      session.terminate()
      
class UploadBackupHandler(webapp.RequestHandler):
  """ Takes the upload of a backup file and stores it in the DB, overwriting the current if existing"""
  def post(self):
    session = check_session(self.response)
    if session == None:
      return
    backup = getBackup(session['me'], self.request.get('flashType'))
    if backup is None:
      backup = BackupData()
      backup.flashType = self.request.get('flashType')
      backup.user = session['me']
    backup.backupFile = self.request.get('backupFile')
    backup.put()
    
class GetBackupHandler(webapp.RequestHandler):
  """ Returns a backup file or 404 if it doesn't exist"""
  def get(self):
    backup = getBackup(session['me'], self.request.get('flashType'))
    if backup is None:
      self.response.error('404')
    else:
      self.response.headers['Content-Type'] = "text/xml"
      self.response.out.write(backup.backupFile)
    
def getBackup(user, flashType):
  query = BackupData.gql("WHERE user = :1 AND flashType = :2", session['me'], self.request.get('flashType'))
  return query.get()