package main

import (
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract provides functions for managing digital certificates
type SmartContract struct {
	contractapi.Contract
}

// Student describes basic details of a student
type Student struct {
	StudentID string    `json:"studentId"`
	Name      string    `json:"name"`
	Email     string    `json:"email"`
	School    string    `json:"school"`
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`
}

// Certificate describes the structure of a certificate
type Certificate struct {
	CertID       string    `json:"certId"`
	StudentID    string    `json:"studentId"`
	CourseID     string    `json:"courseId"`
	Grade        string    `json:"grade"`
	Teacher      string    `json:"teacher"`
	OriginalHash string    `json:"originalHash"`
	CreatedAt    time.Time `json:"createdAt"`
	UpdatedAt    time.Time `json:"updatedAt"`
}

// VerificationResult is the structure for the event payload
type VerificationResult struct {
	CertificateID string    `json:"certificate"`
	StudentID     string    `json:"student"`
	Verifier      string    `json:"verifier"`
	Result        string    `json:"result"`
	VerifiedOn    time.Time `json:"verifiedOn"`
}

// InitLedger is a dummy function to satisfy the chaincode interface
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	fmt.Println("certnet chaincode initialized")
	return nil
}

// CreateStudent issues a new student to the world state with given details.
func (s *SmartContract) CreateStudent(ctx contractapi.TransactionContextInterface, studentID string, name string, email string) (*Student, error) {
	studentKey, err := ctx.GetStub().CreateCompositeKey("org.certification-network.certnet.student", []string{studentID})
	if err != nil {
		return nil, fmt.Errorf("failed to create composite key: %v", err)
	}

	existing, err := ctx.GetStub().GetState(studentKey)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if existing != nil {
		return nil, fmt.Errorf("the student %s already exists", studentID)
	}
	
	clientIdentity, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return nil, fmt.Errorf("failed to get client ID: %v", err)
	}

	student := Student{
		StudentID: studentID,
		Name:      name,
		Email:     email,
		School:    clientIdentity,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	studentJSON, err := json.Marshal(student)
	if err != nil {
		return nil, err
	}

	err = ctx.GetStub().PutState(studentKey, studentJSON)
	if err != nil {
		return nil, err
	}

	return &student, nil
}

// GetStudent returns the student stored in the world state with given id.
func (s *SmartContract) GetStudent(ctx contractapi.TransactionContextInterface, studentID string) (*Student, error) {
	studentKey, err := ctx.GetStub().CreateCompositeKey("org.certification-network.certnet.student", []string{studentID})
	if err != nil {
		return nil, fmt.Errorf("failed to create composite key: %v", err)
	}

	studentJSON, err := ctx.GetStub().GetState(studentKey)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if studentJSON == nil {
		return nil, fmt.Errorf("the student %s does not exist", studentID)
	}

	var student Student
	err = json.Unmarshal(studentJSON, &student)
	if err != nil {
		return nil, err
	}

	return &student, nil
}

// IssueCertificate issues a new certificate to a student.
func (s *SmartContract) IssueCertificate(ctx contractapi.TransactionContextInterface, studentID string, courseID string, gradeReceived string, originalHash string) (*Certificate, error) {
	studentKey, err := ctx.GetStub().CreateCompositeKey("org.certification-network.certnet.student", []string{studentID})
	if err != nil {
		return nil, fmt.Errorf("failed to create student composite key: %v", err)
	}
	studentBytes, err := ctx.GetStub().GetState(studentKey)
	if err != nil {
		return nil, fmt.Errorf("failed to read student from world state: %v", err)
	}
	if studentBytes == nil {
		return nil, fmt.Errorf("student with ID %s does not exist", studentID)
	}

	certID := fmt.Sprintf("%s-%s", courseID, studentID)
	certificateKey, err := ctx.GetStub().CreateCompositeKey("org.certification-network.certnet.certificate", []string{certID})
	if err != nil {
		return nil, fmt.Errorf("failed to create certificate composite key: %v", err)
	}
	
	certBytes, err := ctx.GetStub().GetState(certificateKey)
	if err != nil {
		return nil, fmt.Errorf("failed to check for existing certificate: %v", err)
	}
	if certBytes != nil {
		return nil, fmt.Errorf("certificate for course %s and student %s already exists", courseID, studentID)
	}
	
	clientIdentity, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return nil, fmt.Errorf("failed to get client ID: %v", err)
	}

	certificate := Certificate{
		CertID:       certID,
		StudentID:    studentID,
		CourseID:     courseID,
		Grade:        gradeReceived,
		Teacher:      clientIdentity,
		OriginalHash: originalHash,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	certificateJSON, err := json.Marshal(certificate)
	if err != nil {
		return nil, err
	}

	err = ctx.GetStub().PutState(certificateKey, certificateJSON)
	if err != nil {
		return nil, err
	}

	return &certificate, nil
}

// VerifyCertificate verifies the integrity of a certificate by comparing its hash.
func (s *SmartContract) VerifyCertificate(ctx contractapi.TransactionContextInterface, studentID string, courseID string, currentHash string) (*VerificationResult, error) {
	certID := fmt.Sprintf("%s-%s", courseID, studentID)
	certificateKey, err := ctx.GetStub().CreateCompositeKey("org.certification-network.certnet.certificate", []string{certID})
	if err != nil {
		return nil, fmt.Errorf("failed to create composite key: %v", err)
	}

	certificateJSON, err := ctx.GetStub().GetState(certificateKey)
	if err != nil {
		return nil, fmt.Errorf("failed to read certificate from world state: %v", err)
	}
	if certificateJSON == nil {
		return nil, fmt.Errorf("certificate for course %s and student %s does not exist", courseID, studentID)
	}

	var certificate Certificate
	err = json.Unmarshal(certificateJSON, &certificate)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal certificate data: %v", err)
	}
	
	verifier, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return nil, fmt.Errorf("failed to get verifier ID: %v", err)
	}

	result := &VerificationResult{
		CertificateID: certID,
		StudentID:     studentID,
		Verifier:      verifier,
		VerifiedOn:    time.Now(),
	}
	
	if certificate.OriginalHash == currentHash {
		result.Result = "*** - VALID"
	} else {
		result.Result = "xxx - INVALID"
	}

	eventPayload, err := json.Marshal(result)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal event payload: %v", err)
	}

	err = ctx.GetStub().SetEvent("verifyCertificate", eventPayload)
	if err != nil {
		return nil, fmt.Errorf("failed to set event: %v", err)
	}
	
	return result, nil
}


func main() {
	chaincode, err := contractapi.NewChaincode(&SmartContract{})
	if err != nil {
		log.Panicf("Error creating certnet chaincode: %v", err)
	}

	if err := chaincode.Start(); err != nil {
		log.Panicf("Error starting certnet chaincode: %v", err)
	}
}
