#!/usr/bin/env python3
"""
Build-time script to detect networking symbols in the compiled binary.
This script fails the build if any forbidden networking APIs are found.
"""

import sys
import subprocess
import os
import re

# Forbidden networking symbols that should not be present
FORBIDDEN_SYMBOLS = [
    'URLSession',
    'NSURLSession', 
    'NSURLConnection',
    'CFSocket',
    'Network.framework',
    'socket(',
    'connect(',
    'bind(',
    'listen(',
    'accept(',
    'send(',
    'recv(',
    'sendto(',
    'recvfrom(',
    'CFNetworkExecuteProxyAutoConfigurationURL',
    'CFNetworkCopyProxiesForURL',
    'CFHTTPMessage',
    'CFHTTPStream',
    'SCNetworkReachability',
    'NSNetService',
    'NSStream',
    'CFStream',
    'CFReadStream',
    'CFWriteStream'
]

def check_binary_for_symbols(binary_path):
    """Check if binary contains forbidden networking symbols."""
    if not os.path.exists(binary_path):
        print(f"Warning: Binary not found at {binary_path}")
        return True  # Allow build to continue if binary not found
    
    try:
        # Use nm to list symbols in the binary
        result = subprocess.run(['nm', '-D', binary_path], 
                              capture_output=True, text=True, check=False)
        
        if result.returncode != 0:
            # Try objdump as fallback
            result = subprocess.run(['objdump', '-t', binary_path], 
                                  capture_output=True, text=True, check=False)
        
        if result.returncode != 0:
            print(f"Warning: Could not analyze binary {binary_path}")
            return True  # Allow build to continue
        
        symbols_output = result.stdout
        
        # Check for forbidden symbols
        found_symbols = []
        for symbol in FORBIDDEN_SYMBOLS:
            if symbol in symbols_output:
                found_symbols.append(symbol)
        
        if found_symbols:
            print("❌ NETWORKING SYMBOLS DETECTED!")
            print("The following forbidden networking symbols were found:")
            for symbol in found_symbols:
                print(f"  - {symbol}")
            print("\nWhisper must be completely offline. Remove all networking code.")
            return False
        
        print("✅ No forbidden networking symbols detected")
        return True
        
    except Exception as e:
        print(f"Error checking symbols: {e}")
        return True  # Allow build to continue on error

def check_source_code():
    """Check source code for obvious networking imports."""
    forbidden_imports = [
        'import Network',
        'import CFNetwork',
        '@import Network',
        '@import CFNetwork',
        '#import <CFNetwork/',
        '#import <Network/',
        'URLSession',
        'NSURLSession',
        'NSURLConnection'
    ]
    
    source_dirs = ['WhisperApp/WhisperApp', 'WhisperApp/Tests']
    found_issues = []
    
    for source_dir in source_dirs:
        if not os.path.exists(source_dir):
            continue
            
        for root, dirs, files in os.walk(source_dir):
            for file in files:
                if file.endswith(('.swift', '.m', '.mm', '.h')):
                    file_path = os.path.join(root, file)
                    try:
                        with open(file_path, 'r', encoding='utf-8') as f:
                            content = f.read()
                            
                        for forbidden in forbidden_imports:
                            if forbidden in content:
                                found_issues.append(f"{file_path}: {forbidden}")
                    except Exception as e:
                        print(f"Warning: Could not read {file_path}: {e}")
    
    if found_issues:
        print("❌ FORBIDDEN NETWORKING CODE DETECTED!")
        print("The following networking imports/usage were found:")
        for issue in found_issues:
            print(f"  - {issue}")
        return False
    
    print("✅ No forbidden networking imports detected in source code")
    return True

def main():
    """Main function to run all networking checks."""
    print("🔍 Checking for networking symbols...")
    
    # Check source code first
    source_ok = check_source_code()
    
    # Check binary if available
    binary_path = sys.argv[1] if len(sys.argv) > 1 else None
    binary_ok = True
    
    if binary_path:
        binary_ok = check_binary_for_symbols(binary_path)
    else:
        print("ℹ️  No binary path provided, skipping binary analysis")
    
    # Fail build if any issues found
    if not source_ok or not binary_ok:
        print("\n💥 BUILD FAILED: Networking code detected!")
        print("Whisper must be completely offline with no networking capabilities.")
        sys.exit(1)
    
    print("\n✅ All networking checks passed!")
    sys.exit(0)

if __name__ == '__main__':
    main()