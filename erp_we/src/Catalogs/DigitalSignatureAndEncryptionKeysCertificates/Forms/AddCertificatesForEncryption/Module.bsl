///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	PlacedFiles = Parameters.PlacedFiles;
	
	ToSearchForIndividuals = New Array;
	
	If ValueIsFilled(PlacedFiles) Then
		
		For Each CertificateFile In PlacedFiles Do
			
			CertificateData = GetFromTempStorage(CertificateFile.Location);
		
			CryptoCertificate = DigitalSignatureInternal.CertificateFromBinaryData(CertificateData);
			If CryptoCertificate = Undefined Then
				NewRow = FilesAreNotCertificates.Add();
				If ValueIsFilled(CertificateFile.FullName) Then
					NewRow.PathToFile = CertificateFile.FullName;
				Else
					NewRow.PathToFile = CertificateFile.FileName;
				EndIf;
			Else
				CertificateProperties = DigitalSignature.CertificateProperties(CryptoCertificate);
				
				If Certificates.FindRows(New Structure("Thumbprint, ValidBefore", 
					CertificateProperties.Thumbprint, CertificateProperties.ValidBefore)).Count() > 0 Then
					Continue;
				EndIf;
				
				IssuedTo = DigitalSignatureInternalClientServer.ConvertIssuedToIntoFullName(CertificateProperties.IssuedTo); // String
				
				NewRow = Certificates.Add();
				NewRow.Presentation = CertificateProperties.Presentation;
				NewRow.IssuedTo = IssuedTo;
				NewRow.CertificateAddress = PutToTempStorage(CryptoCertificate.Unload(), UUID);
				NewRow.Thumbprint = CertificateProperties.Thumbprint;
				NewRow.ValidBefore = CertificateProperties.ValidBefore;
				
				ToSearchForIndividuals.Add(IssuedTo);
			EndIf;
		EndDo;
		
	EndIf;
	
	If Certificates.Count() = 0 Then
		Cancel = True;
		Return;
	EndIf;
	
	If Not DigitalSignature.CommonSettings().IndividualUsed Then
		Items.CertificatesIndividual.Visible = False;
	Else
		Items.CertificatesIndividual.ToolTip =
			Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates.Attributes.Individual.Tooltip;
	EndIf;
	
	PopulateCertificatesInTable();
	
	If Items.CertificatesIndividual.Visible And ToSearchForIndividuals.Count() > 0 Then
		
		IndividualsByFullName = DigitalSignatureInternal.GetIndividualsByCertificateFieldIssuedTo(ToSearchForIndividuals);
		For Each CurrentRow In Certificates Do
			
			If ValueIsFilled(CurrentRow.Individual) Then
				Continue;
			EndIf;
			
			ArrayOfValues = IndividualsByFullName.Get(CurrentRow.IssuedTo);
			If TypeOf(ArrayOfValues) = Type("Array") And ArrayOfValues.Count() = 1 Then
				CurrentRow.Individual = ArrayOfValues[0];
				CurrentRow.Refresh = True;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Items.FilesAreNotCertificates.Visible = FilesAreNotCertificates.Count() > 0;
	
	If Not DigitalSignature.CommonSettings().IsCompanyUsed Then
		Items.Organization.Visible = False;
	Else
		If ValueIsFilled(Parameters.Organization) Then
			Organization = Parameters.Organization;
		EndIf;
		
		Items.Organization.ToolTip =
			Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates.Attributes.Organization.Tooltip;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_DigitalSignatureAndEncryptionKeysCertificates" Then
		
		If Not Items.CertificatesIndividual.Visible Then
			Return;
		EndIf;
		
		Found4 = Certificates.FindRows(New Structure("Certificate", Source));
		
		If Found4.Count() = 0 Then
			Return;
		EndIf;
		
		IndividualOfCertificate = IndividualOfCertificate(Source);
		For Each CurrentRow In Found4 Do
			CurrentRow.Individual = IndividualOfCertificate;
			CurrentRow.Refresh = False;
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCertificates

&AtClient
Procedure CertificatesOnActivateRow(Item)
	
	CurrentData = Items.Certificates.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Items.CertificatesCertificate.Visible = ValueIsFilled(CurrentData.Certificate);
	
	If ExtensionAttached = False Then
		PopulateCertificateDataDetailsAtServer(CurrentData.CertificateAddress);
	ElsIf ExtensionAttached = True Then
		FillCertificateDataDetails(True, CurrentData.CertificateAddress);
	Else
		DigitalSignatureClient.InstallExtension(False, New CallbackDescription(
			"FillCertificateDataDetails", ThisObject, CurrentData.CertificateAddress),
			NStr("vi = 'Để tiếp tục, hãy cài đặt phần mở rộng để làm việc với 1C:Enterprise.';
				|ru = 'Для продолжения установите расширение для работы с 1С:Предприятием.';
				|en = 'To continue, install 1C:Enterprise Extension.'; fa = 'To continue, install 1C:Enterprise Extension.';
				|it = 'Для продолжения установите расширение для работы с 1С:Предприятием.';
				|pl = 'W celu kontynuowania zainstaluj rozszerzenie do pracy z 1C:Enterprise.';
				|tr = 'Devam etmek için 1C:Enterprise ile çalışma uzantısını yükleyin.'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure CertificatesBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure CertificatesIndividualAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IndividualStartChoice(StandardProcessing);
	
EndProcedure

&AtClient
Procedure CertificatesIndividualStartChoice(Item, ChoiceData, StandardProcessing)
	
	IndividualStartChoice(StandardProcessing);
	
EndProcedure

&AtClient
Procedure CertificatesPresentationOnChange(Item)
	
	Items.Certificates.CurrentData.Refresh = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShowCertificateData(Command)
	
	If Items.Certificates.CurrentData = Undefined Then
		Return;
	EndIf;
	
	AddressOfCertificate = Items.Certificates.CurrentData.CertificateAddress;
	DigitalSignatureClient.OpenCertificate(AddressOfCertificate, True);
	
EndProcedure

&AtClient
Async Procedure AddCertificatesToCatalog(Command)
	
	Success = AddCertificatesToCatalogAtServer();
	Notify("Write_DigitalSignatureAndEncryptionKeysCertificates");
	
	If Success Then
		Response = Await DoQueryBoxAsync(NStr("vi = 'Đã thêm thành công chứng thư. Đóng biểu mẫu?';
												|ru = 'Сертификаты добавлены успешно. Закрыть форму?';
												|en = 'Certificates are added. Do you want to close the form?'; fa = 'Certificates are added. Do you want to close the form?';
												|it = 'Сертификаты добавлены успешно. Закрыть форму?';
												|pl = 'Certificates are added. Do you want to close the form?';
												|tr = 'Sertifikalar başarıyla eklendi. Form kapatılsın mı?'"), QuestionDialogMode.YesNo);
		If Response = DialogReturnCode.Yes Then
			Close();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure OnCloseIndividualChoiceForm(Value, Var_Parameters) Export

	If Value = Undefined Then
		Return;
	EndIf;
	
	Items.Certificates.CurrentData.Individual = Value;
	Items.Certificates.CurrentData.Refresh = True;

EndProcedure

&AtServer
Procedure PopulateCertificatesInTable()
	
	Query = New Query;
	Query.SetParameter("Thumbprints", Certificates.Unload(, "Thumbprint"));
	
	SetPrivilegedMode(True);
	
	Query.Text =
	"SELECT
	|	Thumbprints.Thumbprint
	|INTO Thumbprints
	|FROM
	|	&Thumbprints AS Thumbprints
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Certificates.Thumbprint,
	|	Certificates.Individual,
	|	Certificates.Ref
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
	|		INNER JOIN Thumbprints AS Thumbprints
	|		ON Certificates.Thumbprint = Thumbprints.Thumbprint";
	
	Selection = Query.Execute().Select();
	
	SetPrivilegedMode(False);
	
	While Selection.Next() Do
		
		CertificateRow = Certificates.FindRows(New Structure("Thumbprint", Selection.Thumbprint));
		For Each CurrentRow In CertificateRow Do
			
			If Items.CertificatesIndividual.Visible Then
				CurrentRow.Individual = Selection.Individual;
			EndIf;
			
			If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
				ModuleAccessManagement = Common.CommonModule("AccessManagement");
				ReadingAllowed = ModuleAccessManagement.ReadingAllowed(Selection.Ref);
			Else
				ReadingAllowed = AccessRight("Read", Selection.Ref.Metadata());
			EndIf;
			If ReadingAllowed Then // Protection against data errors (duplicate certificates).
				CurrentRow.Certificate = Selection.Ref;
			EndIf;
			
			CurrentRow.AlreadyAdded = True;
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServerNoContext
Function IndividualOfCertificate(Val Certificate)
	
	Return Common.ObjectAttributeValue(Certificate, "Individual");
	
EndFunction

&AtClient
Procedure IndividualStartChoice(StandardProcessing)
	
	CurrentData = Items.Certificates.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.Certificate) And ValueIsFilled(CurrentData.Individual)
		And Not CurrentData.Refresh Then
			StandardProcessing = False;
			ShowValue(, CurrentData.Certificate);
		Return;
	EndIf;
	
	Result = DigitalSignatureInternalServerCall.GetIndividualsByCertificateFieldIssuedTo(
		CurrentData.IssuedTo);
		
	If Not Result.Property("Persons") Then
		Return;
	EndIf;
	
	IndividualsForFullName = Result.Persons.Get(CurrentData.IssuedTo);
	
	StandardProcessing = False;
	
	If IndividualsForFullName = Undefined Then
		ChoiceProcessing = New CallbackDescription("OnCloseIndividualChoiceForm", ThisObject);
		FormParameters = New Structure;
		FormParameters.Insert("ChoiceMode", True);
		OpenForm(Result.IndividualChoiceFormPath, FormParameters, ThisObject, , , , ChoiceProcessing,
			FormWindowOpeningMode.LockOwnerWindow);
		Return;
	EndIf;
	
	If IndividualsForFullName.Count() = 1 Then
		If CurrentData.Individual <> IndividualsForFullName[0] Then
			CurrentData.Individual = IndividualsForFullName[0];
		Else
			ChoiceProcessing = New CallbackDescription("OnCloseIndividualChoiceForm", ThisObject);
			FormParameters = New Structure;
			FormParameters.Insert("ChoiceMode", True);
			OpenForm(Result.IndividualChoiceFormPath, FormParameters, ThisObject, , , , ChoiceProcessing,
				FormWindowOpeningMode.LockOwnerWindow);
		EndIf;
		Return;
	EndIf;
	
	FixedSettings = New DataCompositionSettings;

	Filter = FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Ref");
	Filter.ComparisonType = DataCompositionComparisonType.InList;
	Filter.RightValue = IndividualsForFullName;
	Filter.Use = True;
	
	FormParameters = New Structure;
	FormParameters.Insert("FixedSettings", FixedSettings);
	FormParameters.Insert("FilterByReference_", True);
	FormParameters.Insert("ChoiceMode", True);

	ChoiceProcessing = New CallbackDescription("OnCloseIndividualChoiceForm", ThisObject);
	OpenForm(Result.IndividualChoiceFormPath, FormParameters, ThisObject, , , , ChoiceProcessing,
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtServer
Function AddCertificatesToCatalogAtServer()
	
	Success = True;
	
	For Each CurrentRow In Certificates Do
		
		CertificateParameters = New Structure;
		
		If ValueIsFilled(CurrentRow.Certificate) Then
			If CurrentRow.Refresh Then
				CertificateParameters.Insert("CertificateRef", CurrentRow.Certificate);
			Else
				Continue;
			EndIf;
		ElsIf CurrentRow.AlreadyAdded Then
			Continue;
		EndIf;
		
		CertificateParameters.Insert("Description", CurrentRow.Presentation);
		
		If Items.CertificatesIndividual.Visible And ValueIsFilled(CurrentRow.Individual) Then
			CertificateParameters.Insert("Individual", CurrentRow.Individual);
		EndIf;
		
		If ValueIsFilled(Organization) And Not ValueIsFilled(CurrentRow.Certificate) Then
			CertificateParameters.Insert("Organization", Organization);
		EndIf;
		
		Try
			
			CertificateRef = DigitalSignature.WriteCertificateToCatalog(CurrentRow.CertificateAddress, CertificateParameters);
			CurrentRow.Certificate = CertificateRef;
			CurrentRow.Refresh = False;
			
		Except
			
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể ghi lại chứng thư %1: %2';
					|ru = 'Не удалось записать сертификат %1: %2';
					|en = 'Cannot save the %1 certificate: %2'; fa = 'Cannot save the %1 certificate: %2';
					|it = 'Не удалось записать сертификат %1: %2';
					|pl = 'Cannot save the %1 certificate: %2';
					|tr = '%1 sertifikası kaydedilemedi: %2'"), CurrentRow.Presentation,
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
				
			RowIndex = Certificates.IndexOf(CurrentRow);
			Common.MessageToUser(ErrorMessage,, "Certificates[" + RowIndex + "].Presentation");
			Success = False;
			
		EndTry;
		
	EndDo;
	
	Return Success;
	
EndFunction

&AtClient
Async Procedure FillCertificateDataDetails(Result, CertificateAddress) Export
	
	If Result <> True Then
		ExtensionAttached = False;
		PopulateCertificateDataDetailsAtServer(CertificateAddress);
		Return;
	ElsIf ExtensionAttached <> True Then
		ExtensionAttached = True;
	EndIf;
	
	CryptoCertificate = New CryptoCertificate;
	Await CryptoCertificate.InitializeAsync(GetFromTempStorage(CertificateAddress));
	CertificateProperties = Await DigitalSignatureInternalClient.CertificateProperties(CryptoCertificate);
	
	DigitalSignatureInternalClientServer.FillCertificateDataDetails(
		DetailsOfCertificateData, CertificateProperties);
	
EndProcedure

&AtServer
Procedure PopulateCertificateDataDetailsAtServer(Val CertificateAddress)
	
	CryptoCertificate = New CryptoCertificate(GetFromTempStorage(CertificateAddress));
	CertificateProperties = DigitalSignature.CertificateProperties(CryptoCertificate);
	
	DigitalSignatureInternalClientServer.FillCertificateDataDetails(
		DetailsOfCertificateData, CertificateProperties);
		
EndProcedure

#EndRegion