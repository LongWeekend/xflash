from google.appengine.ext import db

class User(db.Model):
  identifier = db.StringProperty()
  email = db.EmailProperty()
  name = db.StringProperty()

class BackupData(db.Model):
  user = db.ReferenceProperty(User)
  flashType = db.StringProperty() # should be something like LWEFLashConstants.APP_NAME_JAPANESE_FLASH
  backupFile = db.BlobProperty() # the backup file will go in here as is  