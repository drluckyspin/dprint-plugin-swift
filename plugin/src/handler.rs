use std::sync::Arc;

use dprint_core::async_runtime::async_trait;
use dprint_core::configuration::ConfigKeyMap;
use dprint_core::configuration::GlobalConfiguration;
use dprint_core::plugins::AsyncPluginHandler;
use dprint_core::plugins::CheckConfigUpdatesMessage;
use dprint_core::plugins::ConfigChange;
use dprint_core::plugins::FileMatchingInfo;
use dprint_core::plugins::FormatError;
use dprint_core::plugins::FormatRequest;
use dprint_core::plugins::FormatResult;
use dprint_core::plugins::HostFormatRequest;
use dprint_core::plugins::PluginInfo;
use dprint_core::plugins::PluginResolveConfigurationResult;

use crate::config::resolve_config;
use crate::config::Configuration;
use crate::formatter::format_with_swiftformat;

pub struct SwiftFormatPluginHandler;

#[async_trait(?Send)]
impl AsyncPluginHandler for SwiftFormatPluginHandler {
    type Configuration = Configuration;

    fn plugin_info(&self) -> PluginInfo {
        PluginInfo {
            name: env!("CARGO_PKG_NAME").to_string(),
            version: include_str!("../../metadata/VERSION").trim().to_string(),
            config_key: "swiftformat".to_string(),
            help_url: "https://github.com/drluckyspin/dprint-plugin-swift".to_string(),
            config_schema_url: format!(
                "https://plugins.dprint.dev/drluckyspin/swiftformat/v{}/schema.json",
                include_str!("../../metadata/VERSION").trim()
            ),
            update_url: Some(
                "https://plugins.dprint.dev/drluckyspin/swiftformat/latest.json".to_string(),
            ),
        }
    }

    fn license_text(&self) -> String {
        include_str!("../../metadata/LICENSES").to_string()
    }

    async fn resolve_config(
        &self,
        config: ConfigKeyMap,
        global_config: GlobalConfiguration,
    ) -> PluginResolveConfigurationResult<Configuration> {
        let result = resolve_config(config, global_config);
        PluginResolveConfigurationResult {
            config: result.config,
            diagnostics: result.diagnostics,
            file_matching: FileMatchingInfo {
                file_extensions: vec!["swift".to_string()],
                file_names: vec![],
            },
        }
    }

    async fn check_config_updates(
        &self,
        _message: CheckConfigUpdatesMessage,
    ) -> Result<Vec<ConfigChange>, FormatError> {
        Ok(Vec::new())
    }

    async fn format(
        &self,
        request: FormatRequest<Self::Configuration>,
        _format_with_host: impl FnMut(
                HostFormatRequest,
            ) -> dprint_core::async_runtime::LocalBoxFuture<'static, FormatResult>
            + 'static,
    ) -> FormatResult {
        if request.range.is_some() {
            return Ok(None);
        }

        let file_text = String::from_utf8(request.file_bytes.clone())?;
        let cancel = Arc::new(tokio::sync::Notify::new());
        let cancel_for_wait = cancel.clone();

        let format_future =
            format_with_swiftformat(&request.file_path, &file_text, &request.config, cancel);

        tokio::select! {
            _ = request.token.wait_cancellation() => {
                cancel_for_wait.notify_waiters();
                Ok(None)
            }
            result = format_future => {
                match result {
                    Ok(Some(formatted)) => Ok(Some(formatted.into_bytes())),
                    Ok(None) => Ok(None),
                    Err(err) => Err(err.to_string().into()),
                }
            }
        }
    }
}
