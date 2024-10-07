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

// Package config contains the configuration file parsing logic.
package config

import "time"

// FileStorageAPI is a generic File Storage API configuration
type FileStorageAPI struct {
	Host    string `yaml:"host"`    // Hostname of the API server
	Path    string `yaml:"path"`    // Path to the storage (e.g., "/tmp/images" or Bucket name)
	Port    int    `yaml:"port"`    // Port number of the API server
	Region  string `yaml:"region"`  // Region of the storage (e.g., "us-east-1" when using S3 like services)
	Token   string `yaml:"token"`   // Token for API authentication (e.g., API key or token, AWS access key ID)
	Secret  string `yaml:"secret"`  // Secret for API authentication (e.g., AWS secret access key)
	Timeout int    `yaml:"timeout"` // Timeout for API requests (in seconds)
	Type    string `yaml:"type"`    // Type of storage (e.g., "local", "http", "volume", "queue", "s3")
	SSLMode string `yaml:"sslmode"` // SSL mode for API connection (e.g., "disable")
}

// Database represents the database configuration
type Database struct {
	Type         string `yaml:"type"`           // Type of database (e.g., "postgres", "mysql", "sqlite")
	Host         string `yaml:"host"`           // Hostname of the database server
	Port         int    `yaml:"port"`           // Port number of the database server
	User         string `yaml:"user"`           // Username for database authentication
	Password     string `yaml:"password"`       // Password for database authentication
	DBName       string `yaml:"dbname"`         // Name of the database
	RetryTime    int    `yaml:"retry_time"`     // Time to wait before retrying to connect to the database (in seconds)
	PingTime     int    `yaml:"ping_time"`      // Time to wait before retrying to ping the database (in seconds)
	SSLMode      string `yaml:"sslmode"`        // SSL mode for database connection (e.g., "disable")
	OptimizeFor  string `yaml:"optimize_for"`   // Optimize for the database connection (e.g., "read", "write")
	MaxConns     int    `yaml:"max_conns"`      // Maximum number of connections to the database
	MaxIdleConns int    `yaml:"max_idle_conns"` // Maximum number of idle connections to the database
}

// Crawler represents the crawler configuration
type Crawler struct {
	Workers               int           `yaml:"workers"`                 // Number of crawler workers
	Interval              string        `yaml:"interval"`                // Interval between crawler requests (in seconds)
	Timeout               int           `yaml:"timeout"`                 // Timeout for crawler requests (in seconds)
	Maintenance           int           `yaml:"maintenance"`             // Interval between crawler maintenance tasks (in seconds)
	SourceScreenshot      bool          `yaml:"source_screenshot"`       // Whether to take a screenshot of the source page or not
	FullSiteScreenshot    bool          `yaml:"full_site_screenshot"`    // Whether to take a screenshot of the full site or not
	ScreenshotMaxHeight   int           `yaml:"screenshot_max_height"`   // Maximum height of the screenshot
	ScreenshotSectionWait int           `yaml:"screenshot_section_wait"` // Time to wait before taking a screenshot of a section in seconds
	MaxDepth              int           `yaml:"max_depth"`               // Maximum depth to crawl
	MaxSources            int           `yaml:"max_sources"`             // Maximum number of sources to crawl
	Delay                 string        `yaml:"delay"`                   // Delay between requests (in seconds)
	BrowsingMode          string        `yaml:"browsing_mode"`           // Browsing type (e.g., "recursive", "human", "fuzzing")
	MaxRetries            int           `yaml:"max_retries"`             // Maximum number of retries
	MaxRedirects          int           `yaml:"max_redirects"`           // Maximum number of redirects
	CollectHTML           bool          `yaml:"collect_html"`            // Whether to collect the HTML content or not
	CollectImages         bool          `yaml:"collect_images"`          // Whether to collect the images or not
	CollectFiles          bool          `yaml:"collect_files"`           // Whether to collect the files or not
	CollectContent        bool          `yaml:"collect_content"`         // Whether to collect the content or not
	CollectKeywords       bool          `yaml:"collect_keywords"`        // Whether to collect the keywords or not
	CollectMetaTags       bool          `yaml:"collect_metatags"`        // Whether to collect the metatags or not
	ReportInterval        int           `yaml:"report_time"`             // Time to wait before sending the report (in minutes)
	CheckForRobots        bool          `yaml:"check_for_robots"`        // Whether to check for robots.txt or not
	Control               ControlConfig `yaml:"control"`                 // Control/COnsole internal API
}

// HealthCheckConfig represents the health check configuration
type ControlConfig struct {
	Host              string `yaml:"host"`               // IP address for the health check server
	Port              int    `yaml:"port"`               // Port number for the health check server
	Timeout           int    `yaml:"timeout"`            // Timeout for API requests (in seconds)
	SSLMode           string `yaml:"sslmode"`            // SSL mode for API connection (e.g., "disable")
	CertFile          string `yaml:"cert_file"`          // Path to the SSL certificate file
	KeyFile           string `yaml:"key_file"`           // Path to the SSL key file
	RateLimit         string `yaml:"rate_limit"`         // Rate limit values are tuples (for ex. "1,3") where 1 means allows 1 request per second with a burst of 3 requests
	ReadHeaderTimeout int    `yaml:"readheader_timeout"` // ReadHeaderTimeout is the amount of time allowed to read request headers.
	ReadTimeout       int    `yaml:"read_timeout"`       // ReadTimeout is the maximum duration for reading the entire request
	WriteTimeout      int    `yaml:"write_timeout"`      // WriteTimeout
}

// DNSConfig represents the DNS information gathering configuration
type DNSConfig struct {
	Enabled   bool   `yaml:"enabled"`    // Whether to enable DNS information gathering or not
	Timeout   int    `yaml:"timeout"`    // Timeout for DNS requests (in seconds)
	RateLimit string `yaml:"rate_limit"` // Rate limit for DNS requests (in milliseconds)
}

// WHOISConfig represents the WHOIS information gathering configuration
type WHOISConfig struct {
	Enabled   bool   `yaml:"enabled"`
	Timeout   int    `yaml:"timeout"`
	RateLimit string `yaml:"rate_limit"`
}

// NetLookupConfig represents the network information gathering configuration
type NetLookupConfig struct {
	Enabled   bool   `yaml:"enabled"`
	Timeout   int    `yaml:"timeout"`
	RateLimit string `yaml:"rate_limit"`
}

// GeoLookupConfig represents the network information gathering configuration
type GeoLookupConfig struct {
	Enabled bool   `yaml:"enabled"`
	Type    string `yaml:"type"`    // "maxmind" or "ip2location"
	DBPath  string `yaml:"db_path"` // Used for MaxMind
	APIKey  string `yaml:"api_key"` // Used for IP2Location
	Timeout int    `yaml:"timeout"`
	SSLMode string `yaml:"sslmode"`
}

type HTTPConfig struct {
	Enabled         bool           `yaml:"enabled"`
	Timeout         int            `yaml:"timeout"`
	FollowRedirects bool           `yaml:"follow_redirects"`
	SSLDiscovery    SSLScoutConfig `yaml:"ssl_discovery"`
	Proxies         []SOCKSProxy   `yaml:"proxies"`
}

type SSLScoutConfig struct {
	Enabled     bool `yaml:"enabled"`
	JARM        bool `yaml:"jarm"`
	JA3         bool `yaml:"ja3"`
	JA3S        bool `yaml:"ja3s"`
	JA4         bool `yaml:"ja4"`
	JA4S        bool `yaml:"ja4s"`
	HASSH       bool `yaml:"hassh"`
	HASSHServer bool `yaml:"hassh_server"`
	TLSH        bool `yaml:"tlsh"`
	SimHash     bool `yaml:"simhash"`
	MinHash     bool `yaml:"minhash"`
	BLAKE2      bool `yaml:"blake2"`
	SHA256      bool `yaml:"sha256"`
	CityHash    bool `yaml:"cityhash"`
	MurmurHash  bool `yaml:"murmurhash"`
	CustomTLS   bool `yaml:"custom_tls"`
}

type SOCKSProxy struct {
	Address  string `yaml:"host"`
	Port     int    `yaml:"port"`
	Username string `yaml:"username"`
	Password string `yaml:"password"`
}

// ServiceScoutConfig represents a structured configuration for an Nmap scan.
// This is a simplified example and does not cover all possible Nmap options.
type ServiceScoutConfig struct {
	Enabled bool `yaml:"enabled"` // Whether to enable the Nmap scan or not
	Timeout int  `yaml:"timeout"` // Timeout for the Nmap scan (in seconds)

	// Basic scan types
	IdleScan         SSIdleScan `yaml:"idle_scan"`             // --ip-options (Use idle scan)
	PingScan         bool       `yaml:"ping_scan"`             // -sn (No port scan)
	ConnectScan      bool       `yaml:"connect_scan"`          // -sT (TCP connect scan)
	SynScan          bool       `yaml:"syn_scan"`              // -sS (TCP SYN scan)
	UDPScan          bool       `yaml:"udp_scan"`              // -sU (UDP scan)
	NoDNSResolution  bool       `yaml:"no_dns_resolution"`     // -n (No DNS resolution)
	ServiceDetection bool       `yaml:"service_detection"`     // -sV (Service version detection)
	ServiceDB        string     `yaml:"service_db"`            // --service-db (Service detection database)
	OSFingerprinting bool       `yaml:"os_finger_print"`       // -O (Enable OS detection)
	AggressiveScan   bool       `yaml:"aggressive_scan"`       // -A (Aggressive scan options)
	ScriptScan       []string   `yaml:"script_scan,omitempty"` // --script (Script scan)

	// Host discovery
	Targets      []string `yaml:"targets,omitempty"`        // Targets can be IPs or hostnames
	ExcludeHosts []string `yaml:"excluded_hosts,omitempty"` // --exclude (Hosts to exclude)

	// Timing and performance
	TimingTemplate string `yaml:"timing_template"` // -T<0-5> (Timing template)
	HostTimeout    string `yaml:"host_timeout"`    // --host-timeout (Give up on target after this long)
	MinRate        string `yaml:"min_rate"`        // --min-rate (Send packets no slower than this)
	MaxRetries     int    `yaml:"max_retries"`     // --max-retries (Caps the number of port scan probe retransmissions)
	MaxPortNumber  int    `yaml:"max_port_number"` // allows to specify the maximum port number to scan (default is 9000)

	// Output (TBD)
	/*
	   OutputAll         bool     `yaml:"output_all"` // -oA (Output in the three major formats at once)
	   OutputNormal      bool     `yaml:"output_normal"` // -oN (Output in normal format)
	   OutputXML         bool     `yaml:"output_"` // -oX (Output in XML format)
	   OutputGrepable    bool     // -oG (Output in grepable format)
	   OutputDirectory   string   // Directory to store the output files
	*/

	// Advanced options
	SourcePort     int      `yaml:"source_port"`     // --source-port (Use given port number)
	Interface      string   `yaml:"interface"`       // -e (Use specified interface)
	SpoofIP        string   `yaml:"spoof_ip"`        // -S (Spoof source address)
	RandomizeHosts bool     `yaml:"randomize_hosts"` // --randomize-hosts (Randomize target scan order)
	DataLength     int      `yaml:"data_length"`     // --data-length (Append random data to sent packets)
	ScanDelay      string   `yaml:"delay"`           // --scan-delay (Adjust delay between probes)
	MTUDiscovery   bool     `yaml:"mtu_discovery"`   // --mtu (Discover MTU size)
	ScanFlags      string   `yaml:"scan_flags"`      // --scanflags (Customize TCP scan flags)
	IPFragment     bool     `yaml:"ip_fragment"`     // --ip-fragment (Fragment IP packets)
	MaxParallelism int      `yaml:"max_parallelism"` // --min-parallelism (Maximum number of parallelism)
	DNSServers     []string `yaml:"dns_servers"`     // --dns-servers (Specify custom DNS servers)
	Proxies        []string `yaml:"proxies"`         // Proxies for the database connection
}

type SSIdleScan struct {
	ZombieHost string `yaml:"zombie_host"` // --zombie-host (Use a zombie host)
	ZombiePort int    `yaml:"zombie_port"` // --zombie-port (Use a zombie port)
}

// NetworkInfo represents the network information gathering configuration
type NetworkInfo struct {
	DNS          DNSConfig          `yaml:"dns"`
	WHOIS        WHOISConfig        `yaml:"whois"`
	NetLookup    NetLookupConfig    `yaml:"netlookup"`
	ServiceScout ServiceScoutConfig `yaml:"service_scout"`
	Geolocation  GeoLookupConfig    `yaml:"geolocation"`
	HostPlatform PlatformInfo       `yaml:"host_platform"`
}

type PlatformInfo struct {
	OSName    string `yaml:"os_name"`
	OSVersion string `yaml:"os_version"`
	OSArch    string `yaml:"os_arch"`
}

// API represents the API configuration
type API struct {
	Host              string `yaml:"host"`               // Hostname of the API server
	Port              int    `yaml:"port"`               // Port number of the API server
	Timeout           int    `yaml:"timeout"`            // Timeout for API requests (in seconds)
	ContentSearch     bool   `yaml:"content_search"`     // Whether to search in the content too or not
	ReturnContent     bool   `yaml:"return_content"`     // Whether to return the content or not
	SSLMode           string `yaml:"sslmode"`            // SSL mode for API connection (e.g., "disable")
	CertFile          string `yaml:"cert_file"`          // Path to the SSL certificate file
	KeyFile           string `yaml:"key_file"`           // Path to the SSL key file
	RateLimit         string `yaml:"rate_limit"`         // Rate limit values are tuples (for ex. "1,3") where 1 means allows 1 request per second with a burst of 3 requests
	EnableConsole     bool   `yaml:"enable_console"`     // Whether to enable the console or not
	ReadHeaderTimeout int    `yaml:"readheader_timeout"` // ReadHeaderTimeout is the amount of time allowed to read request headers.
	ReadTimeout       int    `yaml:"read_timeout"`       // ReadTimeout is the maximum duration for reading the entire request
	WriteTimeout      int    `yaml:"write_timeout"`      // WriteTimeout
	Return404         bool   `yaml:"return_404"`         // Whether to return 404 for not found or not
}

// Selenium represents the CROWler VDI configuration
type Selenium struct {
	Name        string `yaml:"name"`         // Name of the Selenium instance
	Location    string `yaml:"location"`     // Location of the Selenium executable
	Path        string `yaml:"path"`         // Path to the Selenium executable
	DriverPath  string `yaml:"driver_path"`  // Path to the Selenium driver executable
	Type        string `yaml:"type"`         // Type of Selenium driver
	ServiceType string `yaml:"service_type"` // Type of Selenium service (standalone, hub)
	Port        int    `yaml:"port"`         // Port number for Selenium server
	Host        string `yaml:"host"`         // Hostname of the Selenium server
	Headless    bool   `yaml:"headless"`     // Whether to run Selenium in headless mode
	UseService  bool   `yaml:"use_service"`  // Whether to use Selenium service as well or not
	SSLMode     string `yaml:"sslmode"`      // SSL mode for Selenium connection (e.g., "disable")
	ProxyURL    string `yaml:"proxy_url"`    // Proxy URL for Selenium connection
	DownloadDir string `yaml:"download_dir"` // Download directory for Selenium
	Language    string `yaml:"language"`     // Language for Selenium
}

// Rules represents the rules configuration sources for the crawler and the scrapper
type Rules struct {
	// Rules set location
	Path []string `yaml:"path"`
	// URL to fetch the rules from (in case they are distributed by a web server)
	URL []string `yaml:"url"`
	// Rules set update interval (in seconds)
	Interval int `yaml:"interval"`
}

// Remote represents a way to tell the CROWler to load a remote configuration
type Remote struct {
	Host    string `yaml:"host"`    // Hostname of the API server
	Path    string `yaml:"path"`    // Path to the storage (e.g., "/tmp/images" or Bucket name)
	Port    int    `yaml:"port"`    // Port number of the API server
	Region  string `yaml:"region"`  // Region of the storage (e.g., "us-east-1" when using S3 like services)
	Token   string `yaml:"token"`   // Token for API authentication (e.g., API key or token, AWS access key ID)
	Secret  string `yaml:"secret"`  // Secret for API authentication (e.g., AWS secret access key)
	Timeout int    `yaml:"timeout"` // Timeout for API requests (in seconds)
	Type    string `yaml:"type"`    // Type of storage (e.g., "local", "http", "volume", "queue", "s3")
	SSLMode string `yaml:"sslmode"` // SSL mode for API connection (e.g., "disable")
}

// Ruleset represents the top-level structure of the rules YAML file
type RulesetConfig struct {
	SchemaPath string   `yaml:"schema_path"` // Path to the JSON schema file
	Path       []string `yaml:"path"`        // Path to the ruleset files
	Host       string   `yaml:"host"`        // Hostname of the API server
	Port       int      `yaml:"port"`        // Port number of the API server
	Region     string   `yaml:"region"`      // Region of the storage (e.g., "us-east-1" when using S3 like services)
	Token      string   `yaml:"token"`       // Token for API authentication (e.g., API key or token, AWS access key ID)
	Secret     string   `yaml:"secret"`      // Secret for API authentication (e.g., AWS secret access key)
	Timeout    int      `yaml:"timeout"`     // Timeout for API requests (in seconds)
	Type       string   `yaml:"type"`        // Type of storage (e.g., "local", "http", "volume", "queue", "s3")
	SSLMode    string   `yaml:"sslmode"`     // SSL mode for API connection (e.g., "disable")
	Refresh    int      `yaml:"refresh"`     // Refresh interval for the ruleset (in seconds)
}

// PluginConfig represents the top-level structure of the rules YAML file
type PluginConfig struct {
	Path    []string `yaml:"path"`    // Path to the ruleset files
	Host    string   `yaml:"host"`    // Hostname of the API server
	Port    int      `yaml:"port"`    // Port number of the API server
	Region  string   `yaml:"region"`  // Region of the storage (e.g., "us-east-1" when using S3 like services)
	Token   string   `yaml:"token"`   // Token for API authentication (e.g., API key or token, AWS access key ID)
	Secret  string   `yaml:"secret"`  // Secret for API authentication (e.g., AWS secret access key)
	Timeout int      `yaml:"timeout"` // Timeout for API requests (in seconds)
	Type    string   `yaml:"type"`    // Type of storage (e.g., "local", "http", "volume", "queue", "s3")
	SSLMode string   `yaml:"sslmode"` // SSL mode for API connection (e.g., "disable")
	Refresh int      `yaml:"refresh"` // Refresh interval for the ruleset (in seconds)
}

// Config represents the structure of the configuration file
type Config struct {
	// Remote configuration
	Remote Remote `yaml:"remote"`

	// Database configuration
	Database Database `yaml:"database"`

	// Crawler configuration
	Crawler Crawler `yaml:"crawler"`

	// API configuration
	API API `yaml:"api"`

	// Selenium configuration
	Selenium []Selenium `yaml:"selenium"`

	// Image storage API configuration (to store images on a separate server)
	ImageStorageAPI FileStorageAPI `yaml:"image_storage"`

	// File storage API configuration (to store files on a separate server)
	FileStorageAPI FileStorageAPI `yaml:"file_storage"`

	// HTTP Headers Info configuration
	HTTPHeaders HTTPConfig `yaml:"http_headers"`

	// NetworkInfo configuration
	NetworkInfo NetworkInfo `yaml:"network_info"`

	// Rules configuration
	RulesetsSchemaPath string          `yaml:"rulesets_schema_path"` // Path to the JSON schema file for rulesets
	Rulesets           []RulesetConfig `yaml:"rulesets"`

	Plugins PluginsConfig `yaml:"plugins"` // Plugins configuration

	ExternalDetection ExternalDetectionConfig `yaml:"external_detection"`

	OS         string `yaml:"os"`          // Operating system name
	DebugLevel int    `yaml:"debug_level"` // Debug level for logging
}

type PluginsConfig struct {
	PluginTimeout int            `yaml:"plugin_timeout"` // Timeout for plugin execution (in seconds)
	Plugins       []PluginConfig `yaml:"plugins"`
}

type ExternalDetectionConfig struct {
	Timeout            int                     `yaml:"timeout"`      // Timeout for external detection (in seconds)
	MaxRequests        int                     `yaml:"max_requests"` // Maximum number of requests
	MaxRetries         int                     `yaml:"max_retries"`  // Maximum number of retries
	Delay              string                  `yaml:"delay"`        // Delay between requests (in seconds)
	AbuseIPDB          ExtDetectProviderConfig `yaml:"abuse_ipdb"`
	AlienVault         ExtDetectProviderConfig `yaml:"alien_vault"`
	Censys             ExtDetectProviderConfig `yaml:"censys"`
	CiscoUmbrella      ExtDetectProviderConfig `yaml:"cisco_umbrella"`
	Cuckoo             ExtDetectProviderConfig `yaml:"cuckoo"`
	GreyNoise          ExtDetectProviderConfig `yaml:"grey_noise"`
	GoogleSafeBrowsing ExtDetectProviderConfig `yaml:"google_safe_browsing"`
	HybridAnalysis     ExtDetectProviderConfig `yaml:"hybrid_analysis"`
	IPQualityScore     ExtDetectProviderConfig `yaml:"ip_quality_score"`
	IPVoid             ExtDetectProviderConfig `yaml:"ipvoid"`
	OpenPhish          ExtDetectProviderConfig `yaml:"open_phish"`
	PhishTank          ExtDetectProviderConfig `yaml:"phish_tank"`
	Shodan             ExtDetectProviderConfig `yaml:"shodan"`
	VirusTotal         ExtDetectProviderConfig `yaml:"virus_total"`
	URLHaus            ExtDetectProviderConfig `yaml:"url_haus"`
}

type ExtDetectProviderConfig struct {
	Provider    string `yaml:"provider"`
	Host        string `yaml:"host"`
	APIKeyLabel string `yaml:"api_key_label"`
	APIKey      string `yaml:"api_key"`
	APIID       string `yaml:"api_id"`
	APISecret   string `yaml:"api_secret"`
	APIToken    string `yaml:"api_token"`
}

/////////////////////////////////////////////////
//// ----------- Source Config ------------ ////

type SourceConfig struct {
	Version        string                 `json:"version" yaml:"version" validate:"required,version_format"`               // Version of the source configuration
	FormatVersion  string                 `json:"format_version" yaml:"format_version" validate:"required,version_format"` // Regex for version format validation
	Author         string                 `json:"author,omitempty" yaml:"author,omitempty"`
	CreatedAt      time.Time              `json:"created_at,omitempty" yaml:"created_at,omitempty" validate:"datetime_format"` // Date-time formatted as string
	Description    string                 `json:"description,omitempty" yaml:"description,omitempty"`
	SourceName     string                 `json:"source_name" yaml:"source_name" validate:"required"`
	CrawlingConfig CrawlingConfig         `json:"crawling_config" yaml:"crawling_config" validate:"required"`
	ExecutionPlan  []ExecutionPlanItem    `json:"execution_plan,omitempty" yaml:"execution_plan,omitempty"`
	Custom         map[string]interface{} `json:"custom,omitempty" yaml:"custom,omitempty"` // Flexible custom configuration
}

type CrawlingConfig struct {
	Site string `json:"site" yaml:"site" validate:"required,url"`
}

type ExecutionPlanItem struct {
	Label                string                 `json:"label" yaml:"label" validate:"required"`
	Conditions           Condition              `json:"conditions" yaml:"conditions" validate:"required"`
	Rulesets             []string               `json:"rulesets,omitempty" yaml:"rulesets,omitempty"`
	RuleGroups           []string               `json:"rule_groups,omitempty" yaml:"rule_groups,omitempty"`
	Rules                []string               `json:"rules,omitempty" yaml:"rules,omitempty"`
	AdditionalConditions map[string]interface{} `json:"additional_conditions,omitempty" yaml:"additional_conditions,omitempty"`
}

type Condition struct {
	UrlPatterns []string `json:"url_patterns" yaml:"url_patterns" validate:"required"`
}

type FileReader interface {
	ReadFile(filename string) ([]byte, error)
}
