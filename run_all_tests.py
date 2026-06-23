#!/usr/bin/env python3
"""
Script centralizado para executar todos os testes do projeto HistorIA
"""

import subprocess
import sys
from pathlib import Path
from datetime import datetime

def run_tests():
    """Executa testes de todos os serviços"""
    print("\n" + "="*70)
    print("🧪 SUITE DE TESTES COMPLETA - HistorIA".center(70))
    print("="*70 + "\n")
    
    services = [
        ("Alunos", "services/alunos"),
        ("Exercícios", "services/exercicios"),
        ("Conteúdos", "services/conteudos"),
        ("Trilhas", "services/trilhas")
    ]
    
    results = []
    total_passed = 0
    total_failed = 0
    
    for name, path in services:
        print(f"\n📋 Testando {name}...")
        print("-" * 70)
        
        result = subprocess.run(
            [sys.executable, "-m", "pytest", f"{path}/test_main.py", "-v", "--tb=short"],
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent
        )
        
        # Parse resultado
        if result.returncode == 0:
            # Extrai número de testes
            for line in result.stdout.split('\n'):
                if 'passed' in line and '==' in line:
                    results.append((name, "✅ PASSOU", line.strip()))
                    # Conta testes
                    parts = line.split()
                    for i, part in enumerate(parts):
                        if 'passed' in part and i > 0:
                            try:
                                total_passed += int(parts[i-1])
                            except:
                                pass
                    break
        else:
            results.append((name, "❌ FALHOU", f"Exit code: {result.returncode}"))
            for line in result.stdout.split('\n'):
                if 'failed' in line and '==' in line:
                    results.append((name, "", line.strip()))
                    break
    
    # Relatório final
    print("\n" + "="*70)
    print("📊 RELATÓRIO FINAL".center(70))
    print("="*70)
    
    for service, status, detail in results:
        print(f"{service:15} {status:15} {detail}")
    
    print("\n" + "="*70)
    print(f"✅ Total de testes passaram: {total_passed}")
    print(f"Data/Hora: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("="*70 + "\n")

if __name__ == "__main__":
    run_tests()
