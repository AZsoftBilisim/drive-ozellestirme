#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ExternalObject = Parameters.ExternalObject;
	ConsumerMetadata = Parameters.ExternalObject.Metadata();
	ConsumerName = ?(ConsumerMetadata.Synonym <> "",
		ConsumerMetadata.Synonym,
		ConsumerMetadata.Name);
	
	// We get the type and representation of the object being created, if they are unambiguous.
	Rules = IntegrationWith1CDocumentManagementServerCall.SuitableRules(ExternalObject);
	For Each Rule In Rules Do
		If Not ValueIsFilled(TypeOfObjectToCreate) Then
			TypeOfObjectToCreate = Rule.ObjectTypeDM;
		ElsIf TypeOfObjectToCreate <> Rule.ObjectTypeDM Then
			TypeOfObjectToCreate = "";
			Break;
		EndIf;
	EndDo;
	For Each Rule In Rules Do
		If Not ValueIsFilled(PresentationOfObjectBeingCreated) Then
			PresentationOfObjectBeingCreated = Rule.ObjectPresentationDM;
		ElsIf PresentationOfObjectBeingCreated <> Rule.ObjectPresentationDM Then
			PresentationOfObjectBeingCreated = "";
			Break;
		EndIf;
	EndDo;
	
	If ValueIsFilled(PresentationOfObjectBeingCreated) Then
		
		Items.DecorationObjectTitle.Title = StrTemplate("%1:", PresentationOfObjectBeingCreated);
		
	ElsIf ValueIsFilled(TypeOfObjectToCreate) Then
		
		ObjectTypePresentationBefore = IntegrationWith1CDocumentManagementClientServer.ObjectTypePresentationXDTO(
			TypeOfObjectToCreate);
		Items.DecorationObjectTitle.Title = StrTemplate("%1:", ObjectTypePresentationBefore);
		
	Else
		// There are no suitable rules.
		Items.DecorationObjectTitle.Title = NStr("vi = 'So sánh trong 1C:Document Management';
												|ru = 'Соответствие в 1С:Документообороте';
												|en = 'Correspondence in 1C:Document Management'; fa = 'Correspondence in 1C:Document Management';
												|it = 'Corrispondenza in 1C:Document Management';
												|pl = 'Zgodność w 1C:Document Management';
												|tr = '1C:Document Management''te uygunluk'");
		If AccessRight("Insert", Metadata.Catalogs.RulesForIntegrationWith1CDocumentManagement) Then
			Items.InfoDecoration.Title = StringFunctions.FormattedString(
				StrTemplate(
					NStr("vi = 'Chưa tùy chỉnh điền văn bản 1C:Document Management từ ""%1"". <a href = ""%2"">Tùy chỉnh.</a>';
						|ru = 'Не настроено заполнение документа 1С:Документооборота из ""%1"". <a href = ""%2"">Настроить.</a>';
						|en = 'The population of document from 1C:Document Management from ""%1"" is not set up. <a href = ""%2"">Configure.</a>'; fa = 'The population of document from 1C:Document Management from ""%1"" is not set up. <a href = ""%2"">Configure.</a>';
						|it = 'Не настроено заполнение документа 1С:Документооборота из ""%1"". <a href = ""%2"">Настроить.</a>';
						|pl = 'The population of document from 1C:Document Management from ""%1"" is not set up. <a href = ""%2"">Configure.</a>';
						|tr = '%1"". <a href = ""%2"">Ayarlamak.</a>1C:Document Management belgesinden doldurulması ayarlanmadı'"),
					ConsumerName,
					ConsumerMetadata.FullName()));
		Else
			Items.InfoDecoration.Title = StrTemplate(
				NStr("vi = 'Chưa tùy chỉnh điền văn bản 1C:Document Management từ ""%1"".';
					|ru = 'Не настроено заполнение документа 1С:Документооборота из ""%1"".';
					|en = '1C:Document Management document population is not set up from ""%1"".'; fa = '1C:Document Management document population is not set up from ""%1"".';
					|it = 'Non è impostata la compilazione del documento di 1C:Document Management da ""%1"".';
					|pl = 'Nie ustawiono wypełnienie dokumentu 1C:Document Management z ""%1"".';
					|tr = '1C:Document Management belgesinden doldurulması ayarlanmadı ""%1"".'"), ConsumerName);
		EndIf;
		
	EndIf;
	
	MaxFileSize1 =
		IntegrationWith1CDocumentManagementCoreServerCall.MaximumFileSize_();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ExternalObject.IsEmpty() Then
		WarningText = NStr("vi = 'Còn chưa ghi lại dữ liệu. 
			|Chỉ có thể chuyển sang ""Tệp đính kèm"" sau khi ghi lại dữ liệu.';
			|ru = 'Данные еще не записаны.
			|Переход к ""Документооборот"" возможен только после записи данных.';
			|en = 'The data is not saved.
			|To go to ""Document management"", save the data.'; fa = 'The data is not saved.
			|To go to ""Document management"", save the data.';
			|it = 'Данные еще не записаны.
			|Переход к ""Документооборот"" возможен только после записи данных.';
			|pl = 'The data is not saved.
			|To go to ""Document management"", save the data.';
			|tr = 'Veriler henüz kaydedilmedi.
			|""Belge Yönetimi"" kısmına geçiş sadece verilerin kaydından sonra mümkündür.'");
		ShowMessageBox(, WarningText);
		Cancel = True;
		Return;
	EndIf;
	
	TestConnection();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "IntegrationWith1CDocumentManagement_SuccessfulConnection" And Source <> ThisObject Then
		WhenConnecting();
	EndIf;
	
	If Items.ConnectionPageGroup.CurrentPage <>
			Items.Page1CDocumentManagementIsAvailable Then
		Return;
	EndIf;
	
	If (EventName = "Recording_1CDocumentManagementDocument"
				Or EventName = "Recording_1CDocumentManagementObject")
			And Parameter.Property("ExternalObject")
			And Parameter.ExternalObject = ExternalObject Then
		
		DocumentID = Parameter.ID;
		DocumentType = Parameter.type;
		Document = Parameter.name;
		CompleteDocumentPresentation();
		
		ProcessDocumentEntry();
		
	ElsIf EventName = "Recording_1CDocumentManagementBusinessProcess" Then
		
		DisclosedElements = New ValueList;
		GetDisclosedElements(
			Items.TreeOfBusinessProcessesAndTasks,
			TreeOfBusinessProcessesAndTasks.GetItems(),
			DisclosedElements);
		DisclosedElements.Add(Parameter.ID);
		LoadTreeOfBusinessProcessesAndTasks();
		SetExpansionOfTreeElements(
			Items.TreeOfBusinessProcessesAndTasks,
			TreeOfBusinessProcessesAndTasks,
			DisclosedElements);
		SetCurElementInTree(
			Items.TreeOfBusinessProcessesAndTasks,
			TreeOfBusinessProcessesAndTasks,
			Parameter.ID);
		
	ElsIf EventName = "Recording_1CDocumentManagementFile"
			And TypeOf(Parameter) = Type("Structure")
			And Parameter.Property("ExternalObject")
			And Parameter.ExternalObject = ExternalObject Then
		
		UpdateFileListClient();
		
	ElsIf EventName = "Recording_1CDocumentManagementOutgoingEmail" Then
		
		If Source = ThisObject Then
			GetFillInEmailTree();
			ExpandMessageTree();
		ElsIf ValueIsFilled(Parameter) Then
			If Parameter.SubjectOfID = DocumentID Then
				GetFillInEmailTree();
				ExpandMessageTree();
			ElsIf EmailIsInList(Parameter.EmailBasisID) Then
				GetFillInEmailTree();
				ExpandMessageTree();
			EndIf;
		EndIf;
		
	ElsIf EventName = "DocumentManagement_SelectAValueFromTheListCompletion" And Source = ThisObject Then
		
		If Parameter = "Document" Then
			ProcessSelectionOfRelatedObject();
			IntegrationWith1CDocumentManagementCoreClient.Notify_AddingConnection(
				DocumentID,
				DocumentType,
				Parameters.ExternalObject);
			CompleteDocumentPresentation();
		EndIf;
		
	ElsIf EventName = "DocumentManagement_AddingALink" And Parameter.Object = ExternalObject Then
		
		GetDocumentData();
		UpdateDocumentDecorations();
		FilesAreFull = False;
		DocumentsCompleted = False;
		EmailsFilledIn = False;
		TasksCompleted = False;
		LaborCostsAreFilled = False;
		WhenChangingPageOnClient(Items.GroupPages.CurrentPage);
		
	ElsIf EventName = "DocumentManagement_DeletingALink" And Parameter.Object = ExternalObject Then
		
		Document = "";
		DocumentID = "";
		DocumentType = "";
		FilesAreFull = False;
		DocumentsCompleted = False;
		EmailsFilledIn = False;
		TasksCompleted = False;
		LaborCostsAreFilled = False;
		UpdateDocumentDecorations();
		WhenChangingPageOnClient(Items.GroupPages.CurrentPage);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("ObjectTypeIS", FormattedStringURL);
	
	OpenForm("Catalog.RulesForIntegrationWith1CDocumentManagement.Form.ItemForm",
		FormParameters,
		ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	WhenChangingPageOnClient(CurrentPage);
	
EndProcedure

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
Procedure DecorationObjectCreateClick(Item)
	
	If ValueIsFilled(Document) Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	
	CallbackDescription = New CallbackDescription(
		"DecorationObjectCreateClickCompletion", ThisObject, AdditionalParameters);
	
	IntegrationWith1CDocumentManagementClient.StartCreatingARelatedObjectDM(
		ExternalObject,
		CallbackDescription,
		True);
	
EndProcedure

&AtClient
Procedure SceneryObjectSelectClick(Item)
	
	AdditionalParameters = New Structure;
	
	If ValueIsFilled(TypeOfObjectToCreate) Then
		
		DecorationObjectSelectByClickingAfterSelectingType(TypeOfObjectToCreate, AdditionalParameters);
		
	Else // The type is unknown, we will offer the user a choice.
		
		AdditionalParameters = New Structure;
		CallbackDescription = New CallbackDescription(
			"DecorationObjectSelectByClickingAfterSelectingType", ThisObject, AdditionalParameters);
		
		FormParameters = New Structure;
		FormParameters.Insert("Title", NStr("vi = 'Chọn vào 1C:Document Management';
											|ru = 'Выбрать в 1С:Документообороте';
											|en = 'Select from 1C:Document Management'; fa = 'انتخاب از 1C:Document Management';
											|it = 'Selezionare in 1C:Document Management';
											|pl = 'Wybierz w 1C:Document Management';
											|tr = '1C:Document Management''de seç'"));
		FormParameters.Insert("CommandTitle", NStr("vi = 'Chọn';
													|ru = 'Выбрать';
													|en = 'Select'; fa = 'انتخاب';
													|it = 'Selezionare';
													|pl = 'Select';
													|tr = 'Seç'"));
		FormParameters.Insert("ObjectIS", ExternalObject);
		
		OpenForm(
			"DataProcessor.IntegrationWith1CDocumentManagement.Form.SelectingTypeOfDocumentManagementObject",
			FormParameters,,,,,
			CallbackDescription,
			FormWindowOpeningMode.LockWholeInterface);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationObjectClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("ExternalObject", Parameters.ExternalObject);
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(DocumentType, DocumentID, Item, FormParameters);
	
EndProcedure

&AtClient
Procedure DecorationObjectClearClick(Item)
	
	If Not ValueIsFilled(Document) Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("DecorationObjectClearClickCompletion", ThisObject);
	QueryText = StrTemplate(
		NStr("vi = 'Xóa so sánh đối với
			|%1?';
			|ru = 'Очистить соответствие для
			|%1?';
			|en = 'Clear match for
			|%1?'; fa = 'Clear match for
			|%1?';
			|it = 'Cancellare corrispondenza per
			|%1?';
			|pl = 'Wyczyścić zgodność dla
			|%1?';
			|tr = '
			|%1için uygunluğu temizle?'"),
		String(Parameters.ExternalObject));
	QuestionParametersYesNo = IntegrationWith1CDocumentManagementCoreClient.QuestionParametersYesNo();
	QuestionParametersYesNo.YesButtonText = NStr("vi = 'Xóa';
												|ru = 'Очистить';
												|en = 'Clear'; fa = 'پاک کردن';
												|it = 'Очистить';
												|pl = 'Clear';
												|tr = 'Temizle'");
	QuestionParametersYesNo.NoButtonText = NStr("vi = 'Không xóa';
												|ru = 'Не очищать';
												|en = 'Do not clear'; fa = 'پاک نشود';
												|it = 'Не очищать';
												|pl = 'Nie oczyszczaj';
												|tr = 'Temizlenmesin'");
	QuestionParametersYesNo.DefaultButton = DialogReturnCode.No;
	
	IntegrationWith1CDocumentManagementClient.ShowQuestionYesNo(
		Notification,
		QueryText,
		QuestionParametersYesNo);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTreeOfBusinessProcessesAndTasks

&AtClient
Procedure TreeOfBusinessProcessesAndTasksSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	OpenCurTaskOrProcess();
	
EndProcedure

&AtClient
Procedure TreeOfBusinessProcessesAndTasksBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	OpenCurTaskOrProcess();
	
EndProcedure

&AtClient
Procedure ShowExecutedOnChange(Item)
	
	DisclosedElements = New ValueList;
	GetDisclosedElements(
		Items.TreeOfBusinessProcessesAndTasks,
		TreeOfBusinessProcessesAndTasks.GetItems(),
		DisclosedElements);
	LoadTreeOfBusinessProcessesAndTasks();
	SetExpansionOfTreeElements(
		Items.TreeOfBusinessProcessesAndTasks,
		TreeOfBusinessProcessesAndTasks,
		DisclosedElements);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfFiles

&AtClient
Procedure ListOfFilesOnActivateRow(Item)
	
	UpdateAvailabilityOfFileListCommands();
	
EndProcedure

&AtClient
Procedure ListOfFilesBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	If Items.ListOfFiles.CurrentData = Undefined Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("ListOfFilesBeforeDeleteRowCompletion", ThisObject);
	
	If Items.ListOfFiles.SelectedRows.Count() = 1 Then
		QueryText = StrTemplate(
			NStr("vi = 'Đặt dấu xóa ""%1""?';
				|ru = 'Пометить ""%1"" на удаление?';
				|en = 'Do you want to mark %1 for deletion?'; fa = 'Do you want to mark %1 for deletion?';
				|it = 'Contrassegnare ""%1"" per cancellazione?';
				|pl = 'Zaznaczyć ""%1"" do usunięcia?';
				|tr = '""%1"" silinmek üzere işaretlensin mi?'"),
			Items.ListOfFiles.CurrentData.Description);
	Else
		QueryText = NStr("vi = 'Đánh dấu xóa phần tử đã chọn?';
						|ru = 'Пометить выделенные элементы на удаление?';
						|en = 'Mark the selected items for deletion?'; fa = 'Mark the selected items for deletion?';
						|it = 'Contrassegnare gli elementi selezionati per la cancellazione?';
						|pl = 'Zaznaczyć wybrane elementy do usunięcia?';
						|tr = 'Seçilen öğeler silinmek üzere işaretlensin mi?'");
	EndIf;
	
	IntegrationWith1CDocumentManagementClient.ShowQuestionYesNo(Notification, QueryText);
	
EndProcedure

&AtClient
Procedure ListOfFilesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	OpenFileExecute();
	
EndProcedure

&AtClient
Procedure ListOfFilesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	CreateFileExecute();
	
EndProcedure

&AtClient
Procedure ListOfFilesDragCheck(Item, DragParameters,
	StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure ListOfFilesDrag(Item, DragParameters, StandardProcessing,
	String, Field)
	
	StandardProcessing = False;
	
	If TypeOf(DragParameters.Value) = Type("File")
			And DragParameters.Value.IsFile() = True Then
		
		CreateFileFromDiskByDraggingAndDropping(DragParameters.Value);
		
	ElsIf TypeOf(DragParameters.Value) = Type("Array") Then
		
		For Each ReceivedFile1 In DragParameters.Value Do
			If TypeOf(ReceivedFile1) = Type("File") And ReceivedFile1.IsFile() Then
				CreateFileFromDiskByDraggingAndDropping(ReceivedFile1);
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ListOfFilesBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	OpenFileCardExecute();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersLinkTree

&AtClient
Procedure LinkTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.LinkTree.CurrentData;
	OpenRelatedRowData(CurrentData);
	
EndProcedure

&AtClient
Procedure LinkTreeOnActivateRow(Item)
	
	String = Item.CurrentData;
	
	OpeningAvailability =
		(String <> Undefined)
		And (String.Type <> "DMRelationType");
	AvailabilityOfDeletion = OpeningAvailability
		And (String.Type <> "DMFile");
		
	Items.LinkTreeOpen.Enabled = OpeningAvailability;
	Items.LinkTreeOpenContext.Enabled = OpeningAvailability;
	Items.LinkTreeDelete.Enabled = AvailabilityOfDeletion;
	Items.LinkTreeDeleteContext.Enabled = OpeningAvailability;
	
EndProcedure

&AtClient
Procedure LinkTreeBeforeAddRow(Item, Cancel, Copy, Parent,
	Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure LinkTreeBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure LinkTreeBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	CurrentData = Items.LinkTree.CurrentData;
	If CurrentData = Undefined
		Or CurrentData.Type = "DMRelationType"
		Or CurrentData.Type = "DMFile" Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription(
		"StartDeletingLinkCompletion", ThisObject);
	
	LinkTypeString_ = CurrentData.GetParent();
	
	SourceDocument_ = New Structure("ID, Type, Presentation",
		DocumentID, DocumentType, Document);
	LinkedDocument = New Structure("ID, Type, Presentation",
		CurrentData.ID, CurrentData.Type, CurrentData.Title);
	LinkType = New Structure("ID, Type, Presentation",
		LinkTypeString_.ID, LinkTypeString_.Type, LinkTypeString_.Title);
	
	IntegrationWith1CDocumentManagementClient.StartDeletingLink(
		SourceDocument_,
		LinkedDocument,
		LinkType,
		CallbackDescription);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCorrespondenceHistory

&AtClient
Procedure MessageTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentRow = MessageTree.FindByID(RowSelected);
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(
		CurrentRow.MailMessageType,
		CurrentRow.MailMessageID,
		ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure VisaApprovalsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	IntegrationWith1CDocumentManagementClient.OpenVisa(ThisObject,
		Items.VisaApprovals.CurrentData);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Processes and tasks

&AtClient
Procedure OpenTaskProcessCard(Command)
	
	OpenCurTaskOrProcess();
	
EndProcedure

&AtClient
Procedure CreateBusinessProcess(Command)
	
	IntegrationWith1CDocumentManagementClient.CreateABusinessProcessByTheObjectDM(
		DocumentID,
		DocumentType,
		Document,
		ExternalObject);
	
EndProcedure

&AtClient
Procedure UpdateListOfBusinessProcessesAndTasks(Command)
	
	DisclosedElements = New ValueList;
	GetDisclosedElements(
		Items.TreeOfBusinessProcessesAndTasks,
		TreeOfBusinessProcessesAndTasks.GetItems(),
		DisclosedElements);
	LoadTreeOfBusinessProcessesAndTasks();
	SetExpansionOfTreeElements(
		Items.TreeOfBusinessProcessesAndTasks,
		TreeOfBusinessProcessesAndTasks,
		DisclosedElements);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Files

&AtClient
Procedure OpenFile(Command)
	
	OpenFileExecute();
	
EndProcedure

&AtClient
Procedure CreateFile(Command)
	
	CreateFileExecute();
	
EndProcedure

&AtClient
Procedure SaveAs(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.StartSavingSelectedFiles(
		ListOfFiles,
		Items.ListOfFiles.SelectedRows,
		UUID);
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	UpdateFileListClient();
	
EndProcedure

&AtClient
Procedure UpdateFromFileOnHardDrive(Command)
	
	CurrentData = Items.ListOfFiles.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription(
		"UpdateFromFileOnHardDriveCompletion", ThisObject);
	
	IntegrationWith1CDocumentManagementCoreClient.UpdateFromFileOnHardDrive(
		CurrentData.ID,
		CurrentData.Description,
		CurrentData.Extension,
		ToLocalTime(CurrentData.UniversalModificationDate),
		UUID,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure Sign(Command)
	
	CurrentData = Items.ListOfFiles.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FileProperties = IntegrationWith1CDocumentManagementCoreClientServer.FileProperties();
	FileProperties.FileID = CurrentData.ID;
	FileProperties.FileName = CurrentData.Description;
	FileProperties.FileOwner = DocumentID;
	FileProperties.IsBeingEdited = CurrentData.IsBeingEdited;
	FileProperties.Encrypted = CurrentData.Encrypted;
	FileProperties.FileDetails = CurrentData.LongDesc;
	FileProperties.FormUniqueID = UUID;
	FileProperties.FileSignatureData =
		IntegrationWith1CDocumentManagementCoreClient.DataOfSignatures(CurrentData.SignatureTable);
	
	IntegrationWith1CDocumentManagementCoreClient.SignFile(FileProperties);
	
EndProcedure

&AtClient
Procedure AddDSFromFile(Command)
	
	CurrentData = Items.ListOfFiles.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FileSignatureData = IntegrationWith1CDocumentManagementCoreClient.DataOfSignatures(
		CurrentData.SignatureTable);
	
	FileProperties = IntegrationWith1CDocumentManagementCoreClientServer.FileProperties();
	FileProperties.FileID = CurrentData.ID;
	FileProperties.FileName = CurrentData.Description;
	FileProperties.FileDetails = CurrentData.LongDesc;
	FileProperties.IsBeingEdited = CurrentData.IsBeingEdited;
	FileProperties.Encrypted = CurrentData.Encrypted;
	FileProperties.FileSignatureData = FileSignatureData;
	FileProperties.FormUniqueID = UUID;
	FileProperties.FileOwner = DocumentID;
	
	IntegrationWith1CDocumentManagementCoreClient.StartAddingItemsFromFile(FileProperties);
	
EndProcedure

&AtClient
Procedure SaveWithDigitalSignature(Command)
	
	CurrentData = Items.ListOfFiles.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.StartSavingTogetherBOT(
		CurrentData.ID,
		CurrentData.Extension,
		CurrentData.Description,
		CurrentData.Size * 1024,
		CurrentData.UniversalModificationDate,
		UUID);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Links

// Starts adding the linked document.
&AtClient
Procedure AddLink(Command)
	
	Filter = New Structure;
	If ValueIsFilled(CounterpartyID) Then
		Condition = New Structure;
		Condition.Insert("Value", Counterparty);
		Condition.Insert("ValueID", CounterpartyID);
		Filter.Insert("correspondent", Condition);
	EndIf;
	If ValueIsFilled(OrganizationID) Then
		Condition = New Structure;
		Condition.Insert("Value", Organization);
		Condition.Insert("ValueID", OrganizationID);
		Filter.Insert("organization", Condition);
	EndIf;
	
	CallbackDescription = New CallbackDescription(
		"StartAddingLinkCompletion", ThisObject);
	IntegrationWith1CDocumentManagementClient.StartAddingLink(
		DocumentID, DocumentType, Document,, CallbackDescription, Filter);
	
EndProcedure

&AtClient
Procedure OpenRelatedData(Command)
	
	String = Items.LinkTree.CurrentData;
	If String <> Undefined Then
		OpenRelatedRowData(String);
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// History of correspondence

&AtClient
Procedure UpdateEmails(Command)
	
	GetFillInEmailTree();
	ExpandMessageTree();
	
EndProcedure

&AtClient
Procedure OpenEmail(Command)
	
	CurrentData = Items.MessageTree.CurrentData;
	If CurrentData <> Undefined Then
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(
			CurrentData.MailMessageType,
			CurrentData.MailMessageID,
			ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateEmail(Command)
	
	FormParameters = New Structure("SubjectOf", New Structure);
	FormParameters.SubjectOf.Insert("name", Document);
	FormParameters.SubjectOf.Insert("ID", DocumentID);
	FormParameters.SubjectOf.Insert("type", DocumentType);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.Outgoing_Email", FormParameters);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// LaborCosts

&AtClient
Procedure UpdateLaborCosts(Command)
	
	FillInTheLaborCosts();
	
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
		WhenChangingPageOnClient(Items.GroupPages.CurrentPage);
		If Not DocumentsCompleted Then
			UpdateRelationshipTree();
			DocumentsCompleted = True;
			If ValueIsFilled(AddressForLinkedDocumentFiles) Then
				AttachIdleHandler("UpdatingRelatedDocumentFiles", 1, True);
			EndIf;
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
			Items.GroupDocument.Visible = False;
			Items.GroupIndent.Visible = False;
			Items.InfoGroup.Visible = False;
			
		Else
			
			Items.FunctionalityGroupIsNotSupported.Visible = False;
			Items.GroupDocument.Visible = True;
			Items.GroupIndent.Visible = True;
			Items.InfoGroup.Visible = Not ValueIsFilled(PresentationOfObjectBeingCreated)
				And Not ValueIsFilled(TypeOfObjectToCreate);
			
			MailFunctionalityIsAvailable = IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("1.2.8.1.CORP");
			CounterpartiesFunctionalityIsAvailable = IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("1.3.2.3");
			SubfoldersFunctionalityIsAvailable = IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("1.2.7.3");
			TaskFunctionalityIsAvailable = IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("1.2.6.2");
			VisaFunctionalityIsAvailable = IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("2.0.5.4");
			ResolutionFunctionalityIsAvailable = IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("2.0.5.4");
			TimekeepingFunctionalityIsAvailable = IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP");
			
			// The results of the tasks.
			If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3") Then
				Items.TreeOfBusinessProcessesAndTasksCompleted2.Visible = True;
				Items.TreeOfBusinessProcessesAndTasksPicture.Visible = False;
			EndIf;
			Items.LaborCostsGroup.Visible = TimekeepingFunctionalityIsAvailable;
			Items.GroupHistoryOfCorrespondence.Visible = MailFunctionalityIsAvailable;
			Items.ShowExecuted.Visible = TaskFunctionalityIsAvailable;
			
			GetDocumentData();
			
			UseFileStorage1CDocumentManagement =
				Constants.UseFileStorage1CDocumentManagement.Get();
			UseProcessesAndTasks1CDocumentManagement =
				Constants.UseProcessesAndTasks1CDocumentManagement.Get();
			UseRelatedDocuments1CDocumentManagement = (DocumentType <> "DMCorrespondent")
				And Constants.UseRelatedDocuments1CDocumentManagement.Get();
			UseEmail1CDocumentManagement =
				Constants.UseEmail1CDocumentManagement.Get();
			UseDailyReports1CDocumentManagement = (DocumentType <> "DMCorrespondent")
				And Constants.UseDailyReports1CDocumentManagement.Get();
			
			// The saved bookmark may be irrelevant.
			If ValueIsFilled(CurBookmark) Then
				If Items.Find(CurBookmark) = Undefined Then
					CurBookmark = "";
					
				ElsIf CurBookmark = "GroupFiles" And Not UseFileStorage1CDocumentManagement Then
					CurBookmark = "";
					
				ElsIf CurBookmark = "TaskGroup_2" And Not UseProcessesAndTasks1CDocumentManagement Then
					CurBookmark = "";
					
				ElsIf CurBookmark = "GroupRelatedDocuments"
						And Not UseRelatedDocuments1CDocumentManagement Then
					CurBookmark = "";
					
				ElsIf CurBookmark = "GroupHistoryOfCorrespondence"
						And (Not UseEmail1CDocumentManagement
							Or Not MailFunctionalityIsAvailable) Then
					CurBookmark = "";
					
				ElsIf CurBookmark = "LaborCostsGroup"
						And (Not UseDailyReports1CDocumentManagement
							Or Not TimekeepingFunctionalityIsAvailable) Then
					CurBookmark = "";
					
				ElsIf Not Items[CurBookmark].Visible Then
					CurBookmark = "";
				EndIf;
			EndIf;
			
			If CurBookmark = "" Then
				CurBookmark = Items.GroupPages.CurrentPage.Name;
			Else
				Items.GroupPages.CurrentPage = Items[CurBookmark];
			EndIf;
			
			UpdateDocumentDecorations();
			
		EndIf;
		
	Except
		
		If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(ErrorInfo()) Then
			ProcessFormAccordingToServiceVersion();
		EndIf;
		
	EndTry;
	
	Return FormProcessedSuccessfully;
	
EndFunction

&AtClient
Procedure WhenChangingPageOnClient(CurrentPage)
	
	If CurrentPage = Items.GroupFiles And Items.GroupFiles.Visible Then
		
		If Not FilesAreFull Then
			FillInFileData();
			FilesAreFull = True;
		EndIf;
		
	ElsIf CurrentPage = Items.TaskGroup_2 And Items.TaskGroup_2.Visible Then
		
		If Not TasksCompleted Then
			LoadTreeOfBusinessProcessesAndTasks();
			TasksCompleted = True;
		EndIf;
		
	ElsIf CurrentPage = Items.GroupRelatedDocuments And Items.GroupRelatedDocuments.Visible Then
		
		If Not DocumentsCompleted Then
			UpdateRelationshipTree();
			DocumentsCompleted = True;
			If ValueIsFilled(AddressForLinkedDocumentFiles) Then
				AttachIdleHandler("UpdatingRelatedDocumentFiles", 1, True);
			EndIf;
		EndIf;
		
	ElsIf CurrentPage = Items.GroupHistoryOfCorrespondence And Items.GroupHistoryOfCorrespondence.Visible Then
		
		If Not EmailsFilledIn Then
			GetFillInEmailTree();
			ExpandMessageTree();
			EmailsFilledIn = True;
		EndIf;
		
	ElsIf CurrentPage = Items.LaborCostsGroup And Items.LaborCostsGroup.Visible Then
		
		If Not LaborCostsAreFilled Then
			FillInTheLaborCosts();
			LaborCostsAreFilled = True;
		EndIf;
		
	EndIf;
	
	CurBookmark = CurrentPage.Name;
	
	CompleteDocumentPresentation();
	
EndProcedure

&AtServer
Procedure FillInDataOfCurPageOnServer(CurrentPage)
	
	If CurrentPage = Items.GroupFiles And Items.GroupFiles.Visible Then
		
		If Not FilesAreFull Then
			FillInFileData();
			FilesAreFull = True;
		EndIf;
		
	ElsIf CurrentPage = Items.TaskGroup_2 And Items.TaskGroup_2.Visible Then
		
		If Not TasksCompleted Then
			LoadTreeOfBusinessProcessesAndTasks();
			TasksCompleted = True;
		EndIf;
		
	ElsIf CurrentPage = Items.GroupRelatedDocuments And Items.GroupRelatedDocuments.Visible Then
		
		If Not DocumentsCompleted Then
			UpdateRelationshipTree();
			DocumentsCompleted = True;
		EndIf;
		
	ElsIf CurrentPage = Items.GroupHistoryOfCorrespondence And Items.GroupHistoryOfCorrespondence.Visible Then
		
		If Not EmailsFilledIn Then
			GetFillInEmailTree();
			EmailsFilledIn = True;
		EndIf;
		
	ElsIf CurrentPage = Items.LaborCostsGroup And Items.LaborCostsGroup.Visible Then
		
		If Not LaborCostsAreFilled Then
			FillInTheLaborCosts();
			LaborCostsAreFilled = True;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationObjectCreateClickCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationObjectClearClickCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	SavedID = DocumentID;
	SavedType = DocumentType;
	DeleteConnectionOnServer();
	
	IntegrationWith1CDocumentManagementCoreClient.Notify_RemovingLink(
		SavedID,
		SavedType,
		ExternalObject);
	
EndProcedure

&AtClient
Procedure DecorationObjectSelectByClickingAfterSelectingType(Result, AdditionalParameters) Export
	
	If TypeOf(Result) <> Type("String")
		Or Result = "" Then
		Return;
	EndIf;
	
	Filter = IntegrationWith1CDocumentManagementCoreClient.SelectionWhenSelectingLinkedObject(
		ExternalObject,
		Result);
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheList(
		Result,
		"Document",
		ThisObject,
		Filter);
	
EndProcedure

&AtServer
Procedure ProcessSelectionOfRelatedObject()
	
	If ValueIsFilled(DocumentID) And ValueIsFilled(DocumentType) Then // Adding a new connection.
		IntegrationWith1CDocumentManagementCoreServerCall.AddLink(
			DocumentID,
			DocumentType,
			Parameters.ExternalObject);
	EndIf;
	
	GetDocumentData();
	
	CurrentPage = Items.GroupPages.CurrentPage;
	
	FilesAreFull = False;
	TasksCompleted = False;
	DocumentsCompleted = False;
	EmailsFilledIn = False;
	LaborCostsAreFilled = False;
	
	FillInDataOfCurPageOnServer(CurrentPage);
	
EndProcedure

&AtServer
Procedure ProcessDocumentEntry()
	
	UpdateDocumentDecorations();
	If UseProcessesAndTasks1CDocumentManagement Then
		LoadTreeOfBusinessProcessesAndTasks();
	EndIf;
	If UseRelatedDocuments1CDocumentManagement Then
		UpdateRelationshipTree();
	EndIf;
	If ValueIsFilled(DocumentID) Then
		InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.AddLink(
			DocumentID,
			DocumentType,
			ExternalObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure DeleteConnectionOnServer()
	
	IntegrationWith1CDocumentManagementCoreServerCall.DeleteLink(
		DocumentID,
		DocumentType,
		Parameters.ExternalObject);
	
	CurrentPage = Items.GroupPages.CurrentPage;
	
	DocumentID = "";
	DocumentType = "";
	Document = "";
	
	Items.VisaGroup.Visible = False;
	Items.ResolutionGroup.Visible = False;
	
	UpdateDocumentDecorations();
	
	FilesAreFull = False;
	TasksCompleted = False;
	DocumentsCompleted = False;
	EmailsFilledIn = False;
	LaborCostsAreFilled = False;
	
	FillInDataOfCurPageOnServer(CurrentPage);
	
EndProcedure

&AtServer
Procedure UpdateDocumentDecorations()
	
	DocumentFilledIn_ = ValueIsFilled(DocumentID);
	
	Items.DecorationObjectCreate.Visible = Not DocumentFilledIn_;
	Items.DecorationObjectOr.Visible = Not DocumentFilledIn_;
	Items.SceneryObjectSelect.Visible = Not DocumentFilledIn_;
	
	Items.DecorationObject.Visible = DocumentFilledIn_;
	Items.DecorationObjectClear.Visible = DocumentFilledIn_;
	Items.TreeOfBusinessProcessesAndTasks.Enabled = DocumentFilledIn_;
	
	Items.LinkTreeAdd.Enabled = DocumentFilledIn_;
	Items.LinkTreeOpen.Enabled =  DocumentFilledIn_;
	Items.LinkTreeDelete.Enabled =  DocumentFilledIn_;
	
	Items.LinkTreeAddContext.Enabled = DocumentFilledIn_;
	Items.LinkTreeOpenContext.Enabled =  DocumentFilledIn_;
	Items.LinkTreeDeleteContext.Enabled =  DocumentFilledIn_;
	
	Items.MessageTreeCreateEmail.Enabled = DocumentFilledIn_;
	Items.MessageTreeOpenEmail.Enabled = DocumentFilledIn_;
	Items.MessageTreeUpdateEmails.Enabled = DocumentFilledIn_;
	
	Items.WorksRefresh.Enabled = DocumentFilledIn_;
	
	If DocumentType = "DMCorrespondent" Then
		Items.GroupRelatedDocuments.Visible = False;
		Items.LaborCostsGroup.Visible = False;
		Items.MessageTreeNumber.Visible = True;
		Items.MessageTreeRecipients.Visible = False;
		Items.MessageTreeMailMessage.Title = NStr("vi = 'Chứng từ';
													|ru = 'Документ';
													|en = 'Document'; fa = 'سند';
													|it = 'Documento';
													|pl = 'Dokument';
													|tr = 'Belge'");
	Else
		Items.GroupRelatedDocuments.Visible = True;
		// Timing.
		Items.LaborCostsGroup.Visible =
			IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP");
		Items.MessageTreeNumber.Visible = False;
		Items.MessageTreeRecipients.Visible = True;
		Items.MessageTreeMailMessage.Title = NStr("vi = 'E-mail';
													|ru = 'Письмо';
													|en = 'Email'; fa = 'ایمیل';
													|it = 'Mail';
													|pl = 'Email';
													|tr = 'E-posta'");
	EndIf;
	
	Modified = False;

EndProcedure

&AtServer
Procedure GetDocumentData()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetDocumentListRequest");
	
	ListOfExternalObjects = Query.externalObjects; // XDTOList
	ListOfExternalObjects.Add(
		IntegrationWith1CDocumentManagementCore.CreateExternalObject(Proxy, ExternalObject));
	
	FieldsReceived = Query.columnSet; // XDTOList
	FieldsReceived.Add("name");
	If VisaFunctionalityIsAvailable Then
		FieldsReceived.Add("visas");
	EndIf;
	If ResolutionFunctionalityIsAvailable Then
		FieldsReceived.Add("resolutions");
	EndIf;
	
	Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, Result, "DMError") Then
		Raise Result.description;
	EndIf;
		
	XDTODataObject = Undefined;
	If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, Result, "DMGetObjectListResponse") Then
		If Result.items.Count() > 0 Then
			XDTODataObject = Result.items[0].object;
		EndIf;
	Else // Compatibility with older versions of the service.
		If Result.documents.Count() > 0 Then
			XDTODataObject = Result.documents[0];
		EndIf;
	EndIf;
		
	If XDTODataObject = Undefined Then
		Items.ResolutionGroup.Visible = False;
		Items.VisaGroup.Visible = False;
	Else
		// Fill in the basic details.
		DocumentID = XDTODataObject.objectID.ID;
		DocumentType = XDTODataObject.objectID.type;
		Document = XDTODataObject.name;
		// We will process the resolutions.
		If XDTODataObject.Properties().Get("resolutions") <> Undefined
			And XDTODataObject.resolutions.Count() <> 0 Then
			IntegrationWith1CDocumentManagement.UpdateResolutionsPresentation(
				XDTODataObject.resolutions,
				HTMLPresentationResolutions,
				Items.ResolutionGroup);
			Items.ResolutionGroup.Visible = True;
		Else
			Items.ResolutionGroup.Visible = False;
		EndIf;
		// We will process the visas.
		If XDTODataObject.Properties().Get("visas") <> Undefined
			And XDTODataObject.visas.Count() <> 0 Then
			IntegrationWith1CDocumentManagement.UpdateVisaApprovals(
				XDTODataObject.visas,
				VisaApprovals,
				Items.VisaGroup);
			Items.VisaGroup.Visible = True;
		Else
			Items.VisaGroup.Visible = False;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CompleteDocumentPresentation()
	
	If ValueIsFilled(Document) Then
		
		ObjectTypePresentationBefore = IntegrationWith1CDocumentManagementClientServer.ObjectTypePresentationXDTO(
			DocumentType);
		Items.DecorationObjectTitle.Title = StrTemplate("%1:", ObjectTypePresentationBefore);
		
		Items.PageGroupLinkedObject.CurrentPage = Items.PageGroupIsRelatedObject;
		
	Else
		// There is no associated object.
		If ValueIsFilled(PresentationOfObjectBeingCreated) Then
			Items.DecorationObjectTitle.Title = StrTemplate("%1:", PresentationOfObjectBeingCreated);
			
		ElsIf ValueIsFilled(TypeOfObjectToCreate) Then
			Items.DecorationObjectTitle.Title = StrTemplate("%1:",
				IntegrationWith1CDocumentManagementClientServer.ObjectTypePresentationXDTO(TypeOfObjectToCreate));
			
		Else
			// There are no suitable rules.
			Items.DecorationObjectTitle.Title = NStr("vi = 'So sánh trong 1C:Document Management:';
													|ru = 'Соответствие в 1С:Документообороте:';
													|en = 'Correspondence in 1C:Document Management:'; fa = 'مکاتبات در 1C:Document Management:';
													|it = 'Corrispondenza in 1C:Document Management:';
													|pl = 'Zgodność w 1C:Document Management:';
													|tr = '1C:Document Management''te uygunluk:'");
			
		EndIf;
		
		Items.PageGroupLinkedObject.CurrentPage = Items.GroupPageNoAssociatedObject;
		
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Processes and tasks

&AtServer
Procedure EstablishConditionalAppearanceOfProcessesAndTasks()
	
	If ConditionalAppearance.Items.Count() = 3 Then
		ItemForDelete = ConditionalAppearance.Items[2];
		ConditionalAppearance.Items.Delete(ItemForDelete);
	EndIf;
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	Filters = ConditionalAppearanceItem.Filter.Items;
	
	DataFilterItem = Filters.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue =
		New DataCompositionField("TreeOfBusinessProcessesAndTasks.TaskDueDate");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Filled;
	DataFilterItem.Use = True;
	
	DataFilterItem = Filters.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue =
		New DataCompositionField("TreeOfBusinessProcessesAndTasks.Completed2");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use = True;
	
	DataFilterItem = Filters.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue =
		New DataCompositionField("TreeOfBusinessProcessesAndTasks.TaskDueDate");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Less;
	DataFilterItem.RightValue = CurrentSessionDate();
	DataFilterItem.Use = True;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("TreeOfBusinessProcessesAndTasksDescription");
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("TreeOfBusinessProcessesAndTasksTaskDueDate");
		
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.OverdueDataColor.Value;
	AppearanceColorItem.Use = True;
	
EndProcedure

&AtServer
Procedure BuildTaskTreeFromWebServiceResponse(TaskTreeRows, ResponseLines)
	
	TaskResultsFunctionalityIsAvailable =
		IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3");
		
	For Each OneResponseString In ResponseLines Do
		
		Importance = 1;
		If OneResponseString.importance.objectID.ID = "Низкая" Then //@NON-NLS-1
			Importance = 0;
		ElsIf OneResponseString.importance.objectID.ID = "Обычная" Then //@NON-NLS-1
			Importance = 1;
		ElsIf OneResponseString.importance.objectID.ID = "Высокая" Then //@NON-NLS-1
			Importance = 2;
		EndIf;
		
		If Find(OneResponseString.objectID.type, "BusinessProcess") > 0
			And Find(OneResponseString.objectID.type, "Task") = 0 Then
			
			NewRow = TaskTreeRows.Add();
			NewRow.Importance = Importance;
			NewRow.Completed2 = ValueIsFilled(OneResponseString.endDate);
			NewRow.Description = OneResponseString.name;
			NewRow.StartDate = OneResponseString.beginDate;
			NewRow.Author = OneResponseString.author.name;
			NewRow.Type = 0;
			NewRow.DMType = OneResponseString.objectID.type;
			NewRow.DMID = OneResponseString.objectID.ID;
			
			If TaskResultsFunctionalityIsAvailable Then
				NewRow.Picture = IntegrationWith1CDocumentManagement.IndexOfCompletionTagImage(
					OneResponseString.completionMark);
			EndIf;
				
			BuildTaskTreeFromWebServiceResponse(NewRow.Rows, OneResponseString.tasks);
			
		ElsIf Find(OneResponseString.objectID.type, "Task") > 0 Then
			
			If ThisIsServiceTask(OneResponseString) Then
				
				BuildTaskTreeFromWebServiceResponse(TaskTreeRows, OneResponseString.businessProcesses);
				
			Else
				
				NewRow = TaskTreeRows.Add();
				NewRow.Importance = Importance;
				NewRow.Completed2 = OneResponseString.executed;
				NewRow.Description = OneResponseString.name;
				NewRow.TaskDueDate = OneResponseString.dueDate;
				NewRow.StartDate = OneResponseString.beginDate;
				
				If OneResponseString.performer.IsSet("user") Then
					NewRow.Performer = OneResponseString.performer.user.name;
				ElsIf OneResponseString.performer.IsSet("role") Then
					NewRow.Performer = OneResponseString.performer.role.name;
					If OneResponseString.performer.IsSet("mainAddressingObject") Then
						NewRow.Performer = NewRow.Performer + ", "
							+ OneResponseString.performer.mainAddressingObject.name;
					EndIf;
					If OneResponseString.Performer.IsSet("secondaryAddressingObject") Then
						NewRow.Performer = NewRow.Performer + ", "
							+ OneResponseString.performer.secondaryAddressingObject.name;
					EndIf;
				EndIf;
				
				NewRow.Type = 1;
				NewRow.DMType = OneResponseString.objectID.type;
				NewRow.DMID = OneResponseString.objectID.ID;
				NewRow.RoutePoint = OneResponseString.businessProcessStep;
				
				If TaskResultsFunctionalityIsAvailable Then
					NewRow.Picture = IntegrationWith1CDocumentManagement.IndexOfCompletionTagImage(
						OneResponseString.executionMark);
					EndIf;
					
				BuildTaskTreeFromWebServiceResponse(NewRow.Rows, OneResponseString.businessProcesses);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure OpenCurTaskOrProcess()
	
	CurrentData = Items.TreeOfBusinessProcessesAndTasks.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ObjectID = CurrentData.DMID;
	ObjectType = CurrentData.DMType;
	
	If Find(CurrentData.DMType, "Task") > 0 Then
		
		FormParameters = New Structure("ID, type", ObjectID, ObjectType);
		If TaskFunctionalityIsAvailable Then
			Var_FormName = "DataProcessor.IntegrationWith1CDocumentManagement.Form.Task";
		Else
			Var_FormName = "DataProcessor.IntegrationWith1CDocumentManagement.Form.TaskCard";
		EndIf;
		OpenForm(Var_FormName, FormParameters, Items.TreeOfBusinessProcessesAndTasks, ObjectID);
		
	Else
		
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(
			ObjectType,
			ObjectID,
			Items.TreeOfBusinessProcessesAndTasks);
			
	EndIf;
	
EndProcedure

&AtServer
Procedure LoadTreeOfBusinessProcessesAndTasks()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetTasksTreeRequest");
	
	Query.query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetTasksTreeQuery");
	
	ListOfExternalObjects = Query.query.externalTarget; // XDTOList
	ListOfExternalObjects.Add(
		IntegrationWith1CDocumentManagementCore.CreateExternalObject(Proxy, ExternalObject));
	
	If Query.query.Properties().Get("withExecuted") <> Undefined Then
		Query.query.withExecuted = ShowExecuted;
	EndIf;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
	TasksTree = FormAttributeToValue("TreeOfBusinessProcessesAndTasks", Type("ValueTree"));
	TasksTree.Rows.Clear();
	BuildTaskTreeFromWebServiceResponse(TasksTree.Rows, Response.businessProcesses);
	ValueToFormAttribute(TasksTree, "TreeOfBusinessProcessesAndTasks");
	EstablishConditionalAppearanceOfProcessesAndTasks();
	
EndProcedure

&AtClient
Procedure GetDisclosedElements(TreeElement, ArrayOfStringsOfSameLevel, ListOfDisclosedElements)
	
	For Each SingleLevelString In ArrayOfStringsOfSameLevel Do
		ElementID = SingleLevelString.GetID();
		If TreeElement.Expanded(ElementID) <> Undefined And TreeElement.Expanded(ElementID) Then
			ListOfDisclosedElements.Add(SingleLevelString.DMID);
		EndIf;
		GetDisclosedElements(
			TreeElement,
			SingleLevelString.GetItems(),
			ListOfDisclosedElements);
	EndDo;
	
EndProcedure

&AtClient
Procedure SetExpansionOfTreeElements(TreeElement, TreeProps,
		ListOfItemsToDeploy)
	
	If ListOfItemsToDeploy <> Undefined Then
		For Each ListItem In ListOfItemsToDeploy Do
			IndexOf = -1;
			FindElementInTree(
				TreeOfBusinessProcessesAndTasks.GetItems(),
				ListItem.Value,
				IndexOf);
			If IndexOf > -1 Then
				If TreeProps.FindByID(IndexOf).GetItems().Count() > 0 Then
					TreeElement.Expand(
						TreeOfBusinessProcessesAndTasks.FindByID(IndexOf).GetID(),
						False);
				Else
					If TreeProps.FindByID(IndexOf).GetParent() <> Undefined Then
						Parent = TreeOfBusinessProcessesAndTasks.FindByID(IndexOf).GetParent();
						TreeElement.Expand(Parent.GetID(), False);
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure FindElementInTree(CollectionOfElementsOfSameLevel, DesiredElement, IndexOf)
	
	If CollectionOfElementsOfSameLevel.Count() > 0 Then
		For Each TreeItem In CollectionOfElementsOfSameLevel Do
			If TreeItem.DMID = DesiredElement Then
				IndexOf = TreeItem.GetID();
			Else
				FindElementInTree(TreeItem.GetItems(), DesiredElement, IndexOf);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetCurElementInTree(TreeElement, TreeProps, Var_CurrentItem)
	
	If Var_CurrentItem <> Undefined Then
		IndexOf = -1;
		FindElementInTree(TreeProps.GetItems(), Var_CurrentItem, IndexOf);
		If IndexOf > -1 Then
			TreeElement.CurrentRow = IndexOf;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function ThisIsServiceTask(Task)
	
	Service_ = False;
	
	If Task.parentBusinessProcess.objectID.type = "DMComplexBusinessProcess" Then
		If Task.businessProcessStep = "Выполнить все действия процесса" Then //@NON-NLS-1
			Service_ = True;
		EndIf;
	ElsIf Task.parentBusinessProcess.objectID.type = "DMBusinessProcessInternalDocumentProcessing"
			Or Task.parentBusinessProcess.objectID.type = "DMBusinessProcessIncomingDocumentProcessing"
			Or Task.parentBusinessProcess.objectID.type = "DMBusinessProcessOutgoingDocumentProcessing" Then
		Service_ = True;
	EndIf;
	
	Return Service_;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////////////////////////
// Files

&AtClient
Procedure ListOfFilesBeforeDeleteRowCompletion(Response, NotificationParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		MarkToDelete(Items.ListOfFiles.SelectedRows);
		UpdateFileListClient();
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateFileList()
	
	ListOfFiles.Clear();
	
	Files = IntegrationWith1CDocumentManagement.FilesByObjectConsumer(
		ExternalObject.UUID(),
		String(ExternalObject),
		ExternalObject.Metadata().FullName());
	
	For Each FileInfo1 In Files.files Do
		NewRow = ListOfFiles.Add();
		
		NewRow.Description = FileInfo1.name;
		NewRow.Extension = FileInfo1.extension;
		NewRow.LongDesc = FileInfo1.description;
		NewRow.Size = Round(FileInfo1.size/1024, 0);
		NewRow.SignedWithDS = FileInfo1.signed;
		NewRow.Author = FileInfo1.author.name;
		NewRow.ID = FileInfo1.objectID.ID;
		NewRow.CreationDate = FileInfo1.creationDate;
		NewRow.UniversalModificationDate = FileInfo1.modificationDateUniversal;
		
		DeletionMark = False;
		If IntegrationWith1CDocumentManagementCore.PropertySet(FileInfo1, "deletionMark") Then
			DeletionMark = FileInfo1.deletionMark;
		EndIf;
		NewRow.PictureIndex =
			IntegrationWith1CDocumentManagementCore.IndexOfFileIcon(
				NewRow.Extension,
				DeletionMark);
		
		For Each XDTOSignature In FileInfo1.signatures Do
			Signature = NewRow.SignatureTable.Add();
			
			Signature.CertificateOwner = XDTOSignature.author;
			Signature.SignatureDate = XDTOSignature.date;
			Signature.Comment = XDTOSignature.comment;
			Signature.Thumbprint = XDTOSignature.thumbprint;
			
			BinaryData = XDTOSignature.signature;
			Signature.SignatureAddress = PutToTempStorage(BinaryData, UUID);
			
			CertificateBinaryData = XDTOSignature.certificate;
			If CertificateBinaryData <> Undefined Then
				Signature.CertificateAddress = PutToTempStorage(
					CertificateBinaryData, UUID);
			EndIf;
			
			Signature.SignatureFileName = XDTOSignature.signatureFileName;
			Signature.SignatureSetBy = XDTOSignature.signer.name;
			Signature.SignatureSetByID = XDTOSignature.signer.objectID.ID;
		EndDo;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure UpdateFileListClient(FileID = Undefined)
	
	If FileID <> Undefined Then
		CurFileId = FileID;
	ElsIf Items.ListOfFiles.CurrentData <> Undefined Then
		CurFileId = Items.ListOfFiles.CurrentData.ID;
	EndIf;
	
	UpdateFileList();
	
	// let's restore the position in the list
	For Each String In ListOfFiles Do
		If String.ID = CurFileId Then
			Items.ListOfFiles.CurrentRow = String.GetID();
			Break;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure OpenFileCardExecute()
	
	CurrentData = Items.ListOfFiles.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.OpenObject("DMFile", CurrentData.ID);
	
EndProcedure

&AtClient
Procedure OpenFileExecute()
	
	CurrentData = Items.ListOfFiles.CurrentData;
	If CurrentData <> Undefined Then
		IntegrationWith1CDocumentManagementCoreClient.OpenFile(
			CurrentData.ID,
			CurrentData.Description,
			CurrentData.Extension,
			UUID);
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateFileExecute()
	
	OpeningParameters = New Structure("CreateMode", 1);
	
	Notification = New CallbackDescription("CreateFileExecuteCompletion", ThisObject);
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.CreatingNewFile",
		OpeningParameters,,,,,
		Notification,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CreateFileExecuteCompletion(Result, NotificationParameters) Export
	
	If (TypeOf(Result) = Type("DialogReturnCode")) Or (Result = Undefined) Then
		Return;
	EndIf;
	
	If Result = 1 Then
		CreateFileFromDisk();
		
	ElsIf Result = 2 Then
		SelectAnExistingFileIn1CDocumentManagement(Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateFromFileOnHardDriveCompletion(Result, NotificationParameters) Export
	
	UpdateFileListClient();
	
EndProcedure

&AtServer
Function GetIdentifierOf1CDocumentManagementRootFilesFolder()
	
	SetPrivilegedMode(True);
	IdentifierOf1CDocumentManagementRootFilesFolder =
		Constants.IdentifierOf1CDocumentManagementRootFilesFolder.Get();
	
	Return IdentifierOf1CDocumentManagementRootFilesFolder;
	
EndFunction

&AtClient
Procedure SelectAnExistingFileIn1CDocumentManagement(Result)
	
	Notification = New CallbackDescription(
		"SelectAnExistingFileIn1CDocumentManagementCompletion",
		ThisObject,
		Result);
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingFile",,,,,, Notification);
	
EndProcedure

&AtClient
Procedure SelectAnExistingFileIn1CDocumentManagementCompletion(Result, NotificationParameters) Export

	If TypeOf(Result) = Type("Structure") Then
		CopyExistingFileToFolder(Result.AttributeID);
		UpdateFileListClient(Result.AttributeID);
	EndIf;
	
EndProcedure

&AtServer
Procedure CopyExistingFileToFolder(FileID)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRetrieveRequest");
	ListOfObjects = Query.objectIDs; // XDTOList
	FieldsReceived = Query.columnSet; // XDTOList
	
	ObjectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		FileID,
		"DMFile");
	ListOfObjects.Add(ObjectID);
	
	FieldsReceived.Add("objectID");
	FieldsReceived.Add("name");
	FieldsReceived.Add("binaryData");
	FieldsReceived.Add("extension");
	FieldsReceived.Add("modificationDate");
	FieldsReceived.Add("modificationDateUniversal");
	FieldsReceived.Add("size");
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
	FileData = Response.objects[0];
	
	IntegrationWith1CDocumentManagementCoreClientServer.FileSizeExceedsMaximumAllowed(
		MaxFileSize1,
		FileData.size,
		FileData.name);
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMAddLinkedFileRequest");
	
	Query.rootFolderID = IdentifierOf1CDocumentManagementRootFolder;
	
	Query.file = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMFile",
		ExternalObject);
	
	Query.file.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, "", "DMFile");
	Query.file.binaryData = FileData.binaryData;
	Query.file.extension = FileData.extension;
	Query.file.modificationDate = FileData.modificationDate;
	Query.file.modificationDateUniversal = FileData.modificationDateUniversal;
	Query.file.name = FileData.name;
	Query.file.size = FileData.size;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
EndProcedure

&AtServer
Procedure MarkToDelete(Val SelectedRows)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	ListOfObjects = New Array;
	
	For Each LineNumber In SelectedRows Do
		Data = ListOfFiles.FindByID(LineNumber);
		ListOfObjects.Add(New Structure("ID, Type", Data.ID, "DMFile"));
	EndDo;
	
	IntegrationWith1CDocumentManagementCore.MarkForDeletionUncheckItems(
		Proxy,
		ListOfObjects);
	
EndProcedure

&AtClient
Procedure UpdateAvailabilityOfFileListCommands()
	
	SetCommandsAvailability(Items.ListOfFiles.CurrentData);
	
EndProcedure

&AtClient
Procedure SetCommandsAvailability(CurrentData)
	
	If CurrentData = Undefined Then
		
		Items.ListOfFilesContextMenuOpenFile.Enabled = False;
		Items.ListOfFilesContextMenuSaveAs.Enabled = False;
		Items.ListOfFilesContextMenuUpdateFromFileOnHardDrive.Enabled = False;
		Items.ListOfFilesContextMenuSign.Enabled = False;
		Items.ListOfFilesContextMenuAddDSFromFile.Enabled = False;
		Items.ListOfFilesContextMenuSaveWithDigitalSignature.Enabled = False;
		
		Items.ListOfFilesOpenFile.Enabled = False;
		Items.ListOfFilesSaveAs.Enabled = False;
		Items.ListOfFilesUpdateFromFileOnHardDrive.Enabled = False;
		Items.ListOfFilesSign.Enabled = False;
		Items.ListOfFilesAddDSFromFile.Enabled = False;
		Items.ListOfFilesSaveWithDigitalSignature.Enabled = False;
		
	Else
		
		IsBeingEdited = CurrentData.IsBeingEdited;
		SignedWithDS = CurrentData.SignedWithDS;
		Encrypted = CurrentData.Encrypted;
		
		Items.ListOfFilesContextMenuOpenFile.Enabled = True;
		Items.ListOfFilesContextMenuSaveAs.Enabled = True;
		Items.ListOfFilesContextMenuUpdateFromFileOnHardDrive.Enabled = True;
		Items.ListOfFilesContextMenuSign.Enabled =
			Not IsBeingEdited And Not Encrypted;
		Items.ListOfFilesContextMenuAddDSFromFile.Enabled =
			Not IsBeingEdited And Not Encrypted;
		Items.ListOfFilesContextMenuSaveWithDigitalSignature.Enabled = SignedWithDS;
		
		Items.ListOfFilesOpenFile.Enabled = True;
		Items.ListOfFilesSaveAs.Enabled = True;
		Items.ListOfFilesUpdateFromFileOnHardDrive.Enabled = True;
		Items.ListOfFilesSign.Enabled =
			Not IsBeingEdited And Not Encrypted;
		Items.ListOfFilesAddDSFromFile.Enabled =
			Not IsBeingEdited And Not Encrypted;
		Items.ListOfFilesSaveWithDigitalSignature.Enabled = SignedWithDS;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInFileData()
	
	UpdateFileList();
	
	SettingsBefore = IntegrationWith1CDocumentManagementCoreCached.GetSettings();
	UseElectronicDigitalSignaturesVBSP =
		IntegrationWith1CDocumentManagementCoreServerCall.UseElectronicDigitalSignatures();
	
	If SettingsBefore.UseElectronicDigitalSignatures = False Then
		Items.ListOfFilesSignedWithDS.Visible = False;
		Items.ListOfFilesSaveWithDigitalSignature.Visible = False;
		Items.ListOfFilesContextMenuSaveWithDigitalSignature.Visible = False;
	EndIf;
	
	If SettingsBefore.UseElectronicDigitalSignatures = False
			Or UseElectronicDigitalSignaturesVBSP = False Then
		Items.ListOfFilesSign.Visible = False;
		Items.ListOfFilesContextMenuSign.Visible = False;
		Items.ListOfFilesAddDSFromFile.Visible = False;
		Items.ListOfFilesContextMenuAddDSFromFile.Visible = False;
	EndIf;
	
	IdentifierOf1CDocumentManagementRootFolder = GetIdentifierOf1CDocumentManagementRootFilesFolder();
	
EndProcedure

// Start creating a file from a file on disk.
//
&AtClient
Procedure CreateFileFromDisk()
	
	If Not ValueIsFilled(IdentifierOf1CDocumentManagementRootFolder) Then
		ShowMessageBox(,
			NStr("vi = 'Chư chỉ ra thư mục gốc để lưu tệp 1C:Document Management.';
				|ru = 'Не указана корневая папка для хранения файлов 1С:Документооборота.';
				|en = 'Root folder for 1C:Document Management file saving is not specified.'; fa = 'Root folder for 1C:Document Management file saving is not specified.';
				|it = 'Non è indicata la cartella principale per l''archiviazione dei file di 1C:Document Management.';
				|pl = 'Nie określono folderu korzeniowego do przechowywania plików 1C:Document Management.';
				|tr = '1C:Document Management dosyalarını depolamak için kök klasör belirtilmedi.'"));
		Return;
	EndIf;
	
	NotificationParameters = New Structure;
	BeginAttachingFileSystemExtension(New CallbackDescription(
		"CreateFileFromDiskAfterConnectingExtension", ThisObject, NotificationParameters));
	
EndProcedure

// Start creating a file from a file on disk.
//
// Parameters:
//   File - File
//
&AtClient
Procedure CreateFileFromDiskByDraggingAndDropping(File)
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("FullFileName", File.FullName);
	NotificationParameters.Insert("File", File);
	
	File.BeginGettingSize(New CallbackDescription(
		"CreateFileFromDiskAfterGettingSize", ThisObject, NotificationParameters));
	
EndProcedure

// It is performed during the creation of a file from disk after connecting the extension.
//
// Parameters:
//   Attached - Boolean
//   NotificationParameters - Structure
//
&AtClient
Procedure CreateFileFromDiskAfterConnectingExtension(Attached, NotificationParameters) Export
	
	If Attached Then
		
		SelectingFile = New FileDialog(FileDialogMode.Open);
		SelectingFile.Multiselect = False;
		SelectingFile.Title = NStr("vi = 'Chọn tệp';
									|ru = 'Выбор файла';
									|en = 'Select file'; fa = 'انتخاب فایل';
									|it = 'Selezione del file';
									|pl = 'Wybór pliku';
									|tr = 'Dosya seçimi'");
		SelectingFile.Filter = NStr("vi = 'Tất cả tệp (*.*)|*.*';
									|ru = 'Все файлы (*.*)|*.*';
									|en = 'All files (*.*)|*.*'; fa = 'All files (*.*)|*.*';
									|it = 'Tutti i file (*.*)|*.*';
									|pl = 'Wszystkie pliki (*.*)|*.*';
									|tr = 'Tüm dosyalar (*.*)|*.*'");
		SelectingFile.Show(New CallbackDescription(
			"CreateFileFromDiskAfterFileSelectionDialog", ThisObject, NotificationParameters));
		
	Else // Web client without extension.
		
		ImportParameters = FileSystemClient.FileImportParameters();
		ImportParameters.FormIdentifier = UUID;
		
		FileSystemClient.ImportFile_(
			New CallbackDescription(
				"CreateFileFromDiskAfterPlacingFileWithoutExtension",
				ThisObject,
				NotificationParameters),
			ImportParameters);
		
	EndIf;
	
EndProcedure

// It is performed during the creation of a file from disk after the file selection dialog.
//
// Parameters:
//   SelectedFiles - Array of String
//   NotificationParameters - Structure
//
&AtClient
Procedure CreateFileFromDiskAfterFileSelectionDialog(SelectedFiles, NotificationParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	FullFileName = SelectedFiles[0];
	File = New File(FullFileName);
	
	NotificationParameters.Insert("FullFileName", FullFileName);
	NotificationParameters.Insert("File", File);
	File.BeginGettingSize(New CallbackDescription(
		"CreateFileFromDiskAfterGettingSize", ThisObject, NotificationParameters));
	
EndProcedure

// It is performed during the creation of a file from disk after getting the size.
//
// Parameters:
//   Size - Number
//   NotificationParameters - Structure:
//     * FullFileName - String
//     * File - File
//
&AtClient
Procedure CreateFileFromDiskAfterGettingSize(Size, NotificationParameters) Export
	
	IntegrationWith1CDocumentManagementCoreClientServer.FileSizeExceedsMaximumAllowed(
		MaxFileSize1,
		Size,
		NotificationParameters.FullFileName);
	
	NotificationParameters.Insert("Size", Size);
	NotificationParameters.File.BeginGettingModificationTime(New CallbackDescription(
		"CreateFileFromDiskAfterReceivingChangeTime", ThisObject, NotificationParameters));
	
EndProcedure

// It is executed during the creation of a file from disk after receiving the modification time.
//
// Parameters:
//   Var_Modified - Date
//   NotificationParameters - Structure:
//     * FullFileName - String
//     * File - File
//     * Size - Number
//
&AtClient
Procedure CreateFileFromDiskAfterReceivingChangeTime(Var_Modified, NotificationParameters) Export
	
	NotificationParameters.Insert("Modified", Var_Modified);
	NotificationParameters.File.BeginGettingModificationUniversalTime(New CallbackDescription(
		"CreateFileFromDiskAfterGettingUniversalModificationTime", ThisObject, NotificationParameters));
	
EndProcedure

// It is performed during the creation of a file from disk after receiving the universal modification time.
//
// Parameters:
//   ModificationTimeUniversal - Date
//   NotificationParameters - Structure:
//     * FullFileName - String
//     * File - File
//     * Size - Number
//     * Modified - Date
//
&AtClient
Procedure CreateFileFromDiskAfterGettingUniversalModificationTime(ModificationTimeUniversal,
		NotificationParameters) Export
	
	NotificationParameters.Insert("ModificationTimeUniversal", ModificationTimeUniversal);
	
	SizeInMB = NotificationParameters.Size / (1024 * 1024);
	ExplanationText = StrTemplate(NStr("vi = 'Đang lưu lại tệp ""%1"" (%2 Mb).
			|Xin vui lòng đợi...';
			|ru = 'Идет сохранение файла ""%1"" (%2 Мб).
			|Пожалуйста, подождите...';
			|en = 'Saving file ""%1"" (%2 MB).
			|Please wait...'; fa = 'Saving file ""%1"" (%2 MB).
			|Please wait...';
			|it = 'Salvataggio del file ""%1"" (%2 MB). 
			|Attendere...';
			|pl = 'Trwa zapisywanie pliku ""%1"" (%2 MB).
			|Proszę czekać...';
			|tr = '""%1"" (%2 Mb) dosyası kaydediliyor.
			|Lütfen bekleyin...'"),
		NotificationParameters.FullFileName,
		IntegrationWith1CDocumentManagementCoreClientServer.GetStringWithFileSize(SizeInMB));
	Status(ExplanationText);
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.Interactively = False;
	ImportParameters.FormIdentifier = UUID;
	FileSystemClient.ImportFile_(
		New CallbackDescription(
			"CreateFileFromDiskAfterPlacingFile",
			ThisObject,
			NotificationParameters),
		ImportParameters,
		NotificationParameters.FullFileName);
	
EndProcedure

// It is performed during the creation of a file from disk after placing the file (thin and web with the extension).
//
// Parameters:
//   FileThatWasPut - Structure - if the file is placed in the repository:
//     * Location - String - The address of the file data in the temporary storage.
//     * Name - String - the full path to the placed file.
//   NotificationParameters - Structure:
//     * FullFileName - String
//     * File - File
//     * Size - Number
//     * Modified - Date
//     * ModificationTimeUniversal - Date
//
&AtClient
Async Procedure CreateFileFromDiskAfterPlacingFile(Val FileThatWasPut, Val NotificationParameters) Export
	
	Status();
	If FileThatWasPut = Undefined Then
		Return;
	EndIf;
	
	NotificationParameters.Insert("TempFileStorageAddress", FileThatWasPut.Location);
	
	Settings1CDocumentManagement = IntegrationWith1CDocumentManagementCoreClientCached.GetSettings();
	If Settings1CDocumentManagement.NeedToExtractText Then
		ExtractedText = Await IntegrationWith1CDocumentManagementCoreClient.ExtractText1Async(
			NotificationParameters.FullFileName);
		NotificationParameters.Insert("Text", ExtractedText);
	Else
		NotificationParameters.Insert("Text", "");
	EndIf;
	
	CreateFileFromDiskCompletion(NotificationParameters);
	
EndProcedure

// It is performed during the creation of a file from disk after placing the file (web without extension).
//
// Parameters:
//   FileThatWasPut - Structure - if the file is placed in the repository:
//     * Location - String - The address of the file data in the temporary storage.
//     * Name - String - the full path to the placed file.
//   NotificationParameters - Structure:
//     * FullFileName - String
//     * File - File
//     * Size - Number
//     * Modified - Date
//     * ModificationTimeUniversal - Date
//     * TempFileStorageAddress - String
//     * Text - String
//
&AtClient
Procedure CreateFileFromDiskAfterPlacingFileWithoutExtension(FileThatWasPut, NotificationParameters) Export
	
	If FileThatWasPut = Undefined Then
		Return;
	EndIf;
	
	NotificationParameters.Insert("TempFileStorageAddress", FileThatWasPut.Location);
	NotificationParameters.Insert("FullFileName", FileThatWasPut.Name);
	NotificationParameters.Insert("Size", 0);
	NotificationParameters.Insert("Modified", Date('00010101'));
	NotificationParameters.Insert("ModificationTimeUniversal", Date('00010101'));
	NotificationParameters.Insert("Text", "");
	
	CreateFileFromDiskCompletion(NotificationParameters);
	
EndProcedure

// It is performed during the creation of a file from disk after placing the file (universal completion).
//
// Parameters:
//   NotificationParameters - Structure:
//     * FullFileName - String
//     * File - File
//     * Size - Number
//     * Modified - Date
//     * ModificationTimeUniversal - Date
//     * TempFileStorageAddress - String
//     * Text - String
//
&AtClient
Procedure CreateFileFromDiskCompletion(NotificationParameters)
	
	// Let's analyze the full path by name and extension.
	NameStructure = IntegrationWith1CDocumentManagementCoreClient.ParseFullFileName(
		NotificationParameters.FullFileName);
	NotificationParameters.Insert("Extension", NameStructure.Extension);
	NotificationParameters.Insert("Name", NameStructure.BaseName);
	
	NotificationParameters.Delete("File");
	IDOfCreatedFile = CreateFileInFolderFromFileOnHDD(NotificationParameters);
	Status();
	
	UpdateFileListClient(IDOfCreatedFile);
	
	Notify("Recording_1CDocumentManagementFile", Parameters, ThisObject);
	
EndProcedure

&AtServer
Function CreateFileInFolderFromFileOnHDD(CreationParameters)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMAddLinkedFileRequest");
	
	Query.rootFolderID = IdentifierOf1CDocumentManagementRootFolder;
	
	Query.file = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMFile",
		ExternalObject);
	
	Query.file.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, "", "DMFile");
	Query.file.binaryData = GetFromTempStorage(CreationParameters.TempFileStorageAddress);
	Query.file.extension = CreationParameters.Extension;
	Query.file.modificationDate = CreationParameters.Modified;
	Query.file.modificationDateUniversal = CreationParameters.ModificationTimeUniversal;
	Query.file.name = CreationParameters.Name;
	Query.file.size = CreationParameters.Size;
	
	IntegrationWith1CDocumentManagementCoreClientServer.FileSizeExceedsMaximumAllowed(
		MaxFileSize1,
		CreationParameters.Size,
		CreationParameters.Name);
	
	If Not IsBlankString(CreationParameters.Text) Then
		Query.file.text = CreationParameters.Text;
	EndIf;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
	Return Response.file.objectID.ID;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////////////////////////
// Links

// Opens the currently linked document or its file.
//
&AtClient
Procedure OpenRelatedRowData(String)
	
	If String.Type = "DMRelationType" Then // the IP object.
		Return;
		
	ElsIf String.Type = "DMFile" Then // file.
		IntegrationWith1CDocumentManagementCoreClient.OpenFile(
			String.ID,
			String.Title,
			String.Extension,
			UUID);
		
	Else // Object BEFORE.
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(String.Type, String.ID, ThisObject);
		
	EndIf;
	
EndProcedure

// Called after adding a link and updates the link tree.
//
&AtClient
Procedure StartAddingLinkCompletion(Result, Var_Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	UpdateRelationshipTree(, Result.LinkedDocument.ID);
	
	If ValueIsFilled(AddressForLinkedDocumentFiles) Then
		AttachIdleHandler("UpdatingRelatedDocumentFiles", 1, True);
	EndIf;
	
EndProcedure

// Called after the link is deleted and updates the link tree.
//
&AtClient
Procedure StartDeletingLinkCompletion(Result, Var_Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	UpdateRelationshipTree();
	
	If ValueIsFilled(AddressForLinkedDocumentFiles) Then
		AttachIdleHandler("UpdatingRelatedDocumentFiles", 1, True);
	EndIf;
		
EndProcedure

// Updates the document's link data, retrieving it anew if necessary.
//
// Parameters:
//   XDTODataObject - XDTODataObject - the document received from BEFORE, or
//              - Undefined - a sign of the need to get it.
//   AddedDocument - String - id of the document whose files need to be updated, or
//                       - Undefined - indicates whether all files need to be updated.
//
&AtServer
Procedure UpdateRelationshipTree(Val XDTODataObject = Undefined, AddedDocument = Undefined)
	
	Counterparty = "";
	CounterpartyID = "";
	Organization = "";
	OrganizationID = "";
	
	If Not ValueIsFilled(DocumentID) Then
		LinkTree.GetItems().Clear();
		Items.GroupRelatedDocuments.Title = NStr("vi = 'Liên kết';
												|ru = 'Связи';
												|en = 'Links'; fa = 'پیوندها';
												|it = 'Collegamenti';
												|pl = 'Links';
												|tr = 'Bağlantılar'");
		Return;
	EndIf;
	
	If XDTODataObject = Undefined Then
		
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRetrieveRequest");
		ListOfObjects = Query.objectIDs; // XDTOList
		FieldsReceived = Query.columnSet; // XDTOList
		
		ListOfObjects.Add(
			IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				DocumentID,
				DocumentType));
		
		FieldsReceived.Add("relations");
		If IntegrationWith1CDocumentManagementClientServer.IsDocument(DocumentType) Then
			FieldsReceived.Add("correspondent");
			FieldsReceived.Add("organization");
		EndIf;
		
		Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
		IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
		XDTODataObject = Result.objects[0];
		
		// We will fill in the organization and the counterparty for further use in the selections.
		If XDTODataObject.Properties().Get("correspondent") <> Undefined
			And XDTODataObject.IsSet("correspondent") Then
			Counterparty = XDTODataObject.correspondent.name;
			CounterpartyID = XDTODataObject.correspondent.objectID.ID;
		EndIf;
		If XDTODataObject.Properties().Get("organization") <> Undefined
			And XDTODataObject.IsSet("organization") Then
			Organization = XDTODataObject.organization.name;
			OrganizationID = XDTODataObject.organization.objectID.ID;
		EndIf;
		
	EndIf;
	
	AddressForLinkedDocumentFiles = DataProcessors.IntegrationWith1CDocumentManagement.
		FillInLinkTreeAndStartReceivingFiles(
			ThisObject,
			XDTODataObject,
			Items.GroupRelatedDocuments,
			AddedDocument);
	
EndProcedure

// Updates the files of related documents with temporary storage data filled
// in an asynchronous job, postponing the update if the data is not ready yet.
//
&AtClient
Procedure UpdatingRelatedDocumentFiles()
	
	If Not ValueIsFilled(AddressForLinkedDocumentFiles) Then
		Return;
	EndIf;
	
	// Let's save the current position by the object ID, taking into account the type of connection.
	CurrentData = Items.LinkTree.CurrentData;
	If CurrentData = Undefined Then
		Current_ID = Undefined;
		Current_Type = Undefined;
		CurTypeOfCommunication = Undefined;
	Else
		Current_ID = CurrentData.ID;
		Current_Type = CurrentData.Type;
		If Current_Type = "DMRelationType" Then
			LinkTypeString_ = CurrentData;
		ElsIf Current_Type = "DMFile" Then
			LinkTypeString_ = CurrentData.GetParent().GetParent();
		Else
			LinkTypeString_ = CurrentData.GetParent();
		EndIf;
		CurTypeOfCommunication = LinkTypeString_.ID;
	EndIf;
	
	If UpdatingRelatedDocumentFilesServer() Then // The data is not ready yet.
		
		AttachIdleHandler("UpdatingRelatedDocumentFiles", 1, True);
		
	Else // The data is received, expand the tree and restore the position in it.
		
		StringsLinkType = LinkTree.GetItems();
		For Each LinkTypeString In StringsLinkType Do
			
			Id = LinkTypeString.GetID();
			Items.LinkTree.Expand(Id, True);
			
			If Current_Type = Undefined Then
				Continue;
				
			ElsIf Current_Type = "DMRelationType" Then
				If LinkTypeString.ID = Current_ID Then
					Items.LinkTree.CurrentRow = Id;
				EndIf;
				
			ElsIf LinkTypeString.ID = CurTypeOfCommunication Then
				
				LinesDocument = LinkTypeString.GetItems();
				For Each LineDocument In LinesDocument Do
					
					If Current_Type = "DMFile" Then
						LinesFile = LinesDocument.GetItems();
						For Each FileRow In LinesFile Do
							If FileRow.ID = Current_ID Then
								Items.LinkTree.CurrentRow = FileRow.GetID();
								Break;
							EndIf;
						EndDo;
						
					ElsIf LineDocument.ID = Current_ID Then
						Items.LinkTree.CurrentRow = LineDocument.GetID();
						Break;
					EndIf;
					
				EndDo;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Updates the files of related documents with temporary storage data, if they are ready.
//
// Returns:
//   Boolean - True if re-updating is required, and False if not required.
//
&AtServer
Function UpdatingRelatedDocumentFilesServer()
	
	Result = GetFromTempStorage(AddressForLinkedDocumentFiles);
	If Result = Undefined Then
		Return True;
	EndIf;
	
	Tree = FormAttributeToValue("LinkTree");
	
	For Each LinkedDocument In Result Do
		
		LinkedDocumentFiles = LinkedDocument.Files; // Array of Structure
		
		TheStructureOfTheSearch = New Structure("ID, Type",
			LinkedDocument.ID,
			LinkedDocument.Type);
		DocumentStrings = Tree.Rows.FindRows(TheStructureOfTheSearch, True);
		For Each DocumentLine In DocumentStrings Do
			DocumentLine.Rows.Clear();
			For Each File In LinkedDocumentFiles Do
				FileString = DocumentLine.Rows.Add();
				FileString.ID = File.ID;
				FileString.Type = File.Type;
				FileString.Title = File.Description;
				FileString.Extension = File.Extension;
				FileString.Picture =
					IntegrationWith1CDocumentManagementCore.IndexOfFileIcon(FileString.Extension);
			EndDo;
		EndDo;
		
	EndDo;
	
	ValueToFormAttribute(Tree, "LinkTree");
	
	Return False;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////////////////////////
// History of correspondence

&AtServer
Procedure GetFillInEmailTree()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	ListOfConditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetCorrespondenceTreeQuery");
	CorrespondenceObjects = ListOfConditions.target; // XDTOList
	
	SubjectXDTO = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObject");
	SubjectXDTO.name = "";
	SubjectXDTO.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, DocumentID, DocumentType);
	CorrespondenceObjects.Add(SubjectXDTO);
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetCorrespondenceTreeRequest");
	Query.query = ListOfConditions;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
	Tree = FormAttributeToValue("MessageTree");
	Tree.Rows.Clear();
	For Each Item In Response.followers Do
		FillInTreeLine(Tree.Rows, Item);
	EndDo;
	ValueToFormAttribute(Tree, "MessageTree");
	
EndProcedure

&AtServer
Procedure FillInTreeLine(TreeRows, XDTORow)
	
	TreeRow = TreeRows.Add();
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		TreeRow,
		XDTORow.object,
		"MailMessage");
	TreeRow.Recipients = XDTORow.recipients;
	TreeRow.Date = XDTORow.date;
	If DocumentType = "DMCorrespondent" Or DocumentType = "DMOutgoingEMail" Then
		If XDTORow.Properties().Get("regNumber") <> Undefined Then
			TreeRow.Number = XDTORow.regNumber;
		EndIf;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "sent") Then
		TreeRow.Shipped_5 = XDTORow.sent;
	Else
		TreeRow.Shipped_5 = False;
	EndIf;
	
	If TreeRow.MailMessageType = "DMIncomingEMail" Then
		TreeRow.Picture = 0;
	ElsIf TreeRow.MailMessageType = "DMOutgoingEMail" Then
		// filling in the sent property
		If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP") Then
			If TreeRow.Shipped_5 = True Then
				TreeRow.Picture = 1;
			Else
				TreeRow.Picture = 3;
			EndIf;
		Else
			TreeRow.Picture = 1;
		EndIf;
	ElsIf DocumentType = "DMCorrespondent" Then
		If TreeRow.MailMessageType = "DMInternalDocument" Then
			TreeRow.Picture = 2;
		ElsIf TreeRow.MailMessageType = "DMIncomingDocument" Then
			TreeRow.Picture = 0;
		Else
			If TreeRow.Shipped_5 Then
				TreeRow.Picture = 1;
			Else
				TreeRow.Picture = 3;
			EndIf;
		EndIf;
	Else
		TreeRow.Picture = 2;
	EndIf;
	
	For Each Item In XDTORow.followers Do
		FillInTreeLine(TreeRow.Rows, Item);
	EndDo;
	
EndProcedure

&AtClient
Procedure ExpandMessageTree()
	
	TreeItems = MessageTree.GetItems();
	For Each TreeItem In TreeItems Do
		Items.MessageTree.Expand(TreeItem.GetID(), True);
	EndDo;
	
EndProcedure

&AtClient
Function EmailIsInList(MailMessageID)
	
	TreeItems = MessageTree.GetItems();
	Return CheckForTreeElement(TreeItems,MailMessageID);
	
EndFunction

&AtClient
Function CheckForTreeElement(TreeItems, MailMessageID)
	
	LetterExists = False;
	For Each TreeItem In TreeItems Do
		If TreeItem.MailMessageID = MailMessageID Then
			LetterExists = True;
			Return LetterExists;
		Else
			SubordinateItems = TreeItem.GetItems();
		    LetterExists = CheckForTreeElement(SubordinateItems, MailMessageID)
		EndIf;
	EndDo;

	Return LetterExists;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////////////////////////
// LaborCosts

&AtServer
Procedure FillInTheLaborCosts()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	ListOfConditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
	FilterConditions = ListOfConditions.conditions; // XDTOList
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "source";
	
	Condition.value = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, DocumentID, DocumentType);
	
	FilterConditions.Add(Condition);
	
	Response = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
		Proxy,
		"DMActualWork",
		ListOfConditions);
	
	Works.Clear();
	
	For Each ResponseString In Response.items Do
		
		String = ResponseString.object;
		
		NewRow = Works.Add();
		NewRow.AddedOn = String.addDate;
		NewRow.Begin = String.begin;
		NewRow.Ending = String.end;
		NewRow.Work_5 = String.description;
		NewRow.Duration = String.duration / 3600;
		NewRow.DurationOfRow = IntegrationWith1CDocumentManagementClientServer.NumberPerLine(
			NewRow.Duration);
		
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			NewRow, String.workType, "WorkKind", False);
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			NewRow, String.project,"Project", False);
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			NewRow, String.projectTask,"TaskOfTheProject", False);
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			NewRow, String.source, "Source", False);
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			NewRow, String.user, "User", False);
		
		NewRow.ProjectTask = IntegrationWith1CDocumentManagementClientServer.PresentationOfTaskProject(
			NewRow.Project, NewRow.TaskOfTheProject);
		
	EndDo;
		
	Items.WorksDuration.FooterText = Format(Works.Total("Duration"),"ND=15; NFD=2; NZ=0,00");
	
	Works.Sort("AddedOn");
	
EndProcedure

#EndRegion