////////////////////////////////////////////////////////////////////////////////
// Subsystem "Cryptography service Manager".
//
////////////////////////////////////////////////////////////////////////////////
// @strict-types

#Region Public

// Creates a key pair and generates data for the certificate request
//
// Parameters:
//   CallbackOnCompletion - CallbackDescription - description of the procedure receiving the result:
//     * Result - Structure - the result of the procedure:
//       ** Completed2      		- Boolean - if True, the procedure is successfully completed and the result is obtained, 
//       						  otherwise, the details are in the information error.
//       ** ErrorDescription 		- ErrorInfo - description of the execution error, in case of an error, 
//								  the following fields are not generated.
//       ** CertificateRequest1 	- BinaryData - files in the PKCS10 format
//       ** PublicKey 		- BinaryData - key data
//       ** ProviderName 		- String - contains the name of the provider used to generate the key
//       ** ProviderType 		- Number - the type of provider used to generate the key
//   ApplicationID		- String - length-36-usually a unique identifier, used for the subsequent installation of the certificate
//   RequestContent 			- String - description of fields for the certificate request
//   SubscriberID 		- String - length-36-unique identifier
//   NotaryLawyerHeadOfFarm	- Boolean - it is used for building the bin
//
Procedure CreateContainerAndRequestCertificate(CallbackOnCompletion, 
										ApplicationID, 
										RequestContent, 
										SubscriberID = Undefined,
										NotaryLawyerHeadOfFarm = False) Export
	
	CryptographyServiceManagerInternalClient.CreateContainerAndRequestCertificate(
			CallbackOnCompletion,
			ApplicationID,
			RequestContent,
			SubscriberID,
			NotaryLawyerHeadOfFarm);
	
EndProcedure

// Installs the certificate in secure storage
//
// Parameters:
//   CallbackOnCompletion - CallbackDescription - description of the procedure receiving the result:
//     * Result - Structure - the result of the procedure:
//       ** Completed2      	- Boolean - if True, then the procedure is successfully completed and the result is obtained, otherwise see Information about the error.
//       ** ErrorDescription 	- ErrorInfo - description of the execution error, if an error occurs.
//   ApplicationID - String - length-36-usually a unique identifier, used for private key matching.
//   CertificateData 		- BinaryData - in DER or PEM encoding
//
Procedure BindCertToContainerAndSystemStore(CallbackOnCompletion, 
												ApplicationID, 
												CertificateData) Export
	
	CryptographyServiceManagerInternalClient.BindCertToContainerAndSystemStore(
			CallbackOnCompletion,
			ApplicationID,
			CertificateData);
		
EndProcedure

#EndRegion