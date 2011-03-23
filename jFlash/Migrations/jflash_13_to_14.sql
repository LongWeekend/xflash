DELETE FROM card_tag_link WHERE card_id = 7983 AND tag_id = 64;
INSERT INTO card_tag_link (card_id, tag_id) VALUES (62662,64);
DELETE FROM card_tag_link WHERE card_id = 111134 AND tag_id = 12;
INSERT INTO card_tag_link (card_id, tag_id) VALUES (140514,12);
DELETE FROM group_tag_link WHERE tag_id = 0 AND group_id = 0;
INSERT INTO group_tag_link (tag_id, group_id) VALUES (0,0);