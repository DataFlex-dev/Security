# Security Library 

---

Data Access Worldwide created the DataFlex Security Library. With this library attached to your application workspace you can create and verify hashes, store passcodes securely, add 2-factor authentication to your web application, and use encryption. This library provides access to some of today’s most popular and secure algorithms.

The installer executable that you can download installs up to three library workspaces. The main library provides only a framework, which ensures that every security engine will be accessible using a single, easy to use API. This workspace also contains a manual (PDF) to help you get started.

The additional libraries provide access to CNG (CryptoAPI Next Generation) and libsodium. CNG is a part of Windows itself. Libsodium requires distribution of the dll, as well as (potentially) installation of the MS Visual C++ Runtime 2017.

## Algorithms
The current version supports the following algorithms:

- Generic hashes: MD2, MD4, MD5, SHA-1, SHA-2 (256, 384, 512), blake2b
- Keyed hashes: HMAC-MD5, HMAC-SHA-1, HMAC-SHA-2 (256, 384, 512), HMAC-SHA512-256 (truncated SHA-512), blake2b
- Secure passcode storage: PBKDF2-SHA-1, PBKDF2-SHA-256, scrypt, argon2i, argon2id
- Symmetric encryption: AES-CBC
- Authenticated encryption: AES-GCM
- 2FA: oATH TOTP/HOTP and FIDO U2F

## Library Information

This repository contains a `Library` directory where the library source is, and the `help` directory where the library documentation is stored.


###### External Components

If applicable, list the external components used in the table below:

| Component | Version       |
| --------- | ------------- |
| libsodium | 1.0.20-stable |

## General Information

| Product  | Version           |
| -------- | ----------------- |
| DataFlex | 23.0, 24.0, 25.0  |
