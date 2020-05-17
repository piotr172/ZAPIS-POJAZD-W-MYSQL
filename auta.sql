--
-- Struktura tabeli dla tabeli `auta`
--

CREATE TABLE IF NOT EXISTS `auta` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `wlasciciel` varchar(128) CHARACTER SET utf8 COLLATE utf8_polish_ci NOT NULL,
  `model` smallint(3) unsigned NOT NULL,
  `xyz` varchar(64) NOT NULL,
  `rot` varchar(64) NOT NULL,
  `frozen` tinyint(1) NOT NULL DEFAULT '0',
  `hp` smallint(4) NOT NULL DEFAULT '1000',
  `ca` int(10) unsigned NOT NULL DEFAULT '16777215',
  `cb` int(10) unsigned NOT NULL DEFAULT '16777215',
  `cc` int(10) unsigned NOT NULL DEFAULT '16777215',
  `przebieg` double unsigned NOT NULL DEFAULT '0',
  `paliwo` double unsigned NOT NULL DEFAULT '100',
  `upgrades` varchar(100) DEFAULT NULL,
  `wheelstates` varchar(10) CHARACTER SET ascii NOT NULL DEFAULT '0,0,0,0',
  `opis` varchar(128) CHARACTER SET utf8 COLLATE utf8_polish_ci NOT NULL DEFAULT '',
  `panelstates` varchar(64) NOT NULL DEFAULT '0,0,0,0,0,0,0',
  `doorstate` varchar(64) NOT NULL DEFAULT '0,0,0,0,0,0,0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=0 ;
