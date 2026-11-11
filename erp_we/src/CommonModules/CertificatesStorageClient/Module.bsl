////////////////////////////////////////////////////////////////////////////////
// The subsystem "Certificate Store".
//  
////////////////////////////////////////////////////////////////////////////////
//


#Region Public

// Adds the certificate to the certificate store.
// 
// Parameters:
//   CallbackOnCompletion - CallbackDescription - description of the procedure receiving the result.
//     Result - Structure - the result of the procedure.
//       * Executed - Boolean - if True, the procedure is successfully completed and the result is obtained, otherwise see Description of the error.
//       * Error descriptionline - String - description of the execution error.
//
//   Certificate - BinaryData - certificate file.
//                String - address of the certificate file in temporary storage.
//   StoreType - String, EnumRef.CertificatesStorageType - type of storage to add the certificate to.
//
Procedure Add(CallbackOnCompletion, Certificate, StoreType) Export
	
	CertificatesStorageInternalClient.Add(CallbackOnCompletion, Certificate, StoreType);
	
EndProcedure

// Retrieves certificates from the storage.
// 
// Parameters:
//   CallbackOnCompletion - CallbackDescription - description of the procedure receiving the result.
//     Result - Structure - the result of the procedure.
//       * Executed - Boolean - if True, the procedure is successfully completed and the result is obtained, otherwise see Description of the error.
//       * Error descriptionline - String - description of the execution error.
//       * Certificates - Array - an array of fixed structure objects with certificate properties.
//           ** Version - String - Certificate version.
//           ** Datanachala - Date - the date of the certificate's validity.
//           ** End Date - Date - date of expiration of the certificate.
//           ** Publisher - Fixed Structure - information about the certificate publisher:
//                *** CN - commonName; 
//                *** O - organizationName; 
//                *** OU - organizationUnitName; 
//                *** C - countryName; 
//                *** ST - stateOrProvinceName; 
//                *** L - localityName; 
//                *** E - emailAddress; 
//                *** SN - surname; 
//                *** GN - givenName; 
//                *** T - title;
//                *** STREET - streetAddress;
//                *** OGRN - OGRN;
//                *** OGRNIP - OGRNIP;
//                *** INN - String - INN (optional);
//                *** INNLE - String - INN YUL (optional);
//                *** SNILS - SNILS;
//                   ...
//           ** Use for signatures - Boolean - indicates whether this certificate can be used for signing.
//           ** Use for Encryption - Boolean - indicates whether this certificate can be used for encryption.
//           ** Fingerprint - Binary Data - contains fingerprint data. It is calculated dynamically, according to the SHA-1 algorithm.
//           ** Extended Properties - Fixed Structure - Extended certificate properties:
//                *** EKU - Fixed array of String - Enhanced Key Usage.
//           ** Serial Number - Binary data - serial number of the certificate.
//           ** Subject - Fixed structure - information about the subject of the certificate. Composition see Publisher.
//           ** Certificate - Binary data - certificate file in DER encoding.
//           ** Identifier - String - is calculated by the key properties of the Publisher and the serial number according to the SHA1 algorithm.
//                                  Used to identify the certificate in the cryptography service.
//
//   StoreType - String, EnumRef.CertificatesStorageType - type of storage to get
//                                                                certificates from.
//                                                                If not filled in, all certificates will be received.
//
Procedure Get(CallbackOnCompletion, StoreType = Undefined) Export
	
	CertificatesStorageInternalClient.Get(CallbackOnCompletion, StoreType);
	
EndProcedure

// Searches for the certificate in the storage.
//
// Parameters:
//   CallbackOnCompletion - CallbackDescription - description of the procedure receiving the result.
//     Result - Structure - the result of the procedure.
//       * Executed - Boolean - if True, the procedure is successfully completed and the result is obtained, otherwise see Description of the error.
//       * Error descriptionline - String - description of the execution error.
//       * Certificate - Fixed structure, Undefined - properties of the found certificate.
// 
//   Certificate - Structure - the key parameters of the certificate used for the search.
//                            An imprint or pair of SerialNumber and Publisher.
//     * Fingerprint-binary Data-fingerprint certificate.
//                   String - string representation of the print.
//     * Serial Number - Binary data - serial number of the certificate.
//                       String - string representation of the serial number.
//     * Publisher - Structure - Publisher properties
//                  String - string representation of the publisher.
//
Procedure FindCertificate(CallbackOnCompletion, Certificate) Export
	
	CertificatesStorageInternalClient.FindCertificate(CallbackOnCompletion, Certificate);
	
EndProcedure

#EndRegion