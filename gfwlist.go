package main

import (
	"bufio"
	"encoding/base64"
	"flag"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"sort"
	"strings"

	"github.com/golang/glog"
)

const (
	url_gfwlist = "https://github.com/gfwlist/gfwlist/raw/master/gfwlist.txt"
	chars_not   = "*%?():/"
)

var (
	gfwlistPath string
)

type Empty struct{}

type ABPRule struct {
	host        string
	hosts       []string
	isException bool
}

func (r *ABPRule) validate() error {
	validateHost := func(s string) error {
		if s == "" {
			return fmt.Errorf("empty name")
		}
		if !strings.ContainsRune(s, '.') {
			return fmt.Errorf("plain name")
		}
		if strings.HasPrefix(s, ".") {
			return fmt.Errorf("starts with dot")
		}
		if strings.ContainsAny(s, chars_not) {
			return fmt.Errorf("contains %q", chars_not)
		}
		return nil
	}
	if len(r.hosts) == 0 {
		if err := validateHost(r.host); err != nil {
			return fmt.Errorf("%q: %v", r.host, err)
		}
	}
	for _, host := range r.hosts {
		if err := validateHost(host); err != nil {
			return fmt.Errorf("%q: %v", host, err)
		}
	}
	return nil
}

func (r *ABPRule) DnsmasqServerLines() []string {
	var server string
	if !r.isException {
		server = "in_gfw"
	} else {
		server = "not_in_gfw"
	}
	ss := []string{}
	if r.host != "" {
		ss = append(ss, fmt.Sprintf("server=/%s/%s", r.host, server))
	}
	for _, host := range r.hosts {
		ss = append(ss, fmt.Sprintf("server=/%s/%s", host, server))
	}
	return ss
}

func parseLine(line string) (*ABPRule, error) {
	line = strings.TrimSpace(line)
	if line == "" || strings.HasPrefix(line, "!") {
		// empty, comment line
		return nil, nil
	}

	if strings.HasPrefix(line, "|") {
		// |, scheme sensitive prefix match
		// ||, host suffix match and path prefix match
		line = strings.TrimLeft(line, "|")
		return parseLine(line)
	}

	if strings.HasPrefix(line, "/") {
		// regex
		//
		// special case google
		const google_sig = `google\.(`
		if sidx := strings.Index(line, google_sig); sidx >= 0 {
			line = line[sidx+len(google_sig):]
			if eidx := strings.Index(line, ")"); eidx >= 0 {
				line = line[:eidx]
				suffixes := strings.Split(line, "|")
				hosts := make([]string, 0, len(suffixes))
				for _, suffix := range suffixes {
					hosts = append(hosts, "google."+suffix)
				}
				r := &ABPRule{
					hosts: hosts,
				}
				return r, nil
			}
		}
		line = strings.Trim(line, "/^$")
		line = strings.Replace(line, `\/`, `/`, -1)
		line = strings.Replace(line, `\.`, `.`, -1)
		return parseLine(line)
	}

	if strings.HasPrefix(line, "@@") {
		// exception rule
		line = line[2:]
		rule, err := parseLine(line)
		if err != nil {
			return nil, err
		}
		rule.isException = true
		return rule, nil
	}

	if strings.HasPrefix(line, "[") {
		// [AutoProxy 0.2.9]
		return nil, nil
	}

	isPureIP := false
	if host, _, err := net.SplitHostPort(line); err == nil {
		if ip := net.ParseIP(host); ip != nil {
			isPureIP = true
		}
	} else if ip := net.ParseIP(line); ip != nil {
		isPureIP = true
	}
	if isPureIP {
		return nil, nil
	}

	url, _ := url.Parse(line)
	if url != nil {
		host := url.Hostname()
		if host != "" {
			if i := strings.Index(host, "*"); i >= 0 {
				host = host[i+1:]
				host = strings.TrimLeft(host, ".")
			}
			if !strings.ContainsRune(line, '.') {
				return nil, nil
			}
			rule := &ABPRule{
				host: host,
			}
			return rule, nil
		}
	}

	lines := strings.SplitN(line, "/", 2) // example.com/path
	line = lines[0]

	if strings.ContainsAny(line, chars_not) {
		return nil, nil
	}
	line = strings.TrimLeft(line, ".") // .example.com
	if !strings.ContainsRune(line, '.') {
		return nil, nil
	}
	rule := &ABPRule{
		host: line,
	}
	return rule, nil
}

func main() {
	flag.Set("stderrthreshold", "0")
	flag.Set("logtostderr", "true")
	flag.StringVar(&gfwlistPath, "gfwlist", url_gfwlist, "Path to raw gfwlist.txt")
	flag.Parse()

	var gfwlistReader io.Reader
	if strings.HasPrefix(gfwlistPath, "http://") ||
		strings.HasPrefix(gfwlistPath, "https://") {
		resp, err := http.Get(gfwlistPath)
		if err != nil {
			glog.Fatal(err)
		}
		defer resp.Body.Close()
		gfwlistReader = resp.Body
	} else {
		f, err := os.Open(gfwlistPath)
		if err != nil {
			glog.Fatal(err)
		}
		gfwlistReader = f
		defer f.Close()
	}

	serverLines := map[string]Empty{}
	{
		gfwlistBase64Reader := base64.NewDecoder(base64.StdEncoding, gfwlistReader)
		gfwlistBufReader := bufio.NewReader(gfwlistBase64Reader)
		for {
			line, err := gfwlistBufReader.ReadString('\n')
			if err == io.EOF {
				break
			}
			if err != nil {
				glog.Fatalf("read %s: %v", gfwlistPath, err)
			}
			r, err := parseLine(line)
			if err != nil {
				glog.Warningf("parse line: %q: %v", line, err)
			}
			if r != nil {
				if err := r.validate(); err != nil {
					glog.Fatalf("validate parse result: %q: %v", line, err)
				}
				ss := r.DnsmasqServerLines()
				for _, s := range ss {
					if _, ok := serverLines[s]; !ok {
						serverLines[s] = Empty{}
					}
				}
			}
		}
	}
	lines := make([]string, 0, len(serverLines))
	for s := range serverLines {
		lines = append(lines, s)
	}
	sort.Strings(lines)
	for _, s := range lines {
		fmt.Println(s)
	}
}
