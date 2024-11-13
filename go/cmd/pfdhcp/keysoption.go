package main

import (
	"database/sql"

	"github.com/inverse-inc/go-utils/log"
)

// MysqlInsert function
func MysqlInsert(key string, value string, db *sql.DB) bool {
	if err := db.PingContext(ctx); err != nil {
		log.LoggerWContext(ctx).Error("Unable to ping database, reconnect: " + err.Error())
	}

	_, err := db.Exec(
		`
INSERT into key_value_storage values(?,?)
ON DUPLICATE KEY UPDATE value = VALUES(value)
		`,
		"/dhcpd/"+key,
		value,
	)

	if err != nil {
		log.LoggerWContext(ctx).Error("Error while inserting into MySQL: " + err.Error())
		return false
	}

	return true
}

// MysqlGet function
func MysqlGet(key string, db *sql.DB) (string, string) {
	if err := db.PingContext(ctx); err != nil {
		log.LoggerWContext(ctx).Error("Unable to ping database, reconnect: " + err.Error())
	}
	rows, err := db.Query("select id, value from key_value_storage where id = ?", "/dhcpd/"+key)
	defer rows.Close()
	if err != nil {
		log.LoggerWContext(ctx).Debug("Error while getting MySQL '" + key + "': " + err.Error())
		return "", ""
	}
	var (
		ID    string
		Value string
	)
	for rows.Next() {
		err := rows.Scan(&ID, &Value)
		if err != nil {
			log.LoggerWContext(ctx).Crit(err.Error())
		}
	}
	return ID, Value
}

// MysqlDel function
func MysqlDel(key string, db *sql.DB) bool {
	if err := db.PingContext(ctx); err != nil {
		log.LoggerWContext(ctx).Error("Unable to ping database, reconnect: " + err.Error())
	}
	rows, err := db.Query("delete from key_value_storage where id = ?", "/dhcpd/"+key)
	defer rows.Close()
	if err != nil {
		log.LoggerWContext(ctx).Error("Error while deleting MySQL key '" + key + "': " + err.Error())
		return false
	}
	return true
}
