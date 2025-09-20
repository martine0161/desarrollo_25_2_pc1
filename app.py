#!/usr/bin/env python3
"""
Generador de logs simulados para el analizador de logs de red
Autor: Equipo de desarrollo
Uso: python3 app.py [--duration SEGUNDOS] [--output DIRECTORIO]
"""

import random
import time
import datetime
import argparse
import os
import sys
from pathlib import Path

class LogGenerator:
    def __init__(self, output_dir="./logs"):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        
        # Datos realistas para simulación
        self.domains = [
            "google.com", "facebook.com", "twitter.com", "github.com", 
            "stackoverflow.com", "wikipedia.org", "amazon.com", "microsoft.com",
            "cloudflare.com", "digitalocean.com", "example.com", "test.local"
        ]
        
        self.ips = [
            "192.168.1.100", "192.168.1.101", "192.168.1.102", "10.0.0.15",
            "172.16.0.10", "203.0.113.25", "198.51.100.42", "203.0.113.67"
        ]
        
        self.user_agents = [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36",
            "curl/7.68.0", "wget/1.20.3", "Python-requests/2.25.1"
        ]
        
        self.http_methods = ["GET", "POST", "PUT", "DELETE", "HEAD", "OPTIONS"]
        self.http_codes = [200, 200, 200, 404, 500, 301, 302, 403, 401, 204]
        self.tls_versions = ["TLSv1.2", "TLSv1.3", "TLSv1.1", "SSLv3"]
        self.ciphers = [
            "ECDHE-RSA-AES256-GCM-SHA384", "ECDHE-RSA-AES128-GCM-SHA256",
            "DHE-RSA-AES256-SHA", "RC4-MD5", "DES-CBC-SHA"
        ]

    def generate_http_log(self):
        """Genera una línea de log HTTP en formato Apache Common Log"""
        ip = random.choice(self.ips)
        timestamp = datetime.datetime.now().strftime("%d/%b/%Y:%H:%M:%S %z")
        method = random.choice(self.http_methods)
        
        # Rutas más realistas
        paths = ["/", "/index.html", "/api/users", "/api/data", "/favicon.ico", 
                "/login", "/dashboard", "/assets/style.css", "/api/invalid"]
        path = random.choice(paths)
        
        code = random.choice(self.http_codes)
        size = random.randint(200, 5000)
        user_agent = random.choice(self.user_agents)
        
        return f'{ip} - - [{timestamp}] "{method} {path} HTTP/1.1" {code} {size} "-" "{user_agent}"'

    def generate_dns_log(self):
        """Genera una línea de log DNS"""
        timestamp = datetime.datetime.now().strftime("%b %d %H:%M:%S")
        client_ip = random.choice(self.ips)
        domain = random.choice(self.domains)
        query_types = ["A", "AAAA", "CNAME", "MX", "TXT"]
        query_type = random.choice(query_types)
        port = random.randint(32768, 65535)
        
        return f'{timestamp} server named[1234]: client {client_ip}#{port}: query: {domain} IN {query_type} + (127.0.0.1)'

    def generate_tls_log(self):
        """Genera una línea de log TLS/SSL"""
        timestamp = datetime.datetime.now().strftime("%b %d %H:%M:%S")
        domain = random.choice(self.domains)
        
        # Diferentes tipos de eventos TLS
        events = [
            f"TLS handshake completed successfully for {domain}",
            f"SSL error: certificate verification failed for {domain}",
            f"TLS {random.choice(self.tls_versions)} handshake with client completed using cipher {random.choice(self.ciphers)}",
            f"certificate will expire in {random.randint(1, 90)} days for {domain}",
            f"SSL handshake failed with {random.choice(['TLS 1.0', 'SSLv3'])} protocol",
            f"TLS handshake timeout for connection from {random.choice(self.ips)}",
            f"certificate invalid for self-signed cert on {domain}",
            f"cipher {random.choice(['RC4-MD5', 'DES-CBC-SHA'])} negotiated with legacy client"
        ]
        
        event = random.choice(events)
        service = random.choice(["sshd", "nginx", "httpd", "postfix", "apache"])
        
        return f'{timestamp} host {service}: {event}'

    def generate_mixed_log(self, duration=60):
        """Genera logs mixtos durante el tiempo especificado"""
        
        # Crear archivos de log
        access_log = self.output_dir / "access.log"
        dns_log = self.output_dir / "dns.log"
        tls_log = self.output_dir / "tls.log"
        combined_log = self.output_dir / "combined.log"
        
        start_time = time.time()
        log_count = 0
        
        print(f"Generando logs en: {self.output_dir}")
        print(f"Duración: {duration} segundos")
        print("Presiona Ctrl+C para detener...")
        
        try:
            while time.time() - start_time < duration:
                # Generar diferentes tipos de logs con probabilidades
                rand = random.random()
                
                if rand < 0.5:  # 50% HTTP logs
                    log_line = self.generate_http_log()
                    with access_log.open("a") as f:
                        f.write(log_line + "\n")
                    with combined_log.open("a") as f:
                        f.write(f"[HTTP] {log_line}\n")
                        
                elif rand < 0.8:  # 30% DNS logs
                    log_line = self.generate_dns_log()
                    with dns_log.open("a") as f:
                        f.write(log_line + "\n")
                    with combined_log.open("a") as f:
                        f.write(f"[DNS] {log_line}\n")
                        
                else:  # 20% TLS logs
                    log_line = self.generate_tls_log()
                    with tls_log.open("a") as f:
                        f.write(log_line + "\n")
                    with combined_log.open("a") as f:
                        f.write(f"[TLS] {log_line}\n")
                
                log_count += 1
                
                if log_count % 10 == 0:
                    print(f"Logs generados: {log_count}")
                
                # Pausa aleatoria entre logs (0.1 a 2 segundos)
                time.sleep(random.uniform(0.1, 2.0))
                
        except KeyboardInterrupt:
            print(f"\nGeneración detenida. Total de logs: {log_count}")
        
        print(f"\nArchivos generados:")
        for log_file in [access_log, dns_log, tls_log, combined_log]:
            if log_file.exists():
                lines = len(log_file.read_text().strip().split('\n'))
                print(f"  {log_file.name}: {lines} líneas")

def main():
    parser = argparse.ArgumentParser(description="Generador de logs para analizador de red")
    parser.add_argument("--duration", "-d", type=int, default=60, 
                       help="Duración en segundos (default: 60)")
    parser.add_argument("--output", "-o", type=str, default="./logs",
                       help="Directorio de salida (default: ./logs)")
    parser.add_argument("--quiet", "-q", action="store_true",
                       help="Modo silencioso")
    
    args = parser.parse_args()
    
    try:
        generator = LogGenerator(args.output)
        generator.generate_mixed_log(args.duration)
    except KeyboardInterrupt:
        print("\nGeneración cancelada por el usuario")
        sys.exit(0)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()