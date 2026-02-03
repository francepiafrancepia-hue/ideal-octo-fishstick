# 🚀 DAYS 4‑20 OPTIMIZED PLAN (Target <20 days)

**Goal:** Finish in **~19‑20 days** with parallel streams and reduced scope.  
**Assumption:** Days 1‑3 complete (18%).  

---

## ✅ Parallel Streams Overview

**Stream A – Security & K8s Readiness** (critical path)  
**Stream B – ML Framework Validation**  
**Stream C – Observability & Ops**  

---

## 📅 Day‑by‑Day Plan (Days 4‑20)

### **Days 4‑5: Security Baseline (CRITICAL)**
- TLS termination (Ingress + cert‑manager plan)  
- Secrets management (Vault/External Secrets design)  
- Backup strategy (Postgres + Redis)  
- Auth between services (token or mTLS decision)  

### **Days 5‑7: Kubernetes Scaffolding**
- `k8s/` namespace + deployment/service manifests  
- Ingress + basic NetworkPolicy  
- CI/CD pipeline skeleton (lint/build/deploy)  

### **Days 6‑8: ML Framework Validation**
- Torch + TF sanity tests  
- MLflow connectivity tests  

### **Days 9‑11: Observability**
- Prometheus + Grafana baseline  
- Logging (Loki or ELK)  
- Alerting rules (latency, error rate)  

### **Days 12‑14: Orchestration & Reliability**
- Airflow setup + basic DAGs  
- Retries, timeouts, failure hooks  

### **Days 15‑17: Load & Scaling**
- Load tests (k6/Locust)  
- HPA + resource tuning  

### **Days 18‑20: Production Readiness**
- Runbooks, DR test, backup restore test  
- Final security review  
- Go‑live checklist  

---

## 🧭 Critical Path
1. Security baseline (Days 4‑5)  
2. K8s scaffolding (Days 5‑7)  
3. Observability (Days 9‑11)  
4. Airflow + reliability (Days 12‑14)  
5. Load + Prod readiness (Days 15‑20)  

---

## ⚠️ Deferred (Post‑Day‑20)
- Multi‑region failover  
- Full service mesh  
- Extensive chaos engineering  

