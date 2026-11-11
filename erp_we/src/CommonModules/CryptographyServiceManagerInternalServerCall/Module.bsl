////////////////////////////////////////////////////////////////////////////////
// Subsystem "Cryptography service Manager".
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// (See CryptographyServiceManager.CreateContainerAndRequestCertificate)
// 
// Parameters: 
//  ApplicationID - String - ID of the certificate request search.
//  RequestContent - String - contains the OID fields.
//  PhoneNumber - String - contains the ID of the confirmed phone number
//  Email - String - contains the ID of the verified mail
//  SubscriberID - String -subscriber ID
//  NotaryLawyerHeadOfFarm - Boolean -The notary public is the lawyer to the head of farm
// 
// Returns: 
//  Structure:
// * BriefErrorDescription - String
// * AdditionalResultAddress - String
// * ResultAddress - String
// * JobID - Undefined
// * Status - String
// (See TimeConsumingOperations.ExecuteInBackground)
Function CreateContainerAndRequestCertificate(ApplicationID,
										RequestContent,
										PhoneNumber,
										Email,
										SubscriberID = Undefined,
										NotaryLawyerHeadOfFarm = False) Export
	
	ProcedureParameters 	= New Structure;
	ProcedureParameters.Insert("ApplicationID", 	ApplicationID);
	ProcedureParameters.Insert("RequestContent", 		RequestContent);
	ProcedureParameters.Insert("PhoneNumber", 			PhoneNumber);
	ProcedureParameters.Insert("Email", 		Email);
	ProcedureParameters.Insert("SubscriberID", 	SubscriberID);
	ProcedureParameters.Insert("NotaryLawyerHeadOfFarm", 	NotaryLawyerHeadOfFarm);
		
	Return CryptographyServiceInternal.ExecuteInBackground("CryptographyServiceManager.CreateContainerAndRequestCertificate", 
						ProcedureParameters);
	
EndFunction	

// (See CryptographyServiceManager.BindCertToContainerAndSystemStore)
// 
// Parameters: 
//  ApplicationID - String - ID of the certificate request search
//  CertificateData - BinaryData - contains the certificate data in PEM encoding.
// 
// Returns: 
//  Structure - Install The Certificate In The Container And Storage:
// * ResultAddress - String -
// * JobID - Undefined -
// * Status - String -
// (See TimeConsumingOperations.ExecuteFunction)
Function BindCertToContainerAndSystemStore(ApplicationID, CertificateData) Export
	
	ProcedureParameters 	= New Structure;
	ProcedureParameters.Insert("ApplicationID",	ApplicationID);
	ProcedureParameters.Insert("CertificateData", 		CertificateData);
		
	Return CryptographyServiceInternal.ExecuteInBackground("CryptographyServiceManager.BindCertToContainerAndSystemStore", 
					ProcedureParameters);
	
EndFunction

#EndRegion
