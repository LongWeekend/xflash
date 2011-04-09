from google.appengine.ext import webapp
from google.appengine.ext.webapp import util
import logging, Api
import TestUtils

class MainHandler(webapp.RequestHandler):
    def get(self):
        self.response.out.write('This is a program that stores backup files for <a href="http://www.japaneseflash.com">Japanese Flash</a> and other X Flash Apps Made by <a href="http://longweekendmobile.com">Long Weekend</a>')

def main():
    logging.getLogger().setLevel(logging.DEBUG)
    application = webapp.WSGIApplication(
                                        [
                                          ('/', MainHandler),
                                           # api calls
                                          ('/api/authorize', Api.AuthorizeHandler),
                                          ('/api/logout', Api.Logout),
                                          ('/api/getBackup', Api.GetBackupHandler),
                                          ('/api/uploadBackup', Api.UploadBackupHandler),
                                          ('/test/set-readonly-db-mode', TestUtils.MakeReadOnly),
                                        ],
                                        debug=True)
    util.run_wsgi_app(application)

if __name__ == '__main__':
    main()
