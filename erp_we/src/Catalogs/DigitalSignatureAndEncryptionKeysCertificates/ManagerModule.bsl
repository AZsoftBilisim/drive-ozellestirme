///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.BatchEditObjects

// Returns the object attributes that are not recommended to be edited
// using a bulk attribute modification data processor.
//
// Returns:
//  Array of String
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array;
	NotAttributesToEdit.Add("IssuedTo");
	NotAttributesToEdit.Add("Firm");
	NotAttributesToEdit.Add("LastName");
	NotAttributesToEdit.Add("Name");
	NotAttributesToEdit.Add("MiddleName");
	NotAttributesToEdit.Add("JobTitle");
	NotAttributesToEdit.Add("IssuedBy");
	NotAttributesToEdit.Add("ValidBefore");
	NotAttributesToEdit.Add("Signing");
	NotAttributesToEdit.Add("Encryption");
	NotAttributesToEdit.Add("Thumbprint");
	NotAttributesToEdit.Add("CertificateData");
	NotAttributesToEdit.Add("Application");
	NotAttributesToEdit.Add("Revoked");
	NotAttributesToEdit.Add("EnterPasswordInDigitalSignatureApplication");
	NotAttributesToEdit.Add("Organization");
	NotAttributesToEdit.Add("User");
	NotAttributesToEdit.Add("Added");
	
	If Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined Then
		ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
		ProcessingApplicationForNewQualifiedCertificateIssue.AttributesToSkipInBatchProcessing(
			NotAttributesToEdit);
	EndIf;
	
	Return NotAttributesToEdit;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// StandardSubsystems.ReportsOptions

// Defines the list of report commands.
//
// Parameters:
//  ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//  Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	If Not AccessRight("View", Metadata.Reports.DigitalSignatureCertificates) Then
		Return;
	EndIf;
	
	If Parameters.FormName = "CommonForm.DigitalSignatureAndEncryptionSettings" Then
		Command = ReportsCommands.Add();
		Command.VariantKey      = "DigitalSignatureCertificates";
		Command.Presentation     = NStr("vi = 'Chứng thư của chữ ký điện tử';
										|ru = 'Сертификаты электронной подписи';
										|en = 'Digital signature certificates'; fa = 'گواهی‌های امضای دیجیتال';
										|it = 'Сертификаты электронной подписи';
										|pl = 'Digital signature certificates';
										|tr = 'Dijital imza sertifikaları'");
		Command.Id     = "DigitalSignatureCertificates";
		Command.Manager          = "Report.DigitalSignatureCertificates";
		Command.IsNonContextual     = True;
		
		Command = ReportsCommands.Add();
		Command.VariantKey      = "ExpiringSoon";
		Command.Presentation     = NStr("vi = 'Chứng thư sắp hết hạn';
										|ru = 'Сертификаты, у которых заканчивается срок действия';
										|en = 'Expiring certificates'; fa = 'Expiring certificates';
										|it = 'Сертификаты, у которых заканчивается срок действия';
										|pl = 'Expiring certificates';
										|tr = 'Süresi dolmak üzere olan sertifikalar'");
		Command.Id     = "ExpiringSoon";
		Command.Manager          = "Report.DigitalSignatureCertificates";
		Command.IsNonContextual     = True;
		
		Command = ReportsCommands.Add();
		Command.VariantKey      = "MRLOARequired";
		Command.Presentation     = NStr("vi = 'Chứng thư mà đối với chúng yêu cầu giấy ủy quyền có thể đọc bằng máy';
										|ru = 'Сертификаты, для которых требуется МЧД';
										|en = 'Certificates that require MR LOA'; fa = 'گواهی‌هایی که نیاز به MR LOA دارند';
										|it = 'Сертификаты, для которых требуется МЧД';
										|pl = 'Certificates that require MR LOA';
										|tr = 'Elektronik vekaletname gerektiren sertifikalar'");
		Command.Id     = "MRLOARequired";
		Command.Manager          = "Report.DigitalSignatureCertificates";
		Command.IsNonContextual     = True;
	EndIf;
	
EndProcedure

// End StandardSubsystems.ReportsOptions

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization, EmptyRef AS TRUE)
	|	AND (ValueAllowed(User, EmptyRef AS TRUE)
	|	OR ValueAllowed(Users.User, EmptyRef AS TRUE))";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ListForm" Then
		StandardProcessing = False;
		Parameters.Insert("ShowPage", "Certificates");
		SelectedForm = Metadata.CommonForms.DigitalSignatureAndEncryptionSettings;
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Update handlers.

// Registers objects, 
// for which it is necessary to update register records on the InfobaseUpdate exchange plan.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ElectronicSignatureAndEncryptionKeyCertificatesUsers.Ref,
	|	COUNT(ElectronicSignatureAndEncryptionKeyCertificatesUsers.User) AS User
	|INTO OneUserInTableSection
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates.Users AS
	|		ElectronicSignatureAndEncryptionKeyCertificatesUsers
	|GROUP BY
	|	ElectronicSignatureAndEncryptionKeyCertificatesUsers.Ref
	|HAVING
	|	COUNT(ElectronicSignatureAndEncryptionKeyCertificatesUsers.User) = 1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DigitalSignatureAndEncryptionKeysCertificates.Ref AS Ref
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS DigitalSignatureAndEncryptionKeysCertificates
	|		LEFT JOIN OneUserInTableSection AS OneUserInTableSection
	|		ON DigitalSignatureAndEncryptionKeysCertificates.Ref = OneUserInTableSection.Ref
	|WHERE
	|	DigitalSignatureAndEncryptionKeysCertificates.DeleteUserNotifiedOfExpirationDate
	|	OR &StatementCondition
	|	OR DigitalSignatureAndEncryptionKeysCertificates.ValidBefore > &CurrentDate
	|	OR NOT OneUserInTableSection.Ref IS NULL";

	
	If DigitalSignature.CommonSettings().CertificateIssueRequestAvailable Then
		
		ModuleApplicationForIssuingANewQualifiedCertificate = Common.CommonModule(
			"DataProcessors.ApplicationForNewQualifiedCertificateIssue");
		Query.Text = StrReplace(Query.Text, "&StatementCondition",
			"DigitalSignatureAndEncryptionKeysCertificates.DeleteStatementStatement <> &EmptyRef");
		Query.SetParameter("EmptyRef", 
			ModuleApplicationForIssuingANewQualifiedCertificate.StatementStatusEmptyRef());
		
	Else
		Query.Text = StrReplace(Query.Text, "OR &StatementCondition", "");
	EndIf;
	
	Query.SetParameter("CurrentDate", CurrentSessionDate());

	ReferencesArrray = Query.Execute().Unload().UnloadColumn("Ref");
	InfobaseUpdate.MarkForProcessing(Parameters, ReferencesArrray);
	
EndProcedure

// Update register records.
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Selection = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue,
		"Catalog.DigitalSignatureAndEncryptionKeysCertificates");
	If Selection.Count() > 0 Then
		ProcessCertificatesRequestsNotificationsAndValidityPeriods(Selection);
	EndIf;

	ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue,
		"Catalog.DigitalSignatureAndEncryptionKeysCertificates");
	Parameters.ProcessingCompleted = ProcessingCompleted;
	
EndProcedure

#EndRegion

#Region Private

Procedure ProcessCertificatesRequestsNotificationsAndValidityPeriods(Selection)
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;

	CertificateIssueRequestAvailable = DigitalSignature.CommonSettings().CertificateIssueRequestAvailable;
	
	If CertificateIssueRequestAvailable Then
		ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
	EndIf;
	
	While Selection.Next() Do

		RepresentationOfTheReference = String(Selection.Ref);

		BeginTransaction();
		Try

			Block = New DataLock;
			LockItem = Block.Add("Catalog.DigitalSignatureAndEncryptionKeysCertificates");
			LockItem.SetValue("Ref", Selection.Ref);
			LockItem.Mode = DataLockMode.Shared;
			Block.Lock();
			
			WriteObject = False;

			CertificateObject = Selection.Ref.GetObject(); // CatalogObject.DigitalSignatureAndEncryptionKeysCertificates
			
			// Transfer certificate update notifications into the information register.
			If CertificateObject.DeleteUserNotifiedOfExpirationDate Then
				AlertRecordset = InformationRegisters.CertificateUsersNotifications.CreateRecordSet();
				AlertRecordset.Filter.Certificate.Set(Selection.Ref);

				If CertificateObject.Users.Count() > 0 Then
					
					UsersTable = CertificateObject.Users.Unload();
					UsersTable.GroupBy("User");
					
					For Each UserString In UsersTable Do
						WriteAlertSet = AlertRecordset.Add();
						WriteAlertSet.Certificate = Selection.Ref;
						WriteAlertSet.User = UserString.User;
						WriteAlertSet.IsNotified = True;
					EndDo;
					
				ElsIf ValueIsFilled(CertificateObject.User) Then
					WriteAlertSet = AlertRecordset.Add();
					WriteAlertSet.Certificate = Selection.Ref;
					WriteAlertSet.User = CertificateObject.User;
					WriteAlertSet.IsNotified = True;
				EndIf;
				If AlertRecordset.Count() > 0 Then
					InfobaseUpdate.WriteRecordSet(AlertRecordset, True);
				EndIf;
				CertificateObject.DeleteUserNotifiedOfExpirationDate = False;
				WriteObject = True;
			EndIf;
			
			// Transfer request data into the information register.
			If CertificateIssueRequestAvailable
			   And ValueIsFilled(CertificateObject.DeleteStatementStatement) Then
				
				ProcessingApplicationForNewQualifiedCertificateIssue.ProcessDataForMigrationToNewVersion(
					CertificateObject, WriteObject);

			EndIf;
			
			If CertificateObject.Users.Count() = 1 Then
				CertificateObject.User = CertificateObject.Users[0].User;
				CertificateObject.Users.Clear();
				WriteObject = True;
			EndIf;
			
			If CertificateObject.ValidBefore > CurrentSessionDate() Then
				CertificateBinaryData = CertificateObject.CertificateData.Get();
				If TypeOf(CertificateBinaryData) = Type("BinaryData") Then
					Try
						Certificate = New CryptoCertificate(CertificateBinaryData);
					Except
						Certificate = Undefined;
					EndTry;

					If Certificate <> Undefined Then
						CertificateProperties = DigitalSignatureInternalClientServer.CertificateProperties(
							Certificate, DigitalSignatureInternal.UTCOffset(),
							CertificateBinaryData);
						If CertificateObject.ValidBefore <> CertificateProperties.ValidBefore Then
							SearchString = Format(CertificateObject.ValidBefore, "DF=MM.yyyy");
							ReplacementString = Format(CertificateProperties.ValidBefore, "DF=MM.yyyy");
							CertificateObject.Description = StrReplace(CertificateObject.Description, SearchString,
								ReplacementString);
							CertificateObject.ValidBefore = CertificateProperties.ValidBefore;
							WriteObject = True;
						EndIf;

						If ValueIsFilled(CertificateObject.Application) And TypeOf(CertificateObject.Application) = Type(
							"CatalogRef.DigitalSignatureAndEncryptionApplications") Then

							CertificateAlgorithm = DigitalSignatureInternalClientServer.CertificateSignAlgorithm(
								CertificateBinaryData, False, True);
							If DigitalSignatureInternalClientServer.IsGOSTCertificate(CertificateAlgorithm) Then

								ApplicationDetails = Common.ObjectAttributesValues(
									CertificateObject.Application,
									"IsBuiltInCryptoProvider, SignAlgorithm, HashAlgorithm");

								If Not ApplicationDetails.IsBuiltInCryptoProvider Then

									Result = DigitalSignatureInternalClientServer.SignAlgorithmCorrespondsToCertificate(
										"", CertificateAlgorithm, ApplicationDetails.SignAlgorithm, ApplicationDetails.HashAlgorithm);

									If Result <> True Then

										CertificateObject.Application = Catalogs.DigitalSignatureAndEncryptionApplications.EmptyRef();
										WriteObject = True;

									EndIf;
								EndIf;

							EndIf;
						EndIf;

					EndIf;
				EndIf;
			EndIf;

			If WriteObject Then
				InfobaseUpdate.WriteObject(CertificateObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			EndIf;

			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();

		Except

			RollbackTransaction();
			// If a certificate cannot be processed, try again.
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			InfobaseUpdate.WriteErrorToEventLog(
				Selection.Ref,
				RepresentationOfTheReference,
				ErrorInfo());
		EndTry;

	EndDo;

	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xử lý một số chứng chỉ (đã bỏ qua): %1';
				|ru = 'Не удалось обработать некоторые сертификаты (пропущены): %1';
				|en = 'Couldn''t process (skipped) some certificates: %1'; fa = 'Couldn''t process (skipped) some certificates: %1';
				|it = 'Non è stato possibile elaborare alcuni certificati (saltati): %1';
				|pl = 'Nie udało się przetworzyć niektórych certyfikatów (pominięte): %1';
				|tr = 'Bazı sertifikalar işlenemedi (atlandı): %1'"),
			ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Information,
			Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates,,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã xử lý tùy chọn chứng chỉ theo trình tự: %1';
					|ru = 'Обработана очередная порция сертификатов: %1';
					|en = 'Another batch of certificates is processed: %1'; fa = 'Another batch of certificates is processed: %1';
					|it = 'È stata elaborata un''altra porzione di certificati: %1';
					|pl = 'Przetworzono kolejną część certyfikatów: %1';
					|tr = 'Sertifikaların bir grubu daha işlendi: %1'"), ObjectsProcessed));
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
