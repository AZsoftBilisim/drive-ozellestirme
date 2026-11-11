#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("FileOwner", Owner);
	Parameters.Property("CurrentFile", CurrentFile);
	
	HasOwner = ValueIsFilled(Owner);
	
	// We will show the owner when opening the file from the card.
	Items.FileOwner.Visible = ValueIsFilled(CurrentFile) And HasOwner;
	
	If Parameters.Property("FormCaption") Then
		Title = Parameters.FormCaption;
		TitleIsSet = True;
	Else
		Title = StrTemplate("%1: %2", Title, Owner);
	EndIf;
	
	UseDocumentManagementEmail =
		GetFunctionalOption("UseEmail1CDocumentManagement");
	
	UseDigitalSignatureIS =
		IntegrationWith1CDocumentManagementCoreServerCall.UseElectronicDigitalSignatures();
	
	FileCatalogType = "Undefined";
	If HasOwner Then
		FileCatalogType = Owner.Metadata().FullName();
	EndIf;
	
	If Parameters.Property("SimpleForm") Then
		Items.OpenForEditing.OnlyInAllActions = True;
		Items.OpenForReading.OnlyInAllActions = True;
		Items.EndEdit.OnlyInAllActions = True;
		Preview = True;
	Else
		PreviewStorage = Common.CommonSettingsStorageLoad(
			FileCatalogType,
			"PreviewBIDFiles");
		If PreviewStorage = Undefined Then
			Preview = True;
		Else
			Preview = PreviewStorage;
		EndIf;
	EndIf;
	
	Items.SwitchPreview.Check = Preview;
	Items.PreviewImage.Visible = Preview;
	
	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperationsInternal = Common.CommonModule("FilesOperationsInternal");
		PreviewEnabledExtensions = ModuleFilesOperationsInternal.ExtensionsListForPreview();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ObjectBefore = IntegrationWith1CDocumentManagementCoreClientServer.ObjectDMFromFormData(FormOwner);
	If ValueIsFilled(ObjectBefore.ID) And ValueIsFilled(ObjectBefore.Type) Then
		ID = ObjectBefore.ID;
		Type = ObjectBefore.Type;
	Else
		ID = "";
		Type = "";
	EndIf;
	
	If Not TitleIsSet Then
		IntegrationWith1CDocumentManagementCoreClient.SetTitleWhenOpening(ThisObject);
	EndIf;
	
	TestConnection();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "IntegrationWith1CDocumentManagement_SuccessfulConnection" And Source <> ThisObject Then
		WhenConnecting();
	EndIf;
	
	If EventName = "Recording_1CDocumentManagementFile"
			And TypeOf(Parameter) = Type("Structure")
			And Parameter.Property("FileOperation")
			And Parameter.FileOperation.InformFileListForm Then
		ReadAndUpdateListOfFilesAndSignatures();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AuthorizationSettingsDecorationClick(Item)
	
	Notification = New CallbackDescription("AuthorizationSettingsDecorationClickCompletion", ThisObject);
	NameOfParameterForm = "DataProcessor.IntegrationWith1CDocumentManagementCore.Form.AuthorizationIn1CDocumentManagement";
	
	OpenForm(NameOfParameterForm,, ThisObject,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AuthorizationSettingsDecorationClickCompletion(Result, Var_Parameters) Export
	
	If Result = True Then
		WhenConnecting();
	EndIf;
	
EndProcedure

&AtClient
Procedure PreviewImageClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	OpenForReading(Undefined);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFiles

&AtClient
Procedure FilesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	OpenForReading(Undefined);
	
EndProcedure

&AtClient
Procedure FilesBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	OpenCard();
	
EndProcedure

&AtClient
Procedure FilesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
	If Copy Then
		AddByCopying(Items.Files.CurrentData.ID);
	Else
		AddFromDisk(Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure FilesBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	CurrentData = Items.Files.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	QueryText = "";
	
	If Items.Files.SelectedRows.Count() = 1 Then
		If CurrentData.DeletionMark Then
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Bỏ dấu xóa ""%1""?';
					|ru = 'Снять с ""%1"" пометку на удаление?';
					|en = 'Do you want to clear the deletion mark from ""%1""?'; fa = 'Do you want to clear the deletion mark from ""%1""?';
					|it = 'Rimuovere il contrassegno per cancellazione da ""%1""?';
					|pl = 'Usunąć z ""%1"" zaznaczenie do usunięcia?';
					|tr = '""%1"" için silme işareti kaldırılsın mı?'"), CurrentData.Description);
		Else
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đặt dấu xóa ""%1""?';
					|ru = 'Пометить ""%1"" на удаление?';
					|en = 'Do you want to mark %1 for deletion?'; fa = 'Do you want to mark %1 for deletion?';
					|it = 'Contrassegnare ""%1"" per cancellazione?';
					|pl = 'Zaznaczyć ""%1"" do usunięcia?';
					|tr = '""%1"" silinmek üzere işaretlensin mi?'"), CurrentData.Description);
		EndIf;
	Else
		If CurrentData.DeletionMark Then
			QueryText = NStr("vi = 'Bỏ dấu xóa các tệp đã chọn?';
							|ru = 'Снять с выделенных файлов пометку на удаление?';
							|en = 'Unmark selected files for deletion?'; fa = 'Unmark selected files for deletion?';
							|it = 'Rimuovere il contrassegno di eliminazione dai file evidenziati?';
							|pl = 'Usunąć z wybranych plików zaznaczenie do usunięcia?';
							|tr = 'Silinmek üzere seçili dosyaların işareti kaldırılsın mı?'");
		Else
			QueryText = NStr("vi = 'Đặt dấu xóa các tệp đã chọn?';
							|ru = 'Пометить выделенные файлы на удаление?';
							|en = 'Mark selected files for deletion?'; fa = 'Mark selected files for deletion?';
							|it = 'Contrassegnare i file evidenziati per l''eliminazione?';
							|pl = 'Zaznaczyć wybrane pliki do usunięcia?';
							|tr = 'Seçilen dosyalar silinmek üzere işaretlensin mi?'");
		EndIf;
	EndIf;
	
	AdditionalParameters = New Structure("SelectedRows", Items.Files.SelectedRows);
	Notification = New CallbackDescription(
		"FilesBeforeDeleteRowCompletion",
		ThisObject,
		AdditionalParameters);
	
	IntegrationWith1CDocumentManagementClient.ShowQuestionYesNo(Notification, QueryText);
	
EndProcedure

&AtClient
Procedure FilesOnActivateRow(Item)
	
	SetAvailabilityOfFileListCommands();
	UpdatePreview1(Items.Files.CurrentRow);
	
EndProcedure

&AtClient
Procedure FilesDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure FilesDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
	FilesArray = New Array;
	If TypeOf(DragParameters.Value) = Type("Array")
			And DragParameters.Value.Count() > 0 Then
		
		For Each FileToDrag In DragParameters.Value Do
			
			If TypeOf(FileToDrag) = Type("File") And FileToDrag.IsFile() Then
				FilesArray.Add(FileToDrag);
			EndIf;
			
		EndDo;
		
	ElsIf TypeOf(DragParameters.Value) = Type("File")
			And DragParameters.Value.IsFile() Then
		
		FilesArray.Add(DragParameters.Value);
		
	EndIf;
	
	If FilesArray.Count() > 0 Then
		CallbackDescription = New CallbackDescription("FilesDragCompletion", ThisObject, FilesArray);
		If ValueIsFilled(ID) Then // The associated object is already known.
			RunCallback(CallbackDescription, Undefined);
		Else // The linked object should be found or created.
			IntegrationWith1CDocumentManagementCoreClient.StartSearchingForARelatedObjectDM(
				Owner,
				CallbackDescription);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Async Procedure FilesDragCompletion(Result, FilesArray) Export
	
	If TypeOf(Result) = Type("Structure") Then
		// The owner of the file on the DO side could have been created directly at the time of dragging.
		// In this case, the data of the created object BEFORE will be contained in the "Result" structure.
		ID = Result.ID;
		Type = Result.type;
	EndIf;
	If Not ValueIsFilled(ID) Then
		Return;
	EndIf;
	
	YouNeedToAddScannedCopy =
		Await IntegrationWith1CDocumentManagementCoreClient.YouNeedToAddScannedCopyAsync(
			StateAllowsAddingScannedCopy,
			StateAllowsFileAddition);
	
	If YouNeedToAddScannedCopy = DialogReturnCode.Yes Then
		IntegrationWith1CDocumentManagementCoreClient.CreateFileFromDiskByDraggingAndDropping(
			FilesArray,
			FileCreationStartParameters());
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AddByCopying(OriginalID)
	
	CallbackDescription = New CallbackDescription("EditingCommandsCompletion", ThisObject);
	IntegrationWith1CDocumentManagementCoreClient.CreateFileByCopying(OriginalID, CallbackDescription);
	
EndProcedure

&AtClient
Procedure AddFromDisk(Command)
	
	CallbackDescription = New CallbackDescription("AddFromDiskCompletion", ThisObject);
	If ValueIsFilled(ID) Then // The associated object is already known.
		RunCallback(CallbackDescription, Undefined);
	Else // The linked object should be found or created.
		IntegrationWith1CDocumentManagementCoreClient.StartSearchingForARelatedObjectDM(
			Owner,
			CallbackDescription);
	EndIf;
	
EndProcedure

&AtClient
Procedure AddPrintedForm(Command)
	
	CallbackDescription = New CallbackDescription("AddPrintedFormCompletion", ThisObject);
	If ValueIsFilled(ID) Then // The associated object is already known.
		RunCallback(CallbackDescription, Undefined);
	Else // The linked object should be found or created.
		IntegrationWith1CDocumentManagementCoreClient.StartSearchingForARelatedObjectDM(
			Owner,
			CallbackDescription);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenForReading(Command)
	
	CurrentData = Items.Files.CurrentData;
	If CurrentData <> Undefined Then
		IntegrationWith1CDocumentManagementCoreClient.OpenFile(
			CurrentData.ID,
			CurrentData.Description,
			CurrentData.Extension,
			UUID,
			True);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenForEditing(Command)
	
	CurrentData = Items.Files.CurrentData;
	If CurrentData <> Undefined Then
		CallbackDescription = New CallbackDescription("EditingCommandsCompletion", ThisObject);
		IntegrationWith1CDocumentManagementCoreClient.OpenFile(
			CurrentData.ID,
			CurrentData.Description,
			CurrentData.Extension,
			UUID,
			False,
			CallbackDescription);
	EndIf;
	
EndProcedure

&AtClient
Procedure EndEdit(Command)
	
	CurrentData = Items.Files.CurrentData;
	If CurrentData <> Undefined Then
		CallbackDescription = New CallbackDescription("EditingCommandsCompletion", ThisObject);
		IntegrationWith1CDocumentManagementCoreClient.EndFileEditing(
			CurrentData.ID,
			CurrentData.Description,
			CurrentData.Extension,
			UUID,
			CallbackDescription);
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveToDisk(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.StartSavingSelectedFiles(
		Files,
		Items.Files.SelectedRows,
		UUID);
	
EndProcedure

&AtClient
Procedure UpdateFromFileOnHardDrive(Command)
	
	CurrentData = Items.Files.CurrentData;
	If CurrentData <> Undefined Then
		CallbackDescription = New CallbackDescription("EditingCommandsCompletion", ThisObject);
		IntegrationWith1CDocumentManagementCoreClient.UpdateFromFileOnHardDrive(
			CurrentData.ID,
			CurrentData.Description,
			CurrentData.Extension,
			CurrentData.ModificationDate,
			UUID,
			CallbackDescription);
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelEdit(Command)
	
	CurrentData = Items.Files.CurrentData;
	If CurrentData <> Undefined Then
		CallbackDescription = New CallbackDescription("EditingCommandsCompletion", ThisObject);
		IntegrationWith1CDocumentManagementCoreClient.UndoFileEditing(
			CurrentData.ID,
			CallbackDescription,,
			UUID);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenFileDirectory(Command)
	
	If Items.Files.CurrentData <> Undefined Then
		IntegrationWith1CDocumentManagementCoreClient.OpenFileDirectory(Items.Files.CurrentData.ID);
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveChanges(Command)
	
	CurrentData = Items.Files.CurrentData;
	If CurrentData <> Undefined Then
		CallbackDescription = New CallbackDescription("EditingCommandsCompletion", ThisObject);
		IntegrationWith1CDocumentManagementCoreClient.SaveChangesToEditedFile(
			CurrentData.ID,
			CurrentData.Description,
			CurrentData.Extension,
			UUID,
			CallbackDescription);
	EndIf;
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	UpdateFileListClient();
	
EndProcedure

&AtClient
Procedure ShowDeleted(Command)
	
	ShowDeleted = Not ShowDeleted;
	Items.ShowDeleted.Check = ShowDeleted;
	
	UpdateFileListClient();
	
EndProcedure

&AtClient
Procedure SwitchPreview(Command)
	
	Preview = Not Preview;
	Items.SwitchPreview.Check = Preview;
	Items.PreviewImage.Visible = Preview;
	UpdatePreview1(Items.Files.CurrentRow);
	CommonServerCall.CommonSettingsStorageSave(
		FileCatalogType,
		"PreviewBIDFiles",
		Preview);
	
EndProcedure

&AtClient
Procedure Print(Command)
	
	#If WebClient Then
		ShowMessageBox(, NStr("vi = 'Trên Web-client không hỗ trợ in tệp.';
								|ru = 'В Веб-клиенте печать файлов не поддерживается.';
								|en = 'Printing of files is not supported in the web client.'; fa = 'Printing of files is not supported in the web client.';
								|it = 'Non è supportata la stampa di file nel client web.';
								|pl = 'W kliencie webowym drukowanie plików nie jest obsługiwane.';
								|tr = 'Web istemcisi, dosyaların yazdırılmasını desteklemez.'"));
		Return;
	#EndIf
	
	IntegrationWith1CDocumentManagementCoreClient.PrintFiles(
		Files,
		Items.Files.SelectedRows,
		UUID);
	
EndProcedure

&AtClient
Procedure Send(Command)
	
	If UseDocumentManagementEmail Then
		
		SendViaDM();
		
	Else
		
		SendViaIS();
		
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Files (EP)

&AtClient
Procedure SignFile(Command)
	
	CurrentData = Items.Files.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	SignatureTable = IntegrationWith1CDocumentManagementCoreClientServer.SignatureTable(
		Signatures,,
		CurrentData.ID);
	
	FileProperties = IntegrationWith1CDocumentManagementCoreClientServer.FileProperties();
	FileProperties.FileID = CurrentData.ID;
	FileProperties.FileName = CurrentData.Description;
	FileProperties.FileOwner = ID;
	FileProperties.IsBeingEdited = CurrentData.IsBeingEdited;
	FileProperties.Encrypted = CurrentData.Encrypted;
	FileProperties.FileDetails = CurrentData.LongDesc;
	FileProperties.FormUniqueID = UUID;
	FileProperties.FileSignatureData =
		IntegrationWith1CDocumentManagementCoreClient.DataOfSignatures(SignatureTable);
	
	IntegrationWith1CDocumentManagementCoreClient.SignFile(FileProperties);
	
EndProcedure

&AtClient
Procedure AddDSFromFile(Command)
	
	CurrentData = Items.Files.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FileID = CurrentData.ID;
	SignatureTable = IntegrationWith1CDocumentManagementCoreClientServer.SignatureTable(
		Signatures,,
		FileID);
	FileSignatureData = IntegrationWith1CDocumentManagementCoreClient.DataOfSignatures(SignatureTable);
	
	FileProperties = IntegrationWith1CDocumentManagementCoreClientServer.FileProperties();
	FileProperties.FileID = FileID;
	FileProperties.FileName = CurrentData.Description;
	FileProperties.FileDetails = CurrentData.LongDesc;
	FileProperties.IsBeingEdited = CurrentData.IsBeingEdited;
	FileProperties.Encrypted = CurrentData.Encrypted;
	FileProperties.FileSignatureData = FileSignatureData;
	FileProperties.FormUniqueID = UUID;
	FileProperties.FileOwner = ID;
	
	IntegrationWith1CDocumentManagementCoreClient.StartAddingItemsFromFile(FileProperties);
	
EndProcedure

&AtClient
Procedure SaveFileTogetherBOT(Command)
	
	CurrentData = Items.Files.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.StartSavingTogetherBOT(
		CurrentData.ID,
		CurrentData.Extension,
		CurrentData.Description,
		CurrentData.Size * 1024,
		CurrentData.ModificationDate,
		UUID);
	
EndProcedure

#EndRegion

#Region Private

// Checks the connection to the DO by displaying the authorization window, if necessary, and changing the form according to the result.
//
&AtClient
Procedure TestConnection()
	
	CallbackDescription = New CallbackDescription("TestConnectionCompletion", ThisObject);
	IntegrationWith1CDocumentManagementCoreClient.TestConnection(
		CallbackDescription,
		ThisObject,,
		False,
		True);
	
EndProcedure

// It is called after checking the connection to BEFORE and changes the form according to the result.
//
&AtClient
Procedure TestConnectionCompletion(Result, Var_Parameters) Export
	
	If Result = True Then
		WhenConnecting();
	Else // Couldn't connect to BEFORE.
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenConnecting()
	
	If ProcessFormAccordingToServiceVersion() Then
		// Let's set the current line.
		If ValueIsFilled(CurrentFile) Then
			For Each File In Files Do
				If File.ID = CurrentFile Then
					Items.Files.CurrentRow = File.GetID();
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

// Modifies the form according to the availability of the service BEFORE and its version number.
//
&AtServer
Function ProcessFormAccordingToServiceVersion()
	
	ServiceVersion = IntegrationWith1CDocumentManagementCore.ServiceVersion();
	
	If Not IntegrationWith1CDocumentManagementCoreClientServer.ServiceIsAvailable(ServiceVersion) Then
		Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsUnavailable;
		Return False;
	EndIf;
	
	FormProcessedSuccessfully = True;
	
	Try
		
		Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsAvailable;
		
		If IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("3.0.1.1") Then
			
			FormProcessedSuccessfully = False;
			DataProcessors.IntegrationWith1CDocumentManagement.ProcessFormIfServiceVersionFunctionalityIsUnavailable(ThisObject);
			Items.GroupCommandBar.Visible = False;
			Items.GroupFilesAndPreview.Visible = False;
			
		Else
			
			Items.FunctionalityGroupIsNotSupported.Visible = False;
			Items.GroupCommandBar.Visible = True;
			Items.GroupFilesAndPreview.Visible = True;
			
			FileCaptureIsAvailable = IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable(
				"1.4.9.1");
			
			AvailableMarkedForDeletion = IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable(
				"2.0.6.3");
			
			// Let's process the EP settings.
			SettingsBefore = IntegrationWith1CDocumentManagementCoreCached.GetSettings();
			UseDigitalSignatureBefore = (SettingsBefore.UseElectronicDigitalSignatures = True);
			UseDigitalSignature = UseDigitalSignatureBefore And UseDigitalSignatureIS;
			
			Items.FilesSignedEncryptedPictureNumber.Visible = UseDigitalSignatureBefore;
			Items.Sign.Visible = UseDigitalSignature;
			Items.AddDSFromFile.Visible = UseDigitalSignature;
			Items.SaveWithDigitalSignature.Visible = UseDigitalSignature;
			Items.SignContext.Visible = UseDigitalSignature;
			Items.AddItemInstancesFromContextFile.Visible = UseDigitalSignature;
			Items.SaveTogetherBotContext.Visible = UseDigitalSignature;
			
			IntegrationWith1CDocumentManagementCoreClientServer.SetValuesOfAllNDPSFields(
				ThisObject,
				True);
			
			LinkedObjectBefore = IntegrationWith1CDocumentManagementCoreServerCall.ObjectDataUpToExternalObject(
				Owner);
			If LinkedObjectBefore <> Undefined Then
				ID = LinkedObjectBefore.ID;
				Type = LinkedObjectBefore.type;
			Else
				ID = "";
				Type = "";
			EndIf;
			
			ReadAndUpdateFileList();
			
			If ID <> "" And Type <> "" Then
				ObjectIS = InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.ReferenceToIPObjectAccordingToDocumentManagementData(
					ID,
					Type);
				If ObjectIS = Undefined Then
					InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.AddLink(
						ID,
						Type,
						Owner,
						(Files.Count() > 0));
				EndIf;
			EndIf;
			
			Items.AddPrintedForm.Enabled = StateAllowsFileAddition;
			Items.AddFromDisk.Enabled = (StateAllowsFileAddition
				Or StateAllowsAddingScannedCopy);
			Items.AddContextFromDisk.Enabled = (StateAllowsFileAddition
				Or StateAllowsAddingScannedCopy);
			
			Items.OpenForEditing.Enabled = StateAllowsFileEditing;
			Items.ContextOpenForEditing.Enabled = StateAllowsFileEditing;
			Items.EndEdit.Enabled = StateAllowsFileEditing;
			Items.ContextEdit.Enabled = StateAllowsFileEditing;
			Items.UpdateFromFileOnHardDrive.Enabled = StateAllowsFileEditing;
			Items.UpdateFromFileOnDiskContext.Enabled = StateAllowsFileEditing;
			Items.SaveChanges.Enabled = StateAllowsFileEditing;
			
			Items.ShowDeleted.Visible = AvailableMarkedForDeletion;
			
		EndIf;
		
	Except
		
		If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(ErrorInfo()) Then
			ProcessFormAccordingToServiceVersion();
		EndIf;
		
	EndTry;
	
	Return FormProcessedSuccessfully;
	
EndFunction

// General completion of editing commands. Updates the form.
//
&AtClient
Procedure EditingCommandsCompletion(Result, Var_Parameters) Export
	
	If TypeOf(Result) = Type("Structure") And Result.Property("ID") Then
		UpdateFileListClient(Result.ID);
		
	ElsIf TypeOf(Result) = Type("Array")
			And Result.Count() > 0
			And TypeOf(Result[0]) = Type("Structure")
			And Result[0].Property("ID") Then
		UpdateFileListClient(Result[0].ID);
		
	Else
		UpdateFileListClient();
		
	EndIf;
	
EndProcedure

// Constructor of the parameter structure to start creating a file.
//
// Returns:
//   See IntegrationWith1CDocumentManagementCoreClient.FileCreationStartParameters
//
&AtClient
Function FileCreationStartParameters()
	
	ParametersForStartOfCreation =
		IntegrationWith1CDocumentManagementCoreClient.FileCreationStartParameters();
	ParametersForStartOfCreation.IsScannedCopy =
		(StateAllowsAddingScannedCopy And Not StateAllowsFileAddition);
	ParametersForStartOfCreation.OwnerID = ID;
	ParametersForStartOfCreation.OwnerType = Type;
	ParametersForStartOfCreation.FormUniqueID = UUID;
	ParametersForStartOfCreation.OwnerPresentation = String(Owner);
	ParametersForStartOfCreation.Owner = Owner;
	ParametersForStartOfCreation.CallbackDescription =
		New CallbackDescription("EditingCommandsCompletion", ThisObject);
	
	Return ParametersForStartOfCreation;
	
EndFunction

// Completes adding a file from disk and updates the form.
//
&AtClient
Async Procedure AddFromDiskCompletion(Val Result, Val AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		ID = Result.ID;
		Type = Result.type;
	EndIf;
	If Not ValueIsFilled(ID) Then
		Return;
	EndIf;
	
	YouNeedToAddScannedCopy =
		Await IntegrationWith1CDocumentManagementCoreClient.YouNeedToAddScannedCopyAsync(
			StateAllowsAddingScannedCopy,
			StateAllowsFileAddition);
	
	If YouNeedToAddScannedCopy = DialogReturnCode.Yes Then
		IntegrationWith1CDocumentManagementCoreClient.CreateFileFromDisk(FileCreationStartParameters());
	EndIf;
	
EndProcedure

// Continues adding the owner's printed form.
&AtClient
Procedure AddPrintedFormCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		ID = Result.ID;
		Type = Result.type;
	EndIf;
	If Not ValueIsFilled(ID) Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ObjectIS", Owner);
	FormParameters.Insert("ObjectIDDM", ID);
	FormParameters.Insert("ObjectTypeDM", Type);
	CallbackDescription = New CallbackDescription("InsertPrintFormCompletion", ThisObject);
	AdditionForm = OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.InsertPrintForm",
		FormParameters,
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockWholeInterface);
	If AdditionForm = Undefined Then
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 không có mẫu in.';
				|ru = '%1 не имеет печатных форм.';
				|en = '%1 has no print forms.'; fa = '%1 has no print forms.';
				|it = '%1 non possiede forme di stampa.';
				|pl = '%1 nie ma formularzy wydruku.';
				|tr = '%1 yazdırılabilir formları mevcut değil.'"), String(Owner));
		ShowMessageBox(, WarningText);
	EndIf;
	
EndProcedure

// Completes the addition of the owner's printed form. Updates the form.
//
// Parameters:
//   Result - Array of Structure - See IntegrationWith1CDocumentManagementCoreClientServer.NewFileCreationOptions
//   Var_Parameters - Undefined
//
&AtClient
Procedure InsertPrintFormCompletion(Result, Var_Parameters) Export
	
	If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
		UpdateFileListClient(Result[0].CurrentFile.ID);
	EndIf;
	
EndProcedure

// Updates the file list by retrieving it from BEFORE.
//
&AtClient
Procedure UpdateFileListClient(FileID = Undefined)
	
	If FileID <> Undefined Then
		CurFileId = FileID;
	ElsIf Items.Files.CurrentData <> Undefined Then
		CurFileId = Items.Files.CurrentData.ID;
	EndIf;
	
	If ProcessFormAccordingToServiceVersion() Then
		// Let's restore the position in the list.
		For Each String In Files Do
			If String.ID = CurFileId Then
				Items.Files.CurrentRow = String.GetID();
				Break;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

// Retrieves the list of files from BEFORE and updates the list.
&AtServer
Procedure ReadAndUpdateFileList()
	
	Files.Clear();
	
	If Not ValueIsFilled(ID) Then
		Return;
	EndIf;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	FieldsReceived = New Array;
	FieldsReceived.Add("files");
	If Type = "DMInternalDocument" Or Type = "DMIncomingDocument" Or Type = "DMOutgoingDocument" Then
		FieldsReceived.Add("enabledProperties");
	EndIf;
	If ShowDeleted Then
		FieldsReceived.Add("ignoreDeletionMark");
	EndIf;
	
	XDTODataObject = IntegrationWith1CDocumentManagementCore.GetObject(
		Proxy,
		Type,
		ID,
		FieldsReceived);
	
	IntegrationWith1CDocumentManagementCoreServerCall.UpdateFileList(
		XDTODataObject.files,
		Files);
	
	If UseDigitalSignature Then
		IntegrationWith1CDocumentManagementCore.UpdateListOfFileSignatures(
			XDTODataObject.files,
			Signatures,
			UUID);
	EndIf;
	
	// Let's clarify the availability of the add and edit commands.
	IntegrationWith1CDocumentManagementCore.FillInPPEOfXDTOObject(ThisObject, XDTODataObject);
	
EndProcedure

// Opens the card of the selected file.
//
&AtClient
Procedure OpenCard()
	
	CurrentData = Items.Files.CurrentData;
	If CurrentData <> Undefined Then
		AdditionalParameters = New Structure("EditingAllowed", StateAllowsFileEditing);
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(
			"DMFile",
			CurrentData.ID,
			ThisObject,
			AdditionalParameters);
	EndIf;
	
EndProcedure

// Completes file deletion after a question to the user.
//
&AtClient
Procedure FilesBeforeDeleteRowCompletion(Response, NotificationParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		MarkToDelete(NotificationParameters.SelectedRows);
		UpdateFileListClient();
	EndIf;
	
EndProcedure

// Marks selected files for deletion.
//
&AtServer
Procedure MarkToDelete(Val SelectedRows)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	ListOfObjects = New Array;
	
	For Each LineNumber In SelectedRows Do
		Data = Files.FindByID(LineNumber);
		ListOfObjects.Add(New Structure("ID, Type", Data.ID, "DMFile"));
	EndDo;
	
	IntegrationWith1CDocumentManagementCore.MarkForDeletionUncheckItems(
		Proxy,
		ListOfObjects);
	
EndProcedure

// Changes the availability of commands depending on the selected file.
//
&AtClient
Procedure SetAvailabilityOfFileListCommands()
	
	CurrentData = Items.Files.CurrentData;
	If CurrentData = Undefined Then
		
		Items.OpenForReading.Enabled = False;
		Items.ContextOpenForReading.Enabled = False;
		Items.OpenForEditing.Enabled = False;
		Items.ContextOpenForEditing.Enabled = False;
		Items.EndEdit.Enabled = False;
		Items.ContextEdit.Enabled = False;
		Items.SaveToDisk.Enabled = False;
		Items.SaveToDiskContext.Enabled = False;
		Items.UpdateFromFileOnHardDrive.Enabled = False;
		Items.UpdateFromFileOnDiskContext.Enabled = False;
		Items.SaveChanges.Enabled = False;
		Items.CancelEdit.Enabled = False;
		Items.CancelEditingContext.Enabled = False;
		Items.OpenCard.Enabled = False;
		Items.OpenContextCard.Enabled = False;
		Items.Delete.Enabled = False;
		Items.RemoveContext.Enabled = False;
		Items.SaveWithDigitalSignature.Enabled = False;
		Items.SaveTogetherBotContext.Enabled = False;
		
	Else
		
		IsBeingEdited = CurrentData.IsBeingEdited;
		EditedByCurUser = CurrentData.EditedByCurUser;
		EditedByAnotherUser =
			IsBeingEdited
			And Not EditedByCurUser;
		CanBeCaptured =
			StateAllowsFileEditing
			And FileCaptureIsAvailable
			And Not EditedByAnotherUser;
		YouCanLetGo =
			StateAllowsFileEditing
			And FileCaptureIsAvailable
			And EditedByCurUser;
		
		Items.OpenForReading.Enabled = True;
		Items.ContextOpenForReading.Enabled = True;
		Items.OpenForEditing.Enabled = CanBeCaptured;
		Items.ContextOpenForEditing.Enabled = CanBeCaptured;
		Items.EndEdit.Enabled = YouCanLetGo;
		Items.ContextEdit.Enabled = YouCanLetGo;
		Items.SaveChanges.Enabled = YouCanLetGo;
		Items.CancelEdit.Enabled = YouCanLetGo;
		Items.CancelEditingContext.Enabled = YouCanLetGo;
		Items.SaveToDisk.Enabled = True;
		Items.SaveToDiskContext.Enabled = True;
		Items.UpdateFromFileOnHardDrive.Enabled = CanBeCaptured;
		Items.UpdateFromFileOnDiskContext.Enabled = CanBeCaptured;
		Items.OpenCard.Enabled = True;
		Items.OpenContextCard.Enabled = True;
		Items.Delete.Enabled = CanBeCaptured;
		Items.RemoveContext.Enabled = CanBeCaptured;
		Items.SaveWithDigitalSignature.Enabled = CurrentData.SignedWithDS;
		Items.SaveTogetherBotContext.Enabled = CurrentData.SignedWithDS;
		
	EndIf;
	
EndProcedure

// Updates the preview image.
//
&AtServer
Procedure UpdatePreview1(CurrentRow)
	
	If Not Preview
		Or CurrentRow = Undefined Then
		FileDataURL = "";
		Return;
	EndIf;
	
	CurrentData = Files.FindByID(CurrentRow);
	
	If PreviewEnabledExtensions.FindByValue(Lower(CurrentData.Extension)) <> Undefined Then
		If Not ValueIsFilled(CurrentData.FileDataURL) Then
			UseVisualizationOfItemInstanceStamp = True;
			CurrentData.FileDataURL =
				IntegrationWith1CDocumentManagementCoreServerCall.GetFileAndPutItInStorage(
					CurrentData.ID,
					UseVisualizationOfItemInstanceStamp,
					UUID);
		EndIf;
		FileDataURL = CurrentData.FileDataURL;
	Else
		FileDataURL = "";
		Items.PreviewImage.NonselectedPictureText = NStr("vi = 'Không hỗ trợ xem trước tệp kiểu này.';
														|ru = 'Предпросмотр файлов этого типа не поддерживается.';
														|en = 'Preview of files of this type is not supported.'; fa = 'Preview of files of this type is not supported.';
														|it = 'Anteprima dei file di questo tipo non supportata.';
														|pl = 'Podgląd plików tego typu nie jest obsługiwany.';
														|tr = 'Bu türdeki dosyaların önizlemesi desteklenmiyor.'");
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Mail

// Generates parameters of an outgoing email with attachments.
//
// Parameters:
//   Owner - Arbitrary - the owner of the files.
//   Attachments - Array - array of structures with properties:
//     Presentation - String - File Presentation;
//     Id - String - file ID in UP to.
//   FormUniqueID - UUID - ID of the calling form.
//
&AtServerNoContext
Function OutgoingMessageParameters(Val Owner, Val Attachments, Val FormUniqueID)
	
	// Let's prepare the title of the letter.
	EmailParameters = New Structure("DeleteFilesAfterSending", True);
	OneAttachment = Attachments.Count() = 1;
	
	// recipient.
	If IntegrationWith1CDocumentManagementCoreCached.SubsystemExists("SendingMailMessages") Then
		ModuleSendingMailMessages = Common.CommonModule("SendingMailMessages");
	Else
		ModuleSendingMailMessages = Undefined;
	EndIf;
	
	If Common.HasObjectAttribute("Counterparty", Owner.Metadata())
			And ModuleSendingMailMessages <> Undefined Then
		Counterparty = Common.ObjectAttributeValue(Owner, "Counterparty");
		EmailParameters.Insert("Recipient", ModuleSendingMailMessages.Emails(Counterparty));
	Else
		EmailParameters.Insert("Recipient", "");
	EndIf;
	
	// Topic.
	DocumentNumber = Common.ObjectAttributeValue(Owner, "Number");
	If Metadata.CommonModules.Find("ObjectsPrefixesClientServer") <> Undefined Then
		ModuleObjectsPrefixesClientServer = Common.CommonModule("ObjectsPrefixesClientServer");
		DocumentNumber = ModuleObjectsPrefixesClientServer.NumberForPrinting(DocumentNumber, True, True);
	EndIf;
	DocumentDate = Format(Common.ObjectAttributeValue(Owner, "Date"), "DLF=DD");
	Subject = StrTemplate(NStr("vi = '%1, %2 kèm theo chứng từ %3 %4 ngày %5';
								|ru = '%1, %2 к документу %3 %4 от %5';
								|en = '%1, %2 to document %3 %4 from %5'; fa = '%1, %2 to document %3 %4 from %5';
								|it = '%1, %2 al documento %3 %4 di %5';
								|pl = '%1, %2 do dokumentu %3 %4 z dnia %5';
								|tr = '%1, %2 belgeye %3 %4 %5itibaren'"),
		?(OneAttachment, NStr("vi = 'Tệp';
								|ru = 'Файл';
								|en = 'File'; fa = 'فایل';
								|it = 'File';
								|pl = 'Plik';
								|tr = 'Dosya'"), NStr("vi = 'Tệp';
													|ru = 'Файлы';
													|en = 'Files'; fa = 'فایل‌ها';
													|it = 'File';
													|pl = 'Pliki';
													|tr = 'Dosyalar'")),
		?(OneAttachment, NStr("vi = 'đính kèm';
								|ru = 'присоединенный';
								|en = 'attached file'; fa = 'attached file';
								|it = 'allegato';
								|pl = 'załączony';
								|tr = 'ekli'"), NStr("vi = 'đính kèm';
															|ru = 'присоединенные';
															|en = 'attached files'; fa = 'attached files';
															|it = 'allegati';
															|pl = 'załączone';
															|tr = 'ekler'")),
		TypeOf(Owner),
		DocumentNumber,
		DocumentDate);
	EmailParameters.Insert("Subject", Subject);
	
	// Text.
	Text = StrTemplate(NStr("vi = 'Kèm E-mail %1 %2:';
							|ru = 'К письму %1 %2:';
							|en = 'To email %1 %2:'; fa = 'To email %1 %2:';
							|it = 'Alla posta %1 %2:';
							|pl = 'Do wiadomości %1 %2:';
							|tr = '%1 %2mektuba:'"),
		?(OneAttachment, NStr("vi = 'đính kèm';
								|ru = 'присоединен';
								|en = 'attached'; fa = 'attached';
								|it = 'allegato';
								|pl = 'załączony';
								|tr = 'eklendi'"), NStr("vi = 'đính kèm';
														|ru = 'присоединены';
														|en = 'are attached'; fa = 'are attached';
														|it = 'allegati';
														|pl = 'załączone';
														|tr = 'eklendi'")),
		?(OneAttachment, NStr("vi = 'tệp';
								|ru = 'файл';
								|en = 'file'; fa = 'file';
								|it = 'file';
								|pl = 'plik';
								|tr = 'dosya'"), NStr("vi = 'tệp';
													|ru = 'файлы';
													|en = 'files'; fa = 'files';
													|it = 'file';
													|pl = 'pliki';
													|tr = 'dosyalar'")));
	
	// We will get attachments from BEFORE.
	For Each Attachment In Attachments Do
		UseVisualizationOfItemInstanceStamp = True;
		AddressInTempStorage =
			IntegrationWith1CDocumentManagementCoreServerCall.GetFileAndPutItInStorage(
				Attachment.IdBefore,
				UseVisualizationOfItemInstanceStamp,
				FormUniqueID);
		Attachment.Insert("AddressInTempStorage", AddressInTempStorage);
		Text = Text + Chars.LF + StrTemplate(NStr("vi = '- %1';
													|ru = '- %1';
													|en = '- %1'; fa = '- %1';
													|it = '- %1';
													|pl = '- %1';
													|tr = '- %1'"), Attachment.Presentation);
	EndDo;
	EmailParameters.Insert("Attachments", Attachments);
	
	If ModuleSendingMailMessages <> Undefined Then
		PreparedText = ModuleSendingMailMessages.PrepareTextOfLetter(Text);
		EmailParameters.Insert("Text", PreparedText);
		ModuleSendingMailMessages.AddEmailParameters(EmailParameters);
	EndIf;
	
	Return EmailParameters;
	
EndFunction

// Starts sending the email through TO. Called if the corresponding FO is enabled.
//
&AtClient
Procedure SendViaDM()
	
	CallbackDescription = New CallbackDescription(
		"SendViaDMCompletion",
		ThisObject);
	
	If ValueIsFilled(ID) Then
		
		SubjectOf = New Structure;
		SubjectOf.Insert("ID", ID);
		SubjectOf.Insert("type", Type);
		SubjectOf.Insert("name", String(Owner));
		
		RunCallback(CallbackDescription, SubjectOf);
		
	Else
		
		IntegrationWith1CDocumentManagementCoreClient.StartSearchingForARelatedObjectDM(
			Owner,
			CallbackDescription);
		
	EndIf;
	
EndProcedure

// Completes the sending of the email after BEFORE after finding the linked document BEFORE.
//
&AtClient
Procedure SendViaDMCompletion(SubjectOf, NotificationParameters) Export
	
	If TypeOf(SubjectOf) <> Type("Structure") Then
		Return;
	EndIf;
	
	EmailParameters = New Structure("SubjectOf", SubjectOf);
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.Outgoing_Email", EmailParameters);
	
EndProcedure

// Starts sending a message by means of IC, if the use of mail is turned off before.
//
&AtClient
Procedure SendViaIS()
	
	If CommonClient.SubsystemExists("StandardSubsystems.EmailOperations") Then
		CallbackDescription = New CallbackDescription("SendViaISAccountSettingProposed", ThisObject);
		ModuleEmailOperationsClient =
			CommonClient.CommonModule("EmailOperationsClient");
		ModuleEmailOperationsClient.CheckAccountForSendingEmailExists(CallbackDescription);
	Else
		ShowMessageBox(, NStr("vi = 'Không hỗ trợ gửi tệp';
								|ru = 'Отправка файлов не поддерживается';
								|en = 'File sending is not supported'; fa = 'File sending is not supported';
								|it = 'Отправка файлов не поддерживается';
								|pl = 'File sending is not supported';
								|tr = 'Dosya gönderimi desteklenmemektedir'"));
	EndIf;
	
EndProcedure

// Continues sending emails by means of IC after placing files from BEFORE in the repository.
//
&AtClient
Procedure SendViaISAccountSettingProposed(AccountSetUp, Var_Parameters) Export
	
	If AccountSetUp <> True Then
		Return;
	EndIf;
	
	Attachments = New Array;
	For Each SelectedRow In Items.Files.SelectedRows Do
		String = Files.FindByID(SelectedRow);
		Presentation = StrTemplate("%1.%2", String.Description, String.Extension);
		Attachment = New Structure;
		Attachment.Insert("Presentation", Presentation);
		Attachment.Insert("Id", Undefined);
		Attachment.Insert("IdBefore", String.ID);
		Attachments.Add(Attachment);
	EndDo;
	
	Var_Parameters = OutgoingMessageParameters(Owner, Attachments, UUID);
	
	ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
	ModuleEmailOperationsClient.CreateNewEmailMessage(Var_Parameters);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Electronic signature

// Gets signatures from BEFORE and updates the form.
//
&AtServer
Procedure ReadAndUpdateListOfFilesAndSignatures()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	FieldsReceived = New Array;
	FieldsReceived.Add("files");
	If Type = "DMInternalDocument" Or Type = "DMIncomingDocument" Or Type = "DMOutgoingDocument" Then
		FieldsReceived.Add("enabledProperties");
	EndIf;
	If ShowDeleted Then
		FieldsReceived.Add("ignoreDeletionMark");
	EndIf;
	
	XDTODataObject = IntegrationWith1CDocumentManagementCore.GetObject(
		Proxy,
		Type,
		ID,
		FieldsReceived);
	
	IntegrationWith1CDocumentManagementCoreServerCall.UpdateFileList(
		XDTODataObject.files,
		Files);
	
	IntegrationWith1CDocumentManagementCore.UpdateListOfFileSignatures(
		XDTODataObject.files,
		Signatures,
		UUID);
	
EndProcedure

#EndRegion