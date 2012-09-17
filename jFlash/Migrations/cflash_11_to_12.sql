CREATE TABLE users_new (user_id INTEGER PRIMARY KEY, nickname TEXT);
INSERT INTO users_new SELECT user_id, nickname FROM users;
DROP TABLE users;
ALTER TABLE users_new RENAME TO users;
UPDATE group_tag_link SET group_id = 1 WHERE group_id = 0;