#!/usr/bin/env python3.11
"""
Health check script for the AI system
Validates all critical dependencies and services
"""

import sys
import subprocess

def check_python_version():
    """Check Python version is 3.11+"""
    version = sys.version_info
    if version.major == 3 and version.minor >= 11:
        print(f"✅ Python {version.major}.{version.minor}.{version.micro} OK")
        return True
    print(f"❌ Python {version.major}.{version.minor} - requires 3.11+")
    return False

def check_imports():
    """Check critical library imports"""
    imports = {
        'anthropic': 'Anthropic API',
        'langchain': 'LangChain Framework',
        'ollama': 'Ollama Local LLM',
        'openai': 'OpenAI API',
        'streamlit': 'Streamlit Web UI',
        'dotenv': 'Environment Variables',
        'yaml': 'YAML Parser'
    }
    
    all_ok = True
    for module, description in imports.items():
        try:
            __import__(module)
            print(f"✅ {module:15} - {description}")
        except ImportError as e:
            print(f"❌ {module:15} - {description} (MISSING)")
            all_ok = False
    
    return all_ok

def check_env_file():
    """Check .env file exists"""
    import os
    if os.path.exists('.env'):
        print(f"✅ .env file exists (secrets protected)")
        return True
    print(f"❌ .env file missing")
    return False

def check_venv():
    """Check if running in venv"""
    import os
    in_venv = hasattr(sys, 'real_prefix') or (
        hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix
    )
    if in_venv:
        print(f"✅ Virtual environment active: {sys.prefix}")
        return True
    print(f"❌ Not in virtual environment")
    return False

def main():
    print("\n" + "="*60)
    print("🔍 SYSTEM HEALTH CHECK")
    print("="*60 + "\n")
    
    checks = [
        ("Python Version", check_python_version),
        ("Virtual Environment", check_venv),
        ("Environment Config", check_env_file),
        ("Dependencies", check_imports),
    ]
    
    results = []
    for name, check_func in checks:
        print(f"\n📋 Checking: {name}")
        print("-" * 60)
        results.append(check_func())
    
    print("\n" + "="*60)
    if all(results):
        print("✅ ALL CHECKS PASSED - System ready!")
        print("="*60 + "\n")
        return 0
    else:
        print("❌ SOME CHECKS FAILED - Review above")
        print("="*60 + "\n")
        return 1

if __name__ == "__main__":
    sys.exit(main())
