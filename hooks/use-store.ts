
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { ScanResult } from '@/types/scan';

interface AppState {
  // History of scans
  scanHistory: ScanResult[];
  addScan: (scan: ScanResult) => void;
  removeScan: (id: string) => void;
  clearHistory: () => void;
  
  // App settings
  showFps: boolean;
  toggleFps: () => void;
  
  // AI model status
  isModelLoaded: boolean;
  setModelLoaded: (loaded: boolean) => void;
}

export const useStore = create<AppState>()(
  persist(
    (set) => ({
      // Scan history
      scanHistory: [],
      addScan: (scan) => set((state) => ({ 
        scanHistory: [scan, ...state.scanHistory] 
      })),
      removeScan: (id) => set((state) => ({ 
        scanHistory: state.scanHistory.filter((scan) => scan.id !== id) 
      })),
      clearHistory: () => set({ scanHistory: [] }),
      
      // Settings
      showFps: false,
      toggleFps: () => set((state) => ({ showFps: !state.showFps })),
      
      // AI model status
      isModelLoaded: false,
      setModelLoaded: (loaded) => set({ isModelLoaded: loaded }),
    }),
    {
      name: 'orange-quality-app-storage',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);