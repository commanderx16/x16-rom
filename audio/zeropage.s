.exportzp r0, r0L, r0H

.zeropage
  r0: .res 2
  r0L := r0
  r0H := r0+1
