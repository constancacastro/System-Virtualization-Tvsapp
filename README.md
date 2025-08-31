# System Virtualization - TVSApp

This repository contains coursework assignments for the **System Virtualization Techniques** course @ISEL.  

## 📂 Structure
- `cw3/` – **Coursework 3**  
  Deployment and orchestration using **systemd services**, **bash scripts**, and **nginx** as a load balancer.
  
- `cw4/` – **Coursework 4**  
  Containerized deployment using **Docker**, **Docker Compose**, and **nginx** load balancing across replicas.

## Goals
Both assignments share the same application and general objectives:
- Run a scalable web application (`tvsapp`) with **Elasticsearch** as the backend.
- Manage multiple replicas of the application behind an **nginx load balancer**.
- Provide flexible scaling and lifecycle management of the application instances.

The main difference lies in the **virtualization approach**:
- **CW3**: Traditional service-based management with scripts and `systemd`.  
- **CW4**: Modern container-based orchestration with Docker and Compose.

## Technologies
- **Node.js**  
- **Elasticsearch**  
- **nginx**  
- **systemd** (CW3)  
- **Docker & Docker Compose** (CW4)

## 📌 Tags
- `CW3-1`, `CW3-2` → systemd + scripts implementation  
- `CW4-1`, `CW4-2`, `CW4-DONE` → Docker/Compose implementation  

## 👩‍💻 Authors
Coursework for **System Virtualization Techniques** @ ISEL.
