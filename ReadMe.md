# RGP (Request for Goods Purchase) & Transfer Workflow Solution

### Version 2.1.0

A comprehensive **Purchase & Transfer Requisition Management System** for Microsoft Dynamics 365 Business Central with integrated approval workflow, vendor management, responsibility center logic, inventory visibility, and automatic  Purchase Order / Transfer Order generation.

---

## 📋 Overview

Version **2.1.0** introduces major architectural improvements including:

* Responsibility Center-driven defaults
* Automatic location assignment
* Real-time inventory visibility per location
* Approved Quantity logic for document creation
* Enhanced RDL Requisition Report
* Transfer document support (not only Purchase)

This solution now supports both:

* 🛒 **Purchase Requisitions**
* 🔄 **Transfer Requisitions**

With complete workflow and document traceability.

---

# 🚀 Key Features (v2.1.0)

## 🧾 Requisition Management

* Unified document for **Purchase** and **Transfer**
* Auto-generated Request No. via Number Series (RFQ)
* Status-based control (Open → Pending Approval → Approved → Rejected)
* Header & Line level comments

---

## 🏢 Responsibility Center Integration (NEW in v2.1.0)

* Auto-assigns:

  * Responsibility Center from User Setup
  * Transfer-to Location from Responsibility Center
  * Global Dimension 1 & 2 from Default Dimensions
* Lines automatically inherit location from Header
* Clean dimension consistency across documents

---

## 📦 Inventory Visibility (NEW in v2.1.0)

Each Item Line now shows:

* **Requested Quantity**
* **Approved Quantity**
* **Location Current Qty** (inventory at line location)
* **Request From Current Qty** (inventory at Transfer-from location)

Real-time inventory calculation using Item FlowFields.

---

## ✅ Approval-Based Quantity Logic (NEW)

* Only **Approved Qty** flows to:

  * Purchase Orders
  * Transfer Orders
* Report prints only lines with Approved Qty > 0
* Prevents accidental over-ordering

---

## 🏬 Multi-Vendor Management

* Vendor comparison lines
* Vendor acceptance logic
* PO cannot be created until vendor is accepted
* If Vendor is selected in Header → PO uses Header Vendor
* If Vendors exist in Vendor Lines → PO uses Accepted Vendor

---

## 📄 RGP Requisition RDL Report (Enhanced)

Dataset Includes:

### Header

* Request details
* Responsibility Center
* Dimensions
* Vendor full details (Address, Contact, Phone, Email, VAT/TIN)
* Transfer locations
* Company Information with logo

### Lines

* Item details
* Requested Qty
* Approved Qty
* Inventory visibility fields
* Comments

Single layout supports both Purchase and Transfer types.

---

## 🔁 Automatic Document Creation

Depending on Type:

| Type     | Creates                |
| -------- | ---------------------- |
| Purchase | Purchase Order         |
| Transfer | Transfer Order         |

Includes:

* Header data flow
* Line data flow
* Dimensions
* Request No. traceability
* Approved Qty transfer only

---

# 🏗️ Architecture

## AL Object Structure

```
📦 RGP-Workflow-Solution
├── 📄 Tables
│   ├── 50210 RGP Request Header
│   └── 50211 RGP Request Item Line
│   
│
├── 📄 Pages
│   ├── 50213 RGP Request Document
│   ├── 50210 RGP Request Item Subform
│   └── 50211 RGP Request Vendor Subform
│
├── 📄 Codeunits
│   ├── 50210 RGP Custom Workflow Mgmt
│   ├── 50211 RGP Handle Request to Purchase Order
│   └── 50212 RGP Request to Purchase Order
│
├── 📄 Reports
│   └── 50214 RGP Request Document (RDLC)
│
├── 📄 Enums
│   ├── RGP Status Enum
│   └── RGP Line Types Enum
│
├── 📄 TableExtensions
│   ├── Purchase Header Extension
│   └── Purchase Line Extension
│
├── 📄 PageExtensions
│   ├── Purchase Quote Extension
│   ├── Purchase Order Extension
│   └── Purchase Quote Subform Extension
```

---

# 🔄 Workflow Status Flow

```
Open → Pending Approval → Approved → Rejected
```

* **Open** – Editable
* **Pending Approval** – Locked for editing
* **Approved** – Ready for document creation
* **Rejected** – Returned for correction

---

# 📦 Data Model

### RGP Request Header

* Type (Purchase / Transfer)
* Vendor (optional if using Vendor Lines)
* Responsibility Center
* Transfer-from / Transfer-to
* Dimensions
* Approval Status
* Created PO / TO references

### RGP Request Item Line

* Type (Item)
* Location Code
* Requested Qty
* Approved Qty
* Location Current Qty
* Request From Current Qty

---

# 🛠️ Installation

## Prerequisites

* Microsoft Dynamics 365 Business Central (SaaS or On-Prem)
* VS Code with AL Extension
* Git

---

## Setup Steps

1. Clone Repository

```bash
git clone https://github.com/BenStance/AL-Objects-That-Integrate-WorkFlow-and-Post-To-PO.git
```

2. Open in VS Code
3. Configure launch.json
4. Build & Publish

---

## Post Installation Setup

### 1️⃣ Number Series

Purchases & Payables Setup → Configure RFQ number series

### 2️⃣ Responsibility Center Setup

Ensure:

* Responsibility Center has Location Code
* Default Dimensions configured

### 3️⃣ User Setup

Configure:

* Purchase Resp. Ctr. Filter

### 4️⃣ Workflow Setup

Run:

```al
codeunit 50210."RGP Custom Workflow Mgmt".CreateRGPApprovalWorkflow();
```

Then enable workflow.

---

# 📊 Version 2.1.0 Major Improvements

* Responsibility Center auto-location logic
* Auto Transfer-to from RC
* Inventory visibility per line
* Approved Qty control for document creation
* Cleaned document creation logic
* Vendor full information in report
* Improved RDL dataset structure
* Report action using RunModal standard pattern
* Header-to-Line location inheritance fixed
* Better dimension handling

---

# 🎯 Business Benefits

* Stronger cost control
* Clear stock visibility before transfer
* Eliminates over-ordering
* Fully auditable approval process
* Seamless BC integration
* Scalable architecture

---

# 🔐 Security & Control

* Status-based editability
* Approval-controlled quantity posting
* Vendor acceptance validation before PO creation
* Clean separation between Request and Final Documents

---

# 🐛 Troubleshooting

### PO not creating?

✔ Ensure Vendor accepted
✔ Ensure Approved Qty > 0
✔ Ensure Status = Approved

### Inventory not showing?

✔ Confirm Item has ledger entries
✔ Confirm Location codes are valid

---

# 📞 Support

📧 [benedict@act-ltd.com](mailto:benedict@act-ltd.com)
📧 [support@act-ltd.com](mailto:support@act-ltd.com)
📞 0622472600

---

# 🙏 Acknowledgments

* Microsoft Dynamics 365 Business Central Team
* AL Developer Community
* Athena Core Technologies

---

**Version:** 2.1.0
**Release Year:** 2025
**Compatibility:** Business Central 2022 Wave 2 and later
