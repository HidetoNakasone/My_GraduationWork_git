# My_GraduationWork_git


MySQL の 事前準備

CREATE DATABASE GraduationWork;

CREATE TABLE users (id int(11) auto_increment, user_name varchar(256), user_pass varchar(256), user_profile varchar(500), primary key(id));

CREATE TABLE foll (id int(11) auto_increment, who int(11), send int(11), primary key(id));

CREATE TABLE tweets (id int(11) auto_increment, creater_id int(11), dateinfo DATETIME NULL, msg varchar(8000), img_name varchar(50), re_sou_id int(11), primary key(id));

CREATE TABLE iine (id int(11) auto_increment, who int(11), twe_id int(11), primary key(id));

Rubyを習ってまだ一ヶ月なので、自分でも分かるくらいにゴリ押しのコードです。
ただ、この際思い切ってpushしてみました。
何か反応をしてくださると大変うれしいです。
