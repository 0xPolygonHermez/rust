use crate::spec::{Cc, CodeModel, LinkerFlavor, Lld, PanicStrategy};
use crate::spec::{RelocModel, SanitizerSet, Target, TargetOptions};

// The PSP has custom linker requirements.
const LINKER_SCRIPT: &str = include_str!("./riscv64ima_polygon_ziskos_elf_linker_script.ld");

pub(crate) fn target() -> Target {
    Target {
        data_layout: "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128".into(),
        llvm_target: "riscv64".into(),
        metadata: crate::spec::TargetMetadata {
            description: None,
            tier: None,
            host_tools: None,
            std: None,
        },
        pointer_width: 64,
        arch: "riscv64".into(),

        options: TargetOptions {
            os: "ziskos".into(),
            vendor: "polygon".into(),
            linker_flavor: LinkerFlavor::Gnu(Cc::No, Lld::Yes),
            linker: Some("rust-lld".into()),
            cpu: "generic-rv64".into(),
            max_atomic_width: Some(64),
            features: "+m,+a".into(),
            panic_strategy: PanicStrategy::Abort,
            relocation_model: RelocModel::Static,
            code_model: Some(CodeModel::Medium),
            emit_debug_gdb_scripts: false,
            eh_frame_header: false,
            supported_sanitizers: SanitizerSet::KERNELADDRESS,
            link_script: Some(LINKER_SCRIPT.into()),
            ..Default::default()
        },
    }
}
