////////////////////////////////////////////////////////////////////////////////
// The "Cryptography Service" subsystem.
//  
////////////////////////////////////////////////////////////////////////////////
// @strict-types

#Region Public

// Encrypts data for the specified list of recipients.
//
// Parameters:
//   CallbackOnCompletion - CallbackDescription - description of the procedure receiving the result:
//    * Result - Structure - the result of the procedure:
//       ** Completed2           - Boolean - if True, then the procedure is successfully completed and the result is obtained, otherwise see Information about the error.
//       ** ErrorInfo  - ErrorInfo - description of the execution error.
//       ** EncryptedData - BinaryData, String, Array - one or more files.
//                                                                If the data is passed through temporary storage,
//                                                                the result will be returned as well.
//  
//   Data - BinaryData, String, Array - one or more files that need to be encrypted.
//                                             Binary data or address in temporary storage of the data file
//                                     		   to be encrypted.
//
//   Recipients - BinaryData, Structure, FixedStructure, Array, FixedArray - certificates of recipients of the encrypted message.
//                Either binary Data of certificate files or a Structure with parameters for searching certificates in the store.
//     Structure - key parameters of the certificate that is used for the search.
//                 A fingerprint or a pair of serial Number and Publisher, or a Certificate with binary data.
//       * Fingerprint-binary Data, String-certificate fingerprint.
//       * Serial number - Binary data, String - serial number of the certificate.
//       * Publisher - Structure, Fixed structure, String - publisher properties.
//       * Certificate - Binary data - certificate file.
//
//   EncryptionType - String - encryption type. Only CMS is supported.
//
//   EncryptionParameters - Structure, FixedStructure - allows you to specify additional encryption parameters.
//
Procedure Encrypt(CallbackOnCompletion, Data, Recipients, EncryptionType = "CMS", EncryptionParameters = Undefined) Export
	
	CryptographyServiceInternalClient.Encrypt(CallbackOnCompletion, Data, Recipients, EncryptionType, EncryptionParameters);
	
EndProcedure

// Encrypts the data block for the recipient.
//
// Parameters:
//   CallbackOnCompletion - CallbackDescription - description of the procedure receiving the result:
//    * Result - Structure - the result of the procedure:
//       ** Completed2           - Boolean - if True, the procedure is successfully completed and the result is obtained, see the error information.
//       ** ErrorInfo  - ErrorInfo - description of the execution error.
//       ** EncryptedData - BinaryData, String, Array - one or more files.
//                                                                If the data is passed through temporary storage,
//                                                                the result will be returned as well.
//  
//   Data - BinaryData, String - Binary data or address in temporary storage of the data file
//                                     		   to be encrypted.
//
//   Recipient - BinaryData, Structure, FixedStructure  - certificate of the recipient of the encrypted message.
//                Either binary Data of certificate files or a Structure with parameters for searching certificates in the store.
//     Structure - key parameters of the certificate that is used for the search.
//                 A fingerprint or a pair of serial Number and Publisher, or a Certificate with binary data.
//       * Fingerprint-binary Data, String-certificate fingerprint.
//       * Serial number - Binary data, String - serial number of the certificate.
//       * Publisher - Structure, Fixed structure, String - publisher properties.
//       * Certificate - Binary data - certificate file.
//
Procedure EncryptBlock(CallbackOnCompletion, Data, Recipient) Export
	
	CryptographyServiceInternalClient.EncryptBlock(CallbackOnCompletion, Data, Recipient);
	
EndProcedure

// Performs the decryption of the data.
//
// Parameters:
//   CallbackOnCompletion - CallbackDescription - description of the procedure receiving the result:
//    * Result - Structure - the result of the procedure:
//       ** Completed2            - Boolean - if True, then the procedure is successfully completed and the result is obtained, otherwise see Information about the error.
//       ** ErrorInfo   - ErrorInfo - description of the execution error.
//       ** DecryptedData - BinaryData, String - if data is passed through temporary storage,
//                                                        the result will be returned as well.
//       * Recipients           - FixedArray - certificates that data is encrypted for.
//
//   EncryptedData - BinaryData, String - binary data or address in temporary storage of the data file
//                                                  to be decrypted.
//
//   EncryptionType - String - only CMS is supported.
//
//   EncryptionParameters - Structure, FixedStructure - allows you to specify additional encryption parameters.
//
Procedure Decrypt(CallbackOnCompletion, EncryptedData, EncryptionType = "CMS", EncryptionParameters = Undefined) Export
	
	CryptographyServiceInternalClient.Decrypt(CallbackOnCompletion, EncryptedData, EncryptionType, EncryptionParameters);
	
EndProcedure

// Performs decryption of a data block.
//
// Parameters:
//   CallbackOnCompletion - CallbackDescription - description of the procedure receiving the result:
//    * Result - Structure - the result of the procedure:
//       ** Completed2            - Boolean - if True, then the procedure is successfully completed and the result is obtained, otherwise see Information about the error.
//       ** ErrorInfo   - ErrorInfo - description of the execution error.
//       ** DecryptedData - BinaryData, String - if data is passed through temporary storage,
//                                                        the result will be returned as well.
//       ** Recipients           - FixedArray - certificates that data is encrypted for.
//
//   EncryptedData - BinaryData, String - binary data or address in temporary storage of the data file
//                                                  to be decrypted.
//
//   Recipient - BinaryData - data from the encrypted message recipient's certificate files.
//				- Structure, FixedStructure - parameters for searching for certificates in the repository.
//
//   KeyInformation - Structure, FixedStructure - allows you to send data about encryption keys to the request:
//       * ephemeral_key - BinaryData, String - in base64, an ephemeral key
//       * session_key - BinaryData, String - in base64, the session key
//       * iv_data - BinaryData, String - in base64, initialization vector data
//
//   EncryptionParameters - Structure, FixedStructure - allows you to specify additional encryption parameters:
//       * ClearPaddingBytes - Boolean - a flag that determines whether the fill bytes will be deleted. By default, they are deleted.
//
Procedure DecryptBlock(CallbackOnCompletion, EncryptedData, Recipient, KeyInformation, EncryptionParameters = Undefined) Export
	
	CryptographyServiceInternalClient.DecryptBlock(CallbackOnCompletion, EncryptedData, Recipient, KeyInformation, EncryptionParameters);
	
EndProcedure

// Performs data signing.
//
// Parameters:
//   CallbackOnCompletion - CallbackDescription - description of the procedure receiving the result:
//    * Result - Structure - the result of the procedure:
//       ** Completed2      - Boolean - if True, then the procedure is successfully completed and the result is obtained, otherwise see Information about the error.
//       ** ErrorInfo - ErrorInfo - description of the execution error.
//       ** Signature        - BinaryData, String , Array of BinaryData - 
//       				   - Array of String - one or more files.
//                           If the data is transferred via temporary storage, then the result will be returned as well.
//
//   Data - BinaryData, String, Array - one or more files to sign. 
//                                             Binary data or address in temporary storage of the data file
//                                             to be signed.
//
//   Signatory - BinaryData - the certificate file to sign.
//             - Structure, FixedStructure - parameters for searching for certificates in the repository:
//       		  * Thumbprint     - BinaryData, String - the thumbprint of the certificate, or
//       		  * SerialNumber - BinaryData, String - serial number of the certificate.
//       		  * Issuer      - Structure, FixedStructure, String - properties of the publisher, or
//       		  * Certificate    - BinaryData - certificate file.
//
//   SignatureType - String - the type of the signature. Only CMS or GOST3410 are supported.
//
//   SigningParameters - Structure, FixedStructure - allows you to specify additional signing parameters:
//     * DisconnectedSignature - Boolean - only CMS is supported. if True, a detached signature will be generated, otherwise it will be attached.
//                                       True is the default value.
//
Procedure Sign(CallbackOnCompletion, Data, Signatory, SignatureType = "CMS", SigningParameters = Undefined) Export
	
	CryptographyServiceInternalClient.Sign(CallbackOnCompletion, Data, Signatory, SignatureType, SigningParameters);
	
EndProcedure

// Performs signature verification.
//
// Parameters:
//   CallbackOnCompletion - CallbackDescription - description of the procedure receiving the result:
//    * Result - Structure - the result of the procedure:
//       ** Completed2 - Boolean - if True, then the procedure is successfully completed and the result is obtained, otherwise see Information about the error.
//       ** ErrorInfo - ErrorInfo - description of the execution error.
//       ** SignatureIsValid - Boolean - True - the result of the signature verification.
//
//   Signature - BinaryData - the signature that you want to test.
//
//   Data - BinaryData - source data required for signature verification. Used for checking the disconnected Signature.
//
//   SignatureType - String - the type of the signature. Only "CMS" or "GOST3410"are supported.
//
//   SigningParameters - Structure, FixedStructure - allows you to specify additional signing parameters.
//     * Detached signature - Boolean - used in conjunction with the signature type = "CMS", if True, the signature will be verified using the data.
//                                       True is the default value.
//     * Certificate - Binary data - certificate file, must be used in conjunction with the signature type = "GOST3410".
//
Procedure VerifySignature(CallbackOnCompletion, Signature, Data = Undefined, SignatureType = "CMS", SigningParameters = Undefined) Export
	
	CryptographyServiceInternalClient.VerifySignature(CallbackOnCompletion, Signature, Data, SignatureType, SigningParameters);
	
EndProcedure

// Performs certificate verification.
//
// Parameters:
//   CallbackOnCompletion - CallbackDescription - description of the procedure receiving the result:
//    * Result - Structure - the result of the procedure:
//       ** Completed2 - Boolean - if True, then the procedure is successfully completed and the result is obtained, otherwise see Information about the error.
//       ** ErrorInfo - ErrorInfo - description of the execution error.
//       ** Valid1 - Boolean - the certificate meets the verification requirements.
//  
//   Certificate - BinaryData - certificate file.
//
Procedure CheckCertificate(CallbackOnCompletion, Certificate) Export
	
	CryptographyServiceInternalClient.CheckCertificate(CallbackOnCompletion, Certificate);
	
EndProcedure

// Checks the certificate with additional parameters.
//
// Parameters:
//   CallbackOnCompletion - CallbackDescription - description of the procedure receiving the result:
//    * Result - Structure - the result of the procedure:
//       ** Completed2 - Boolean - if True, then the procedure is successfully completed and the result is obtained, otherwise see Information about the error.
//       ** ErrorInfo - ErrorInfo - description of the execution error.
//       ** Valid1 - Boolean - the certificate meets the verification requirements.
//  
//   Certificate - BinaryData - certificate file.
//
//   CheckParameters 				- Structure, FixedStructure - allows you to specify additional parameters for verifying the certificate.
//     * Certificate Verification mode-String-lists the certificate verification modes separated by commas, 
//									the values of the strings correspond to the enumeration mode of verification of the certificate of Cryptography
//
Procedure VerifyCertificateWithParameters(CallbackOnCompletion, Certificate, CheckParameters) Export
	
	CryptographyServiceInternalClient.VerifyCertificateWithParameters(CallbackOnCompletion, Certificate, CheckParameters);
	
EndProcedure

// Retrieves the basic properties of the passed certificate.
// 
// Parameters:
//   CallbackOnCompletion - CallbackDescription - description of the procedure receiving the result:
//     * Result - Structure - the result of the procedure:
//       ** Completed2 - Boolean - if True, the procedure is successfully completed and the result is obtained. Otherwise , see Information about the error.
//       ** ErrorInfo - ErrorInfo - description of the execution error.
//       ** Certificate - FixedStructure - certificate properties:
//           *** Version - String - the version of the certificate.
//           *** StartDate - Date - certificate start date (UTC).
//           *** EndDate - Date - certificate expiration date (UTC).
//           *** Issuer - FixedStructure - information about the certificate publisher:
//                *** CN - String - commonName; 
//                *** O - String - organizationName; 
//                *** OU - String - organizationUnitName; 
//                *** C - String - countryName; 
//                *** ST - String - stateOrProvinceName; 
//                *** L - String - localityName; 
//                *** E - String - emailAddress; 
//                *** SN - String - surname; 
//                *** GN - String - givenName; 
//                *** T - String - title;
//                *** STREET - String - streetAddress;
//                *** OGRN - String - Bin;
//                *** OGRNIP - String - OGRNIP;
//                *** INN - String - INN (optional);
//                *** INNLE - String - TIN YUL (optional);
//                *** SNILS - String - SNILS;
//                   ...
//           ** UseToSign - Boolean - specifies whether this certificate can be used for signing.
//           ** UseToEncrypt - Boolean - specifies whether this certificate can be used for encryption.
//           ** PublicKey - BinaryData - contains public key data.
//           ** Thumbprint - BinaryData - contains the data of the print. It is calculated dynamically using the SHA-1 algorithm.
//           ** Extensions - FixedStructure -  Extended Certificate Properties:
//                *** EKU - FixedArray - Enhanced Key Usage.
//           ** SerialNumber - BinaryData - serial number of the certificate.
//           ** Subject - FixedStructure - information about the subject of the certificate. Composition see Publisher.
//           ** Certificate - BinaryData - certificate file in DER encoding.
//           ** Id - String - calculated by the key properties of the Publisher and the serial number using the SHA1 algorithm.
//                                  Used to identify the certificate in the cryptography service.
//
//   Certificate - BinaryData - the certificate whose properties you want to get.
//
Procedure GetCertificateProperties(CallbackOnCompletion, Certificate) Export
	
	CryptographyServiceInternalClient.GetCertificateProperties(CallbackOnCompletion, Certificate);
	
EndProcedure

// Retrieves an array of certificates from the signature data.
//
// Parameters:
//   CallbackOnCompletion - CallbackDescription - description of the procedure receiving the result:
//     * Result - Structure - the result of the procedure:
//       ** Completed2 - Boolean - if True, then the procedure is successfully completed and the result is obtained, otherwise see Information about the error.
//       ** ErrorInfo - ErrorInfo - description of the execution error.
//       ** Certificates - Array of BinaryData - the contents of the certificates
//  
//   Signature - BinaryData - signature file.
//           - String - the address in the temporary storage.
//
Procedure GetCertificatesFromSignature(CallbackOnCompletion, Signature) Export
	
	CryptographyServiceInternalClient.GetCertificatesFromSignature(CallbackOnCompletion, Signature);
	
EndProcedure

// Calculates the hash amount based on the transmitted data.
//
// Parameters:
//   CallbackOnCompletion - CallbackDescription - description of the procedure receiving the result:
//     * Result - Structure - the result of the procedure:
//       ** Completed2      - Boolean - if True, then the procedure is successfully completed and the result is obtained, otherwise see Information about the error.
//       ** ErrorInfo - ErrorInfo - description of the execution error.
//       ** Hash  - BinaryData - value of the hash sum.
//
//   Data - BinaryData, String - binary data or an address in the temporary storage of the data file
//                                     from which the hash sum must be calculated.
//   HashAlgorithm - String - constant from the list "GOST R 34.11-94", "GOST R 34.11-2012 256","GOST R 34.11-2012 512".
//
//   HashingParameters - Structure, FixedStructure - allows you to specify additional hashing parameters:
//     * InvertNibbles - Boolean - controls the inversion of the half-byte value of the hash sum. Applies only to " GOST R 34.11-94"
//                                For example, the forward order is 62 FB, the reverse order is 26 BF.
//                                True is the default value.
//
Procedure DataHashing(CallbackOnCompletion, Data, HashAlgorithm = "GOST R 34.11-94", HashingParameters = Undefined) Export

	CryptographyServiceInternalClient.DataHashing(CallbackOnCompletion, Data, HashAlgorithm, HashingParameters);
	
EndProcedure

#EndRegion
