CREATE TABLE `cards_staging` (
  `card_id` int(11) NOT NULL AUTO_INCREMENT,
  `headword_trad` varchar(255) NOT NULL,
  `headword_simp` varchar(255) NOT NULL,
  `headword_en` varchar(255) NOT NULL,
  `reading` varchar(255) NOT NULL,
  `reading_diacritic` varchar(255) NOT NULL,
  `meaning` varchar(3000) NOT NULL,
  `meaning_fts` varchar(3000) NOT NULL,
  `meaning_html` varchar(5000) NOT NULL,
  `classifier` varchar(255) DEFAULT NULL,
  `tags` varchar(200) DEFAULT NULL,
  `is_variant` tinyint(1) NOT NULL DEFAULT '0',
  `is_erhua_variant` tinyint(1) NOT NULL DEFAULT '0',
  `variant` varchar(255) DEFAULT NULL,
  `cedict_hash` longblob NOT NULL,
  `referenced_cards` varchar(255) DEFAULT NULL,
  `is_reference_only` tinyint(1) DEFAULT '0',
  `is_proper_noun` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`card_id`),
  KEY `headword_trad` (`headword_trad`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
    
CREATE TABLE `groups_staging` (
  `group_id` int(11) NOT NULL,
  `group_name` varchar(50) NOT NULL,
  `owner_id` int(11) NOT NULL,
  `tag_count` int(11) DEFAULT '0',
  `recommended` int(11) DEFAULT '0',
  PRIMARY KEY (`group_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE `tags_staging` (
  `tag_id` int(11) NOT NULL AUTO_INCREMENT,
  `tag_name` varchar(50) DEFAULT NULL,
  `tag_type` varchar(4) DEFAULT NULL,
  `short_name` varchar(20) DEFAULT NULL,
  `description` varchar(200) DEFAULT NULL,
  `source_name` varchar(50) DEFAULT NULL,
  `source` varchar(50) DEFAULT NULL,
  `visible` int(11) NOT NULL DEFAULT '0',
  `count` int(11) NOT NULL DEFAULT '0',
  `parent_tag_id` int(11) NULL DEFAULT NULL,
  `force_off` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`tag_id`),
  UNIQUE KEY `short_name` (`short_name`)
) ENGINE=MyISAM AUTO_INCREMENT=0 DEFAULT CHARSET=utf8;
    
CREATE TABLE `sentences_staging` (
  `sentence_id` int(11) NOT NULL AUTO_INCREMENT,
  `sentence_ch` varchar(500) DEFAULT NULL,
  `sentence_en` varchar(500) DEFAULT NULL,
  `en_id` int(11) DEFAULT NULL,
  `ch_id` int(11) DEFAULT NULL,
  `checked` tinyint(4) DEFAULT NULL,
  KEY `sentence_id` (`sentence_id`),
  KEY `checked` (`checked`)
) ENGINE=MyISAM AUTO_INCREMENT=0 DEFAULT CHARSET=utf8;

CREATE TABLE `card_tag_link` (
  `tag_id` int(11) DEFAULT NULL,
  `card_id` int(11) DEFAULT NULL,
  UNIQUE KEY `card_tag_link_uniq` (`tag_id`,`card_id`),
  KEY `card_tag` (`tag_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE `group_tag_link` (`group_id` int(11) NOT NULL,`tag_id` int(11) NOT NULL) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE `card_sentence_link` (
  `card_id` int(11) DEFAULT NULL,
  `sentence_id` int(11) DEFAULT NULL,
  `should_show` tinyint(4) DEFAULT 1,      
  `sense_number` int(11) DEFAULT NULL,
  KEY `card_id` (`card_id`),
  KEY `sentence_id` (`sentence_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE `idx_sentences_by_keyword_staging` (
  `sentence_id` int(11) DEFAULT NULL,
  `segment_number` int(11) DEFAULT NULL,
  `sense_number` int(11) DEFAULT NULL,
  `checked` tinyint(4) DEFAULT NULL,
  `keyword_type` int(11) DEFAULT NULL,
  `keyword` varchar(100) DEFAULT NULL,
  `reading` varchar(100) DEFAULT NULL,
  KEY `sentence_id` (`sentence_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
    
CREATE TABLE `idx_cards_by_headword_staging` (
  `card_id` int(11) DEFAULT NULL,
  `keyword` varchar(100) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
