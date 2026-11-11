////////////////////////////////////////////////////////////////////////////////
// Subsystem "Electronic signature in the service model".
//  
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Generates a name to search for the certificate ID settings in the secure storage.
// 
// Parameters:
//	CertificateID - String - settings search key
//
// Returns:
//	String - name of the setting.
//
Function NameForConfiguringLongTermCertificateToken(CertificateID)

	Return "DigitalSignature.DigitalSignatureSaaS." + CertificateID;

EndFunction

// Returns the storage structure for the token verification settings for the certificate
//
// Returns:
//	Structure - contains the necessary properties:
//	* CryptoOperationsConfirmationMethod - EnumRef.CryptoOperationsConfirmationMethods
//	* Id - String
//	* Thumbprint - String
//	* Token - String
//
Function DecryptionSigningBasicProperties()
	
	Result = New Structure();
	Result.Insert("CryptoOperationsConfirmationMethod", Enums.CryptoOperationsConfirmationMethods.SessionToken);
	Result.Insert("Id", "");
	Result.Insert("Thumbprint", "");
	Result.Insert("Token", "");
	
	Return Result;
	
EndFunction

// The service function is used to determine the certificate ID in the passed parameters
//
// Parameters:
//	Certificate - String, Structure - data containing the certificate ID:
//	 * Id - String - ID of the certificate.
//
// Returns:
//   String - contains the certificate ID or an empty string.
//
Function IDOfPropertyCertificate(Certificate, CurrentProperties = Undefined)
	
	Result = "";
	Thumbprint = "";
	
	If TypeOf(Certificate) = Type("Structure") Then
		If Certificate.Property("Id") Then
			Result = CryptographyServiceInternal.Id(Certificate);
		ElsIf Certificate.Property("Thumbprint") Then
			Thumbprint = Certificate.Thumbprint;
			CertificateStructure = CertificatesStorage.FindCertificate(Certificate);
			If CertificateStructure <> Undefined Then
				Result = CertificateStructure.Id;
			EndIf;	
		EndIf;
		
	Else
		Result = Certificate;
		
	EndIf;
	
	If CurrentProperties <> Undefined Then
		CurrentProperties.Thumbprint 		= Thumbprint;
		CurrentProperties.Id 	= Result;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the certificate settings: use of a long-term token and its value
//
// Parameters:
//   Certificate - String, Structure - contains certificate properties, the presence of the "Identifier" property is required:
//    * Id - String
//    
// Returns:
//  See DecryptionSigningBasicProperties
//
Function CertificateSigningDecryptProperties(Certificate) Export
	
	Result 					= DecryptionSigningBasicProperties();
	CertificateID    = IDOfPropertyCertificate(Certificate, Result);
	
	If Not ValueIsFilled(CertificateID) Then
		Return Result;
	EndIf;
	
	Try
		SetSafeModeDisabled(True);
		SetPrivilegedMode(True);
		
		// We store the long-term security token in a secure password store.
		ConfigurationData = Common.ReadDataFromSecureStorage(NameForConfiguringLongTermCertificateToken(CertificateID), "Settings");
		
		SetPrivilegedMode(False);
		SetSafeModeDisabled(False);
		
		If ConfigurationData <> Undefined Then
			FillPropertyValues(Result, ConfigurationData);
		EndIf;
		
	Except
		
	EndTry;
	
	Return Result;
	
EndFunction

// Deletes settings for using a long-term token
//
// Parameters:
//	Certificate - Structure, String - contains properties of the certificate, the existence of the property "ID" is mandatory.
//
Procedure DeleteDecryptionSigningProperties(Certificate) Export
	
	CertificateID    = IDOfPropertyCertificate(Certificate);
	
	If Not ValueIsFilled(CertificateID) Then
		Return;
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Common.DeleteDataFromSecureStorage(NameForConfiguringLongTermCertificateToken(CertificateID));
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

// Saves settings for using a long-term token
//
// Parameters:
//   Certificate - Structure, String - contains properties of the certificate, the existence of the property "ID" is mandatory.
//
Procedure SetDecryptionSigningProperties(Certificate) Export
	
	NewSettings1 				= DecryptionSigningBasicProperties();
	CertificateID    = IDOfPropertyCertificate(Certificate, NewSettings1);
	
	If Not ValueIsFilled(CertificateID) Then
		Return;
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	SettingName	= CryptographyServiceInternal.ConfigurationNameAndCertificateSecurityToken(CertificateID);
	CurrentToken	= Common.ReadDataFromSecureStorage(SettingName, "UseLongLastingSecurityToken");
						
	NewSettings1.CryptoOperationsConfirmationMethod = Enums.CryptoOperationsConfirmationMethods.LongLivedToken;
	If CurrentToken <> Undefined Then
		NewSettings1.Token = CurrentToken;
	EndIf;						
	
	SettingName = NameForConfiguringLongTermCertificateToken(CertificateID);
	Common.WriteDataToSecureStorage(SettingName, NewSettings1, "Settings");
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

Procedure ConfigureUseOfLongTermToken(CryptoOperationsConfirmationMethod, Certificate) Export
	
	CertificateID    = IDOfPropertyCertificate(Certificate);
	
	If Not ValueIsFilled(CertificateID) Then
		Return;
	
	ElsIf CryptoOperationsConfirmationMethod = Enums.CryptoOperationsConfirmationMethods.LongLivedToken Then
		SetDecryptionSigningProperties(CertificateID);
		
	Else
		DeleteDecryptionSigningProperties(CertificateID);
		
	EndIf;
	
EndProcedure

// Parameters:
// 	Certificate - See CryptographyServiceInternal.Id.Certificate
// Returns:
// 	BinaryData - certificate data.
Function FindCertificateById(Certificate) Export
	
	If Certificate.Property("Thumbprint")
		And ValueIsFilled(Certificate.Thumbprint) Then
		Result = Certificate.Thumbprint;
		
	Else
		SetSafeModeDisabled(True);
		SetPrivilegedMode(True);
		
		QueryText = 
		"SELECT TOP 1
		|	CertificatesStorage.Thumbprint AS Thumbprint
		|FROM
		|	InformationRegister.CertificatesStorage AS CertificatesStorage
		|WHERE
		|	CertificatesStorage.Id = &Id
		|	AND CertificatesStorage.StoreType = VALUE(Enum.CertificatesStorageType.PersonalCertificates)";
		
		Query 	= New Query(QueryText);
		Query.SetParameter("Id", CryptographyServiceInternal.Id(Certificate));
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			Result = Selection.Thumbprint;
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion
