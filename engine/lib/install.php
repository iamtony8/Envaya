<?php

	/**
	 * Elgg installation
	 * Various functions to assist with installing and upgrading the system
	 * 
	 * @package Elgg
	 * @subpackage Core

	 * @author Curverider Ltd

	 * @link http://elgg.org/
	 */

	/**
	 * Returns whether or not the database has been installed
	 *
	 * @return true|false Whether the database has been installed
	 */
		function is_db_installed() {
			
			global $CONFIG;

			if (isset($CONFIG->db_installed)) {
				return $CONFIG->db_installed;
			}

			if ($dblink = get_db_link('read')) {
				mysql_query("select name from datalists limit 1",$dblink);
				if (mysql_errno($dblink) > 0) return false;
			} else return false; 
			
			$CONFIG->db_installed = true; // Set flag if db is installed (if false then we want to check every time)
			
			return true;
			
		}
		
	/**
	 * Returns whether or not other settings have been set
	 *
	 * @return true|false Whether or not the rest of the installation has been followed through with
	 */
		function is_installed() {			
			global $CONFIG;
			return datalist_get('installed');			
		}
		
		
	/**
	 * Initialisation for installation functions
	 *
	 */
		function install_init() {
			register_action("systemsettings/install",true);			
		}
		
		register_elgg_event_handler("boot","system","install_init");
		
?>