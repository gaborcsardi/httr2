has_otel <- function() {
  env_cache(the, "has_otel", is_installed("otel")) && otel::is_tracing()
}

otel_req_start <- function(
  name,
  req,
  ...,
  resend_count = 1L,
  scope = parent.frame()
) {
  req$otel_span <- otel::start_span(
    name,
    options = list(kind = "client"),
    attributes = otel_req_attrs(req, resend_count = resend_count),
    scope = scope,
    ...
  )
  req <- req_headers(req, !!!otel::pack_http_context())
  req
}

otel_req_attrs <- function(req, resend_count = 1) {
  parsed <- url_parse(req$url)
  if (!is.null(parsed$username)) {
    parsed$username <- "REDACTED"
  }
  if (!is.null(parsed$password)) {
    parsed$password <- "REDACTED"
  }
  default_port <- if (parsed$scheme == "https") 443L else 80L
  compact(list(
    "http.request.method" = req_method_get(req),
    "server.address" = parsed$hostname,
    "server.port" = parsed$port %||% default_port,
    "url.full" = url_build(parsed),
    "http.request.resend_count" = if (resend_count > 1) resend_count,
    "user_agent.original" = req_user_agent(req)$options$useragent
  ))
}

otel_handle_resp <- function(req, resp) {
  if (is_error(resp)) {
    req$otel_span$record_exception(resp)
    req$otel_span$set_status("error")
  } else {
    req$otel_span$set_attribute("http.response.status_code", resp_status(resp))
    if (error_is_error(req, resp)) {
      req$otel_span$set_status("error", resp_status_desc(resp))
      # The semantic conventions recommend using the status code as a string for
      # these cases.
      req$otel_span$set_attribute("error.type", as.character(resp_status(resp)))
    }
  }
}
