use std::collections::BTreeMap;

use dprint_core::configuration::get_nullable_value;
use dprint_core::configuration::get_unknown_property_diagnostics;
use dprint_core::configuration::ConfigKeyMap;
use dprint_core::configuration::ConfigKeyValue;
use dprint_core::configuration::ConfigurationDiagnostic;
use dprint_core::configuration::GlobalConfiguration;
use dprint_core::configuration::ResolveConfigurationResult;
use serde::Deserialize;
use serde::Serialize;

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Configuration {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub swift_version: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub config_path: Option<String>,
    #[serde(default, skip_serializing_if = "BTreeMap::is_empty")]
    pub options: BTreeMap<String, ConfigKeyValue>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub line_width: Option<u32>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub indent_width: Option<u32>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub use_tabs: Option<bool>,
}

pub fn resolve_config(
    config: ConfigKeyMap,
    global_config: GlobalConfiguration,
) -> ResolveConfigurationResult<Configuration> {
    let mut config = config;
    let mut diagnostics = Vec::new();

    let swift_version = get_nullable_value(&mut config, "swiftVersion", &mut diagnostics);
    let config_path = get_nullable_value(&mut config, "configPath", &mut diagnostics);
    let options = take_options_map(&mut config, &mut diagnostics);

    let line_width = get_nullable_value::<u32>(&mut config, "lineWidth", &mut diagnostics)
        .or(global_config.line_width);
    let indent_width = get_nullable_value::<u32>(&mut config, "indentWidth", &mut diagnostics)
        .or(global_config.indent_width.map(u32::from));
    let use_tabs = get_nullable_value::<bool>(&mut config, "useTabs", &mut diagnostics)
        .or(global_config.use_tabs);

    diagnostics.extend(get_unknown_property_diagnostics(config));

    ResolveConfigurationResult {
        config: Configuration {
            swift_version,
            config_path,
            options,
            line_width,
            indent_width,
            use_tabs,
        },
        diagnostics,
    }
}

pub fn build_cli_args(config: &Configuration) -> Vec<String> {
    let mut args = Vec::new();

    if let Some(swift_version) = &config.swift_version {
        args.push("--swiftversion".to_string());
        args.push(swift_version.clone());
    }

    if let Some(config_path) = &config.config_path {
        args.push("--config".to_string());
        args.push(config_path.clone());
    }

    if let Some(line_width) = config.line_width {
        args.push("--maxwidth".to_string());
        args.push(line_width.to_string());
    }

    if let Some(indent_width) = config.indent_width {
        args.push("--indent".to_string());
        args.push(indent_width.to_string());
    }

    if let Some(use_tabs) = config.use_tabs {
        if use_tabs {
            args.push("--tabs".to_string());
            args.push("enabled".to_string());
        } else {
            args.push("--tabwidth".to_string());
            args.push(config.indent_width.unwrap_or(4).to_string());
        }
    }

    for (key, value) in &config.options {
        args.push(format!("--{}", key));
        push_config_value(&mut args, value);
    }

    args
}

fn push_config_value(args: &mut Vec<String>, value: &ConfigKeyValue) {
    match value {
        ConfigKeyValue::String(s) => args.push(s.clone()),
        ConfigKeyValue::Number(n) => args.push(n.to_string()),
        ConfigKeyValue::Bool(b) => args.push(b.to_string()),
        ConfigKeyValue::Array(values) => {
            for item in values {
                push_config_value(args, item);
            }
        }
        ConfigKeyValue::Object(_) | ConfigKeyValue::Null => {}
    }
}

fn take_options_map(
    config: &mut ConfigKeyMap,
    diagnostics: &mut Vec<ConfigurationDiagnostic>,
) -> BTreeMap<String, ConfigKeyValue> {
    match config.shift_remove("options") {
        Some(ConfigKeyValue::Object(map)) => map.into_iter().collect(),
        Some(_) => {
            diagnostics.push(ConfigurationDiagnostic {
                property_name: "options".to_string(),
                message: "Expected an object.".to_string(),
            });
            BTreeMap::new()
        }
        None => BTreeMap::new(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn maps_globals_to_cli_args() {
        let config = Configuration {
            swift_version: Some("5.9".to_string()),
            config_path: None,
            options: BTreeMap::new(),
            line_width: Some(100),
            indent_width: Some(2),
            use_tabs: Some(false),
        };

        let args = build_cli_args(&config);
        assert!(args.contains(&"--swiftversion".to_string()));
        assert!(args.contains(&"5.9".to_string()));
        assert!(args.contains(&"--maxwidth".to_string()));
        assert!(args.contains(&"100".to_string()));
        assert!(args.contains(&"--indent".to_string()));
        assert!(args.contains(&"2".to_string()));
    }
}
