import React from "react";
import { MerSuiProvider, MerSuiWidget } from "mersui";

export function MerSui() {
  return (
    <MerSuiProvider>
      <MerSuiWidget recipientAddress="0xe91e4925e5d68dafa7b484022c14d40b64b6a4ffae37683b6bf2aa760c059b61" />
    </MerSuiProvider>
  );
}
