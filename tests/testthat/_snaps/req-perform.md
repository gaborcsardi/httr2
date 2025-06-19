# curl errors become errors

    Code
      req_perform(req)
    Condition
      Error in `req_perform()`:
      ! Failed to perform HTTP request.
      Caused by error in `curl_fetch()`:
      ! Failed to connect

# http errors become errors

    Code
      req_perform(req)
    Condition
      Error in `req_perform()`:
      ! HTTP 404 Not Found.

---

    Code
      req_perform(req)
    Condition
      Error in `req_perform()`:
      ! HTTP 429 Too Many Requests.

---

    Code
      req_perform(req)
    Condition
      Error in `req_perform()`:
      ! HTTP 599.

# checks input types

    Code
      req_perform(req, path = 1)
    Condition
      Error in `req_perform()`:
      ! `path` must be a single string or `NULL`, not the number 1.
    Code
      req_perform(req, verbosity = 1.5)
    Condition
      Error in `req_perform()`:
      ! `verbosity` must 0, 1, 2, or 3.
    Code
      req_perform(req, mock = 7)
    Condition
      Error in `req_perform()`:
      ! `mock` must be a function or `NULL`, not the number 7.

# tracing works as expected

    Code
      try(req_perform(request("")), silent = TRUE)
    Message
      OpenTelemetry error: Failed to parse URL: Malformed input to a URL function
      OpenTelemetry error: Failed to parse URL: Malformed input to a URL function

---

    Code
      sort(names(attr))
    Output
      [1] "http.request.method"       "http.response.status_code"
      [3] "server.address"            "server.port"              
      [5] "url.full"                  "user_agent.original"      

---

    Code
      spans[["httr2::req_perform"]]$attributes[red]
    Output
      $server.address
      [1] "127.0.0.1"
      
      $url.full
      [1] "http://REDACTED:REDACTED@127.0.0.1:<port>/"
      
    Code
      spans[["httr2::req_perform1"]]$attributes[red]
    Output
      $server.address
      [1] "127.0.0.1"
      
      $url.full
      [1] "http://REDACTED:REDACTED@127.0.0.1:<port>/"
      

---

    Code
      spans[["httr2::req_perform"]]$events[[1]]$name
    Output
      [1] "exception"
    Code
      spans[["httr2::req_perform"]]$events[[1]]$attributes$exception.type
    Output
      [1] "httr2_failure" "httr2_error"   "rlang_error"   "error"        
      [5] "condition"    

