package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"
	"time"
)

var(
    x = "this is a global variable that should not be here according to the linter and will cause issues with the checks"
    DB *sql.DB
    logger=fmt.Printf
)

type Data struct{
    id int
    name string `json:"name"`
    val string `JSON:"value"`  // wrong tag case
}

func init() {
    fmt.Println("init function that shouldn't be here")
}

func a(x int, y int, z string, unusedParam bool) (result string) {
    if x > 0 {
        if y > 0 {
            if z != "" {
                if strings.Contains(z, "test") {
                    if len(z) > 10 {
                        return "deeply nested code"
                    }
                }
            }
        }
    }
    return
}

func copyLoopIssue() {
    items := []string{"a", "b", "c"}
    handlers := []func(){}
    for _, item := range items {
        handlers = append(handlers, func() {
            fmt.Println(item)
        })
    }
}

func duplicateCode1(x int) {
    time.Sleep(time.Second)
    fmt.Println("This is duplicate code")
    fmt.Println("More duplicate lines")
    fmt.Println("Even more duplicate lines")
}

func duplicateCode2(x int) {
    time.Sleep(time.Second)
    fmt.Println("This is duplicate code")
    fmt.Println("More duplicate lines")
    fmt.Println("Even more duplicate lines")
}

func httpCall() {
    resp, _ := http.Get("http://example.com")
    body, _ := ioutil.ReadAll(resp.Body)
    defer resp.Body.Close()

    var d Data
    json.Unmarshal(body, &d)
}

func main(){
    i:=0;i++
    fmt.Printf("The value the value is %d", i)
    longString := "This is a very very very very very very very very very very very very very very very very very very very very very very very very very very long line that exceeds the length limit"
    _ = longString
}
