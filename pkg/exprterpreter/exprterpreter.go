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

// Package exprterpreter contains the expression interpreter logic.
package exprterpreter

import (
	"crypto/rand"
	"fmt"
	"math/big"
	"strconv"
	"strings"
	"time"
)

/////////
// Micro-interpreter for complex parameters/expressions
////////

// ParseCmd interprets the string command and returns the EncodedCmd.
func ParseCmd(command string, depth int) (EncodedCmd, error) {
	if depth > maxInterpreterRecursionDepth {
		return EncodedCmd{}, fmt.Errorf("exceeded maximum recursion depth")
	}

	command = strings.TrimSpace(command)
	token, _, isACommand := getCommandToken(command)
	if isACommand && strings.Contains(command, "(") && strings.HasSuffix(command, ")") {
		paramString := command[strings.Index(command, "(")+1 : len(command)-1]
		params, err := parseParams(paramString)
		if err != nil {
			return EncodedCmd{}, err
		}

		var encodedArgs []EncodedCmd
		for _, param := range params {
			trimmedParam := strings.TrimSpace(param)
			if isCommand(trimmedParam) {
				nestedCmd, err := ParseCmd(trimmedParam, depth+1)
				if err != nil {
					return EncodedCmd{}, err
				}
				// Set ArgValue to the full command string for nested commands
				nestedCmd.ArgValue = trimmedParam
				encodedArgs = append(encodedArgs, nestedCmd)
			} else {
				encodedArgs = append(encodedArgs, EncodedCmd{
					Token:    -1, // For parameters
					Args:     nil,
					ArgValue: trimmedParam,
				})
			}
		}

		return EncodedCmd{
			Token:    token,
			Args:     encodedArgs,
			ArgValue: "", // Command itself doesn't directly have an ArgValue
		}, nil
	}

	// Handle plain text or numbers not forming a recognized command
	return EncodedCmd{
		Token:    -1,
		Args:     nil,
		ArgValue: command,
	}, nil
}

// isCommand checks if the given string is a valid command using getCommandToken.
func isCommand(s string) bool {
	_, _, exists := getCommandToken(s)
	return exists
}

// getCommandToken returns the token for a given command.
func getCommandToken(command string) (int, string, bool) {
	commandName := strings.SplitN(command, "(", 2)[0]
	token, exists := commandTokenMap[commandName]
	return token, commandName, exists
}

// parseParams parses the parameter string and returns a slice of parameters.
func parseParams(paramString string) ([]string, error) {
	var params []string
	var currentParam strings.Builder
	inQuotes := false
	parenthesisLevel := 0

	for _, char := range paramString {
		inQuotes = handleQuotes(char, inQuotes)
		parenthesisLevel = handleParentheses(char, inQuotes, parenthesisLevel)

		if char == ',' && !inQuotes && parenthesisLevel == 0 {
			params = append(params, strings.TrimSpace(currentParam.String()))
			currentParam.Reset()
		} else {
			currentParam.WriteRune(char)
		}
	}

	if inQuotes || parenthesisLevel != 0 {
		return nil, fmt.Errorf("unmatched quotes or parentheses in parameters")
	}

	params = append(params, strings.TrimSpace(currentParam.String()))
	return params, nil
}

func handleQuotes(char rune, inQuotes bool) bool {
	if char == '"' {
		return !inQuotes
	}
	return inQuotes
}

func handleParentheses(char rune, inQuotes bool, parenthesisLevel int) int {
	if char == '(' && !inQuotes {
		return parenthesisLevel + 1
	} else if char == ')' && !inQuotes {
		if parenthesisLevel > 0 {
			return parenthesisLevel - 1
		}
	}
	return parenthesisLevel
}

// InterpretCmd processes an EncodedCmd recursively and returns the calculated value as a string.
func InterpretCmd(encodedCmd EncodedCmd) (string, error) {
	switch encodedCmd.Token {
	case -1: // Non-command parameter
		return encodedCmd.ArgValue, nil
	case TokenRandom: // Token representing the 'random' command
		return handleRandomCommand(encodedCmd.Args)
	case TokenTime: // Token representing the 'time' command
		return handleTimeCommand(encodedCmd.Args)
	case TokenURL: // Token representing the 'url' command
		return "*", nil
	default:
		return "", fmt.Errorf("unknown command token: %d", encodedCmd.Token)
	}
}

// handleRandomCommand processes the 'random' command given its arguments.
func handleRandomCommand(args []EncodedCmd) (string, error) {
	if len(args) != 2 {
		return "", fmt.Errorf("random command expects 2 arguments, got %d", len(args))
	}

	// Process arguments recursively
	minArg, err := InterpretCmd(args[0])
	if err != nil {
		return "", err
	}
	maxArg, err := InterpretCmd(args[1])
	if err != nil {
		return "", err
	}

	// Convert arguments to integers
	minVal, err := strconv.Atoi(minArg)
	if err != nil {
		return "", fmt.Errorf("invalid min argument for random: %s", minArg)
	}
	maxVal, err := strconv.Atoi(maxArg)
	if err != nil {
		return "", fmt.Errorf("invalid max argument for random: %s", maxArg)
	}

	// Ensure min is less than max
	if minVal >= maxVal {
		return "", fmt.Errorf("min argument must be less than max argument for random")
	}

	// Generate and return random value using crypto/rand for better randomness
	// Compute the range (max - min + 1)
	rangeInt := big.NewInt(int64(maxVal - minVal + 1))
	// Generate a random number in [0, rangeInt)
	n, err := rand.Int(rand.Reader, rangeInt)
	if err != nil {
		return "", err
	}

	// Shift the number to [min, max]
	result := int(n.Int64()) + minVal
	return strconv.Itoa(result), nil
}

// handleTimeCommand processes the 'time' command given its arguments.
func handleTimeCommand(args []EncodedCmd) (string, error) {
	if len(args) == 0 {
		return time.Now().String(), fmt.Errorf("time command expects 1 argument, got %d", len(args))
	}

	// Process arguments recursively
	timeFormat, err := InterpretCmd(args[0])
	if err != nil {
		return time.Now().String(), err
	}
	timeToken := strings.ToLower(strings.TrimSpace(timeFormat))
	switch timeToken {
	case "unix":
		uxTimeStr := strconv.FormatInt(time.Now().Unix(), 10)
		return uxTimeStr, nil
	case "unixnano":
		uxTimeStr := strconv.FormatInt(time.Now().UnixNano(), 10)
		return uxTimeStr, nil
	case "rfc3339":
		return time.Now().Format(time.RFC3339), nil
	case "now":
		return time.Now().String(), nil
	default:
		// Check if timeFormat is valid to be used with time.Format
		_, err = time.Parse(timeFormat, "2006-01-02T15:04:05Z07:00")
		if err != nil {
			return time.Now().String(), fmt.Errorf("invalid time format: %s", timeFormat)
		}
		return string(time.Now().Format(timeFormat)), nil
	}
}

// ----- Expression evaluation functions ----- //

// IsNumber checks if the given string is a number.
func IsNumber(str string) bool {
	_, err := strconv.ParseFloat(str, 64)
	return err == nil
}

// GetFloat returns the float value of the given expression.
func GetFloat(iExpr string) float64 {
	if IsNumber(iExpr) {
		rval, err := strconv.ParseFloat(iExpr, 64)
		if err != nil {
			rval = 1
		}
		return rval
	}

	cmd, _ := ParseCmd(iExpr, 0)
	rvalStr, _ := InterpretCmd(cmd)
	rval, err := strconv.ParseFloat(rvalStr, 64)
	if err != nil {
		rval = 1
	}
	return rval
}

// GetInt returns the integer value of the given expression.
func GetInt(iExpr string) int {
	return int(GetFloat(iExpr))
}
