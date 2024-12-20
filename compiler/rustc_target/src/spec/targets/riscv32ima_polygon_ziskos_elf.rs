use crate::spec::{Cc, LinkerFlavor, Lld, PanicStrategy, RelocModel};
use crate::spec::{Target, TargetOptions};

pub(crate) fn target() -> Target {
    Target {
        data_layout: "e-m:e-p:32:32-i64:64-n32-S128".into(),
        llvm_target: "riscv32".into(),
        metadata: crate::spec::TargetMetadata {
            description: None,
            tier: None,
            host_tools: None,
            std: None,
        },
        pointer_width: 32,
        arch: "riscv32".into(),

        options: TargetOptions {
            os: "ziskos".into(),
            vendor: "polygon".into(),
            linker_flavor: LinkerFlavor::Gnu(Cc::No, Lld::Yes),
            linker: Some("rust-lld".into()),
            cpu: "generic-rv32".into(),

            max_atomic_width: Some(64),
            atomic_cas: true,

            features: "+m,+a".into(),
            executables: true,
            panic_strategy: PanicStrategy::Abort,
            relocation_model: RelocModel::Static,
            emit_debug_gdb_scripts: false,
            eh_frame_header: false,
            singlethread: true,
            ..Default::default()
        },
    }
}
