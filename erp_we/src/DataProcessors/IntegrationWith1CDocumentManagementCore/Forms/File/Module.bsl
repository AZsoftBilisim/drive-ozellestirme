#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	UseIntegrationBefore2 = Settings.UseIntegrationBefore2;
	UseIntegrationBefore3 = Settings.UseIntegrationBefore3;
	
	UseProcessesAndTasks1CDocumentManagement = False;
	If UseIntegrationBefore2 Then
		FOName = "UseProcessesAndTasks1CDocumentManagement";
		UseProcessesAndTasks1CDocumentManagement = GetFunctionalOption(FOName);
	EndIf;
	
	CaptureAndEditingIsAvailable =
		IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.4.9.1");
	Items.OpenForEditing.Visible = CaptureAndEditingIsAvailable;
	Items.OpenForEditingPanel.Visible = CaptureAndEditingIsAvailable;
	Items.EndEdit.Visible = CaptureAndEditingIsAvailable;
	Items.FinishEditingPanel.Visible = CaptureAndEditingIsAvailable;
	Items.SaveChangesPanel.Visible = CaptureAndEditingIsAvailable;
	Items.UndoEditingPanel.Visible = CaptureAndEditingIsAvailable;
	Items.OpenFileDirectoryPanel.Visible = CaptureAndEditingIsAvailable;
	
	Items.PresentationEdits.Visible = CaptureAndEditingIsAvailable;
	Items.SceneryIsEdited.Visible = Not CaptureAndEditingIsAvailable;
	
	ID = Parameters.ID;
	OriginalID = Parameters.OriginalID; // Filled in if a new file is created by copying an existing file.
	TemplateID = Parameters.TemplateID; // Filled in if a new file is created from a template.
	
	If Not Parameters.Property("EditingAllowed", EditingAllowed) Then
		EditingAllowed = True;
	EndIf;
	
	GetFileDescriptionAndFillOutForm(Parameters);
	
	SettingsOf1CDocumentManagement = IntegrationWith1CDocumentManagementCoreCached.GetSettings();
	TitleOfMessageInPreviewArea = SettingsOf1CDocumentManagement.TitleOfMessageInPreviewArea;
	WorkflowSettingsUseItemInstances = SettingsOf1CDocumentManagement.UseElectronicDigitalSignatures;
	UseDigitalSignature =
		IntegrationWith1CDocumentManagementCoreServerCall.UseElectronicDigitalSignatures();
	ListOfExtensionsOfScannedCopiesOfOriginals = SettingsOf1CDocumentManagement.ListOfExtensionsOfScannedCopiesOfOriginals;
	ShowPDFUsing1C = SettingsOf1CDocumentManagement.ShowPDFUsing1C;
	If ShowPDFUsing1C Then
		ModuleIntegrationWith1CDocumentManagement3 = Common.CommonModule("IntegrationWith1CDocumentManagement3");
		ModuleIntegrationWith1CDocumentManagement3.OutputPDFDocumentToForm(ThisObject, "PageGroupPDF");
	EndIf;
	
	If WorkflowSettingsUseItemInstances = False Then
		Items.EPImage.Visible = False;
		Items.EPGroup.Visible = False;
		Items.FormSaveWithDigitalSignature.Visible = False;
	EndIf;
	
	If WorkflowSettingsUseItemInstances = False Or UseDigitalSignature = False Then
		Items.FormSign.Visible = False;
		Items.FormAddDSFromFile.Visible = False;
		Items.SignatureTableValidate.Visible = False;
		Items.SignatureTableCheckEverything.Visible = False;
	EndIf;
	
	ColumnsArray = New Array;
	For Each ColumnDetails In FormAttributeToValue("SignatureTable").Columns Do
		ColumnsArray.Add(ColumnDetails.Name);
	EndDo;
	SignatureTableColumnsDetails = New FixedArray(ColumnsArray);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetAvaliabilityOfDSCommandsList();
	
	BinaryData = BinaryDataFromTemporaryFileStorage();
	If TypeOf(BinaryData) = Type("BinaryData") Or ValueIsFilled(PresentationHTML) Then
		HTMLObjectPreview =
			IntegrationWith1CDocumentManagementCoreClientServer.NotificationParametersReceivedHTMLObjectPreview();
		HTMLObjectPreview.ID = ID;
		HTMLObjectPreview.Type = Type;
		HTMLObjectPreview.Extension = Extension;
		If TypeOf(BinaryData) = Type("BinaryData") Then
			HTMLObjectPreview.BinaryData = BinaryData;
		Else
			HTMLObjectPreview.PresentationHTML = PresentationHTML;
			HTMLObjectPreview.PreviewCut = PreviewCut;
		EndIf;
		Notify("HTMLObjectPreviewReceived", HTMLObjectPreview, ThisObject);
	Else
		Items.ViewPages.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If ShowPDFUsing1C Then
		ThisObject["PDFDocumentAttributes"] = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If ClosingWithParameter Then
		Return;
	EndIf;
	
	If Modified Then
		
		Notification = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		WarningText = "";
		CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit,,WarningText);
		
	Else
		
		Cancel = True;
		AttachIdleHandler("CloseWithParameter", 0.1, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Not IsOpen() Then
		Return;
	EndIf;
	
	If EventName = "HTMLObjectPreviewReceived" Then
		If Not IntegrationWith1CDocumentManagementCoreClientServer.TheseAreNotificationParametersHTMLObjectPreviewReceived(
				Parameter) Then
			Return;
		EndIf;
		ProcessHTMLPreviewReceiptEvent(Parameter, Source);
		
	ElsIf EventName = "Recording_1CDocumentManagementFile" Then
		If TypeOf(Parameter) <> Type("Structure")
				Or Not Parameter.Property("FileOperation")
				Or Not Parameter.Property("FileID")
				Or Not Parameter.FileOperation.InformFormOfFile
				Or Parameter.FileID <> ID
				Or Parameter.FileOperation.DeleteFile Then
			Return;
		EndIf;
		NeedUpdate = True;
		If Parameter.FileOperation.EditingFile Then
			NeedUpdate = Not IsBeingEdited;
		EndIf;
		If NeedUpdate Then
			GetFileDescriptionAndFillOutForm();
			SetAvaliabilityOfDSCommandsList();
			If Items.AdditionalPageDataGroup.CurrentPage = Items.EPGroup
					And SignatureTable.Count() > 0 Then
				CheckAllSignatures(Undefined);
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AdditionalPageDataGroupOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.EPGroup And SignatureTable.Count() > 0 Then
		CheckAllSignatures(Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure PictureIsLargeClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	Cancel = False;
	
	If Not ValueIsFilled(ID) Then
		WriteExecuteClient(Cancel);
	EndIf;
	
	If Not Cancel Then
		IntegrationWith1CDocumentManagementCoreClient.OpenFile(
			ID,
			Description,
			Extension,
			UUID);
	EndIf;
	
EndProcedure

&AtClient
Procedure PictureInteractionClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If UseProcessesAndTasks1CDocumentManagement Then
		
		ExternalObject = New Structure;
		ExternalObject.Insert("ID", ID);
		ExternalObject.Insert("type", Type);
		ExternalObject.Insert("presentation", "");
		
		FormParameters = New Structure("ExternalObject", ExternalObject);
		FormNameAllIssues = "DataProcessor.IntegrationWith1CDocumentManagement.Form.AllTasks";
		
		OpenForm(
			FormNameAllIssues,
			FormParameters,
			ThisObject,
			UniqueKey,
			Window);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure EPImageClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Encrypted Or Not Exists Then
		Return;
	EndIf;
	
	Items.AdditionalPageDataGroup.CurrentPage = Items.EPGroup;
	CheckAllSignatures(Undefined);
	
EndProcedure

&AtClient
Procedure PresentationHTMLOnClick(Item, EventData, StandardProcessing)
	
	StandardProcessing = False;
	If Not ValueIsFilled(EventData.Href) Then
		Return;
	EndIf;
	
	If StrFind(EventData.Href, "OpenForEdit") Then
		
		IntegrationWith1CDocumentManagementCoreClient.OpenFile(
			ID,
			Description,
			Extension,
			UUID,
			False,,
			OwnerID);
		
	ElsIf StrFind(EventData.Href, "OpenForView") Then
		
		IntegrationWith1CDocumentManagementCoreClient.OpenFile(
			ID,
			Description,
			Extension,
			UUID);
		
	ElsIf StrFind(EventData.Href, "CreatePreview") Then
		
		UpdatePreview1(True);
		
	EndIf;
	
EndProcedure

&AtClient
Async Procedure IsOriginalOnChange(Val Item)
	
	If IsOriginal Then
		SettingAttributeIsOriginalIsPossible =
			Await IntegrationWith1CDocumentManagementCoreClient.SettingAttributeIsOriginalIsPossible(
				TemplateID,
				Extension,
				ListOfExtensionsOfScannedCopiesOfOriginals);
		If Not SettingAttributeIsOriginalIsPossible Then
			IsOriginal = False;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProperties

&AtClient
Procedure PropertiesValueStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.SelectValueOfAdditionalProps(
		ThisObject,
		Item,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure PropertiesOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.Properties.CurrentData;
	If CurrentData.AvailableTypeList.Count() <> 1 Then
		Return;
	EndIf;
		
	If TypeOf(CurrentData.Value) = Type("String") Then
		XDTOType =CurrentData.AvailableTypeList[0].Value.xdtoClassName;
		If XDTOType = "integer" Then
			CurrentData.Value = 0;
		ElsIf XDTOType = "boolean" Then
			CurrentData.Value = False;
		ElsIf XDTOType = "date" Then
			CurrentData.Value = Date(1, 1, 1);
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure PropertiesValueAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If Not ValueIsFilled(Text) Then
		Return;
	EndIf;
	
	CurrentData = Items.Properties.CurrentData;
	If CurrentData.AvailableTypeList.Count() <> 1 Then
		StandardProcessing = False;
		Return;
	EndIf;
		
	XDTOType = CurrentData.AvailableTypeList[0].Value.xdtoClassName;
	
	If XDTOType = "integer"
			Or XDTOType = "boolean"
			Or XDTOType = "date"
			Or XDTOType = "string" Then
		Return;
	EndIf;
		
	If XDTOType = "DMObjectPropertyValue" Then
		AdditionalProperty = New Structure;
		AdditionalProperty.Insert("ID", CurrentData.PropertyID);
		AdditionalProperty.Insert("type", CurrentData.PropertyType);
		Filter = New Structure("additionalProperty", AdditionalProperty);
	Else
		Filter = Undefined;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
		XDTOType,
		ChoiceData,
		Text,
		StandardProcessing,
		Filter);
	
EndProcedure

&AtClient
Procedure PropertiesValueTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If Not ValueIsFilled(Text) Then
		Return;
	EndIf;
	
	CurrentData = Items.Properties.CurrentData;
	If CurrentData.AvailableTypeList.Count() <> 1 Then
		StandardProcessing = False;
		Return;
	EndIf;
		
	XDTOType = CurrentData.AvailableTypeList[0].Value.xdtoClassName;
	
	If XDTOType = "integer"
		Or XDTOType = "boolean"
		Or XDTOType = "string"
		Or XDTOType = "date" Then
		Return;
	EndIf;
		
	If XDTOType = "DMObjectPropertyValue" Then
		AdditionalProperty = New Structure;
		AdditionalProperty.Insert("ID", CurrentData.PropertyID);
		AdditionalProperty.Insert("type", CurrentData.PropertyType);
		Filter = New Structure("additionalProperty", AdditionalProperty);
	Else
		Filter = Undefined;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
		XDTOType, ChoiceData, Text, StandardProcessing, Filter);
	
	If ChoiceData.Count() = 1 Then
		IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
			"Value", ChoiceData[0].Value, StandardProcessing, ThisObject, True, Item);
		StandardProcessing = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure PropertiesValueChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Value", ValueSelected, StandardProcessing, ThisObject, True, Item);
	
EndProcedure

&AtClient
Procedure PropertiesValueClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	Items.Properties.CurrentData.Value = "";
	Items.Properties.CurrentData.ValueID = "";
	Items.Properties.CurrentData.ValueType = "";
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDS

&AtClient
Procedure SignatureTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	IntegrationWith1CDocumentManagementCoreClient.OpenSignature(Items.SignatureTable.CurrentData);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PDFDocumentEnlarge(Command)
	
	Items["DocumentPDFField"].Scale = Items["DocumentPDFField"].Scale + 10;
	
EndProcedure

&AtClient
Procedure PDFDocumentReduce(Command)
	
	If Items["DocumentPDFField"].Scale <= 10 Then
		Return;
	EndIf;
	
	Items["DocumentPDFField"].Scale = Items["DocumentPDFField"].Scale - 10;
	
EndProcedure

&AtClient
Procedure PDFDocumentLeftTurn(Command)
	
	Items["DocumentPDFField"].Orientation = Items["DocumentPDFField"].Orientation - 90;
	
EndProcedure

&AtClient
Procedure PDFDocumentTurnRight(Command)
	
	Items["DocumentPDFField"].Orientation = Items["DocumentPDFField"].Orientation + 90;
	
EndProcedure


&AtClient
Procedure Refresh(Command)
	
	GetFileDescriptionAndFillOutForm();
	If Items.AdditionalPageDataGroup.CurrentPage = Items.EPGroup
			And SignatureTable.Count() > 0 Then
		CheckAllSignatures(Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdatePreviewCommand(Command)
	
	UpdatePreview1();
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	Cancel = False;
	WriteExecuteClient(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	Close();
	
EndProcedure

&AtClient
Procedure ShowInList(Command)
	
	OpeningParameters = IntegrationWith1CDocumentManagementCoreClient.OptionsForOpeningListOfFiles();
	OpeningParameters.CurrentFile = ID;
	OpeningParameters.FileOwnerID = OwnerID;
	OpeningParameters.FileOwnerType = OwnerType;
	OpeningParameters.OwnerPresentation = OwnerPresentation;
	IntegrationWith1CDocumentManagementCoreClient.OpenFormAttachedFiles(
		FileOwner,
		OpeningParameters);
	
EndProcedure

&AtClient
Procedure OpenForReading(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.OpenFile(
		ID,
		Description,
		Extension,
		UUID);
	
EndProcedure

&AtClient
Procedure OpenForEditing(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.OpenFile(
		ID,
		Description,
		Extension,
		UUID,
		False,,
		OwnerID);
	
EndProcedure

&AtClient
Procedure EndEdit(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.EndFileEditing(
		ID,
		Description,
		Extension,
		UUID,,
		OwnerID);
	
EndProcedure

&AtClient
Procedure SaveToDisk(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.SaveFileAs(
		ID,
		Description,
		Extension,
		UUID);
	
EndProcedure

&AtClient
Procedure FileOperationsStill(Command)
	
	Popup = New ValueList;
	If CaptureAndEditingIsAvailable Then
		Popup.Add("OpenFileDirectory", NStr("vi = 'Mở thư mục tệp';
											|ru = 'Открыть каталог файла';
											|en = 'Open file directory'; fa = 'باز کردن پوشه فایل';
											|it = 'Apri catalogo del file';
											|pl = 'Otwórz katalog pliku';
											|tr = 'Dosya kataloğunu aç'"),,
			PictureLib.Folder);
	EndIf;
	If (Not IsBeingEdited Or EditedByCurUser) And EditingAllowed And Not HasSignatures Then
		Popup.Add("UpdateFromFileOnHardDrive", NStr("vi = 'Cập nhật từ tệp trên đĩa';
													|ru = 'Обновить из файла на диске';
													|en = 'Update from a file on a hard drive.'; fa = 'به‌روزرسانی از فایل روی دیسک سخت.';
													|it = 'Aggiornare dal file sul disco';
													|pl = 'Zaktualizuj z pliku na dysku';
													|tr = 'Sabit sürücüdeki dosyadan güncelle'"),,
			PictureLib.UpdateFileFromFileOnHardDrive);
	EndIf;
	If CaptureAndEditingIsAvailable And EditedByCurUser And Not HasSignatures Then
		Popup.Add("CancelEdit", NStr("vi = 'Hủy bỏ soạn';
									|ru = 'Отменить редактирование';
									|en = 'Cancel editing'; fa = 'لغو ویرایش';
									|it = 'Annulla modifiche';
									|pl = 'Anuluj edycję';
									|tr = 'Düzenlemeyi iptal et'"),,
			PictureLib.UnlockFile);
		If EditingAllowed Then
			Popup.Add("SaveChanges", NStr("vi = 'Lưu các thay đổi';
											|ru = 'Сохранить изменения';
											|en = 'Save changes'; fa = 'ذخیره تغییرات';
											|it = 'Salvare le modifiche';
											|pl = 'Zapisz zmiany';
											|tr = 'Değişiklikleri kaydet'"),,
				PictureLib.PublishFile);
		EndIf;
	EndIf;
	CallbackDescription = New CallbackDescription("FileOperationsEvenAfterSelection", ThisObject);
	ShowChooseFromMenu(CallbackDescription, Popup, Items.FileOperationsStill);
	
EndProcedure

&AtClient
Procedure FileOperationsEvenAfterSelection(Result, Var_Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Value = "OpenFileDirectory" Then
		OpenFileDirectory();
	ElsIf Result.Value = "UpdateFromFileOnHardDrive" Then
		UpdateFromFileOnHardDrive();
	ElsIf Result.Value = "CancelEdit" Then
		CancelEdit();
	ElsIf Result.Value = "SaveChanges" Then
		SaveChanges();
	EndIf;
	
EndProcedure

&AtClient
Procedure Sign(Command)
	
	FileProperties = IntegrationWith1CDocumentManagementCoreClientServer.FileProperties();
	FileProperties.FileID = ID;
	FileProperties.FileName = Description;
	FileProperties.FileOwner = OwnerID;
	FileProperties.IsBeingEdited = IsBeingEdited;
	FileProperties.Encrypted = Encrypted;
	FileProperties.FileDetails = LongDesc;
	FileProperties.FormUniqueID = UUID;
	FileProperties.FileSignatureData =
		IntegrationWith1CDocumentManagementCoreClient.DataOfSignatures(SignatureTable);
	
	IntegrationWith1CDocumentManagementCoreClient.SignFile(FileProperties);
	
EndProcedure

&AtClient
Procedure VerifySignature(Command)
	
	SelectedSignatures = IntegrationWith1CDocumentManagementCoreClient.SelectedSignatures(
		Items.SignatureTable.SelectedRows,
		SignatureTable);
	
	IntegrationWith1CDocumentManagementCoreClient.VerifySignatures(
		SignatureTable,
		Undefined,
		Undefined,
		SelectedSignatures);
	
EndProcedure

&AtClient
Procedure CheckAllSignatures(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.VerifySignatures(SignatureTable);
	
EndProcedure

&AtClient
Procedure DeleteSignature(Command)
	
	SelectedSignatures = IntegrationWith1CDocumentManagementCoreClient.SelectedSignatures(
		Items.SignatureTable.SelectedRows,
		SignatureTable);
	
	IntegrationWith1CDocumentManagementCoreClient.DeleteSignatures(
		SelectedSignatures,
		SignatureTable,
		OwnerID,,
		UUID);
	
EndProcedure

&AtClient
Procedure Send(Command)
	
	FormParameters = New Structure("MainTask, SubjectOf", New Structure, New Structure);
	
	FormParameters.SubjectOf.Insert("name", Description);
	FormParameters.SubjectOf.Insert("ID", ID);
	FormParameters.SubjectOf.Insert("type", Type);
	FormParameters.SubjectOf.Insert("ExternalObject", FileOwner);
	
	NameOfFormCreatingBusinessProcess = "DataProcessor.IntegrationWith1CDocumentManagement.Form.CreatingBusinessProcess";
	OpenForm(NameOfFormCreatingBusinessProcess, FormParameters);
	
EndProcedure

&AtClient
Procedure AddDSFromFile(Command)
	
	FileSignatureData = IntegrationWith1CDocumentManagementCoreClient.DataOfSignatures(SignatureTable);
	
	FileProperties = IntegrationWith1CDocumentManagementCoreClientServer.FileProperties();
	FileProperties.FileID = ID;
	FileProperties.FileName = Description;
	FileProperties.FileDetails = LongDesc;
	FileProperties.IsBeingEdited = IsBeingEdited;
	FileProperties.Encrypted = Encrypted;
	FileProperties.FileSignatureData = FileSignatureData;
	FileProperties.FormUniqueID = UUID;
	FileProperties.FileOwner = OwnerID;
	
	IntegrationWith1CDocumentManagementCoreClient.StartAddingItemsFromFile(FileProperties);
	
EndProcedure

&AtClient
Procedure SaveWithDigitalSignature(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.StartSavingTogetherBOT(
		ID,
		Extension,
		Description,
		Size,
		UniversalModificationDate,
		UUID);
	
EndProcedure

&AtClient
Procedure OpenSignature(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.OpenSignature(Items.SignatureTable.CurrentData);
	
EndProcedure

&AtClient
Procedure WriteObject(Command)
	
	Cancel = False;
	WriteExecuteClient(Cancel);
	
EndProcedure

&AtClient
Procedure Save(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.SaveSignature(Items.SignatureTable.CurrentData);
	
EndProcedure

#EndRegion

#Region Private

#Region Client

// Closes the form without questions and modifiability checks.
//
&AtClient
Procedure CloseWithParameter()
	
	ClosingWithParameter = True;
	Close(DialogReturnCode.Cancel);
	
EndProcedure

// Records the file and its signatures.
//
&AtClient
Procedure WriteExecuteClient(Cancel)
	
	If Not ValueIsFilled(Description) Then
		ClearMessages();
		CommonClient.MessageToUser(
			CommonClientServer.FillingErrorText(,, NStr("vi = 'Tên gọi';
														|ru = 'Наименование';
														|en = 'Description'; fa = 'شرح';
														|it = 'Наименование';
														|pl = 'Description';
														|tr = 'Tanım'")),,
			"Description");
		Cancel = True;
		Return;
	EndIf;
	
	If ValueIsFilled(ID) Then
		FileSignatureData = IntegrationWith1CDocumentManagementCoreClient.DataOfSignatures(SignatureTable);
		WriteExecute(FileSignatureData);
	ElsIf ValueIsFilled(OriginalID) Then
		CreateFromOriginal();
	ElsIf ValueIsFilled(TemplateID) Then
		CreateFromTemplate();
	EndIf;
	
	FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
	FileOperation.WritingFile = True;
	FileOperation.InformFormOfFile = True;
	FileOperation.InformFileListForm = True;
	IntegrationWith1CDocumentManagementCoreClient.InformAboutFileChanges(
		FileOperation,
		Description,
		ID,
		OwnerID,,,
		UUID);
	
	Modified = False;
	
EndProcedure

&AtClient
Procedure UpdateFromFileOnHardDrive()
	
	IntegrationWith1CDocumentManagementCoreClient.UpdateFromFileOnHardDrive(
		ID,
		Description,
		Extension,
		ToLocalTime(UniversalModificationDate),
		UUID,,
		OwnerID);
	
EndProcedure

&AtClient
Procedure UpdatePreview1(IgnoreMaxSize = False)
	
	If UseIntegrationBefore3 Then
		PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.DownloadMessage();
		Items.ViewPages.CurrentPage = Items.HTMLGroupPage;
		Items.GroupPreviewCut.Visible = False;
		
		ModuleIntegrationWith1CWorkflow3ServerCall = CommonClient.CommonModule(
			"IntegrationWith1CDocumentManagement3ServerCall");
		ReturnBinaryData = ShowPDFUsing1C And Lower(Extension) = "pdf" And Not Encrypted;
		TimeConsumingOperation = ModuleIntegrationWith1CWorkflow3ServerCall.GetHTMLPreviewOfObjectAsynchronously(
			UUID,
			ID,
			Type,
			IgnoreMaxSize,
			IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
				OwnerID,
				OwnerType),
			ReturnBinaryData);
		
		CallbackOnCompletion = New CallbackDescription(
			"UpdatePreview1Completion",
			ThisObject);
		
		IntegrationWith1CDocumentManagementCoreClient.ExecuteRequestAsynchronously(
			ThisObject,
			TimeConsumingOperation,
			CallbackOnCompletion,
			False,,
			False);
	EndIf;
	
EndProcedure

// Called after getting a preview of the object BEFORE.
//
// Parameters:
//   Result - See TimeConsumingOperations.ActionCompleted
//   NotificationParameters - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//
&AtClient
Procedure UpdatePreview1Completion(Result, NotificationParameters) Export
	
	HTMLObjectPreview =
		IntegrationWith1CDocumentManagementCoreClientServer.NotificationParametersReceivedHTMLObjectPreview();
	
	If Result <> Undefined And Result.Status = "Error" Then
		HTMLMessage =
			IntegrationWith1CDocumentManagementCoreClientServer.PreviewMessage(
				Result.BriefErrorDescription,
				TitleOfMessageInPreviewArea);
		HTMLObjectPreview.ID = ID;
		HTMLObjectPreview.Type = Type;
		HTMLObjectPreview.Extension = Extension;
		HTMLObjectPreview.PresentationHTML = HTMLMessage;
		Notify("HTMLObjectPreviewReceived", HTMLObjectPreview, ThisObject);
		Raise Result.BriefErrorDescription;
	ElsIf IntegrationWith1CDocumentManagementCoreClient.ActionCompleted(Result) Then
		IntegrationWith1CDocumentManagementCoreClientServer.AddPersonalData(HTMLObjectPreview);
		FillPropertyValues(HTMLObjectPreview, Result.ResultLongOperation);
		HTMLObjectPreview.ID = ID;
		HTMLObjectPreview.Type = Type;
		HTMLObjectPreview.Extension = Extension;
		If IsBlankString(HTMLObjectPreview.PresentationHTML) Then
			HTMLObjectPreview.PresentationHTML =
				IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
					TitleOfMessageInPreviewArea);
		EndIf;
		Notify("HTMLObjectPreviewReceived", HTMLObjectPreview, ThisObject);
	EndIf;
	
EndProcedure

// Handler for the "GETTHTML Object view" event.
//
// Parameters:
//   Parameter - See IntegrationWith1CDocumentManagementCoreClientServer.NotificationParametersReceivedHTMLObjectPreview
//   Source - Arbitrary - event source.
//
&AtClient
Procedure ProcessHTMLPreviewReceiptEvent(Parameter, Source)
	
	If Parameter.ID = ID And Parameter.Type = Type Then
		If TypeOf(Parameter.BinaryData) = Type("BinaryData") And Lower(Parameter.Extension) = "pdf" Then
			PresentationHTML = "";
			PreviewCut = False;
			AddressInPreviewFileStorage = PutToTempStorage(
				Parameter.BinaryData,
				UUID);
		Else
			PresentationHTML = Parameter.PresentationHTML;
			PreviewCut = Parameter.PreviewCut;
		EndIf;
		UpdatePreviewElements();
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenFileDirectory()
	
	IntegrationWith1CDocumentManagementCoreClient.OpenFileDirectory(ID);
	
EndProcedure

&AtClient
Procedure CancelEdit()
	
	IntegrationWith1CDocumentManagementCoreClient.UndoFileEditing(
		ID,,
		OwnerID,
		UUID);
	
EndProcedure

// Called after the "Save Changes" request and completes the closure.
//
&AtClient
Procedure BeforeCloseCompletion(Response, NotificationParameters) Export
	
	Cancel = False;
	
	WriteExecuteClient(Cancel);
	NotificationParameters = New Structure;
	Notify("Recording_1CDocumentManagementDocument", NotificationParameters, FormOwner);
	
	If Not Cancel Then
		CloseWithParameter();
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveChanges()
	
	IntegrationWith1CDocumentManagementCoreClient.SaveChangesToEditedFile(
		ID,
		Description,
		Extension,
		UUID,,
		OwnerID);
	
EndProcedure

// Depending on the availability of signatures, it sets the availability of EP commands.
//
&AtClient
Procedure SetAvaliabilityOfDSCommandsList()
	
	Items.SignatureTableValidate.Enabled = HasSignatures And Not Encrypted;
	Items.SignatureTableCheckEverything.Enabled = HasSignatures And Not Encrypted;
	Items.SignatureTableOpenSignature.Enabled = HasSignatures And Not Encrypted;
	Items.SignatureTableSave.Enabled = HasSignatures And Not Encrypted;
	Items.TableOfSignaturesDelete.Enabled = HasSignatures And Not Encrypted;
	
	Items.FormSaveWithDigitalSignature.Enabled = HasSignatures And Not Encrypted;
	
EndProcedure

#EndRegion

#Region Server

&AtServer
Function BinaryDataFromTemporaryFileStorage()
	
	BinaryData = Undefined;
	If ShowPDFUsing1C
			And Lower(Extension) = "pdf"
			And Not EditedByCurUser
			And IsTempStorageURL(TempFileStorageAddress) Then
		BinaryData = GetFromTempStorage(TempFileStorageAddress);
	EndIf;
	
	Return BinaryData;
	
EndFunction

// Records the file and the specified signatures.
//
&AtServer
Procedure WriteExecute(ArrayOfExistingFileSignatures)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	XDTOFile = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, Type);
	
	XDTOFile.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, ID, Type);
	
	// When recording, we pass the Name, Description, the attribute Is the original, Add. properties, as well as signatures.
	XDTOFile.name = Description;
	XDTOFile.description = LongDesc;
	XDTOFile.scannedOriginal = IsOriginal;
	
	IntegrationWith1CDocumentManagementCore.FillInSignaturesOfXDTOObject(
		Proxy,
		XDTOFile,
		ArrayOfExistingFileSignatures);
	
	DataProcessors.IntegrationWith1CDocumentManagementCore.GenerateAdditionalProperties(
		Proxy,
		XDTOFile,
		ThisObject);
	
	IntegrationWith1CDocumentManagementCore.WriteObject(Proxy, XDTOFile);
	
EndProcedure

// Fills in the form with the file data.
//
// Parameters:
//   FileDetails - See IntegrationWith1CDocumentManagementCoreServerCall.FileDetails
//
&AtServer
Procedure FillForm(FileDetails)
	
	Exists = ValueIsFilled(ID);
	
	Encrypted = FileDetails.Encrypted;
	TemplateTextWithExplanation = "%1 (%2)";
	Size = FileDetails.Size;
	PresentationSize = IntegrationWith1CDocumentManagementCoreClientServer.BriefSizePresentation(Size);
	Description = FileDetails.Description;
	LongDesc = FileDetails.LongDesc;
	Extension = FileDetails.Extension;
	FullFileName = IntegrationWith1CDocumentManagementCoreClientServer.FileNameWithExtension(
		Description,
		Extension);
	CreationDate = FileDetails.CreationDate;
	UniversalModificationDate = FileDetails.UniversalModificationDate;
	Author = FileDetails.Author;
	Type = "DMFile";
	IsBeingEdited = FileDetails.IsBeingEdited;
	TemplateID = FileDetails.TemplateID;
	IsOriginal = FileDetails.IsOriginal;
	Items.IsOriginal.Visible = FileDetails.IsOriginalVisibility;
	Items.IsOriginal.ReadOnly = FileDetails.IsOriginalViewOnly;
	
	PictureIndex = IntegrationWith1CDocumentManagementCore.IndexOfFileIcon(Extension);
	
	If FileDetails.Property("Owner") And ValueIsFilled(FileDetails.Owner) Then
		OwnerPresentation = FileDetails.Owner;
		Items.OwnerPresentation.Visible = True;
		FileDetails.Property("Owner", Owner);
		FileDetails.Property("OwnerID", OwnerID);
		FileDetails.Property("OwnerType", OwnerType);
		FileDetails.Property("FileOwner", FileOwner);
		Items.FormShowInList.Visible = True;
		
		OwnerTypePresentation = IntegrationWith1CDocumentManagementCore.ObjectTypePresentationXDTO(
			OwnerType);
		Items.OwnerPresentation.Title = OwnerTypePresentation;
		Items.Owner.Title = OwnerTypePresentation;
	Else
		Items.OwnerPresentation.Visible = False;
		Items.FormShowInList.Visible = False;
	EndIf;
	
	//@skip-check module-nstr-camelcase
	FormatString = NStr("vi = 'DF=""dd.MM.yyyy HH:mm""';
						|ru = 'ДФ=""дд.ММ.гггг ЧЧ:мм""';
						|en = 'DF=""MM/dd/yyyy HH:mm""'; fa = 'DF=""MM/dd/yyyy HH:mm""';
						|it = 'ДФ=""дд.ММ.гггг ЧЧ:мм""';
						|pl = 'DF=""MM/dd/yyyy HH:mm""';
						|tr = 'DF=""dd.MM.yyyy HH:mm""'");
	
	PresentationCreated = StrTemplate(TemplateTextWithExplanation,
		Format(FileDetails.CreationDate, FormatString),
		FileDetails.Author);
	
	If ValueIsFilled(FileDetails.CurVersionDateOfCreation) Then
		PresentationChanged = Format(FileDetails.CurVersionDateOfCreation, FormatString);
		AuthorOfModification = FileDetails.CurrentVersionAuthor;
	Else
		PresentationChanged = Format(FileDetails.ModificationDate, FormatString);
		AuthorOfModification = FileDetails.AuthorOfModification;
	EndIf;
	If ValueIsFilled(AuthorOfModification) Then
		PresentationChanged = StrTemplate(TemplateTextWithExplanation, PresentationChanged, AuthorOfModification);
	EndIf;
	
	If FileDetails.Property("BeingEditedBy") And ValueIsFilled(FileDetails.BeingEditedBy) Then
		BeingEditedBy = FileDetails.BeingEditedBy;
		LockedDate = FileDetails.LockedDate;
		PresentationEdits = StrTemplate(TemplateTextWithExplanation,
			Format(FileDetails.LockedDate, FormatString),
			FileDetails.BeingEditedBy);
		CurCurrentUserAndEmployees =
			IntegrationWith1CDocumentManagementCoreCached.Current1CDocumentManagementUser();
		EditedByCurUser =
			IntegrationWith1CDocumentManagementCoreServerCall.FileIsBeingEditedByCurUser(
				FileDetails.BeingEditedByID,
				FileDetails.BeingEditedByType,
				CurCurrentUserAndEmployees);
	Else
		BeingEditedBy = "";
		LockedDate = Undefined;
		PresentationEdits = "";
		EditedByCurUser = False;
		Items.SceneryIsEdited.Title = ?(IsBeingEdited, NStr("vi = 'Được soạn';
															|ru = 'Редактируется';
															|en = 'Draft'; fa = 'پیش‌نویس';
															|it = 'Редактируется';
															|pl = 'Draft';
															|tr = 'Düzenleniyor'"), "");
	EndIf;
	
	If TypeOf(BinaryDataFromTemporaryFileStorage()) = Type("BinaryData") Then
		PresentationHTML = "";
		PreviewCut = False;
	Else
		PresentationHTML = FileDetails.PresentationHTML;
		PreviewCut = FileDetails.PreviewCut;
	EndIf;
	UpdatePreviewElements();
	
	Items.ApplicationTasks.Title = FileDetails.ApplicationTasks;
	Items.ApplicationTasks.Visible = ValueIsFilled(Items.ApplicationTasks.Title);
	
	CurrentVersionID = FileDetails.CurrentVersionID;
	CurCurrentVersionNumber = FileDetails.CurCurrentVersionNumber;
	Items.CurCurrentVersionNumber.Visible = (FileDetails.CurCurrentVersionNumber <> Undefined);
	CurrentVersionAuthor = FileDetails.CurrentVersionAuthor;
	Items.CurrentVersionAuthor.Visible = (FileDetails.CurrentVersionAuthor <> Undefined);
	CurVersionDateOfCreation = FileDetails.CurVersionDateOfCreation;
	Items.CurVersionDateOfCreation.Visible = (FileDetails.CurVersionDateOfCreation <> Undefined);
	CurVersionDateOfChange = FileDetails.CurVersionDateOfChange;
	Items.CurVersionDateOfChange.Visible = (FileDetails.CurVersionDateOfChange <> Undefined);
	CurrentVersionSize = FileDetails.CurrentVersionSize;
	Items.SizeGroup.Visible = (FileDetails.CurrentVersionSize <> Undefined);
	StoreVersions = FileDetails.StoreVersions;
	Items.StoreVersions.Visible = (FileDetails.StoreVersions <> Undefined);
	
	FileRoleID = FileDetails.FileRoleID;
	FileRoleView = FileDetails.FileRole;
	Items.FileRoleView.Visible = (FileRoleView <> "");
	
	Code = FileDetails.Code;
	Items.Code.Visible = (Code <> "");
	
	Project = FileDetails.Project;
	Items.Project.Visible = (Project <> "");
	
	SignatureTable.Clear();
	
	SignatureOwnerSDetails = IntegrationWith1CDocumentManagementCoreClientServer.SignatureOwnerSDetails(
		Description,
		ID,
		Type,
		Encrypted);
	
	LineNumber = 0;
	For Each Signature In FileDetails.Signatures Do
		IntegrationWith1CDocumentManagementCore.FillInSignatureTreeLine(
			SignatureTable.Add(),
			LineNumber,
			Signature,
			SignatureOwnerSDetails,
			UUID);
		LineNumber = LineNumber + 1;
	EndDo;
	
	NumberOfSignatures = SignatureTable.Count();
	HasSignatures = (NumberOfSignatures <> 0);
	
	TitleText = NStr("vi = 'Chữ ký điện tử';
					|ru = 'ЭП';
					|en = 'Digital signature'; fa = 'امضای دیجیتال';
					|it = 'ЭП';
					|pl = 'Digital signature';
					|tr = 'Dijital İmza'");
	If HasSignatures Then
		TitleText = StrTemplate(TemplateTextWithExplanation,
			TitleText,
			String(NumberOfSignatures));
	EndIf;
	Items.EPGroup.Title = TitleText;
	
	If FileDetails.ItemInstanceStatus <> Undefined Then
		
		ItemInstanceStatus = FileDetails.ItemInstanceStatus;
		Items.EPImage.ToolTip = FileDetails.ItemInstanceStatusHint;
		
	Else
		
		If Encrypted Then
			If NumberOfSignatures = 0 Then
				ItemInstanceStatus = 1;
				Items.EPImage.ToolTip = NStr("vi = 'Đã mã hóa. Chưa ký bởi chữ ký điện tử';
											|ru = 'Зашифрован. Не подписан электронной подписью';
											|en = 'Encrypted. Not digitally signed'; fa = 'Encrypted. Not digitally signed';
											|it = 'Зашифрован. Не подписан электронной подписью';
											|pl = 'Encrypted. Not digitally signed';
											|tr = 'Şifreli. Elektronik imza ile imzalanmadı'");
			Else
				ItemInstanceStatus = 3;
				Items.EPImage.ToolTip = NStr("vi = 'Đã mã hóa. Đã ký bằng chữ ký điện tử. Chưa kiểm tra chữ ký.';
											|ru = 'Зашифрован. Подписан электронной подписью. Подпись не проверена.';
											|en = 'Encrypted. Digitally signed. The signature is not verified.'; fa = 'Encrypted. Digitally signed. The signature is not verified.';
											|it = 'Зашифрован. Подписан электронной подписью. Подпись не проверена.';
											|pl = 'Encrypted. Digitally signed. The signature is not verified.';
											|tr = 'Şifreli. Elektronik imza ile imzalandı. İmza kontrol edilmedi.'");
			EndIf;
		Else
			If NumberOfSignatures = 0 Then
				ItemInstanceStatus = 0;
				Items.EPImage.ToolTip = NStr("vi = 'Chưa ký bằng chữ ký điện tử';
											|ru = 'Не подписан электронной подписью';
											|en = 'Not digitally signed'; fa = 'Not digitally signed';
											|it = 'Не подписан электронной подписью';
											|pl = 'Not digitally signed';
											|tr = 'Elektronik imza ile imzalanmadı'");
			Else
				ItemInstanceStatus = 2;
				Items.EPImage.ToolTip = NStr("vi = 'Đã ký bằng chữ ký điện tử. Chưa kiểm tra chữ ký.';
											|ru = 'Подписан электронной подписью. Подпись не проверена.';
											|en = 'Digitally signed. The signature is not verified.'; fa = 'Digitally signed. The signature is not verified.';
											|it = 'Подписан электронной подписью. Подпись не проверена.';
											|pl = 'Digitally signed. The signature is not verified.';
											|tr = 'Elektronik imza ile imzalanmıştır. İmza kontrol edilmedi.'");
			EndIf;
		EndIf;
		
	EndIf;
	
	If FileDetails.InteractionStatus <> Undefined Then
		
		InteractionStatus = FileDetails.InteractionStatus;
		Items.PictureInteraction.ToolTip = FileDetails.InteractionStatusHint;
		
	Else
		
		ThereAreTasks = False;
		
		If UseIntegrationBefore2 Then
			ModuleIntegrationWith1CDocumentManagement = Common.CommonModule("IntegrationWith1CDocumentManagement");
			ThereAreTasks = ModuleIntegrationWith1CDocumentManagement.ThereAreTasks(ID, Type);
		EndIf;
		
		If ThereAreTasks Then
			InteractionStatus = 1;
			Items.PictureInteraction.ToolTip = NStr("vi = 'Theo tệp đang thực hiện nhiệm vụ';
													|ru = 'По файлу выполняются задачи';
													|en = 'Tasks are being executed by the file'; fa = 'Tasks are being executed by the file';
													|it = 'По файлу выполняются задачи';
													|pl = 'Tasks are being executed by the file';
													|tr = 'Dosya için görevler yürütülür'");
		Else
			InteractionStatus = 0;
			Items.PictureInteraction.ToolTip = NStr("vi = 'Theo tệp không có nhiệm vụ đang thực hiện';
													|ru = 'По файлу нет выполняющихся задач';
													|en = 'There are no tasks that are being executed by the file'; fa = 'There are no tasks that are being executed by the file';
													|it = 'По файлу нет выполняющихся задач';
													|pl = 'There are no tasks that are being executed by the file';
													|tr = 'Dosya için gerçekleştirilen görev mevcut değil'");
		EndIf;
		
	EndIf;
	
	DataProcessors.IntegrationWith1CDocumentManagementCore.PlaceAdditionalDetailsOnForm(
		ThisObject,,
		FileDetails.AddAttributes);
	
EndProcedure

&AtServer
Procedure UpdatePreviewElements()
	
	Items.ViewPages.CurrentPage = Items.HTMLGroupPage;
	Items.GroupPreviewCut.Visible = (Not EditedByCurUser And PreviewCut);
	
	ThereIsPreviewFile = IsTempStorageURL(AddressInPreviewFileStorage) And Not Encrypted;
	
	If ThereIsPreviewFile And Not ValueIsFilled(PresentationHTML) Then
		If EditedByCurUser Then
			PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutEditing(
				TitleOfMessageInPreviewArea);
		Else
			PDFDocument = IntegrationWith1CDocumentManagementCoreServerCall.GetPDFDocument(
				AddressInPreviewFileStorage);
			If PDFDocument = Undefined Then
				PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
					TitleOfMessageInPreviewArea);
			Else
				ThisObject["PDFDocumentAttributes"] = PDFDocument;
				Items.ViewPages.CurrentPage = Items.PageGroupPDF;
				Items["DocumentPDFField"].CurrentPageNumber = 1;
			EndIf;
		EndIf;
	ElsIf Not ValueIsFilled(PresentationHTML) Then
		PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
			TitleOfMessageInPreviewArea);
	EndIf;
	
EndProcedure

// Retrieves the file description by ID and fills in the form fields.
//
// Parameters:
//   FormParameters - Structure - Form parameters
//     Processing.Integrations1documentobase functionality.Form.The file.
//
&AtServer
Procedure GetFileDescriptionAndFillOutForm(FormParameters = Undefined)
	
	TempFileStorageAddress = PutToTempStorage(Undefined, UUID);
	If ValueIsFilled(ID) Then
		FileDetails = IntegrationWith1CDocumentManagementCoreServerCall.FileDetails(
			ID,
			ThisObject,
			TempFileStorageAddress);
	ElsIf ValueIsFilled(OriginalID) Then
		FileDetails = IntegrationWith1CDocumentManagementCoreServerCall.FileDetails(
			OriginalID,
			ThisObject,
			TempFileStorageAddress);
	ElsIf ValueIsFilled(TemplateID) And FormParameters <> Undefined Then
		FileDetails = IntegrationWith1CDocumentManagementCoreServerCall.FileDetails(
			TemplateID,
			ThisObject);
		FileDetails.Owner = FormParameters.Owner;
		FileDetails.OwnerID = FormParameters.OwnerID;
		FileDetails.OwnerType = FormParameters.OwnerType;
		FileDetails.FileOwner = FormParameters.FileOwner;
		FileDetails.FileRoleID = FormParameters.FileRoleID;
		FileDetails.TemplateID = FormParameters.TemplateID;
		FileDetails.CreationDate = CurrentSessionDate();
		FileDetails.Code = "";
	Else
		Raise NStr("vi = 'Chưa chỉ ra định danh tệp.';
					|ru = 'Не указан идентификатор файла.';
					|en = 'File ID is not specified.'; fa = 'File ID is not specified.';
					|it = 'ID file non indicato.';
					|pl = 'Nie wskazano identyfikatora pliku.';
					|tr = 'Dosya kimliği belirtilmedi.'");
	EndIf;
	
	FillForm(FileDetails);
	SetCommandsAvailability();
	
	Items.Description.ReadOnly = Not EditingAllowed;
	Items.LongDesc.ReadOnly = Not EditingAllowed;
	
	If ValueIsFilled(ID) Then
		Title = StrTemplate(NStr("vi = '%1 (Tệp)';
								|ru = '%1 (Файл)';
								|en = '%1 (File)'; fa = '%1 (File)';
								|it = '%1 (file)';
								|pl = '%1 (Plik)';
								|tr = '%1 (Dosya)'"), Description);
	Else
		Title = NStr("vi = 'Tệp (tạo mới)';
					|ru = 'Файл (создание)';
					|en = 'File (creation)'; fa = 'File (creation)';
					|it = 'File (creazione)';
					|pl = 'Plik (utworzenie)';
					|tr = 'Dosya (oluşturma)'");
	EndIf;
	
EndProcedure

// Creates a file by copying the original.
//
&AtServer
Procedure CreateFromOriginal()
	
	CurrentFile = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
		Description,
		Undefined,
		"DMFile",
		Extension,
		FileRoleID);
	CurrentFile.LongDesc = LongDesc;
	CurrentFile.Size = Size;
	CurrentFile.ModificationDate = UniversalModificationDate;
	CurrentFile.UniversalModificationDate = UniversalModificationDate;
	
	CreationParameters = IntegrationWith1CDocumentManagementCoreClientServer.NewFileCreationOptions(
		CurrentFile);
	CreationParameters.TempFileStorageAddress = TempFileStorageAddress;
	CreationParameters.Owner = FileOwner;
	CreationParameters.IsScannedCopy = IsOriginal;
	
	ID = IntegrationWith1CDocumentManagementCoreServerCall.CreateFileInWorkflow(
		CreationParameters,
		OwnerID,
		OwnerType,
		Owner);
	
	OriginalID = "";
	
	GetFileDescriptionAndFillOutForm();
	
EndProcedure

// Creates a file from a template.
//
&AtServer
Procedure CreateFromTemplate()
	
	CurrentFile = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
		Description,
		Undefined,
		"DMFile",
		Extension,
		FileRoleID);
	CurrentFile.LongDesc = LongDesc;
	CurrentFile.Size = Size;
	CurrentFile.ModificationDate = UniversalModificationDate;
	CurrentFile.UniversalModificationDate = UniversalModificationDate;
	
	CreationParameters = IntegrationWith1CDocumentManagementCoreClientServer.NewFileCreationOptions(
		CurrentFile);
	CreationParameters.TemplateID = TemplateID;
	CreationParameters.Owner = FileOwner;
	CreationParameters.IsScannedCopy = IsOriginal;
	
	ID = IntegrationWith1CDocumentManagementCoreServerCall.CreateFileInWorkflow(
		CreationParameters,
		OwnerID,
		OwnerType,
		Owner);
	
	GetFileDescriptionAndFillOutForm();
	
EndProcedure

&AtServer
Procedure SetCommandsAvailability()
	
	EditedByAnotherUser = IsBeingEdited And Not EditedByCurUser;
	
	CanBeCaptured = CaptureAndEditingIsAvailable
		And Not EditedByAnotherUser
		And EditingAllowed
		And Not Encrypted
		And Not HasSignatures;
	YouCanFinishEditing = Exists And EditedByCurUser And Not Encrypted And Not HasSignatures;
	
	Items.FormShowInList.Enabled = Exists And Not Encrypted;
	Items.OpenForReading.Enabled = Exists And Not Encrypted;
	Items.OpenForReadingPanel.Enabled = Exists And Not Encrypted;
	Items.SaveToDisk.Enabled = Exists And Not Encrypted;
	Items.SaveToDiskPanel.Enabled = Exists And Not Encrypted;
	Items.FileOperationsStill.Enabled = Exists And Not Encrypted;
	Items.OpenFileDirectoryPanel.Enabled = Exists And Not Encrypted;
	
	Items.EPGroup.Enabled = Exists And Not Encrypted;
	Items.EPTeamGroup.Enabled = Exists And Not Encrypted;
	
	Items.OpenForEditing.Enabled = Exists And CanBeCaptured;
	Items.OpenForEditingPanel.Enabled = Exists And CanBeCaptured;
	
	Items.EndEdit.Enabled = YouCanFinishEditing;
	Items.FinishEditingPanel.Enabled = YouCanFinishEditing;
	Items.SaveChangesPanel.Enabled = YouCanFinishEditing;
	Items.UndoEditingPanel.Enabled = YouCanFinishEditing;
	
	Items.UpdateFromFileOnDiskPanel.Enabled = Exists And CanBeCaptured;
	
EndProcedure

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
