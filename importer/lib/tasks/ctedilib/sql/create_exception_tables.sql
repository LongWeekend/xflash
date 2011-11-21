CREATE TABLE IF NOT EXISTS `tag_matching_exceptions` (
  `entry_id` char(32) NOT NULL DEFAULT '',
  `human_readable` varchar(255) NOT NULL DEFAULT '',
  `serialized_entry` longblob NOT NULL,
  UNIQUE KEY `entry_id` (`entry_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `tag_matching_resolutions` (
  `entry_id` char(32) NOT NULL DEFAULT '',
  `serialized_entry` longblob NOT NULL,
  `resolution_type` varchar(255) NOT NULL DEFAULT ''
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE `tag_matching_resolution_choices` (
  `base_entry_id` char(32) NOT NULL DEFAULT '',
  `human_readable` varchar(255) NOT NULL DEFAULT '',
  `serialized_entry` longblob NOT NULL,
  PRIMARY KEY (`base_entry_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;