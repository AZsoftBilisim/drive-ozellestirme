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

// Returns True if the configuration supports sending signatures to the mobile service and the setting is enabled.
//
// Returns:
//  Boolean
//
Function UseMobileSignatureService() Export
	
	Used = False;
	DigitalSignatureLocalization.OnRetrieveMobileServiceUsageSettings(Used);
	Return Used;
	
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

// Verifies that digital signing web services are enabled for the application.
// Parameters:
//  ShowError - Boolean - Raise an exception.
// 
// Returns:
//  Boolean
//
Function AccessToInternetServicesAllowed(ShowError = False) Export
	
	AccessToInternetServicesAllowed = Common.AccessToInternetServicesAllowed(ShowError);
	
	SetPrivilegedMode(True);
	AllowAccessToDigitalSignatureInternetServices = Constants.AllowAccessToDigitalSignatureInternetServices.Get();
	SetPrivilegedMode(False);
	
	IsInternetDownloadAllowed = AccessToInternetServicesAllowed And AllowAccessToDigitalSignatureInternetServices;
	
	If Not IsInternetDownloadAllowed And ShowError Then
		Raise DigitalSignatureInternalClientServer.AccessToInternetServicesDeniedMessageText();
	EndIf;
	
	Return IsInternetDownloadAllowed;
	
EndFunction

// Gets object signatures and returns them.
//
// Parameters:
//  Object - DefinedType.SignedObject - Reference to the signed object.
//             The object must have the "SignedWithDS" attribute.
//
//  AdditionalParameters - See NewObjectSignaturesAcquisitionParameters
//
// Returns:
//  Array of See DigitalSignatureClientServer.NewSignatureProperties 
//
Function ObjectSignatures(Object, AdditionalParameters = Undefined) Export
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = NewObjectSignaturesAcquisitionParameters();
	EndIf;
	
	CheckParameterObject(Object, "DigitalSignature.ObjectSignatures", True);
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.CheckReadAllowed(Object);
	EndIf;
	
	If Common.IsReference(TypeOf(Object)) Then
		ObjectRef = Object;
	Else
		ObjectRef = Object.Ref;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	DigitalSignatures.Signature AS Signature,
		|	DigitalSignatures.SequenceNumber AS SequenceNumber,
		|	DigitalSignatures.SignatureSetBy AS SignatureSetBy,
		|	DigitalSignatures.Comment AS Comment,
		|	DigitalSignatures.SignatureDate AS SignatureDate,
		|	DigitalSignatures.SignatureValidationDate AS SignatureValidationDate,
		|	DigitalSignatures.SignatureCorrect AS SignatureCorrect,
		|	DigitalSignatures.Thumbprint AS Thumbprint,
		|	DigitalSignatures.CertificateOwner AS CertificateOwner,
		|	DigitalSignatures.SignatureType AS SignatureType,
		|	DigitalSignatures.IsVerificationRequired AS IsVerificationRequired,
		|	DigitalSignatures.DateActionLastTimestamp AS DateActionLastTimestamp,
		|	DigitalSignatures.SignatureID AS SignatureID,
		|	DigitalSignatures.IsSignatureMathematicallyValid,
		|	DigitalSignatures.SignatureMathValidationError,
		|	DigitalSignatures.AdditionalAttributesCheckError,
		|	DigitalSignatures.IsAdditionalAttributesCheckedManually,
		|	DigitalSignatures.AdditionalAttributesManualCheckAuthor,
		|	DigitalSignatures.AdditionalAttributesManualCheckJustification
		|FROM
		|	InformationRegister.DigitalSignatures AS DigitalSignatures
		|WHERE
		|	DigitalSignatures.SignedObject = &SignedObject
		|	AND DigitalSignatures.SequenceNumber IN (&SequenceNumber)
		|
		|ORDER BY
		|	SequenceNumber";
	
	Query.SetParameter("SignedObject", ObjectRef);
	
	If AdditionalParameters.SequenceNumber = Undefined Then
		Query.Text = StrReplace(Query.Text, "AND DigitalSignatures.SequenceNumber IN (&SequenceNumber)", "");
	Else
		Query.SetParameter("SequenceNumber", AdditionalParameters.SequenceNumber);
	EndIf;
	
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	
	// StandardSubsystems.MachineReadableLettersOfAuthority
	SelectionMRLOADetailedRecords = Undefined;
	
	If Not QueryResult.IsEmpty() And AdditionalParameters.ShouldReturnMachineReadableLOAData
		And Common.SubsystemExists("StandardSubsystems.MachineReadableLettersOfAuthority") Then
		
		SignaturesIDs = New Array;
		While SelectionDetailRecords.Next() Do
			SignaturesIDs.Add(SelectionDetailRecords.SignatureID);
		EndDo;
		SelectionDetailRecords.Reset();
		
		ModuleMachineReadableLettersOfAuthorityFTSInternal = Common.CommonModule("MachineReadableLettersOfAuthorityFTSInternal");
		SelectionMRLOADetailedRecords = ModuleMachineReadableLettersOfAuthorityFTSInternal.MRLOAOfSignatures(ObjectRef, SignaturesIDs);
		
	EndIf;
	// End StandardSubsystems.MachineReadableLettersOfAuthority
	
	SignatureFilesExtension = PersonalSettings().SignatureFilesExtension;
	Result = New Array;
	While SelectionDetailRecords.Next() Do
		
		SignatureProperties = DigitalSignatureClientServer.NewSignatureProperties();
		SignatureProperties.SignedObject = Object;
		FillPropertyValues(SignatureProperties, SelectionDetailRecords);
		SignatureProperties.Signature = SignatureProperties.Signature.Get();
		
		SignedObjectName = Common.ObjectAttributeValue(ObjectRef, "Description");
		SignatureProperties.SignatureFileName = DigitalSignatureClientServer.SignatureFileName(SignedObjectName,
			SelectionDetailRecords.CertificateOwner, SignatureFilesExtension);
			
		ReturnTimestampDate = AdditionalParameters.ReturnTimestampDate
			And SelectionDetailRecords.SignatureType <> Enums.CryptographySignatureTypes.NormalCMS 
			And SelectionDetailRecords.SignatureType <> Enums.CryptographySignatureTypes.BasicCAdESBES;
		
		If (AdditionalParameters.ShouldExtractCertificatesFromSignatures 
			Or ReturnTimestampDate)
			And ValueIsFilled(SignatureProperties.Signature) Then
			
			ExtendedSignatureProperties = DigitalSignatureInternal.SignaturePropertiesFromBinaryData(SignatureProperties.Signature,
				AdditionalParameters.ShouldExtractCertificatesFromSignatures);
			SignatureProperties.Certificate = ExtendedSignatureProperties.Certificate;
			SignatureProperties.DateSignedFromLabels = ExtendedSignatureProperties.DateSignedFromLabels;
			
			If (AdditionalParameters.ShouldExtractCertificatesFromSignatures
				And ExtendedSignatureProperties.Certificate = Undefined
				Or ReturnTimestampDate And ExtendedSignatureProperties.DateSignedFromLabels = Undefined)
				And DigitalSignatureInternal.IsCryptographyAvailable() Then
					
				// If the signature is not linked to the certificate, try to retrieve the certificate from the signature container.
				CreationParameters = DigitalSignatureInternal.CryptoManagerCreationParameters();
				CreationParameters.SignAlgorithm =
					DigitalSignatureInternalClientServer.GeneratedSignAlgorithm(SignatureProperties.Signature);
				
				CryptoManager = DigitalSignatureInternal.CryptoManager("ReadSignature", CreationParameters);
				If CryptoManager <> Undefined Then
					
					IsContainerReceived = False;
					Try
						ContainerSignatures = CryptoManager.GetCryptoSignaturesContainer(SignatureProperties.Signature);
						IsContainerReceived = True;
					Except
						WriteLogEvent(
							NStr("vi = 'Chữ ký điện tử.Nhận nơi chứa chữ ký';
								|ru = 'Электронная подпись.Получение контейнера подписи';
								|en = 'Digital signature.Get signature container'; fa = 'Digital signature.Get signature container';
								|it = 'Digital signature.Get signature container';
								|pl = 'Digital signature.Get signature container';
								|tr = 'Dijital imza. İmza kapsayıcısının alınması'",
								Common.DefaultLanguageCode()),
							EventLogLevel.Error, , ,
							ErrorProcessing.DetailErrorDescription(ErrorInfo()));
					EndTry;
					
					If IsContainerReceived Then
						SignatureParameters = DigitalSignatureInternal.ParametersCryptoSignatures(
							ContainerSignatures, DigitalSignatureInternal.UTCOffset(), CurrentSessionDate());
						
						If AdditionalParameters.ShouldExtractCertificatesFromSignatures Then
							Certificate = SignatureParameters.Certificate;
							If DigitalSignatureInternalClientServer.IsCertificateExists(Certificate) Then
								SignatureProperties.Certificate = Certificate.Unload();
							EndIf;
						EndIf;
						If ReturnTimestampDate Then
							SignatureProperties.DateSignedFromLabels = SignatureParameters.DateSignedFromLabels;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		
		// StandardSubsystems.MachineReadableLettersOfAuthority
		If SelectionMRLOADetailedRecords <> Undefined Then
			ModuleMachineReadableLettersOfAuthorityFTSInternal.FillInMRLOASignatureDetails(SignatureProperties, SelectionMRLOADetailedRecords);
		EndIf;
		// End StandardSubsystems.MachineReadableLettersOfAuthority
		
		Result.Add(SignatureProperties);
		
	EndDo;
	
	// StandardSubsystems.MobileSignatureService
	If AdditionalParameters.ShouldReturnExpectedSignatures 
		And Common.SubsystemExists("StandardSubsystems.MobileSignatureService")Then
		ModuleMobileSignatureServiceInternal = Common.CommonModule("MobileSignatureServiceInternal");
		ModuleMobileSignatureServiceInternal.AddExpectedObjectSignatures(Object, Result);
	EndIf;
	// End StandardSubsystems.MobileSignatureService
	
	Return Result;
	
EndFunction

// Adds a signature to an object and writes it.
// Sets the True value for the SignedWithDS attribute.
// 
// Parameters:
//  Object - DefinedType.SignedObject - an object will be received,
//               locked, changed, or written by reference. The object must have the SignedWithDS attribute.
//           Or immediately pass an object of the type specified above, then it
//           will be changed without locking and writing.
//
//  SignatureProperties - String - a temporary storage address that contains the structure described below.
//                  - Structure - See DigitalSignatureClientServer.NewSignatureProperties.
//                  - Array of String
//                  - Array of See DigitalSignatureClientServer.NewSignatureProperties.
//
//  FormIdentifier - UUID - a form ID that is used for lock
//                       if an object reference is passed.
//
//  ObjectVersion      - String - an object data version, if an object reference is passed that is used 
//                       to lock an object before writing it, considering that signing
//                       is performed on the client and the object could be changed during it.
//
//  WrittenObject   - Arbitrary - an object that was received and written if a reference was passed.
//
Procedure AddSignature(Object, Val SignatureProperties, FormIdentifier = Undefined,
			ObjectVersion = Undefined, WrittenObject = Undefined) Export
	
	CheckParameterObject(Object, "DigitalSignature.AddSignature");
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.CheckChangeAllowed(Object);
	EndIf;
	
	If TypeOf(SignatureProperties) = Type("String") Then
		SignatureProperties = GetFromTempStorage(SignatureProperties);
		
	ElsIf TypeOf(SignatureProperties) = Type("Array") Then
		LastItemIndex = SignatureProperties.Count()-1;
		For IndexOf = 0 To LastItemIndex Do
			If TypeOf(SignatureProperties[IndexOf]) = Type("String") Then
				SignatureProperties[IndexOf] = GetFromTempStorage(SignatureProperties[IndexOf]);
			EndIf;
		EndDo;
	EndIf;
	
	IsReference = Common.IsReference(TypeOf(Object));
	
	BeginTransaction();
	Try
		
		If IsReference Then
			LockDataForEdit(Object, ObjectVersion, FormIdentifier);
			DataObject = Object.GetObject();
		Else
			DataObject = Object;
		EndIf;
		
		Block = New DataLock;
		LockItem = Block.Add(DataObject.Metadata().FullName());
		LockItem.SetValue("Ref", DataObject.Ref);
		
		Block.Lock();
		
		EventLogMessage = "";
		
		AddSignatureRows(DataObject, SignatureProperties, EventLogMessage);
		
		If Not DataObject.SignedWithDS
		   And (TypeOf(SignatureProperties) <> Type("Array")
		      Or SignatureProperties.Count() > 0) Then
			
			DataObject.SignedWithDS = True;
		EndIf;
		
		If IsReference Then
			// To determine that this is a record to add or remove a signature.
			DataObject.AdditionalProperties.Insert("WriteSignedObject", True);
			If DataObject.Modified() Then
				DataObject.Write();
			EndIf;
			UnlockDataForEdit(Object.Ref, FormIdentifier);
			WrittenObject = DataObject;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		ErrorInfo = ErrorInfo();
		If ValueIsFilled(EventLogMessage) Then
			WriteLogEvent(
				NStr("vi = 'Chữ ký điện tử.Lỗi thêm chữ ký';
					|ru = 'Электронная подпись.Ошибка добавления подписи';
					|en = 'Digital signature. An error occurred while adding a signature'; fa = 'Digital signature. An error occurred while adding a signature';
					|it = 'Firma elettronica. Errore durante l''aggiunta della firma';
					|pl = 'Podpis elektroniczny.Błąd dodawania podpisu';
					|tr = 'Dijital imza.İmza ekleme hatası'", Common.DefaultLanguageCode()),
				EventLogLevel.Information,
				Object.Metadata(),
				Object.Ref,
				EventLogMessage + "
				|
				|" + ErrorProcessing.BriefErrorDescription(ErrorInfo));
		EndIf;
		Raise;
	EndTry;
	
EndProcedure

// Updates an object signature.
// 
// Parameters:
//  Object - DefinedType.SignedObject - - a reference to a signed object
//             to refresh a signature for.
//
//  SignatureProperties - String - a temporary storage address that contains the structure described below.
//                  - Structure - See DigitalSignatureClientServer.NewSignatureProperties.
//  UpdateByOrderNumber - Boolean - Flag indicating whether to update the signature by its sequence number
//                                as the binary data was changed upon enhancement. By default, False.
//
Procedure UpdateSignature(Object, Val SignatureProperties, UpdateByOrderNumber = False) Export
	
	CheckParameterObject(Object, "DigitalSignature.UpdateSignature", True);
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.CheckChangeAllowed(Object);
	EndIf;
	
	If TypeOf(SignatureProperties) = Type("String") Then
		SignatureProperties = GetFromTempStorage(SignatureProperties);
	EndIf;
	
	SetPrivilegedMode(True);
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.DigitalSignatures");
	LockItem.SetValue("SignedObject", Object);
	// StandardSubsystems.MachineReadableLettersOfAuthority
	If Common.SubsystemExists("StandardSubsystems.MachineReadableLettersOfAuthority") Then
		ModuleMachineReadableLettersOfAuthorityFTSInternal = Common.CommonModule(
			"MachineReadableLettersOfAuthorityFTSInternal");
		ModuleMachineReadableLettersOfAuthorityFTSInternal.AddBlock(Block, Object);
	EndIf;
	// End StandardSubsystems.MachineReadableLettersOfAuthority
	
	BeginTransaction();
	Try
		Block.Lock();
		If UpdateByOrderNumber Then
			SignaturesAcquisitionParameters = NewObjectSignaturesAcquisitionParameters();
			SignaturesAcquisitionParameters.SequenceNumber = SignatureProperties.SequenceNumber;
			ObjectSignatures = ObjectSignatures(Object, SignaturesAcquisitionParameters);
		Else
			ObjectSignatures = ObjectSignatures(Object);
		EndIf;
		For Each ObjectSignature In ObjectSignatures Do
			SignatureBinaryData = ObjectSignature.Signature;
			ResultOfSignatureVerificationByMRLOA = Undefined;
			If UpdateByOrderNumber And ObjectSignature.SequenceNumber = SignatureProperties.SequenceNumber 
				// If binary data matches, the signature must be refreshed.
				Or SignatureBinaryData = SignatureProperties.Signature Then
					
				RecordSet = InformationRegisters.DigitalSignatures.CreateRecordSet();
				RecordSet.Filter.SequenceNumber.Set(SignatureProperties.SequenceNumber);
				RecordSet.Filter.SignedObject.Set(Object);
				RecordSet.AdditionalProperties.Insert("SignatureUpdate");
				RecordSet.Read();
				
				SignatureToRefresh = RecordSet[0];
				
				If UpdateByOrderNumber Then
					For Each KeyAndValue In SignatureProperties Do
						If KeyAndValue.Key = "Certificate"
							Or KeyAndValue.Key = "SignedObject"
							Or KeyAndValue.Key = "SignatureDate"
							Or KeyAndValue.Key = "DateSignedFromLabels"
							Or KeyAndValue.Key = "SequenceNumber"
							Or KeyAndValue.Key = "CertificateDetails"
							Or KeyAndValue.Key = "SignatureID"
							Or KeyAndValue.Key = "SignatureFileName" Then
							Continue;
						EndIf;
						
						If KeyAndValue.Key = "ResultOfSignatureVerificationByMRLOA" Then
							If ValueIsFilled(KeyAndValue.Value) Then
								ResultOfSignatureVerificationByMRLOA = KeyAndValue.Value;
							EndIf;
							Continue;
						EndIf;
						
						If KeyAndValue.Value <> Undefined Then
							If KeyAndValue.Key = "Signature" Then
								SignatureToRefresh.Signature = New ValueStorage(KeyAndValue.Value,
									New Deflation(9));
							Else
								SignatureToRefresh[KeyAndValue.Key] = KeyAndValue.Value;
							EndIf;
						EndIf;
					EndDo;
				Else
					
					For Each KeyAndValue In SignatureProperties Do
						If KeyAndValue.Key = "Certificate"
							Or KeyAndValue.Key = "Signature"
							Or KeyAndValue.Key = "CertificateDetails"
							Or KeyAndValue.Key = "DateSignedFromLabels"
							Or KeyAndValue.Key = "SignatureFileName" 
							Or KeyAndValue.Key = "SignatureID"
								And ValueIsFilled(SignatureToRefresh.SignatureID) Then
							Continue;
						EndIf;
						
						If KeyAndValue.Key = "ResultOfSignatureVerificationByMRLOA" Then
							If ValueIsFilled(KeyAndValue.Value) Then
								ResultOfSignatureVerificationByMRLOA = KeyAndValue.Value;
							EndIf;
							Continue;
						EndIf;
						
						If KeyAndValue.Value <> Undefined Then
							SignatureToRefresh[KeyAndValue.Key] = KeyAndValue.Value;
						EndIf;
					EndDo;
					
				EndIf;
				
				RecordSet.Write(True);
			EndIf;
				
			// StandardSubsystems.MachineReadableLettersOfAuthority
			If ValueIsFilled(ResultOfSignatureVerificationByMRLOA) And Common.SubsystemExists(
				"StandardSubsystems.MachineReadableLettersOfAuthority") Then
		
				ModuleMachineReadableLettersOfAuthorityFTSInternal.UpdateMachineReadableSignatureAuthorizationLetter(
					Object, SignatureToRefresh.SignatureID, ResultOfSignatureVerificationByMRLOA);

			EndIf;
			// End StandardSubsystems.MachineReadableLettersOfAuthority
			
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Deletes an object signature and writes it.
// 
// Parameters:
//  Object - DefinedType.SignedObject - an object will be received,
//               locked, changed, or written by reference. The object must have the SignedWithDS attribute.
//           Or immediately pass an object of the type specified above, then it
//           will be changed without locking and writing.
// 
//  SequenceNumber      - Number - a signature sequence number.
//                       - UUID - ID of the pending signature.
//                       - Array - values of the type specified above.
//
//  FormIdentifier - UUID - a form ID that is used for lock
//                       if an object reference is passed.
//
//  ObjectVersion      - String - an object data version, if an object reference is passed that is used 
//                       to lock an object before writing it, considering that signing
//                       is performed on the client and the object could be changed during it.
//
//  WrittenObject   - Arbitrary - an object that was received and written if a reference was passed.
//
Procedure DeleteSignature(Object, SequenceNumber, FormIdentifier = Undefined,
			ObjectVersion = Undefined, WrittenObject = Undefined) Export
	
	CheckParameterObject(Object, "DigitalSignature.DeleteSignature");
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.CheckChangeAllowed(Object);
	EndIf;
	
	IsReference = Common.IsReference(TypeOf(Object));
	BeginTransaction();
	Try
		If IsReference Then
			LockDataForEdit(Object, ObjectVersion, FormIdentifier);
			DataObject = Object.GetObject();
		Else
			DataObject = Object;
		EndIf;
		
		Block = New DataLock;
		LockItem = Block.Add(DataObject.Metadata().FullName());
		LockItem.SetValue("Ref", DataObject.Ref);
		Block.Lock();
		
		EventLogMessage = "";
		
		If TypeOf(SequenceNumber) = Type("Array") Then
			ArrayForDelete = SequenceNumber;
		Else
			ArrayForDelete = CommonClientServer.ValueInArray(SequenceNumber);
		EndIf;

		SequenceNumbers = New Array;
		ExpectedSignaturesIDs = New Array;
		For Each Number In ArrayForDelete Do
			If TypeOf(Number) = Type("UUID") Then
				ExpectedSignaturesIDs.Add(Number);
			Else
				SequenceNumbers.Add(Number);
			EndIf;
		EndDo;
		
		DeleteSignatureRows(DataObject, SequenceNumbers, ExpectedSignaturesIDs, EventLogMessage);
		RefreshSignaturesNumbering(DataObject, SequenceNumbers);
		
		If IsReference Then
			// To determine that this is a record to add or remove a signature.
			DataObject.AdditionalProperties.Insert("WriteSignedObject", True);
			If DataObject.Modified() Then
				DataObject.Write();
			EndIf;
			UnlockDataForEdit(Object.Ref, FormIdentifier);
			WrittenObject = DataObject;
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		ErrorInfo = ErrorInfo();
		If ValueIsFilled(EventLogMessage) Then
			WriteLogEvent(
				NStr("vi = 'Chữ ký điện tử.Lỗi xóa chữ ký';
					|ru = 'Электронная подпись.Ошибка удаления подписи';
					|en = 'Digital signature.Signature deletion error'; fa = 'Digital signature.Signature deletion error';
					|it = 'Firma elettronica. Errore durante la cancellazione della firma';
					|pl = 'Podpis elektroniczny.Błąd usunięcia podpisu';
					|tr = 'Dijital imza.İmza silme hatası'", Common.DefaultLanguageCode()),
				EventLogLevel.Information,
				Object.Metadata(),
				Object.Ref,
				EventLogMessage + "
				|
				|" + ErrorProcessing.BriefErrorDescription(ErrorInfo));
		EndIf;
		Raise;
	EndTry;
	
EndProcedure

// Returns encryption certificates for the given object.
//
// Parameters:
//  Object - DefinedType.SignedObject - a reference to the encrypted object.
//
// Returns:
//   Array of Structure:
//     * Thumbprint - String
//     * Presentation - String
//     * Certificate - BinaryData
//     * SequenceNumber - Number
//
Function EncryptionCertificates(Object) Export
	
	CheckParameterObject(Object, "DigitalSignature.EncryptionCertificates", True);
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.CheckReadAllowed(Object);
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	EncryptionCertificates.Presentation,
		|	EncryptionCertificates.Thumbprint,
		|	EncryptionCertificates.Certificate,
		|	EncryptionCertificates.SequenceNumber AS SequenceNumber
		|FROM
		|	InformationRegister.EncryptionCertificates AS EncryptionCertificates
		|WHERE
		|	EncryptionCertificates.EncryptedObject = &EncryptedObject
		|
		|ORDER BY
		|	SequenceNumber";
	
	Query.SetParameter("EncryptedObject", Object);
	
	Selection = Query.Execute().Select();
	Result = New Array;
	While Selection.Next() Do
		ThumbprintStructure = New Structure;
		ThumbprintStructure.Insert("Thumbprint",       Selection.Thumbprint);
		ThumbprintStructure.Insert("Presentation",   Selection.Presentation);
		ThumbprintStructure.Insert("Certificate",      Selection.Certificate.Get());
		ThumbprintStructure.Insert("SequenceNumber", Selection.SequenceNumber);
		Result.Add(ThumbprintStructure);
	EndDo;
	
	Return Result;

EndFunction

// Places encryption certificates to the information register and writes an object.
// Sets the Encrypted attribute by the presence of certificates in the EncryptionCertificate information register.
// 
// Parameters:
//  Object - DefinedType.SignedObject - an object will be received,
//               locked, changed, or written by reference. The object must have the Encrypted attribute.
//           Or immediately pass an object of the type specified above, then it
//           will be changed without locking and writing.
//
//  EncryptionCertificates - String - a temporary storage address that contains the array described below.
//                        - Array - Array of the following structures:
//                             * Thumbprint     - String - a certificate thumbprint in the Base64 string format.
//                             * Presentation - String - a saved subject presentation
//                                                  got from certificate binary data.
//                             * Certificate    - BinaryData - contains export of the certificate
//                                                  that was used for encryption.
//
//  FormIdentifier - UUID - a form ID that is used for lock
//                       if an object reference is passed.
//
//  ObjectVersion      - String - an object data version, if an object reference is passed that is used 
//                       to lock an object before writing it, considering that signing
//                       is performed on the client and the object could be changed during it.
//
//  WrittenObject   - Arbitrary - an object that was received and written if a reference was passed.
//
Procedure WriteEncryptionCertificates(Object, Val EncryptionCertificates, FormIdentifier = Undefined,
	ObjectVersion = Undefined, WrittenObject = Undefined) Export
	
	CheckParameterObject(Object, "DigitalSignature.WriteEncryptionCertificates", False);
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.CheckChangeAllowed(Object);
	EndIf;
	
	IsReference = Common.IsReference(TypeOf(Object));
	ObjectRef = ?(IsReference, Object, Object.Ref);
	
	If TypeOf(EncryptionCertificates) = Type("String") Then
		EncryptionCertificates = GetFromTempStorage(EncryptionCertificates);
	EndIf;
	
	BeginTransaction();
	Try
		If IsReference Then
			LockDataForEdit(ObjectRef, ObjectVersion, FormIdentifier);
			DataObject = Object.GetObject();// CatalogObject, DocumentObject, ChartOfCharacteristicTypesObject, ChartOfAccountsObject, ChartOfCalculationTypesObject 
		Else
			DataObject = Object;
		EndIf;
		
		SetPrivilegedMode(True);
		RecordSet = InformationRegisters.EncryptionCertificates.CreateRecordSet();
		RecordSet.Filter.EncryptedObject.Set(DataObject.Ref);
		SequenceNumber = 1;
		For Each EncryptionCertificate In EncryptionCertificates Do
			NewCertificate = RecordSet.Add();
			NewCertificate.EncryptedObject = DataObject.Ref;
			FillPropertyValues(NewCertificate, EncryptionCertificate);
			NewCertificate.Certificate = New ValueStorage(EncryptionCertificate.Certificate, New Deflation(9));
			NewCertificate.SequenceNumber = SequenceNumber;
			SequenceNumber = SequenceNumber + 1;
		EndDo;
		
		DataObject.Encrypted = RecordSet.Count() > 0;
		
		RecordSet.Write();
		If IsReference Then
			UnlockDataForEdit(ObjectRef, FormIdentifier);
			WrittenObject = DataObject;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Returns the date extracted from the signature binary data or Undefined.
//
// Parameters:
//  Signature - BinaryData - Signature data to extract a date from.
//  CastToSessionTimeZone - Boolean - Cast the universal time to the session time.
//
// Returns:
//  Date - Successfully extracted signature date.
//  Undefined - Failed to extract date from the signature data.
//
Function SigningDate(Signature, CastToSessionTimeZone = True) Export
	
	SigningDate = DigitalSignatureInternalClientServer.SigningDateUniversal(Signature);
	
	If SigningDate = Undefined Then
		Return Undefined;
	EndIf;
	
	If CastToSessionTimeZone Then
		SigningDate = ToLocalTime(SigningDate, SessionTimeZone());
	EndIf;
	
	Return SigningDate;
	
EndFunction

// Returns a reference to the certificate by the passed binary data or thumbprint.
//
// Parameters:
//  Certificate - CryptoCertificate - a certificate.
//             - BinaryData - certificate binary data.
//             - String - String (28), a certificate thumbprint in the Base64 format.
//             - String - an address of a temporary storage that contains certificate binary data.
//
// Returns:
//  CatalogRef.DigitalSignatureAndEncryptionKeysCertificates
//  Undefined - Certificate does not exist in the catalog.
//
Function CertificateRef(Val Certificate) Export
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED TOP 1
	|	Certificates.Ref AS Ref
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
	|WHERE
	|	Certificates.Thumbprint = &Thumbprint";
	Query.SetParameter("Thumbprint", CertificateThumbprint(Certificate));
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Ref;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Returns references to the certificates by the passed binary data or thumbprint.
//
// Parameters:
//  Certificates - Array of CryptoCertificate
//              - Array of BinaryData - Binary data of the certificates.
//              - Array of String - String (28), certificate thumbprints in the Base64 format.
//              - Array of String - Addresses in the temporary storage that contain the binary data of the certificates.
//  ShouldReturnNonExistent - Boolean - If set to "True", the returned values include empty references to the certificates
//               missing from the catalog "DigitalSignatureAndEncryptionKeysCertificates".
//
// Returns:
//  Array of CatalogRef.DigitalSignatureAndEncryptionKeysCertificates
//  
Function RefsToCertificates(Val Certificates, Val ShouldReturnNonExistent = False) Export
	
	If Certificates.Count() = 0 Then
		Return New Array;	
	EndIf;
	
	Thumbprints = New Array;
	Map = New Map;
	For Each Certificate In Certificates Do
		Thumbprint = ?(Certificate = Undefined, Undefined, CertificateThumbprint(Certificate));
		Map.Insert(Certificate, Thumbprint);
		If Thumbprint <> Undefined Then
			Thumbprints.Add(Thumbprint);
		EndIf;
	EndDo;
	
	Query = New Query;
	Query.SetParameter("CertificateThumbprints", Thumbprints);
	Query.Text =
	"SELECT ALLOWED
	|	Certificates.Ref AS Ref,
	|	Certificates.Thumbprint AS Thumbprint
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
	|WHERE
	|	Certificates.Thumbprint IN (&CertificateThumbprints)";
	
	CertificateThumbprints = Query.Execute().Unload();
	
	If ShouldReturnNonExistent Then
		Result = New Array;
		Filter = New Structure("Thumbprint", "");
		For Each Certificate In Certificates Do
			Thumbprint = Map.Get(Certificate);
			If Thumbprint = Undefined Then
				Result.Add(Catalogs.DigitalSignatureAndEncryptionKeysCertificates.EmptyRef());
				Continue;
			EndIf;
			Filter.Thumbprint = Thumbprint;
			CertificateFound = CertificateThumbprints.FindRows(Filter);
			Result.Add(?(CertificateFound.Count() > 0, CertificateFound[0].Ref, 
				Catalogs.DigitalSignatureAndEncryptionKeysCertificates.EmptyRef()));
		EndDo;
		Return Result;
	EndIf;

	Result = CertificateThumbprints.UnloadColumn("Ref");
	Return CommonClientServer.CollapseArray(Result);
	
EndFunction

// Intended for creating and updating an item of the DigitalSignatureAndEncryptionKeysCertificates catalog
// by the specified crypto certificate.
// To add a certificate at the client, See DigitalSignatureClient.ToAddCertificate.
//
// Parameters:
//  Certificate - CryptoCertificate - a certificate.
//             - BinaryData - certificate binary data.
//             - String - an address of a temporary storage that contains certificate binary data.
//
//  AdditionalParameters - Undefined - without additional parameters.
//                          - Structure - Has an arbitrary composition with the following properties:
//      * Description - String - Certificate presentation in the list.
//
//      * User - CatalogRef.Users - a user who owns the certificate.
//                       The value is used when receiving a list of personal user certificates
//                       in the forms of signing and data encryption.
//
//      * Organization     - DefinedType.Organization - a company that owns the certificate.
//      * Individual  - DefinedType.Individual - Certificate recipient.
//
//      * Application - CatalogRef.DigitalSignatureAndEncryptionApplications - App required for
//                      signing and encrypting.
//
//      * EnterPasswordInDigitalSignatureApplication - Boolean - Flag "Protect digital signature application with password".
//                      True is required if a certificate was installed on the computer with strong private key protection.
//                      Meaning that only a blank password is supported at 1C:Enterprise level.
//                      The password is requested by the operating system, which rejects empty passwords from 1C:Enterprise.
//                      
//
// Returns:
//  CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - a reference to the certificate.
//
Function WriteCertificateToCatalog(Val Certificate, AdditionalParameters = Undefined) Export
	
	If TypeOf(AdditionalParameters) <> Type("Structure") Then
		AdditionalParameters = New Structure;
	EndIf;
	
	If TypeOf(Certificate) = Type("String") And IsTempStorageURL(Certificate) Then
		CertificateBinaryData = GetFromTempStorage(Certificate);
	
	ElsIf TypeOf(Certificate) = Type("BinaryData") Then
		CertificateBinaryData = Certificate;
	EndIf;
	
	If CertificateBinaryData = Undefined Then
		CryptoCertificate = Certificate;
		CertificateBinaryData = CryptoCertificate.Unload();
	Else
		CryptoCertificate = New CryptoCertificate(CertificateBinaryData);
	EndIf;
	
	If AdditionalParameters.Property("CertificateRef") Then
		CertificateReference = AdditionalParameters.CertificateRef;
	Else
		CertificateReference = CertificateRef(Certificate);
	EndIf;
	
	AccessRightInsert = DigitalSignatureInternal.HasRightToAddCertificatesToCatalog();
	
	If Not AccessRightInsert And Not ValueIsFilled(CertificateReference) Then
		Raise(NStr("vi = 'Không đủ quyền để sử dụng chứng thư.';
					|ru = 'Недостаточно прав для использования сертификата.';
					|en = 'insufficient rights to use the certificate.'; fa = 'insufficient rights to use the certificate.';
					|it = 'Недостаточно прав для использования сертификата.';
					|pl = 'insufficient rights to use the certificate.';
					|tr = 'Sertifika verilerini değiştirmek için yetersiz yetki.'"), ErrorCategory.AccessViolation);
	EndIf;
	
	AllowedFieldsToChange = Undefined;
	If Not AccessRightInsert Then
		AllowedFieldsToChange = New Array;
		AllowedFieldsToChange.Add("Organization");
		AllowedFieldsToChange.Add("User");
		AllowedFieldsToChange.Add("Application");
		AllowedFieldsToChange.Add("Individual");
		AllowedFieldsToChange.Add("EnterPasswordInDigitalSignatureApplication");
		SetPrivilegedMode(True);
	EndIf;
		
	BeginTransaction();
	Try
		
		If ValueIsFilled(CertificateReference) Then
			
			Block = New DataLock;
			LockItem = Block.Add("Catalog.DigitalSignatureAndEncryptionKeysCertificates");
			LockItem.SetValue("Ref", CertificateReference);
			
			Block.Lock();
			
			CertificateObject = CertificateReference.GetObject();
			UpdateValue(CertificateObject.DeletionMark, False);
			
		Else
			CertificateObject = Catalogs.DigitalSignatureAndEncryptionKeysCertificates.CreateItem();
			CertificateObject.CertificateData = New ValueStorage(CertificateBinaryData, New Deflation(9));
			CertificateObject.Thumbprint = Base64String(CryptoCertificate.Thumbprint);
			
			CertificateObject.Added = Users.AuthorizedUser();
		EndIf;
		
		If CertificateObject.CertificateData.Get() <> CertificateBinaryData Then
			If Not AccessRightInsert Then
				RollbackTransaction();
				Raise(NStr("vi = 'Không đủ quyền để thay đổi dữ liệu chứng chỉ.';
							|ru = 'Недостаточно прав для изменения данных сертификата.';
							|en = 'Insufficient rights to modify certificate data.'; fa = 'Insufficient rights to modify certificate data.';
							|it = 'Diritti insufficienti per modificare i dati del certificato.';
							|pl = 'Nie masz wystarczających praw do zmiany danych certyfikatu.';
							|tr = 'Sertifika verilerini değiştirmek için yetersiz yetki.'"), ErrorCategory.AccessViolation);
			EndIf;
			CertificateObject.CertificateData = New ValueStorage(CertificateBinaryData, New Deflation(9));
		EndIf;
		
		CertificateProperties = Undefined;
		If AccessRightInsert Then
			CertificateProperties = CertificateProperties(CryptoCertificate);
			
			UpdateValue(CertificateObject.Signing,     CertificateProperties.Signing);
			UpdateValue(CertificateObject.Encryption,     CertificateProperties.Encryption);
			UpdateValue(CertificateObject.IssuedTo,      CertificateProperties.IssuedTo);
			UpdateValue(CertificateObject.IssuedBy,       CertificateProperties.IssuedBy);
			UpdateValue(CertificateObject.ValidBefore, CertificateProperties.ValidBefore);
			
			SubjectProperties = CertificateSubjectProperties(CryptoCertificate);
			
			If SubjectProperties.Property("MiddleName") Then
				NameAndPatronymicOfSubject = ?(ValueIsFilled(SubjectProperties.Name), SubjectProperties.Name, "")
					+ ?(ValueIsFilled(SubjectProperties.MiddleName), " " + SubjectProperties.MiddleName, "");
				NameAndPatronymicOfCertificate = ?(ValueIsFilled(CertificateObject.Name), CertificateObject.Name, "")
					+ ?(ValueIsFilled(CertificateObject.MiddleName), " " + CertificateObject.MiddleName, "");
				If NameAndPatronymicOfSubject <> NameAndPatronymicOfCertificate Then
					UpdateValue(CertificateObject.Name, SubjectProperties.Name, True);
					UpdateValue(CertificateObject.MiddleName, SubjectProperties.MiddleName, True);
				EndIf;
			Else
				UpdateValue(CertificateObject.Name, SubjectProperties.Name, True);
			EndIf;
			
			UpdateValue(CertificateObject.LastName,   SubjectProperties.LastName,     True);
			UpdateValue(CertificateObject.Firm,     SubjectProperties.Organization, True);
			
			If SubjectProperties.Property("JobTitle") Then
				UpdateValue(CertificateObject.JobTitle, SubjectProperties.JobTitle,   True);
			EndIf;
		EndIf;
		
		If CertificateObject.IsNew()
			And Not AdditionalParameters.Property("Description") Then
		
			If CertificateProperties = Undefined Then
				CertificateProperties = CertificateProperties(CryptoCertificate);
			EndIf;
			
			AdditionalParameters.Insert("Description",
				CertificateProperties.Presentation);
		EndIf;
		
		For Each KeyAndValue In AdditionalParameters Do
			
			If KeyAndValue.Key = "CertificateRef" Then
				Continue;
			EndIf;
			
			If AllowedFieldsToChange <> Undefined 
			   And AllowedFieldsToChange.Find(KeyAndValue.Key) = Undefined Then
				Continue;
			EndIf;
			
			If KeyAndValue.Key = "User" Then
				If ValueIsFilled(KeyAndValue.Value) Then
					If ValueIsFilled(CertificateObject.User) And CertificateObject.User <> KeyAndValue.Value Then
						AddAUserToTheCertificate(CertificateObject.User, CertificateObject.Users);
						AddAUserToTheCertificate(KeyAndValue.Value, CertificateObject.Users);
						CertificateObject.User = Undefined;
					ElsIf CertificateObject.Users.Count() > 0 Then
						AddAUserToTheCertificate(KeyAndValue.Value, CertificateObject.Users);
					Else
						UpdateValue(CertificateObject[KeyAndValue.Key], KeyAndValue.Value);
					EndIf;
				EndIf;
			Else
				UpdateValue(CertificateObject[KeyAndValue.Key], KeyAndValue.Value);
			EndIf;
		EndDo;
		
		If CertificateObject.Modified() Then
			CertificateObject.Write();
		EndIf;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return CertificateObject.Ref;
	
EndFunction

// Returns a spreadsheet document that contains a digital signature visualization stamp.
//
// Parameters:
//  Signature - See DigitalSignatureClientServer.NewSignatureProperties
//  SignatureDate  - Date -  a date of signing the document.
//  MarkText - String -  a text that appears directly below the stamp and describes
//                          the location of the original document.
//  CompanyLogo - Picture - if it is not specified, the standard picture will be used.
//
// Returns:
//  SpreadsheetDocument - a spreadsheet document that contains the ready digital signature stamp.
//
Function DigitalSignatureVisualizationStamp(Val Signature, Val SignatureDate = Undefined, 
	Val MarkText = "", Val CompanyLogo = Undefined) Export

	NewSignature = DigitalSignatureClientServer.NewSignatureProperties();
	
	If TypeOf(Signature) = Type("CryptoCertificate") Then
		//@skip-check bsl-legacy-check-expression-type - for backward compatibility
		NewSignature.Certificate = Signature;
		NewSignature.SignatureDate = ?(SignatureDate = Undefined, Date(1,1,1), SignatureDate);
		Signature = NewSignature;
	Else
		FillPropertyValues(NewSignature, Signature);
		NewSignature.SignatureDate = ?(SignatureDate = Undefined, NewSignature.SignatureDate, SignatureDate);
	EndIf;
	
	Result = DigitalSignatureVisualizationStamps(Undefined, CommonClientServer.ValueInArray(Signature),
		?(Not IsBlankString(MarkText), CommonClientServer.ValueInArray(MarkText), Undefined));
	
	Return Result[0];
	
EndFunction

// Returns spreadsheets with the stamps of the applied digital signatures.
// 
// Parameters:
//  SignedFile - DefinedType.SignedObject - Signed document.
//                                                        It must have the "SignedWithDS" attribute.
//  DigitalSignatures - Array of See DigitalSignatureClientServer.NewSignatureProperties - If provided,
//                       stamps are generated using the given digital signatures
//                       (not the ones the "SignedFile" is signed with).
//  MarksTexts      - Array of String - Text that appears directly below the stamp and describes
//                                          the location of the original document.
// 
// Returns:
//  Array of SpreadsheetDocument
//
Function DigitalSignatureVisualizationStamps(Val SignedFile, Val DigitalSignatures = Undefined,
	Val MarksTexts = Undefined) Export
	
	If DigitalSignatures = Undefined Then
		SignaturesAcquisitionParameters = NewObjectSignaturesAcquisitionParameters();
		SignaturesAcquisitionParameters.ShouldReturnMachineReadableLOAData = True;
		SignaturesAcquisitionParameters.ShouldExtractCertificatesFromSignatures = True;
		SignaturesAcquisitionParameters.ReturnTimestampDate = True;
		DigitalSignatures = ObjectSignatures(SignedFile, SignaturesAcquisitionParameters);
	EndIf;
	
	StampsParameters = DigitalSignatureInternal.StampsParameters(DigitalSignatures, MarksTexts);
	
	Result = New Array;
	
	For Each StampParameters In StampsParameters Do
		Stamp = Catalogs.DigitalSignatureAndEncryptionKeysCertificates.GetTemplate("Stamp");
		FillPropertyValues(Stamp.Parameters, StampParameters);
		
		If StampParameters.CompanyLogo <> Undefined Then
			Stamp.Areas.Picture.Picture = StampParameters.CompanyLogo;
		EndIf;
		Result.Add(Stamp);
	EndDo;
	
	Return Result;

EndFunction

// Places stamps to the passed spreadsheet document.
//
// Parameters:
//  Document        - SpreadsheetDocument - a spreadsheet document to add stamps to.
//  StampsDetails - Array of SpreadsheetDocument - Stamps obtained using the
//                             "DigitalSignature.DigitalSignatureVisualizationStamp" function.
//                             The provided stamps will be placed either at the end of the document or in designated 
//                             stamp areas if they are defined in the spreadsheet template::
//                               a) The area name is specified as "DSStamp" followed by the stamp number
//                                  (for example, "DSStamp1").
//                               b) The stamp output area consists of two columns and seven rows,
//                                  with column widths set arbitrarily. In this case, the stamps will be placed in
//                             the specified areas in the order they appear in the "StampsDetails" parameter.
//                             
//                  - Map of KeyAndValue - Describes stamp output locations:
//                       * Key     - String - an area name, where the stamp must be put. For such an area,
//                                    an arbitrary column width 
//                                    different from the column width of the rest of the document, must be set.
//                       * Value - SpreadsheetDocument - a stamp got by the
//                                       DigitalSignature.DigitalSignatureVisualizationStamp function.
//  CellSize         - Structure - allows you to change stamp size and has the following properties:
//                       * LeftColumn  - Number - width of the left stamp column that contains property titles.
//                                                 The default value is 10.
//                       * RightColumn - Number - width of the right stamp column that contains property titles.
//                                                 The default value is 30.
//
Procedure AddStampsToSpreadsheetDocument(Document, StampsDetails, CellSize = Undefined) Export
	
	If CellSize = Undefined Then
		CellSize = New Structure;
		CellSize.Insert("LeftColumn", 10);
		CellSize.Insert("RightColumn", 30);
	EndIf;
	
	If TypeOf(StampsDetails) = Type("Array") Then
		
		StampIndex = 1; StampCount = StampsDetails.Count();
		
		StampColumnsWidth = 3 + CellSize.LeftColumn + CellSize.RightColumn;
		
		StampsCountByWidth = Undefined;
		StampNumberInRow = 0; StampsRowWidth = 0; TableWidth = 0;
		
		For Each Stamp In StampsDetails Do
			AreaName = "DSStamp" + String(StampIndex);
			AreaFound = False;
			For Each NextInTurnArea In Document.Areas Do
				If StrStartsWith(NextInTurnArea.Name, AreaName) Then
					AreaFound = True;
					AreaName = NextInTurnArea.Name;
					Break;
				EndIf;
			EndDo;
			
			If AreaFound Then
				StampArea = Document.Areas[AreaName];
				Document.InsertArea(Stamp.Areas.Stamp, StampArea,, True);
				Document.Area(StampArea.Top, StampArea.Left, StampArea.Top, StampArea.Left).ColumnWidth = CellSize.LeftColumn;
				Document.Area(StampArea.Top, StampArea.Right, StampArea.Top, StampArea.Right).ColumnWidth = CellSize.RightColumn;
				Document.Area(StampArea.Top, , StampArea.Bottom).RowHeight = 0;
				Document.Area(StampArea.Top, , StampArea.Bottom).AutoRowHeight = True;
			Else
				StampNumberInRow = StampNumberInRow + 1;
				
				StampWidth = Stamp.Areas.Stamp.Right;
				StampTop = Stamp.Areas.Stamp.Top;
				BottomStamp = Stamp.Areas.Stamp.Bottom;
				StampHeight = BottomStamp - StampTop;
				
				If StampNumberInRow = 1 Or StampNumberInRow > StampsCountByWidth Then
					
					If StampsCountByWidth = Undefined Then
						
						For TableWidth = 1 To Document.TableWidth Do
							
							Area = Document.Area(, TableWidth,, TableWidth);
							StampsRowWidth = StampsRowWidth + Area.ColumnWidth;
							If Area.PageBottom Then
								Break;
							EndIf;
							
							If TableWidth = Document.TableWidth Then
								
								StampsRowWidth = 0;
								TableHeight = Min(Document.TableHeight, 100);
								
								For ColumnNumberBackward = 1 To TableWidth Do
									
									ColumnNumber = TableWidth - ColumnNumberBackward + 1;
									
									For RowNumberBackward = 1 To TableHeight Do
										
										LineNumber = Document.TableHeight - RowNumberBackward + 1;
										
										TableCellArea = Document.Area(LineNumber, ColumnNumber);
										
										If IsBlankString(TableCellArea.Text)
											And TableCellArea.Left = ColumnNumber
											And TableCellArea.Top = LineNumber
											And TableCellArea.RightBorder.LineType = SpreadsheetDocumentCellLineType.None
											And TableCellArea.BottomBorder.LineType = SpreadsheetDocumentCellLineType.None
											And TableCellArea.TopBorder.LineType = SpreadsheetDocumentCellLineType.None
											Then
											Continue;
										EndIf;
										
										SpreadsheetDocument = New SpreadsheetDocument;
										Area = Document.GetArea(LineNumber, 1, LineNumber, ColumnNumber);
										SpreadsheetDocument.Put(Area);
										
										For SpreadsheetColumnNumber = 1 To ColumnNumber Do
											Area = SpreadsheetDocument.Area(1, SpreadsheetColumnNumber, 1,
												SpreadsheetColumnNumber);
											StampsRowWidth = StampsRowWidth + Area.ColumnWidth;
										EndDo;
										
										Break;
									EndDo;
									
									If StampsRowWidth <> 0 Then
										Break;
									EndIf;
								EndDo;
								
								Break;
							EndIf;
						EndDo;
						StampsCountByWidth = Max(1, Int(StampsRowWidth/StampColumnsWidth));
					EndIf;
						
					StartingWidth = 1; StampNumberInRow = 1;
					
					AreasToCheckByHeight = New Array;
					AreasToCheckByHeight.Add(Stamp.GetArea("Indent"));
					AreasToCheckByHeight.Add(Stamp.GetArea("RowsAreaStamp"));
					If Not Common.SpreadsheetDocumentFitsPage(Document, AreasToCheckByHeight, True) Then
						Document.PutHorizontalPageBreak();
					EndIf;
					
					Document.Put(Stamp.GetArea("Indent"));
					
					HeightStart = Document.TableHeight;
					HeightEnd = Document.TableHeight + StampHeight;
					
					Document.Area(HeightStart, StartingWidth, HeightEnd, TableWidth).UndoMerge();
					// Row format that won't affect the rest of the document when the column width is changed.
					Document.Area(HeightStart, , HeightEnd).CreateFormatOfRows();
					
					RemainingWidth = StampsRowWidth;
					
				Else
					
					HeightEnd = HeightStart + StampHeight;
					
				EndIf;
				
				FinalWidth = StartingWidth - 1 + StampWidth;
				
				// Insert the area from the stamp layout in the gap.
				SourceArea = Stamp.Area(StampTop, 1, BottomStamp, StampWidth);
				ReceivingArea = Document.Area(HeightStart, StartingWidth, HeightEnd, FinalWidth);
				Document.InsertArea(SourceArea, ReceivingArea, , True);
				
				Document.Areas.StampRightColumn.ColumnWidth = CellSize.RightColumn;
				If Stamp.Areas.Find("StampLeftColumn") <> Undefined Then // Intended for compatibility purposes.
					Document.Areas.StampLeftColumn.ColumnWidth  = CellSize.LeftColumn;
				Else
					Document.Areas.Picture.ColumnWidth  = CellSize.LeftColumn;
				EndIf;
				Document.Areas.StampIndent.ColumnWidth       = 3;
					
				StartingWidth = FinalWidth + 1;
				
				If RemainingWidth > StampColumnsWidth Or StampIndex = StampCount Then
					
					RemainingWidth = RemainingWidth - StampColumnsWidth;
					
					If RemainingWidth < StampColumnsWidth Or StampIndex = StampCount Then
						If StartingWidth < TableWidth Then
							Document.Area(HeightStart, StartingWidth, HeightEnd, TableWidth).ColumnWidth = 0;
						EndIf;
						If RemainingWidth > 0 Then
							Document.Area(HeightStart, StartingWidth, HeightEnd, StartingWidth).ColumnWidth = RemainingWidth;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			
			StampIndex = StampIndex + 1;
		EndDo;

	Else
		For Each StampDetails In StampsDetails Do
			AreaName = StampDetails.Key;
			Stamp      = StampDetails.Value;
			AreaFound = Document.Areas.Find(AreaName) <> Undefined;
			If AreaFound Then
				Document.InsertArea(Stamp.Areas.Stamp, Document.Areas[AreaName],, True);
				Document.Areas.Picture.ColumnWidth  = CellSize.LeftColumn;
				Document.Areas.StampRightColumn.ColumnWidth = CellSize.RightColumn;
				If Stamp.Areas.Find("StampLeftColumn") <> Undefined Then // Intended for compatibility purposes.
					Document.Areas.StampLeftColumn.ColumnWidth  = CellSize.LeftColumn;
				Else
					Document.Areas.Picture.ColumnWidth  = CellSize.LeftColumn;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

// See DigitalSignatureClient.CertificatePresentation.
Function CertificatePresentation(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.CertificatePresentation(Certificate, DigitalSignatureInternal.UTCOffset());
	
EndFunction

// See DigitalSignatureClient.SubjectPresentation.
Function SubjectPresentation(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.SubjectPresentation(Certificate);
	
EndFunction

// See DigitalSignatureClient.IssuerPresentation.
Function IssuerPresentation(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.IssuerPresentation(Certificate);
	
EndFunction

// Returns main certificate properties.
//
// Parameters:
//   Certificate - CryptoCertificate - Cryptographic certificate.
//              - BinaryData - Certificate's binary data in DER encoding.
//
// Returns:
//   Structure:
//    * Thumbprint      - String - A certificate thumbprint in the Base64 string format.
//    * SerialNumber  - BinaryData - the SerialNumber certificate property.
//    * Presentation  - See DigitalSignatureClient.CertificatePresentation.
//    * IssuedTo      - See DigitalSignatureClient.SubjectPresentation.
//    * IssuedBy       - See DigitalSignatureClient.IssuerPresentation.
//    * StartDate     - Date   - Certificate's "StartDate" property in the session time zone.
//    * EndDate  - Date   - Certificate's "EndDate" property in the session time zone.
//    * PrivateKeyStartDate     - Date   - Certificate's property specified in OID 2.5.29.16 in the session time zone.
//    * PrivateKeyExpirationDate  - Date   - Certificate's property specified in OID 2.5.29.16 in the session time zone.
//    * ValidBefore - Date - The earliest date from "EndDate" and "PrivateKeyExpirationDate" (if specified in the certificate).
//    * Purpose     - String - Extended property details of the EKU certificate.
//    * Signing     - Boolean - Certificate's "UseToSign" property.
//    * Encryption     - Boolean - Certificate property "UseToEncrypt".
//        For 1C:Enterprise v.8.3.27 and later, the structure has the following properties:
//    * CertificateAuthorityKeyID - String - Issuer key ID.
//    * SignAlgorithm - String - OID algorithm of the certificate's signature.
//    * PublicKeyAlgorithm - String - OID algorithm of the certificate's public key.
//    * AddressesOfRevocationLists - Array of String
//
Function CertificateProperties(Certificate) Export
	
	CertificateData = Certificate;
	If TypeOf(Certificate) = Type("CryptoCertificate") Then
		CertificateBinaryData = Certificate.Unload();
	ElsIf TypeOf(Certificate) = Type("FixedStructure") Then
		CertificateBinaryData = Certificate.Certificate;
	ElsIf TypeOf(Certificate) = Type("BinaryData") Then
		CertificateBinaryData = Certificate;
		CertificateData = New CryptoCertificate(Certificate);
	Else
		CertificateBinaryData = Undefined;
	EndIf;
	
	Return DigitalSignatureInternalClientServer.CertificateProperties(
		CertificateData, DigitalSignatureInternal.UTCOffset(), CertificateBinaryData);
	
EndFunction

// See DigitalSignatureClient.CertificateSubjectProperties.
Function CertificateSubjectProperties(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.CertificateSubjectProperties(Certificate);
	
EndFunction

// See DigitalSignatureClient.CertificateIssuerProperties.
Function CertificateIssuerProperties(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.CertificateIssuerProperties(Certificate);
	
EndFunction

// Returns the causes and solutions for an issue based on the standard problem 
// classifier related to electronic signature operations.
// It is recommended to call this method after any unsuccessful cryptographic operation on the server to log the information in the event log.
//
// Parameters:
//   TextToSearchInClassifier - String - The issue text used for search in the classifier.
//   ErrorAtServer               - Boolean - The issue location (the causes and solutions may
//                                   differ for server and for client). By default, "False".
//
// Returns:
//   Undefined - There is no such issue in the classifier.
//   Structure:
//     * Cause          - String - Possible causes of the issue.
//     * Decision          - String - Possible solutions for the issue.
//     * Remedy - String - ID of the method that auto-fixes the issue.
//     * Ref           - String - the anchor ID in the article on the ITS website.
//
Function ClassifierError(TextToSearchInClassifier, ErrorAtServer = False) Export
	
	Result = DigitalSignatureInternal.ClassifierError(TextToSearchInClassifier, ErrorAtServer);
	
	If Result = Undefined Then
		Return Undefined;
	EndIf;
	
	Structure = New Structure("Cause, Decision, Remedy, Ref");
	FillPropertyValues(Structure, Result);
	
	Return Structure;
	
EndFunction

// Enhances the signature to the given type if possible.
// Adds an archive timestamp to the archived signature (CAdES-A). 
// Returns only the modified signature properties.
// 
// Parameters:
//  Signature                      - BinaryData - digital signature binary data.
//  SignatureType                   - EnumRef.CryptographySignatureTypes - Signature type to upgrade to.
//                                  If the actual SignatureType is the same or higher, no actions are performed.
//                                  
//  AddArchiveTimestamp - Boolean - If True and SignatureType is ArchivalCAdESAv3,
//                                   a timestamp is added.
//  AdditionalParameters - Structure:
//                             * CryptoManager - Undefined - Get a cryptographic manager to check.
//                                                    - CryptoManager - Cryptographic manager to be used.
//                             * ShouldIgnoreCertificateValidityPeriod  - Boolean - Flag indicating whether to check the certificate 
//                                                      validity before enhancement. By default, False.
//                          - Undefined - get a crypto manager to check
//                                 digital signatures as it was configured by the administrator.
//                          - CryptoManager - Cryptographic manager to be used.
// 
// Returns:
//  Structure:
//   * Success - Boolean - True if upgrade was successful or wasn't needed.
//   * ErrorText - String - If False, a value is assigned.
//   * SignatureProperties - See DigitalSignatureClientServer.NewSignatureProperties.
//
Function EnhanceSignature(Signature, SignatureType, AddArchiveTimestamp = False,
	AdditionalParameters = Undefined) Export
	
	EnhancementParameters = New Structure;
	EnhancementParameters.Insert("CryptoManager", Undefined);
	EnhancementParameters.Insert("ShouldIgnoreCertificateValidityPeriod", False);
	EnhancementParameters.Insert("PerformCAVerification",
		DigitalSignatureInternalClientServer.NotVerifyCertificate());
	
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		FillPropertyValues(EnhancementParameters, AdditionalParameters);
	Else
		EnhancementParameters.CryptoManager = AdditionalParameters;
	EndIf;
	
	CryptoManager = EnhancementParameters.CryptoManager;
	
	Result = New Structure("Success, ErrorText, SignatureProperties", False);

	If CryptoManager = Undefined Then
		
		CreationParameters = DigitalSignatureInternal.CryptoManagerCreationParameters();
		CreationParameters.SignAlgorithm =
			DigitalSignatureInternalClientServer.GeneratedSignAlgorithm(Signature);
		
		CryptoManager = DigitalSignatureInternal.CryptoManager(
			"ExtensionValiditySignature", CreationParameters);
		
		If CryptoManager = Undefined Then
			Result.ErrorText = CreationParameters.ErrorDescription;
			Return Result;
		EndIf;
		
		CryptoManager.TimestampServersAddresses = CommonSettings().TimestampServersAddresses;

	EndIf;
	
	SignatureProperties = DigitalSignatureClientServer.NewSignatureProperties();
	
	Try
		ContainerSignatures = CryptoManager.GetCryptoSignaturesContainer(Signature);
	Except
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể đọc dữ liệu chữ ký: %1';
				|ru = 'Не удалось прочитать данные подписи: %1';
				|en = 'Cannot read the signature data: %1'; fa = 'Cannot read the signature data: %1';
				|it = 'Non è stato possibile leggere i dati di firma: %1';
				|pl = 'Nie udało się odczytać danych podpisu: %1';
				|tr = 'İmza verileri okunamadı: %1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return Result;
	EndTry;
	
	ParametersCryptoSignatures = DigitalSignatureInternal.ParametersCryptoSignatures(ContainerSignatures,
		DigitalSignatureInternal.UTCOffset(), CurrentSessionDate());
		
	If ParametersCryptoSignatures.CertificateLastTimestamp = Undefined Then
		Result.ErrorText = NStr("vi = 'Không thể nhận chứng thư chữ ký';
								|ru = 'Не удалось получить сертификат подписи';
								|en = 'Cannot get the signature certificate'; fa = 'Cannot get the signature certificate';
								|it = 'Не удалось получить сертификат подписи';
								|pl = 'Cannot get the signature certificate';
								|tr = 'İmza sertifikası alınamadı'");
		Return Result;
	EndIf;
	
	SignatureProperties.SignatureType = ParametersCryptoSignatures.SignatureType;
	SignatureProperties.DateActionLastTimestamp = ParametersCryptoSignatures.DateActionLastTimestamp;
	SignatureProperties.DateSignedFromLabels = ParametersCryptoSignatures.DateSignedFromLabels;
	
	Result.SignatureProperties = SignatureProperties;
	
	If Not EnhancementParameters.ShouldIgnoreCertificateValidityPeriod
		And ValueIsFilled(ParametersCryptoSignatures.DateActionLastTimestamp)
		And ParametersCryptoSignatures.DateActionLastTimestamp < CurrentSessionDate() Then
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã quá thời hạn hiệu lực chữ ký: %1';
				|ru = 'Истек срок действия подписи: %1';
				|en = 'The signature expired: %1'; fa = 'The signature expired: %1';
				|it = 'È scaduto il periodo di validità della firma: %1';
				|pl = 'Upłynął termin ważności podpisu: %1';
				|tr = 'İmzanın geçerlilik dönemi sona erdi: %1'"), ParametersCryptoSignatures.DateActionLastTimestamp);
		Return Result;
	EndIf;
	
	ErrorDescription = "";
	
	CheckParameters = New Structure;
	CheckParameters.Insert("PerformCAVerification",
		EnhancementParameters.PerformCAVerification);
	
	CertificateVerificationResult = CheckCertificate(CryptoManager,
		ParametersCryptoSignatures.CertificateLastTimestamp, ErrorDescription,, CheckParameters);
	If CertificateVerificationResult Then
		If ValueIsFilled(SignatureType) And DigitalSignatureInternalClientServer.ToBeImproved(
			ParametersCryptoSignatures.SignatureType, SignatureType) Then
			Try
				ResultBinaryData = CryptoManager.EnhanceSignature(Signature,
					DigitalSignatureInternalClientServer.CryptoSignatureType(SignatureType));
			Except
				Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Không thể nâng cấp chữ ký: %1';
							|ru = 'Не удалось усовершенствовать подпись: %1';
							|en = 'Couldn''t enhance the signature: %1'; fa = 'Couldn''t enhance the signature: %1';
							|it = 'Non è stato possibile perfezionare la firma: %1';
							|pl = 'Nie udało się udoskonalić podpisu: %1';
							|tr = 'İmza geliştirilemedi: %1'"), ErrorProcessing.BriefErrorDescription(
					ErrorInfo()));
				Return Result;
			EndTry;
		ElsIf AddArchiveTimestamp And (ParametersCryptoSignatures.SignatureType
			= Enums.CryptographySignatureTypes.ArchivalCAdESAv3 Or ParametersCryptoSignatures.SignatureType
			= Enums.CryptographySignatureTypes.CAdESAv2) Then
			Try
				ResultBinaryData = CryptoManager.AddArchiveTimestamp(Signature);
			Except
				Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Không thể thêm dấu thời gian đã lưu trữ vào chữ ký: %1';
							|ru = 'Не удалось добавить архивную метку времени в подпись: %1';
							|en = 'Cannot add an archive timestamp to the signature: %1'; fa = 'Cannot add an archive timestamp to the signature: %1';
							|it = 'Non è stato possibile aggiungere il contrassegno di archivio di tempo nella firma: %1';
							|pl = 'Nie udało się dodać znacznika archiwalnego do podpisu: %1';
							|tr = 'İmzaya arşiv tarih etiketi eklenemedi: %1'"), ErrorProcessing.BriefErrorDescription(
					ErrorInfo()));
				Return Result;
			EndTry;
		Else // Flag indicating whether there are signatures not requiring enhancement but their properties must be populated.
			Result.Success = True;
			Return Result;
		EndIf;
	Else
		CertificateProperties = CertificateProperties(ParametersCryptoSignatures.CertificateLastTimestamp);
		InformationAboutCertificate = DigitalSignatureInternalClientServer.DetailsCertificateString(
				CertificateProperties);
				
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chứng chỉ chữ ký không có hiệu lực: %1
				|%2';
				|ru = 'Не действует сертификат подписи: %1
				|%2';
				|en = 'The signature certificate is invalid: %1
				|%2'; fa = 'The signature certificate is invalid: %1
				|%2';
				|it = 'Non funziona il certificato di firma: %1
				|%2';
				|pl = 'Certyfikat podpisu: %1
				|%2 nie jest ważny';
				|tr = 'İmza sertifikası geçerli değil: %1
				|%2'"), ErrorDescription, InformationAboutCertificate);
		Return Result;
	EndIf;
	
	Try
		ContainerSignatures = CryptoManager.GetCryptoSignaturesContainer(ResultBinaryData);
	Except
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể đọc dữ liệu của chữ ký đã nâng cấp: %1';
					|ru = 'Не удалось прочитать данные усовершенствованной подписи: %1';
					|en = 'Couldn''t read the enhanced signature data: %1'; fa = 'Couldn''t read the enhanced signature data: %1';
					|it = 'Non è stato possibile leggere i dati della firma perfezionata: %1';
					|pl = 'Nie udało się odczytać danych podpisu udoskonalonego: %1';
					|tr = 'Geliştirilmiş imza verileri okunamadı: %1'"), ErrorProcessing.BriefErrorDescription(
			ErrorInfo()));
		Return Result;
	EndTry;

	ParametersCryptoSignatures = DigitalSignatureInternal.ParametersCryptoSignatures(
			ContainerSignatures, DigitalSignatureInternal.UTCOffset(), CurrentSessionDate());
	
	CertificateVerificationResult = CheckCertificate(CryptoManager,
		ParametersCryptoSignatures.CertificateLastTimestamp, ErrorDescription);

	If CertificateVerificationResult Then
		SignatureProperties.Signature = ResultBinaryData;
		SignatureProperties.SignatureType = ParametersCryptoSignatures.SignatureType;
		SignatureProperties.DateSignedFromLabels = ParametersCryptoSignatures.DateSignedFromLabels;
		SignatureProperties.DateActionLastTimestamp = ParametersCryptoSignatures.DateActionLastTimestamp;
		SignatureProperties.CertificateDetails = ParametersCryptoSignatures.CertificateDetails;
		SignatureProperties.SignatureDate = 
			?(ValueIsFilled(ParametersCryptoSignatures.UnverifiedSignatureDate),
			ParametersCryptoSignatures.UnverifiedSignatureDate, ParametersCryptoSignatures.DateSignedFromLabels);
		Result.SignatureProperties = SignatureProperties;
	Else
		CertificateProperties = CertificateProperties(ParametersCryptoSignatures.CertificateLastTimestamp);
		InformationAboutCertificate = DigitalSignatureInternalClientServer.DetailsCertificateString(
				CertificateProperties);

		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã qua kiểm tra chứng thư dấu thời gian đã nhận được: %1
					 |%2';
					 |ru = 'Не прошел проверку сертификат полученной метки времени: %1
					 |%2';
					 |en = 'The certificate of the received timestamp is invalid: %1
					 |%2'; fa = 'The certificate of the received timestamp is invalid: %1
					 |%2';
					 |it = 'Не прошел проверку сертификат полученной метки времени: %1
					 |%2';
					 |pl = 'The certificate of the received timestamp is invalid: %1
					 |%2';
					 |tr = 'Alınan zaman damgasının sertifikası doğrulanamadı: %1
					 |%2'"), ErrorDescription, InformationAboutCertificate);

		Raise ErrorDescription;
	EndIf;
	
	Result.Success = True;
	Return Result;
	
EndFunction

// Upgrades the object signature to the given type if applicable.
// Adds an archived timestamp to the archived signature (CAdES-A).
// Updates object signature data (Signature type, Validity period of the last timestamp).
// 
// Parameters:
//  SignedObject - DefinedType.SignedObject - Reference to the signature for upgrade and update lock.
//           
//
//  SequenceNumber - Number - a signature sequence number.
//
//  SignatureType      - EnumRef.CryptographySignatureTypes - Signature type to upgrade to.
//                    If the actual SignatureType is the same or higher, no actions are performed.
//                    
//
//  AddArchiveTimestamp - Boolean - If True and SignatureType and actual SignatureType are archived, add a timestamp.
//                           
//
//  FormIdentifier - UUID - a form ID that is used for lock
//                      if an object reference is passed.
//
//  AdditionalParameters - Structure:
//                             * CryptoManager - Undefined, CryptoManager - See details below.
//                             * ShouldIgnoreCertificateValidityPeriod  - Boolean - Flag indicating whether to check the certificate 
//                                                      validity before enhancement. By default, False.
//                          - Undefined - get a crypto manager to check
//                                 digital signatures as it was configured by the administrator.
//                          - CryptoManager - Cryptographic manager to be used.
//
// Returns:
//  Structure:
//   * Success - Boolean - True if upgrade was successful or wasn't needed.
//   * ErrorText - String - If False, a value is assigned.
//   * SignatureProperties - See DigitalSignatureClientServer.NewSignatureProperties
//   
Function ImproveObjectSignature(SignedObject, SequenceNumber, SignatureType, AddArchiveTimestamp = False,
			FormIdentifier = Undefined, AdditionalParameters = Undefined) Export
			
			
	EnhancementParameters = New Structure;
	EnhancementParameters.Insert("CryptoManager", Undefined);
	EnhancementParameters.Insert("ShouldIgnoreCertificateValidityPeriod", False);
	
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		FillPropertyValues(EnhancementParameters, AdditionalParameters);
	Else
		EnhancementParameters.CryptoManager = AdditionalParameters;
	EndIf;
	
	Result = New Structure("Success, ErrorText, SignatureProperties", False);
	
	SignaturesAcquisitionParameters = NewObjectSignaturesAcquisitionParameters();
	SignaturesAcquisitionParameters.SequenceNumber = SequenceNumber;
	ObjectSignatures = ObjectSignatures(SignedObject, SignaturesAcquisitionParameters);
	
	If ObjectSignatures.Count() = 0 Then
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể tìm thấy chữ ký có số thứ tự %1 trong %2';
				|ru = 'Не удалось найти подпись с порядковым номером %1 у %2';
				|en = 'Cannot find a signature with sequence number %1 for %2'; fa = 'Cannot find a signature with sequence number %1 for %2';
				|it = 'Non è stato possibile trovare la firma con numero di ordine %1 presso %2';
				|pl = 'Nie udało się odnaleźć podpisu z numerem kolejnym %1 dla %2';
				|tr = '%2''da %1 sıra numaralı imza bulunamadı'"), SequenceNumber, SignedObject);
		Return Result;
	EndIf;
	
	SignatureProperties = ObjectSignatures[0];
	Signature = SignatureProperties.Signature;
	
	Result = EnhanceSignature(Signature, SignatureType, AddArchiveTimestamp, EnhancementParameters);
	
	If Result.SignatureProperties = Undefined Then
		Return Result;
	EndIf;
	
	Result.SignatureProperties.SignedObject = SignedObject;
	Result.SignatureProperties.SequenceNumber = SequenceNumber;
	
	If Result.SignatureProperties.Signature = Undefined Then
		// Signature wasn't upgraded. But the data may require an update.
		If SignatureProperties.SignatureType = Result.SignatureProperties.SignatureType
			And SignatureProperties.DateActionLastTimestamp = Result.SignatureProperties.DateActionLastTimestamp Then
			Return Result;
		EndIf;
	EndIf;
	
	ErrorPresentation = DigitalSignatureInternal.UpdateAdvancedSignature(
		Result.SignatureProperties);
	
	If ValueIsFilled(ErrorPresentation) Then
		Result.ErrorText = ErrorPresentation;
		Result.Success = False;
		Result.SignatureProperties = Undefined;
		Return Result;
	EndIf;
	
	If ValueIsFilled(Result.SignatureProperties.Signature) Then
		DigitalSignatureInternal.RegisterImprovementSignaturesInJournal(Result.SignatureProperties);
	EndIf;
	
	Return Result;
	
EndFunction

// A constructor of additional parameters for receiving an object's digital signatures.
// 
// Returns:
//   Structure:
//     * SequenceNumber               - Number - Signature's sequence number (for filtering).
//                                     - Array of Number - Array of the signature's sequence numbers (for filtering).
//     * ShouldReturnMachineReadableLOAData           - Boolean - If set to "True" and there is a machine-readable LoA for the signature, populate the "ResultOfSignatureVerificationByMRLOA" property
//     * ShouldExtractCertificatesFromSignatures - Boolean - If set to "True", certificates will be obtained from
//                                                  signature binary data. 
//     * ShouldReturnExpectedSignatures - Boolean - If set to True, data about the signers to whom the document was sent 
//                                                  for signing via the mobile signing service will be included.
//     * ReturnTimestampDate - Boolean - If True, the timestamp value will be recorded.
//
Function NewObjectSignaturesAcquisitionParameters() Export
	
	Structure = New Structure;
	Structure.Insert("SequenceNumber", Undefined);
	Structure.Insert("ShouldReturnMachineReadableLOAData", False);
	Structure.Insert("ShouldExtractCertificatesFromSignatures", False);
	Structure.Insert("ShouldReturnExpectedSignatures", False);
	Structure.Insert("ReturnTimestampDate", False);
	
	Return Structure;
	
EndFunction

// Extracts the certificate from the signature's binary data.
// 
// Parameters:
//  Signature - BinaryData - Signing result
// 
// Returns:
//   BinaryData - Certificate's binary data.
//   Undefined - The signature does not contain any cryptography certificates.
//
Function CertificateFromSignatureBinaryData(Signature) Export
	
	Return DigitalSignatureInternal.CertificateFromSignatureBinaryData(Signature);
	
EndFunction

// Retrieves the result of sending data for signing.
// 
// Parameters:
//  DocumentIDs - Array of UUID
// 
// Returns:
//  Structure:
//  * CheckResults - Map of KeyAndValue:
//   ** Key - UUID
//   ** Value - Structure:
//      *** Signature - BinaryData - Empty if the signature hasn't been obtained.
//      
//      Otherwise, contains signature properties.:
//      *** SignatureType          - EnumRef.CryptographySignatureTypes, Underfined.
//      *** DateActionLastTimestamp - Date - Validity period of the certificate that the last timestamp was signed with.
//            Empty date if there's no timestamp. Applicable if the period was determined using CryptoManager.
//      *** UnverifiedSignatureDate - Date - Unconfirmed signature data.
//                                      - Undefined - Unconfirmed signature data is missing from the signature data.
//      *** DateSignedFromLabels - Date - Date of the earliest timestamp.
//                         - Undefined - Signature data is missing a timestamp.
//      *** SignatureDate - Date - UnconfirmedSignatureDate. If the property is empty, then CurrentSessionDate.
//      *** Certificate - BinaryData - Signatory's certificate
//      *** Thumbprint - String - a certificate thumbprint in the Base64 string format.
//      *** CertificateOwner - String - a subject presentation received from the certificate binary data.
//      *** WrittenSignature - Structure:
//            **** SignedObject - DefinedType.SignedObject
//            **** SequenceNumber - Number
//      *** SignatureID - UUID
//      
//      Signature properties in case the signature is not obtained:
//      *** StatusInMobileService - 
//      *** AdditionalAttributesCheckError - String - Status information or error details in case the
//                                                           signature is not obtained.
//      
//   * Error - Structure - In case of a status check error:
//     ** ErrorTitle - String
//     ** ErrorText - String
//     ** QueryID - String, Undefined - Query ID.
//     ** AdditionalFiles - Array of Structure - Files containing additional error details:
//        ** Data - BinaryData
//        ** Name - String - Filename
//
Function SendForSigningResult(DocumentIDs) Export
	
	Result = New Map;
	DigitalSignatureLocalization.OnRetrieveSentForSigningResults(DocumentIDs, Result);
	Return Result;

EndFunction

#Region InterfaceImplementation

// The following procedures and functions are intended for integration with 1C:Electronic Document Library
// and 1C:Regulated Reporting Library.

// Returns the crypto manager (on the server) for the specified app.
//
// Parameters:
//  Operation       - String - if it is not blank, it needs to contain one of rows that determine
//                   the operation to insert into the error description: Signing, SignatureCheck, Encryption,
//                   Decryption, CertificateCheck, and GetCertificates.
//
//  ShowError - Boolean - if True, throw an exception that contains the error description.
//
//  ErrorDescription - String - an error description that is returned when the function returns Undefined.
//
//  Application      - Undefined - returns a crypto manager of the first
//                   app from the catalog for which it was possible to create it.
//                 - CatalogRef.DigitalSignatureAndEncryptionApplications - App for which
//                   a crypto manager must be created and returned.
//                 - Structure - See NewApplicationDetails.
//                 - BinaryData - DER-encoded data from a signature or certificate used to determine the application.
//                 - String - Address of the binary data in the temp storage.
//
// Returns:
//   CryptoManager - -a crypto manager.
//   Undefined - an error occurred. The error description is in the ErrorDescription parameter.
//
Function CryptoManager(Operation, ShowError = True, ErrorDescription = "", Application = Undefined) Export
	
	CreationParameters = DigitalSignatureInternal.CryptoManagerCreationParameters();
	CreationParameters.Application = Application;
	CreationParameters.ShowError = ShowError;
	
	Result = DigitalSignatureInternal.CryptoManager(Operation, CreationParameters);
	
	If Result = Undefined Then
		ErrorDescription = CreationParameters.ErrorDescription;
	EndIf;
	
	Return Result;
	
EndFunction

// Obtains signature properties from the signature data. If the Cryptography manager failed 
// to obtain the properties, it returns the properties read from the binary data.
//
// Parameters:
//   Signature - BinaryData - DER-encoded certificate data.
//   ShouldReadCertificates - Boolean - If False, don't populate the properties: Certificate, Thumbprint, CertificateOwner, Certificates.
//                                   By default, True.
//
// Returns:
//   Structure:
//       * Success       - Boolean, Undefined - Undefined if the cryptographic service failed to read all properties.
//                                              
//       * ErrorText - String - Filled if "Success" is False or Undefined
//       * SignatureType  - EnumRef.CryptographySignatureTypes
//       * DateActionLastTimestamp - Date, Undefined - Filled only using the cryptographic manager.
//       * DateSignedFromLabels - Date, Undefined - Earliest timestamp: CADES-T. If not available but other timestamps exist,
//               the date is filled only using the cryptographic manager.
//       * UnverifiedSignatureDate - Date - Unconfirmed signature data.
//                                     - Undefined - Unconfirmed signature data is missing from the signature data.
//       * Certificate  - BinaryData - Certificate used for signature validation.
//       * Thumbprint           - String - A certificate thumbprint in the Base64 string format.
//       * CertificateOwner - String - A subject presentation received from the certificate binary data. 
//       * Certificates - Array of BinaryData - Certificates used for signature validation.
//
Function SignatureProperties(Signature, ShouldReadCertificates = True) Export
	
	Return DigitalSignatureInternal.SignatureProperties(Signature, ShouldReadCertificates)
	
EndFunction

// Checks and returns the installed apps.
// 
// Parameters:
//  CheckParameters - Undefined, Structure:
//   * AppsToCheck - Undefined - By default, returns all installed apps.
//                          - Boolean - See DigitalSignatureClientServerLocalization.AppsRelevantAlgorithms
//                          - BinaryData - Signature or certificate data used for determining suitable apps.
//                          - String - Address of the signature or certificate data in the temp storage.
//                               - Array - Contains values as the DigitalSignature.NewApplicationDetails function returns.
//                          
//  Returns:
//    Structure:
//     * CheckCompleted - Boolean - If True, the check was executed on computer and the installed cryptographic service providers are obtained.
//                 If False, the Error is populated.
//     * Error - String - Error text.
//     * Programs - Array of Structure:
//        ** ApplicationName  - String  - Cryptographic service provider's name. For example, "Infotecs GOST 2012/512 Cryptographic Service Provider"
//        ** ApplicationType  - Number  - Cryptographic service provider. For example, "77"
//        ** Name           - String  - App presentation as specified in the supplied list.
//             For example, NStr("en = 'ViPNet CSP'; fa = 'ViPNet CSP'")
//        ** Version        - String - Library version.
//        ** ILicenseInfo      - Boolean - License presence flag
//     * IsConflictPossible - Boolean - Flag indicating whether a few cryptographic apps are installed,
//             which might conflict with each other.
//
Function CheckCryptographyAppsInstallation(CheckParameters = Undefined) Export
	
	Context = New Structure;
	Context.Insert("AppsToCheck", Undefined);
	Context.Insert("ExtendedDescription", False);
	Context.Insert("SignAlgorithms", New Array);
	Context.Insert("DataType", Undefined);
	Context.Insert("IsServer", True);
	
	If TypeOf(CheckParameters) = Type("Structure") Then
		FillPropertyValues(Context, CheckParameters);
	EndIf;
	
	If Context.AppsToCheck <> Undefined Then
		If Context.AppsToCheck = True Then
			Context.AppsToCheck = Undefined;
			Context.SignAlgorithms = DigitalSignatureInternalClientServer.AppsRelevantAlgorithms();
			Context.DataType = "Certificate";
		ElsIf TypeOf(Context.AppsToCheck) = Type("BinaryData")
			Or TypeOf(Context.AppsToCheck) = Type("String") Then
			BinaryData = DigitalSignatureInternalClientServer.BinaryDataFromTheData(
				Context.AppsToCheck, "DigitalSignature.CheckCryptographyAppsInstallation");
			Context.AppsToCheck = Undefined;
			Context.DataType = DigitalSignatureInternalClientServer.DefineDataType(BinaryData);
			If Context.DataType = "Certificate" Then
				SignAlgorithm = DigitalSignatureInternalClientServer.CertificateSignAlgorithm(BinaryData);
			ElsIf Context.DataType = "Signature" Then
				SignAlgorithm = DigitalSignatureInternalClientServer.GeneratedSignAlgorithm(BinaryData);
			Else
				Raise NStr("vi = 'Dữ liệu để tìm kiếm chương trình mã hóa không phải là chứng thư hoặc chữ ký.';
							|ru = 'Данные для поиска приложения криптографии не являются сертификатом или подписью.';
							|en = 'The data to search for a cryptography app is not a certificate or a signature.'; fa = 'The data to search for a cryptography app is not a certificate or a signature.';
							|it = 'Данные для поиска приложения криптографии не являются сертификатом или подписью.';
							|pl = 'The data to search for a cryptography app is not a certificate or a signature.';
							|tr = 'Kriptografi programı arama verisi bir sertifika veya imza değildir.'");
			EndIf;
			Context.SignAlgorithms.Add(SignAlgorithm);
		EndIf;
	EndIf;
	
	Result = DigitalSignatureInternalCached.InstalledCryptoProviders();
	
	CheckResult = New Structure("Error, CheckCompleted");
	CheckResult.Insert("Programs", New Array);
	CheckResult.Insert("IsConflictPossible", False);
	FillPropertyValues(CheckResult, Result);
	If Not CheckResult.CheckCompleted Then
		Return CheckResult;
	EndIf;
	
	DigitalSignatureInternalClientServer.DoProcessAppsCheckResult(Result.Cryptoproviders,
		CheckResult.Programs, CheckResult.IsConflictPossible, Context);
		
	Return CheckResult;
	
EndFunction

// Checks the validity of the signature and the certificate.
// For operations using platform tools only (CryptoManager).
//
// Parameters:
//   CryptoManager - Undefined - get a crypto manager to check
//                          digital signatures as it was configured by the administrator.
//                        - CryptoManager - Cryptographic manager to be used.
//
//   RawData       - BinaryData - binary data that was signed.
//                        - String         - an address of a temporary storage with binary data.
//                        - String         - a full name of a file that contains
//                                           signed binary data.
//                        - Structure:
//                           * XMLEnvelope       - String - the signed XMLEnvelope,
//                                                         see also the XMLEnvelope function.
//                           * XMLDSigParameters - See DigitalSignature.XMLDSigParameters
//                        - Structure:
//                           * CMSParameters - See DigitalSignature.CMSParameters
//                           * Data  - String - custom string for signing,
//                                     - BinaryData - binary data for signing.
//
//   Signature              - BinaryData - digital signature binary data.
//                        - String         - an address of a temporary storage with binary data.
//                        - String         - a full name of a file that contains digital signature
//                                           binary data.
//                        - Undefined   - if SourceData is a SOAP envelope.
//
//   ErrorDescription       - Null - raise an exception if an error occurs during the check.
//                        - String - contains an error description if an error occurred.
// 
//   OnDate               - Date - Date for checking the certificate if the date cannot be extracted
//                          from the signature or XMLEnvelope is to be checked.
//                          If the parameter is not passed, use the current session date
//                          if the date cannot be extracted from the signature or XMLEnvelope is to be checked.
//   ResultStructure   - See DigitalSignatureClientServer.SignatureVerificationResult.
//
// Returns:
//  Boolean - True if the check is completed successfully.
//           False if the crypto manager is not received (because it is not specified)
//                   or an error specified in the ErrorDescription parameter has occurred.
//
Function VerifySignature(CryptoManager, RawData, Signature, ErrorDescription = Null, OnDate = Undefined, ResultStructure = Undefined) Export
	
	If ResultStructure <> Undefined Then
		ExpectedValues = New Array;
		ExpectedValues.Add(DigitalSignatureInternalClientServer.VerifyQualified());
		ExpectedValues.Add(DigitalSignatureInternalClientServer.QualifiedOnly());
		ExpectedValues.Add(DigitalSignatureInternalClientServer.NotVerifyCertificate());
		CommonClientServer.CheckParameter("DigitalSignature.VerifySignature",
			"ResultStructure.CertificateVerificationParameters", ResultStructure.CertificateVerificationParameters, Type("String"),, ExpectedValues);
	EndIf;

	CheckResult = False;
	InvalidHash = Undefined;
	DateSignedFromLabels = Undefined;
	SignatureProperties = Undefined;
	
	RaiseException1 = ErrorDescription = Null;
	
	SourceDataToCheck = RawData;
	If TypeOf(RawData) = Type("String") And IsTempStorageURL(RawData) Then
		SourceDataToCheck = GetFromTempStorage(RawData);
	EndIf;
	
	IsXMLDSig = TypeOf(SourceDataToCheck) = Type("Structure")
		And SourceDataToCheck.Property("XMLDSigParameters");
	
	If IsXMLDSig Then
		If Not SourceDataToCheck.Property("XMLEnvelope") Then
			SourceDataToCheck = New Structure(New FixedStructure(SourceDataToCheck));
			SourceDataToCheck.Insert("XMLEnvelope", SourceDataToCheck.SOAPEnvelope);
		EndIf;
		XMLEnvelopeProperties = DigitalSignatureInternal.XMLEnvelopeProperties(
			SourceDataToCheck.XMLEnvelope, SourceDataToCheck.XMLDSigParameters, True);
		If XMLEnvelopeProperties <> Undefined
		   And ValueIsFilled(XMLEnvelopeProperties.ErrorText) Then
			ErrorDescription = XMLEnvelopeProperties.ErrorText;
			FillSignatureVerificationResult(ErrorDescription, ResultStructure);
			If RaiseException1 Then
				Raise ErrorDescription;
			EndIf;
			Return CheckResult;
		EndIf;
	EndIf;
	
	IsCMS = TypeOf(SourceDataToCheck) = Type("Structure")
		And SourceDataToCheck.Property("CMSParameters");
	
	If TypeOf(Signature) = Type("String") And IsTempStorageURL(Signature) Then
		SignatureToCheck = GetFromTempStorage(Signature);
	Else
		SignatureToCheck = Signature;
	EndIf;
	
	CryptoManagerToCheck = CryptoManager;
	
	If CryptoManagerToCheck = Undefined Then
		UseDigitalSignatureSaaS = Not IsXMLDSig And Not IsCMS
			And DigitalSignatureInternal.UseDigitalSignatureSaaS();
		
		CreationParameters = DigitalSignatureInternal.CryptoManagerCreationParameters();
		CreationParameters.ShowError = RaiseException1 And Not UseDigitalSignatureSaaS;
		If TypeOf(SignatureToCheck) = Type("BinaryData") Then
			CreationParameters.SignAlgorithm =
				DigitalSignatureInternalClientServer.GeneratedSignAlgorithm(SignatureToCheck);
		ElsIf IsXMLDSig Then
			If XMLEnvelopeProperties = Undefined Then
				CertificateData = DigitalSignatureInternalClientServer.CertificateFromSOAPEnvelope(
					SourceDataToCheck.XMLEnvelope, False);
			Else
				CertificateData = Base64Value(XMLEnvelopeProperties.Certificate.CertificateValue);
			EndIf;
			
			CreationParameters.SignAlgorithm =
				DigitalSignatureInternalClientServer.CertificateSignAlgorithm(CertificateData);
		EndIf;
		
		CryptoManagerToCheck = DigitalSignatureInternal.CryptoManager(
			"CheckSignature", CreationParameters);
		
		If CryptoManagerToCheck = Undefined Then
			ErrorDescription = CreationParameters.ErrorDescription;
			If Not UseDigitalSignatureSaaS Then
				If ResultStructure <> Undefined Then
					SignatureProperties = DigitalSignatureInternal.SignaturePropertiesFromBinaryData(SignatureToCheck, True);
					If ValueIsFilled(SignatureProperties.Certificate) Then
						Certificate = SignatureProperties.Certificate;
						CertificateProperties = CertificateProperties(Certificate);
						SignatureProperties.Certificate = Certificate;
						SignatureProperties.Thumbprint = CertificateProperties.Thumbprint;
						SignatureProperties.CertificateOwner = CertificateProperties.IssuedTo;
					EndIf;
					FillPropertyValues(ResultStructure, SignatureProperties);
					FillSignatureVerificationResult(ErrorDescription, ResultStructure, True);
				EndIf;
				If RaiseException1 Then
					Raise ErrorDescription;
				EndIf;
				Return CheckResult;
			EndIf;
		EndIf;
		
	EndIf;
	
	If IsXMLDSig Then
		Try
			Result = DigitalSignatureInternal.VerifySignature(
				SourceDataToCheck.XMLEnvelope,
				SourceDataToCheck.XMLDSigParameters,
				CryptoManagerToCheck,
				XMLEnvelopeProperties);
		Except
			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			FillSignatureVerificationResult(ErrorDescription, ResultStructure);
			If RaiseException1 Then
				Raise;
			EndIf;
			Return CheckResult;
		EndTry;
		Certificate     = Result.Certificate;
		DateToVerifySignatureCertificate = Result.SigningDate;
		
		If ResultStructure <> Undefined Then
			ResultStructure.UnverifiedSignatureDate = DateToVerifySignatureCertificate;
			CertificateProperties = CertificateProperties(Certificate);
			ResultStructure.Certificate = Certificate.Unload();
			ResultStructure.Thumbprint = CertificateProperties.Thumbprint;
			ResultStructure.CertificateOwner = CertificateProperties.IssuedTo;
		EndIf;
		
	ElsIf IsCMS Then
		Try
			Result = DigitalSignatureInternal.CheckCMSSignature(
				SignatureToCheck,
				SourceDataToCheck.Data,
				SourceDataToCheck.CMSParameters,
				CryptoManagerToCheck);
		Except
			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			FillSignatureVerificationResult(ErrorDescription, ResultStructure);
			If RaiseException1 Then
				Raise;
			EndIf;
			Return CheckResult;
		EndTry;
		
		Certificate     = Result.Certificate;
		DateToVerifySignatureCertificate = Result.SigningDate;
		
		If ResultStructure <> Undefined Then
			SignatureProperties = DigitalSignatureInternal.SignaturePropertiesFromBinaryData(SignatureToCheck, False);
			CertificateProperties = CertificateProperties(Certificate);
			SignatureProperties.Certificate = Certificate.Unload();
			SignatureProperties.Thumbprint = CertificateProperties.Thumbprint;
			SignatureProperties.CertificateOwner = CertificateProperties.IssuedTo;
			FillPropertyValues(ResultStructure, SignatureProperties);
		EndIf;
		
	ElsIf CryptoManagerToCheck = Undefined
	      Or CryptoManagerToCheck = "CryptographyService" Then
		
		ModuleCryptographyService = Common.CommonModule("CryptographyService");
		
		Try
			Result = ModuleCryptographyService.VerifySignature(SignatureToCheck, SourceDataToCheck);
		Except
			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			FillSignatureVerificationResult(ErrorDescription, ResultStructure, True);
			If RaiseException1 Then
				Raise;
			EndIf;
			Return CheckResult;
		EndTry;
		
		SignatureProperties = DigitalSignatureInternal.SignaturePropertiesFromBinaryData(SignatureToCheck, True);
		If ResultStructure <> Undefined Then
			FillPropertyValues(ResultStructure, SignatureProperties);
		EndIf;
		
		If Not SignatureProperties.Success Then
			ErrorDescription = SignatureProperties.ErrorText;
			FillSignatureVerificationResult(ErrorDescription, ResultStructure);
			If RaiseException1 Then
				Raise ErrorDescription;
			EndIf;
			Return CheckResult;
		EndIf;
		
		If SignatureProperties.Certificate = Undefined Then
			ErrorDescription = NStr("vi = 'Chứng chỉ không tồn tại trong dữ liệu chữ ký.';
									|ru = 'Сертификат не существует в данных подписи.';
									|en = 'The certificate does not exist in signature data.'; fa = 'The certificate does not exist in signature data.';
									|it = 'Il certificato non esiste nei dati di firma.';
									|pl = 'Certyfikat nie istnieje w danych podpisu.';
									|tr = 'Sertifika imza verilerde mevcut değil.'");
			FillSignatureVerificationResult(ErrorDescription, ResultStructure);
			If RaiseException1 Then
				Raise ErrorDescription;
			EndIf;
			Return CheckResult;
		EndIf;
		
		If Not Result Then
			ErrorDescription = DigitalSignatureInternalClientServer.ServiceErrorTextSignatureInvalid();
			FillSignatureVerificationResult(ErrorDescription, ResultStructure);
			If RaiseException1 Then
				Raise ErrorDescription;
			EndIf;
			Return CheckResult;
		EndIf;
		
		If ResultStructure <> Undefined Then
			FillPropertyValues(ResultStructure, SignatureProperties);
		EndIf;
		
		Certificate = SignatureProperties.Certificate;
		
		DateToVerifySignatureCertificate = DigitalSignatureInternalClientServer.DateToVerifySignatureCertificate(SignatureProperties);
		If Not ValueIsFilled(DateToVerifySignatureCertificate) Then
			DateToVerifySignatureCertificate = OnDate;
		EndIf;
	Else
		Certificate = Undefined;
		
		SignatureVerificationError = "";
		Try
			CryptoManagerToCheck.VerifySignature(SourceDataToCheck, SignatureToCheck, Certificate, False);
			InvalidHash = False;
		Except
			InvalidHash = True;
			SignatureVerificationError = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndTry;
		
		SignatureProperties = DigitalSignatureInternal.SignaturePropertiesReadByCryptoManager(
				SignatureToCheck, CryptoManagerToCheck, Certificate = Undefined);
		If IsBlankString(SignatureVerificationError) And SignatureProperties.SignatureType <> Enums.CryptographySignatureTypes.NormalCMS
			And SignatureProperties.SignatureType <> Enums.CryptographySignatureTypes.BasicCAdESBES Then
			Try
				CryptoManagerToCheck.VerifySignature(SourceDataToCheck, SignatureToCheck,
					Certificate, True);
			Except
				SignatureVerificationError = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			EndTry;
		EndIf;
		
		CertificateProperties = Undefined;
		If ResultStructure <> Undefined Then
			FillPropertyValues(ResultStructure, SignatureProperties);
			If Not ValueIsFilled(ResultStructure.Certificate)
				And DigitalSignatureInternalClientServer.IsCertificateExists(Certificate) Then
				CertificateProperties = CertificateProperties(Certificate);
				ResultStructure.Certificate = Certificate.Unload();
				ResultStructure.Thumbprint = CertificateProperties.Thumbprint;
				ResultStructure.CertificateOwner = CertificateProperties.IssuedTo;
			EndIf;
		EndIf;
		
		If Not IsBlankString(SignatureVerificationError) Then
			ErrorDescription = SignatureVerificationError;
			FillSignatureVerificationResult(ErrorDescription, ResultStructure, Undefined, InvalidHash);
			If RaiseException1 Then
				Raise ErrorDescription;
			EndIf;
			Return CheckResult;
		EndIf;
		
		DateToVerifySignatureCertificate = DigitalSignatureInternalClientServer.DateToVerifySignatureCertificate(SignatureProperties);
		If Not ValueIsFilled(DateToVerifySignatureCertificate) Then
			DateToVerifySignatureCertificate = OnDate;
		EndIf;
		
	EndIf;
	
	If RaiseException1 Then
		ErrorDescription = Null;
	EndIf;
	
	If ResultStructure = Undefined 
		Or ResultStructure.CertificateVerificationParameters <> DigitalSignatureInternalClientServer.NotVerifyCertificate() Then
			
		AdditionalParameters = DigitalSignatureInternal.AdditionalCertificateVerificationParameters();
		AdditionalParameters.ToVerifySignature = True;
		If SignatureProperties <> Undefined And ValueIsFilled(SignatureProperties.DateSignedFromLabels) Then 
			AdditionalParameters.IsTimestampDateSpecified = True;
		EndIf;
		If ResultStructure = Undefined Then
			AdditionalParameters.PerformCAVerification = DigitalSignatureInternalClientServer.VerifyQualified();
		Else
			AdditionalParameters.PerformCAVerification = ResultStructure.CertificateVerificationParameters;
		EndIf;
		
		If ValueIsFilled(SignatureProperties) And SignatureProperties.SignatureType = Enums.CryptographySignatureTypes.ArchivalCAdESAv3 Then
			AdditionalParameters.IgnoreCertificateRevocationStatus = True;
		EndIf;
		
		CertificateVerificationResult = DigitalSignatureInternal.CheckCertificate(
			CryptoManagerToCheck, Certificate, ErrorDescription, DateToVerifySignatureCertificate, AdditionalParameters);
		
		If CertificateVerificationResult = True Then
			FillSignatureVerificationResult(True, ResultStructure);
		Else
			FillSignatureVerificationResult(ErrorDescription, ResultStructure, Undefined, False);
		EndIf;
		
	Else
		CertificateVerificationResult = True;
		FillSignatureVerificationResult(True, ResultStructure);
	EndIf;
		
	Return CertificateVerificationResult;
	
EndFunction

// Checks the crypto certificate validity.
// For operations using platform tools only (CryptoManager).
//
// Parameters:
//   CryptoManager - Undefined - get the crypto manager automatically.
//                        - CryptoManager - Cryptographic manager to be used.
//
//   Certificate           - CryptoCertificate - a certificate.
//                        - BinaryData - certificate binary data.
//                        - String - an address of a temporary storage that contains certificate binary data.
//
//   ErrorDescription       - Null - raise an exception if an error occurs during the check.
//                        - String - contains an error description if an error occurred.
//
//   OnDate               - Date - Check the certificate on the specified date.
//                          If the parameter is not specified or an empty value is passed,
//                          check on the current session date.
//   CheckParameters -  See DigitalSignatureClient.CertificateVerificationParameters
//
// Returns:
//  Boolean - True if the check is completed successfully.
//           False if the cryptographic manager is not received (because it is not specified).
//
Function CheckCertificate(CryptoManager, Certificate, ErrorDescription = Null, OnDate = Undefined, CheckParameters = Undefined) Export
	
	Return DigitalSignatureInternal.CheckCertificate(CryptoManager, Certificate, ErrorDescription, OnDate, CheckParameters);
	
EndFunction

// Gets certificate thumbprints of the OS user in the Base64 format.
// 
// Parameters:
//
//  OnlyPersonal - Boolean - if False, recipient certificates are added to the personal certificates.
//  ErrorDescription - Null - raise an exception if an error occurs during the check.
//                 - String - Contains error details (if occurred).
//  Service - Boolean - Flag indicating whether the service should return the thumbprints.
//
// Returns:
//  Map of KeyAndValue:
//    * Key - String - Certificate thumbprint in the Base64 format.
//    * Value - String - Received from: "Server" or "Service". 
//
Function CertificateThumbprints(OnlyPersonal, ErrorDescription = Null, Service = True) Export
	
	Thumbprints = New Map;
	
	If Service Then
		ThumbprintsArray = DigitalSignatureInternal.ServiceCertificateThumbprints();
		For Each Thumbprint In ThumbprintsArray Do
			Thumbprints.Insert(Thumbprint, "Service");
		EndDo;
	EndIf;

	ThumbprintsArray = DigitalSignatureInternal.CertificateThumbprints(OnlyPersonal, ErrorDescription);
	For Each Thumbprint In ThumbprintsArray Do
		Thumbprints.Insert(Thumbprint, "Server");
	EndDo;

	Return Thumbprints;

EndFunction

// Finds a certificate on the computer by a thumbprint string.
// For operations using platform tools only (CryptoManager).
//
// Parameters:
//   Thumbprint              - String - a Base64 coded certificate thumbprint.
//   InPersonalStorageOnly - Boolean - if True, search in the Personal store, otherwise, search everywhere.
//
// Returns:
//   CryptoCertificate - Certificate for digital signing and encryption.
//   Undefined - the certificate does not exist in the store.
//
Function GetCertificateByThumbprint(Thumbprint, InPersonalStorageOnly) Export
	
	Return DigitalSignatureInternal.GetCertificateByThumbprint(Thumbprint, InPersonalStorageOnly);
	
EndFunction

// Populates the DigitalSignatureAndEncryptionApplications catalog. For example, during an infobase update.
// Supports only 1C:Enterprise tools (CryptoManager).
//
// Bundled with ViPNet and CryptoPro.
// If an app with the given name and type already exists, its properties will be updated.
// The new property values are not validated.
//
// You can use the provided app details stored in ApplicationsSettingsToSupply of the DigitalSignatureAndEncryptionApplications catalog manager module.
// 
// 
//
// Parameters:
//  ApplicationsDetails - Array - For details, See DigitalSignature.NewApplicationDetails.
//                              Structure properties:
//   * ApplicationName  - String - a unique app name given by its developer,
//                       for example, Signal-COM CPGOST Cryptographic Provider.
//   * ApplicationType  - Number - Number that defines the app type and complements the app name.
//                       If Name and Type of an app are specified or you need to update individual properties, then the following parameters are required.
//
//   
//   
//
//   * Presentation       - String - an app name that a user will see,
//                             for example, Signal-COM CSP (RFC 4357).
//   * SignAlgorithm     - String - Name of the signature algorithm that
//                             the specified app supports. For example, ECR3410-CP.
//   * HashAlgorithm - String - Name of the hashing algorithm that
//                             the specified app supports, for example, ENG-HASH-CP. This algorithm prepares data
//                             during signature generation with the signature algorithm.
//   * EncryptAlgorithm  - String - Name of the encryption algorithm that the
//                             specified app supports, for example, GOST28147.
//
// Example:
//	ApplicationsDetails = New Array;
//	
//	// Filling in additional application Signal-COM CSP (RFC 4357).
//	ApplicationDetails = DigitalSignature.NewApplicationDetails();
//	ApplicationDetails.ApplicationName = Signal-COM CPGOST Cryptographic Provider;
//	ApplicationDetails.ApplicationType = 75;
//	ApplicationsDetails.Add(ApplicationDetails);
//	
//	// Modifies the proprietary ViPNet CSP algorithm.
//	ApplicationDetails = DigitalSignature.NewApplicationDetails();
//	ApplicationDetails.ApplicationName = Infotecs Cryptographic Service Provider;
//	ApplicationDetails.ApplicationType = 2;
//	ApplicationDetails.SignAlgorithm = GOST R 34.10-2001;
//	ApplicationsDetails.Add(ApplicationDetails);
//	
//	DigitalSignature.FillApplicationsList(ApplicationsDetails);
//
Procedure FillApplicationsList(ApplicationsDetails) Export
	
	SettingsToSupply = Catalogs.DigitalSignatureAndEncryptionApplications.ApplicationsSettingsToSupply();
	
	InfobaseUpdateInProgress =
		    InfobaseUpdate.InfobaseUpdateInProgress()
		Or InfobaseUpdate.IsCallFromUpdateHandler();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Programs.Ref AS Ref,
	|	Programs.ApplicationName,
	|	Programs.ApplicationType
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionApplications AS Programs";
	
	Block = New DataLock;
	Block.Add("Catalog.DigitalSignatureAndEncryptionApplications");
	
	BeginTransaction();
	Try
		Block.Lock();
		Upload0 = Query.Execute().Unload();
		
		For Each ApplicationDetails In ApplicationsDetails Do
			Filter = New Structure;
			Filter.Insert("ApplicationName", ApplicationDetails.ApplicationName);
			Filter.Insert("ApplicationType", ApplicationDetails.ApplicationType);
			
			Rows = Upload0.FindRows(Filter);
			If Rows.Count() > 0 Then
				ApplicationObject = Rows[0].Ref.GetObject();
			Else
				ApplicationObject = Catalogs.DigitalSignatureAndEncryptionApplications.CreateItem();
			EndIf;
			
			UpdateValue(ApplicationObject.DeletionMark, False);
			If Not ValueIsFilled(ApplicationObject.UsageMode) Then
				UpdateValue(ApplicationObject.UsageMode, Enums.DigitalSignatureAppUsageModes.Configured);
			EndIf;
			
			Rows = SettingsToSupply.FindRows(Filter);
			For Each KeyAndValue In ApplicationDetails Do
				FieldName = ?(KeyAndValue.Key = "Presentation", "Description", KeyAndValue.Key);
				If KeyAndValue.Value <> Undefined Then
					UpdateValue(ApplicationObject[FieldName], KeyAndValue.Value, True);
				ElsIf Rows.Count() > 0 Then
					UpdateValue(ApplicationObject[FieldName], Rows[0][KeyAndValue.Key], True);
				EndIf;
			EndDo;
			
			If Not ApplicationObject.Modified() Then
				Continue;
			EndIf;
			
			If InfobaseUpdateInProgress Then
				InfobaseUpdate.WriteData(ApplicationObject);
			Else
				ApplicationObject.Write();
			EndIf;
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// To use in the DigitalSignature.FillApplicationsList procedure.
// For operations using platform tools only (CryptoManager).
//
// Parameters:
//  ApplicationName - String - a name of the digital signature and encryption application.
//  ApplicationType - String - App type.
//
// Returns:
//  Structure - To pass in the DigitalSignature.FillApplicationsList procedure 
//              See the procedure comments for the property details.
//
Function NewApplicationDetails(ApplicationName = Undefined, ApplicationType = Undefined) Export
	
	ApplicationDetails = New Structure;
	ApplicationDetails.Insert("ApplicationName", ApplicationName);
	ApplicationDetails.Insert("ApplicationType", ApplicationType);
	ApplicationDetails.Insert("Presentation");
	ApplicationDetails.Insert("SignAlgorithm");
	ApplicationDetails.Insert("HashAlgorithm");
	ApplicationDetails.Insert("EncryptAlgorithm");
	
	Return ApplicationDetails;
	
EndFunction

// See DigitalSignatureClient.XMLEnvelope.
Function XMLEnvelope(Parameters) Export
	
	Return DigitalSignatureInternalClientServer.XMLEnvelope(Parameters);
	
EndFunction

// See DigitalSignatureClient.XMLEnvelopeParameters.
Function XMLEnvelopeParameters() Export
	
	Return DigitalSignatureInternalClientServer.XMLEnvelopeParameters();
	
EndFunction

// See DigitalSignatureClient.XMLDSigParameters.
Function XMLDSigParameters() Export
	
	Return DigitalSignatureInternalClientServer.XMLDSigParameters();
	
EndFunction

// See DigitalSignatureClient.CMSParameters.
Function CMSParameters() Export
	
	Return DigitalSignatureInternalClientServer.CMSParameters();
	
EndFunction

// Returns the result of the CA check.
// 
// Parameters:
//  Certificate - CryptoCertificate
//  OnDate - Undefined, Date - If not specified, the check uses the session date.
//  CheckParameters - Structure:
//   * ThisVerificationSignature - Boolean - Signature check flag. The warning (not an error) will not be filled.
//   * VerifyCertificate - String - 
//       "VerifyQualified" - (Default) Allow signing with NES and validate QES against the list of trusted non-accredited CAs. 
//                                      "QualifiedOnly" - Allow signing with QES only and ignore the list of trusted non-accredited CAs.
//       
//                                   
//
// Returns:
//  Structure - Result of the default CA check.:
//   * Valid - Boolean - Flag indicating whether the CA is valid on the date or the check was not performed 
//                 (the certificate is unqualified or CA is missing from the list of qualified CAs)
//   * FoundintheListofCAs - Boolean - Qualified certificate flag
//   * IsState - Boolean - Flag indicating whether the CA is trusted and some checks must be skipped.
//                                For example, in Russia, they include: Treasury of the Russian Federation, Bank of Russia,
//   Federal Tax Service Certification Authority.
//   * ThisIsQualifiedCertificate - Boolean - Flag indicating whether the certificate was issued by an accredited CA.
//   * Warning - Structure - Error or warning on the certificate.:
//                       ** ErrorText - String
//                       ** PossibleReissue - Boolean - Flag indicating whether users can apply for a new certificate from the app.
//                       ** Cause - String - Error reason for display in the extended error form.
//                       ** Decision - String - Solution for display in the extended error form.
//
Function ResultofCertificateAuthorityVerification(Certificate, OnDate = Undefined, CheckParameters = Undefined) Export
	
	Return DigitalSignatureInternal.ResultofCertificateAuthorityVerification(Certificate, OnDate, CheckParameters);
	
EndFunction

// Saves the current user settings to work with the digital signature.
// 
// Parameters:
//  PersonalSettings - See PersonalSettings
//
Procedure SavePersonalSettings(PersonalSettings) Export
	
	DigitalSignatureInternal.SavePersonalSettings(PersonalSettings);
	
EndProcedure

// Checks whether the CA service has completed processing the submitted application,
// updates the application status, and retrieves the certificate from the CA service if available.
// The certificate is not installed automatically after retrieval.
//
// Parameters:
//   Certificate - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates
//
//  Returns:
//   Undefined - The certificate has been installed and is ready for use, or it does not contain a certificate issuance request.
//   Structure:
//     * IsApplicationProcessed - Boolean - If "False", the CA service is processing the application.
//     * IsApplicationRejected  - Boolean - If "True", the CA service has rejected the application.
//
Function CertificateIssuanceApplicationState(Certificate) Export
	
	Result = New Structure;
	Result.Insert("IsApplicationProcessed", False);
	Result.Insert("IsApplicationRejected", False);
	
	DigitalSignatureLocalization.OnGetCertificateIssuanceApplicationStatus(Certificate, Result);
	
	Return Result;
	
EndFunction

#EndRegion

// Returns the availability of creating an application for
// qualified certificates issue for companies and individuals.
// It is required to hide commands using the AddCertificate
// procedure of the DigitalSignatureClient common module
// in the application creation mode.
//
// Returns:
//  Structure:
//   * ForIndividuals - Boolean
//   * ForHeadsLegalEntities - Boolean
//   * ForEmployeesLegalEntities - Boolean
//   * ForSoleProprietors - Boolean
//
Function AvailabilityOfCreatingAnApplication() Export
	
	TheApplicationIsAvailable = CommonSettings().CertificateIssueRequestAvailable;
	
	AvailabilityOfCreatingAnApplication = New Structure;
	AvailabilityOfCreatingAnApplication.Insert("ForIndividuals", TheApplicationIsAvailable);
	AvailabilityOfCreatingAnApplication.Insert("ForHeadsLegalEntities", TheApplicationIsAvailable);
	AvailabilityOfCreatingAnApplication.Insert("ForEmployeesLegalEntities", TheApplicationIsAvailable);
	AvailabilityOfCreatingAnApplication.Insert("ForSoleProprietors", TheApplicationIsAvailable);
	
	DigitalSignatureLocalization.OnDetermineAvailabilityOfApplicationCreation(AvailabilityOfCreatingAnApplication);
	
	Return AvailabilityOfCreatingAnApplication;
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Deprecated. Always returns True.
//
// Returns:
//  Boolean - if True, digital signatures are used.
//
Function AvailableAdvancedSignature() Export
	
	Return True;

EndFunction

// Deprecated. Instead, use "ObjectSignatures".
// Returns object signatures.
//
// Parameters:
//  Object - DefinedType.SignedObject - a reference to the signed object.
//             The object must have the SignedWithDS attribute.
//
//  SequenceNumber - Number
//                  - Array of Number
//  ShouldReturnMachineReadableLOAData - Boolean - If True and there is a machine-readable LoA for the signature, populate the ResultOfSignatureVerificationByMRLOA property
//
// Returns:
//  Array of See DigitalSignatureClientServer.NewSignatureProperties 
//
Function SetSignatures(Object, SequenceNumber = Undefined, ShouldReturnMachineReadableLOAData = False) Export
	
	CheckParameterObject(Object, "DigitalSignature.SetSignatures", True);
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.CheckReadAllowed(Object);
	EndIf;
	
	If Common.IsReference(TypeOf(Object)) Then
		ObjectRef = Object;
	Else
		ObjectRef = Object.Ref;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	DigitalSignatures.Signature AS Signature,
		|	DigitalSignatures.SequenceNumber AS SequenceNumber,
		|	DigitalSignatures.SignatureSetBy AS SignatureSetBy,
		|	DigitalSignatures.Comment AS Comment,
		|	DigitalSignatures.SignatureDate AS SignatureDate,
		|	DigitalSignatures.SignatureValidationDate AS SignatureValidationDate,
		|	DigitalSignatures.SignatureCorrect AS SignatureCorrect,
		|	DigitalSignatures.Thumbprint AS Thumbprint,
		|	DigitalSignatures.CertificateOwner AS CertificateOwner,
		|	DigitalSignatures.SignatureType AS SignatureType,
		|	DigitalSignatures.IsVerificationRequired AS IsVerificationRequired,
		|	DigitalSignatures.DateActionLastTimestamp AS DateActionLastTimestamp,
		|	DigitalSignatures.SignatureID AS SignatureID,
		|	DigitalSignatures.IsSignatureMathematicallyValid,
		|	DigitalSignatures.SignatureMathValidationError,
		|	DigitalSignatures.AdditionalAttributesCheckError,
		|	DigitalSignatures.IsAdditionalAttributesCheckedManually,
		|	DigitalSignatures.AdditionalAttributesManualCheckAuthor,
		|	DigitalSignatures.AdditionalAttributesManualCheckJustification
		|FROM
		|	InformationRegister.DigitalSignatures AS DigitalSignatures
		|WHERE
		|	DigitalSignatures.SignedObject = &SignedObject
		|	AND DigitalSignatures.SequenceNumber IN (&SequenceNumber)
		|
		|ORDER BY
		|	SequenceNumber";
	
	Query.SetParameter("SignedObject", ObjectRef);
	
	If SequenceNumber = Undefined Then
		Query.Text = StrReplace(Query.Text, "AND DigitalSignatures.SequenceNumber IN (&SequenceNumber)", "");
	Else
		Query.SetParameter("SequenceNumber", SequenceNumber);
	EndIf;
	
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	
	// StandardSubsystems.MachineReadableLettersOfAuthority
	SelectionMRLOADetailedRecords = Undefined;
	
	If Not QueryResult.IsEmpty() And ShouldReturnMachineReadableLOAData
		And Common.SubsystemExists("StandardSubsystems.MachineReadableLettersOfAuthority") Then
		
		SignaturesIDs = New Array;
		While SelectionDetailRecords.Next() Do
			SignaturesIDs.Add(SelectionDetailRecords.SignatureID);
		EndDo;
		SelectionDetailRecords.Reset();
		
		ModuleMachineReadableLettersOfAuthorityFTSInternal = Common.CommonModule("MachineReadableLettersOfAuthorityFTSInternal");
		SelectionMRLOADetailedRecords = ModuleMachineReadableLettersOfAuthorityFTSInternal.MRLOAOfSignatures(ObjectRef, SignaturesIDs);
		
	EndIf;
	// End StandardSubsystems.MachineReadableLettersOfAuthority
	
	SignatureFilesExtension = PersonalSettings().SignatureFilesExtension;
	DigitalSignaturesArray = New Array;
	While SelectionDetailRecords.Next() Do
		SignatureProperties = DigitalSignatureClientServer.NewSignatureProperties();
		SignatureProperties.SignedObject = Object;
		FillPropertyValues(SignatureProperties, SelectionDetailRecords);
		SignatureProperties.Signature = SignatureProperties.Signature.Get();
		SignatureProperties.Certificate = DigitalSignatureInternal.CertificateFromSignatureBinaryData(SignatureProperties.Signature, True);
		
		SignedObjectName = Common.ObjectAttributeValue(ObjectRef, "Description");
		SignatureProperties.SignatureFileName = DigitalSignatureClientServer.SignatureFileName(SignedObjectName,
			SelectionDetailRecords.CertificateOwner, SignatureFilesExtension);
		
		// StandardSubsystems.MachineReadableLettersOfAuthority
		If SelectionMRLOADetailedRecords <> Undefined Then
			ModuleMachineReadableLettersOfAuthorityFTSInternal.FillInMRLOASignatureDetails(SignatureProperties, SelectionMRLOADetailedRecords);
		EndIf;
		// End StandardSubsystems.MachineReadableLettersOfAuthority
		
		DigitalSignaturesArray.Add(SignatureProperties);
	EndDo;
	
	Return DigitalSignaturesArray;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Binary data signature.
// 
// Parameters:
//  SignatureData - BinaryData
//                - String - Address in the temp storage.
// 
// Returns:
//  BinaryData - Signature from the DER-encoded binary data.
//
Function DERSignature(SignatureData) Export
	
	BinaryData = DigitalSignatureInternalClientServer.BinaryDataFromTheData(SignatureData,
		"DigitalSignature.DERSignature");
	
	TempFileFullName = GetTempFileName();
	BinaryData.Write(TempFileFullName);
	Text = New TextDocument;
	Text.Read(TempFileFullName);
	
	Try
		DeleteFiles(TempFileFullName);
	Except
		WriteLogEvent(
			NStr("vi = 'Chữ ký điện tử.Xóa tệp tạm thời';
				|ru = 'Электронная подпись.Удаление временного файла';
				|en = 'Digital signature.Delete temporary file'; fa = 'Digital signature.Delete temporary file';
				|it = 'Firma elettronica. Eliminazione del file temporaneo';
				|pl = 'Podpis elektroniczny.Usuń plik tymczasowy';
				|tr = 'Dijital imza.Geçici dosyanın silinmesi'",
				Common.DefaultLanguageCode()),
			EventLogLevel.Error, , ,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Base64Row = Undefined;
	If Text.LineCount() > 3 And StrStartsWith(Text.GetLine(1), "-----BEGIN")
		And StrStartsWith(Text.GetLine(Text.LineCount()), "-----END") Then
		Text.DeleteLine(1);
		Text.DeleteLine(Text.LineCount());
		Base64Row = Text.GetText();
	ElsIf StrStartsWith(Text.GetLine(1), "MI") Then
		Base64Row = Text.GetText();
	EndIf;
	
	If Base64Row <> Undefined Then
		Try
			BinaryData = Base64Value(Base64Row);
		Except
			ErrorInfo = ErrorInfo();
			Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể nhận dữ liệu từ tệp chữ ký do nguyên nhân:
						|%1';
						|ru = 'Не удалось получить данные из файла подписи по причине:
						|%1';
						|en = 'Cannot get data from the signature file. Reason:
						|%1'; fa = 'Cannot get data from the signature file. Reason:
						|%1';
						|it = 'Не удалось получить данные из файла подписи по причине:
						|%1';
						|pl = 'Cannot get data from the signature file. Reason:
						|%1';
						|tr = 'İmza dosyasında veriler alınamadı çünkü:
						|%1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo));
		EndTry;
	EndIf;
	
	Return BinaryData;
	
EndFunction

// Returns the encrypted data viewability flag.
//
// Returns:
//  Boolean - If True, users can view encrypted data.
//
Function DataDecryption() Export
	
	Return EncryptAndDecryptData()
		Or UseEncryption() And Users.RolesAvailable("DataDecryption");
		
EndFunction

// Returns the data encryption availability flag.
//
// Returns:
//  Boolean - If True, data encryption is available.
//
Function EncryptAndDecryptData() Export
	
	Return UseEncryption() And Users.RolesAvailable("EncryptAndDecryptData");
	
EndFunction

// Returns the digital signature availability flag.
//
// Returns:
//  Boolean - If True, digital signing is available.
//
Function AddEditDigitalSignatures() Export
	
	// ACC:515-off
	// The role has no rights to metadata objects except for the common form "AddDigitalSignatureFromFile".
	Return UseDigitalSignature() And Users.RolesAvailable("AddEditDigitalSignatures");
	// ACC:515-on
	
EndFunction

// Returns the flag of manageability of certificate validity period notifications and certificate delivery reminders.
// 
//
// Returns:
//  Boolean - If True, users can manage the notifications.
//
Function ManageAlertsCertificates() Export
	
	Return AccessRight("Update", Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates)
		Or AddEditDigitalSignatures() Or DataDecryption();
	
EndFunction


// Returns the current user settings to work with the digital signature.
//
// Returns:
//   Structure - Personal settings for managing the digital signature:
//       * ActionsOnSavingWithDS - String - Actions when saving digitally signed files:
//           Prompt - Show the signature selection dialog box to save a signature.
//           SaveAllSignatures - Always save signatures.
//       * PathsToDigitalSignatureAndEncryptionApplications - Map of KeyAndValue:
//           ** Key     - CatalogRef.DigitalSignatureAndEncryptionApplications - App.
//           ** Value - String - App path on the user's computer.
//       * SignatureFilesExtension - String - an extension for DS files.
//       * EncryptedFilesExtension - String - Encrypted file extension.
//       * SaveCertificateWithSignature - Boolean
//       * PathToDiagnosticsDirectory - Map of KeyAndValue:
//           ** Key - UUID - Client ID.
//           ** Value - String - Directory path.
//
// See also::
//   CommonForm.DigitalSignatureAndEncryptionSettings - a location to determine these parameters and
//   their text descriptions.
//
Function PersonalSettings() Export
	
	PersonalSettings = New Structure;
	// Initial values.
	PersonalSettings.Insert("ActionsOnSavingWithDS", "Prompt");
	PersonalSettings.Insert("PathsToDigitalSignatureAndEncryptionApplications", New Map);
	PersonalSettings.Insert("SignatureFilesExtension", "p7s");
	PersonalSettings.Insert("EncryptedFilesExtension", "p7m");
	PersonalSettings.Insert("SaveCertificateWithSignature", False);
	PersonalSettings.Insert("PathToDiagnosticsDirectory", New Map);
	
	SubsystemKey = DigitalSignatureInternal.SettingsStorageKey();
	
	For Each KeyAndValue In PersonalSettings Do
		SavedValue = Common.CommonSettingsStorageLoad(SubsystemKey,
			KeyAndValue.Key);
		
		If ValueIsFilled(SavedValue)
		   And TypeOf(KeyAndValue.Value) = TypeOf(SavedValue) Then
			
			PersonalSettings.Insert(KeyAndValue.Key, SavedValue);
		EndIf;
	EndDo;
	
	Return PersonalSettings;
	
EndFunction

// Returns encrypted data.
// 
// Parameters:
//  Data - BinaryData
//  Certificate - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates
//  EncryptAlgorithm - String - Contains an explicit name ("Magma", "Kuznyechik", or "GOST 28147-89"), OID,
//    or a presentation of the encryption algorithm that will override the default encryption algorithm.
//    For example, if the representation "Magma" is provided, it will be converted into
//    the encryption algorithm name used by the program performing the encryption."
// 
// Returns:
//  BinaryData
//
Function Encrypt(Data, Certificate, EncryptAlgorithm = "") Export
	
	If Not CommonSettings().UseEncryption Then
		Raise NStr("vi = 'Không được phép mã hóa.';
					|ru = 'Шифрование недоступно.';
					|en = 'Encryption unavailable.'; fa = 'Encryption unavailable.';
					|it = 'Шифрование недоступно.';
					|pl = 'Encryption unavailable.';
					|tr = 'Şifreleme mevcut değil.'");
	EndIf;
	
	ErrorList = New Array;

	AttributesValues = Common.ObjectAttributesValues(
		Certificate, "Application, CertificateData");
	
	Application = AttributesValues.Application;
	
	Try
		CertificateBinaryData = AttributesValues.CertificateData.Get();
		CryptoCertificate = New CryptoCertificate(CertificateBinaryData);
	Except
		ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể nhận dữ liệu chứng thư ""%1""
			           |từ cơ sở thông tin do nguyên nhân:
			           |%2';
			           |ru = 'Не удалось получить данные сертификата ""%1""
			           |из информационной базы по причине:
			           |%2';
			           |en = 'Cannot receive the ""%1"" certificate data
			           |from the infobase due to:
			           |%2'; fa = 'Cannot receive the ""%1"" certificate data
			           |from the infobase due to:
			           |%2';
			           |it = 'Не удалось получить данные сертификата ""%1""
			           |из информационной базы по причине:
			           |%2';
			           |pl = 'Cannot receive the ""%1"" certificate data
			           |from the infobase due to:
			           |%2';
			           |tr = 'Infobase''deki ""%1"" sertifika verileri
			           |şu sebeple alınamadı:
			           |%2'"),
			Certificate,
			ErrorDescription);
	EndTry;
	
	CryptoManager = Undefined;
	
	If ValueIsFilled(AttributesValues.Application) Then
		
		If TypeOf(AttributesValues.Application) = DigitalSignatureInternal.ServiceProgramTypeSignatures() Then
			
			Return DigitalSignatureInternal.EncryptInCloudSignatureService(
				Data, CertificateBinaryData, AttributesValues.Application);
		
		ElsIf Application = DigitalSignatureInternal.BuiltinCryptoprovider() Then
			
			Return DigitalSignatureInternal.EncryptByBuiltInCryptoProvider(
				Data, CertificateBinaryData);
			
		ElsIf DigitalSignatureInternal.IsCryptographyAvailable() Then

			CreationParameters = DigitalSignatureInternal.CryptoManagerCreationParameters();
			CreationParameters.Application = AttributesValues.Application;
			CreationParameters.ErrorDescription = "";
			CreationParameters.EncryptAlgorithm = EncryptAlgorithm;
			
			CryptoManager = DigitalSignatureInternal.CryptoManager("Encryption",
				CreationParameters);

			ErrorAtServer = CreationParameters.ErrorDescription;
			If ValueIsFilled(ErrorAtServer) Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể mã hóa bởi chứng thư ""%1"":
						 |%2';
						 |ru = 'Не удалось выполнить шифрование сертификатом ""%1"":
						 |%2';
						 |en = 'Cannot encrypt with the ""%1"" certificate:
						 |%2'; fa = 'Cannot encrypt with the ""%1"" certificate:
						 |%2';
						 |it = 'Не удалось выполнить шифрование сертификатом ""%1"":
						 |%2';
						 |pl = 'Cannot encrypt with the ""%1"" certificate:
						 |%2';
						 |tr = '""%1"" sertifikasının şifrelenmesi gerçekleştirilemedi:
						 |%2'"), Certificate, ErrorAtServer);
			EndIf;

			If CryptoManager = Undefined Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể mã hóa bởi chứng thư ""%1"":
						|Không thể tạo bộ quản lý mã hóa';
						|ru = 'Не удалось выполнить шифрование сертификатом ""%1"":
						|Не удалось создать менеджер криптографии';
						|en = 'Cannot encrypt with the ""%1"" certificate:
						|Cannot create a crypto manager'; fa = 'Cannot encrypt with the ""%1"" certificate:
						|Cannot create a crypto manager';
						|it = 'Не удалось выполнить шифрование сертификатом ""%1"":
						|Не удалось создать менеджер криптографии';
						|pl = 'Cannot encrypt with the ""%1"" certificate:
						|Cannot create a crypto manager';
						|tr = '""%1"" sertifikasının şifrelenmesi gerçekleştirilemedi:
						| Yönetici kriptografisi oluşturulamadı'"), Certificate);
			EndIf;

			Try
				ResultBinaryData = DigitalSignatureInternal.Encrypt(Data, CryptoCertificate,
					CryptoManager);
				Return ResultBinaryData;
			Except
				ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể mã hóa bởi chứng thư ""%1"":
						 |%2';
						 |ru = 'Не удалось выполнить шифрование сертификатом ""%1"":
						 |%2';
						 |en = 'Cannot encrypt with the ""%1"" certificate:
						 |%2'; fa = 'Cannot encrypt with the ""%1"" certificate:
						 |%2';
						 |it = 'Не удалось выполнить шифрование сертификатом ""%1"":
						 |%2';
						 |pl = 'Cannot encrypt with the ""%1"" certificate:
						 |%2';
						 |tr = '""%1"" sertifikasının şifrelenmesi gerçekleştirilemedi:
						 |%2'"), Certificate, ErrorDescription);
			EndTry;
			
		EndIf;
		
		ErrorList.Add(NStr("vi = 'Không thể mã hóa trên máy chủ.';
							|ru = 'Недоступно шифрование на сервере.';
							|en = 'Encryption on the server is unavailable.'; fa = 'Encryption on the server is unavailable.';
							|it = 'Недоступно шифрование на сервере.';
							|pl = 'Encryption on the server is unavailable.';
							|tr = 'Sunucuda şifreleme kullanılamıyor.'"));

	EndIf;
	
	SignAlgorithm = DigitalSignatureInternalClientServer.CertificateSignAlgorithm(CertificateBinaryData);
	
	If DigitalSignatureInternal.IsCryptographyAvailable() Then
	
		CreationParameters = DigitalSignatureInternal.CryptoManagerCreationParameters();
		CreationParameters.ErrorDescription	 = "";
		CreationParameters.SignAlgorithm	 = SignAlgorithm;
		CreationParameters.EncryptAlgorithm = EncryptAlgorithm;
		
		CryptoManager = DigitalSignatureInternal.CryptoManager("Encryption", CreationParameters);
		
		ErrorDescription = CreationParameters.ErrorDescription;
		
		If Not ValueIsFilled(ErrorDescription) Then
			
			If CryptoManager = Undefined Then
				ErrorDescription = NStr("vi = 'Không thể tạo bộ quản lý mã hóa';
										|ru = 'Не удалось создать менеджер криптографии';
										|en = 'Cannot create a crypto manager'; fa = 'Cannot create a crypto manager';
										|it = 'Не удалось создать менеджер криптографии';
										|pl = 'Cannot create a crypto manager';
										|tr = 'Yönetici kriptografisi oluşturulamadı'");
			Else

				Try
					ResultBinaryData = DigitalSignatureInternal.Encrypt(Data, CryptoCertificate,
						CryptoManager);
					Return ResultBinaryData;
				Except
					ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
				EndTry;

			EndIf;
			
		EndIf;
		
		ErrorList.Add(ErrorDescription);
		
	EndIf;
	
	CanBeEncryptedInCloud = StrFind(SignAlgorithm, "GOST 34.10") <> 0;
	
	If CanBeEncryptedInCloud Then
		
		If CommonSettings().ThisistheServiceModelwithEnhancementAvailable Then
			Try
				ResultBinaryData = DigitalSignatureInternal.EncryptInCloudSignatureService(Data,
				CertificateBinaryData);
				Return ResultBinaryData;
			Except
				ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
				ErrorList.Add(ErrorDescription);
			EndTry;
		EndIf;
		
		If DigitalSignatureInternal.UseDigitalSignatureSaaS() Then
			Try
				ResultBinaryData = DigitalSignatureInternal.EncryptByBuiltInCryptoProvider(Data, CertificateBinaryData);
				Return ResultBinaryData;
			Except
				ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
				ErrorList.Add(ErrorDescription);
			EndTry;
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(ErrorList) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể mã hóa bởi chứng thư ""%1"":
					 |%2';
					 |ru = 'Не удалось выполнить шифрование сертификатом ""%1"":
					 |%2';
					 |en = 'Cannot encrypt with the ""%1"" certificate:
					 |%2'; fa = 'Cannot encrypt with the ""%1"" certificate:
					 |%2';
					 |it = 'Не удалось выполнить шифрование сертификатом ""%1"":
					 |%2';
					 |pl = 'Cannot encrypt with the ""%1"" certificate:
					 |%2';
					 |tr = '""%1"" sertifikasının şifrelenmesi gerçekleştirilemedi:
					 |%2'"), Certificate, StrConcat(ErrorList, Chars.LF));
	EndIf;

	Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể mã hóa bởi chứng thư ""%1""';
						|ru = 'Не удалось выполнить шифрование сертификатом ""%1""';
						|en = 'Cannot encrypt with the ""%1"" certificate'; fa = 'Cannot encrypt with the ""%1"" certificate';
						|it = 'Не удалось выполнить шифрование сертификатом ""%1""';
						|pl = 'Cannot encrypt with the ""%1"" certificate';
						|tr = '""%1"" sertifikasının şifrelenmesi gerçekleştirilemedi'"), Certificate);
EndFunction

// Returns common settings of all users to work with the digital signature.
//
// Returns: 
//   FixedStructure - Common subsystem settings for managing digital signature:
//     * UseDigitalSignature       - Boolean - if True, digital signatures are used.
//     * UseEncryption               - Boolean - if True, encryption is used.
//     * VerifyDigitalSignaturesOnTheServer - Boolean - if True, digital signatures and
//                                                       certificates are checked on the server.
//     * GenerateDigitalSignaturesAtServer - Boolean - if True, digital signatures are created
//                                                       on the server, and if creation failed, they are created on the client.
//
//     * ApplicationsDetailsCollection - FixedArray of See DigitalSignatureInternalCached.ApplicationDetails -
//                          Information about supported cryptographic apps.
//
//     * DescriptionsOfTheProgramsOnTheLink - FixedMap of KeyAndValue:
//         ** Key - CatalogRef.DigitalSignatureAndEncryptionApplications
//         ** Value - See DigitalSignatureInternalCached.ApplicationDetails
//
// See also:
//   Common form.Electronic decryption setups - the place where these parameters are determined and
//   their text descriptions.
//
Function CommonSettings() Export
	
	Return DigitalSignatureInternalCached.CommonSettings();
	
EndFunction

#Region ScheduledJobsHandlers

// Scheduled job.
Procedure ExtendSignatureValidity() Export
	
	Common.OnStartExecuteScheduledJob(
			Metadata.ScheduledJobs.ExtendSignatureValidity);
	
	If Not UseDigitalSignature() Then
		Return;
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		
		RequireImprovementSignatures = Constants.RefineSignaturesAutomatically.Get() = 1;
		CryptoSignatureTypeDefault = Constants.CryptoSignatureTypeDefault.Get();
		If Not RequireImprovementSignatures 
			Or CryptoSignatureTypeDefault <> Enums.CryptographySignatureTypes.WithTimeCAdEST Then
			DigitalSignatureInternal.ChangeRegulatoryTaskExtensionCredibilitySignatures(,False,CryptoSignatureTypeDefault);
			Return;
		EndIf;
		
		If Not CommonSettings().ThisistheServiceModelwithEnhancementAvailable Then
			Constants.RefineSignaturesAutomatically.Set(0);
			Raise NStr("vi = 'Không thể nâng cấp chữ ký trên server. Nhiệm vụ thường kỳ đã bị tắt.';
						|ru = 'Недоступно усовершенствование подписей на сервере. Регламентное задание отключено.';
						|en = 'Cannot enhance signatures on the server. The scheduled job is disabled.'; fa = 'Cannot enhance signatures on the server. The scheduled job is disabled.';
						|it = 'Cannot enhance signatures on the server. The scheduled job is disabled.';
						|pl = 'Cannot enhance signatures on the server. The scheduled job is disabled.';
						|tr = 'Sunucuda imza iyileştirmesi kullanılamıyor. Zamanlanmış görev devre dışı bırakıldı.'");
		Else
			ServiceAccountSettings = DigitalSignatureInternal.ServiceAccountSettingsToImproveSignatures();
			If ValueIsFilled(ServiceAccountSettings.Error) Then
				Raise(ServiceAccountSettings.Error);
			EndIf;
		EndIf;
		
		RequiredAddArchiveTags = False;
	Else
		RequiredAddArchiveTags = Constants.AddTimestampsAutomatically.Get();
		CryptoSignatureTypeDefault = Constants.CryptoSignatureTypeDefault.Get();
		RequireImprovementSignatures = Constants.RefineSignaturesAutomatically.Get() = 1;
	EndIf;
	
	If (Not RequireImprovementSignatures
		Or (CryptoSignatureTypeDefault <> Enums.CryptographySignatureTypes.WithTimeCAdEST
		And CryptoSignatureTypeDefault <> Enums.CryptographySignatureTypes.ArchivalCAdESAv3))
		And Not RequiredAddArchiveTags Then
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("SignatureType");
	ExecutionParameters.Insert("RequiredAddArchiveTags");
	ExecutionParameters.Insert("TimestampServersAddresses");
	ExecutionParameters.Insert("ParametersSignatureCAdEST");
	ExecutionParameters.Insert("ServiceAccountDSS");
	
	If Not Common.DataSeparationEnabled() Then
		If RequireImprovementSignatures Or RequiredAddArchiveTags Then
			TimestampServersAddresses = CommonSettings().TimestampServersAddresses;
			If TimestampServersAddresses.Count() = 0 Then
				Raise NStr("vi = 'Chưa chỉ ra địa chỉ máy chủ dấu thời gian.';
							|ru = 'Не указаны адреса серверов меток времени.';
							|en = 'Timestamp server addresses are not specified.'; fa = 'Timestamp server addresses are not specified.';
							|it = 'Non sono indicati gli indirizzi dei server dei contrassegni di tempo.';
							|pl = 'Nie są podane adresy serwerów znaczników czasu.';
							|tr = 'Tarih etiketlerinin sunucu adresleri belirtilmedi.'");
			EndIf;
		EndIf;
		ExecutionParameters.TimestampServersAddresses = TimestampServersAddresses;
	Else
		ExecutionParameters.ServiceAccountDSS = ServiceAccountSettings.ServiceAccountDSS;
		ExecutionParameters.ParametersSignatureCAdEST = ServiceAccountSettings.ParametersSignatureCAdEST;
	EndIf;
	
	If RequireImprovementSignatures Then
		ExecutionParameters.Insert("SignatureType", CryptoSignatureTypeDefault);
	EndIf;
	ExecutionParameters.Insert("RequiredAddArchiveTags", RequiredAddArchiveTags);

	// For now, determining the initial signature type is not supported.
	If ExecutionParameters.ServiceAccountDSS = Undefined Then
		// Process unprocessed signatures with the highest priority.
		QueryOptions = New Structure;
		QueryOptions.Insert("ScheduledJob", True);
		QueryOptions.Insert("rawsignatures", True);
		DigitalSignatureInternal.ExecuteDataProcessingRegularTask(QueryOptions, ExecutionParameters);
	EndIf;
	
	If RequireImprovementSignatures
		And (CryptoSignatureTypeDefault = Enums.CryptographySignatureTypes.WithTimeCAdEST
			Or CryptoSignatureTypeDefault = Enums.CryptographySignatureTypes.ArchivalCAdESAv3) Then
		
		QueryOptions = New Structure;
		QueryOptions.Insert("ScheduledJob", True);
		QueryOptions.Insert("RequireImprovementSignatures", RequireImprovementSignatures);
		QueryOptions.Insert("RefineToType", CryptoSignatureTypeDefault);
		
		DigitalSignatureInternal.ExecuteDataProcessingRegularTask(QueryOptions, ExecutionParameters);
	EndIf;
	
	If RequiredAddArchiveTags Then
		QueryOptions = New Structure;
		QueryOptions.Insert("ScheduledJob", True);
		QueryOptions.Insert("RequiredAddArchiveTags", RequiredAddArchiveTags);
		
		DigitalSignatureInternal.ExecuteDataProcessingRegularTask(QueryOptions, ExecutionParameters);
	EndIf;

EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region AuxiliaryProceduresAndFunctions

// Intended for: AddSignature procedure.
Procedure AddSignatureRows(DataObject, PropertiesSignatures, EventLogMessage)
	
	SetPrivilegedMode(True);

	SequenceNumber = 1;

	Query = New Query;
	Query.Text =
	"SELECT
	|	COUNT(DigitalSignatures.SignedObject) AS LastSequenceNumber
	|FROM
	|	InformationRegister.DigitalSignatures AS DigitalSignatures
	|WHERE
	|	DigitalSignatures.SignedObject = &SignedObject";

	Query.SetParameter("SignedObject", DataObject.Ref);

	QueryResult = Query.Execute();

	SelectionDetailRecords = QueryResult.Select();

	While SelectionDetailRecords.Next() Do
		SequenceNumber = SelectionDetailRecords.LastSequenceNumber + 1;
	EndDo;

	If TypeOf(PropertiesSignatures) = Type("Array") Then
		SignaturePropertiesArray = PropertiesSignatures;
	Else
		SignaturePropertiesArray = CommonClientServer.ValueInArray(PropertiesSignatures);
	EndIf;

	For Each SignatureProperties In SignaturePropertiesArray Do

		NewRecord = InformationRegisters.DigitalSignatures.CreateRecordManager();
		
		NewSignatureProperties = DigitalSignatureClientServer.NewSignatureProperties();
		FillPropertyValues(NewSignatureProperties, SignatureProperties);
		FillPropertyValues(NewRecord, SignatureProperties, , "Signature");

		NewRecord.SignedObject = DataObject.Ref;
		NewRecord.Signature    = New ValueStorage(SignatureProperties.Signature, New Deflation(9));

		NewRecord.SequenceNumber = SequenceNumber;

		If Not ValueIsFilled(NewRecord.SignatureSetBy) Then
			NewRecord.SignatureSetBy = Users.AuthorizedUser();
		EndIf;
	
		SignatureDate = Undefined;
		If ValueIsFilled(CommonClientServer.StructureProperty(
			SignatureProperties, "UnverifiedSignatureDate", Undefined)) Then
			SignatureDate = SignatureProperties.UnverifiedSignatureDate;
		ElsIf ValueIsFilled(NewRecord.SignatureType) Then
			SignatureDate = SigningDate(SignatureProperties.Signature);
		Else
			SignatureParameters = DigitalSignatureInternalClientServer.SignaturePropertiesFromBinaryData(
			SignatureProperties.Signature, DigitalSignatureInternal.UTCOffset());
			If ValueIsFilled(SignatureParameters.SigningDate) Then
				SignatureDate = SignatureParameters.SigningDate;
			EndIf;
			NewRecord.SignatureType = SignatureParameters.SignatureType;
		EndIf;
		If SignatureDate <> Undefined Then
			NewRecord.SignatureDate = SignatureDate;
			
		ElsIf Not ValueIsFilled(NewRecord.SignatureDate) Then
			NewRecord.SignatureDate = CurrentSessionDate();
		EndIf;
		
		EventLogMessage = DigitalSignatureInternal.SignatureInfoForEventLog(
			NewRecord.SignatureDate, SignatureProperties);
				
		If Not ValueIsFilled(NewRecord.SignatureID) Then
			NewRecord.SignatureID = New UUID;
		EndIf;

		NewRecord.Write();
		
		// StandardSubsystems.MachineReadableLettersOfAuthority
		If ValueIsFilled(NewSignatureProperties.ResultOfSignatureVerificationByMRLOA)
			And Common.SubsystemExists("StandardSubsystems.MachineReadableLettersOfAuthority") Then
			
			ModuleMachineReadableLettersOfAuthorityFTSInternal = Common.CommonModule("MachineReadableLettersOfAuthorityFTSInternal");
			ModuleMachineReadableLettersOfAuthorityFTSInternal.AddSignatureMachineReadableLetterOfAuthority(
				DataObject.Ref, NewRecord.SignatureID, NewSignatureProperties.ResultOfSignatureVerificationByMRLOA);
			
		EndIf;
		// End StandardSubsystems.MachineReadableLettersOfAuthority
		
		WriteLogEvent(
				NStr("vi = 'Chữ ký điện tử.Thêm chữ ký';
					|ru = 'Электронная подпись.Добавление подписи';
					|en = 'Digital signature.Add signature'; fa = 'Digital signature.Add signature';
					|it = 'Firma elettronica. Aggiunta della firma';
					|pl = 'Podpis elektroniczny.Dodaj podpis';
					|tr = 'Dijital imza.İmza ekleme'", Common.DefaultLanguageCode()),
			EventLogLevel.Information, DataObject.Metadata(), DataObject.Ref,
			EventLogMessage, EventLogEntryTransactionMode.Transactional);
		
		SequenceNumber = SequenceNumber + 1;
	EndDo;
	
EndProcedure

// Intended for: DeleteSignature procedure.
Procedure DeleteSignatureRows(SignedObject, SequenceNumbers, ExpectedSignaturesIDs, EventLogMessage)
	
	HasRightsToDeleteOthersSignatures = Users.IsFullUser() 
		Or Users.RolesAvailable("RemoveDigitalSignatures");

	SetPrivilegedMode(True);

	If SequenceNumbers.Count() > 0 Then
		Query = New Query;
		Query.Text =
		"SELECT
		|	DigitalSignatures.SequenceNumber AS SequenceNumber,
		|	DigitalSignatures.SignedObject AS SignedObject,
		|	0 AS HasMRLOASignatures
		|FROM
		|	InformationRegister.DigitalSignatures AS DigitalSignatures
		|WHERE
		|	DigitalSignatures.SequenceNumber IN(&SequenceNumbersArray)
		|	AND DigitalSignatures.SignedObject = &SignedObject
		|
		|ORDER BY
		|	SequenceNumber DESC";
		
		// StandardSubsystems.MachineReadableLettersOfAuthority
		If Common.SubsystemExists("StandardSubsystems.MachineReadableLettersOfAuthority") Then
			ModuleMachineReadableLettersOfAuthorityFTSInternal = Common.CommonModule("MachineReadableLettersOfAuthorityFTSInternal");
			Query.Text = ModuleMachineReadableLettersOfAuthorityFTSInternal.QueryTextForDigitalSignaturesDeletion();
		EndIf;
		// End StandardSubsystems.MachineReadableLettersOfAuthority
		Query.SetParameter("SequenceNumbersArray", SequenceNumbers);
		Query.SetParameter("SignedObject", SignedObject.Ref);
	EndIf;
	
	BeginTransaction();
	Try

		// StandardSubsystems.MobileSignatureService
		If ExpectedSignaturesIDs.Count() > 0
			And Common.SubsystemExists("StandardSubsystems.MobileSignatureService") Then
			ModuleMobileSignatureServiceInternal = Common.CommonModule("MobileSignatureServiceInternal");
			ModuleMobileSignatureServiceInternal.DeleteExpectedObjectSignatures(SignedObject.Ref,
				ExpectedSignaturesIDs, HasRightsToDeleteOthersSignatures, EventLogMessage);
		EndIf;
		// End StandardSubsystems.MobileSignatureService

		If SequenceNumbers.Count() > 0 Then
			
			Block = New DataLock;
			LockItem = Block.Add(Metadata.InformationRegisters.DigitalSignatures.FullName());
			LockItem.SetValue("SignedObject", SignedObject.Ref);
			Block.Lock();
			
			SelectionDetailRecords = Query.Execute().Select();
			If SelectionDetailRecords.Count() <> SequenceNumbers.Count() Then
				Raise NStr("vi = 'Dòng có chữ ký không tồn tại.';
							|ru = 'Строка с подписью не существует.';
							|en = 'A signature row does not exist.'; fa = 'A signature row does not exist.';
							|it = 'La riga con firma non esiste.';
							|pl = 'Wierszu z podpisem nie istnieje.';
							|tr = 'İmzalı satır mevcut değil.'");
			EndIf;
			
			While SelectionDetailRecords.Next() Do
				RecordManager = InformationRegisters.DigitalSignatures.CreateRecordManager();
				FillPropertyValues(RecordManager, SelectionDetailRecords);
				
				RecordManager.Read();
				
				HasRights = HasRightsToDeleteOthersSignatures 
					Or RecordManager.SignatureSetBy = Users.AuthorizedUser();
				
				Certificate = DigitalSignatureInternal.CertificateFromSignatureBinaryData(RecordManager.Signature.Get());
				SignatureProperties = New Structure;
				SignatureProperties.Insert("Certificate", Certificate);
				SignatureProperties.Insert("CertificateOwner", RecordManager.CertificateOwner);
				
				EventLogMessage = DigitalSignatureInternal.SignatureInfoForEventLog(
					RecordManager.SignatureDate, SignatureProperties);
				
				If Not HasRights Then
					Raise(NStr("vi = 'Không đủ quyền để xóa chữ ký.';
								|ru = 'Недостаточно прав на удаление подписи.';
								|en = 'Insufficient rights to delete the signature.'; fa = 'Insufficient rights to delete the signature.';
								|it = 'Diritti insufficiente per l''eliminazione della firma.';
								|pl = 'Niewystarczające uprawnienia do usunięcia podpisu.';
								|tr = 'İmzanın silinmesi için yetersiz yetki.'"), ErrorCategory.AccessViolation);
				EndIf;
				RecordManager.Delete();
				
				// StandardSubsystems.MachineReadableLettersOfAuthority
				If SelectionDetailRecords.HasMRLOASignatures > 0 Then
					ModuleMachineReadableLettersOfAuthorityFTSInternal.DeleteSignatureMachineReadableLetterOfAuthority(
						SignedObject.Ref, SelectionDetailRecords.SignatureID);
				EndIf;
				// End StandardSubsystems.MachineReadableLettersOfAuthority
				
				WriteLogEvent(NStr("vi = 'Chữ ký điện tử.Xóa chữ ký';
									|ru = 'Электронная подпись.Удаление подписи';
									|en = 'Digital signature.Delete signature'; fa = 'Digital signature.Delete signature';
									|it = 'Firma elettronca. Eliminazione della firma';
									|pl = 'Podpis elektroniczny.Usuwanie podpisu';
									|tr = 'Dijital imza.İmzanın silinmesi'", Common.DefaultLanguageCode()),
					EventLogLevel.Information, SignedObject.Metadata(), SignedObject.Ref,
					EventLogMessage, EventLogEntryTransactionMode.Transactional);
				
			EndDo;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Intended for: DeleteSignature procedure.
Procedure RefreshSignaturesNumbering(SignedObject, SequenceNumbers)
	
	SetPrivilegedMode(True);
	
	SignedWithDS = False;
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.DigitalSignatures");
		LockItem.SetValue("SignedObject", SignedObject.Ref);
		Block.Lock();

		RecordSet = InformationRegisters.DigitalSignatures.CreateRecordSet();
		RecordSet.Filter.SignedObject.Set(SignedObject.Ref);
		RecordSet.Read();
		
		SignedWithDS = RecordSet.Count() > 0;

		If SequenceNumbers.Count() > 0 Then // Signatures were deleted
			SequenceNumber = 1;
			For Each ObjectDigitalSignature In RecordSet Do
				ObjectDigitalSignature.SequenceNumber = SequenceNumber;
				SequenceNumber = SequenceNumber + 1;
			EndDo;
			RecordSet.Write(True);
		EndIf;
		
		// StandardSubsystems.MobileSignatureService
		If Not SignedWithDS
			And Common.SubsystemExists("StandardSubsystems.MobileSignatureService") Then
			ModuleMobileSignatureServiceInternal = Common.CommonModule("MobileSignatureServiceInternal");
			SignedWithDS = ModuleMobileSignatureServiceInternal.HasExpectedSignatures(SignedObject.Ref);
		EndIf;
		// End StandardSubsystems.MobileSignatureService
		
		If SignedObject.SignedWithDS <> SignedWithDS Then
			SignedObject.SignedWithDS = SignedWithDS;
		EndIf;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Intended for: WriteCertificateToCatalog procedure.
Procedure UpdateValue(PreviousValue2, NewValue, SkipNotDefinedValues = False)
	
	If NewValue = Undefined And SkipNotDefinedValues Then
		Return;
	EndIf;
	
	If PreviousValue2 <> NewValue Then
		PreviousValue2 = NewValue;
	EndIf;
	
EndProcedure

// Intended for: WriteCertificateToCatalog procedure.
// 
// Parameters:
//  User - CatalogRef.Users - a user
//  Users - CatalogTabularSection.DigitalSignatureAndEncryptionKeysCertificates.Users - users
//
Procedure AddAUserToTheCertificate(User, Users)
	
	If Users.Find(User, "User") = Undefined Then
		Users.Add().User = User;
	EndIf;
	
EndProcedure

Procedure CheckParameterObject(Object, ProcedureName, RefsOnly = False)
	
	CommonClientServer.CheckParameter(ProcedureName, "Object", Object,
		DigitalSignatureInternalCached.OwnersTypes(RefsOnly));
	
EndProcedure

Procedure FillSignatureVerificationResult(
	Result, ResultStructure, IsVerificationRequired = Undefined, InvalidHash = Undefined)
	
	If ResultStructure = Undefined Then
		Return;
	EndIf;
	
	ResultStructure.Result = Result;
	
	If Result = True Then
		ResultStructure.SignatureCorrect = True;
		ResultStructure.IsVerificationRequired = False;
		Return;
	EndIf;
	
	ResultStructure.SignatureCorrect = False;
	
	If InvalidHash = True Then
		ResultStructure.IsVerificationRequired = False;
		ResultStructure.IsSignatureMathematicallyValid = False;
		ResultStructure.SignatureMathValidationError = Result;
		Return;
	EndIf;
	
	CertificateRevoked = False;
	ClassifierError = DigitalSignatureInternal.ClassifierError(Result, True, True);
	If ClassifierError <> Undefined Then
		CertificateRevoked = ClassifierError.CertificateRevoked;
		If InvalidHash = Undefined Then
			InvalidHash = ClassifierError.InvalidSignatureHash;
		EndIf;
		If IsVerificationRequired = Undefined Then
			IsVerificationRequired = ClassifierError.IsCheckRequired;
		EndIf;
	EndIf;
		
	If InvalidHash = True Then
		ResultStructure.SignatureCorrect = False;
		ResultStructure.IsVerificationRequired = False;
		ResultStructure.IsSignatureMathematicallyValid = False;
		ResultStructure.SignatureMathValidationError = Result;
		Return;
	EndIf;
		
	If CertificateRevoked = True Then
		ResultStructure.Result = DigitalSignatureInternalClientServer.ErrorTextForRevokedSignatureCertificate(
			ResultStructure);
		ResultStructure.AdditionalAttributesCheckError = ResultStructure.Result;
		ResultStructure.CertificateRevoked = True;
		ResultStructure.IsVerificationRequired = False;
		ResultStructure.IsSignatureMathematicallyValid = True;
		Return;
	EndIf;
	
	If IsVerificationRequired <> Undefined Then
		ResultStructure.IsVerificationRequired = IsVerificationRequired;
	Else
		ResultStructure.IsVerificationRequired = False;
	EndIf;
	
	ResultStructure.IsSignatureMathematicallyValid = Not ResultStructure.IsVerificationRequired Or InvalidHash = False;
	
	ResultStructure.AdditionalAttributesCheckError = Result;
	
EndProcedure

Function CertificateThumbprint(Val Certificate)
	
	If TypeOf(Certificate) = Type("String") And IsTempStorageURL(Certificate) Then
		Certificate = GetFromTempStorage(Certificate);
	EndIf;
	
	If TypeOf(Certificate) = Type("BinaryData") Then
		Certificate = New CryptoCertificate(Certificate);
	EndIf;
	
	Return ?(TypeOf(Certificate) = Type("CryptoCertificate"), Base64String(Certificate.Thumbprint), 
		String(Certificate));
	
EndFunction 

#EndRegion

#EndRegion