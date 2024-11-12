import { persistentAtom } from "@nanostores/persistent";
import type { SuiSystemStateSummaryData } from "@typedef/sui";
import { getLatestSuiSystemState } from "@client/sui";
import { network } from "@utils/configs";

export const suiSystemStateAtom =
  persistentAtom<SuiSystemStateSummaryData | null>(
    "suiSystemStateAtom" + network,
    null,
    {
      encode: JSON.stringify,
      decode: JSON.parse,
    },
  );

const suiSystemState = suiSystemStateAtom.get();

if (suiSystemState) {
  if (
    Number(suiSystemState.epochStartTimestampMs) +
      Number(suiSystemState.epochDurationMs) <
    new Date().getTime()
  ) {
    getLatestSuiSystemState().then((latestSuiSystemState) => {
      suiSystemStateAtom.set(latestSuiSystemState);
    });
  }
} else {
  getLatestSuiSystemState().then((latestSuiSystemState) => {
    suiSystemStateAtom.set(latestSuiSystemState);
  });
}
