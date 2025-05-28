#!/usr/bin/env python3

import sys
import os
from datetime import datetime

# Add your MobileInsight path
sys.path.insert(0, '/home/mobileinsight/MobileInsightsAugmented')

try:
    # Import MobileInsight components
    from mobile_insight.monitor import OnlineMonitor
    from mobile_insight.analyzer import *
    
    def start_log_collection():
        """Start collecting logs from connected Android device"""
        
        # Create monitor instance
        src = OnlineMonitor()
        
        # Set the log directory
        log_dir = "./collected_logs"
        if not os.path.exists(log_dir):
            os.makedirs(log_dir)
        
        # Generate log filename with timestamp
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        log_file = f"{log_dir}/mobile_log_{timestamp}.mi2log"
        
        # Set log file destination
        src.set_log_file(log_file)
        
        # Enable log types you want to collect
        log_types = [
            "LTE_RRC_OTA_Packet",
            "LTE_NAS_ESM_OTA_Incoming_Packet", 
            "LTE_NAS_ESM_OTA_Outgoing_Packet",
            "LTE_NAS_EMM_OTA_Incoming_Packet",
            "LTE_NAS_EMM_OTA_Outgoing_Packet",
            "5G_NR_RRC_OTA_Packet",
            "5G_NR_NAS_5GSM_OTA_Incoming_Packet",
            "5G_NR_NAS_5GSM_OTA_Outgoing_Packet",
            "LTE_PHY_Serv_Cell_Measurement",
            "LTE_PHY_Connected_Mode_Intra_Freq_Meas",
            "LTE_PHY_Connected_Mode_Neighbor_Measurement",
            "LTE_PHY_Inter_RAT_Measurement",
            "LTE_PHY_PDSCH_Packet",
            "LTE_PHY_PUSCH_CSF",
            "LTE_MAC_UL_Tx_Statistics",
            "LTE_MAC_DL_Tx_Statistics"
        ]
        
        # Enable each log type
        for log_type in log_types:
            try:
                src.enable_log(log_type)
                print(f"✓ Enabled: {log_type}")
            except Exception as e:
                print(f"✗ Failed to enable {log_type}: {e}")
        
        # Optional: Add analyzers for real-time processing
        # lte_rrc_analyzer = LteRrcAnalyzer()
        # lte_rrc_analyzer.set_source(src)
        
        print(f"\n=== Starting Log Collection ===")
        print(f"Log file: {log_file}")
        print(f"Press Ctrl+C to stop collection\n")
        
        try:
            # Start the monitor
            src.run()
        except KeyboardInterrupt:
            print("\n=== Stopping Log Collection ===")
            print(f"Log file saved: {log_file}")
            print(f"File size: {os.path.getsize(log_file) if os.path.exists(log_file) else 0} bytes")
        except Exception as e:
            print(f"Error during collection: {e}")

    if __name__ == "__main__":
        start_log_collection()
        
except ImportError as e:
    print(f"Import error: {e}")
    print("\nTroubleshooting:")
    print("1. Make sure MobileInsight is properly installed")
    print("2. Check if your Android device is connected and in debug mode")
    print("3. Verify ADB is working: 'adb devices'")
    print("4. Check if diag mode is enabled on your device")
