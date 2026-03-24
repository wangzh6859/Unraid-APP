import React from 'react';

// Display container name, state, and resource usage (CPU / Memory).
// Removed: colored status dot and remote icon fetch — replaced with lightweight resource metrics.
const ContainerStatus = ({ container }) => {
  const formatCpu = (cpu) => {
    if (cpu == null) return 'N/A';
    // assume cpu is a fraction like 0.123 or percentage number
    if (cpu <= 1) return `${(cpu * 100).toFixed(1)}%`;
    return `${cpu.toFixed(1)}%`;
  };

  const formatMemory = (memBytes) => {
    if (memBytes == null) return 'N/A';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    let val = memBytes;
    let i = 0;
    while (val >= 1024 && i < units.length - 1) {
      val /= 1024;
      i++;
    }
    return `${val.toFixed(1)} ${units[i]}`;
  };

  return (
    <div className="card">
      <div className="header">
        <div className="name">{container.name}</div>
        <div className="state">{container.state}</div>
      </div>

      <div className="resources">
        <div className="cpu">
          <div className="label">CPU</div>
          <div className="value">{formatCpu(container.cpu)}</div>
        </div>
        <div className="memory">
          <div className="label">Memory</div>
          <div className="value">{formatMemory(container.memory)}</div>
        </div>
      </div>
    </div>
  );
};

export default ContainerStatus;
