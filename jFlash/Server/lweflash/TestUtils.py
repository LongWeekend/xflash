from google.appengine.ext import webapp
from google.appengine.api import apiproxy_stub_map
from google.appengine.runtime.apiproxy_errors import CapabilityDisabledError

class MakeReadOnly(webapp.RequestHandler):
  """Puts the datastore into read only mode for testing purposes."""
  def get(self):
    make_datastore_readonly()
    
def make_datastore_readonly():
  """Throw ReadOnlyError on put and delete operations."""
  def hook(service, call, request, response):
    assert(service == 'datastore_v3')
    if call in ('Put', 'Delete'):
      raise CapabilityDisabledError('Datastore is in read-only mode')
  apiproxy_stub_map.apiproxy.GetPreCallHooks().Push('readonly_datastore', hook, 'datastore_v3')