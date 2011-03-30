#!/usr/bin/env python
#
# Copyright 2007 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
from google.appengine.ext import webapp
from google.appengine.ext.webapp import util
import logging

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
                                        ],
                                        debug=True)
    util.run_wsgi_app(application)

if __name__ == '__main__':
    main()
