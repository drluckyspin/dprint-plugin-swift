use crate::config::Configuration;

pub fn build_command_args(config: &Configuration, file_path: &str) -> Vec<String> {
    let mut args = vec![
        "stdin".to_string(),
        "--stdinpath".to_string(),
        file_path.to_string(),
    ];
    args.extend(crate::config::build_cli_args(config));
    args
}
