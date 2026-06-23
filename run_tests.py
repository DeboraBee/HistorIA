#!/usr/bin/env python3
"""
Script de teste integrado para toda a aplicação HistorIA
Executa testes de todos os serviços e gera relatório
"""

import subprocess
import sys
import json
from pathlib import Path
from datetime import datetime

class TestRunner:
    def __init__(self):
        self.root_path = Path(__file__).parent
        self.results = {}
        self.timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    def run_service_tests(self, service_name, service_path):
        """Executa testes de um serviço específico"""
        print(f"\n{'='*60}")
        print(f"Testando: {service_name}")
        print(f"{'='*60}")
        
        service_dir = self.root_path / "services" / service_path
        
        try:
            # Executa pytest com saída detalhada
            result = subprocess.run(
                [sys.executable, "-m", "pytest", "-v", "--tb=short", "test_main.py"],
                cwd=service_dir,
                capture_output=True,
                text=True,
                timeout=60
            )
            
            self.results[service_name] = {
                "status": "passed" if result.returncode == 0 else "failed",
                "returncode": result.returncode,
                "stdout": result.stdout,
                "stderr": result.stderr
            }
            
            print(result.stdout)
            if result.stderr:
                print("STDERR:", result.stderr)
            
            return result.returncode == 0
        
        except subprocess.TimeoutExpired:
            self.results[service_name] = {
                "status": "timeout",
                "error": "Testes excederam timeout de 60 segundos"
            }
            print(f"❌ TIMEOUT: {service_name}")
            return False
        
        except Exception as e:
            self.results[service_name] = {
                "status": "error",
                "error": str(e)
            }
            print(f"❌ ERRO: {service_name}")
            print(str(e))
            return False
    
    def run_all_tests(self):
        """Executa testes de todos os serviços"""
        services = [
            ("Alunos", "alunos"),
            ("Exercícios", "exercicios"),
            ("Conteúdos", "conteudos"),
            ("Trilhas", "trilhas")
        ]
        
        passed = 0
        failed = 0
        
        for service_name, service_path in services:
            if self.run_service_tests(service_name, service_path):
                passed += 1
            else:
                failed += 1
        
        return passed, failed
    
    def generate_report(self):
        """Gera relatório dos testes"""
        report = []
        report.append("\n" + "="*60)
        report.append("RELATÓRIO DE TESTES - HistorIA")
        report.append("="*60)
        report.append(f"Data/Hora: {self.timestamp}\n")
        
        total_services = len(self.results)
        passed_services = sum(1 for r in self.results.values() if r.get("status") == "passed")
        failed_services = total_services - passed_services
        
        report.append(f"Total de Serviços: {total_services}")
        report.append(f"✅ Passou: {passed_services}")
        report.append(f"❌ Falhou: {failed_services}")
        report.append("")
        
        report.append("Detalhes por Serviço:")
        report.append("-" * 60)
        
        for service, result in self.results.items():
            status = "✅ PASSOU" if result.get("status") == "passed" else "❌ FALHOU"
            report.append(f"{service}: {status}")
            
            if result.get("error"):
                report.append(f"  Erro: {result['error']}")
        
        report.append("="*60)
        
        return "\n".join(report)

def main():
    runner = TestRunner()
    passed, failed = runner.run_all_tests()
    
    report = runner.generate_report()
    print(report)
    
    # Salva relatório em arquivo
    report_path = Path(__file__).parent / "test_report.txt"
    with open(report_path, "w", encoding="utf-8") as f:
        f.write(report)
    
    print(f"\nRelatório salvo em: {report_path}")
    
    # Retorna código de saída baseado em falhas
    sys.exit(0 if failed == 0 else 1)

if __name__ == "__main__":
    main()
