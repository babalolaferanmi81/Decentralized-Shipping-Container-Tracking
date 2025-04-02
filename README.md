# Decentralized Shipping Container Tracking System

A blockchain-based solution for transparent and secure tracking of shipping containers throughout the global supply chain, built with Clarity smart contracts on the Stacks blockchain.

## Overview

This system provides a decentralized approach to shipping container logistics, enabling:

- Transparent tracking of container ownership and location
- Secure recording of environmental conditions during transport
- Streamlined customs clearance and documentation management
- Immutable audit trail of a container's journey

## Smart Contracts

### Container Registration (`container-registration.clar`)

Manages the lifecycle of shipping containers:

- Register new containers with detailed specifications
- Transfer ownership between parties
- Update container status
- Query container details and ownership information

```clarity
;; Register a new container
(define-public (register-container 
    (container-number (string-ascii 11))
    (container-type (string-ascii 10))
    (length uint)
    (width uint)
    (height uint)
    (max-weight uint)
    (manufacturing-date uint))
  ;; Implementation details...
)

