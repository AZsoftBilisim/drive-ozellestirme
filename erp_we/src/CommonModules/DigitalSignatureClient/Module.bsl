///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns the current setting of digital signature usage.
//
// Returns:
//  Boolean - if True, digital signatures are used.
//
Function UseDigitalSignature() Export
	
	Return CommonSettings().UseDigitalSignature;
	
EndFunction

// Returns the current setting of encryption usage.
//
// Returns:
//  Boolean - if True, encryption is used.
//
Function UseEncryption() Export
	
	Return CommonSettings().UseEncryption;
	
EndFunction

// Returns the current setting of digital signature check on the server.
//
// Returns:
//  Boolean - if True, digital signatures will be checked on the server.
//
Function VerifyDigitalSignaturesOnTheServer() Export
	
	Return CommonSettings().VerifyDigitalSignaturesOnTheServer;
	
EndFunction

// Returns the current setting of digital signature creation on the server.
// The setting also involves encryption and decryption on the server.
//
// Returns:
//  Boolean - if True, digital signatures will be created on the server.
//
Function GenerateDigitalSignaturesAtServer() Export
	
	Return CommonSettings().GenerateDigitalSignaturesAtServer;
	
EndFunction

// Signs data, returns a signature, and adds the signature to an object, if specified.
//
// A common method to process property values with the NotifyDescription type in the DataDetails parameter.
//  When processing a notification, the parameter structure is passed to it.
//  This structure always has a Notification property of the NotifyDescription type, which needs to be processed to continue.
//  In addition, the structure always has the DataDetails property received when calling the procedure.
//  When calling a notification, the structure must be passed as a value. If an error occurs during the asynchronous
//  execution, add the ErrorDetails property of String type to this structure.
// 
// Parameters:
//  DataDetails - Structure:
//    * Operation             - String - header of the data signing form, such as file Signing.
//    * DataTitle      - String - title of an element or data set, such as a File.
//    * NotifyOnCompletion  - Boolean - (optional) - if False, it will not be shown the notification about successful
//                           the completion of the operation to present information that is specified next to the title.
//    * ShowComment  - Boolean - (optional) - allows entering a comment in
//                           the data signing form. If omitted, it means False.
//    * CertificatesFilter    - Array - (optional) - contains links to directory elements.
//                           Electronic signature decryption certificates that can be selected
//                           by the user. Selection blocks the ability to select other certificates
//                           from the personal storage.
//                           - Structure:
//                             * Organization - DefinedType.Organization - contains a link to the organization
//                                 for which the selection will be set in the list of user certificates 
//                                 and in the list of signatories.
//    * AuthorityLettersFilter   - Structure - (optional) - selection parameters for searching for a suitable power of attorney
//                             * Organization - String - (optional) - TIN for selecting the principal in the list of powers of attorney.
//                                           - DefinedType.Organization - contains a link to the principal's organization,
//                                              the TIN of which will be selected in the list of powers of attorney.
//                             * Powers - Array of String - (optional) - authorization codes for searching
//                                                               for a suitable power of attorney.
//                             * SelectionKey - String - (optional) - to save the selected power of attorney for
//                                 the certificate in the user settings and automatic substitution during subsequent 
//                                 signing in this scenario. For example, "For a Photo frame". It is recommended to use
//                                 it if the authorization codes for selection are not filled in.
//    * Signatory            - Structure - (optional) - parameters of the subscriber of the mobile service,
//                           See SignatoryParameters
//                           will be added to the Catalog of subscribers in case of successful sending.
//    * NoConfirmation     - Boolean - (optional) - skip user confirmation if
//                           there is only one certificate in the Certificate selection property and:
//                           a) or "Enter password in the electronic signature program" is specified for the certificate;
//                           b) either the user has memorized the password to the certificate for the duration of the session;
//                           c) either the password was set earlier by the installpassertificate method.
//                           If an error occurred during the signing process, then a form will be opened
//                           with the option to specify a password. The Show Comment parameter is ignored.
//    * BeforeExecute     - CallbackDescription - (optional) - description of the handler for additional
//                           data preparation after selecting the certificate with which the data will be signed.
//                           In this handler, you can fill in the Data parameter if it depends
//                           on the certificate/signer that was already inserted
//                           as the selected certificate in the data description at the time of the call/The selected subscriber (see below).
//                           You can also override the Selected Trust parameter in the data descriptionEdit.
//                           The general approach should be taken into account (see above).
//    * ExecuteAtServer   - Undefined
//                           - Boolean - (optional) - when not specified or Undefined,
//                           then execution will be determined automatically: if there is a server, then first
//                           on the server, then (if unsuccessful) on the client, then a message about two errors.
//                           When True: if execution on the server is allowed, then execution
//                           only on the server, if it fails, one error message on the server.
//                           When False: execution only on the client, as if there is no server.
//    * AdditionalActionParameters - Arbitrary - (optional) - if specified, it is passed
//                           to the server in the procedure for pre-Moderation of the shared module
//                           The electronic signature is defined as input Parameters.
//    * OperationContext     - Undefined - (optional) - if specified, then
//                           a certain value of an arbitrary type will be set to the property, which allows
//                           you to perform an action with the same certificate again (the user 
//                           is not asked for either a password or confirmation of the action).
//                           In case of an error after calling the procedure, the repeated action performed
//                           with the received context may also be erroneous.
//                           - Arbitrary - (optional) - if defined, the action will be performed
//                           with the same certificate without requesting a password or confirmation.
//                           The parameter without confirmation is considered to be True.
//                           The parameters Operation, Data headers, Show Comments, select
//                           Certificates and Execute Server are ignored, their values remain the same as when the first call was made.
//                           The Optional Action parameter is ignored.
//                           The procedure before the start of the operation is not called.
//                           If you pass the context returned by the Decrypt procedure, then
//                           the password entered for the certificate can be used as if
//                           the password was saved for the duration of the session. Otherwise, the context is ignored.
//    * StopExecution - Arbitrary - if the property exists and an error occurs during asynchronous execution
//                           , execution stops without displaying the operation form or closing this form
//                           if it was open.
//
//    Option 1.
//    * Data              - BinaryData - data for signing.
//                          - String - the address of the temporary storage containing binary data.
//                          The following options are not available for sending to the mobile signature service:
//                          - CallbackDescription - a data acquisition handler that returns
//                          them in the Data property (see the general approach above). At the time of the call
//                          , the Selected Certificate parameter has already been inserted in the data description (see below).
//                          - Structure:
//                             * XMLEnvelope       - See DigitalSignatureClient.XMLEnvelope
//                             * XMLDSigParameters - See DigitalSignatureClient.XMLDSigParameters
//                          - Structure:
//                             * CMSParameters - See DigitalSignatureClient.CMSParameters
//                             * Data  - String - custom string for signing,
//                                       - BinaryData - binary data for signing.
//    * Object              - AnyRef - (optional) - a reference to the object to add the signature to.
//                          If omitted, the signature does not need to be added.
//                          - CallbackDescription - (optional) - handler for adding a signature to
//                          the Electronic signature information register. The general approach should be taken into account (see above).
//                          At the time of the call, the Signature property parameter has already been inserted in the data description.
//                          In the case of the Data parameter, the Current
//                          Data Element property is inserted into the data description, containing the Signature property parameter.
//    * ObjectVersion       - String - (optional) - the version of the object data to check and
//                          lock the object before adding a signature.
//    * Presentation       - AnyRef - (optional), if the parameter is not specified,
//                                  then the representation is calculated by the value of the Object property.
//                          - String
//                          - Structure:
//                             ** Value      - AnyRef
//                                              - CallbackDescription - for the opening.
//                             ** Presentation - String - representation of the value.
//                             ** FileName      - String - (optional) file name, displayed in the mobile application,
//                              fill in if it differs from the presentation.
//                              If the parameters of the signature.Allow to send a .caption = True, representation or file name 
//                              is mandatory and must contain a file name no longer than 250 characters. Characters
//                              that do not match the regular expression [^.()w,s-] will be replaced by "_", character #
//                              by N.
//    Option 2.
//    * DataSet         - Array - structures with the properties described in Option 1.
//    * SetPresentation - String - representations of multiple data set elements, such as " Files (%1)".
//                          In this view, the %1 parameter is filled with the number of elements.
//                          You can use the hyperlink to open the list.
//                          If the dataset 1 element, then use the value
//                          in the property View properties Nabetani, if not specified, then
//                          performance is calculated on the value of the item Object of the data set.
//    * PresentationsList - ValueList
//                          - Array - (optional) - an arbitrary list of elements
//                          or an array with values like the View property that
//                          the user can open. If not specified, it is filled in from
//                          the View or Object properties in the Data type property.
//                          If the parameters of the signature.To allow the correction, the signature = True, the representation of the value or
//                          file name is mandatory and must contain a file name no longer than 250 characters and no duplicates
//                          in the dataset. Characters that do not match the regular expression [^.()w,s-] will
//                          be replaced by "_", character # by N.
//
//  Form - ClientApplicationForm - a form, from which you need to get an UUID
//                                that will be used when locking an object.
//        - UUID - a UUID that will be used
//                                to lock an object.
//        - Undefined     - use a standard form.
//
//  ResultProcessing - CallbackDescription -
//     Required for non-standard result processing, for example, if the Object or Form parameter is not specified.
//     The result gets the DataDetails parameter, to which the following properties are added in case of success::
//     # Success - Boolean - True if everything is successfully completed.
//               If Success = False, the partial completion is defined by having the SignatureProperties property.
//     # Cancel - Boolean - True if the user canceled the operation interactively.
//     # UserClickedSign - Boolean - If True, the user has clicked Sign at least once.
//               Used for scenarios where a simple signature is enough to continue the business process (the intention to set a signature),
//               and setting a qualified signature is an addition that can be implemented later if technical problems arise.
//               # ShouldSignInThisApp - Boolean - "True" if a certificate is selected.
//     "False" if signing in cloud service is selected.
//               # SelectedCertificate - Structure - Contains the following certificate properties:
//     ## CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - Reference to the found certificate.
//         ## Thumbprint - String - Certificate thumbprint in the Base64 string format.
//         ## String - Address of temporary storage that contains certificate binary data.
//         # SelectedSigner -
//     - If signing in cloud service is selected. See SignatoryParameters
//     # SelectedLetterOfAuthority - AnyRef
//     # SignatureProperties = String - Address in a temporary storage that contains the structure described below
//               if it was signed on the server side.
//                       Check the property in the DataSet parameter when passing it.
//     = Structure:
//                        * Signature - BinaryData
//                        * SignatureType  - EnumRef.CryptographySignatureTypes
//                        * DateActionLastTimestamp - Date, Undefined - Filled only using
//                                                                                   the cryptographic manager.
//                        * DateSignedFromLabels - Date, Undefined - Date of the earliest timestamp.
//                        * UnverifiedSignatureDate - Date - Unconfirmed signature data.
//                        * Certificate  - BinaryData - Certificate used for signature validation.
//                        * Thumbprint           - String - Certificate thumbprint in the Base64 string format.
//                        * CertificateOwner - String - Object presentation obtained from the certificate binary data. 
//         In the "DataSet" parameter is passed, the property is checked in it.
//                       
//  SignatureParameters - See NewSignatureType
//
Procedure Sign(DataDetails, Form = Undefined, ResultProcessing = Undefined, SignatureParameters = Undefined) Export
	
	ClientParameters = New Structure;
	ClientParameters.Insert("DataDetails", DataDetails);
	ClientParameters.Insert("Form", Form);
	ClientParameters.Insert("ResultProcessing", ResultProcessing);
	
	CompletionProcessing = New CallbackDescription("RegularlyCompletion",
		DigitalSignatureInternalClient, ClientParameters);
	
	If DataDetails.Property("OperationContext")
	   And TypeOf(DataDetails.OperationContext) = Type("ClientApplicationForm") Then
		
		DigitalSignatureInternalClient.ExtendStoringOperationContext(DataDetails);
		FormNameBeginning = "Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.";
		
		If DataDetails.OperationContext.FormName = FormNameBeginning + "DataSigning" Then
			DataDetails.OperationContext.PerformSigning(ClientParameters, CompletionProcessing);
			Return;
		EndIf;
		If DataDetails.OperationContext.FormName = FormNameBeginning + "DataDecryption" Then
			ClientParameters.Insert("SpecifiedContextOfOtherOperation");
		EndIf;
	EndIf;
	
	ServerParameters1 = New Structure;
	ServerParameters1.Insert("Operation",            NStr("vi = 'Ký dữ liệu';
															|ru = 'Подписание данных';
															|en = 'Data signing'; fa = 'امضای داده‌ها';
															|it = 'Firma dati';
															|pl = 'Podpisanie danych';
															|tr = 'Verilerin imzalanması'"));
	ServerParameters1.Insert("DataTitle",     NStr("vi = 'Dữ liệu';
													|ru = 'Данные';
													|en = 'Data'; fa = 'داده';
													|it = 'Dati';
													|pl = 'Data';
													|tr = 'Veriler'"));
	ServerParameters1.Insert("ShowComment", False);
	ServerParameters1.Insert("CertificatesFilter");
	ServerParameters1.Insert("AuthorityLettersFilter");
	ServerParameters1.Insert("Signatory");
	ServerParameters1.Insert("ExecuteAtServer");
	ServerParameters1.Insert("AdditionalActionParameters");
	ServerParameters1.Insert("NotifyOfCertificateAboutToExpire", True);
	FillPropertyValues(ServerParameters1, DataDetails);
	
	ServerParameters1.Insert("SignatureType", SignatureParameters);
	
	DigitalSignatureInternalClient.OpenNewForm("DataSigning",
		ClientParameters, ServerParameters1, CompletionProcessing);
	
EndProcedure

// Construction of the SignatureType parameter. Used in the "Sign" procedure.
// It is ignored when signing XML envelopes.
// 
// Parameters:
//  SignatureType - EnumRef.CryptographySignatureTypes
// 
// Returns:
//  Structure:
//   * SignatureTypes - Array - Array of signature types to choose from.
//   * Visible - Boolean - Signature type visibility on the signing form.
//   * Enabled - Boolean - Signature type availability on the signing form.
//   * CanSelectLetterOfAuthority - Boolean - Flag indicating whether to show the LoA selection field.
//   * AllowSendingForSigning - Allow sending data for signing to the mobile signing service.
//   * Sender - Undefined - See DigitalSignatureClientLocalization.OnDefineParametersOfDocumentsForSignatureSender
//   * BatchSendingForSigning - Undefined, Boolean - If Undefined, the form will prompt for options.
//   * VerifyCertificate - String - The signature verification options:
//       "VerifyQualified" - (Default) Allow signing with NES and validate QES against the list of trusted non-accredited CAs. 
//                                      "QualifiedOnly" - Allow signing with QES only and ignore the list of trusted non-accredited CAs.
//       "DoNotVerifyCertificate" - Skip certificate verification.
//                                   
//       
//
Function NewSignatureType(SignatureType = Undefined) Export
	
	Structure = New Structure;
	Structure.Insert("SignatureTypes", New Array);
	Structure.Insert("Visible", False);
	Structure.Insert("Enabled", False);
	Structure.Insert("CanSelectLetterOfAuthority", False);
	Structure.Insert("AllowSendingForSigning", False);
	Structure.Insert("BatchSendingForSigning", Undefined);
	Structure.Insert("Sender", Undefined);
	Structure.Insert("VerifyCertificate", DigitalSignatureInternalClientServer.VerifyQualified());
	
	If ValueIsFilled(SignatureType) Then
		Structure.SignatureTypes.Add(SignatureType);
	EndIf;
	
	Return Structure;
	
EndFunction

// Parameter constructor for adding signers.
// 
// Returns:
//  Structure
//
Function SignatoryParameters() Export
	
	SignatoryParameters = New Structure;
	DigitalSignatureClientLocalization.OnRetrieveSignatoryParameters(SignatoryParameters);
	Return SignatoryParameters;
	
EndFunction

// Sends data for signing to the mobile service, returns the signature ID, which can be used
// to retrieve the result. 
// 
//
// A common method to process property values with the NotifyDescription type in the DataDetails parameter.
//  When processing a notification, the parameter structure is passed to it.
//  This structure always has a Notification property of the NotifyDescription type, which needs to be processed to continue.
//  In addition, the structure always has the DataDetails property received when calling the procedure.
//  When calling a notification, the structure must be passed as a value. If an error occurs during the asynchronous
//  execution, add the ErrorDetails property of String type to this structure.
// 
// Parameters:
//  DataDetails - Structure:
//    * Operation             - String - header of the data signing form, such as file Signing.
//    * DataTitle      - String - the header of the dataset, for example a File.
//    * Signatory            - See SignatoryParameters
//                           - AnyRef - link to the Catalog of signatories.
//    * SignatoriesFilter - Structure:
//                                    * Key - String - The name of the selection field in the list of signatories: "Organization", "TIN".
//                                    * Value - AnyRef, String - the value of the selection.
//    * AuthorityLettersFilter   - Structure - (optional) - selection parameters for searching for a suitable power of attorney
//                             * Organization - String - (optional) - TIN for selecting the principal in the list of powers of attorney.
//                                           - DefinedType.Organization - contains a link to the principal's organization,
//                                              the TIN of which will be selected in the list of powers of attorney.
//                             * Powers - Array of String - (optional) - authorization codes for searching
//                                                               for a suitable power of attorney.
//                             * SelectionKey - String - (optional) - to save the selected power of attorney for
//                                 the certificate in the user settings and automatic substitution during subsequent 
//                                 signing in this scenario. For example, "For a Photo frame". It is recommended to use
//                                 it if the authorization codes for selection are not filled in.
//    * NotifyOnCompletion  - Boolean - (optional) - if False, it will not be shown the notification about successful
//                           the completion of the operation to present information that is specified next to the title.
//    * ShowComment  - Boolean - (optional) - allows entering a comment in
//                           the data signing form. If omitted, it means False.
//    * StopExecution - Arbitrary - if the property exists and an error occurs during asynchronous execution
//                           , execution stops without displaying the of operation form or closing this form
//                           if it was opened.
//    * BatchSending    - Boolean - (optional) send one document at a time or in a package. The default is True.
//    * DataSet         - Array of Structure:
//     ** Data            - BinaryData - data for signing.
//                          - String - the address of the temporary storage containing binary data.
//     ** Object              - AnyRef - (optional) - a reference to the object to add the signature to.
//                          If omitted, the signature does not need to be added.
//     ** ObjectVersion       - String - (optional) - the version of the object data to check and
//                          lock the object before adding a signature.
//     ** Presentation       - Structure:
//                             ** Value      - AnyRef
//                                              - CallbackDescription - for the opening.
//                             ** Presentation - String - Presentation in the form of submission for signing.
//                             ** FileName      - String - (optional) file name, displayed in the mobile application,
//                              fill in if it differs from the Presentation. 
//                              A file name with an extension of no more than 250 characters and no duplicates
//                              in the data set in the case of batch sending. Characters that do not match the regular expression 
//                               [^.()w,s-] will be replaced by "_", character # by N.
//    * SetPresentation - String - representations of multiple data set elements, such as " Files (%1)".
//                          In this view, the %1 parameter is filled with the number of elements.
//                          You can use the hyperlink to open the list.
//                          If the dataset 1 element, then use the value
//                          in the property View properties Nabetani, if not specified, then
//                          performance is calculated on the value of the item Object of the data set.
//    * PresentationsList - Array - an array with values like the Presentation property that
//                          the user can open.
//
//  Form - ClientApplicationForm - a form, from which you need to get an UUID
//                                that will be used when locking an object.
//        - UUID - a UUID that will be used
//                                to lock an object.
//        - Undefined     - use a standard form.
//
//  ResultProcessing - CallbackDescription -
//     Required for non-standard result processing, for example, if the Object or Form parameter is not specified.
//     The result gets the DataDetails parameter, to which the following properties are added in case of success::
//     # Success - Boolean - True if everything is successfully completed.
//               If Success = False, the partial completion is defined by having the DocumentID property.
//     # Cancel - Boolean - True if the user canceled the operation interactively.
//     # UserClickedSign - Boolean - If True, the user has clicked Sign at least once.
//               Used for scenarios where a simple signature is enough to continue the business process (the intention to set a signature),
//               and setting a qualified signature is an addition that can be implemented later if technical problems arise.
//               # SelectedSigner - Structure - Contains the signer properties.
//     # SelectedLetterOfAuthority - AnyRef
//     # DataSet
//     ## DocumentID - UUID - ID assigned to the document.
//      Used for retrieving the signing result.
//      
//                       
//  SignatureParameters - See NewSignatureType
//
Procedure SendForSigning(DataDetails, Form = Undefined, ResultProcessing = Undefined, SignatureParameters = Undefined) Export
	
	FormName = "";
	DigitalSignatureClientLocalization.OnDefineSignatureSubmissionForm(FormName);
	
	If Not ValueIsFilled(FormName) Then
		Raise NStr("vi = 'Không hỗ trợ việc gửi để ký tên trong ứng dụng.';
					|ru = 'Отправка на подписание не поддерживается в приложении.';
					|en = 'The application does not support sending documents for signing.'; fa = 'The application does not support sending documents for signing.';
					|it = 'The application does not support sending documents for signing.';
					|pl = 'The application does not support sending documents for signing.';
					|tr = 'Uygulamada imzalama için gönderim desteklenmemektedir.'");
	EndIf;
	
	ClientParameters = New Structure;
	ClientParameters.Insert("DataDetails", DataDetails);
	ClientParameters.Insert("Form", Form);
	ClientParameters.Insert("ResultProcessing", ResultProcessing);
	
	CompletionProcessing = New CallbackDescription("RegularlyCompletion",
		DigitalSignatureInternalClient, ClientParameters);
	
	ServerParameters1 = New Structure;
	ServerParameters1.Insert("Operation",            NStr("vi = 'Ký dữ liệu';
															|ru = 'Подписание данных';
															|en = 'Data signing'; fa = 'امضای داده‌ها';
															|it = 'Firma dati';
															|pl = 'Podpisanie danych';
															|tr = 'Verilerin imzalanması'"));
	ServerParameters1.Insert("DataTitle",     NStr("vi = 'Dữ liệu';
													|ru = 'Данные';
													|en = 'Data'; fa = 'داده';
													|it = 'Dati';
													|pl = 'Data';
													|tr = 'Veriler'"));
	ServerParameters1.Insert("ShowComment", False);
	ServerParameters1.Insert("Signatory");
	ServerParameters1.Insert("SignatoriesFilter");
	ServerParameters1.Insert("AuthorityLettersFilter");
	
	FillPropertyValues(ServerParameters1, DataDetails);
	
	ServerParameters1.Insert("SignatureParameters", SignatureParameters);
	
	DigitalSignatureInternalClient.OpenNewForm("SendForSigning",
		ClientParameters, ServerParameters1, CompletionProcessing);
		
EndProcedure

// It prompts the user to select signature files to add to the object, and adds them.
//
// A common method to process property values with the NotifyDescription type in the DataDetails parameter.
//  When processing a notification, the parameter structure is passed to it.
//  This structure always has a Notification property of the NotifyDescription type, which needs to be processed to continue.
//  In addition, the structure always has the DataDetails property received when calling the procedure.
//  When calling a notification, the structure must be passed as a value. If an error occurs during the asynchronous
//  execution, add the ErrorDetails property of String type to this structure.
// 
// Parameters:
//  DataDetails - Structure:
//    * DataTitle      - String - a data item title, for example, File.
//    * ShowComment  - Boolean - (optional) - allows adding a comment in the
//                             data signing form. False if not specified.
//    * Object               - AnyRef - (optional) - a reference to an object to be signed.
//                           - CallbackDescription - (optional) - a handler for adding a signature to
//                             the DigitalSignatures information register. Consider the common approach (see above).
//                             DataDetails already has the Signatures parameter at the time it is called.
//    * ObjectVersion        - String - (optional) - an object data version to check and
//                             lock the object before adding the signature.
//    * Presentation        - AnyRef
//                           - String - (optional), if it is not specified,
//                             the presentation is calculated by the Object property value.
//    * Data               - BinaryData - (optional) - data to check the signature.
//                           - String - (optional) - an address of a temporary storage with binary data.
//                           - CallbackDescription - (optional) - a data receipt handler that returns
//                             it in the Data property (see the common approach above).
//
//  Form - ClientApplicationForm - a form, from which you need to get an UUID
//        that will be used when locking an object.
//        - UUID - a UUID that will be used
//        to lock an object.
//        - Undefined - use a standard form.
//
//  ResultProcessing - CallbackDescription -
//     Required for non-standard result processing, for example, if the Object or Form parameter is not specified.
//     Required for non-standard result processing, for example, if the Object or Form parameter is not specified.:
//     # Success - Boolean - True if everything is successfully completed.
//     #Cancel - Boolean - True if the user canceled the operation interactively.
//     # Signatures - Array - Array that contains the following elements:
//       ## SignatureProperties = String - Temporary storage address that contains the structure described below.
//                          = Structure - Detailed signature description:
//           ### Comment - String - Comment if it was entered upon signing.
//           ### SignedBy - CatalogRef.Users - User who
//                                   signed the infobase object.
//           ### Comment - String - Comment if it was entered upon signing.
//           ### SignatureFileName - String - a name of the file from which the signature was added.
//           ### SignatureDate - Date - Signing date.
//                                   Applicable if the date cannot be extracted from signature data.
//                                   If the date is not specified or blank, the current session date is used.
//           ### SignatureCheckDate - Date - Date of signature check after adding from file.
//                                   If the Data property is not specified in the DataDetails parameter,
//                                   it returns a blank date.
//           ### SignatureCorrect - Boolean - Signature check result after adding from file.
//                                    If the Data property is not specified in the DataDetails parameter,
//                                    it returns False.
//
//           Derivative properties:
//           ### Certificate - BinaryData - Contains export of the certificate
//                                   that was used for signing (it is in the signature).
//           ### Thumbprint - String - Certificate thumbprint in the Base64 format.
//           ### CertificateRecipient - String - Subject presentation received from the certificate binary data.
//
Procedure AddSignatureFromFile(DataDetails, Form = Undefined, ResultProcessing = Undefined) Export
	
	DataDetails.Insert("Success", False);
	
	ServerParameters1 = New Structure;
	ServerParameters1.Insert("DataTitle", NStr("vi = 'Dữ liệu';
												|ru = 'Данные';
												|en = 'Data'; fa = 'داده';
												|it = 'Dati';
												|pl = 'Dane';
												|tr = 'Veriler'"));
	ServerParameters1.Insert("ShowComment", False);
	FillPropertyValues(ServerParameters1, DataDetails);
	
	ClientParameters = New Structure;
	ClientParameters.Insert("DataDetails",      DataDetails);
	ClientParameters.Insert("Form",               Form);
	ClientParameters.Insert("ResultProcessing", ResultProcessing);
	DigitalSignatureInternalClient.SetDataPresentation(ClientParameters, ServerParameters1);
	
	AdditionForm = OpenForm("CommonForm.AddDigitalSignatureFromFile", ServerParameters1,,,,,
		New CallbackDescription("RegularlyCompletion", DigitalSignatureInternalClient, ClientParameters));
	
	If AdditionForm = Undefined Then
		If ResultProcessing <> Undefined Then
			RunCallback(ResultProcessing, DataDetails);
		EndIf;
		Return;
	EndIf;
	
	AdditionForm.ClientParameters = ClientParameters;
	
	Context = New Structure;
	Context.Insert("ResultProcessing", ResultProcessing);
	Context.Insert("AdditionForm", AdditionForm);
	Context.Insert("CheckCryptoManagerAtClient", False);
	Context.Insert("DataDetails", DataDetails);
	
	If (VerifyDigitalSignaturesOnTheServer()
		Or GenerateDigitalSignaturesAtServer())
		And Not ValueIsFilled(AdditionForm.CryptographyManagerOnServerErrorDescription) Then
		
		Context.CheckCryptoManagerAtClient = False;
		DigitalSignatureInternalClient.AddSignatureFromFileAfterCreateCryptoManager(
			Undefined, Context);
	Else
		
		CreationParameters = DigitalSignatureInternalClient.CryptoManagerCreationParameters();
		CreationParameters.ShowError = Undefined;
		
		DigitalSignatureInternalClient.CreateCryptoManager(
			New CallbackDescription("AddSignatureFromFileAfterCreateCryptoManager",
				DigitalSignatureInternalClient, Context),
			"", CreationParameters);
			
	EndIf;
	
EndProcedure

// It prompts the user to select signatures to save together with the object data.
//
// A common method to process property values with the NotifyDescription type in the DataDetails parameter.
//  When processing a notification, the parameter structure is passed to it.
//  This structure always has a Notification property of the NotifyDescription type, which needs to be processed to continue.
//  In addition, the structure always has the DataDetails property received when calling the procedure.
//  When calling a notification, the structure must be passed as a value. If an error occurs during the asynchronous
//  execution, add the ErrorDetails property of String type to this structure.
// 
// Parameters:
//  DataDetails - Structure:
//    * DataTitle      - String - a data item title, for example, File.
//    * ShowComment  - Boolean - (optional) - allows adding a comment in the
//                           data signing form. False if not specified.
//    * Presentation        - AnyRef
//                           - String - (optional), if it is not specified,
//                           the presentation is calculated by the Object property value.
//    * Object               - AnyRef - a reference to object, from which you need to get the signature list.
//                           - String - a temporary storage address of a signature array with properties,
//                           as the AddSignatureFromFile procedure returns.
//    * Data               - CallbackDescription - Handler for saving data and receiving the full file
//                           name with a path (after saving it), returned in the FullFileName property
//                           of the String type for saving digital signatures (see the common approach above).
//                           If 1C:Enterprise Extension is not attached, return
//                           the file name without a path.
//                           If the property will not be inserted or filled, it means canceling
//                           the continuation, and ResultProcessing with the False result will be called.
//
//                           For a batch request for permissions from the web client user to save the file of data
//                           and signatures, you need to insert the PermissionsProcessingRequest parameter of the NotifyDescription type.
//                           The procedure will get a structure with the following properties:
//                              # Calls - Array - Contains details of calls to save signatures.
//                              # ContinuationHandler - NotifyDescription - Procedure to be executed
//                                                     after requesting permissions, the procedure parameters are the same as
//                                                     the notification for the BeginRequestingUserPermission method has.
//                                                     If the permission is not received, everything is canceled.
//
//  ResultProcessing - CallbackDescription -
//     The parameter is passed to the result of the type: Boolean - True if everything was successful.
//
Procedure SaveDataWithSignature(DataDetails, ResultProcessing = Undefined) Export
	
	DigitalSignatureInternalClient.SaveDataWithSignature(DataDetails, ResultProcessing);
	
EndProcedure

// Checks the validity of the signature and the certificate..
// The certificate is always checked on the server if the administrator
// had set the check of digital signatures on the server.
//
// Parameters:
//   Notification           - CallbackDescription - CheckParameters.ResultAsStructure - True.:
//             
//             
//             
//             See DigitalSignatureClientServer.SignatureVerificationResult
//             CheckParameters.ResultAsStructure - True.
//   RawData       - BinaryData - binary data that was signed.
//                          Mathematical check is executed on the client side, even when
//                          the administrator has set the check of digital signatures on the server
//                          if the crypto manager is specified or it was received without an error.
//                          Performance and security increase when the signature is checked
//                          in the decrypted file (it will not be passed to the server).
//                        - String - the address of temporary storage that contains initial binary data.
//                        - Structure:
//                           * XMLEnvelope       - String - the signed XMLEnvelope,
//                                                         see also the XMLEnvelope function.
//                           * XMLDSigParameters - See DigitalSignatureClient.XMLDSigParameters
//                        - Structure:
//                           * CMSParameters - See DigitalSignatureClient.CMSParameters
//                           * Data  - String - custom string for signing,
//                                     - BinaryData - binary data for signing.
//   Signature              - BinaryData - digital signature binary data.
//                        - String         - an address of a temporary storage with binary data.
//                        - Undefined   - if SourceData is a SOAP envelope.
//   CryptoManager - Undefined - get crypto manager by default
//                          (manager of the first app in the list, as configured by the administrator).
//                        - CryptoManager - use the specified crypto manager.
//   OnDate               - Date - Date for checking the certificate if the date cannot be extracted
//                          from the signature or XMLEnvelope is to be checked.
//                          If the parameter is not passed, use the current session date
//                          if the date cannot be extracted from the signature or XMLEnvelope is to be checked.
//   CheckParameters    - See SignatureVerificationParameters
//                        - Undefined - show an error creating a cryptography Manager (when omitted).
//
Procedure VerifySignature(Notification, RawData, Signature,
	CryptoManager = Undefined,
	OnDate = Undefined,
	CheckParameters = Undefined) Export
	
	DigitalSignatureInternalClient.VerifySignature(
		Notification, RawData, Signature, CryptoManager, OnDate, CheckParameters);
	
EndProcedure

// Constructor of the CheckParameters parameter for the VerifySignature procedure.
// 
// Returns:
//  Structure:
//   * ShowCryptoManagerCreationError - Boolean - Flag indicating whether to 
//              display a cryptographic manager creation error (when it's not specified).
//   * ResultAsStructure - Boolean - If True, the result will have the following format:
//      See DigitalSignatureClientServer.SignatureVerificationResult
//   * VerifyCertificate - String - The signature verification options. Applicable if "ResultAsStructure" is set to "True".
//      Otherwise, the option is always "VerifyQualified".
//       "VerifyQualified" - (Default) Allow signing with NES and validate QES against the list of trusted non-accredited CAs. 
//                                      "QualifiedOnly" - Allow signing with QES only and ignore the list of trusted non-accredited CAs.
//       "DoNotVerifyCertificate" - Skip certificate verification.
//                                   
//       
//
Function SignatureVerificationParameters() Export
	
	Structure = New Structure;
	Structure.Insert("ShowCryptoManagerCreationError", True);
	Structure.Insert("ResultAsStructure", False);
	Structure.Insert("VerifyCertificate", DigitalSignatureInternalClientServer.VerifyQualified());
	
	Return Structure;
	
EndFunction

// Encrypts data, returns encryption certificates, and adds them to an object, if specified.
// 
// A common method to process property values with the NotifyDescription type in the DataDetails parameter.
//  When processing a notification, the parameter structure is passed to it.
//  This structure always has a Notification property of the NotifyDescription type, which needs to be processed to continue.
//  In addition, the structure always has the DataDetails property received when calling the procedure.
//  When calling a notification, the structure must be passed as a value. If an error occurs during the asynchronous
//  execution, add the ErrorDetails property of String type to this structure.
// 
// Parameters:
//  DataDetails - Structure:
//    * Operation             - String - a data encryption form title, for example, File encryption.
//    * DataTitle      - String - a title of an item or a data set, for example, File.
//    * NotifyOnCompletion  - Boolean - (optional) - if False, no notification of successful
//                           completion of the operation will be shown to present the data indicated next to the title.
//    * CertificatesSet    - String - (optional) the address of temporary storage that contains an array, described below.
//                           - Array - (optional) contains values of the
//                           CatalogRef.KeyCertificatesForDigitalSignaturesAndEncryption type or
//                           the BinaryData type (certificate export).
//                           - AnyRef - (Optional) - a reference to the object that requires certificates.
//    * ChangeSet        - Boolean - if True and CertificatesSet is specified and contains only references
//                           to certificates, you will be able to change the content of certificates.
//    * NoConfirmation     - Boolean - (optional) - skip user confirmation
//                           if the CertificatesFilter property is specified.
//    * ExecuteAtServer   - Undefined
//                           - Boolean -  (optional) - when not specified or Undefined,
//                           the execution will be determined automatically: if there is a server, first
//                           execute at the server, then in case of a failure at the client, then display a message about two errors.
//                           When True: if execution on the server is allowed, execute
//                           only on the server, in case of a failure one message about a server error is displayed.
//                           When False: execute only on the client, as if there is no server.
//    * OperationContext     - Undefined - (optional) - if specified, the property will be
//                           set to a specific value of an arbitrary type, which allows you to
//                           execute an action with the same encryption certificates again (the user
//                           is not asked to confirm the action).
//                           - Arbitrary - (optional) - if defined, the action will be executed
//                           with the same encryption certificates.
//                           The WithoutConfirmation parameter is considered to be True.
//                           The Operation, DataTitle, CertificatesSet, ChangeSet,
//                           and ExecuteAtServer parameters are ignored, and their values are left as they were at the first call.
//    * StopExecution - Arbitrary - if the property exists and an
//                           error occurs during asynchronous execution, execution stops without displaying the operation form or with closing this form
//                           if it was opened.
//    * EncryptAlgorithm - String - (Optional) Contains an explicit name ("Magma", "Kuznyechik", or "GOST 28147-89"), OID,
//                           or a presentation of the encryption algorithm that will override the default encryption algorithm.
//                           For example, if the representation "Magma" is provided, it will be converted into
//                           the encryption algorithm name used by the program performing the encryption."
//
//    Option 1.
//    * Data                - BinaryData - data to encrypt.
//                            - String - an address of a temporary storage with binary data.
//                            - CallbackDescription - a data receipt handler that returns
//                            it in the Data property (see the common approach above).
//    * ResultPlacement  - Undefined - (optional) - describes where to place the encrypted data.
//                            If it is not specified or Undefined, use the ResultProcessing parameter.
//                            - CallbackDescription - a handler of saving encrypted data.
//                            Consider the common approach (see above).
//                            DataDetails already has the EncryptedData parameter at the time it is called.
//                            In case of the DataSet parameter,
//                            the DataSetCurrentItem property is inserted into the DataDetails. It contains the EncryptedData parameter.
//    * Object                - AnyRef - (optional) - a reference to the object that needs to be encrypted.
//                            f not specified, encryption certificates are not required.
//    * ObjectVersion         - String - (optional) - version of the object data to check and
//                            lock the object before adding the encryption certificates.
//    * Presentation       - AnyRef - (optional), if the parameter is not specified,
//                                  the presentation is calculated by the Object property value.
//                          - String
//                          - Structure:
//                             ** Value      - AnyRef
//                                              - CallbackDescription - to open.
//                             ** Presentation - String - - a value presentation.
//
//    Option 2.
//    * DataSet           - Array - structures with properties described in Option 1.
//    * SetPresentation   - String - presentations of several data set items, for example, Files (%1).
//                            To this presentation, the number of items is filled in parameter %1.
//                            Click the hyperlink to open the list.
//                            If the data set has 1 item, value
//                            in the Presentation property of the DataSet property is used. If not specified,
//                            the presentation is calculated by the Object property value of a data set item.
//    * PresentationsList   - ValueList
//                            - Array - (optional) - an arbitrary list of items
//                            or an array with values, like the Presentation property has, and which
//                            the user can open. If not specified, it is filled from
//                            the Presentation or Object properties in the DataSet property.
//
//  Form - ClientApplicationForm  - a form to provide a UUID used to
//        store encrypted data to a temporary storage.
//        - UUID - a UUID that will be
//        used to store encrypted data to a temporary storage.
//        - Undefined      - use a standard form.
//
//  ResultProcessing - CallbackDescription -
//     It is required for non-standard result processing, if the Form or the ResultPlacement parameter is not specified.
//     The result gets the DataDetails parameter, to which the following properties are added in case of a success:
//     # Success - Boolean - True if everything is successfully completed. If "Success" is False, the partial completion
//               is defined by the SignatureProperties property (if the property is present, the step is completed).
//     # Cancel - Boolean - True if the user canceled the operation interactively.
//     # EncryptionCertificates = String - Temporary storage address that contains the array described below.
//                             = Array - Placed before starting encryption and after this it is not changed.
//                                ## Value - Structure
//                                   ### Thumbprint - String - Certificate thumbprint in the Base64 string format.
//                                   ### Presentation - String - Saved subject presentation
//                                                       got from certificate binary data.
//                                   ### Certificate - BinaryData - Contains export of the certificate
//                                                       that was used for encryption.
//     # EncryptedData = BinaryData - Encryption result.
//                             Check the property in the DataSet parameter when passing it.
//                           String = Address of temporary storage that contains the encryption result.
//
Procedure Encrypt(DataDetails, Form = Undefined, ResultProcessing = Undefined) Export
	
	ClientParameters = New Structure;
	ClientParameters.Insert("DataDetails", DataDetails);
	ClientParameters.Insert("Form", Form);
	ClientParameters.Insert("ResultProcessing", ResultProcessing);
	
	CompletionProcessing = New CallbackDescription("RegularlyCompletion",
		DigitalSignatureInternalClient, ClientParameters);
	
	If DataDetails.Property("OperationContext")
	   And TypeOf(DataDetails.OperationContext) = Type("ClientApplicationForm") Then
		
		DigitalSignatureInternalClient.ExtendStoringOperationContext(DataDetails);
		FormNameBeginning = "Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.";
		
		If DataDetails.OperationContext.FormName = FormNameBeginning + "DataEncryption" Then
			DataDetails.OperationContext.ExecuteEncryption(ClientParameters, CompletionProcessing);
			Return;
		EndIf;
	EndIf;
	
	ServerParameters1 = New Structure;
	ServerParameters1.Insert("Operation",            NStr("vi = 'Mã hóa dữ liệu';
															|ru = 'Шифрование данных';
															|en = 'Data encryption'; fa = 'رمزگذاری داده‌ها';
															|it = 'Crittografia dei dati';
															|pl = 'Szyfrowanie danych';
															|tr = 'Veri şifrelemesi'"));
	ServerParameters1.Insert("DataTitle",     NStr("vi = 'Dữ liệu';
													|ru = 'Данные';
													|en = 'Data'; fa = 'داده';
													|it = 'Dati';
													|pl = 'Data';
													|tr = 'Veriler'"));
	ServerParameters1.Insert("CertificatesSet");
	ServerParameters1.Insert("ChangeSet");
	ServerParameters1.Insert("ExecuteAtServer");
	FillPropertyValues(ServerParameters1, DataDetails);
	
	DigitalSignatureInternalClient.OpenNewForm("DataEncryption",
		ClientParameters, ServerParameters1, CompletionProcessing);
	
EndProcedure

// Decrypts data, returns it and places into object if it is specified.
// 
// A common method to process property values with the NotifyDescription type in the DataDetails parameter.
//  When processing a notification, the parameter structure is passed to it.
//  This structure always has a Notification property of the NotifyDescription type, which needs to be processed to continue.
//  In addition, the structure always has the DataDetails property received when calling the procedure.
//  When calling a notification, the structure must be passed as a value. If an error occurs during the asynchronous
//  execution, add the ErrorDetails property of String type to this structure.
// 
// Parameters:
//  DataDetails - Structure:
//    * Operation             - String - a data decryption form title, for example, File decryption.
//    * DataTitle      - String - a title of an item or a data set, for example, File.
//    * NotifyOnCompletion  - Boolean - (optional) - if False, no notification of successful
//                           completion of the operation will be shown to present the data indicated next to the title.
//    * CertificatesFilter    - Array - (optional) - contains references to the catalog items.
//                           DigitalSignatureAndEncryptionCertificates that can be selected
//                           by the user. The filter locks the ability to select other certificates
//                           from the Personal store.
//    * NoConfirmation     - Boolean - (Optional)
//                           - Skip user confirmation if CertificatesFilter property has one certificate and:
//                           a) Either the certificate has the flag "Protect digital signature application with password",
//                           b) Or a user has memorized the certificate password for the time of the session,
//                           c) Or a password has been set earlier by the SetCertificatePassword method.
//                           If an error occurs during decryption, a form opens where the user can enter the password.
//                           
//    * IsAuthentication    - Boolean - (optional) - if True, show the OK button
//                           instead of the Decrypt button. And some labels will be corrected.
//                           Besides, the ReportCompletion parameter is set to False.
//    * BeforeExecute     - CallbackDescription - (optional) - details of the additional
//                           data preparation handler, after selecting the certificate, by which the data will be decrypted.
//                           In this handler you can fill the Data parameter if it is required.
//                           DataDetails already has
//                           the SelectedCertificate parameter in the moment of call (see below). Consider the common approach (see above).
//    * ExecuteAtServer   - Undefined
//                           - Boolean -  (optional) - when not specified or Undefined,
//                           the execution will be determined automatically: if there is a server, first
//                           execute at the server, then in case of a failure at the client, then display a message about two errors.
//                           When True: if execution on the server is allowed, execute
//                           only on the server, in case of a failure one message about a server error is displayed.
//                           When False: execute only on the client, as if there is no server.
//    * AdditionalActionParameters - Arbitrary - (optional) - if specified, it is passed
//                           to the server to the BeforeOperationStart common module procedure.
//                           DigitalSignatureOverridable common module as InputParameters.
//    * OperationContext     - Undefined - (Optional) If specified, the property is assigned a value
//                           of an arbitrary type, which allows the user to repeat the same action
//                           with the certificate without asking the user for the password and the action confirmation. 
//                           If the procedure fails, the repeated action with the passed context
//                           might also cause an error.
//                           
//                           - Arbitrary - (optional) - if defined, the action will be executed
//                           with the same certificate without requesting a password or confirmation.
//                           The WithoutConfirmation parameter is considered to be True.
//                           The Operation, DataTitle, CertificatesFilter, IsAuthentication
//                           and ExecuteAtServer parameters are ignored. They retain the values they had at the first call.
//                           The AdditionalActionsParameters parameter is ignored.
//                           The BeforeOperationStart procedure is not called.
//                           If you pass the context returned by the Sign procedure,
//                           the password entered for the certificate can be used as if
//                           the password had been saved for the duration of session. In other cases, the context is ignored.
//    * StopExecution - Arbitrary - if the property exists and an
//                           error occurs during asynchronous execution, execution stops without displaying the operation form or with closing this form
//                           if it was opened.
// 
//    Option 1.
//    * Data                - BinaryData - data to decrypt.
//                            - String - an address of a temporary storage with binary data.
//                            - CallbackDescription - a data receipt handler that returns
//                            it in the Data property (see the common approach above). In the moment of call,
//                            DataDetails already has the selected certificate as SelectedCertificate (see below).
//    * ResultPlacement  - Undefined - (optional) - describes where to place the decrypted data.
//                            If it is not specified or Undefined, use the ResultProcessing parameter.
//                            - CallbackDescription - a handler of saving decrypted data.
//                            Consider the common approach (see above).
//                            DataDetails already has the DecryptedData parameter at the time it is called.
//                            In case of the DataSet parameter,
//                            the DataSetCurrentItem property is inserted into the DataDetails. It contains the DecryptedData parameter.
//    * Object                - AnyRef - (optional) - a reference to the object to be decrypted,
//                            as well as clear records from the EncryptionCertificates
//                            information register after decryption is completed successfully.
//                            If not specified, you do not need to get certificates from an object and clear them.
//                            - String - temporary storage address that contains
//                              ## Array of Structure - encryption certificate array
//                                 ### Thumbprint     - String - a certificate thumbprint in the Base64 string format.
//                                 ### Presentation - String - a saved subject presentation
//                                                     received from certificate binary data.
//                                 ### Certificate    - BinaryData - contains export of the certificate
//                                                     that was used for encryption.
//    * Presentation       - AnyRef - (optional), if the parameter is not specified,
//                                  the presentation is calculated by the Object property value.
//                          - String
//                          - Structure:
//                             ** Value      - AnyRef
//                                              - CallbackDescription - to open.
//                             ** Presentation - String - - a value presentation.
// 
//    Option 2.
//    * DataSet           - Array - structures with properties described in Option 1.
//    * SetPresentation   - String - presentations of several data set items, for example, Files (%1).
//                            To this presentation, the number of items is filled in parameter %1.
//                            Click the hyperlink to open the list.
//                            If the data set has 1 item, value
//                            in the Presentation property of the DataSet property is used. If not specified,
//                            the presentation is calculated by the Object property value of a data set item.
//    * PresentationsList   - ValueList
//                            - Array - (optional) - an arbitrary list of items
//                            or an array with values, like the Presentation property has, and which
//                            the user can open. If not specified, it is filled from
//                            the Presentation or Object properties in the DataSet property.
//    * EncryptionCertificates - Array - (optional) values, like the Object parameter has. It is used
//                            to extract encryption certificate lists for items that are specified
//                            in the PresentationsList parameter (the order needs to correspond to it).
//                            When specified, the Object parameter is not used.
//
//  Form - ClientApplicationForm - a form to provide a UUID used to
//        store decrypted data to a temporary storage.
//        - UUID - a UUID that will be
//        used to store decrypted data to a temporary storage.
//        - Undefined - use a standard form.
//
//  ResultProcessing - CallbackDescription -
//     It is required for non-standard result processing, if the Form and/or the ResultPlacement parameter is not specified.
//     The result gets the DataDetails parameter, to which the following properties are added in case of a success:
//     # Success - Boolean - True if everything is successfully completed. If Success = False, the partial completion
//               is defined by having the SignatureProperties property. If there is, the step is completed.
//     # Cancel - Boolean - True if the user canceled the operation interactively.
//     # SelectedCertificate - Structure - contains the following certificate properties
//         ## Ref - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - Reference to the certificate.
//         ## Thumbprint - String - Certificate thumbprint in the Base64 format.
//         ## Data - String - Temp storage address that contains certificate binary data.
//     # DecryptedData - BinaryData - Decryption result.
//                              Check the property in the DataSet parameter when passing it.
//                            = String - Temp storage address that contains the decryption result.
//
Procedure Decrypt(DataDetails, Form = Undefined, ResultProcessing = Undefined) Export
	
	ClientParameters = New Structure;
	ClientParameters.Insert("DataDetails", DataDetails);
	ClientParameters.Insert("Form", Form);
	ClientParameters.Insert("ResultProcessing", ResultProcessing);
	
	CompletionProcessing = New CallbackDescription("RegularlyCompletion",
		DigitalSignatureInternalClient, ClientParameters);
	
	If DataDetails.Property("OperationContext")
	   And TypeOf(DataDetails.OperationContext) = Type("ClientApplicationForm") Then
		
		DigitalSignatureInternalClient.ExtendStoringOperationContext(DataDetails);
		FormNameBeginning = "Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.";
		
		If DataDetails.OperationContext.FormName = FormNameBeginning + "DataDecryption" Then
			DataDetails.OperationContext.ExecuteDecryption(ClientParameters, CompletionProcessing);
			Return;
		EndIf;
		If DataDetails.OperationContext.FormName = FormNameBeginning + "DataSigning" Then
			ClientParameters.Insert("SpecifiedContextOfOtherOperation");
		EndIf;
	EndIf;
	
	ServerParameters1 = New Structure;
	ServerParameters1.Insert("Operation",            NStr("vi = 'Giải mã dữ liệu';
															|ru = 'Расшифровка данных';
															|en = 'Data decryption'; fa = 'رمزگشایی داده‌ها';
															|it = 'Crittografia dati';
															|pl = 'Rozszyfrowanie danych';
															|tr = 'Veri detaylandırması'"));
	ServerParameters1.Insert("DataTitle",     NStr("vi = 'Dữ liệu';
													|ru = 'Данные';
													|en = 'Data'; fa = 'داده';
													|it = 'Dati';
													|pl = 'Data';
													|tr = 'Veriler'"));
	ServerParameters1.Insert("CertificatesFilter");
	ServerParameters1.Insert("EncryptionCertificates");
	ServerParameters1.Insert("IsAuthentication");
	ServerParameters1.Insert("ExecuteAtServer");
	ServerParameters1.Insert("AdditionalActionParameters");
	ServerParameters1.Insert("AllowRememberPassword");
	FillPropertyValues(ServerParameters1, DataDetails);
	
	If DataDetails.Property("Data") Then
		If TypeOf(ServerParameters1.EncryptionCertificates) <> Type("Array")
		   And DataDetails.Property("Object") Then
			
			ServerParameters1.Insert("EncryptionCertificates", DataDetails.Object);
		EndIf;
		
	ElsIf TypeOf(ServerParameters1.EncryptionCertificates) <> Type("Array") Then
		
		ServerParameters1.Insert("EncryptionCertificates", New Array);
		For Each DataElement In DataDetails.DataSet Do
			If DataElement.Property("Object") Then
				ServerParameters1.EncryptionCertificates.Add(DataElement.Object);
			Else
				ServerParameters1.EncryptionCertificates.Add(Undefined);
			EndIf;
		EndDo;
	EndIf;
	
	DigitalSignatureInternalClient.OpenNewForm("DataDecryption",
		ClientParameters, ServerParameters1, CompletionProcessing);
	
EndProcedure

// Upgrades the signatures to the given type.
//
// Parameters:
//  DataDetails - Structure:
//    * SignatureType          - EnumRef.CryptographySignatureTypes - Signature type to upgrade to.
//                           If the actual SignatureType is the same or higher, no actions are performed.
//                           
//    * AddArchiveTimestamp - Boolean - If True and SignatureType and actual SignatureType are archived, add a timestamp.
//                           
//   
//    * Signature             - BinaryData - Signature data.
//                          - String - an address of a temporary storage with binary data.
//                          - Structure:
//                             ** SignedObject - AnyRef - Reference to the object whose signatures will be upgraded.
//                             ** SequenceNumber - Number - a signature sequence number.
//                                                - Array - values of the type specified above.
//                                                - Undefined - All object's signatures.
//                             ** Signature - BinaryData - (Optional) Signature data.
//                                        Applicable if the signature sequence number is numeric.
//                                        - String - Address of the temporary storage that contains the signature binary data.
//                                                          Applicable if the signature sequence number is numeric.
//                          - Array of BinaryData
//                          - Array of String - Same as in the line above. 
//                          - Array of Structure - Same as the structure above.
//   
//    * Presentation       - AnyRef - (Optional) If not specified, the presentation is generated using the Object and SequenceNumber property values.
//                                  
//                          - String
//                          - Structure:
//                             ** Value      - AnyRef
//                                              - CallbackDescription - to open.
//                             ** Presentation - String - Value presentation.
//                          - ValueList
//                          - Array - (Optional) Arbitrary list or array with the above values that users can open.
//                          If not specified, takes the value from properties Object and SequenceNumber.
//                          
//                          
//
//  Form - ClientApplicationForm - a form, from which you need to get an UUID
//                                that will be used when locking an object.
//        - UUID - a UUID that will be used
//                                to lock an object.
//
//  AbortArrayProcessingOnError  - Boolean - Flag indicating whether to interrupt processing items if an error occurs. By default, True.
//  ShouldIgnoreCertificateValidityPeriod - Boolean - Flag indicating whether to validate the certificate before enhancement
//                                                 By default, False.
//
//  ResultProcessing - NotifyDescription - Required for non-standard result processing.
//     For example, if the object reference or signature number is not specified.
//     Structure:
//     # Success = Boolean - True if all operations succeeded. If False, the partial abortion is defined by SignatureProperties.
//               If the property is specified, the step is considered completed.
//     # ErrorText = String
//     # SignatureProperties - Array of Structure -
//                          ## Signature - BinaryData - Signature to be upgraded.
//                                     = String - Address in the temp storage.
//                          ## SignedObject - AnyRef - If any.
//                          ## SequenceNumber - Number - If any.
//                          ## SignatureType - EnumRef.CryptographySignatureTypes - Signature type.
//                                Applicable if the upgrade failed but the type was determined.
//                          ## LastTimestampValidityPeriod - Date - Timestamp validity.
//                                Applicable if the upgrade failed but the validity period was determined.
//                          ## SignatureProperties = See DigitalSignatureClientServer.NewSignatureProperties
//                             -
//                          Upgraded signature properties.
//                           Only modified properties are available.
//                        ## Error - String - Text of an error occurred during the upgrade.
//                                                 In this case, the structure doesn't contain properties of the signature that failed to upgrade.
//                                                 - String - Address of the temp storage that contains the array above.
//
Procedure EnhanceSignature(DataDetails, Form, ResultProcessing = Undefined,
	AbortArrayProcessingOnError = True, ShouldIgnoreCertificateValidityPeriod = False) Export
	
	Context = New Structure;
	Context.Insert("ResultProcessing", ResultProcessing);
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("DataDetails",      DataDetails);
	If TypeOf(Form) = Type("ClientApplicationForm") Then
		ExecutionParameters.Insert("FormIdentifier", Form.UUID);
	Else
		ExecutionParameters.Insert("FormIdentifier", Form);
	EndIf;
	ExecutionParameters.Insert("AbortArrayProcessingOnError",  AbortArrayProcessingOnError);
	ExecutionParameters.Insert("ShouldIgnoreCertificateValidityPeriod", ShouldIgnoreCertificateValidityPeriod);
		
	Context.Insert("ExecutionParameters", ExecutionParameters);
	
	DigitalSignatureInternalClient.EnhanceSignature(Context);

EndProcedure

// Checks the crypto certificate validity.
//
// Parameters:
//   Notification           - CallbackDescription - a notification about the execution result of the following types:
//             = Boolean       - True if the check is completed successfully.
//             = String       - a description of a certificate check error.
//             = Undefined - cannot get the crypto manager (because it is not specified).
//
//   Certificate           - CryptoCertificate - a certificate.
//                        - BinaryData - certificate binary data.
//                        - String - an address of a temporary storage that contains certificate binary data.
//
//   CryptoManager - Undefined - get the crypto manager automatically.
//                        - CryptoManager - use the specified crypto manager
//                          (a check on the server will not be executed).
//
//   OnDate               - Date - Check the certificate on the specified date.
//                          If the parameter is not specified or an empty value is passed,
//                          check on the current session date.
//   CheckParameters - See CertificateVerificationParameters.
//
Procedure CheckCertificate(Notification, Certificate, CryptoManager = Undefined, OnDate = Undefined, CheckParameters = Undefined) Export
	
	DigitalSignatureInternalClient.CheckCertificate(Notification, Certificate, CryptoManager, OnDate, CheckParameters);
	
EndProcedure

// Additional parameters for the certificate check.
// 
// Returns:
//  Structure - Additional parameters for the certificate check:
//   * PerformCAVerification - String - The signature verification options:
//       "VerifyQualified" - (Default) Allow signing with NES and validate QES against the list of trusted non-accredited CAs. 
//                                      "QualifiedOnly" - Allow signing with QES only and ignore the list of trusted non-accredited CAs.
//       "DoNotVerifyCertificate" - Skip certificate verification.
//                                   
//       
//   * IgnoreCertificateRevocationStatus - Boolean - Skip validating certificate against the revocation list.
//   * IsTimestampDateSpecified - Boolean - The "OnDate" parameter specifies the date on which the certificate revocation and
//                                        chain verification will be performed.
//
Function CertificateVerificationParameters() Export
	
	Structure = New Structure;
	Structure.Insert("PerformCAVerification", DigitalSignatureInternalClientServer.VerifyQualified());
	Structure.Insert("IgnoreCertificateRevocationStatus", False);
	Structure.Insert("IsTimestampDateSpecified", False);
	Return Structure;
	
EndFunction

// Opens the CertificateCheck form and returns the check result.
//
// Parameters:
//  Certificate - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - a certificate being checked.
//
//  AdditionalParameters - Undefined - an ordinary certificate check.
//                          - Structure - Has the following optional properties:
//    * FormOwner          - ClientApplicationForm - another form.
//    * FormCaption         - String - if specified, it replaces the form title.
//    * CheckOnSelection      - Boolean - if True, the Check button will be called
//                             "Check and continue", and the Close button will be called "Cancel".
//    * ResultProcessing    - CallbackDescription - it is called immediately after the check,
//                             Result.ChecksPassed (see below) is passed to the procedure with the initial value False.
//                             If True is not set in the CheckOnChoose mode,
//                             the form will not be closed after a return from the notification procedure and
//                             a warning that it is impossible to continue will be shown.
//    * NoConfirmation       - Boolean - if it is set to True and you have a password,
//                             the check will be executed immediately without opening the form.
//                             If the mode is CheckOnChoose and the ResultProcessing parameter is set,
//                             the form will not open if the ChecksPassed parameter is set to True.
//    * CompletionProcessing    - CallbackDescription - it is called when the form is closed,
//                             the Undefined or the ChecksPassed value are passed as its result (see below).
//    * OperationContext       - Arbitrary - if you pass the context returned by the Sign procedure,
//                             Decrypt procedure, the password entered for the certificate can be used
//                             as if the password had been saved for the duration of session.
//                             When recalling the WithoutConfirmation parameter is considered equal to True.
//    * DontShowResults - Boolean - if a parameter takes the True value and the OperationContext parameter
//                             contains the context of the previous operation, the check results will not be shown
//                             to the user.
//    * SignatureType             - EnumRef.CryptographySignatureTypes - By default, the type specified in the settings. 
//                             It gets the type from "OperationContext" if it is passed from "Sign".
//    * PerformCAVerification - See CertificateVerificationParameters.
//    * IgnoreCertificateRevocationStatus - See CertificateVerificationParameters.
//    * Result              - Undefined - a check was never performed.
//                             - Structure - Return value. It is inserted before processing the result:
//         * ChecksPassed  - Boolean - a return value. Is set in the procedure of the ResultProcessing parameter.
//         * ChecksAtServer - Undefined - a check was not executed on the server:
//                             - Structure - with properties, as the following parameter has.
//         * ChecksAtClient - Structure:
//             * CertificateExists  - Boolean
//                                   - Undefined - if True, the check was successful;
//                                     if False - the check was not successful; if Undefined, it was not executed.
//                                     If standard checks are hidden in the OnCreateFormCertificateCheck
//                                     of the DigitalSignatureOverridable module, there is no property.
//             * CertificateData   - Boolean
//                                   - Undefined - the same as specified above.
//             * ProgramExists    - Boolean
//                                   - Undefined - the same as specified above.
//             * Signing          - Boolean
//                                   - Undefined - the same as specified above.
//             * CheckSignature     - Boolean
//                                   - Undefined - the same as specified above.
//             * Encryption          - Boolean
//                                   - Undefined - the same as specified above.
//             * Details         - Boolean
//                                   - Undefined - the same as specified above.
//             <Additional check name> additional check name determined
//                                     in the OnCreateFormCertificateCheck common module
//                                     with types as specified above.
//             <Additional check name>Error additional check name with the Error ending and
//                                    the String type (contains the error text if the check is False).
//
//    * AdditionalChecksParameters - Arbitrary - parameters that are passed to the procedure named
//        OnCreateFormCertificateCheck of the DigitalSignatureOverridable common module.
//
Procedure CheckCatalogCertificate(Certificate, AdditionalParameters = Undefined) Export
	
	DigitalSignatureInternalClient.CheckCatalogCertificate(Certificate, AdditionalParameters);
	
EndProcedure

// Shows the dialog box for installing an extension to use digital signature and encryption.
// For operations using platform tools only (CryptoManager).
//
// Parameters:
//   WithoutQuestion - Boolean - if True is set, the question will not be shown.
//                It is required if the user clicked Install extension.
//
//   HandlerResults_1 - CallbackDescription - details of the procedure that gets the ExtensionInstalled
//      selection result of the following types:
//       = Boolean
//          True - The user confirmed the installation, the extension was successfully attached after installation.
//          False   - The user confirmed the installation, but the extension could not be attached after the installation.
//       = Undefined - The user refused to install.
//
//   QueryText     - String - a question text.
//   QuestionTitle - String - a question title.
//
//
Procedure InstallExtension(WithoutQuestion, HandlerResults_1 = Undefined, QueryText = "", QuestionTitle = "") Export
	
	DigitalSignatureInternalClient.InstallExtension(WithoutQuestion, HandlerResults_1, QueryText, QuestionTitle);
	
EndProcedure

// Opens or activates the form of setting digital signature and encryption.
// 
// Parameters:
//  Page - String - allowed rows are Certificates, Settings, and Applications.
//
Procedure OpenDigitalSignatureAndEncryptionSettings(Page = "Certificates") Export
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowPage", Page);
	
	Form = OpenForm("CommonForm.DigitalSignatureAndEncryptionSettings", FormParameters);
	
	// When re-opening the form, additional actions are required.
	If Page = "Certificates" Then
		Form.Items.Pages.CurrentPage = Form.Items.CertificatesPage;
		
	ElsIf Page = "Settings" Then
		Form.Items.Pages.CurrentPage = Form.Items.SettingsPage;
		
	ElsIf Page = "Programs" Then
		Form.Items.Pages.CurrentPage = Form.Items.ApplicationPage;
	EndIf;
	
	Form.Open();
	
EndProcedure

// Opens a diagnostics form that displays causes and possible solutions for known issues related to digital signatures.
// These recommendations are automatically loaded from a classifier via the Internet. The form also provides an option to send information to technical support.
// It is recommended to call this function instead of showing a technical error message to the user in all cases
// following an unsuccessful operation with a digital signature.
// 
// Parameters:
//  FormParameters - See ExtendedErrorPresentationFormParameters.
//  OwnerForm - ClientApplicationForm - Form owner.
//  CallbackOnCompletion - CallbackDescription - Notification about the closure of the error form.
//  
//  Example:
//   FormParameters = ErrorExtendedPresentationFormParameters();
//	 FormParameters.WarningTitle = NStr("en = 'Failed to distribute the reports'; fa = 'Failed to distribute the reports'");
//	 FormParameters.ErrorTextServer = EncryptionErrorAtServerText;
//	 FormParameters.AdditionalData.Insert("Certificate", Result.CertificateToEncrypt);
//	 FormParameters.ShowNeedHelp = True;
//	 FormParameters.ShowInstruction = True;
//	 ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
//	 ModuleDigitalSignatureClient.OpenExtendedErrorPresentationForm(FormParameters);
//  
Procedure OpenExtendedErrorPresentationForm(FormParameters, OwnerForm = Undefined, CallbackOnCompletion = Undefined) Export
	
	DigitalSignatureInternalClient.OpenExtendedErrorPresentationForm(FormParameters, OwnerForm, CallbackOnCompletion);
	
EndProcedure

// The parameter constructor for the extended error presentation form.
// 
// Returns:
//  Structure - Parameters of the extended error presentation form.:
//   * WarningTitle - String - The title of the error form.
//   * SupportInformation - FormattedString - Item title for the technical support.
//   * ErrorTextClient     - String - Text used to search for issues and solutions on the client.
//                            It's provided if the error context is important or, in case of 
//                            a single common error, the error text is important.
//   * ErrorTextServer     - String - Text used to search for issues and solutions on the server. 
//                            It's provided if the error context is important.
//   * AdditionalData  - Structure:
//      ** SignatureData     - String - (Optional) The address of the signature data in the temporary storage if a signature error occurred.
//      ** Certificate        - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - (Optional) A reference to the certificate
//                              associated with the error.
//      ** CertificateData  - String - (Optional) Certificate data address in the temporary storage.
//   * ShowNeedHelp - Boolean - Show the "Need help?" group and the buttons for installing the extension and setting up the applications.
//   * ShowOpenApplicationsSettings - Boolean - If "ShowNeedHelp" is set to "True",
//                            then display a button that navigates to the digital signature application setup.
//   * ShowExtensionInstallation - Boolean - If "ShowNeedHelp" is set to "True",
//                            display a button for installing the cryptography extension.
//   * ShowInstruction - Boolean - If "ShowNeedHelp" is set to "True", then display the "Need help?" hyperlink.
//   * AdditionalLinkText - String - The title of the additional link that runs the "AdditionalRefHandler"
//                            event handler, whose outcome is a Structure:
//                             # URL - String - The link specified in "AdditionalLinkText".
//                             # AdditionalLinkHandlerParameter - See below.
//   * AdditionalLinkHandler - String - The name of the notification handler from the common module.
//                            For example, "EDLIssuesHandling.OpenDiagnosticWizard".
//   * AdditionalLinkHandlerParameter - Arbitrary - A parameter of "AdditionalRefHandler".
//
Function ExtendedErrorPresentationFormParameters() Export
	
	Structure = New Structure;
	Structure.Insert("WarningTitle", "");
	Structure.Insert("SupportInformation", "");
	Structure.Insert("ErrorTextClient", "");
	Structure.Insert("ErrorTextServer", "");
	Structure.Insert("AdditionalData", New Structure);
	Structure.Insert("ShowNeedHelp", False);
	Structure.Insert("ShowOpenApplicationsSettings", False);
	Structure.Insert("ShowExtensionInstallation", False);
	Structure.Insert("ShowInstruction", False);
	Structure.Insert("AdditionalLinkText", "");
	Structure.Insert("AdditionalLinkHandler", "");
	Structure.Insert("AdditionalLinkHandlerParameter");
	
	Return Structure;
		
EndFunction

// Opens a reference to the "How to work with digital signature and encryption apps" ITS section.
//
Procedure OpenInstructionOfWorkWithApplications() Export
	
	DigitalSignatureInternalClient.OpenInstructionOfWorkWithApplications();
	
EndProcedure

// Returns the date extracted from the signature binary data or Undefined.
//
// Parameters:
//  Notification - CallbackDescription - Called to pass the return value, which has one of the following types::
//                 = Date - Date was successfully obtained.
//                 = Undefined - Failed to obtain the date.
//  Signature - BinaryData - signature data to extract a date from.
//  CastToSessionTimeZone - Boolean - cast the universal time to the session time.
//
Procedure SigningDate(Notification, Signature, CastToSessionTimeZone = True) Export
	
	SigningDate = DigitalSignatureInternalClientServer.SigningDateUniversal(Signature);
	
	If SigningDate = Undefined Then
		RunCallback(Notification, Undefined);
		Return;
	EndIf;
	
	If CastToSessionTimeZone Then
		SigningDate = SigningDate + (CommonClient.SessionDate()
			- CommonClient.UniversalDate());
	EndIf;
	
	RunCallback(Notification, SigningDate);
	
EndProcedure
	
// Returns a certificate presentation in the catalog, generated
// from the subject presentation ("IssuedTo") and certificate expiration date.
//
// Parameters:
//   Certificate   - CryptoCertificate - Cryptographic certificate.
//                - Structure:
//                   * ValidBefore - See DigitalSignature.CertificateProperties.
//                   * Certificate   - CryptoCertificate - Cryptographic certificate.
//
// Returns:
//  String - Certificate presentation in the catalog.
//
Function CertificatePresentation(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.CertificatePresentation(Certificate,
		DigitalSignatureInternalClient.UTCOffset());
	
EndFunction

// Returns the certificate subject presentation (IssuedTo).
//
// Parameters:
//   Certificate - CryptoCertificate - a crypto certificate.
//
// Returns:
//   String   - a subject presentation in the format "Last name Name, Company, Department, Position."
//              If cannot determine FullName, then it is replaced with CommonName.
//              Company, Department, or JobPosition can be missing if they are not specified or
//              cannot be determined.
//
Function SubjectPresentation(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.SubjectPresentation(Certificate);
	
EndFunction

// Returns a presentation of the certificate issuer (IssuedBy).
//
// Parameters:
//   Certificate - CryptoCertificate - a crypto certificate.
//
// Returns:
//   String - Issuer's presentation in the format "CommonName, Company, Department",
//            Company and Department can be missing, if undefined.
//
Function IssuerPresentation(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.IssuerPresentation(Certificate);
	
EndFunction

// Returns main certificate properties as a structure.
//
// Parameters:
//   Certificate - CryptoCertificate - a crypto certificate.
//
// Returns:
//   Structure:
//    * Thumbprint      - String - a certificate thumbprint in the Base64 string format.
//    * SerialNumber  - BinaryData - a property of the SerialNumber certificate.
//    * Presentation  - See DigitalSignatureClient.CertificatePresentation.
//    * IssuedTo      - See DigitalSignatureClient.SubjectPresentation.
//    * IssuedBy       - See DigitalSignatureClient.IssuerPresentation.
//    * StartDate     - Date   - a StartDate certificate property in the session time zone.
//    * EndDate  - Date   - an EndDate certificate property in the session time zone.
//    * Purpose     - String - Extended property details of the EKU certificate.
//    * Signing     - Boolean - the UseToSign certificate property.
//    * Encryption     - Boolean - Certificate property "UseToEncrypt".
//        For 1C:Enterprise v.8.3.27 and later, the structure has the following properties:
//    * ValidBefore - Date - The earliest date from "EndDate" and "PrivateKeyExpirationDate" (if specified in the certificate).
//    * PrivateKeyStartDate     - Date   - Certificate's property specified in OID 2.5.29.16 in the session time zone.
//    * PrivateKeyExpirationDate  - Date   - Certificate's property specified in OID 2.5.29.16 in the session time zone.
//    * CertificateAuthorityKeyID - String - Issuer key ID.
//    * SignAlgorithm - String - OID algorithm of the certificate's signature.
//    * PublicKeyAlgorithm - String - OID algorithm of the certificate's public key.
//    * AddressesOfRevocationLists - Array of String
//
Function CertificateProperties(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.CertificateProperties(Certificate,
		DigitalSignatureInternalClient.UTCOffset(), Undefined);
	
EndFunction

// Returns properties of the crypto certificate subject.
//
// Parameters:
//   Certificate - CryptoCertificate - a certificate to return the subject properties for.
//
// Returns:
//  Structure - Contains properties whose content depends on the national specifics. For example, for the Russian Federation:
//     * CommonName         - String - (64) - it is extracted from the CN field - it is an alias of the certificate authority.
//                          LE: depends on type of the last DS owner.
//                              a) Company name
//                              b) Automated system name
//                              c) other displayed name as the information system requires.
//                          Individual: FullName.
//                        - Undefined - such certificate property is missing.
//
//     * Country           - String - (2) - it is extracted from the C field - the two-symbol country code
//                          according to ISO 3166-1:1997 (GOST 7.67-2003).
//                        - Undefined - the certificate property does not exist.
//
//     * State           - String - (128) - it is extracted from the S field - the RF region name.
//                          LE - by the location address.
//                          Individual - by the registration address.
//                        - Undefined - such certificate property is missing.
//
//     * Locality  - String - (128) - extracted from the L field - a locality description.
//                          LE - by the location address.
//                          Individual - by the registration address.
//                        - Undefined - such certificate property is missing.
//
//     * Street            - String - (128) - it is extracted from the Street field - the street, house, and office names.
//                          LE - by the location address.
//                          Individual - by the registration address.
//                        - Undefined - such certificate property is missing.
//
//     * Organization      - String - (64) - extracted from the O field.
//                          LE - a full or short company name.
//                        - Undefined - such certificate property is missing.
//
//     * Department    - String - (64) - it is extracted from the OU field.
//                          LE - in case of issuing the DS to official responsible - the company department.
//                              Department is a territorial structural unit of a large company,
//                              which is not usually filled in the certificate.
//                        - Undefined - such certificate property is missing.
//
//     * Email - String - (128) - extracted from the E field (an email address).
//                          LE - an official responsible email address.
//                          Individual - email address of an individual.
//                        - Undefined - such certificate property is missing.
//
//     * JobTitle        - String - (64) - extracted from the T field.
//                          LE - in case of issuing the DS to an official responsible - their position.
//                        - Undefined - such certificate property is missing.
//
//     * OGRN             - String - (64) - extracted from the OGRN field.
//                          For LE, a company's registration number.
//                        - Undefined - such certificate property is missing.
//
//     * OGRNIE           - String - (64) - extracted from the OGRNIP field.
//                          For IE, an individual entrepreneur's registration number.
//                        - Undefined - such certificate property is missing.
//
//     * SNILS            - String - (64) - extracted from the SNILS field.
//                          Individual - a SNILS number
//                          LE - not required, in case of issuing the DS to official responsible - their SNILS number.
//                        - Undefined - such certificate property is missing.
//
//     * TIN              - String - (12) - extracted from the INN field.
//                          Individual - a TIN.
//                          IE - a TIN.
//                          LE - not required, but can be filled in in old certificates.
//                        - Undefined - such certificate property is missing.
//
//     * TINEntity            - String - (10) - extracted from the INNLE field.
//                          LE - required, but may be absent in old certificates.
//                        - Undefined - such certificate property is missing.
//
//     * LastName          - String - (64) - extracted from the SN field (if the field is filled in).
//                        - Undefined - such certificate property is missing.
//
//     * Name              - String - (64) - extracted from the GN field (if the field is filled in).
//                        - Undefined - such certificate property is missing.
//
//     * MiddleName         - String - (64) - extracted from the GN field (if the field is filled in).
//                        - Undefined - such certificate property is missing.
//
Function CertificateSubjectProperties(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.CertificateSubjectProperties(Certificate);
	
EndFunction

// Returns properties of the crypto certificate issuer. 
//
// Parameters:
//   Certificate - CryptoCertificate - a certificate to return the issuer properties for.
//
// Returns:
//  Structure - Contains properties whose content depends on the national specifics.
//              For example, for the Russian Federation:
//     * CommonName         - String - (64) - it is extracted from the CN field - it is an alias of the certificate authority.
//                        - Undefined - such certificate property is missing.
//
//     * Country           - String - (2) - it is extracted from the C field - the two-symbol country code
//                          according to ISO 3166-1:1997 (GOST 7.67-2003).
//                        - Undefined - such certificate property is missing.
//
//     * State           - String - (128) - it is extracted from the S field - it is the RF region name
//                          by the location address of hardware and software complex certificate authority.
//                        - Undefined - such certificate property is missing.
//
//     * Locality  - String - (128) - it is extracted from the L field - the description of the locality
//                          by the location address of hardware and software complex certificate authority.
//                        - Undefined - such certificate property is missing.
//
//     * Street            - String - (128) - it is extracted from the S field - it is the name of the street, house, and office
//                          by the location address of hardware and software complex certificate authority.
//                        - Undefined - such certificate property is missing.
//
//     * Organization      - String - (64) - a full or short name of the company is extracted from the O field.
//                        - Undefined - such certificate property is missing.
//
//     * Department    - String - (64) - extracted from the OU field (a company department).
//                            Department is a territorial structural unit of a large company,
//                            which is not usually filled in the certificate.
//                        - Undefined - such certificate property is missing.
//
//     * Email - String - (128) - it is extracted from the E field. It is an email address of the certificate authority.
//                        - Undefined - such certificate property is missing.
//
//     * OGRN             - String - (13) - extracted from the OGRN field. A certificate authority's registration number.
//                        - Undefined - such certificate property is missing.
//
//     * TIN              - String - (12) - extracted from the INN field - a TIN of the certificate authority company.
//                          LE - not required, but may be present in old certificates.
//                        - Undefined - such certificate property is missing.
//
//     * TINEntity            - String - (10) - extracted from the INNLE field - a TIN of the certificate authority company.
//                          LE - required, but may be absent in old certificates.
//                        - Undefined - such certificate property is missing.
//
Function CertificateIssuerProperties(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.CertificateIssuerProperties(Certificate);
	
EndFunction

// Returns the XML format template containing one standard Signature
// item (see standard https://www.w3.org/TR/xmldsig-core1) 
// with one Reference item and the filled in URI attribute
// (reference to the XML message to be signed).
//
// The returned template contains the %SignatureMethod%, %DigestMethod%,
// %DigestValue%, %SignatureValue%, %BinarySecurityToken% parameters,
// which are automatically filled in upon signing.
// The %SignatureMethod% (signature algorithm in the XML format) and
// %DigestMethod% (hashing algorithm in the XML format) parameters are calculated by
// the public key algorithm of the certificate that is used for signing,
// first by the table specified in the XMLDSigParameters, then
// if the table is not filled in or mapping is not found,
// by the internal mapping table (recommended).
// 
// Templates with multiple Signature and multiple Reference are supported.
// Signing and hashing algorithms GOST 94…2012 are supported.
// Canonicalization algorithms are supported
//
// Exclusive XML Canonicalization 1.0
// http://www.w3.org/2001/10/xml-exc-c14n#
//  http://www.w3.org/2001/10/xml-exc-c14n#WithComments
//   Canonical XML 1.0
//   http://www.w3.org/TR/2001/REC-xml-c14n-20010315
//  http://www.w3.org/TR/2001/REC-xml-c14n-20010315#WithComments
//   Canonical XML 1.1
//   http://www.w3.org/2006/12/xml-c14n11
//  http://www.w3.org/2006/12/xml-c14n11#WithComments
//   Enveloped signature (it is ignored since
//   the empty URI is not supported in the SignedInfo.Reference item)
//  http://www.w3.org/2000/09/xmldsig#enveloped-signature
//  Recommendation SMEV 3.5.0.1, "XML transformation ALGORITHM"
//   urn://smev-gov-ru/xmldsig/transform
//  The certificate can be specified in the KeyInfo as the base64 value:
//   - Either as the X509Data.X509Certificate item
//
// - Or as the KeyInfoReference.Reference item or
// - the SecurityTokenReference.Reference with the URI to an item with a value.
// 
//   
//
// Parameters:
//  Parameters - See DigitalSignatureClient.XMLEnvelopeParameters
//            - Undefined - use the default settings.
//
// Returns:
//  String
//
// Example:
//	EnvelopeParameters = DigitalSignatureClient.XMLEnvelopeParameters();
//	EnvelopeParameters.Option = "furs.mark.crpt.ru_v1";
//	EnvelopeParameters.XMLMessage =
//	"    <getProductDetailsResponse xmlns=""http://warehouse.example.com/ws"">
//	|      <getProductDetailsResult>
//	|       <productID>12345</productID>
//	|       <productName>Faceted glass</productName>
//	|       <description>Faceted glass. 250 ml.</description>
//	|       <price>9.95</price>
//	|       <currency>
//	|         <code>840</code>
//	|         <alpha3>USD</alpha3>
//	|         <sign>$</sign>
//	|         <name>US dollar</name>
//	|         <accuracy>2</accuracy>
//	|       </currency>
//	|       <inStock>true</inStock>
//	|     </getProductDetailsResult>
//	|   </getProductDetailsResponse>";
//	
//	XMLEnvelope = DigitalSignatureClient.XMLEnvelope(Parameters);
//
Function XMLEnvelope(Parameters = Undefined) Export
	
	Return DigitalSignatureInternalClientServer.XMLEnvelope(Parameters);
	
EndFunction

// Returns the parameters that can be set for the XML envelope.
//
// Returns:
//  Structure:
//   * Variant - String - an option of the standard XML template for exchange with a service:
//                 "furs.mark.crpt.ru_v1" (initial value) or "dmdk.goznak.ru_v1".
//                 Other formats are possible if they meet the requirements
//                 specified in the details of the XMLEnvelope function.
//
//   * XMLMessage - String - a message in the XML format that is inserted into the template.
//                             If it is not filled in, the %MessageXML% parameter remains.
//
Function XMLEnvelopeParameters() Export
	
	Return DigitalSignatureInternalClientServer.XMLEnvelopeParameters();
	
EndFunction

// Generates a property structure for configuring the non-standard processing
// of the XML envelope and signing and hashing algorithms.
//
// It is recommended that you do not fill in the XPathSignedInfo and the XPathTagToSign parameters,
// the XPathSignedInfo parameter is calculated using canonicalization algorithms,
// and the XPathTagToSign parameter is calculated by reference
// in the URI attribute of the SignedInfo.Reference item of the XML envelope.
// The parameters are left for backward compatibility. If specified, it works the same way:
// the parameters are not extracted from the XML envelope and they are not controlled, while
// the envelope must contain canonicalization algorithms and have certificate placement
// items, as in the "furs.mark.crpt.ru_v1" envelope option.
//
// It is not required to fill in the algorithms for using certificates
// with public key algorithms GOST 94, GOST 2001, GOST 2012/256, and GOST 2012/512.
// Signing and hashing algorithms are calculated using the public key algorithm
// extracted from the certificate that is used for signing. First
// by the passed table, then if the table is not filled in or mapping
// is not found, by the internal mapping table (recommended).
//
// Returns:
//  Structure:
//   * XPathSignedInfo         - String - By default: "(//. | //@* | //namespace::*)[ancestor-or-self::*[local-name()='SignedInfo']]".
//   * XPathTagToSign   - String - by default: "(//. | //@* | //namespace::*)[ancestor-or-self::soap:Body]".
//
//   * OIDOfPublicKeyAlgorithm - String - for example, "1.2.643.2.2.19" + Chars.LF + "1.2.643.7.1.1.1.1" + …
//   * SIgnatureAlgorithmName        - String - for example, "GOST R 34.10-2001" + Chars.LF + "GOST R 34.11-2012" + …
//   * SignatureAlgorithmOID        - String - for example, 1.2.643.2.2.3" + Chars.LF + "1.2.643.7.1.1.3.2" + …
//   * HashingAlgorithmName    - String - for example, "GOST R 34.11-94" + Chars.LF + "GOST R 34.11-12" + …
//   * HashingAlgorithmOID    - String - for example, "1.2.643.2.2.9" + Chars.LF + "1.2.643.7.1.1.2.2" + …
//   * SignAlgorithm            - String - for example, "http://www.w3.org/2001/04/xmldsig-more#gostr34102001-gostr3411"
//                                      + Chars.LF +
//                                      "urn:ietf:params:xml:ns:cpxmlsec:algorithms:gostr34102012-gostr34112012-256" + …
//   * HashAlgorithm        - String - for example, "http://www.w3.org/2001/04/xmldsig-more#gostr3411"+ Chars.LF +
//                                      "urn:ietf:params:xml:ns:cpxmlsec:algorithms:gostr34112012-256" + …
//
Function XMLDSigParameters() Export
	
	Return DigitalSignatureInternalClientServer.XMLDSigParameters();
	
EndFunction

// Generates property structures to sign data in the CMS format.
// 
// Returns:
//  Structure:
//   * SignatureType                    - String - "CAdES-BES" - other options are not used yet.
//   * DetachedAddIn                  - Boolean -  False (default) - include data in a signature container.
//                                   True - do not include data in a signature container.
//   * IncludeCertificatesInSignature - CryptoCertificateIncludeMode - determines the length of the chain of
//                                   certificates included in the signature. The IncludeChainWithoutRoot value
//                                   is not supported and is considered equal to the IncludeWholeChain value.
//
Function CMSParameters() Export
	
	Return DigitalSignatureInternalClientServer.CMSParameters();
	
EndFunction

#Region WriteCertificateToCatalog1

// Initializes the parameters structure to add a certificate
// to the DigitalSignatureAndEncryptionKeysCertificates catalog.
// To use in the WriteCertificateToCatalog procedure.
//
// Returns:
//   Structure:
//      * Description   - String - Certificate presentation in the list.
//                       By default, "".
//      * User   - CatalogRef.Users - a user who owns the certificate.
//                       The value is used when receiving a list of personal user certificates
//                       in the forms of signing and data encryption.
//                       The default value is Undefined.
//      * Organization    - DefinedType.Organization - a company that owns the certificate.
//                       The default value is Undefined.
//      * Individual - DefinedType.Individual - The individual that owns the certificate.
//                       By default. "Undefined".
//      * Application      - CatalogRef.DigitalSignatureAndEncryptionApplications - Application for signing and encrypting.
//                       By default, Undefined.
//                       
//      * EnterPasswordInDigitalSignatureApplication - Boolean - Flag "Protect digital signature app with password".
//                       True is required if a certificate was installed on the computer with strong private key protection.
//                       Meaning that only a blank password is supported at 1C:Enterprise level.
//                       The password is requested by the operating system, which rejects empty passwords from 1C:Enterprise.
//                       By default, False.
//                       
//
Function CertificateRecordParameters() Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Description", "");
	AdditionalParameters.Insert("User", Undefined);
	AdditionalParameters.Insert("Organization", Undefined);
	AdditionalParameters.Insert("Individual", Undefined);
	AdditionalParameters.Insert("Application", Undefined);
	AdditionalParameters.Insert("EnterPasswordInDigitalSignatureApplication", False);
	
	Return AdditionalParameters;
	
EndFunction

// Checks the certificate and if check is successful, adds a new or updates an existing certificate
// in the DigitalSignatureAndEncryptionKeysCertificates catalog. If the check fails, displays
// information about the errors that have occurred.F
// To add a certificate at the server, see DigitalSignature.WriteCertificateToCatalog.
//
// Parameters:
//   CompletionHandler - CallbackDescription - Called after adding a certificate
//                           to pass the return value of the following types:
//       = Undefined - Error occurred while checking or adding the certificate.
//       = CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - Added certificate.
//   Certificate              - BinaryData - certificate binary data.
//                           - String - binary data of an digital signature certificate or
//                           data address in temporary storage.
//   CertificatePassword       - String - a certificate password for checking private key operations.
//   ToEncrypt           - Boolean - determines components of checks
//                           performed before adding a certificate. If the parameter takes the True value,
//                           encryption and decryption are checked, otherwise signing and signature are checked.
//   AdditionalParameters - Undefined - without additional parameters.
//                           - See CertificateRecordParameters
//
Procedure WriteCertificateToCatalog(CompletionHandler,
	Certificate,
	CertificatePassword,
	ToEncrypt = False,
	AdditionalParameters = Undefined) Export
	
	Context = New Structure;
	Context.Insert("CertificatePassword", CertificatePassword);
	Context.Insert("ToEncrypt", ToEncrypt);
	Context.Insert("AdditionalParameters", ?(AdditionalParameters = Undefined,
		CertificateRecordParameters(), AdditionalParameters));
	Context.Insert("FormCaption", ?(Context.ToEncrypt = True,
		NStr("vi = 'Không thể kiểm tra mã hóa và giải mã';
			|ru = 'Не удалось проверить шифрование и расшифровку';
			|en = 'Cannot check encryption and decryption.'; fa = 'Cannot check encryption and decryption.';
			|it = 'Non è stato possibile verificare codifica e decodifica.';
			|pl = 'Nie udało się sprawdzić szyfrowania i rozszyfrowania';
			|tr = 'Şifreleme ile detaylandırma denetlenemedi'"),
		NStr("vi = 'Không thể kiểm tra cài đặt chữ ký điện tử';
			|ru = 'Не удалось проверить установку электронной подписи';
			|en = 'Cannot check if it is digitally signed.'; fa = 'Cannot check if it is digitally signed.';
			|it = 'Non è stato possibile verificare l''installazione della firma elettronica';
			|pl = 'Nie udało się sprawdzić instalacji podpisu elektronicznego';
			|tr = 'Dijital imzanın kurulumu denetlenemedi'")));
	Context.Insert("ApplicationErrorTitle",
		DigitalSignatureInternalClientServer.CertificateAddingErrorTitle(
			?(Context.ToEncrypt = True, "Encryption", "Signing")));
		
	Context.Insert("CertificateData", Certificate);
	Context.Insert("SignAlgorithm",
		DigitalSignatureInternalClientServer.CertificateSignAlgorithm(Certificate));
		
	If TypeOf(Context.CertificateData) = Type("String")
		And IsTempStorageURL(Context.CertificateData) Then
		
		Context.CertificateData = GetFromTempStorage(Context.CertificateData);
	EndIf;
	
	If CommonSettings().VerifyDigitalSignaturesOnTheServer Then
		
		CertificateRef = DigitalSignatureInternalServerCall.WriteCertificateAfterCheck(Context);
		If CertificateRef <> Undefined Then
			RunCallback(CompletionHandler, CertificateRef);
			Return;
		EndIf;
		
	EndIf;
	
	Context.Insert("CompletionHandler", CompletionHandler);
	
	CreationParameters = DigitalSignatureInternalClient.CryptoManagerCreationParameters();
	CreationParameters.ShowError = Undefined;
	CreationParameters.SignAlgorithm = Context.SignAlgorithm;
	
	DigitalSignatureInternalClient.CreateCryptoManager(
		New CallbackDescription("AddCertificateAfterCreateCryptoManager",
		DigitalSignatureInternalClient, Context), "", CreationParameters);
	
EndProcedure

#EndRegion

#Region InteractiveCertificateAddition

// Initializes a parameter structure for interactively adding a certificate.
// If the CreateApplication parameter is True and the FromPersonalStorage parameter is False, opens a new application
// for certificate issue.
// If the CreateApplication parameter is False and the FromPersonalStorage parameter is True, adds a certificate
// from the Personal store.
// If the CreateApplication parameter is True and the FromPersonalStorage parameter is True, opens a window for
// choosing certificate addition method.
// For usage in DigitalSignatureClient.AddCertificate
//
// Returns:
//   Structure:
//      * ToPersonalList      - Boolean - if the parameter takes the True value, the user attribute
//                           will be filled in by the current user, otherwise the attribute will not be filled in.
//                           The default value is False.
//      * Organization        - DefinedType.Organization - a company that owns the certificate.
//                           The default value is Undefined.
//                           In the case when the parameter is used to create an application, then the value
//                           is passed to the OnFillCompanyAttributesInApplicationForCertificate procedure
//                           of the ApplicationForACertificateOverridable common module without change, and after the call
//                           it cast to the types of the CompanyType property.
//      * CreateRequest   - Boolean - if the parameter takes the True value, adds the ability
//                           to create a new application for certificate issue.
//                           The default value is True.
//      * FromPersonalStorage - Boolean - if the parameter takes the True value, adds the ability to
//                           select a certificate from the installed certificates in the Personal store.
//                           The default value is True.
//      * Individual     - CatalogRef - the individual for whom you need to create an application
//                           for certificate issue (when it is filled in, it has priority over the company).
//                           The default value is Undefined.
//                           The value is passed to the OnFillOwnerAttributesInApplicationForCertificate procedure
//                           of the ApplicationForACertificateOverridable common module without change, and after the call
//                           is cast to the types of the OwnerType property.
//      * IsOnToken           - Boolean - By default, select token in certificate issuance applications.
//
Function CertificateAddingOptions() Export
	
	AddingOptions = New Structure;
	AddingOptions.Insert("ToPersonalList", False);
	AddingOptions.Insert("Organization", Undefined);
	AddingOptions.Insert("CreateRequest", True);
	AddingOptions.Insert("FromPersonalStorage", True);
	AddingOptions.Insert("Individual", Undefined);
	AddingOptions.Insert("IsOnToken", False);
	
	Return AddingOptions;
	
EndFunction

// Interactively adds a certificate from installed on the computer or creates an application for certificate issue.
//
// Parameters:
//   CompletionHandler - CallbackDescription - Called after adding a certificate with a value of one of the following types:
//      = Undefined - Error occurred while checking or adding the certificate.
//      = Structure
//          # Ref - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - Added certificate.
//          # Added - Boolean - Successful addition flag. If a certificate is added
//                      using an application for a new qualified certificate issue, the flag takes
//                      the False value until the application is executed and the certificate is installed on 
//                      the computer.
//   AddingOptions - Undefined - without additional parameters.
//                       - See DigitalSignatureClient.CertificateAddingOptions
//
// Example:
//  1) Adding a certificate from installed in the Personal store:
//  AddingOptions = DigitalSignatureClient.CertificateAddingOptions();
//  AddingOptions.CreateApplication = False;
//  DigitalSignatureClient.AddCertificate(, AddingOptions);
//  
//  2) Creation of an application for certificate issue:
//  AddingOptions = DigitalSignatureClient.CertificateAddingOptions();
//  AddingOptions.FromPersonalStorage = False;
//  DigitalSignatureClient.AddCertificate(, AddingOptions);
//  
//  3) Interactive selection of certificate addition method:
//  DigitalSignatureClient.AddCertificate();
//
Procedure ToAddCertificate(CompletionHandler = Undefined, AddingOptions = Undefined) Export
	
	If AddingOptions = Undefined Then
		AddingOptions = CertificateAddingOptions();
	EndIf;
	
	InteractiveSelectionParameters = New Structure("ToPersonalList, Organization, Individual");
	FillPropertyValues(InteractiveSelectionParameters, AddingOptions);
	
	If Not AddingOptions.CreateRequest
		And Not AddingOptions.FromPersonalStorage Then
		
		Return;
	EndIf;
	
	InteractiveSelectionParameters.Insert("HideApplication",
		AddingOptions.FromPersonalStorage And Not AddingOptions.CreateRequest);
	InteractiveSelectionParameters.Insert("CreateRequest",
		AddingOptions.CreateRequest And Not AddingOptions.FromPersonalStorage);
	If InteractiveSelectionParameters.CreateRequest Then
		InteractiveSelectionParameters.Insert("IsOnToken", AddingOptions.IsOnToken);
	EndIf;
	
	DigitalSignatureInternalClient.ToAddCertificate(InteractiveSelectionParameters, CompletionHandler);
	
EndProcedure

#EndRegion

#Region InterfaceImplementation

// These procedures and functions are intended for integration with 1C:Electronic Document Library.

// Creates and returns the cryptographic manager (on the client) for the specified app or data.
//
// Parameters:
//  Notification     - CallbackDescription - Runtime result notification of the following types:
//                   = CryptoManager - Initialized crypto manager.
//                   = String - Details of the cryptographic manager creation error.
//
//  Operation       - String - if it is not blank, it needs to contain one of rows that determine
//                   the operation to insert into the error description: Signing, SignatureCheck, Encryption,
//                   Decryption, CertificateCheck, and GetCertificates.
//
//  ShowError - Boolean - if True, the ApplicationCallError form will open,
//                   from which you can go to the list of installed apps
//                   in the personal settings form on the "Installed applications" page,
//                   where you can see why the app could not be used,
//                   and open the installation instructions.
//
//  Application      - Undefined - Returns a cryptographic manager for the first app
//                   it was successfully created.
//                 - CatalogRef.DigitalSignatureAndEncryptionApplications - App for which
//                   a crypto manager must be created and returned.
//                 - Structure - See DigitalSignature.NewApplicationDetails.
//                 - BinaryData - DER-encoded data from a signature or certificate used to determine the app.
//                 - String - Address of the binary data in the temp storage.
//
Procedure CreateCryptoManager(Notification, Operation, ShowError = True, Application = Undefined) Export
	
	If TypeOf(Operation) <> Type("String") Then
		Operation = "";
	EndIf;
	
	If ShowError <> True Then
		ShowError = False;
	EndIf;
	
	CreationParameters = DigitalSignatureInternalClient.CryptoManagerCreationParameters();
	CreationParameters.Application = Application;
	CreationParameters.ShowError = ShowError;
	
	DigitalSignatureInternalClient.CreateCryptoManager(Notification, Operation, CreationParameters);
	
EndProcedure

// Finds a certificate on the computer by a thumbprint string.
// For operations using platform tools only (CryptoManager).
//
// Parameters:
//   Notification           - CallbackDescription - a notification about the execution result of the following types:
//     = CryptoCertificate - a found certificate.
//     = Undefined           - the certificate does not exist in the storage.
//     = String                 - a text of the crypto manager creation error (or other error).
//
//   Thumbprint              - String - a Base64 coded certificate thumbprint.
//   InPersonalStorageOnly - Boolean - if True, search in the Personal store, otherwise, search everywhere.
//   ShowError         - Boolean - if False, hide the error text to be returned.
//
Procedure GetCertificateByThumbprint(Notification, Thumbprint, InPersonalStorageOnly, ShowError = True) Export
	
	If TypeOf(ShowError) <> Type("Boolean") Then
		ShowError = True;
	EndIf;
	
	DigitalSignatureInternalClient.GetCertificateByThumbprint(Notification,
		Thumbprint, InPersonalStorageOnly, ShowError);
	
EndProcedure

// Gets certificate thumbprints of the OS user.
// 
// Parameters:
//  Notification     - CallbackDescription - Called for transferring return values of the following types:
//                     Structure:
//                     = Thumbprints - Map - Key: Thumbprint in the Base64 format. Value: Source
//                      "Client", "Server", "Service".
//                      If "ReceivingParameters" type is Boolean, then "Value" is set to "True".
//                     (Intended for backward compatibility.)
//                     = ErrorOnGetCertificatesAtClient - String -  Error text (creation error or another error).
//                     = ErrorGettingCertificatesAtServer - String - Error text (creation error or another error).
//
//  OnlyPersonal   - Boolean - if False, recipient certificates are added to the personal certificates.
//
//  ReceivingParameters - See CertificateThumbprintsReceiptParameters
//                     - Boolean - getting prints only on a computer (for backward compatibility)
//
Procedure GetCertificatesThumbprints(Notification, OnlyPersonal, ReceivingParameters = True) Export
	
	DigitalSignatureInternalClient.GetCertificatesThumbprints(Notification, OnlyPersonal, ReceivingParameters);
	
EndProcedure

// The constructor of parameters for getting certificate thumbprints.
// See GetCertificatesThumbprints.
// 
// Parameters:
//   ClientSide - Boolean, Undefined - Flag indicating whether the cryptography manager creation error should be displayed on the user's computer.
//     If it's set to "Undefined", then receiving OS user certificates on the computer is restricted.
//   ServerSide  - Boolean, Undefined - Flag indicating whether the cryptography manager creation error should be displayed on the server side.
//     If it's set to "Undefined", then receiving OS user certificates on the server is restricted.
//   Service     - Boolean, Undefined - If Boolean, and the setting is enabled, get the OS user certificate thumbprints in the service. 
//     If it's set to "Undefined", then receiving OS user certificates in the service is restricted.
//
// Returns:
//  Structure:
//   * ClientSide - Boolean, Undefined
//   * ServerSide  - Boolean, Undefined
//   * Service     - Boolean, Undefined
//   * ShouldReturnSource - Boolean - Always set to "True". Intended for backward compatibility.
//
Function CertificateThumbprintsReceiptParameters(ClientSide = True, ServerSide = True, Service = True) Export
	
	Structure = New Structure;
	Structure.Insert("ClientSide", ClientSide);
	Structure.Insert("ServerSide", ServerSide);
	Structure.Insert("Service", Service);
	Structure.Insert("ShouldReturnSource", True);
	Return Structure;
	
EndFunction

//  The procedure checks whether the certificate is in the Personal store, its expiration date whether the current user
//  is specified in the certificate or no one is specified, and also that the app for working with the certificate is filled.
//
//  Parameters:
//   Notification - CallbackDescription - Notification with the result of the type:
//     = Array of Structure
//            # Ref - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - Reference to the certificate.
//            # Description - String - Certificate presentation in the list.
//            # Thumbprint - String - Certificate thumbprint in the Base64 string format.
//            # Data - String - Address of a temporary storage that contains certificate binary data.
//            # Company - DefinedType.Company - Company that owns the certificate.
//   Filter - Undefined - use default values for the structure properties that are specified below.
//         - Structure:
//                 * CheckExpirationDate - Boolean - if there is no property, it is True.
//                 * CertificatesWithFilledProgramOnly - Boolean - if there is no property, it is True.
//                         In the query to the catalog, only those certificates are selected
//                         that have the Application field filled in.
//                 * IncludeCertificatesWithBlankUser - Boolean - if there is no property, it is True.
//                         In the query to the catalog, not only those certificates are selected, for which the User field
//                         matches the current user, but also those for which it is not filled.
//                 * Organization - DefinedType.Organization - if there is a property and it is filled in,
//                         only certificates with the Company field that matches
//                         the specified one are selected in the catalog query.
//
Procedure FindValidPersonalCertificates(Notification, Filter = Undefined) Export
	
	FilterTypesArray = New Array;
	FilterTypesArray.Add(Type("Structure"));
	FilterTypesArray.Add(Type("Undefined"));
	
	CommonClientServer.CheckParameter("DigitalSignatureClient.FindValidPersonalCertificates",
		"Filter", Filter, FilterTypesArray);
	
	CommonClientServer.CheckParameter("DigitalSignatureClient.FindValidPersonalCertificates",
		"Notification", Notification, Type("CallbackDescription"));
	
	DigitalSignatureInternalClient.FindValidPersonalCertificates(Notification, Filter);
	
EndProcedure

// Searches for installed apps both on the client and on the server.
// For operations using platform tools only (CryptoManager).
//
// Parameters:
//   Notification - CallbackDescription - Notification with the result of the following type::
//     Array - Contains Structure values with the same properties as DigitalSignature.NewApplicationDetails
//                and the following additional properties:
//       # Set - Boolean - if True, it is specified at the client or at the server.
//       # CheckResultAtClient - String - If blank, then it is specified. Otherwise, contains error details.
//       # CheckResultAtServer - String - If blank, then it is specified. Otherwise, contains error details.
//                                     - Undefined - the check was not performed.
//
//   ApplicationsDetails   - Undefined - check only known apps that are populated with the
//                                 DigitalSignature.FillApplicationsList procedure, if an empty array is passed.
//                      - Array - Contains the same values as returned by DigitalSignature.NewApplicationDetails.
//                                 The specified details will be appended to the built-in details.
//                                 If the new details match the app type or name, the latter will be replaced.
//
//   CheckAtServer1 - Undefined - check at the server if signing or encryption at the server is enabled.
//                      - Boolean - if True check on the server, otherwise do not check
//                                 whether signing or encryption is enabled on the server or not.
//
Procedure FindInstalledPrograms(Notification, ApplicationsDetails = Undefined, CheckAtServer1 = Undefined) Export
	
	If ApplicationsDetails = Undefined Then
		ApplicationsDetails = New Array;
	EndIf;
	
	TypesArrayCheckAtServer = New Array;
	TypesArrayCheckAtServer.Add(Type("Boolean"));
	TypesArrayCheckAtServer.Add(Type("Undefined"));
	
	CommonClientServer.CheckParameter("DigitalSignatureClient.FindInstalledPrograms", "CheckAtServer1", 
		CheckAtServer1, TypesArrayCheckAtServer);
		
	CommonClientServer.CheckParameter("DigitalSignatureClient.FindInstalledPrograms", "Notification", 
		Notification, Type("CallbackDescription"));
		
	CommonClientServer.CheckParameter("DigitalSignatureClient.FindInstalledPrograms", "ApplicationsDetails", 
		ApplicationsDetails, Type("Array"));
	
	DigitalSignatureInternalClient.FindInstalledPrograms(Notification, ApplicationsDetails, CheckAtServer1);
	
EndProcedure

// Checks installed apps and prompts to install apps depending on the passed parameters.
// 
// Parameters:
//  Form - ClientApplicationForm
//  CheckParameters - Undefined, Structure:
//   * ShouldPromptToInstallApp - Boolean - If set to "True", the data processor form opens. 
//      See "DataProcessor.DigitalSignatureAndEncryptionApplications.InstallDigitalSignaturesManagementApps" (if the data processor is present and the list of installed apps is empty).
//      By default "True" if "AppsToCheck" is set to "True" and cloud signatures and cryptographic operations 
//      are not used on the server side. Otherwise, "False" by default.
//   * AppsToCheck - Undefined - (Default value) Returns all the installed apps.
//      - Boolean - See DigitalSignatureClientServerLocalization.AppsRelevantAlgorithms
//      - BInaryData - Signature/certificate data used for looking for suitable apps.
//      - String - Address of the signature/certificate data in a temporary storage.
//      - Array - contains value that are returned by "DigitalSignature.NewApplicationDetails".
//   * SetComponent - Boolean - Flag indicating whether to prompt for installing the add-in
//        that automatically detects installed apps. By default, "True".
//   * ShouldInstallExtension - Boolean - Flag indicating whether to prompt the user for installing the cryptographic extension
//        that automatically detects installed apps. By default, "True".
//   * IsCheckedOnServer - Boolean, Undefined - If set to "Undefined", the check will run on server depending on the general settings.
//                                                 By default, "Undefined".
//  CallbackOnCompletion - CallbackDescription - :
//     Runtime result notification. One of the types
//     = Structure:
//                           # CheckCompleted = Boolean - True if the check was performed on a computer and installed CSP are detected.
//     If False, "Error" is populated with the error details.
//     # Error = String - Error text.
//          # Programs = Array of Structure - Only the apps installed on the client.
//          ## ApplicationName - String - Name of a cryptographic service provider. For example, "Infotecs GOST 2012/512 Cryptographic Service Provider"
//          ## ApplicationType - Number - Type of a cryptographic service provider. For example, "77".
//             ## Name - String - Application presentation as specified in the supplied list.
//          For example, NStr("en = 'ViPNet CSP'; fa = 'ViPNet CSP'").
//          ## Version - String - Library version.
//     ## License - Boolean - License presence flag.
//                                            # ServerApplications = see Programs - Apps passed in the AppsToCheck parameter that were installed on the server.
//     # IsConflictPossible = Boolean - Flag indicating whether a few cryptographic apps are installed,
//     which might conflict with each other.
//     # IsConflictPossibleAtServer = Boolean - Flag indicating whether a few cryptographic apps are installed,
//     which might conflict with each other.
//
Procedure CheckCryptographyAppsInstallation(Form, CheckParameters = Undefined, CallbackOnCompletion = Undefined) Export
	
	DigitalSignatureInternalClient.CheckCryptographyAppsInstallation(Form, CheckParameters, CallbackOnCompletion);
	
EndProcedure

// False if not specified.
// For operations using platform tools only (CryptoManager).
//
// Setting a password allows the user not to enter the password during the next
// operation, which is useful when performing a package of operations.
// If a password is set for the certificate, the RememberPassword check box
// in the DataSigning and DataDecryption forms becomes hidden.
// To cancel the set password, set the password value to Undefined.
//
// Parameters:
//  CertificateReference - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - a certificate
//                        for which password is being set.
//
//  Password           - String - a password to be set. It can be blank.
//                   - Undefined - reset the set password, if any.
//
//  PasswordNote   - Structure - with the note properties under the password instead of the RememberPassword check box:
//     * ExplanationText       - String - - text only.
//     * HyperlinkNote - Boolean - if True, then call ActionProcessing by clicking the note.
//     * ToolTipText       - String
//                            - FormattedString - a text or a text with hyperlinks.
//     * ProcessAction    - CallbackDescription - Calls a procedure, the result of which takes the value of the following type
//        = Structure:
//        # Certificate - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - Reference
//          to the selected certificate.
//                         # Action - String - "NoteClick" or the tooltip URL.
//          
// 
Procedure SetCertificatePassword(CertificateReference, Password, PasswordNote = Undefined) Export
	
	DigitalSignatureInternalClient.SetCertificatePassword(CertificateReference, Password, PasswordNote);
	
EndProcedure

// The function checks whether the password was installed during the session.
// It uses either the SetCertificatePassword procedure,
// or the successful operation with the selected "Save password" checkbox.
//
// Parameters:
//  CertificateReference - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - 
//                        Certificate whose password is being checked.
//
// Returns:
//  Boolean - If False, no password is specified.
//
Function CertificatePasswordIsSet(CertificateReference) Export
	
	Return DigitalSignatureInternalClient.CertificatePasswordIsSet(CertificateReference);
	
EndFunction

// Overrides the usual certificate choice from the catalog to certificate selection
// from the Personal store with password confirmation and automatic addition to the catalog
// if there is no certificate in the catalog yet.
//
// Parameters:
//  Item    - FormField - a form item, where the selected value will be passed.
//  Certificate - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - the current value
//               selected in the Item field required to select the matching list line.
//
//  StandardProcessing - Boolean - Standard parameter of the StartChoice event that needs to be set to False.
//  
//  ToEncryptAndDecrypt - Boolean - manages the choice form title. The initial value is False.
//                              False is to sign, True is to encrypt and decrypt.
//                            - Undefined - to sign and encrypt.
//
Procedure CertificateStartChoiceWithConfirmation(Item, Certificate, StandardProcessing, ToEncryptAndDecrypt = False) Export
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("SelectedCertificate", Certificate);
	FormParameters.Insert("ToEncryptAndDecrypt", ToEncryptAndDecrypt);
	
	DigitalSignatureInternalClient.SelectSigningOrDecryptionCertificate(FormParameters, Item);
	
EndProcedure

// Shows the certificate check result executed in the background mode.
//
// Parameters:
//   Certificate           - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - the certificate
//                        for which a check was executed.
//   Result            - See DigitalSignatureClient.CheckCatalogCertificate.AdditionalParameters.
//   FormOwner        - ClientApplicationForm - the owner of the certificate check form that is being opened.
//   Title            - String - the title of the certificate check form that is being opened.
//   MergeResults - String - determines the method of the check result representation in the client/server
//                        mode when using a digital signature on the server. It can be
//                        DontMerge, MergeByAnd, MergeByOr. If it is 
//                        MergeByAnd or MergeByOr, the check results will be merged with 
//                        the corresponding condition. Otherwise, the results will be displayed
//                        separately for client and server checks.
//   CompletionProcessing  - CallbackDescription - contains details of the procedure that will be called after
//                        closing the certificate check form.
//
Procedure ShowCertificateCheckResult(Certificate, Result, FormOwner,
	Title = "", MergeResults = "DontMerge", CompletionProcessing = Undefined) Export
	
	DigitalSignatureInternalClient.ShowCertificateCheckResult(
		Certificate, Result, FormOwner, Title, MergeResults, CompletionProcessing);
	
EndProcedure

// Gets a root certificate from the certificate data and installs it.
// 
// Parameters:
//  Certificate - BinaryData
//             - String - Address in the temp storage.
//             - String - Certificate's string presentation in the Base64 format
//             - CryptoCertificate
//
Procedure InstallRootCertificate(Certificate) Export
	
	Parameters = DigitalSignatureInternalClient.CertificateInstallationParameters(Certificate);
	DigitalSignatureInternalClient.InstallRootCertificate(Parameters);
	
EndProcedure

// Get signature properties from the binary data without using the cryptographic manager.
// 
// Parameters:
//  Notification - CallbackDescription - Depending on the passed data, returns the structure
//                                   containing signature properties or a Map 
//                                   in case an Array was passed (key is Signature, value is Structure).
//   # Structure: 
//     ## SignatureType - EnumRef.CryptographySignatureTypes, Undefined - Undefined if the passed file is not a signature file.
//     ## LastTimestampValidityPeriod - Date, Undefined - Expiration date of the certificate used for signing the last timestamp.
//                                 It is required only if a cryptographic manager was created successfully. 
//     ## SignatureDateFromTimestamp - Date, Undefined - Earliest timestamp (CADES-T). If it is missing but there are other stamps,
//                                                   the date is populated using the cryptographic manager.
//     ## UnconfirmedSignatureDate - Date - Unconfirmed signature date.
//             - Undefined - Signature data has no unconfirmed signature date.
//     ## Certificates - Array of BinaryDate - Certificates to check.
//     ## Certificate - BinaryDate - Signatory's certificate.
//     ## Thumbprint - String - Certificate thumbprint in the Base64 format.
//     ## CertificateOwner - String - Subject presentation extracted from the certificate binary data. 
//     
//  Signature - BinaryData - DER-encoded certificate data.
//          - String - Address in the temp storage.
//          - Array of String
//          - Array of BinaryData
//  ShouldReadCertificates - Boolean - Flag indicating whether to populate the "Certificate" and "Certificates" properties in the return value.
//
Procedure ReadSignatureProperties(Notification, Signature, ShouldReadCertificates = True) Export

	DigitalSignatureInternalClient.ReadSignatureProperties(Notification, Signature, ShouldReadCertificates);

EndProcedure

// Notifies the user when the certificate is about to expire (unless "Do not remind again" checkbox is selected)
// 
// Parameters:
//  Certificate - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates
//
Procedure NotifyAboutCertificateExpiring(Certificate) Export
	
	Result = DigitalSignatureInternalServerCall.CertificateCustomSettings(Certificate);

	If ValueIsFilled(Result.CertificateRef) And Not Result.IsNotified Then
		
		FormOpenParameters = New Structure("Certificate", Certificate);
		ActionOnClick = New CallbackDescription("OpenNotificationFormNeedReplaceCertificate",
			DigitalSignatureInternalClient, FormOpenParameters);
		ShowUserNotification(NStr("vi = 'Cần thay thế chứng thư';
									|ru = 'Необходима замена сертификата';
									|en = 'You need to reissue the certificate'; fa = 'You need to reissue the certificate';
									|it = 'È necessario sostituire il certificato';
									|pl = 'Jest konieczna wymiana certyfikatu';
									|tr = 'Sertifika değiştirilmelidir'"), ActionOnClick, Certificate,
			PictureLib.DialogExclamation, UserNotificationStatus.Important, Certificate);

	EndIf;
	
EndProcedure

// Returns the properties that were manually entered during the signature verification.
// 
// Parameters:
//  FormOwner - ClientApplicationForm - The owner of the signature manual verification form.
//  Notification - CallbackDescription - Returns the result of updating the signature properties during a manual verification.
//   If input is canceled, it returns "Undefined". Otherwise, returns Structure
//   # IsAdditionalAttributesCheckedManually -:
//    # AdditionalAttributesManualCheckAuthor - See DigitalSignatureClientServer.NewSignatureProperties.
//    # AdditionalAttributesManualCheckJustification - See DigitalSignatureClientServer.NewSignatureProperties.
//    # CheckDate - See DigitalSignatureClientServer.NewSignatureProperties.
//    # SignatureCorrect - See DigitalSignatureClientServer.NewSignatureProperties.
//    # IsVerificationRequired - See DigitalSignatureClientServer.NewSignatureProperties.
//     See DigitalSignatureClientServer.NewSignatureProperties.
//
Procedure EnterSignatureAuthenticityJustification(FormOwner, Notification) Export
	
	ClosingNotification1 = New CallbackDescription("AfterSignatureAuthenticityJustificationEntered", DigitalSignatureInternalClient, Notification);
	OpenForm("InformationRegister.DigitalSignatures.Form.SignatureAuthenticityJustification",,FormOwner,True,,,
		ClosingNotification1, FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Opens the link that navigates to the digital signature errors and their solutions.
// 
//
// Parameters:
//   SearchString - String - The search string.
//
Procedure OpenSearchByErrorsWhenManagingDigitalSignature(SearchString = "") Export
	
	URL = "";
	DigitalSignatureClientServerLocalization.OnDefineRefToSearchByErrorsWhenManagingDigitalSignature(
		URL, SearchString);
	
	If Not IsBlankString(URL) Then
		FileSystemClient.OpenURL(URL);
	EndIf;
	
EndProcedure

// Opens the DS view form.
Procedure OpenSignature(CurrentData) Export
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(CurrentData.SignatureAddress) Then
		
		// StandardSubsystems.MobileSignatureService
		If CommonClient.SubsystemExists("StandardSubsystems.MobileSignatureService")
			And ValueIsFilled(CurrentData.SignatureID) Then
			ModuleMobileSignatureServiceClient = CommonClient.CommonModule("MobileSignatureServiceClient");
			ModuleMobileSignatureServiceClient.OpenSignature(CurrentData);
		EndIf;
		// End StandardSubsystems.MobileSignatureService
	
		Return;
	EndIf;
	
	SignatureProperties = DigitalSignatureClientServer.ResultOfSignatureValidationOnForm();
	FillPropertyValues(SignatureProperties, CurrentData);
	
	FormParameters = New Structure("SignatureProperties", SignatureProperties);
	OpenForm("CommonForm.DigitalSignature", FormParameters);
	
EndProcedure

Procedure OpenRenewalFormActionsSignatures(Form, RenewalOptions, FollowUpHandler = Undefined) Export
	
	OpenForm("CommonForm.RenewDigitalSignatures", RenewalOptions,
		Form,,,,FollowUpHandler, FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

// Opens the RenewDigitalSignatures report form.
// 
// Parameters:
//  ExtensionMode - String - Report options: 
//   UnprocessedSignatures, IsSignatureUpdateRequired, 
//   IsArchiveMarksRequried, AreErrorsOccurredDuringAutomaticRenewal.
//
Procedure OpenReportExtendValidityofElectronicSignatures(ExtensionMode) Export
	
	OpenForm("Report.RenewDigitalSignatures.Form", 
		New Structure("ExtensionMode", ExtensionMode));
	
EndProcedure


// Saves a signature to the computer.
Procedure SaveSignature(SignatureAddress, SignatureFileName = "") Export
	
	DigitalSignatureInternalClient.SaveSignature(SignatureAddress, SignatureFileName);
	
EndProcedure

// Opens the certificate data view form.
//
// Parameters:
//  CertificateData - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - a reference to the certificate.
//                    - CryptoCertificate - an existing certificate.
//                    - BinaryData - certificate binary data.
//                    - String - an address of temporary storage that contains the certificate BinaryData.
//                    - String - a certificate thumbprint to be searched in all storages.
//
//  OpenData     - Boolean - open the certificate data and not the form of catalog item.
//                      If not a reference is passed to the catalog item and the catalog item
//                      could not be found by thumbprint, the certificate data will be opened.
//
Procedure OpenCertificate(CertificateData, OpenData = False) Export
	
	DigitalSignatureInternalClient.OpenCertificate(CertificateData, OpenData);
	
EndProcedure

// It reports the signing once it is completed.
//
// Parameters:
//  DataPresentation - Arbitrary - a reference to the object, to which
//                          digital signature is added.
//  IsPluralForm     - Boolean - determines the type of message and whether there are multiple items
//                          or one item.
//  FromFile             - Boolean - determines the type of message to add
//                          a digital signature or a file.
//
Procedure ObjectSigningInfo(DataPresentation, IsPluralForm = False, FromFile = False) Export
	
	If FromFile Then
		If IsPluralForm Then
			MessageText = NStr("vi = 'Đã thêm chữ ký từ tệp:';
								|ru = 'Добавлены подписи из файлов:';
								|en = 'Signatures from files added:'; fa = 'Signatures from files added:';
								|it = 'Firme aggiunte da file:';
								|pl = 'Dodano sygnatury z plików:';
								|tr = 'Şu dosyalardan imzalar eklendi:'");
		Else
			MessageText = NStr("vi = 'Đã thêm chữ ký từ tệp:';
								|ru = 'Добавлена подпись из файла:';
								|en = 'Signature from file added:'; fa = 'Signature from file added:';
								|it = 'Firma aggiunta da file:';
								|pl = 'Dodano podpis z pliku:';
								|tr = 'Şu dosyadan imza eklendi:'");
		EndIf;
	Else
		If IsPluralForm Then
			MessageText = NStr("vi = 'Đã cài đặt chữ ký:';
								|ru = 'Установлены подписи:';
								|en = 'Digitally signed:'; fa = 'Digitally signed:';
								|it = 'Firme installate:';
								|pl = 'Zainstalowane sygnatury:';
								|tr = 'İmzalar ayarlandı:'");
		Else
			MessageText = NStr("vi = 'Đã cài đặt chữ ký:';
								|ru = 'Установлены подписи:';
								|en = 'Digitally signed:'; fa = 'Digitally signed:';
								|it = 'Firme installate:';
								|pl = 'Zainstalowane sygnatury:';
								|tr = 'İmzalar ayarlandı:'");
		EndIf;
	EndIf;
	
	ShowUserNotification(MessageText, , DataPresentation);
	
EndProcedure

// Reports completion at the end of encryption.
//
// Parameters:
//  DataPresentation - Arbitrary - a reference to an object
//                          whose data is encrypted.
//  IsPluralForm     - Boolean - determines the type of message and whether there are multiple items
//                          or one item.
//
Procedure InformOfObjectEncryption(DataPresentation, IsPluralForm = False) Export
	
	MessageText = NStr("vi = 'Đã thực hiện mã hóa';
						|ru = 'Выполнено шифрование:';
						|en = 'Encrypted:'; fa = 'Encrypted:';
						|it = 'Crittografia eseguita:';
						|pl = 'Wykonano szyfrowanie:';
						|tr = 'Şifreleme tamamlandı:'");
	
	ShowUserNotification(MessageText, , DataPresentation);
	
EndProcedure

// Reports completion at the end of decryption.
//
// Parameters:
//  DataPresentation - Arbitrary - a reference to an object
//                          whose data is decrypted.
//  IsPluralForm     - Boolean - determines the type of message and whether there are multiple items
//                          or one item.
//
Procedure InformOfObjectDecryption(DataPresentation, IsPluralForm = False) Export
	
	MessageText = NStr("vi = 'Đã thực hiện giải mã:';
						|ru = 'Выполнена расшифровка:';
						|en = 'Decrypted:'; fa = 'Decrypted:';
						|it = 'Decrittografia eseguita:';
						|pl = 'Wykonywane dekodowanie:';
						|tr = 'Detaylandırma yapıldı:'");
	
	ShowUserNotification(MessageText, , DataPresentation);
	
EndProcedure

// See DigitalSignature.PersonalSettings.
Function PersonalSettings() Export
	
	Return StandardSubsystemsClient.ClientRunParameters().DigitalSignature.PersonalSettings;
	
EndFunction

#EndRegion

#Region Private

// See DigitalSignature.CommonSettings.
Function CommonSettings() Export
	
	Return StandardSubsystemsClient.ClientRunParameters().DigitalSignature.CommonSettings;
	
EndFunction

#EndRegion
