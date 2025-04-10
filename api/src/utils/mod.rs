mod log_layout;

/// Configure observability functions like logging and tracing
/// 
/// - `service_name`: The name to use for tracing service visualization
pub(crate) fn observe(service_name: &str) {

  // Setup logging with logforth
  logforth::builder()

    // Log to stdout
    .dispatch(|x|
      x.append(logforth::append::Stdout::default().with_layout(log_layout::LogLayout))
    )

    // Integrate with tracing
    .dispatch(|x|
      // Attaches trace id to logs
      x.diagnostic(logforth::diagnostic::FastraceDiagnostic::default())
        // Attaches logs to spans
        .append(logforth::append::FastraceEvent::default())
    )
    .apply();

  // Setup tracing with fastrace
  // fastrace::set_reporter(
  //   fastrace::collector::ConsoleReporter,
  //   fastrace::collector::Config::default()
  // );
  // fastrace::set_reporter(
  //     fastrace_jaeger::JaegerReporter::new("127.0.0.1:6831".parse().unwrap(), service_name).unwrap(),
  //     fastrace::collector::Config::default()
  // );

  log::info!("Starting {}...", service_name);
}
