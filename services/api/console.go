// Copyright 2023 Paolo Fabio Zaino
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Package main (API) implements the API server for the Crowler search engine.
package main

import (
	"database/sql"
	"encoding/json"
	"fmt"

	cmn "github.com/pzaino/thecrowler/pkg/common"
	cfg "github.com/pzaino/thecrowler/pkg/config"
	cdb "github.com/pzaino/thecrowler/pkg/database"
)

const (
	errFailedToInitializeDBHandler = "Failed to initialize database handler"
	errFailedToConnectToDB         = "Error connecting to the database"
	errFailedToStartTransaction    = "Failed to start transaction"
	errFailedToCommitTransaction   = "Failed to commit transaction"

	infoAllSourcesStatus = "All Sources status"
	//infoSourceStatus     = "Source status"
	infoSourceRemoved = "Source and related data removed successfully"
)

func performAddSource(query string, qType int, db *cdb.Handler) (ConsoleResponse, error) {
	var sqlQuery string
	var sqlParams addSourceRequest
	if qType == getQuery {
		sqlParams.URL = normalizeURL(query)
		//sqlQuery = "INSERT INTO Sources (url, last_crawled_at, status) VALUES ($1, NULL, 'pending')"
		sqlQuery = "INSERT INTO Sources (url, last_crawled_at, category_id, usr_id, status, restricted, disabled, flags, config) VALUES ($1, NULL, 0, 0, 'pending', 2, false, 0, '{}')"
	} else {
		// extract the parameters from the query
		extractAddSourceParams(query, &sqlParams)
		// Normalize the URL
		sqlParams.URL = normalizeURL(sqlParams.URL)
		// Prepare the SQL query
		sqlQuery = "INSERT INTO Sources (url, last_crawled_at, status, restricted, disabled, flags, config, category_id, usr_id) VALUES ($1, NULL, $2, $3, $4, $5, $6, $7, $8)"
	}

	if sqlParams.URL == "" {
		return ConsoleResponse{Message: "Invalid URL"}, nil
	}

	// Perform the addSource operation
	results, err := addSource(sqlQuery, sqlParams, db)
	if err != nil {
		cmn.DebugMsg(cmn.DbgLvlError, "adding the source: %v", err)
		return results, err
	}

	cmn.DebugMsg(cmn.DbgLvlInfo, "Website inserted successfully: %s", query)
	return results, nil
}

func extractAddSourceParams(query string, params *addSourceRequest) {
	params.Restricted = -1

	// Unmarshal query into params
	err := json.Unmarshal([]byte(query), &params)
	if err != nil {
		cmn.DebugMsg(cmn.DbgLvlError, "unmarshalling the query: %v", err)
	}

	// Check for missing parameters
	if params.Status == "" {
		params.Status = "pending"
	}
	if params.Restricted < 0 || params.Restricted > 4 {
		params.Restricted = 2
	}
	if !params.Config.IsEmpty() {
		// Validate and potentially reformat the existing Config JSON
		// First, marshal the params.Config struct to JSON
		configJSON, err := json.Marshal(params.Config)
		if err != nil {
			cmn.DebugMsg(cmn.DbgLvlError, "marshalling the Config field: %v", err)
		}

		// Unmarshal the JSON into a map to check for invalid JSON
		var jsonRaw map[string]interface{}
		if err := json.Unmarshal([]byte(configJSON), &jsonRaw); err != nil {
			// Handle invalid JSON
			cmn.DebugMsg(cmn.DbgLvlError, "Config field contains invalid JSON: %v", err)
		}

		// Re-marshal to ensure the JSON is in a standardized format (optional)
		configJSONChecked, err := json.Marshal(jsonRaw)
		if err != nil {
			cmn.DebugMsg(cmn.DbgLvlError, "re-marshalling the Config field: %v", err)
		}
		if err := json.Unmarshal(configJSONChecked, &params.Config); err != nil {
			cmn.DebugMsg(cmn.DbgLvlError, "unmarshalling the Config field: %v", err)
		}
	}
}

func addSource(sqlQuery string, params addSourceRequest, db *cdb.Handler) (ConsoleResponse, error) {
	var results ConsoleResponse
	results.Message = "Failed to add the source"

	// Check if Config is empty and set to default JSON if it is
	if !params.Config.IsEmpty() {
		// Validate and potentially reformat the existing Config JSON
		err := validateAndReformatConfig(&params.Config)
		if err != nil {
			return results, fmt.Errorf("failed to validate and reformat Config: %w", err)
		}
	}

	// Get the JSON string for the Config field
	configJSON, err := json.Marshal(params.Config)
	if err != nil {
		return results, err
	}

	// Execute the SQL statement
	_, err = (*db).Exec(sqlQuery, params.URL, params.Status, params.Restricted, params.Disabled, params.Flags, string(configJSON), params.CategoryID, params.UsrID)
	if err != nil {
		return results, err
	}

	results.Message = "Website inserted successfully"
	return results, nil
}

/*
func getDefaultConfig() cfg.SourceConfig {
	defaultConfig := map[string]string{}
	defaultConfigJSON, _ := json.Marshal(defaultConfig)
	var config cfg.SourceConfig
	_ = json.Unmarshal(defaultConfigJSON, &config)
	return config
}
*/

func validateAndReformatConfig(config *cfg.SourceConfig) error {
	configJSON, err := json.Marshal(config)
	if err != nil {
		return fmt.Errorf("failed to marshal config to JSON: %w", err)
	}

	var jsonRaw map[string]interface{}
	if err := json.Unmarshal([]byte(configJSON), &jsonRaw); err != nil {
		return fmt.Errorf("config field contains invalid JSON: %w", err)
	}

	configJSONChecked, err := json.Marshal(jsonRaw)
	if err != nil {
		return fmt.Errorf("failed to marshal Config field: %w", err)
	}

	if err := json.Unmarshal(configJSONChecked, config); err != nil {
		return fmt.Errorf("failed to unmarshal validated JSON back to Config struct: %w", err)
	}

	return nil
}

func performRemoveSource(query string, qType int, db *cdb.Handler) (ConsoleResponse, error) {
	var results ConsoleResponse
	var sourceURL string // Assuming the source URL is passed. Adjust as necessary based on input.

	if qType == getQuery {
		// Direct extraction from query if it's a simple GET request
		sourceURL = query
	} else {
		// Handle extraction from a JSON document or other POST data
		// Assuming you have a method or logic to extract the URL from the POST body
		return ConsoleResponse{Message: "Invalid request"}, nil
	}

	// Start a transaction
	tx, err := (*db).Begin()
	if err != nil {
		return ConsoleResponse{Message: errFailedToStartTransaction}, err
	}

	// Proceed with deleting the source using the obtained source_id
	results, err = removeSource(tx, sourceURL)
	if err != nil {
		return ConsoleResponse{Message: "Failed to remove source and related data"}, err
	}

	// If everything went well, commit the transaction
	err = tx.Commit()
	if err != nil {
		return ConsoleResponse{Message: errFailedToCommitTransaction}, err
	}

	results.Message = infoSourceRemoved
	return results, nil
}

func removeSource(tx *sql.Tx, sourceURL string) (ConsoleResponse, error) {
	var results ConsoleResponse
	results.Message = "Failed to remove the source"

	// First, get the source_id for the given URL to ensure it exists and to use in cascading deletes if necessary
	var sourceID int64
	err := tx.QueryRow("SELECT source_id FROM Sources WHERE url = $1", sourceURL).Scan(&sourceID)
	if err != nil {
		return results, err
	}

	// Proceed with deleting the source using the obtained source_id
	_, err = tx.Exec("DELETE FROM Sources WHERE source_id = $1", sourceID)
	if err != nil {
		err2 := tx.Rollback() // Rollback in case of error
		if err2 != nil {
			return ConsoleResponse{Message: "Failed to delete source"}, err2
		}
		return ConsoleResponse{Message: "Failed to delete source and related data"}, err
	}
	_, err = tx.Exec("SELECT cleanup_orphaned_httpinfo();")
	if err != nil {
		err2 := tx.Rollback() // Rollback in case of error
		if err2 != nil {
			return ConsoleResponse{Message: "Failed to cleanup orphaned httpinfo"}, err2
		}
		return ConsoleResponse{Message: "Failed to cleanup orphaned httpinfo"}, err
	}
	_, err = tx.Exec("SELECT cleanup_orphaned_netinfo();")
	if err != nil {
		err2 := tx.Rollback() // Rollback in case of error
		if err2 != nil {
			return ConsoleResponse{Message: "Failed to cleanup orphaned netinfo"}, err2
		}
		return ConsoleResponse{Message: "Failed to cleanup orphaned netinfo"}, err
	}

	results.Message = infoSourceRemoved
	return results, nil
}

func performGetURLStatus(query string, qType int, db *cdb.Handler) (StatusResponse, error) {
	var results StatusResponse
	var sourceURL string // Assuming the source URL is passed. Adjust as necessary based on input.

	if qType == getQuery {
		// Direct extraction from query if it's a simple GET request
		sourceURL = query
	} else {
		// Handle extraction from a JSON document or other POST data
		// Assuming you have a method or logic to extract the URL from the POST body
		return StatusResponse{Message: "Invalid request"}, nil
	}

	// Start a transaction
	tx, err := (*db).Begin()
	if err != nil {
		return StatusResponse{Message: errFailedToStartTransaction}, err
	}

	// Proceed with getting the status
	results, err = getURLStatus(tx, sourceURL)
	if err != nil {
		return StatusResponse{Message: "Failed to get the status"}, err
	}

	// If everything went well, commit the transaction
	err = tx.Commit()
	if err != nil {
		return StatusResponse{Message: errFailedToCommitTransaction}, err
	}

	return results, nil
}

func getURLStatus(tx *sql.Tx, sourceURL string) (StatusResponse, error) {
	var results StatusResponse
	results.Message = "Failed to get the status"

	sourceURL = normalizeURL(sourceURL)
	sourceURL = fmt.Sprintf("%%%s%%", sourceURL)
	cmn.DebugMsg(cmn.DbgLvlDebug5, "Source URL: %s", sourceURL)

	query := `
		SELECT source_id,
			   url,
			   status,
			   engine,
			   created_at,
			   last_updated_at,
			   last_crawled_at,
			   last_error,
			   last_error_at,
			   restricted,
			   disabled,
			   flags
		FROM Sources
		WHERE url LIKE $1`

	// Get the status
	rows, err := tx.Query(query, sourceURL)
	if err != nil {
		return results, err
	}
	defer rows.Close() //nolint:errcheck // Don't lint for error not checked, this is a defer statement

	var statuses []StatusResponseRow
	for rows.Next() {
		var row StatusResponseRow
		err = rows.Scan(&row.SourceID, &row.URL, &row.Status, &row.Engine, &row.CreatedAt, &row.LastUpdatedAt, &row.LastCrawledAt, &row.LastError, &row.LastErrorAt, &row.Restricted, &row.Disabled, &row.Flags)
		if err != nil {
			return results, err
		}
		statuses = append(statuses, row)
	}

	results.Message = infoAllSourcesStatus
	results.Items = statuses
	return results, nil
}

func performGetAllURLStatus(_ int, db *cdb.Handler) (StatusResponse, error) {
	// using _ instead of qType because for now we don't need it

	// Start a transaction
	tx, err := (*db).Begin()
	if err != nil {
		return StatusResponse{Message: errFailedToStartTransaction}, err
	}

	// Proceed with getting all statuses
	results, err := getAllURLStatus(tx)
	if err != nil {
		return StatusResponse{Message: "Failed to get all statuses"}, err
	}

	// If everything went well, commit the transaction
	err = tx.Commit()
	if err != nil {
		return StatusResponse{Message: errFailedToCommitTransaction}, err
	}

	return results, nil
}

func getAllURLStatus(tx *sql.Tx) (StatusResponse, error) {
	var results StatusResponse
	results.Message = "Failed to get all statuses"

	// Proceed with getting all statuses
	rows, err := tx.Query("SELECT source_id, url, status, engine, created_at, last_updated_at, last_crawled_at, last_error, last_error_at, restricted, disabled, flags FROM Sources")
	if err != nil {
		return results, err
	}
	defer rows.Close() //nolint:errcheck // Don't lint for error not checked, this is a defer statement

	var statuses []StatusResponseRow
	for rows.Next() {
		var row StatusResponseRow
		err = rows.Scan(&row.SourceID, &row.URL, &row.Status, &row.Engine, &row.CreatedAt, &row.LastUpdatedAt, &row.LastCrawledAt, &row.LastError, &row.LastErrorAt, &row.Restricted, &row.Disabled, &row.Flags)
		if err != nil {
			return results, err
		}
		statuses = append(statuses, row)
	}

	results.Message = infoAllSourcesStatus
	results.Items = statuses
	return results, nil
}
