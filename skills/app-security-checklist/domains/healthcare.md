# Healthcare Security Profile

## Compliance Framework
- HIPAA Security Rule (45 CFR Part 164)
- HIPAA Privacy Rule
- HITECH Act
- HL7 FHIR security considerations

## Detection Signals
Keywords that trigger auto-detection: `hipaa`, `patient`, `medical`,
`health_record`, `diagnosis`, `prescription`, `hl7`, `fhir`, `phi`

## Severity Elevations

| Item | Standard Severity | Healthcare Severity | Reason |
|------|-------------------|---------------------|--------|
| DP-01 (PII plain text) | High | Critical | PHI subject to HIPAA |
| EH-05 (Audit trail) | Medium | Critical | HIPAA requires audit controls |
| DP-04 (Encryption at rest) | High | Critical | HIPAA addressable requirement |
| CS-01 (HTTPS) | High | Critical | HIPAA transmission security |
| AC-02 (Authorization) | Critical | Critical | PHI access must be authorized |
| EH-04 (Sensitive data in logs) | High | Critical | PHI in logs is a HIPAA violation |
| SM-03 (Session expiry) | Medium | High | HIPAA workstation security |

## Additional Checks

### HC-01: PHI Access Logging
- **What to check:** Every access to patient data is logged (read AND write)
- **Detection patterns:**
  - Search: logging around patient/medical record access
  - Search: `Patient|MedicalRecord|HealthRecord` model access without audit
  - Search: PHI read operations without logging
  - Files: `app/controllers/**/*patient*`, `app/models/**/*patient*`, `app/services/**/*medical*`
- **Secure pattern:**
  ```ruby
  class PatientRecordsController < ApplicationController
    after_action :log_phi_access
    def log_phi_access
      PhiAuditLog.create!(user: current_user, patient_id: params[:id], action: action_name, ip: request.remote_ip)
    end
  end
  ```
- **Severity:** Critical

### HC-02: Minimum Necessary Access
- **What to check:** Users see only the PHI necessary for their role
- **Detection patterns:**
  - Search: role-based data filtering on patient records
  - Search: `select|only|except` clauses on PHI queries by role
  - Search: all PHI fields exposed regardless of user role
  - Files: `app/policies/**/*.rb`, `app/controllers/**/*patient*`, `app/serializers/**/*.rb`
- **Secure pattern:**
  ```ruby
  class PatientPolicy < ApplicationPolicy
    def permitted_fields
      case user.role
      when 'nurse' then [:name, :vitals, :medications]
      when 'doctor' then [:name, :vitals, :medications, :diagnosis, :history]
      when 'billing' then [:name, :insurance, :billing_code]
      end
    end
  end
  ```
- **Severity:** High

### HC-03: Break-the-Glass Procedure
- **What to check:** Emergency access to restricted PHI is logged and reviewed
- **Detection patterns:**
  - Search: emergency access or override mechanisms in authorization
  - Search: `emergency|break_glass|override` in access control
  - Search: elevated access without additional logging
  - Files: `app/controllers/**/*.rb`, `app/policies/**/*.rb`
- **Secure pattern:**
  ```ruby
  def emergency_access
    EmergencyAccessLog.create!(user: current_user, patient_id: params[:id], reason: params[:reason])
    notify_compliance_team(current_user, params[:id])
    # Grant temporary elevated access
  end
  ```
- **Severity:** High

### HC-04: Data De-identification
- **What to check:** PHI properly de-identified for research/analytics
- **Detection patterns:**
  - Search: de-identification, anonymization in data export features
  - Search: `anonymize|de_identify|redact` in data processing
  - Search: analytics queries on PHI without de-identification
  - Files: `app/services/**/*export*`, `app/services/**/*analytics*`, `lib/tasks/**/*.rake`
- **Secure pattern:**
  ```ruby
  class DeIdentificationService
    HIPAA_IDENTIFIERS = %i[name address phone email ssn dob medical_record_number].freeze
    def call(record)
      record.attributes.except(*HIPAA_IDENTIFIERS.map(&:to_s))
    end
  end
  ```
- **Severity:** High

### HC-05: Business Associate Agreements
- **What to check:** Third-party integrations handling PHI have BAA documentation
- **Detection patterns:**
  - Search: third-party API calls with patient data
  - Search: webhook payloads containing PHI
  - Search: external service integrations in PHI data flow
  - Files: `app/services/**/*.rb`, `config/initializers/**/*.rb`
- **Secure pattern:** Document all third parties receiving PHI. Verify BAA exists for each.
- **Severity:** High (compliance, not code)
