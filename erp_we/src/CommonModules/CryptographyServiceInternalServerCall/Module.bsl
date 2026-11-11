////////////////////////////////////////////////////////////////////////////////
// Subsystem "Cryptography service (service)".
//  
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Encrypt
// 
// Parameters: 
//  Data - See CryptographyServiceClient.Encrypt.Data
//  Recipients - See CryptographyServiceClient.Encrypt.Recipients
//  EncryptionType - See CryptographyServiceClient.Encrypt.EncryptionType
//  EncryptionParameters - See CryptographyServiceClient.Encrypt.EncryptionParameters
// 
// Returns: See TimeConsumingOperations.ExecuteInBackground
Function Encrypt(Val Data, Val Recipients, Val EncryptionType, Val EncryptionParameters) Export
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Recipients", Recipients);
	ProcedureParameters.Insert("EncryptionType", EncryptionType);
	ProcedureParameters.Insert("EncryptionParameters", EncryptionParameters);
	ProcedureParameters.Insert("ReturnResultAsAddressInTemporaryStorage", CryptographyServiceInternal.ReturnResultAsAddressInTemporaryStorage(Data));
	Data = CryptographyServiceInternal.ExtractBinaryDataIfNecessary(Data);
	ProcedureParameters.Insert("Data", Data);
			
	ResultFileAddresses = New Array;
	If ProcedureParameters.ReturnResultAsAddressInTemporaryStorage Then
		If TypeOf(Data) = Type("Array") Then 
			TotalItems = Data;
		Else
			TotalItems = CommonClientServer.ValueInArray(Data);
		EndIf;		
		// @skip-warning UnusedVariable - a feature of the implementation.
		For Each Item In TotalItems Do
			ResultFileAddresses.Add(PutToTempStorage(Undefined, New UUID));
		EndDo;
	EndIf;
	ProcedureParameters.Insert("ResultFileAddresses", ResultFileAddresses);
		
	Return CryptographyServiceInternal.ExecuteInBackground("CryptographyServiceInternal.Encrypt", ProcedureParameters);
	
EndFunction

// To encrypt a block
// 
// Parameters: 
//  Data - See CryptographyServiceClient.DecryptBlock.EncryptedData
//  Recipient - See CryptographyServiceClient.DecryptBlock.Recipient
// 
// Returns: See TimeConsumingOperations.ExecuteInBackground
Function EncryptBlock(Val Data, Val Recipient) Export
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Recipient", Recipient);
	ProcedureParameters.Insert("ReturnResultAsAddressInTemporaryStorage", CryptographyServiceInternal.ReturnResultAsAddressInTemporaryStorage(Data));
	Data = CryptographyServiceInternal.ExtractBinaryDataIfNecessary(Data);
	ProcedureParameters.Insert("Data", Data);
			
	If ProcedureParameters.ReturnResultAsAddressInTemporaryStorage Then
		ProcedureParameters.Insert("AddressOfResultFile", PutToTempStorage(Undefined, New UUID));
	EndIf;
		
	Return CryptographyServiceInternal.ExecuteInBackground("CryptographyServiceInternal.EncryptBlock", ProcedureParameters);
	
EndFunction

// Parameters: 
//  EncryptedData - See CryptographyServiceClient.Decrypt.EncryptedData
//  Certificate - Structure:
//   * Id - Arbitrary
//  EncryptionType - See CryptographyServiceClient.Decrypt.EncryptionType
//  EncryptionParameters - See CryptographyServiceClient.Decrypt.EncryptionParameters
// 
// Returns:  See TimeConsumingOperations.ExecuteInBackground
Function Decrypt(Val EncryptedData, Val Certificate, Val EncryptionType, Val EncryptionParameters) Export
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("EncryptedData", CryptographyServiceInternal.ExtractBinaryDataIfNecessary(EncryptedData));
	ProcedureParameters.Insert("Certificate", Certificate);
	ProcedureParameters.Insert("EncryptionType", EncryptionType);
	ProcedureParameters.Insert("EncryptionParameters", EncryptionParameters);
	ProcedureParameters.Insert("ReturnResultAsAddressInTemporaryStorage", CryptographyServiceInternal.ReturnResultAsAddressInTemporaryStorage(EncryptedData));
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	ProcedureParameters.Insert("SecurityTokens", SessionParameters.SecurityTokens);
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	ResultFileAddresses = New Array;
	ResultFileAddresses.Add(PutToTempStorage(Undefined, New UUID));
	ProcedureParameters.Insert("ResultFileAddresses", ResultFileAddresses);
	
	Return CryptographyServiceInternal.ExecuteInBackground("CryptographyServiceInternal.Decrypt", ProcedureParameters);
	
EndFunction

// Parameters: 
//  EncryptedData - See CryptographyServiceClient.DecryptBlock.EncryptedData
//  Recipient - See CryptographyServiceClient.DecryptBlock.Recipient
//  KeyInformation - See CryptographyServiceClient.DecryptBlock.KeyInformation
//  EncryptionParameters - See CryptographyServiceClient.DecryptBlock.EncryptionParameters
// 
// Returns: See TimeConsumingOperations.ExecuteInBackground
Function DecryptBlock(Val EncryptedData, Val Recipient, Val KeyInformation, Val EncryptionParameters) Export
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("EncryptedData", CryptographyServiceInternal.ExtractBinaryDataIfNecessary(EncryptedData));
	ProcedureParameters.Insert("Recipient", Recipient);
	ProcedureParameters.Insert("KeyInformation", KeyInformation);	
	ProcedureParameters.Insert("EncryptionParameters", EncryptionParameters);
	ProcedureParameters.Insert("ReturnResultAsAddressInTemporaryStorage", CryptographyServiceInternal.ReturnResultAsAddressInTemporaryStorage(EncryptedData));
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	ProcedureParameters.Insert("SecurityTokens", SessionParameters.SecurityTokens);
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	AddressOfResultFile = PutToTempStorage(Undefined, New UUID);
	ProcedureParameters.Insert("AddressOfResultFile", AddressOfResultFile);
	
	Return CryptographyServiceInternal.ExecuteInBackground("CryptographyServiceInternal.DecryptBlock", ProcedureParameters);
	
EndFunction

// Returns: See TimeConsumingOperations.ExecuteInBackground
Function Sign(Val Data, Val Signatory, Val SignatureType, Val SigningParameters) Export
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Signatory", Signatory);
	ProcedureParameters.Insert("SignatureType", SignatureType);
	ProcedureParameters.Insert("SigningParameters", SigningParameters);
	ProcedureParameters.Insert("ReturnResultAsAddressInTemporaryStorage", CryptographyServiceInternal.ReturnResultAsAddressInTemporaryStorage(Data));
	Data = CryptographyServiceInternal.ExtractBinaryDataIfNecessary(Data);
	ProcedureParameters.Insert("Data", Data);
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	ProcedureParameters.Insert("SecurityTokens", SessionParameters.SecurityTokens);
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	ResultFileAddresses = New Array;
	If ProcedureParameters.ReturnResultAsAddressInTemporaryStorage Then
		If TypeOf(Data) = Type("Array") Then 
			TotalItems = Data;
		Else
			TotalItems = CommonClientServer.ValueInArray(Data);
		EndIf;		
		// @skip-warning UnusedVariable - a feature of the implementation.
		For Each Item In TotalItems Do
			ResultFileAddresses.Add(PutToTempStorage(Undefined, New UUID));
		EndDo;
	EndIf;
	ProcedureParameters.Insert("ResultFileAddresses", ResultFileAddresses);
	
	Return CryptographyServiceInternal.ExecuteInBackground("CryptographyServiceInternal.Sign", ProcedureParameters);	
	
EndFunction

// Returns: See TimeConsumingOperations.ExecuteInBackground
Function VerifySignature(Val Signature, Val Data, Val SignatureType, Val SigningParameters) Export
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Data", CryptographyServiceInternal.ExtractBinaryDataIfNecessary(Data));
	ProcedureParameters.Insert("Signature", CryptographyServiceInternal.ExtractBinaryDataIfNecessary(Signature));
	ProcedureParameters.Insert("SignatureType", SignatureType);
	ProcedureParameters.Insert("SigningParameters", SigningParameters);
	
	Return CryptographyServiceInternal.ExecuteInBackground("CryptographyServiceInternal.VerifySignature", ProcedureParameters);	
	
EndFunction

// Returns: See TimeConsumingOperations.ExecuteInBackground
Function CheckCertificate(Val Certificate) Export
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Certificate", CryptographyServiceInternal.ExtractBinaryDataIfNecessary(Certificate));
	
	Return CryptographyServiceInternal.ExecuteInBackground("CryptographyServiceInternal.CheckCertificate", ProcedureParameters);	

EndFunction

// Returns: See TimeConsumingOperations.ExecuteInBackground
Function VerifyCertificateWithParameters(Val Certificate, Val CheckParameters) Export
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Certificate", CryptographyServiceInternal.ExtractBinaryDataIfNecessary(Certificate));
	ProcedureParameters.Insert("CheckParameters", CheckParameters);
	
	Return CryptographyServiceInternal.ExecuteInBackground("CryptographyServiceInternal.VerifyCertificateWithParameters", ProcedureParameters);	

EndFunction

// Returns: See TimeConsumingOperations.ExecuteInBackground
Function GetCertificateProperties(Val Certificate) Export
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Certificate", CryptographyServiceInternal.ExtractBinaryDataIfNecessary(Certificate));
	
	Return CryptographyServiceInternal.ExecuteInBackground("CryptographyServiceInternal.GetCertificateProperties", ProcedureParameters);	
	
EndFunction

// To obtain the certificate from the signature
// 
// Parameters: 
//  Signature - String, BinaryData - the signature data.
// 
// Returns: 
//  Structure:
// * Status - String
// * JobID - UUID
// * ResultAddress - String
// * AdditionalResultAddress - String
// * BriefErrorDescription - String
// * DetailErrorDescription - String
// * Messages - FixedArray of String
//
Function GetCertificatesFromSignature(Val Signature) Export
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Signature", CryptographyServiceInternal.ExtractBinaryDataIfNecessary(Signature));
	ProcedureParameters.Insert("ReturnResultAsAddressInTemporaryStorage", CryptographyServiceInternal.ReturnResultAsAddressInTemporaryStorage(Signature));
	
	Return CryptographyServiceInternal.ExecuteInBackground("CryptographyServiceInternal.GetCertificatesFromSignature", ProcedureParameters);	
	
EndFunction

// Returns: See TimeConsumingOperations.ExecuteInBackground
Function GetCryptoMessageProperties(Val CryptoMessage, Val OnlyKeyProperties) Export
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("CryptoMessage", CryptographyServiceInternal.ExtractBinaryDataIfNecessary(CryptoMessage));
	ProcedureParameters.Insert("OnlyKeyProperties", OnlyKeyProperties);
	
	Return CryptographyServiceInternal.ExecuteInBackground("CryptographyServiceInternal.GetCryptoMessageProperties", ProcedureParameters);
	
EndFunction

// Parameters: 
//  Data - See CryptographyServiceClient.DataHashing.Data
//  HashAlgorithm - See CryptographyServiceClient.DataHashing.HashAlgorithm
//  HashingParameters - See CryptographyServiceClient.DataHashing.HashingParameters
// 
// Returns: See TimeConsumingOperations.ExecuteInBackground
Function DataHashing(Val Data, Val HashAlgorithm, Val HashingParameters) Export
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Data", CryptographyServiceInternal.ExtractBinaryDataIfNecessary(Data));
	ProcedureParameters.Insert("HashAlgorithm", HashAlgorithm);
	ProcedureParameters.Insert("HashingParameters", HashingParameters);
	
	Return CryptographyServiceInternal.ExecuteInBackground("CryptographyServiceInternal.DataHashing", ProcedureParameters);	
	
EndFunction

// Sorts the ids of certificates by date of validity and belonging to the database
//
// Parameters:
//	CertificateIDs - Array of String - contains certificate IDs
//
// Returns:
//  Array of String
//
Function DetermineOrderOfCertificates(CertificateIDs) Export
	
	Return CryptographyServiceInternal.DetermineOrderOfCertificates(CertificateIDs);
	
EndFunction

#EndRegion
