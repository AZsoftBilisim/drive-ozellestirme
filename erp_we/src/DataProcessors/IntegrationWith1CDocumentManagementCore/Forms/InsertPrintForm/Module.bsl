#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ObjectIS = Parameters.ObjectIS;
	ObjectTypeDM = Parameters.ObjectTypeDM;
	ObjectIDDM = Parameters.ObjectIDDM;
	FileRoleID = Parameters.FileRoleID;
	
	If ValueIsFilled(Parameters.UniqueOwnerID) Then
		UniqueOwnerID = Parameters.UniqueOwnerID;
	Else
		UniqueOwnerID = UUID;
	EndIf;
	
	ObjectTypeIS = ObjectIS.Metadata().FullName();
	TypeOfPrintedForm = CommonServerCall.CommonSettingsStorageLoad(
		"IntegrationWith1CDocumentManagement",
		"TypeOfPrintedForm" + ObjectTypeIS,
		IntegrationWith1CDocumentManagementCore.DefaultFileTypeOfSavedPrintedForm());
	
	// Capture and edit files.
	Items.AddAndEdit.Visible =
		IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.4.9.1");
	
	IntegrationWith1CDocumentManagementCore.FillInTableOfObjectPrintManagers(
		ObjectTypeIS,
		PrintForms);
	
	If PrintForms.Count() = 0 Then
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PrintFormsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	AddPrintedForm(
		Items.PrintForms.CurrentData.CommandName,
		Items.PrintForms.CurrentData.CommandPresentation,
		Items.PrintForms.CurrentData.AdditionalParameters,
		True);
	
EndProcedure

&AtClient
Procedure Add(Command)
	
	CurrentData = Items.PrintForms.CurrentData;
	If CurrentData <> Undefined Then
		AddPrintedForm(
			CurrentData.CommandName,
			CurrentData.CommandPresentation,
			CurrentData.AdditionalParameters,
			True);
	EndIf;
	
EndProcedure

&AtClient
Procedure AddAndEdit(Command)
	
	CurrentData = Items.PrintForms.CurrentData;
	If CurrentData <> Undefined Then
		AddPrintedForm(
			CurrentData.CommandName,
			CurrentData.CommandPresentation,
			CurrentData.AdditionalParameters,
			False);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AddPrintedForm(CommandName, CommandPresentation, AdditionalParameters, ForReading)
	
	ObjectBefore = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		ObjectIDDM,
		ObjectTypeDM);
	
	CreatedFiles =
		IntegrationWith1CDocumentManagementCoreServerCall.AttachPrintedFormOfObjectToDocument(
			ObjectIS,
			ObjectBefore,
			CommandName,
			AdditionalParameters,
			TypeOfPrintedForm,
			FileRoleID,
			CommandPresentation);
	For Each CreatedFile_ In CreatedFiles Do
		CurrentFile = CreatedFile_.CurrentFile; // See IntegrationWith1CDocumentManagementCoreClientServer.FileData
		MessageText = StrTemplate(NStr("vi = 'Đã tạo tệp ""%1""';
										|ru = 'Создан файл ""%1""';
										|en = 'The ""%1"" file is created'; fa = 'The ""%1"" file is created';
										|it = 'Создан файл ""%1""';
										|pl = 'The ""%1"" file is created';
										|tr = '""%1"" dosyası oluşturuldu'"), CurrentFile.Description);
		FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
		FileOperation.CreatingFile = True;
		FileOperation.InformFormOfFile = True;
		IntegrationWith1CDocumentManagementCoreClient.InformAboutFileChanges(
			FileOperation,
			CurrentFile.Description,
			CurrentFile.ID,
			ObjectIDDM,
			MessageText,,
			UniqueOwnerID);
	EndDo;
	If TypeOf(CurrentFile) = Type("Structure") Then
		FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
		FileOperation.CreatingFile = True;
		FileOperation.InformFileListForm = True;
		IntegrationWith1CDocumentManagementCoreClient.InformAboutFileChanges(
			FileOperation,
			CurrentFile.Description,
			CurrentFile.ID,
			ObjectIDDM,,,
			UniqueOwnerID);
	EndIf;
	
	CommonServerCall.CommonSettingsStorageSave(
		"IntegrationWith1CDocumentManagement",
		"TypeOfPrintedForm" + ObjectTypeIS,
		TypeOfPrintedForm);
	
	If Not ForReading Then
		For Each CreatedFile_ In CreatedFiles Do
			CurrentFile = CreatedFile_.CurrentFile; // See IntegrationWith1CDocumentManagementCoreClientServer.FileData
			IntegrationWith1CDocumentManagementCoreClient.OpenFile(
				CurrentFile.ID,
				CurrentFile.Description,
				CurrentFile.Extension,
				UniqueOwnerID,
				ForReading,,
				ObjectIDDM);
		EndDo;
	EndIf;
	
	Close(CreatedFiles);
	
EndProcedure

#EndRegion