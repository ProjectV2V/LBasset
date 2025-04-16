
package main

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"io"
	"log"
	"math/rand"
	"net"
	"net/http"
	"os"
	"time"

	"golang.org/x/net/proxy"
)

var socksAddr = "91.225.219.139:44445"
var username = "gargallow"
var password = "mashin"
var listenPort = ":8081"

var androidUserAgents = []string{
	"Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 Chrome/91.0.4472.120 Mobile Safari/537.36",
	"Mozilla/5.0 (Linux; Android 9; Pixel 3) AppleWebKit/537.36 Chrome/92.0.4515.159 Mobile Safari/537.36",
	"Mozilla/5.0 (Linux; Android 11; Redmi Note 8T) AppleWebKit/537.36 Chrome/94.0.4606.71 Mobile Safari/537.36",
}

func randomHex(n int) string {
	b := make([]byte, n)
	_, _ = rand.Read(b)
	return hex.EncodeToString(b)
}

func getRandomUA() string {
	return androidUserAgents[rand.Intn(len(androidUserAgents))]
}

func handleTunneling(w http.ResponseWriter, r *http.Request) {
	destConn, err := net.Dial("tcp", r.Host)
	if err != nil {
		http.Error(w, err.Error(), http.StatusServiceUnavailable)
		return
	}

	hijacker, ok := w.(http.Hijacker)
	if !ok {
		http.Error(w, "Hijacking not supported", http.StatusInternalServerError)
		return
	}
	clientConn, _, err := hijacker.Hijack()
	if err != nil {
		http.Error(w, err.Error(), http.StatusServiceUnavailable)
		return
	}

	fmt.Fprintf(clientConn, "HTTP/1.1 200 Connection Established\r\n")
	fmt.Fprintf(clientConn, "Proxy-Agent: go-bridge\r\n")
	fmt.Fprintf(clientConn, "Connection: keep-alive\r\n\r\n")

	go transfer(destConn, clientConn)
	go transfer(clientConn, destConn)
}

func transfer(destination io.WriteCloser, source io.ReadCloser) {
	defer destination.Close()
	defer source.Close()
	io.Copy(destination, source)
}

func handleHTTP(w http.ResponseWriter, req *http.Request) {
	dialer, err := proxy.SOCKS5("tcp", socksAddr, &proxy.Auth{
		User:     username,
		Password: password,
	}, proxy.Direct)
	if err != nil {
		http.Error(w, "Proxy error", http.StatusBadGateway)
		return
	}

	transport := &http.Transport{
		Dial: dialer.Dial,
	}

	client := &http.Client{
		Transport: transport,
		Timeout:   10 * time.Second,
	}

	req.RequestURI = ""
	req.URL.Scheme = "http"
	req.URL.Host = req.Host
	req.Header.Set("User-Agent", getRandomUA())
	req.Header.Set("Cookie", "session_id=" + randomHex(8))
	req.Header.Set("Accept-Language", "en-US,en;q=0.9")
	req.Header.Set("Connection", "keep-alive")

	log.Printf("[+] %s %s", req.Method, req.URL)
	log.Printf("    UA: %s", req.Header.Get("User-Agent"))
	log.Printf("    Cookie: %s", req.Header.Get("Cookie"))

	resp, err := client.Do(req)
	if err != nil {
		http.Error(w, "Upstream error", http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	for k, vv := range resp.Header {
		for _, v := range vv {
			w.Header().Add(k, v)
		}
	}

	w.WriteHeader(resp.StatusCode)
	io.Copy(w, resp.Body)
}

func main() {
	rand.Seed(time.Now().UnixNano())
	log.Println("[✓] Go HTTP-to-SOCKS5 bridge is running on port", listenPort)

	server := &http.Server{
		Addr: listenPort,
		Handler: http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if r.Method == http.MethodConnect {
				handleTunneling(w, r)
			} else {
				handleHTTP(w, r)
			}
		}),
	}

	log.Fatal(server.ListenAndServe())
}
