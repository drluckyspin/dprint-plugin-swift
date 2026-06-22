mod config;
mod formatter;
mod handler;

use dprint_core::plugins::process::get_parent_process_id_from_cli_args;
use dprint_core::plugins::process::handle_process_stdio_messages;
use dprint_core::plugins::process::start_parent_process_checker_task;

use handler::SwiftFormatPluginHandler;

#[tokio::main(flavor = "current_thread")]
async fn main() {
    if let Some(parent_process_id) = get_parent_process_id_from_cli_args() {
        start_parent_process_checker_task(parent_process_id);
    }

    if let Err(err) = handle_process_stdio_messages(SwiftFormatPluginHandler).await {
        eprintln!("Shutting down due to error: {err}");
        std::process::exit(1);
    }
}
