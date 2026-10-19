package com.minespace.unofficial.gtceu.nuclear;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * Optional diagnostic entry point. It intentionally imports no NCO/QMD types so the
 * normal game classpath never needs those jars.
 */
public final class MinespaceDiagnosticsEvents {

    private static final Logger LOG = LogManager.getLogger("minespace_core");

    private MinespaceDiagnosticsEvents() {
    }

    public static void exportIfRequested() {
        if (!Boolean.getBoolean("minespace.exportDiagnostics")) {
            return;
        }
        try {
            Class.forName("com.minespace.unofficial.gtceu.nuclear.MinespaceDiagnostics")
                    .getMethod("exportAll")
                    .invoke(null);
        } catch (ReflectiveOperationException e) {
            LOG.warn("diagnostic export could not start", e);
        }
    }
}
