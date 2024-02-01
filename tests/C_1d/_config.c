#include "error.h"

const int mainHasArgs = 0;
const int mainPreserveDelimiter = 0;
const int warnUnstable = 0;
void CreateConfigVarTable(void) {
  initConfigVarTable();
  installConfigVar("printModuleInitOrder", "bool", "Built-in", /* private = */ 0, /* deprecated = */ 0, "printModuleInitOrder is deprecated"
                   , /* unstable = */ 1, "The variable 'printModuleInitOrder' is unstable and its interface is subject to change in the future"
                   );
  installConfigVar("dataParTasksPerLocale", "int(64)", "Built-in", /* private = */ 0, /* deprecated = */ 0, "dataParTasksPerLocale is deprecated"
                   , /* unstable = */ 1, "The variable 'dataParTasksPerLocale' is unstable and its interface is subject to change in the future"
                   );
  installConfigVar("dataParIgnoreRunningTasks", "bool", "Built-in", /* private = */ 0, /* deprecated = */ 0, "dataParIgnoreRunningTasks is deprecated"
                   , /* unstable = */ 1, "The variable 'dataParIgnoreRunningTasks' is unstable and its interface is subject to change in the future"
                   );
  installConfigVar("dataParMinGranularity", "int(64)", "Built-in", /* private = */ 0, /* deprecated = */ 0, "dataParMinGranularity is deprecated"
                   , /* unstable = */ 1, "The variable 'dataParMinGranularity' is unstable and its interface is subject to change in the future"
                   );
  installConfigVar("memTrack", "bool", "Built-in", /* private = */ 0, /* deprecated = */ 0, "memTrack is deprecated"
                   , /* unstable = */ 1, "The variable 'memTrack' is unstable and its interface is subject to change in the future"
                   );
  installConfigVar("memStats", "bool", "Built-in", /* private = */ 0, /* deprecated = */ 0, "memStats is deprecated"
                   , /* unstable = */ 1, "The variable 'memStats' is unstable and its interface is subject to change in the future"
                   );
  installConfigVar("memLeaksByType", "bool", "Built-in", /* private = */ 0, /* deprecated = */ 0, "memLeaksByType is deprecated"
                   , /* unstable = */ 1, "The variable 'memLeaksByType' is unstable and its interface is subject to change in the future"
                   );
  installConfigVar("memLeaks", "bool", "Built-in", /* private = */ 0, /* deprecated = */ 0, "memLeaks is deprecated"
                   , /* unstable = */ 1, "The variable 'memLeaks' is unstable and its interface is subject to change in the future"
                   );
  installConfigVar("memMax", "uint(64)", "Built-in", /* private = */ 0, /* deprecated = */ 0, "memMax is deprecated"
                   , /* unstable = */ 1, "The variable 'memMax' is unstable and its interface is subject to change in the future"
                   );
  installConfigVar("memThreshold", "uint(64)", "Built-in", /* private = */ 0, /* deprecated = */ 0, "memThreshold is deprecated"
                   , /* unstable = */ 1, "The variable 'memThreshold' is unstable and its interface is subject to change in the future"
                   );
  installConfigVar("memLog", "string", "Built-in", /* private = */ 0, /* deprecated = */ 0, "memLog is deprecated"
                   , /* unstable = */ 1, "The variable 'memLog' is unstable and its interface is subject to change in the future"
                   );
  installConfigVar("memLeaksLog", "string", "Built-in", /* private = */ 0, /* deprecated = */ 0, "memLeaksLog is deprecated"
                   , /* unstable = */ 1, "The variable 'memLeaksLog' is unstable and its interface is subject to change in the future"
                   );
  installConfigVar("memLeaksByDesc", "string", "Built-in", /* private = */ 0, /* deprecated = */ 0, "memLeaksByDesc is deprecated"
                   , /* unstable = */ 1, "The variable 'memLeaksByDesc' is unstable and its interface is subject to change in the future"
                   );
  installConfigVar("debugGpu", "bool", "Built-in", /* private = */ 0, /* deprecated = */ 0, "debugGpu is deprecated"
                   , /* unstable = */ 1, "The variable 'debugGpu' is unstable and its interface is subject to change in the future"
                   );
  installConfigVar("gpuNoCpuModeWarning", "bool", "Built-in", /* private = */ 0, /* deprecated = */ 0, "gpuNoCpuModeWarning is deprecated"
                   , /* unstable = */ 1, "The variable 'gpuNoCpuModeWarning' is unstable and its interface is subject to change in the future"
                   );
  installConfigVar("gpuSyncWithHostAfterGpuOp", "bool", "Built-in", /* private = */ 0, /* deprecated = */ 0, "gpuSyncWithHostAfterGpuOp is deprecated"
                   , /* unstable = */ 1, "The variable 'gpuSyncWithHostAfterGpuOp' is unstable and its interface is subject to change in the future"
                   );
  installConfigVar("gpuUseStreamPerTask", "bool", "Built-in", /* private = */ 0, /* deprecated = */ 0, "gpuUseStreamPerTask is deprecated"
                   , /* unstable = */ 1, "The variable 'gpuUseStreamPerTask' is unstable and its interface is subject to change in the future"
                   );
  installConfigVar("enableGpuP2P", "bool", "Built-in", /* private = */ 0, /* deprecated = */ 0, "enableGpuP2P is deprecated"
                   , /* unstable = */ 1, "The variable 'enableGpuP2P' is unstable and its interface is subject to change in the future"
                   );
  installConfigVar("defaultHashTableResizeThreshold", "real(64)", "Built-in", /* private = */ 0, /* deprecated = */ 0, "defaultHashTableResizeThreshold is deprecated"
                   , /* unstable = */ 0, "defaultHashTableResizeThreshold is unstable"
                   );
  installConfigVar("numLocales", "int(64)", "Built-in", /* private = */ 0, /* deprecated = */ 0, "numLocales is deprecated"
                   , /* unstable = */ 0, "numLocales is unstable"
                   );
}


