#
# ABOUT: Question class. Convenience class to distinguish Talk from Questions.
#
class Question < ForumTopic
  default_scope :conditions => { :answerable_flag => true }
end