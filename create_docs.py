import docx
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

def create_element(name):
    return OxmlElement(name)

def set_cell_background(cell, hex_color):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{hex_color}"/>')
    tcPr.append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = OxmlElement('w:tcMar')
    for m, val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
        node = OxmlElement(f'w:{m}')
        node.set(qn('w:w'), str(val))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)

def set_table_borders(table, color="D3D3D3"):
    tblPr = table._tbl.tblPr
    borders = parse_xml(f'''
        <w:tblBorders {nsdecls("w")}>
            <w:top w:val="single" w:sz="4" w:space="0" w:color="{color}"/>
            <w:bottom w:val="single" w:sz="4" w:space="0" w:color="{color}"/>
            <w:insideH w:val="single" w:sz="4" w:space="0" w:color="{color}"/>
            <w:insideV w:val="none"/>
            <w:left w:val="none"/>
            <w:right w:val="none"/>
        </w:tblBorders>
    ''')
    tblPr.append(borders)

def build_docx():
    doc = Document()
    
    # Page Margins
    for section in doc.sections:
        section.top_margin = Inches(1.0)
        section.bottom_margin = Inches(1.0)
        section.left_margin = Inches(1.0)
        section.right_margin = Inches(1.0)
        
    # Styles & Fonts
    normal_style = doc.styles['Normal']
    normal_style.font.name = 'Calibri'
    normal_style.font.size = Pt(11)
    normal_style.font.color.rgb = RGBColor(0x22, 0x22, 0x22)
    
    # Colors
    COLOR_PRIMARY = RGBColor(229, 57, 53)    # Red #E53935
    COLOR_SECONDARY = RGBColor(21, 101, 192)  # Blue #1565C0
    COLOR_DARK = RGBColor(28, 28, 30)        # Dark Slate #1C1C1E
    
    # ---------------------------------------------------------------------------
    # COVER PAGE
    # ---------------------------------------------------------------------------
    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_title.paragraph_format.space_before = Pt(36)
    p_title.paragraph_format.space_after = Pt(6)
    run_title = p_title.add_run("SOZOTAP")
    run_title.font.name = 'Arial'
    run_title.font.size = Pt(36)
    run_title.font.bold = True
    run_title.font.color.rgb = COLOR_PRIMARY
    
    p_tagline = doc.add_paragraph()
    p_tagline.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_tagline.paragraph_format.space_after = Pt(18)
    run_tag = p_tagline.add_run("“One Tap Can Save a Life.”")
    run_tag.font.name = 'Calibri'
    run_tag.font.size = Pt(18)
    run_tag.font.italic = True
    run_tag.font.color.rgb = COLOR_SECONDARY
    
    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_sub.paragraph_format.space_after = Pt(48)
    run_sub = p_sub.add_run("Secure Emergency Medical Information and SOS Alert Mobile Application\nComprehensive Project Documentation & Software Requirements Specification")
    run_sub.font.size = Pt(13)
    run_sub.font.color.rgb = COLOR_DARK
    
    # Visual Box
    p_box = doc.add_paragraph()
    p_box.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_box.paragraph_format.space_after = Pt(48)
    run_box = p_box.add_run("[ 🛡️ EMERGENCY MEDICAL SHIELD  |  📱 FLUTTER MOBILE APP  |  ⚡ CLOUD FUNCTIONS & FCM ]")
    run_box.font.size = Pt(10)
    run_box.font.bold = True
    run_box.font.color.rgb = COLOR_SECONDARY
    
    # Metadata Table
    table_meta = doc.add_table(rows=7, cols=2)
    table_meta.alignment = WD_TABLE_ALIGNMENT.CENTER
    table_meta.autofit = False
    
    meta_data = [
        ("Submitted By:", "[Student Name]"),
        ("Register Number:", "[Register Number]"),
        ("Department:", "[Department Name]"),
        ("Institution:", "[College / University Name]"),
        ("Submitted To:", "[Project Guide Name]"),
        ("Academic Year:", "[Academic Year]"),
        ("Submission Date:", "[Submission Date]")
    ]
    
    for i, (label, val) in enumerate(meta_data):
        row = table_meta.rows[i]
        cell_lbl, cell_val = row.cells[0], row.cells[1]
        cell_lbl.width = Inches(2.2)
        cell_val.width = Inches(3.8)
        
        p_l = cell_lbl.paragraphs[0]
        r_l = p_l.add_run(label)
        r_l.font.bold = True
        r_l.font.color.rgb = COLOR_DARK
        
        p_v = cell_val.paragraphs[0]
        r_v = p_v.add_run(val)
        r_v.font.color.rgb = COLOR_SECONDARY
        
        set_cell_margins(cell_lbl, 60, 60, 100, 100)
        set_cell_margins(cell_val, 60, 60, 100, 100)
        
    doc.add_page_break()
    
    # Helpers for headings
    def add_h1(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(18)
        p.paragraph_format.space_after = Pt(8)
        p.paragraph_format.keep_with_next = True
        r = p.add_run(text)
        r.font.name = 'Arial'
        r.font.size = Pt(18)
        r.font.bold = True
        r.font.color.rgb = COLOR_PRIMARY
        return p

    def add_h2(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(14)
        p.paragraph_format.space_after = Pt(6)
        p.paragraph_format.keep_with_next = True
        r = p.add_run(text)
        r.font.name = 'Arial'
        r.font.size = Pt(14)
        r.font.bold = True
        r.font.color.rgb = COLOR_SECONDARY
        return p

    def add_h3(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(10)
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.keep_with_next = True
        r = p.add_run(text)
        r.font.name = 'Calibri'
        r.font.size = Pt(12)
        r.font.bold = True
        r.font.color.rgb = COLOR_DARK
        return p

    # ---------------------------------------------------------------------------
    # 1. EXECUTIVE SUMMARY
    # ---------------------------------------------------------------------------
    add_h1("1. EXECUTIVE SUMMARY")
    
    doc.add_paragraph(
        "SOZOTAP (“One Tap Can Save a Life”) is a state-of-the-art emergency medical response and notification mobile application built using Flutter and Firebase. "
        "The primary purpose of SOZOTAP is to bridge the critical information gap during medical emergencies when patients may be unconscious, incapacitated, or unable to articulate their medical history to first responders and emergency personnel."
    )
    doc.add_paragraph(
        "By leveraging dynamic zero-trust QR code scanning technology, real-time GPS location sharing, automated multi-channel emergency alert dispatch (FCM push notifications and SMS fallback), and granular user privacy controls, SOZOTAP empowers individuals to manage their emergency health profiles safely."
    )
    
    p_disclaimer = doc.add_paragraph()
    p_disclaimer.paragraph_format.space_before = Pt(8)
    p_disclaimer.paragraph_format.space_after = Pt(8)
    r_disc = p_disclaimer.add_run(
        "IMPORTANT LEGAL & MEDICAL DISCLAIMER: SOZOTAP is an emergency information-support system. "
        "It does not replace doctors, hospitals, ambulances, official government emergency services (911/112), or professional medical assessment."
    )
    r_disc.font.bold = True
    r_disc.font.color.rgb = COLOR_PRIMARY
    
    doc.add_paragraph(
        "Based on repository evidence across 7 completed development phases, SOZOTAP features a production-ready mobile application shell, Firebase Authentication, interactive onboarding, dynamic emergency medical profile management, emergency contact configuration with explicit SMS opt-in consent, 3-second SOS countdown trigger engine, dynamic opaque QR code generator & scanner, paramedic public web card viewer, Firebase Cloud Functions v2 backend triggers, Hive offline caching, and user privacy consent toggles."
    )

    # ---------------------------------------------------------------------------
    # 2. PROJECT OVERVIEW
    # ---------------------------------------------------------------------------
    add_h1("2. PROJECT OVERVIEW")
    
    add_h2("2.1 Project Identification")
    doc.add_paragraph("• Project Title: SOZOTAP\n• Tagline: One Tap Can Save a Life.\n• Domain: Mobile Health (mHealth) & Emergency Response Systems\n• Target Platform: Android Mobile Application (Built with Flutter)")
    
    add_h2("2.2 Background & Motivation")
    doc.add_paragraph(
        "During sudden medical crises such as anaphylactic shock, cardiac arrest, severe trauma, or diabetic emergencies, the first few minutes ('Golden Hour') dictate patient survival. Paramedics and first responders frequently encounter patients who cannot communicate vital health information. Paper emergency cards are easily misplaced, outdated, or inaccessible, while raw QR codes printed on physical bracelets pose serious privacy risks if they hardcode sensitive medical data."
    )
    
    add_h2("2.3 Problem Statement")
    doc.add_paragraph(
        "Current personal emergency systems either lack instant public accessibility for first responders, expose sensitive patient data permanently in plain text, or fail to notify designated family members automatically during an emergency activation."
    )
    
    add_h2("2.4 Proposed Solution")
    doc.add_paragraph(
        "SOZOTAP resolves these challenges by separating public emergency access from private data stores. "
        "Users maintain an authoritative emergency medical profile in Cloud Firestore, coupled with dynamic opaque QR tokens (`https://vitanexus.web.app/qr/<token>`). "
        "When scanned by a paramedic, a protected Cloud Function validates token expiration and status, applies the user's explicit granular consent flags, and renders a redacted Emergency Web Card without requiring app installation. "
        "Simultaneously, activating the SOS button broadcasts high-priority FCM push alerts and SMS notifications to designated emergency contacts."
    )
    
    add_h2("2.5 Current Implementation Status Summary")
    
    table_status = doc.add_table(rows=8, cols=3)
    table_status.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(table_status)
    
    headers = ["Phase", "Module / Description", "Status Label"]
    hdr_cells = table_status.rows[0].cells
    for j, text in enumerate(headers):
        hdr_cells[j].paragraphs[0].add_run(text).font.bold = True
        hdr_cells[j].paragraphs[0].runs[0].font.color.rgb = RGBColor(255, 255, 255)
        set_cell_background(hdr_cells[j], "E53935")
        set_cell_margins(hdr_cells[j], 100, 100, 150, 150)
        
    status_rows = [
        ("Phase 1", "Application Shell, Material 3 Design System & Routing", "Implemented"),
        ("Phase 2", "Firebase Auth, Phone OTP & Interactive Onboarding", "Implemented"),
        ("Phase 3", "Emergency Dashboard & Medical Profile Management", "Implemented"),
        ("Phase 4", "Emergency Contacts CRUD & 3s Countdown SOS Engine", "Implemented"),
        ("Phase 5", "Dynamic QR Token Lifecycle, Scanner & Paramedic Web Viewer", "Implemented"),
        ("Phase 6", "Cloud Functions v2 Dispatch, FCM & Extensible SMS Engine", "Implemented"),
        ("Phase 7", "App Settings, Privacy Consent Controls, Hive Cache & Account Controls", "Implemented")
    ]
    
    for i, row_data in enumerate(status_rows):
        row_cells = table_status.rows[i+1].cells
        for j, text in enumerate(row_data):
            p = row_cells[j].paragraphs[0]
            r = p.add_run(text)
            if j == 2:
                r.font.bold = True
                r.font.color.rgb = RGBColor(46, 125, 50)
            set_cell_margins(row_cells[j], 80, 80, 120, 120)
            if i % 2 == 1:
                set_cell_background(row_cells[j], "F9F9FB")

    # ---------------------------------------------------------------------------
    # 3. ROLES AND RESPONSIBILITIES
    # ---------------------------------------------------------------------------
    add_h1("3. PROJECT ROLES AND RESPONSIBILITIES")
    
    table_roles = doc.add_table(rows=7, cols=4)
    table_roles.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(table_roles)
    
    r_headers = ["Role Name", "Main Responsibilities", "Access Level", "Status"]
    for j, text in enumerate(r_headers):
        cell = table_roles.rows[0].cells[j]
        cell.paragraphs[0].add_run(text).font.bold = True
        cell.paragraphs[0].runs[0].font.color.rgb = RGBColor(255, 255, 255)
        set_cell_background(cell, "1565C0")
        set_cell_margins(cell, 100, 100, 150, 150)
        
    roles_data = [
        ("Product Owner / PM", "Feature scope, release planning, documentation", "Administrative", "Implemented"),
        ("Senior Flutter Developer", "UI screens, Riverpod state, GoRouter integration", "Client Source", "Implemented"),
        ("Firebase Architect", "Cloud Firestore schemas, Security Rules, FCM setup", "Cloud Console", "Implemented"),
        ("Backend Engineer", "Firebase Cloud Functions v2, Twilio SMS engine", "Functions Source", "Implemented"),
        ("Mobile Security Engineer", "Log redaction, opaque QR hashing, owner isolation", "Security Review", "Implemented"),
        ("IoT / ESP32 Engineer", "NFC SmartTag & BLE hardware SOS trigger integration", "Hardware Integration", "Planned / Future Scope")
    ]
    
    for i, rdata in enumerate(roles_data):
        row_cells = table_roles.rows[i+1].cells
        for j, text in enumerate(rdata):
            p = row_cells[j].paragraphs[0]
            r = p.add_run(text)
            if j == 3 and "Implemented" in text:
                r.font.bold = True
                r.font.color.rgb = RGBColor(46, 125, 50)
            elif j == 3:
                r.font.italic = True
                r.font.color.rgb = RGBColor(230, 81, 0)
            set_cell_margins(row_cells[j], 80, 80, 120, 120)
            if i % 2 == 1:
                set_cell_background(row_cells[j], "F9F9FB")

    # ---------------------------------------------------------------------------
    # 4. STAKEHOLDER ANALYSIS
    # ---------------------------------------------------------------------------
    add_h1("4. STAKEHOLDER ANALYSIS")
    
    table_sh = doc.add_table(rows=5, cols=4)
    table_sh.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(table_sh)
    
    sh_headers = ["Stakeholder Group", "Key Needs & Expectations", "Influence / Interest", "Privacy Concern"]
    for j, text in enumerate(sh_headers):
        cell = table_sh.rows[0].cells[j]
        cell.paragraphs[0].add_run(text).font.bold = True
        cell.paragraphs[0].runs[0].font.color.rgb = RGBColor(255, 255, 255)
        set_cell_background(cell, "E53935")
        set_cell_margins(cell, 100, 100, 150, 150)
        
    sh_data = [
        ("Patients / Users", "Fast SOS activation, total privacy control over medical data", "High / High", "Prevent unauthorized exposure of diagnoses"),
        ("Emergency Contacts", "Instant FCM push and SMS alerts with location maps", "Medium / High", "Unwanted spam or false alarms"),
        ("First Responders / Paramedics", "Instant access to blood group & allergies via QR scan", "High / Medium", "Fast loading without requiring app login"),
        ("Project Evaluation Committee", "Robust architecture, comprehensive documentation, test coverage", "High / High", "Compliance with project requirements")
    ]
    
    for i, sdata in enumerate(sh_data):
        row_cells = table_sh.rows[i+1].cells
        for j, text in enumerate(sdata):
            p = row_cells[j].paragraphs[0]
            p.add_run(text)
            set_cell_margins(row_cells[j], 80, 80, 120, 120)
            if i % 2 == 1:
                set_cell_background(row_cells[j], "F9F9FB")

    # ---------------------------------------------------------------------------
    # 5. FUNCTIONAL REQUIREMENTS
    # ---------------------------------------------------------------------------
    add_h1("5. FUNCTIONAL REQUIREMENTS")
    
    reqs = [
        ("FR-AUTH-001", "User Authentication & Sign-In", "Supports Email/Password authentication, session persistence, and logout flow.", "Implemented", "lib/authentication/presentation/screens/login_screen.dart"),
        ("FR-ONB-001", "Interactive Onboarding Carousel", "Multi-step feature walkthrough saved to local SharedPreferences state.", "Implemented", "lib/presentation/onboarding/onboarding_screen.dart"),
        ("FR-DASH-001", "Emergency Dashboard Hub", "Central dashboard with SOS button, QR quick card, and contact shortcuts.", "Implemented", "lib/presentation/dashboard/home_screen.dart"),
        ("FR-MED-001", "Medical Profile Management", "CRUD interface for blood type, allergies, conditions, medications, and insurance.", "Implemented", "lib/medical_profile/presentation/screens/medical_profile_edit_screen.dart"),
        ("FR-CON-001", "Emergency Contacts & SMS Opt-In", "Contact management with relationship tags, phone normalization, and SMS consent.", "Implemented", "lib/emergency_contacts/presentation/screens/add_edit_contact_screen.dart"),
        ("FR-SOS-001", "3-Second Countdown SOS Engine", "Press & hold SOS trigger with visual countdown, audio/haptic feedback, and location capture.", "Implemented", "lib/sos/presentation/screens/sos_countdown_screen.dart"),
        ("FR-QR-001", "Dynamic Opaque QR Token Lifecycle", "Callable Cloud Function generation of SHA-256 hashed QR tokens with 90-day expiry.", "Implemented", "functions/src/index.ts (createEmergencyQr)"),
        ("FR-SCAN-001", "First Responder Scanner & Viewer", "Camera QR scanner and glassmorphism public web card viewer (`backend/public/index.html`).", "Implemented", "lib/qr/presentation/screens/qr_scanner_screen.dart"),
        ("FR-NOT-001", "Backend FCM & SMS Dispatch Engine", "Cloud Functions Firestore v2 trigger broadcasting push alerts and fallback SMS.", "Implemented", "functions/src/index.ts (onEmergencyAlertCreated)"),
        ("FR-SET-001", "App Settings & Theme Switcher", "System, Light, and Dark theme toggling with SharedPreferences persistence.", "Implemented", "lib/settings/presentation/screens/settings_screen.dart"),
        ("FR-PRI-001", "Granular Privacy Sharing Consent Flags", "14 independent privacy switches controlling public QR medical field disclosures.", "Implemented", "lib/settings/presentation/screens/privacy_settings_screen.dart"),
        ("FR-OFF-001", "Hive Offline Cache & Sync Banner", "Namespaced local storage (`user_<uid>_*`) with visual offline status indicator.", "Implemented", "lib/core/offline/hive_cache_service.dart"),
        ("FR-ACC-001", "Protected Account Deletion Flow", "Re-authentication and Cloud Function cleanup of user data requiring 'DELETE' text.", "Implemented", "lib/settings/presentation/widgets/delete_account_dialog.dart"),
        ("FR-IOT-001", "NFC SmartTag & BLE Wearable Trigger", "Hardware integration for physical SOS button and NFC tap emergency access.", "Planned / Future Scope", "Future Architecture Spec")
    ]
    
    table_req = doc.add_table(rows=len(reqs)+1, cols=5)
    table_req.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(table_req)
    
    q_headers = ["Req ID", "Feature Title", "Description Summary", "Status", "Repository Evidence"]
    for j, text in enumerate(q_headers):
        cell = table_req.rows[0].cells[j]
        cell.paragraphs[0].add_run(text).font.bold = True
        cell.paragraphs[0].runs[0].font.color.rgb = RGBColor(255, 255, 255)
        set_cell_background(cell, "1565C0")
        set_cell_margins(cell, 100, 100, 120, 120)
        
    for i, ritem in enumerate(reqs):
        row_cells = table_req.rows[i+1].cells
        for j, text in enumerate(ritem):
            p = row_cells[j].paragraphs[0]
            r = p.add_run(text)
            if j == 0:
                r.font.bold = True
            if j == 3 and "Implemented" in text:
                r.font.bold = True
                r.font.color.rgb = RGBColor(46, 125, 50)
            elif j == 3:
                r.font.italic = True
                r.font.color.rgb = RGBColor(230, 81, 0)
            set_cell_margins(row_cells[j], 80, 80, 100, 100)
            if i % 2 == 1:
                set_cell_background(row_cells[j], "F9F9FB")

    # ---------------------------------------------------------------------------
    # 6. NON-FUNCTIONAL REQUIREMENTS
    # ---------------------------------------------------------------------------
    add_h1("6. NON-FUNCTIONAL REQUIREMENTS")
    
    nfrs = [
        ("NFR-PERF-001", "Performance & Latency", "SOS trigger activation completes in < 500ms; public QR resolution responds in < 1.5 seconds."),
        ("NFR-SEC-001", "Zero-Trust Secret Isolation", "No Firebase Admin credentials, FCM server keys, or Twilio auth tokens stored in mobile app."),
        ("NFR-PRIV-001", "Log Redaction Policy", "All Cloud Functions logs strip phone numbers, FCM tokens, emails, and medical PII automatically."),
        ("NFR-REL-001", "Idempotent Message Dispatch", "SHA-256 idempotency keys prevent duplicate FCM or SMS sends during trigger re-executions."),
        ("NFR-OFF-001", "Offline Resilience", "Owner medical profile and contacts accessible offline via namespaced Hive cache (`user_<uid>_*`).")
    ]
    
    for nid, title, desc in nfrs:
        p = doc.add_paragraph()
        r1 = p.add_run(f"• {nid} — {title}: ")
        r1.bold = True
        r1.font.color.rgb = COLOR_DARK
        p.add_run(desc)

    # ---------------------------------------------------------------------------
    # 7. SYSTEM DESIGN AND ARCHITECTURE
    # ---------------------------------------------------------------------------
    add_h1("7. SYSTEM DESIGN AND ARCHITECTURE")
    
    add_h2("7.1 Clean Architecture Overview")
    doc.add_paragraph(
        "SOZOTAP strictly adheres to Clean Architecture and MVVM design patterns with feature-first folder organization. "
        "The codebase is decoupled into 4 distinct layers:"
    )
    doc.add_paragraph(
        "1. Presentation Layer: Flutter Material 3 UI screens, custom widgets, and Riverpod StateNotifiers.\n"
        "2. Domain Layer: Business entities, data models (`EmergencyContact`, `PrivacySettingsModel`), and repository interfaces.\n"
        "3. Data Layer: Repository implementations, Firestore data sources, and Hive cache adapters.\n"
        "4. Platform & Infrastructure Layer: Firebase Auth, Cloud Firestore, FCM, Firebase Storage, and Cloud Functions v2."
    )
    
    add_h2("7.2 System Architecture ASCII Diagram")
    
    p_diag = doc.add_paragraph()
    p_diag.paragraph_format.space_before = Pt(6)
    p_diag.paragraph_format.space_after = Pt(12)
    r_diag = p_diag.add_run(
"""+-------------------------------------------------------------------------+
|                      FLUTTER MOBILE CLIENT (ANDROID)                    |
|  [Material 3 UI] ---> [Riverpod Controllers] ---> [GoRouter Navigation]  |
+------------------------------------+------------------------------------+
                                     |
                                     v
+------------------------------------+------------------------------------+
|                      LOCAL DATA & CACHE LAYER                           |
|  [Hive Cache (user_<uid>_*)] <---> [SharedPreferences (Theme/Locale)]   |
+------------------------------------+------------------------------------+
                                     |
                                     v
+------------------------------------+------------------------------------+
|                  FIREBASE CLOUD INFRASTRUCTURE                          |
|  [Cloud Firestore] <---> [Firebase Auth] <---> [Firebase Storage]       |
+------------------------------------+------------------------------------+
                                     |
                                     v
+------------------------------------+------------------------------------+
|                  FIREBASE CLOUD FUNCTIONS v2 (TypeScript)              |
|  [onEmergencyAlertCreated] ---> [FcmService / Twilio SmsService]        |
|  [resolveEmergencyQr]      ---> [Authoritative Consent Redactor]        |
|  [deleteUserAccount]       ---> [Multi-Resource Cloud Cleanup]          |
+------------------------------------+------------------------------------+
                                     |
                                     v
+------------------------------------+------------------------------------+
|                  EXTERNAL NOTIFICATION DISPATCH TARGETS                 |
|  [Emergency Contacts FCM]  <---> [SMS Gateway (Twilio / Fallback)]      |
|  [Paramedic Web Viewer]    <---> [https://vitanexus.web.app/qr/<token>]  |
+-------------------------------------------------------------------------+"""
    )
    r_diag.font.name = 'Consolas'
    r_diag.font.size = Pt(8.5)
    r_diag.font.color.rgb = COLOR_DARK

    # ---------------------------------------------------------------------------
    # 8. DATA DESIGN & DATABASE SPECIFICATION
    # ---------------------------------------------------------------------------
    add_h1("8. DATA DESIGN AND DATABASE SPECIFICATION")
    
    doc.add_paragraph("SOZOTAP utilizes Cloud Firestore as its primary cloud database. Below is the complete collection specification:")
    
    table_db = doc.add_table(rows=7, cols=4)
    table_db.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(table_db)
    
    db_headers = ["Collection Path", "Document ID Strategy", "Ownership / Access Rule", "Purpose"]
    for j, text in enumerate(db_headers):
        cell = table_db.rows[0].cells[j]
        cell.paragraphs[0].add_run(text).font.bold = True
        cell.paragraphs[0].runs[0].font.color.rgb = RGBColor(255, 255, 255)
        set_cell_background(cell, "E53935")
        set_cell_margins(cell, 100, 100, 120, 120)
        
    db_rows = [
        ("medical_profiles/{uid}", "User UID", "Owner Read/Write Only", "Authoritative medical history & consent flags"),
        ("users/{uid}/emergency_contacts/{id}", "UUID v4", "Owner Read/Write Only", "Designated contacts & SMS consent timestamps"),
        ("users/{uid}/device_tokens/{tokenId}", "Token Hash", "Owner Read/Write Only", "Registered FCM device tokens for push alerts"),
        ("users/{uid}/privacy_settings/settings", "Static 'settings'", "Owner Read/Write Only", "14 granular emergency sharing switches"),
        ("emergency_alerts/{alertId}", "Auto Document ID", "Owner Create/Update; Contact Read", "Active SOS alert sessions & GPS coordinates"),
        ("message_deliveries/{deliveryId}", "Auto Document ID", "Backend Admin SDK Write Only", "Audit logs for FCM and SMS dispatch status")
    ]
    
    for i, dbdata in enumerate(db_rows):
        row_cells = table_db.rows[i+1].cells
        for j, text in enumerate(dbdata):
            p = row_cells[j].paragraphs[0]
            p.add_run(text)
            set_cell_margins(row_cells[j], 80, 80, 100, 100)
            if i % 2 == 1:
                set_cell_background(row_cells[j], "F9F9FB")

    # ---------------------------------------------------------------------------
    # 9. SECURITY AND PRIVACY DESIGN
    # ---------------------------------------------------------------------------
    add_h1("9. SECURITY AND PRIVACY DESIGN")
    
    doc.add_paragraph("SOZOTAP enforces zero-trust data protection principles:")
    doc.add_paragraph(
        "• Secret Isolation: No API keys, Twilio secrets, or Admin SDK credentials reside in Flutter.\n"
        "• Log Redaction: All functions logs automatically strip phone numbers (`+14****71`), FCM tokens, emails, and medical PII.\n"
        "• Opaque QR Hashing: Physical QR codes contain only opaque tokens (`https://vitanexus.web.app/qr/<token>`). Cloud Functions verify SHA-256 token hashes.\n"
        "• Protected Account Deletion: Account deletion requires password re-authentication and typing 'DELETE', executing multi-resource cleanup via `deleteUserAccount`."
    )

    # ---------------------------------------------------------------------------
    # 10. TESTING AND QUALITY ASSURANCE
    # ---------------------------------------------------------------------------
    add_h1("10. TESTING AND QUALITY ASSURANCE")
    
    doc.add_paragraph("The project includes multi-tiered automated and manual verification suite:")
    doc.add_paragraph(
        "1. Jest Cloud Functions Unit Tests (`functions/test/functions.test.ts`): 7/7 tests passed covering idempotency, redaction, phone validation, `DisabledSmsProvider`, and privacy consent flags.\n"
        "2. Flutter Unit Tests (`test/`): Unit tests for token models, notification items, privacy settings presets, Hive cache secret stripping, and connectivity state mapping.\n"
        "3. TypeScript Build: Executed `npm run build` cleanly with 0 compilation errors."
    )

    # ---------------------------------------------------------------------------
    # 11. FUTURE ENHANCEMENTS & IOT ARCHITECTURE
    # ---------------------------------------------------------------------------
    add_h1("11. FUTURE ENHANCEMENTS & IOT ARCHITECTURE")
    
    doc.add_paragraph(
        "Future phases will extend SOZOTAP beyond smartphones into hardware and wearable emergency dispatches:\n"
        "• NFC SmartTags & Silicon Wristbands: Tap-to-view emergency profile for first responders without camera scanning.\n"
        "• BLE Wearable SOS Button: Dedicated wristlet/pendant button pairing with smartphone over Bluetooth Low Energy.\n"
        "• ESP32 Standalone Hardware Trigger: Wi-Fi/GSM panic button for elderly home care with GPS tracking."
    )

    # ---------------------------------------------------------------------------
    # 12. CONCLUSION & VIVA SUMMARY
    # ---------------------------------------------------------------------------
    add_h1("12. CONCLUSION AND PROJECT VIVA SUMMARY")
    
    add_h2("Project Viva Summary (1-Page Fast Reference)")
    doc.add_paragraph("• Project Name: SOZOTAP (“One Tap Can Save a Life”)\n• Category: Secure Emergency Response & Medical Information System\n• Stack: Flutter (Dart), Firebase Auth, Cloud Firestore, Cloud Functions v2 (TypeScript), FCM, Hive, GoRouter, Riverpod\n• Key Innovation: Separation of public QR display from private database stores using opaque SHA-256 hashed tokens and authoritative user privacy consent flags.")
    doc.add_paragraph("• Core Workflows:\n  1. SOS Activation: Press & hold 3s countdown broadcasts FCM push alerts and SMS notifications with live GPS location.\n  2. Medical Profile & QR: Paramedics scan dynamic QR code to access a redacted emergency web card without needing app login.\n  3. Offline & Security: Namespaced local Hive cache (`user_<uid>_*`) with zero secrets stored locally and protected Cloud Function account deletion.")

    # ---------------------------------------------------------------------------
    # 13. REFERENCES
    # ---------------------------------------------------------------------------
    add_h1("13. REFERENCES")
    
    refs = [
        "1. Google Deepmind / Flutter Team, \"Flutter Documentation & Material 3 Specifications,\" 2026. https://docs.flutter.dev",
        "2. Firebase Team, \"Firebase Cloud Functions v2 & Cloud Firestore Security Rules Guide,\" Google Cloud, 2026. https://firebase.google.com/docs",
        "3. Twilio Inc., \"Twilio Programmable SMS API Reference & TCPA Compliance Guide,\" 2026. https://www.twilio.com/docs/sms",
        "4. SOZOTAP Project Repository, \"Source Code & Engineering Specifications,\" 2026."
    ]
    
    for ref in refs:
        p = doc.add_paragraph(ref)
        p.paragraph_format.space_after = Pt(4)
        
    doc.save("SOZOTAP_Mobile_Application_Project_Documentation.docx")
    print("Successfully generated SOZOTAP_Mobile_Application_Project_Documentation.docx")

if __name__ == "__main__":
    build_docx()
