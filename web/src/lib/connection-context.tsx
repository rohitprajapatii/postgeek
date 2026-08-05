"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { api, getApiUrl, setApiUrl } from "./api";

interface ConnectionState {
  connected: boolean;
  checking: boolean;
  apiUrl: string;
  database?: string;
  host?: string;
  /** e.g. 160013 — used to gate version-dependent features. */
  serverVersionNum?: number;
  serverVersion?: string;
}

interface ConnectionContextValue extends ConnectionState {
  refresh: () => Promise<void>;
  markConnected: (info: { database?: string; host?: string }) => void;
  updateApiUrl: (url: string) => void;
  disconnect: () => Promise<void>;
}

const ConnectionContext = createContext<ConnectionContextValue | null>(null);

export function ConnectionProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<ConnectionState>({
    connected: false,
    checking: true,
    apiUrl: getApiUrl(),
  });

  const refresh = useCallback(async () => {
    setState((s) => ({ ...s, checking: true, apiUrl: getApiUrl() }));
    try {
      const status = await api.status();
      setState((s) => ({
        ...s,
        connected: Boolean(status.isConnected),
        checking: false,
        apiUrl: getApiUrl(),
        database: status.database ?? s.database,
        host: status.host ?? s.host,
        serverVersionNum: status.serverVersionNum ?? s.serverVersionNum,
        serverVersion: status.serverVersion ?? s.serverVersion,
      }));
    } catch {
      setState((s) => ({ ...s, connected: false, checking: false }));
    }
  }, []);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  const markConnected = useCallback((info: { database?: string; host?: string }) => {
    setState((s) => ({ ...s, connected: true, checking: false, ...info }));
    // Pick up server-reported details (version, resolved database/user) without
    // flipping `checking`, which would flash the loading screen after connect.
    void api
      .status()
      .then((status) => {
        setState((s) => ({
          ...s,
          database: status.database ?? s.database,
          host: status.host ?? s.host,
          serverVersionNum: status.serverVersionNum ?? s.serverVersionNum,
          serverVersion: status.serverVersion ?? s.serverVersion,
        }));
      })
      .catch(() => {
        /* non-fatal: version-gated features fall back to attempting anyway */
      });
  }, []);

  const updateApiUrl = useCallback((url: string) => {
    setApiUrl(url);
    setState((s) => ({ ...s, apiUrl: getApiUrl() }));
  }, []);

  const disconnect = useCallback(async () => {
    try {
      await api.disconnect();
    } catch {
      /* ignore */
    }
    setState((s) => ({ ...s, connected: false, database: undefined, host: undefined }));
  }, []);

  const value = useMemo<ConnectionContextValue>(
    () => ({ ...state, refresh, markConnected, updateApiUrl, disconnect }),
    [state, refresh, markConnected, updateApiUrl, disconnect],
  );

  return <ConnectionContext.Provider value={value}>{children}</ConnectionContext.Provider>;
}

export function useConnection() {
  const ctx = useContext(ConnectionContext);
  if (!ctx) throw new Error("useConnection must be used within ConnectionProvider");
  return ctx;
}
