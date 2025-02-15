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

// Package ruleset implements the ruleset library for the Crowler and
// the scrapper.
package ruleset

import (
	"reflect"
	"testing"
)

func TestCrawlingRuleGetRuleName(t *testing.T) {
	c := CrawlingRule{RuleName: " Crawl Social Media "}
	expected := "Crawl Social Media"
	if got := c.GetRuleName(); got != expected {
		t.Errorf("GetRuleName() = %v, want %v", got, expected)
	}
}

func TestCrawlingRuleGetRequestType(t *testing.T) {
	c := CrawlingRule{RequestType: " post "}
	expected := "POST"
	if got := c.GetRequestType(); got != expected {
		t.Errorf("GetRequestType() = %v, want %v", got, expected)
	}
}

func TestCrawlingRuleGetTargetElements(t *testing.T) {
	c := CrawlingRule{
		TargetElements: []TargetElement{
			{SelectorType: "css", Selector: ".login"},
		},
	}
	expected := []TargetElement{{SelectorType: "css", Selector: ".login"}}
	if got := c.GetTargetElements(); !reflect.DeepEqual(got, expected) {
		t.Errorf("GetTargetElements() = %v, want %v", got, expected)
	}
}

func TestCrawlingRuleGetFuzzingParameters(t *testing.T) {
	c := CrawlingRule{
		FuzzingParameters: []FuzzingParameter{
			{ParameterName: "username", FuzzingType: "fixed_list", Values: []string{"admin", "guest"}},
		},
	}
	expected := []FuzzingParameter{{ParameterName: "username", FuzzingType: "fixed_list", Values: []string{"admin", "guest"}}}
	if got := c.GetFuzzingParameters(); !reflect.DeepEqual(got, expected) {
		t.Errorf("GetFuzzingParameters() = %v, want %v", got, expected)
	}
}

func TestTargetElementGetSelectorType(t *testing.T) {
	te := TargetElement{SelectorType: " CSS "}
	expected := "css"
	if got := te.GetSelectorType(); got != expected {
		t.Errorf("GetSelectorType() = %v, want %v", got, expected)
	}
}

func TestTargetElementGetSelector(t *testing.T) {
	te := TargetElement{Selector: " #submit "}
	expected := "#submit"
	if got := te.GetSelector(); got != expected {
		t.Errorf("GetSelector() = %v, want %v", got, expected)
	}
}

func TestFuzzingParameterGetParameterName(t *testing.T) {
	fp := FuzzingParameter{ParameterName: " Email "}
	expected := "Email"
	if got := fp.GetParameterName(); got != expected {
		t.Errorf("GetParameterName() = %v, want %v", got, expected)
	}
}

func TestFuzzingParameterGetFuzzingType(t *testing.T) {
	fp := FuzzingParameter{FuzzingType: " PATTERN_BASED "}
	expected := "pattern_based"
	if got := fp.GetFuzzingType(); got != expected {
		t.Errorf("GetFuzzingType() = %v, want %v", got, expected)
	}
}

func TestFuzzingParameterGetValues(t *testing.T) {
	fp := FuzzingParameter{Values: []string{" test1 ", "test2"}}
	expected := []string{"test1", "test2"}
	if got := fp.GetValues(); !reflect.DeepEqual(got, expected) {
		t.Errorf("GetValues() = %v, want %v", got, expected)
	}
}

func TestFuzzingParameterGetPattern(t *testing.T) {
	fp := FuzzingParameter{Pattern: " .*@example.com "}
	expected := ".*@example.com"
	if got := fp.GetPattern(); got != expected {
		t.Errorf("GetPattern() = %v, want %v", got, expected)
	}
}

func TestTargetElementGetSelector2(t *testing.T) {
	tests := []struct {
		name     string
		selector string
		expected string
	}{
		{"Trim spaces", " #submit ", "#submit"},
		{"No spaces", "#submit", "#submit"},
		{"Empty string", " ", ""},
		{"Special characters", " @submit ", "@submit"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			te := TargetElement{Selector: tt.selector}
			if got := te.GetSelector(); got != tt.expected {
				t.Errorf("GetSelector() = %v, want %v", got, tt.expected)
			}
		})
	}
}
