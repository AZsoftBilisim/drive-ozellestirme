#Region Variables

&AtClient
Var LinesForDisclosure;

&AtClient
Var CurRowId_;

&AtClient
Var CurCurrentStringType;

&AtClient
Var FileTreeStringKey;

&AtClient
Var LinkTreeStringKey;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ExternalObject = Parameters.ExternalObject;
	FileCatalogType = ExternalObject.Metadata().FullName();
	HomePage = Parameters.HomePage;
	ConsumerMetadata = Parameters.ExternalObject.Metadata();
	ConsumerName = ?(ConsumerMetadata.Synonym <> "",
		ConsumerMetadata.Synonym,
		ConsumerMetadata.Name);
	FullNameOfConsumer = ConsumerMetadata.FullName();
	
	AbbreviatedNameOfConfiguration =
		IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration();
	
	UpdateViewOfObjectBeingCreated();
	
	UseProcessingOf1CDocumentManagementObjects =
		Constants.UseProcessingOf1CDocumentManagementObjects.Get();
	UseDigitalSignatureIS =
		IntegrationWith1CDocumentManagementCoreServerCall.UseElectronicDigitalSignatures();
	
	PreviewOfLinksStorage = Common.CommonSettingsStorageLoad(
		"ObjectsLinksBefore",
		"PreviewBIDFiles");
	If PreviewOfLinksStorage = Undefined Then
		PreviewLinks = False;
	Else
		PreviewLinks = PreviewOfLinksStorage;
	EndIf;
	
	Items.LinkTreePreview.Check = PreviewLinks;
	Items.LinkViewPages.Visible = PreviewLinks;
	
	AddressOfObjectSBinaryData =
		IntegrationWith1CDocumentManagementCoreClientServer.AddressOfObjectSBinaryData(
			UUID);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ValueIsFilled(HomePage) Then
		CurBookmark = HomePage;
	EndIf;
	
	If ExternalObject.IsEmpty() Then
		WarningText = NStr("vi = 'Còn chưa ghi lại dữ liệu. 
			|Chỉ có thể chuyển sang ""Document Management"" sau khi ghi lại dữ liệu.';
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
Procedure OnClose(Exit)
	
	If ShowPDFUsing1C Then
		ThisObject["PDFDocumentOverviewAttributes"] = Undefined;
		ThisObject["PDFDocumentCommunicationAttributes"] = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Not IsOpen() Then
		Return;
	EndIf;
	
	If EventName = "IntegrationWith1CDocumentManagement_SuccessfulConnection" Then
		If Source <> ThisObject Then
			WhenConnecting();
		EndIf;
		
	ElsIf EventName = "IntegrationWith1CWorkflow3_RuleWritten" Then
		UpdateViewOfObjectBeingCreated();
		
	ElsIf EventName = "DocumentManagement_SelectAValueFromTheListCompletion" Then
		If Source = ThisObject
				And Parameter = "ObjectBefore"
				And ValueIsFilled(ObjectBeforeID)
				And ValueIsFilled(ObjectBeforeType) Then
			// Adding a new connection.
			IntegrationWith1CDocumentManagementCoreServerCall.AddLink(
				ObjectBeforeID,
				ObjectBeforeType,
				ExternalObject);
			IntegrationWith1CDocumentManagementCoreClient.Notify_AddingConnection(
				ObjectBeforeID,
				ObjectBeforeType,
				ExternalObject);
		EndIf;
		
	ElsIf EventName = "DocumentManagement_AddingALink" Then
		If TypeOf(Parameter) = Type("Structure")
				And Parameter.Property("Object")
				And Parameter.Object = ExternalObject Then
			StartReceivingDataFromLinkedObjectDM(Items.GroupPages.CurrentPage, True);
		EndIf;
		
	ElsIf EventName = "DocumentManagement_DeletingALink" Then
		If TypeOf(Parameter) = Type("Structure")
				And Parameter.Property("Object")
				And Parameter.Object = ExternalObject Then
			DeleteLink();
		EndIf;
		
	ElsIf EventName = "Workflow_ActionWithProcessing" Then
		If TypeOf(Parameter) = Type("Structure")
				And Parameter.Property("DataProcessorData")
				And Parameter.DataProcessorData.SubjectOfID = ObjectBeforeID
				And Parameter.DataProcessorData.SubjectOfType = ObjectBeforeType Then
			// The review needs to be updated anyway.
			ReviewIsFull = False;
			If Source <> ThisObject Then
				// Processing needs to be updated only if the processing action was performed in a different Form.
				// Otherwise, the processing has already been updated.
				ProcessingIsFilled = False;
			EndIf;
			If TypeOf(Source) = Type("ClientApplicationForm") And Source.FormOwner = ThisObject Then
				OutputIdleWindow = True;
			Else
				OutputIdleWindow = False;
			EndIf;
			StartUpdatingForm(Items.GroupPages.CurrentPage, OutputIdleWindow);
		EndIf;
		
	ElsIf EventName = "Workflow_ActionOnTask" Then
		If TypeOf(Parameter) = Type("Structure")
				And Parameter.Property("ID")
				And Parameter.Property("Type")
				And Parameter.Property("OperationType")
				And (Parameter.OperationType.PerformTaskAction
					Or Parameter.OperationType.TakeToWork
					Or Parameter.OperationType.CancelTakingToWork
					Or Parameter.OperationType.Forward)
				And Task_By_ID(Parameter.ID, Parameter.Type, Actions.GetItems()) <> Undefined Then
			ReviewIsFull = False;
			ProcessingIsFilled = False;
			If TypeOf(Source) = Type("ClientApplicationForm") And Source.FormOwner = ThisObject Then
				OutputIdleWindow = Parameter.OperationType.PerformTaskAction;
			Else
				OutputIdleWindow = False;
			EndIf;
			StartUpdatingForm(Items.GroupPages.CurrentPage, OutputIdleWindow);
		EndIf;
		
	ElsIf EventName = "Write_ConstantsSet" Then
		If Source = "UseProcessingOf1CDocumentManagementObjects" Then
			ReReadFunctionalOptions(ObjectBeforeType);
		EndIf;
		
	ElsIf EventName = "HTMLObjectPreviewReceived" Then
		If Not IntegrationWith1CDocumentManagementCoreClientServer.TheseAreNotificationParametersHTMLObjectPreviewReceived(
				Parameter) Then
			Return;
		EndIf;
		ProcessEventOfReceivingHTMLPreviewReview(Parameter, Source);
		ProcessEventOfReceivingHTMLLinkPreview(Parameter, Source);
		
	ElsIf EventName = "Recording_1CDocumentManagementFile" Then
		If TypeOf(Parameter) <> Type("Structure")
				Or Not Parameter.Property("FileOperation")
				Or Not Parameter.Property("FileID")
				Or Not Parameter.Property("FileOwner")
				Or Not Parameter.Property("FileName")
				Or Not Parameter.Property("FormUniqueID")
				Or Not Parameter.FileOperation.InformFileListForm Then
			Return;
		EndIf;
		ProcessFileWriteEventOverview(Parameter, Source);
		ProcessCommunicationFileRecordingEvent(Parameter, Source);
		
	ElsIf EventName = "AddingObjectLinksTO" Or EventName = "DeletingObjectLinksBEFORE" Then
		If TypeOf(Parameter) <> Type("Structure")
				Or Not Parameter.Property("ID")
				Or Not Parameter.Property("Type") Then
			Return;
		EndIf;
		NeedUpdate = (Parameter.ID = ObjectBeforeID) And (Parameter.Type = ObjectBeforeType);
		If NeedUpdate Then
			OutputIdleWindow = (Source <> ThisObject);
			UpdateConnections(OutputIdleWindow);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	NavigationLinkArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
		FormattedStringURL,
		"||");
	
	FormParameters = New Structure;
	FormParameters.Insert("ObjectTypeIS", NavigationLinkArray[1]);
	
	If NavigationLinkArray[0] = "ItemForm" Then
		NameOfRuleForm = "Catalog.RulesForIntegrationWith1CDocumentManagement3.Form.ItemForm";
		
	ElsIf NavigationLinkArray[0] = "ListForm" Then
		NameOfRuleForm = "Catalog.RulesForIntegrationWith1CDocumentManagement3.Form.ListForm";
		
	Else
		Return;
		
	EndIf;
	
	OpenForm(NameOfRuleForm, FormParameters, ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	CurBookmark = CurrentPage.Name;
	
	StartUpdatingForm(CurrentPage, False, True);
	
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
Procedure SceneryObjectSelectClick(Item)
	
	AdditionalParameters = New Structure;
	
	If ValueIsFilled(TypeOfObjectToCreate) Then
		
		DecorationObjectSelectByClickingAfterSelectingType(TypeOfObjectToCreate, AdditionalParameters);
		
	Else // The type is unknown, we will offer the user a choice.
		
		CallbackDescription = New CallbackDescription(
			"DecorationObjectSelectByClickingAfterSelectingType",
			ThisObject,
			AdditionalParameters);
		
		FormParameters = New Structure;
		FormParameters.Insert("Title", NStr("vi = 'Chọn trong 1C:Document Management';
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
			"DataProcessor.IntegrationWith1CDocumentManagement3.Form.SelectingTypeOfDocumentManagementObject",
			FormParameters,,,,,
			CallbackDescription,
			FormWindowOpeningMode.LockWholeInterface);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationObjectClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	IntegrationWith1CDocumentManagement3Client.OpenDMObject(MapItemDMNavigationLink);
	
EndProcedure

&AtClient
Async Procedure DecorationObjectClearClick(Val Item)
	
	If Not ValueIsFilled(ObjectBeforeID) Then
		Return;
	EndIf;
	
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
			|%1için uygunluğu temizle?'"), String(ExternalObject));
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
												|tr = 'Temizlememek'");
	QuestionParametersYesNo.DefaultButton = DialogReturnCode.No;
	Response = Await IntegrationWith1CDocumentManagementCoreClient.ShowQuestionYesNoAsync(
		QueryText,
		QuestionParametersYesNo);
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	SavedID = ObjectBeforeID;
	SavedType = ObjectBeforeType;
	
	IntegrationWith1CDocumentManagementCoreServerCall.DeleteLink(
		ObjectBeforeID,
		ObjectBeforeType,
		ExternalObject);
	
	IntegrationWith1CDocumentManagementCoreClient.Notify_RemovingLink(
		SavedID,
		SavedType,
		ExternalObject);
	
EndProcedure

&AtClient
Procedure DecorationObjectCreateClick(Item)
	
	If ValueIsFilled(ObjectBefore) Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagement3Client.StartCreatingARelatedObjectDM(ExternalObject);
	
EndProcedure

&AtClient
Procedure PictureInteractionClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Items.ProcessingPage.Visible Then
		Items.GroupPages.CurrentPage = Items.ProcessingPage;
		GroupPagesOnCurrentPageChange(Items.GroupPages, Items.ProcessingPage);
	EndIf;
	
EndProcedure

&AtClient
Procedure EPImageClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Items.ItemInstancePage.Visible Then
		Items.GroupPages.CurrentPage = Items.ItemInstancePage;
		GroupPagesOnCurrentPageChange(Items.GroupPages, Items.ItemInstancePage);
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowOnlyOriginalsInLinksOnChange(Item)
	
	UpdateConnections(True);
	
EndProcedure

&AtClient
Procedure PresentationHTMLOnClick(Item, EventData, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not ValueIsFilled(EventData.Href) Then
		Return;
	EndIf;
	
	If StrFind(EventData.Href, "OpenForEdit") Then
		
		OpenCurrentFileInFileTreeForEditing();
		
	ElsIf StrFind(EventData.Href, "OpenForView") Then
		
		OpenCurrentFileInFileTreeForReading();
		
	ElsIf StrFind(EventData.Href, "CreatePreview") Then
		
		RefreshFilePreview(True, True);
		
	ElsIf StrFind(EventData.Href, "v8doc:status") And Items.ProcessingPage.Visible Then
		
		Items.GroupPages.CurrentPage = Items.ProcessingPage;
		GroupPagesOnCurrentPageChange(Items.GroupPages, Items.ProcessingPage);
		
	ElsIf StrFind(EventData.Href, "ShowLinks") And Items.LinkPage.Visible Then
		
		Items.GroupPages.CurrentPage = Items.LinkPage;
		GroupPagesOnCurrentPageChange(Items.GroupPages, Items.LinkPage);
		
	ElsIf IntegrationWith1CDocumentManagementCoreClient.IsURL(EventData.Href) Then
		
		IntegrationWith1CDocumentManagementCoreClient.OpenURL(EventData.Href);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PresentationOfHTMLLinkWhenClicked(Item, EventData, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not ValueIsFilled(EventData.Href) Then
		Return;
	EndIf;
	
	RelationshipTreeCurrentData = IntegrationWith1CDocumentManagement3Client.LinkTreeCurrentDataToView(
		Items.LinkTree);
	
	If StrFind(EventData.Href, "OpenForEdit") Then
		
		OpenCurrentFileInLinkTreeForEditing(RelationshipTreeCurrentData);
		
	ElsIf StrFind(EventData.Href, "OpenForView") Then
		
		OpenCurrentFileInLinkTreeForReading(RelationshipTreeCurrentData);
		
	ElsIf StrFind(EventData.Href, "CreatePreview") Then
		
		UpdateLinkPreview(True, True);
		
	ElsIf StrFind(EventData.Href, "v8doc:status") Then
		
		IntegrationWith1CDocumentManagement3Client.OpenWorkflowFormFromLinkTree(
			"ProcessingPage",
			RelationshipTreeCurrentData,
			UUID);
		
	ElsIf StrFind(EventData.Href, "ShowLinks") Then
		
		If RelationshipTreeCurrentData <> Undefined Then
			LinkedObjectBefore = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
				RelationshipTreeCurrentData.LinkedObjectID,
				RelationshipTreeCurrentData.LinkedObjectType,
				RelationshipTreeCurrentData.LinkedObject,,
				RelationshipTreeCurrentData.URL);
			IntegrationWith1CDocumentManagement3Client.ShowObjectConnections(LinkedObjectBefore);
		EndIf;
		
	ElsIf IntegrationWith1CDocumentManagementCoreClient.IsURL(EventData.Href) Then
		
		IntegrationWith1CDocumentManagementCoreClient.OpenURL(EventData.Href);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersActions

&AtClient
Procedure ActionsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ActionsBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ActionsOnActivateRow(Item)
	
	If Not ProcessingTreeIsBeingUpdated Then
		TreeType = IntegrationWith1CDocumentManagement3Client.TreeType();
		TreeType.ThisIsProcessingTree = True;
		StateOfProcessingTree = IntegrationWith1CDocumentManagement3Client.CurCurrentStateOfTree(
			TreeType,
			Actions.GetItems(),
			Items.Actions);
	EndIf;
	
EndProcedure

&AtClient
Procedure ActionsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Item.CurrentData;
	StandardProcessing = False;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	OpenEmployeeSTask = True;
	If CurrentData.ThisIsParticipant And CurrentData.ThisIsAnAction And Field <> Items.ActionsPresentationStaff Then
		OpenEmployeeSTask = False;
	EndIf;
	
	If OpenEmployeeSTask And ProcessDoubleClickOnActionParticipant(CurrentData) Then
		Return;
	EndIf;
	
	If IntegrationWith1CDocumentManagement3ClientServer.ThisIsFamiliarizationAction(CurrentData.ActionType)
			And CurrentData.ThisIsParticipant
			And Field = Items.ActionsPresentationStaff Then
		
		If ValueIsFilled(CurrentData.TaskActionID) And ValueIsFilled(CurrentData.TaskActionType) Then
			FormParameters = New Structure(
				"MainSubject, MainSubjectID, MainSubjectType", ObjectBefore, ObjectBeforeID, ObjectBeforeType);
			IntegrationWith1CDocumentManagementCoreClient.OpenObject(
				CurrentData.TaskActionType,
				CurrentData.TaskActionID,
				ThisObject,
				FormParameters);
			Return;
		EndIf;
		
	EndIf;
	
	If CurrentData.ThisIsSubtask
			And ValueIsFilled(CurrentData.TaskActionID)
			And ValueIsFilled(CurrentData.TaskActionType) Then
		FormParameters = New Structure(
			"MainSubject, MainSubjectID, MainSubjectType", ObjectBefore, ObjectBeforeID, ObjectBeforeType);
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(
			CurrentData.TaskActionType,
			CurrentData.TaskActionID,
			ThisObject,
			FormParameters);
		Return;
	EndIf;
	
	If ViewActionsAvailable
			And ValueIsFilled(CurrentData.ActionID)
			And ValueIsFilled(CurrentData.ActionType) Then
		FormParameters = New Structure(
			"MainSubject, MainSubjectID, MainSubjectType", ObjectBefore, ObjectBeforeID, ObjectBeforeType);
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(
			CurrentData.ActionType,
			CurrentData.ActionID,
			ThisObject,
			FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure ActionsBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
	CurrentData = Items.Actions.CurrentData;
	If CurrentData = Undefined Then
		Return;
	ElsIf CurrentData.ThisIsParticipant And Not CurrentData.ThisIsAnAction
			And ProcessDoubleClickOnActionParticipant(CurrentData) Then
		Return;
	EndIf;
	
	If CurrentData.ThisIsSubtask
			And ValueIsFilled(CurrentData.TaskActionID)
			And ValueIsFilled(CurrentData.TaskActionType) Then
		FormParameters = New Structure(
			"MainSubject, MainSubjectID, MainSubjectType", ObjectBefore, ObjectBeforeID, ObjectBeforeType);
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(
			CurrentData.TaskActionType,
			CurrentData.TaskActionID,
			ThisObject,
			FormParameters);
		Return;
	EndIf;
	
	If ViewActionsAvailable
			And ValueIsFilled(CurrentData.ActionID)
			And ValueIsFilled(CurrentData.ActionType) Then
		FormParameters = New Structure(
			"MainSubject, MainSubjectID, MainSubjectType", ObjectBefore, ObjectBeforeID, ObjectBeforeType);
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(
			CurrentData.ActionType,
			CurrentData.ActionID,
			ThisObject,
			FormParameters);
	ElsIf ValueIsFilled(CurrentData.TaskActionID) And ValueIsFilled(CurrentData.TaskActionType) Then
		FormParameters = New Structure(
			"MainSubject, MainSubjectID, MainSubjectType", ObjectBefore, ObjectBeforeID, ObjectBeforeType);
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(
			CurrentData.TaskActionType,
			CurrentData.TaskActionID,
			ThisObject,
			FormParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSignatureTree

&AtClient
Procedure SignatureTreeBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure SignatureTreeBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
	IntegrationWith1CDocumentManagement3Client.OpenSignature(
		Items.SignatureTree.CurrentData,
		FilesTree,
		UseFileRoles,
		UUID);
	
EndProcedure

&AtClient
Procedure SignatureTreeBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	Notification = New CallbackDescription("DeleteSignatureCompletion", ThisObject);
	IntegrationWith1CDocumentManagement3Client.DeleteSignature(
		Items.SignatureTree.SelectedRows,
		SignatureTree,
		ObjectBeforeID,
		Notification,
		UUID);
	
EndProcedure

&AtClient
Procedure SignatureTreeOnActivateRow(Item)
	
	SetAvaliabilityOfDSCommandsList();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersLinkTree

&AtClient
Procedure LinkTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	RelationshipTreeCurrentData = IntegrationWith1CDocumentManagement3Client.LinkTreeCurrentDataToView(
		Items.LinkTree);
	IntegrationWith1CDocumentManagement3Client.OpenLinkedObjectForViewing(
		RelationshipTreeCurrentData,
		UUID);
	
EndProcedure

&AtClient
Procedure LinkTreeBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	Cancel = True;
	
	If Not CreatingLinksIsAvailable Then
		Return;
	EndIf;
	
	InitialObjectBefore = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		ObjectBeforeID,
		ObjectBeforeType,
		ObjectBefore,,
		MapItemDMNavigationLink);
	IntegrationWith1CDocumentManagement3Client.StartAddingLink(InitialObjectBefore);
	
EndProcedure

&AtClient
Procedure LinkTreeBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
	RelationshipTreeCurrentData = IntegrationWith1CDocumentManagement3Client.LinkTreeCurrentDataToView(
		Items.LinkTree);
	If RelationshipTreeCurrentData = Undefined Then
		Return;
	EndIf;
	If Not ValueIsFilled(RelationshipTreeCurrentData.LinkedObjectID)
			Or Not ValueIsFilled(RelationshipTreeCurrentData.LinkedObjectType) Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(
		RelationshipTreeCurrentData.LinkedObjectType,
		RelationshipTreeCurrentData.LinkedObjectID,
		ThisObject);
	
EndProcedure

&AtClient
Procedure LinkTreeBeforeExpand(Item, String, Cancel)
	
	TreeRow = LinkTree.FindByID(String);
	ParentRow = TreeRow.GetParent();
	
	If ParentRow <> Undefined
			And TreeRow.ThisIsCommunicationBranch
			And TreeRow.GetItems().Count() > 0 Then
		SubordinateRow = TreeRow.GetItems()[0];
		If SubordinateRow.ServiceLine Then
			If TreeOfLinksIsExpandedString <> 0 Then
				Cancel = True;
				Return;
			EndIf;
			SubordinateRow.LinkedObject = NStr("vi = 'Đang chờ lấy dữ liệu từ 1C:Document Management...';
												|ru = 'Ожидается получение данных из 1С:Документооборота...';
												|en = 'Expecting data from 1C:Document Management...'; fa = 'Expecting data from 1C:Document Management...';
												|it = 'Expecting data from 1C:Document Management...';
												|pl = 'Expecting data from 1C:Document Management...';
												|tr = '1C:Document Management üzerinden veri alınması bekleniyor...'");
			TreeOfLinksIsExpandedString = TreeRow.GetID();
			UpdateConnections(False);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure LinkTreeBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	If Not CreatingLinksIsAvailable Then
		Return;
	EndIf;
	
	InitialObjectBefore = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		ObjectBeforeID,
		ObjectBeforeType,
		ObjectBefore,,
		MapItemDMNavigationLink);
	IntegrationWith1CDocumentManagement3Client.StartDeletingLink(Items.LinkTree, InitialObjectBefore);
	
EndProcedure

&AtClient
Procedure LinkTreeOnActivateRow(Item)
	
	If Item.CurrentRow = Undefined Or Item.CurrentRow = LinkTreeStringKey Then
		Return;
	EndIf;
	LinkTreeStringKey = Item.CurrentRow;
	
	LinkCanBeDeleted = IntegrationWith1CDocumentManagement3Client.LinkCanBeDeleted(Items.LinkTree.CurrentData);
	Items.LinkTreeDelete.Enabled = LinkCanBeDeleted;
	Items.LinkTreeContextMenuDelete.Enabled = LinkCanBeDeleted;
	
	RelationshipTreeCurrentData = IntegrationWith1CDocumentManagement3Client.LinkTreeCurrentDataToView(
		Items.LinkTree);
	If RelationshipTreeCurrentData = Undefined Then
		Return;
	EndIf;
	
	IsReferenceObject = ValueIsFilled(RelationshipTreeCurrentData.LinkedObjectID)
		And ValueIsFilled(RelationshipTreeCurrentData.LinkedObjectType);
	IsFile = (RelationshipTreeCurrentData.LinkedObjectType = "DMFile");
	
	Items.LinkTreeOpen.Enabled = IsReferenceObject;
	Items.LinkTreeContextMenuOpenButton.Enabled = IsReferenceObject;
	Items.LinkTreeChange.Enabled = IsReferenceObject;
	Items.LinkTreeContextMenuEditButton.Enabled = IsReferenceObject;
	
	Items.SaveLinkTreeAs.Enabled = IsFile;
	Items.LinkTreeContextMenuSaveAsButton.Enabled = IsFile;
	Items.LinkTreePrintFiles.Enabled = IsFile;
	Items.LinkTreeContextMenuPrintFilesButton.Enabled = IsFile;
	
	HTMLLinkPresentation = IntegrationWith1CDocumentManagementCoreClientServer.DownloadMessage();
	Items.LinkViewPages.CurrentPage = Items.HTMLLinkGroupPage;
	Items.GroupPreviewCut.Visible = False;
	AttachIdleHandler("UpdatePreviewOfWaitHandlerConnection", 0.2, True);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFilesTree

&AtClient
Procedure FilesTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	OpenCurrentFileInFileTreeForReading();
	
EndProcedure

&AtClient
Procedure FilesTreeBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	Cancel = True;
	
	If (Not StateAllowsFileAddition And Not StateAllowsAddingScannedCopy) Or SignedWithDS Then
		Return;
	EndIf;
	
	StartAddingFile();
	
EndProcedure

&AtClient
Procedure FilesTreeBeforeRowChange(Item, Cancel)
	
	If Items.FilesTree.CurrentItem = Items.Original Then
		Return;
	EndIf;
	
	Cancel = True;
	
	FileTreeOpenCard();
	
EndProcedure

&AtClient
Procedure FilesTreeBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined
			Or CurrentData.Type <> "DMFile"
			Or Not StateAllowsFileDeletion
			Or CurrentData.IsBeingEdited
			Or SignedWithDS Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("AfterDeletingFiles", ThisObject);
	
	Selected_Files = IntegrationWith1CDocumentManagementCoreClient.Selected_Files(
		FilesTree,
		Items.FilesTree.SelectedRows);
	IntegrationWith1CDocumentManagementCoreClient.MarkForDeletionUncheckFiles(
		Selected_Files,
		CurrentData.DeletionMark,
		Notification,
		ObjectBeforeID,
		UUID);
	
EndProcedure

&AtClient
Procedure FilesTreeOnActivateRow(Item)
	
	If Item.CurrentRow = Undefined Or Item.CurrentRow = FileTreeStringKey Then
		Return;
	EndIf;
	FileTreeStringKey = Item.CurrentRow;
	
	SetAvailabilityOfFileListCommands();
	
	PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.DownloadMessage();
	Items.ViewPagesOverview.CurrentPage = Items.HTMLOverviewGroupPage;
	Items.GroupPreviewStrippedDownReview.Visible = False;
	AttachIdleHandler("UpdatePreviewOfWaitHandlerFile", 0.2, True);
	
EndProcedure

&AtClient
Procedure FilesTreeDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	DragParameters.Action = DragAction.Cancel;
	
	FilesArray = IntegrationWith1CDocumentManagement3Client.ArrayOfFilesFromDragAndDropOptions(
		FilesTree,
		DragParameters.Value);
	
	If FilesArray.Count() = 0 Then
		Return;
	EndIf;
	
	If UseFileRoles Then
		NewRoleOfIDFile = IntegrationWith1CDocumentManagement3Client.CurCurrentFileRole(FilesTree, String);
	Else
		NewRoleOfIDFile = "";
	EndIf;
	
	For Each FileToDrag In FilesArray Do
		If TypeOf(FileToDrag) = Type("Structure")
				And (NewRoleOfIDFile = ""
					Or FileToDrag.FileRoleID = NewRoleOfIDFile
					Or FileToDrag.Type <> "DMFile") Then
			Return;
		EndIf;
	EndDo;
	
	DragParameters.Action = DragAction.Move;
	
EndProcedure

&AtClient
Procedure FilesTreeDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
	If UseFileRoles Then
		FileRoleID = IntegrationWith1CDocumentManagement3Client.CurCurrentFileRole(
			FilesTree, String);
	EndIf;
	
	FilesArray = IntegrationWith1CDocumentManagement3Client.ArrayOfFilesFromDragAndDropOptions(
		FilesTree,
		DragParameters.Value);
	
	If FilesArray.Count() = 0 Then
		Return;
	EndIf;
	
	If TypeOf(FilesArray[0]) = Type("Structure") Then
		IntegrationWith1CDocumentManagement3Client.ReplaceRoleOfFiles(
			FilesArray,
			FileRoleID,
			ObjectBeforeID,
			UUID);
	ElsIf TypeOf(FilesArray[0]) = Type("File") Then
		NotificationParameters = New Structure("FilesArray, FileRoleID", FilesArray, FileRoleID);
		CallbackDescription = New CallbackDescription("FilesDragCompletion", ThisObject, NotificationParameters);
		If ValueIsFilled(ObjectBeforeID) Then
			RunCallback(CallbackDescription, Undefined);
		Else
			IntegrationWith1CDocumentManagementCoreClient.StartSearchingForARelatedObjectDM(
				ExternalObject,
				CallbackDescription,,,
				False);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Async Procedure FilesDragCompletion(Val Result, Val NotificationParameters) Export
	
	YouNeedToAddScannedCopy =
		Await IntegrationWith1CDocumentManagementCoreClient.YouNeedToAddScannedCopyAsync(
			StateAllowsAddingScannedCopy,
			StateAllowsFileAddition);
	
	If YouNeedToAddScannedCopy = DialogReturnCode.Yes Then
		ParametersForStartOfCreation = FileCreationStartParameters();
		ParametersForStartOfCreation.CurrentFile.FileRoleID = NotificationParameters.FileRoleID;
		IntegrationWith1CDocumentManagementCoreClient.CreateFileFromDiskByDraggingAndDropping(
			NotificationParameters.FilesArray,
			ParametersForStartOfCreation);
	EndIf;
	
EndProcedure

&AtClient
Async Procedure OriginalOnChange(Val Item)
	
	FileTreeCurrentData = Items.FilesTree.CurrentData;
	If FileTreeCurrentData = Undefined Then
		Return;
	EndIf;
	
	FileBeingModified = New Structure;
	FileBeingModified.Insert("Description", FileTreeCurrentData.Description);
	FileBeingModified.Insert("Type", FileTreeCurrentData.Type);
	FileBeingModified.Insert("ID", FileTreeCurrentData.ID);
	FileBeingModified.Insert("LongDesc", FileTreeCurrentData.LongDesc);
	FileBeingModified.Insert("IsOriginal", FileTreeCurrentData.IsOriginal);
	
	If FileTreeCurrentData.IsOriginal Then
		SettingAttributeIsOriginalIsPossible =
			Await IntegrationWith1CDocumentManagementCoreClient.SettingAttributeIsOriginalIsPossible(
				FileTreeCurrentData.TemplateID,
				FileTreeCurrentData.Extension,
				ListOfExtensionsOfScannedCopiesOfOriginals);
		If SettingAttributeIsOriginalIsPossible Then
			EditAttributeIsOriginal(FileBeingModified);
		Else
			FileTreeCurrentData.IsOriginal = False;
		EndIf;
	Else
		EditAttributeIsOriginal(FileBeingModified);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ActionsToFillIn(Command)
	
	OperationType = IntegrationWith1CDocumentManagement3ClientServer.TypeOfOperationWithProcessing();
	OperationType.Fill = True;
	ActionWithProcessing(OperationType);
	
EndProcedure

&AtClient
Procedure ActionsToStop(Command)
	
	OperationType = IntegrationWith1CDocumentManagement3ClientServer.TypeOfOperationWithProcessing();
	If ProcessingState = "Executing" Then
		OperationType.Stop = True;
	Else
		OperationType.Continue = True;
	EndIf;
	
	ActionWithProcessing(OperationType);
	
EndProcedure

&AtClient
Procedure ActionsSend(Command)
	
	If ProcessingState = "Executing" Or ProcessingState = "Stopped" Then
		CallbackDescription = New CallbackDescription(
			"ContinueInterruptingProcessingAfterEnteringReasonForInterruption",
			ThisObject);
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement3.Form.TerminateObjectProcessing",
			New Structure("ObjectBefore, ObjectBeforeType", ObjectBefore, ObjectBeforeType),
			ThisObject,,,,
			CallbackDescription,
			FormWindowOpeningMode.LockOwnerWindow);
	Else
		OperationType = IntegrationWith1CDocumentManagement3ClientServer.TypeOfOperationWithProcessing();
		OperationType.ToBegin = True;
		ActionWithProcessing(OperationType);
	EndIf;
	
EndProcedure

&AtClient
Procedure ActionsRestartProcessing(Command)
	
	OperationType = IntegrationWith1CDocumentManagement3ClientServer.TypeOfOperationWithProcessing();
	OperationType.Restart = True;
	ActionWithProcessing(OperationType);
	
EndProcedure

&AtClient
Procedure ActionsProtocolOfDisagreement(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Print") Then
		IntegrationWith1CDocumentManagementCoreClient.ExecutePrintCommand(
			"DataProcessor.IntegrationWith1CDocumentManagement3",
			"ProtocolOfDisagreements",
			ExternalObject,
			ThisObject);
	Else
		MessageText = StrTemplate(
			NStr("vi = 'Cấu hình %1 không hỗ trợ in biên bản chênh lệch.
				|Có thể tạo biên bản chênh lệch ở bên 1C:Document Management.';
				|ru = 'Конфигурация %1 не поддерживает печать протокола разногласий.
				|Сформировать протокол разногласий можно на стороне 1С:Документооборот.';
				|en = 'The %1 application does not support printing of a protocol of disagreements.
				|You can generate a protocol of disagreements in 1C:Document Management.'; fa = 'The %1 application does not support printing of a protocol of disagreements.
				|You can generate a protocol of disagreements in 1C:Document Management.';
				|it = 'Конфигурация %1 не поддерживает печать протокола разногласий.
				|Сформировать протокол разногласий можно на стороне 1С:Документооборот.';
				|pl = 'The %1 application does not support printing of a protocol of disagreements.
				|You can generate a protocol of disagreements in 1C:Document Management.';
				|tr = '""%1"" konfigürasyonu, anlaşmazlık protokolünün yazdırılmasını desteklememektedir.
				|1C:Document Management tarafında anlaşmazlık protokolü oluşturulabilir.'"),
			AbbreviatedNameOfConfiguration);
		ShowMessageBox(, MessageText);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckSignatureTree(Command)
	
	SelectedSignatures = IntegrationWith1CDocumentManagementCoreClient.SelectedSignatures(
		Items.SignatureTree.SelectedRows,
		SignatureTree);
	SignatureTable = IntegrationWith1CDocumentManagementCoreClientServer.SignatureTable(SignatureTree);
	
	Notification = New CallbackDescription("VerifySignatureCompletion", ThisObject);
	IntegrationWith1CDocumentManagementCoreClient.VerifySignatures(
		SignatureTable,
		AddressOfObjectSBinaryData,
		Notification,
		SelectedSignatures);
	
EndProcedure

&AtClient
Procedure SignatureTreeCheckEverything(Command)
	
	SignatureTable = IntegrationWith1CDocumentManagementCoreClientServer.SignatureTable(SignatureTree);
	
	Notification = New CallbackDescription("VerifySignatureCompletion", ThisObject);
	IntegrationWith1CDocumentManagementCoreClient.VerifySignatures(
		SignatureTable,
		AddressOfObjectSBinaryData,
		Notification);
	
EndProcedure

&AtClient
Procedure LinkTreePrintFiles(Command)
	
#If WebClient Then
	ShowMessageBox(, NStr("vi = 'Trên Web-client không hỗ trợ in tệp.';
							|ru = 'В Веб-клиенте печать файлов не поддерживается.';
							|en = 'Printing of files is not supported in the web client.'; fa = 'Printing of files is not supported in the web client.';
							|it = 'Non è supportata la stampa di file nel client web.';
							|pl = 'W kliencie webowym drukowanie plików nie jest obsługiwane.';
							|tr = 'Web istemcisi, dosyaların yazdırılmasını desteklemez.'"));
	Return;
#EndIf
	
	Selected_Files = New Array;
	
	For Each SelectedRow In Items.LinkTree.SelectedRows Do
		Data = LinkTree.FindByID(SelectedRow);
		If Data.LinkedObjectType <> "DMFileRole" Then
			FileData = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
				Data.LinkedObject,
				Data.LinkedObjectID,
				Data.LinkedObjectType,
				Data.FileExtention,
				Data.LinkedObjectID);
			Selected_Files.Add(FileData);
		EndIf;
	EndDo;
	
	IntegrationWith1CDocumentManagementCoreClient.PrintFiles(
		Selected_Files,
		Items.LinkTree.SelectedRows,
		UUID);
	
EndProcedure

&AtClient
Procedure SaveLinkTreeAs(Command)
	
	RelationshipTreeCurrentData = IntegrationWith1CDocumentManagement3Client.LinkTreeCurrentDataToView(
		Items.LinkTree);
	If RelationshipTreeCurrentData = Undefined Or RelationshipTreeCurrentData.LinkedObjectType <> "DMFile" Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.SaveFileAs(
		RelationshipTreeCurrentData.LinkedObjectID,
		RelationshipTreeCurrentData.LinkedObject,
		RelationshipTreeCurrentData.FileExtention,
		UUID);
	
EndProcedure

&AtClient
Procedure PDFDocumentOverviewLeftTurn(Command)
	
	Items["PDFDocumentOverviewField"].Orientation = Items["PDFDocumentOverviewField"].Orientation - 90;
	
EndProcedure

&AtClient
Procedure PDFDocumentLinksTurnLeft(Command)
	
	Items["PDFDocumentCommunicationField"].Orientation = Items["PDFDocumentCommunicationField"].Orientation - 90;
	
EndProcedure

&AtClient
Procedure PDFDocumentOverviewTurnRight(Command)
	
	Items["PDFDocumentOverviewField"].Orientation = Items["PDFDocumentOverviewField"].Orientation + 90;
	
EndProcedure

&AtClient
Procedure PDFDocumentCommunicationTurnRight(Command)
	
	Items["PDFDocumentCommunicationField"].Orientation = Items["PDFDocumentCommunicationField"].Orientation + 90;
	
EndProcedure

&AtClient
Procedure PDFDocumentOverviewZoomIn(Command)
	
	Items["PDFDocumentOverviewField"].Scale = Items["PDFDocumentOverviewField"].Scale + 10;
	
EndProcedure

&AtClient
Procedure PDFDocumentLinksZoomIn(Command)
	
	Items["PDFDocumentCommunicationField"].Scale = Items["PDFDocumentCommunicationField"].Scale + 10;
	
EndProcedure

&AtClient
Procedure PDFDocumentOverviewReduce(Command)
	
	If Items["PDFDocumentOverviewField"].Scale <= 10 Then
		Return;
	EndIf;
	
	Items["PDFDocumentOverviewField"].Scale = Items["PDFDocumentOverviewField"].Scale - 10;
	
EndProcedure

&AtClient
Procedure PDFDocumentLinksReduce(Command)
	
	If Items["PDFDocumentCommunicationField"].Scale <= 10 Then
		Return;
	EndIf;
	
	Items["PDFDocumentCommunicationField"].Scale = Items["PDFDocumentCommunicationField"].Scale - 10;
	
EndProcedure

&AtClient
Procedure CopyNavigationLinkToClipboard(Command)
	
	If ClipboardTools.CanUse() And ValueIsFilled(MapItemDMNavigationLink) Then
		ClipboardItem = New ClipboardItem(
			ClipboardDataStandardFormat.Text,
			MapItemDMNavigationLink);
		ClipboardTools.PutDataAsync(ClipboardItem);
	EndIf;
	
EndProcedure

&AtClient
Procedure FamiliarizationSheet(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Print") Then
		IntegrationWith1CDocumentManagementCoreClient.ExecutePrintCommand(
			"DataProcessor.IntegrationWith1CDocumentManagement3",
			"ExaminationSheet",
			ExternalObject,
			ThisObject);
	Else
		MessageText = StrTemplate(
			NStr("vi = 'Cấu hình %1 không hỗ trợ tờ tham khảo.
				|Có thể tạo tờ tham khảo ở bên 1C:Document Management.';
				|ru = 'Конфигурация %1 не поддерживает печать листа ознакомления.
				|Сформировать лист ознакомления можно на стороне 1С:Документооборот.';
				|en = 'The %1 application does not support the preview sheet printing.
				|You can generate a preview sheet in 1C:Document Management.'; fa = 'The %1 application does not support the preview sheet printing.
				|You can generate a preview sheet in 1C:Document Management.';
				|it = 'Конфигурация %1 не поддерживает печать листа ознакомления.
				|Сформировать лист ознакомления можно на стороне 1С:Документооборот.';
				|pl = 'The %1 application does not support the preview sheet printing.
				|You can generate a preview sheet in 1C:Document Management.';
				|tr = '""%1"" konfigürasyonu, inceleme sayfasının yazdırılmasını desteklememektedir.
				|1C:Document Management tarafında inceleme sayfası oluşturulabilir.'"),
			AbbreviatedNameOfConfiguration);
		ShowMessageBox(, MessageText);
	EndIf;
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	StartUpdatingForm(Items.GroupPages.CurrentPage);
	
EndProcedure

&AtClient
Procedure UpdateActionsCommand(Command)
	
	UpdateDataProcessor();
	
EndProcedure

&AtClient
Procedure UpdateReviewCommand(Command)
	
	UpdateOverview();
	
EndProcedure

&AtClient
Procedure UpdateLinkPreviewCommand(Command)
	
	UpdateLinkPreview(True);
	
EndProcedure

&AtClient
Procedure UpdateConnectionsCommand(Command)
	
	UpdateConnections(True);
	
EndProcedure

&AtClient
Procedure OpenSignature(Command)
	
	IntegrationWith1CDocumentManagement3Client.OpenSignature(
		Items.SignatureTree.CurrentData,
		FilesTree,
		UseFileRoles,
		UUID);
	
EndProcedure

&AtClient
Procedure OpenALink(Command)
	
	RelationshipTreeCurrentData = IntegrationWith1CDocumentManagement3Client.LinkTreeCurrentDataToView(
		Items.LinkTree);
	IntegrationWith1CDocumentManagement3Client.OpenLinkedObjectForViewing(
		RelationshipTreeCurrentData,
		UUID);
	
EndProcedure

&AtClient
Procedure SwitchPreviewOfLinks(Command)
	
	PreviewLinks = Not PreviewLinks;
	Items.LinkTreePreview.Check = PreviewLinks;
	Items.LinkViewPages.Visible = PreviewLinks;
	CommonServerCall.CommonSettingsStorageSave(
		"ObjectsLinksBefore",
		"PreviewBIDFiles",
		PreviewLinks);
	UpdateLinkPreview();
	
EndProcedure

&AtClient
Procedure PrintApprovalSheet(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Print") Then
		IntegrationWith1CDocumentManagementCoreClient.ExecutePrintCommand(
			"DataProcessor.IntegrationWith1CDocumentManagement3",
			"ApprovalSheet",
			ExternalObject,
			ThisObject);
	Else
		IntegrationWith1CDocumentManagementCoreClientOverridable.ExecutePrintApprovalSheetCommand(
			ExternalObject,
			ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure PrintHistoryApprovalSheet(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Print") Then
		IntegrationWith1CDocumentManagementCoreClient.ExecutePrintCommand(
			"DataProcessor.IntegrationWith1CDocumentManagement3",
			"ApprovalSheetWithHistory",
			ExternalObject,
			ThisObject);
	Else
		MessageText = StrTemplate(
			NStr("vi = 'Cấu hình %1 không hỗ trợ tờ thống nhất có lịch sử.
				|Có thể tạo tờ thống nhất có lịch sử ở bên 1C:Document Management.';
				|ru = 'Конфигурация %1 не поддерживает печать листа согласования с историей.
				|Сформировать лист согласования с историей можно на стороне 1С:Документооборот.';
				|en = 'The %1 application does not support printing of the approval sheet with history.
				|You can generate an approval sheet with history in 1C:Document Management.'; fa = 'The %1 application does not support printing of the approval sheet with history.
				|You can generate an approval sheet with history in 1C:Document Management.';
				|it = 'Конфигурация %1 не поддерживает печать листа согласования с историей.
				|Сформировать лист согласования с историей можно на стороне 1С:Документооборот.';
				|pl = 'The %1 application does not support printing of the approval sheet with history.
				|You can generate an approval sheet with history in 1C:Document Management.';
				|tr = '""%1"" konfigürasyonu, geçmişi içeren mutabakat sayfasının yazdırılmasını desteklememektedir.
				|1C:Document Management tarafında geçmişi içeren mutabakat sayfası oluşturulabilir.'"),
			AbbreviatedNameOfConfiguration);
		ShowMessageBox(, MessageText);
	EndIf;
	
EndProcedure

&AtClient
Procedure SignDocument(Command)
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("DataArrayToStoreInDatabase", New Array);
	NotificationParameters.Insert("AddressesArray", New Array);
	Notification = New CallbackDescription("SignDocumentCompletion", ThisObject, NotificationParameters);
	
	ObjectDocumentManagement =
		IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
			ObjectBeforeID,
			ObjectBeforeType,
			ObjectBefore,
			StrTemplate(NStr("ru = '%1 (Документ предприятия)';
							|vi = '%1 (Enterprise document)';
							|en = '%1 (Enterprise document)'; fa = '%1 (Enterprise document)';
							|it = '%1 (Enterprise document)';
							|pl = '%1 (Enterprise document)';
							|tr = '%1 (İşletme belgesi)'"), ObjectBefore));
	
	Files = New Array;
	For Each String In FilesTree.GetItems() Do
		If String.Type = "DMFile" And Not String.DeletionMark Then
			Files.Add(String);
		EndIf;
		For Each Substring In String.GetItems() Do
			If Substring.Type = "DMFile" And Not Substring.DeletionMark Then
				Files.Add(Substring);
			EndIf;
		EndDo;
	EndDo;
	
	IntegrationWith1CDocumentManagementCoreClient.StartCreatingItemSSignature(
		ObjectDocumentManagement,
		Files,
		AddressOfObjectSBinaryData,
		Notification);
	
EndProcedure

&AtClient
Procedure ShowAllConnections(Command)
	
	OnlyImportantConnections = False;
	Items.LinkTreeShowAllLinks.Enabled = False;
	Items.InfoCommunicationGroup.Visible = False;
	
	UpdateConnections(True);
	
EndProcedure

&AtClient
Procedure SaveSignature(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.SaveSignature(Items.SignatureTree.CurrentData);
	
EndProcedure

&AtClient
Procedure DeleteSignature(Command)
	
	Notification = New CallbackDescription("DeleteSignatureCompletion", ThisObject);
	IntegrationWith1CDocumentManagement3Client.DeleteSignature(
		Items.SignatureTree.SelectedRows,
		SignatureTree,
		ObjectBeforeID,
		Notification,
		UUID);
	
EndProcedure

&AtClient
Async Procedure FilesInsertImageFromBuffer(Val Command)
	
	YouNeedToAddScannedCopy =
		Await IntegrationWith1CDocumentManagementCoreClient.YouNeedToAddScannedCopyAsync(
			StateAllowsAddingScannedCopy,
			StateAllowsFileAddition);
	
	If YouNeedToAddScannedCopy = DialogReturnCode.Yes Then
		ParametersForStartOfCreation = FileCreationStartParameters();
		If UseFileRoles Then
			ParametersForStartOfCreation.CurrentFile.FileRoleID = IntegrationWith1CDocumentManagement3Client.CurCurrentFileRole(
				FilesTree,
				Items.FilesTree.CurrentRow);
		EndIf;
		IntegrationWith1CDocumentManagementCoreClient.CreateFileFromBuffer(ParametersForStartOfCreation);
	EndIf;
	
EndProcedure

&AtClient
Procedure FilesSelectFileRole(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("FilesOwner", ObjectBeforeID);
	FormParameters.Insert("AvailableRoles", AvailableRoles);
	FormParameters.Insert("IdOfOwnerSForm", UUID);
	FormParameters.Insert("UseFileRoles", UseFileRoles);
	
	IntegrationWith1CDocumentManagement3Client.ChooseFileRole(FilesTree, Items.FilesTree, FormParameters);
	
EndProcedure

&AtClient
Procedure FilesAddPrintedForm(Command)
	
	If UseFileRoles Then
		FileRoleID = IntegrationWith1CDocumentManagement3Client.CurCurrentFileRole(
			FilesTree,
			Items.FilesTree.CurrentRow);
	Else
		FileRoleID = "";
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ObjectIS", ExternalObject);
	FormParameters.Insert("ObjectIDDM", ObjectBeforeID);
	FormParameters.Insert("ObjectTypeDM", ObjectBeforeType);
	FormParameters.Insert("FileRoleID", FileRoleID);
	FormParameters.Insert("UniqueOwnerID", UUID);
	AdditionForm = OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.InsertPrintForm",
		FormParameters,
		ThisObject,,,,,
		FormWindowOpeningMode.LockWholeInterface);
	If AdditionForm = Undefined Then
		ObjectTypeArray = StrSplit(FileCatalogType, ".");
		WarningText = StrTemplate(NStr("ru = '%1 ""%2"" не имеет печатных форм.';
										|vi = '%1 ""%2"" has no print forms.';
										|en = '%1 ""%2"" has no print forms.'; fa = '%1 ""%2"" has no print forms.';
										|it = '%1 ""%2"" has no print forms.';
										|pl = '%1 ""%2"" has no print forms.';
										|tr = '%1 ""%2"" yazdırılabilir formları mevcut değil.'"),
			ObjectTypeArray[0],
			String(ExternalObject));
		ShowMessageBox(, WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure FilesAddDigitalSignatureFromFile(Command)
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.Type <> "DMFile" Then
		Return;
	EndIf;
	
	FileProperties = CompletedFileProperties(CurrentData);
	
	IntegrationWith1CDocumentManagementCoreClient.StartAddingItemsFromFile(FileProperties);
	
EndProcedure

&AtClient
Procedure FilesFinishEditing(Command)
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.Type <> "DMFile" Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.EndFileEditing(
		CurrentData.ID,
		CurrentData.Description,
		CurrentData.Extension,
		UUID,,
		ObjectBeforeID);
	
EndProcedure

&AtClient
Procedure FilesImportFiles(Command)
	
	CreateFileFromDisk();
	
EndProcedure

&AtClient
Procedure FilesPrint(Command)
	
#If WebClient Then
	ShowMessageBox(, NStr("ru = 'В Веб-клиенте печать файлов не поддерживается.';
							|vi = 'Printing of files is not supported in the web client.';
							|en = 'Printing of files is not supported in the web client.'; fa = 'Printing of files is not supported in the web client.';
							|it = 'Non è supportata la stampa di file nel client web.';
							|pl = 'W kliencie webowym drukowanie plików nie jest obsługiwane.';
							|tr = 'Web istemcisi, dosyaların yazdırılmasını desteklemez.'"));
	Return;
#EndIf
	
	IntegrationWith1CDocumentManagementCoreClient.PrintFiles(
		FilesTree,
		Items.FilesTree.SelectedRows,
		UUID);
	
EndProcedure

&AtClient
Procedure UpdateFilesFromFileOnDisk(Command)
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.Type <> "DMFile" Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.UpdateFromFileOnHardDrive(
		CurrentData.ID,
		CurrentData.Description,
		CurrentData.Extension,
		CurrentData.ModificationDate,
		UUID,,
		ObjectBeforeID);
	
EndProcedure

&AtClient
Procedure FilesUpdatePreview(Command)
	
	RefreshFilePreview(True);
	
EndProcedure

&AtClient
Procedure ReleaseFiles(Command)
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.Type <> "DMFile" Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.UndoFileEditing(
		CurrentData.ID,,
		ObjectBeforeID,
		UUID);
	
EndProcedure

&AtClient
Procedure FilesOpenFile(Command)
	
	OpenCurrentFileInFileTreeForReading();
	
EndProcedure

&AtClient
Procedure FilesSignFile(Command)
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.Type <> "DMFile" Then
		Return;
	EndIf;
	
	FileProperties = CompletedFileProperties(CurrentData);
	
	IntegrationWith1CDocumentManagementCoreClient.SignFile(FileProperties);
	
EndProcedure

&AtClient
Procedure FilesShowDeleted(Command)
	
	FilesShowDeleted = Not FilesShowDeleted;
	Items.FilesShowDeleted.Check = FilesShowDeleted;
	
	ReviewIsFull = False;
	OutputIdleWindow = True;
	
	StartUpdatingForm(Items.OverviewPage, OutputIdleWindow);
	
EndProcedure

&AtClient
Procedure EditFiles(Command)
	
	OpenCurrentFileInFileTreeForEditing();
	
EndProcedure

&AtClient
Procedure FilesSaveWithDigitalSignature(Command)
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.Type <> "DMFile" Then
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

&AtClient
Procedure FilesSaveChanges(Command)
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.Type <> "DMFile" Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.SaveChangesToEditedFile(
		CurrentData.ID,
		CurrentData.Description,
		CurrentData.Extension,
		UUID,,
		ObjectBeforeID);
	
EndProcedure

&AtClient
Procedure SaveFilesAs(Command)
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Selected_Files = New Array;
	
	If Items.FilesTree.SelectedRows.Count() > 1 Then
		For Each RowSelected In Items.FilesTree.SelectedRows Do
			RowData = Items.FilesTree.RowData(RowSelected);
			If IntegrationWith1CDocumentManagement3Client.ObjectCanBeSavedToDisk(RowData.Type) Then
				Selected_Files.Add(FileDataToSave(RowData));
			EndIf;
		EndDo;
	Else
		If IntegrationWith1CDocumentManagement3Client.ObjectCanBeSavedToDisk(CurrentData.Type) Then
			Selected_Files.Add(FileDataToSave(CurrentData));
		EndIf;
	EndIf;
	
	If Selected_Files.Count() = 0 Then
		ShowMessageBox(, NStr("ru = 'Выберите файл.';
								|vi = 'Select a file.';
								|en = 'Select a file.'; fa = 'Select a file.';
								|it = 'Выберите файл.';
								|pl = 'Select a file.';
								|tr = 'Dosya ekle.'"));
		Return;
	EndIf;
	
	SavingParameters = New Structure;
	SavingParameters.Insert("RemainingFiles", New Array);
	SavingParameters.Insert("UseVisualizationOfItemInstanceStamp", True);
	For IndexOf = 0 To Selected_Files.UBound() Do
		If IndexOf = 0 Then
			SavingParameters.Insert("CurrentFile", Selected_Files[IndexOf]);
		Else
			SavingParameters.RemainingFiles.Add(Selected_Files[IndexOf]);
		EndIf;
	EndDo;
	SavingParameters.Insert("FormUniqueID", UUID);
	SavingParameters.Insert("CallbackDescription", Undefined);
	
	IntegrationWith1CDocumentManagementCoreClient.SaveFilesAsStart(SavingParameters);
	
EndProcedure

#EndRegion

#Region Private

#Region Client

&AtClient
Procedure RestorePositionInFileList()
	
	// Open the tree.
	For Each LineToDisclosure In LinesForDisclosure Do
		String = IntegrationWith1CDocumentManagement3Client.FileTreeStringByID(
			FilesTree,
			UseFileRoles,
			LineToDisclosure);
		If String <> Undefined Then
			Items.FilesTree.Expand(String.GetID(), True);
		EndIf;
	EndDo;
	
	CurLineIsSet = False;
	
	// if the Cur row id is passed, we will set the Cur row to it.
	If ValueIsFilled(CurRowId_) Then
		String = IntegrationWith1CDocumentManagement3Client.FileTreeStringByID(
			FilesTree,
			UseFileRoles,
			CurRowId_,
			CurCurrentStringType);
		If String <> Undefined Then
			Items.FilesTree.CurrentRow = String.GetID();
			CurLineIsSet = True;
		EndIf;
	EndIf;
	
	// If the current line ID is not passed, we will set the current line of the document itself.
	If Not CurLineIsSet And FilesTree.GetItems().Count() > 0 Then
		Items.FilesTree.CurrentRow = FilesTree.GetItems()[0].GetID();
		CurLineIsSet = True;
	EndIf;
	
EndProcedure

&AtClient
Function FileDataToSave(FilesTreeRow)
	
	If FilesTreeRow.Type = "DMIncomingElectronicDocument"
			Or FilesTreeRow.Type = "DMOutgoingElectronicDocument" Then
		Extension = "xml";
	Else
		Extension = FilesTreeRow.Extension;
	EndIf;
	
	FileData = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
		FilesTreeRow.Description,
		FilesTreeRow.ID,
		FilesTreeRow.Type,
		Extension,
		FilesTreeRow.FileRoleID);
	
	If FilesTreeRow.Type = "DMIncomingElectronicDocument"
			Or FilesTreeRow.Type = "DMOutgoingElectronicDocument" Then
		FileData.RefToBinaryFileData =
			IntegrationWith1CDocumentManagement3ServerCall.GetDocumentFileAndPutItInRepository(
				FilesTreeRow.ID,
				FilesTreeRow.Type,
				UUID,
				Extension);
	EndIf;
	
	Return FileData;
	
EndFunction

&AtClient
Procedure DecorationObjectSelectByClickingAfterSelectingType(Result, AdditionalParameters) Export
	
	If TypeOf(Result) <> Type("String") Or Result = "" Then
		Return;
	EndIf;
	
	DocumentTypeSelection = New Structure("Value, ValueID",
		DocumentTypeFromRules,
		DocumentTypeFromRulesID);
	Filter = IntegrationWith1CDocumentManagementCoreClient.SelectionWhenSelectingLinkedObject(
		ExternalObject,
		Result,
		DocumentTypeSelection);
	IntegrationWith1CDocumentManagement3Client.SelectAValueFromTheList(
		Result,
		"ObjectBefore",
		ThisObject,
		Filter);
	
EndProcedure

&AtClient
Procedure FileTreeOpenCard()
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.Type <> "DMFile" Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure("EditingAllowed", StateAllowsFileEditing);
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(
		CurrentData.Type,
		CurrentData.ID,
		ThisObject,
		AdditionalParameters);
	
EndProcedure

&AtClient
Procedure AddingFile(Result, Var_Parameters) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	If Result = 1 Then
		CreateFileFromDisk();
	ElsIf Result = 2 Then
		// Creating a template file.
		Notification = New CallbackDescription("AddingFileCompletion", ThisObject);
		OpenForm(
			"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingFile",,
			ThisObject,,,,
			Notification,
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure AddingFileCompletion(Result, Var_Parameters) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	If UseFileRoles Then
		FileRoleID = IntegrationWith1CDocumentManagement3Client.CurCurrentFileRole(
			FilesTree,
			Items.FilesTree.CurrentRow);
	Else
		FileRoleID = "";
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Owner", ObjectBefore);
	AdditionalParameters.Insert("OwnerID", ObjectBeforeID);
	AdditionalParameters.Insert("OwnerType", ObjectBeforeType);
	AdditionalParameters.Insert("FileOwner", ExternalObject);
	AdditionalParameters.Insert("TemplateID", Result.AttributeID);
	AdditionalParameters.Insert("FileRoleID", FileRoleID);
	AdditionalParameters.Insert("EditingAllowed", StateAllowsFileEditing);
	
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(
		"DMFile",
		"",
		ThisObject,
		AdditionalParameters);
	
EndProcedure

&AtClient
Function Task_By_ID(TaskActionID, TaskActionType, ProcessingTreeRows)
	
	For Each String In ProcessingTreeRows Do
		
		Task_By_ID = Task_By_ID(TaskActionID, TaskActionType, String.GetItems());
		If Task_By_ID <> Undefined Then
			Return Task_By_ID;
		EndIf;
		
		If String.TaskActionID = TaskActionID And String.TaskActionType = TaskActionType Then
			Return String;
		EndIf;
		
	EndDo;
	
	Return Undefined;
	
EndFunction

&AtClient
Function CompletedFileProperties(CurrentData)
	
	FileProperties = IntegrationWith1CDocumentManagementCoreClientServer.FileProperties();
	
	FileID = CurrentData.ID;
	SignatureTable = IntegrationWith1CDocumentManagementCoreClientServer.SignatureTable(
		SignatureTree,,
		FileID);
	FileSignatureData = IntegrationWith1CDocumentManagementCoreClient.DataOfSignatures(SignatureTable);
	
	FileProperties.FileID = CurrentData.ID;
	FileProperties.FileName = CurrentData.Description;
	FileProperties.FileDetails = CurrentData.LongDesc;
	FileProperties.IsBeingEdited = CurrentData.IsBeingEdited;
	FileProperties.Encrypted = CurrentData.Encrypted;
	FileProperties.FileSignatureData = FileSignatureData;
	FileProperties.FormUniqueID = UUID;
	FileProperties.FileOwner = ObjectBeforeID;
	
	Return FileProperties;
	
EndFunction

&AtClient
Procedure StartAddingFile()
	
	CallbackDescription = New CallbackDescription("AddingFile", ThisObject);
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.CreatingNewFile",,,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure UpdateSceneryOfObjectTO(OnOpen = False)
	
	ObjectIsFilledUpTo = ValueIsFilled(ObjectBeforeID);
	NavigationLinkIsFull = ValueIsFilled(MapItemDMNavigationLink);
	
	Items.DecorationObjectCreate.Visible = Not ObjectIsFilledUpTo;
	Items.DecorationObjectOr.Visible = Not ObjectIsFilledUpTo;
	Items.SceneryObjectSelect.Visible = Not ObjectIsFilledUpTo;
	
	Items.DecorationObject.Visible = ObjectIsFilledUpTo;
	Items.DecorationObject.Title = ObjectBefore;
	Items.CopyNavigationLinkToClipboard.Visible = NavigationLinkIsFull;
	Items.CopyNavigationLinkToClipboardContext.Visible = NavigationLinkIsFull;
	Items.DecorationObjectClear.Visible = ObjectIsFilledUpTo;
	
	If ObjectIsFilledUpTo Then
		Items.PageGroupLinkedObject.CurrentPage = Items.PageGroupIsRelatedObject;
	Else
		Items.PageGroupLinkedObject.CurrentPage = Items.GroupPageNoAssociatedObject;
	EndIf;
	
	Items.PresentationOfHTMLFilesAndDocument.Enabled = ObjectIsFilledUpTo;
	Items.Actions.Enabled = ObjectIsFilledUpTo;
	
	Items.LaunchButtonGroup.Visible = ObjectIsFilledUpTo
		And ProcessingIsFilled
		And Items.LaunchButtonGroup.Visible;
	Items.ProcessingInterruptionInformationGroup.Visible = ObjectIsFilledUpTo
		And ProcessingIsFilled
		And Items.ProcessingInterruptionInformationGroup.Visible;
	
	If ObjectIsFilledUpTo Then
		TreeType = IntegrationWith1CDocumentManagement3Client.TreeType();
		TreeType.ThisIsProcessingTree = True;
		IntegrationWith1CDocumentManagement3Client.ExpandTheTree(
			TreeType,
			Actions.GetItems(),
			Items.Actions,
			StateOfProcessingTree);
	EndIf;
	
	If OverviewIsAvailable Then
		Items.GroupOfDataCollectionPageOverview.CurrentPage = Items.PageDataReceivedOverview;
		Items.Original.Visible = (ObjectBeforeType = "DMDocument");
		Items.Original.ReadOnly = (StateAllowsAddingScannedCopy And Not StateAllowsFileAddition);
		If OnOpen Then
			LinesForDisclosure = New Array;
			If UseFileRoles Then
				For Each String In FilesTree.GetItems() Do
					If ValueIsFilled(String.ID) And String.RoleIsMandatory Then
						LinesForDisclosure.Add(String.ID);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		If Items.GroupPages.CurrentPage = Items.OverviewPage
				Or Items.GroupPages.CurrentPage = Items.ItemInstancePage Then
			RestorePositionInFileList();
		EndIf;
	Else
		Items.GroupOfDataCollectionPageOverview.CurrentPage = Items.ReviewPageIsUnavailable;
	EndIf;
	If ProcessingViewIsAvailable Then
		Items.DataCollectionPageGroupProcessing.CurrentPage = Items.PageDataReceivedProcessing;
	Else
		Items.DataCollectionPageGroupProcessing.CurrentPage = Items.ProcessingPageIsUnavailable;
	EndIf;
	If LinkTreeIsAvailable Then
		Items.GroupOfPageForReceivingCommunicationData.CurrentPage = Items.PageDataReceivedLinks;
		If LinkTreeIsFull And Not LinkTreeIsExpanded Then
			IntegrationWith1CDocumentManagement3Client.ExpandLinkTreeLevel(
				TreeOfLinksIsExpandedString,
				LinkTree,
				Items.LinkTree);
			LinkTreeIsExpanded = True;
			TreeOfLinksIsExpandedString = 0;
		EndIf;
	Else
		Items.GroupOfPageForReceivingCommunicationData.CurrentPage = Items.LinksPageIsUnavailable;
	EndIf;
	If SignatureTreeIsAvailable Then
		Items.SignatureDataPageGroup.CurrentPage = Items.SignatureReceivedDataPage;
		TreeRows = SignatureTree.GetItems();
		For Each TreeRow In TreeRows Do
			RowID = TreeRow.GetID();
			Items.SignatureTree.Expand(RowID);
		EndDo;
	Else
		Items.SignatureDataPageGroup.CurrentPage = Items.SignaturePageIsUnavailable;
	EndIf;
	
	Modified = False;
	
EndProcedure

&AtClient
Procedure UpdateOverview(FileID = Undefined, OutputIdleWindow = True)
	
	ReviewIsFull = False;
	
	CurRowId_ = Undefined;
	CurCurrentStringType = Undefined;
	If FileID <> Undefined Then
		CurRowId_ = FileID;
		CurCurrentStringType = "DMFile";
	ElsIf Items.FilesTree.CurrentData <> Undefined Then
		CurRowId_ = Items.FilesTree.CurrentData.ID;
		CurCurrentStringType = Items.FilesTree.CurrentData.Type;
	EndIf;
	LinesForDisclosure = New Array;
	If UseFileRoles Then
		For Each String In FilesTree.GetItems() Do
			If Items.FilesTree.Expanded(String.GetID()) Then
				LinesForDisclosure.Add(String.ID);
			EndIf;
		EndDo;
	EndIf;
	
	StartUpdatingForm(Items.OverviewPage, OutputIdleWindow);
	
EndProcedure

&AtClient
Procedure UpdateDataProcessor(OutputIdleWindow = True)
	
	ProcessingIsFilled = False;
	StartUpdatingForm(Items.ProcessingPage, OutputIdleWindow);
	
EndProcedure

&AtClient
Procedure UpdateLinkPreview(UpdateData1 = False, IgnoreMaxSize = False)
	
	If Not PreviewLinks Then
		Return;
	EndIf;
	
	HTMLLinkPresentation = IntegrationWith1CDocumentManagementCoreClientServer.DownloadMessage();
	Items.LinkViewPages.CurrentPage = Items.HTMLLinkGroupPage;
	Items.GroupPreviewCut.Visible = False;
	
	RelationshipTreeCurrentData = IntegrationWith1CDocumentManagement3Client.LinkTreeCurrentDataToView(
		Items.LinkTree);
	If RelationshipTreeCurrentData = Undefined Then
		HTMLLinkPresentation = IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
			TitleOfMessageInPreviewArea);
		Return;
	EndIf;
	If RelationshipTreeCurrentData.WaitingForPreview Then
		Return;
	EndIf;
	
	// The receipt of the document's NDPS is combined with the receipt of a preview for optimization.
	// We will get the NDPS in one batch request together with the preview, for one service call BEFORE.
	// In advance, when receiving the task list, it is impossible to get the NDPS of all items, because this
	// will significantly slow down the updating of the list.
	ObjectForGettingPersonalData = Undefined;
	DocumentLine = IntegrationWith1CDocumentManagement3ClientServer.DocumentStringInLinkTree(
		RelationshipTreeCurrentData);
	If DocumentLine <> Undefined Then
		ObjectForGettingPersonalData =
			IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
				DocumentLine.LinkedObjectID,
				DocumentLine.LinkedObjectType);
	EndIf;
	
	ReturnBinaryData = ShowPDFUsing1C
		And (Lower(RelationshipTreeCurrentData.FileExtention) = "pdf")
		And Not RelationshipTreeCurrentData.Encrypted;
	ThereIsPreviewFile = IsTempStorageURL(RelationshipTreeCurrentData.AddressInPreviewFileStorage)
		And Not RelationshipTreeCurrentData.Encrypted;
	
	If (RelationshipTreeCurrentData.LinkedObjectType = "DMFile"
				Or IntegrationWith1CDocumentManagement3ClientCached.ThisIsWellKnownObjectOfReview(RelationshipTreeCurrentData.LinkedObjectType))
			And (UpdateData1
				Or (ReturnBinaryData And Not ThereIsPreviewFile)
				Or (Not ValueIsFilled(RelationshipTreeCurrentData.PresentationHTML) And Not ThereIsPreviewFile)) Then
		
		RelationshipTreeCurrentData.WaitingForPreview = True;
		TimeConsumingOperation = IntegrationWith1CDocumentManagement3ServerCall.GetHTMLPreviewOfObjectAsynchronously(
			UUID,
			RelationshipTreeCurrentData.LinkedObjectID,
			RelationshipTreeCurrentData.LinkedObjectType,
			IgnoreMaxSize,
			ObjectForGettingPersonalData,
			ReturnBinaryData);
		
		CallbackOnCompletion = New CallbackDescription(
			"UpdateLinkPreviewCompletion",
			ThisObject,
			RelationshipTreeCurrentData);
		
		IntegrationWith1CDocumentManagementCoreClient.ExecuteRequestAsynchronously(
			ThisObject,
			TimeConsumingOperation,
			CallbackOnCompletion,
			False,,
			False);
		
		Return;
		
	EndIf;
	
	If Not RelationshipTreeCurrentData.EditedByCurUser
			And RelationshipTreeCurrentData.PreviewCut Then
		Items.GroupPreviewCut.Visible = True;
	EndIf;
	
	If ValueIsFilled(RelationshipTreeCurrentData.PresentationHTML) Then
		HTMLLinkPresentation = RelationshipTreeCurrentData.PresentationHTML;
	ElsIf ThereIsPreviewFile Then
		If RelationshipTreeCurrentData.EditedByCurUser Then
			HTMLLinkPresentation = IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutEditing(
				TitleOfMessageInPreviewArea);
		Else
			PDFDocument = IntegrationWith1CDocumentManagementCoreServerCall.GetPDFDocument(
				RelationshipTreeCurrentData.AddressInPreviewFileStorage);
			If PDFDocument = Undefined Then
				HTMLLinkPresentation = IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
					TitleOfMessageInPreviewArea);
			Else
				ThisObject["PDFDocumentCommunicationAttributes"] = PDFDocument;
				Items.LinkViewPages.CurrentPage = Items.PDFLinkGroupPage;
				Items["PDFDocumentCommunicationField"].CurrentPageNumber = 1;
			EndIf;
		EndIf;
	Else
		HTMLLinkPresentation = IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
			TitleOfMessageInPreviewArea);
	EndIf;
	
EndProcedure

// Called after getting a preview of the object BEFORE.
//
// Parameters:
//   Result - See TimeConsumingOperations.ActionCompleted
//   NotificationParameters - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//
&AtClient
Procedure UpdateLinkPreviewCompletion(Result, NotificationParameters) Export
	
	HTMLObjectPreview =
		IntegrationWith1CDocumentManagementCoreClientServer.NotificationParametersReceivedHTMLObjectPreview();
	
	If Result <> Undefined And Result.Status = "Error" Then
		HTMLMessage =
			IntegrationWith1CDocumentManagementCoreClientServer.PreviewMessage(
				Result.BriefErrorDescription,
				TitleOfMessageInPreviewArea);
		HTMLObjectPreview.ID = NotificationParameters.LinkedObjectID;
		HTMLObjectPreview.Type = NotificationParameters.LinkedObjectType;
		HTMLObjectPreview.Extension = NotificationParameters.FileExtention;
		HTMLObjectPreview.PresentationHTML = HTMLMessage;
		Notify("HTMLObjectPreviewReceived", HTMLObjectPreview, ThisObject);
	EndIf;
	
	ProcessAForm = False;
	If IntegrationWith1CDocumentManagementCoreClient.ActionCompleted(Result, ProcessAForm) Then
		IntegrationWith1CDocumentManagementCoreClientServer.AddPersonalData(HTMLObjectPreview);
		FillPropertyValues(HTMLObjectPreview, Result.ResultLongOperation);
		HTMLObjectPreview.ID = NotificationParameters.LinkedObjectID;
		HTMLObjectPreview.Type = NotificationParameters.LinkedObjectType;
		HTMLObjectPreview.Extension = NotificationParameters.FileExtention;
		If IsBlankString(HTMLObjectPreview.PresentationHTML) Then
			HTMLObjectPreview.PresentationHTML =
				IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
					TitleOfMessageInPreviewArea);
		EndIf;
		Notify("HTMLObjectPreviewReceived", HTMLObjectPreview, ThisObject);
	ElsIf ProcessAForm Then
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdatePreviewOfWaitHandlerConnection()
	
	UpdateLinkPreview();
	
EndProcedure

&AtClient
Procedure RefreshFilePreview(UpdateData1 = False, IgnoreMaxSize = False)
	
	PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.DownloadMessage();
	Items.ViewPagesOverview.CurrentPage = Items.HTMLOverviewGroupPage;
	Items.GroupPreviewStrippedDownReview.Visible = False;
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Then
		PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
			TitleOfMessageInPreviewArea);
		Return;
	EndIf;
	If CurrentData.WaitingForPreview Then
		Return;
	EndIf;
	
	If CurrentData.Type = "DMDocument" Or CurrentData.Type = "DMFileRole" Then
		PresentationHTML = FilesTree.GetItems()[0].PresentationHTML;
		Return;
	EndIf;
	
	// The receipt of the document's NDPS is combined with the receipt of a preview for optimization.
	// We will get the NDPS in one batch request together with the preview, for one service call BEFORE.
	// In advance, when receiving the task list, it is impossible to get the NDPS of all items, because this
	// will significantly slow down the updating of the list.
	ObjectForGettingPersonalData =
		IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
			ObjectBeforeID,
			ObjectBeforeType);
	
	ReturnBinaryData = ShowPDFUsing1C
		And (Lower(CurrentData.Extension) = "pdf")
		And Not CurrentData.Encrypted;
	ThereIsPreviewFile = IsTempStorageURL(CurrentData.AddressInPreviewFileStorage)
		And Not CurrentData.Encrypted;
	
	If (CurrentData.Type = "DMFile"
				Or IntegrationWith1CDocumentManagement3ClientCached.ThisIsWellKnownObjectOfReview(CurrentData.Type))
			And (UpdateData1
				Or (ReturnBinaryData And Not ThereIsPreviewFile)
				Or (Not ValueIsFilled(CurrentData.PresentationHTML) And Not ThereIsPreviewFile)) Then
		
		CurrentData.WaitingForPreview = True;
		TimeConsumingOperation = IntegrationWith1CDocumentManagement3ServerCall.GetHTMLPreviewOfObjectAsynchronously(
			UUID,
			CurrentData.ID,
			CurrentData.Type,
			IgnoreMaxSize,
			ObjectForGettingPersonalData,
			ReturnBinaryData);
		
		CallbackOnCompletion = New CallbackDescription(
			"RefreshFilePreviewCompletion",
			ThisObject,
			CurrentData);
		
		IntegrationWith1CDocumentManagementCoreClient.ExecuteRequestAsynchronously(
			ThisObject,
			TimeConsumingOperation,
			CallbackOnCompletion,
			False,,
			False);
		
		Return;
		
	EndIf;
	
	If Not CurrentData.EditedByCurUser And CurrentData.PreviewCut Then
		Items.GroupPreviewStrippedDownReview.Visible = True;
	EndIf;
	
	If ValueIsFilled(CurrentData.PresentationHTML) Then
		PresentationHTML = CurrentData.PresentationHTML;
	ElsIf ThereIsPreviewFile Then
		If CurrentData.EditedByCurUser Then
			PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutEditing(
				TitleOfMessageInPreviewArea);
		Else
			PDFDocument = IntegrationWith1CDocumentManagementCoreServerCall.GetPDFDocument(
				CurrentData.AddressInPreviewFileStorage);
			If PDFDocument = Undefined Then
				PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
					TitleOfMessageInPreviewArea);
			Else
				ThisObject["PDFDocumentOverviewAttributes"] = PDFDocument;
				Items.ViewPagesOverview.CurrentPage = Items.PageGroupPDFOverview;
				Items["PDFDocumentOverviewField"].CurrentPageNumber = 1;
			EndIf;
		EndIf;
	Else
		PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
			TitleOfMessageInPreviewArea);
	EndIf;
	
EndProcedure

// Called after getting a preview of the object BEFORE.
//
// Parameters:
//   Result - See TimeConsumingOperations.ActionCompleted
//   NotificationParameters - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//
&AtClient
Procedure RefreshFilePreviewCompletion(Result, NotificationParameters) Export
	
	HTMLObjectPreview =
		IntegrationWith1CDocumentManagementCoreClientServer.NotificationParametersReceivedHTMLObjectPreview();
	
	If Result <> Undefined And Result.Status = "Error" Then
		HTMLMessage =
			IntegrationWith1CDocumentManagementCoreClientServer.PreviewMessage(
				Result.BriefErrorDescription,
				TitleOfMessageInPreviewArea);
		HTMLObjectPreview.ID = NotificationParameters.ID;
		HTMLObjectPreview.Type = NotificationParameters.Type;
		HTMLObjectPreview.Extension = NotificationParameters.Extension;
		HTMLObjectPreview.PresentationHTML = HTMLMessage;
		Notify("HTMLObjectPreviewReceived", HTMLObjectPreview, ThisObject);
	EndIf;
	
	ProcessAForm = False;
	If IntegrationWith1CDocumentManagementCoreClient.ActionCompleted(Result, ProcessAForm) Then
		IntegrationWith1CDocumentManagementCoreClientServer.AddPersonalData(HTMLObjectPreview);
		FillPropertyValues(HTMLObjectPreview, Result.ResultLongOperation);
		HTMLObjectPreview.ID = NotificationParameters.ID;
		HTMLObjectPreview.Type = NotificationParameters.Type;
		HTMLObjectPreview.Extension = NotificationParameters.Extension;
		If IsBlankString(HTMLObjectPreview.PresentationHTML) Then
			HTMLObjectPreview.PresentationHTML =
				IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
					TitleOfMessageInPreviewArea);
		EndIf;
		Notify("HTMLObjectPreviewReceived", HTMLObjectPreview, ThisObject);
	ElsIf ProcessAForm Then
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdatePreviewOfWaitHandlerFile()
	
	RefreshFilePreview();
	
EndProcedure

&AtClient
Procedure UpdateConnections(OutputIdleWindow)
	
	LinkTreeIsExpanded = False;
	LinkTreeIsFull = False;
	If TreeOfLinksIsExpandedString = 0 Then
		HTMLLinkPresentation =
			IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
				TitleOfMessageInPreviewArea);
		ReadLinks = 0;
		TotalConnections = 0;
	EndIf;
	StartUpdatingForm(Items.LinkPage, OutputIdleWindow);
	
EndProcedure

&AtClient
Function ProcessDoubleClickOnActionParticipant(CurrentData)
	
	If CurrentData = Undefined Then
		Return False;
	EndIf;
	
	If Not CurrentData.ThisIsParticipant Then
		Return False;
	EndIf;
	
	If CurrentData.State <> "Performing" And CurrentData.State <> "Completed" Then
		Return False;
	EndIf;
	
	If IntegrationWith1CDocumentManagement3ClientServer.ThisIsFamiliarizationAction(CurrentData.ActionType)Then
		Return False;
	EndIf;
	
	If ValueIsFilled(CurrentData.TaskActionID) And ValueIsFilled(CurrentData.TaskActionType) Then
		FormParameters = New Structure(
			"MainSubject, MainSubjectID, MainSubjectType", ObjectBefore, ObjectBeforeID, ObjectBeforeType);
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(
			CurrentData.TaskActionType,
			CurrentData.TaskActionID,
			ThisObject,
			FormParameters);
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

&AtClient
Procedure ProcessFileWriteEventOverview(Parameter, Source)
	
	If ObjectBeforeID = ""
			Or Parameter.FileOwner <> ObjectBeforeID
			Or Parameter.FileOperation.SigningDocumentWithFiles
			Or (Parameter.FileOperation.DeletingItemInstanceFile
				And UUID = Parameter.FormUniqueID)
			Or (Parameter.FileOperation.DeleteFile
				And UUID = Parameter.FormUniqueID) Then
		Return;
	EndIf;
	
	NeedUpdate = True;
	If Parameter.FileOperation.EditingFile Then
		String = IntegrationWith1CDocumentManagement3Client.FileTreeStringByID(
			FilesTree,
			UseFileRoles,
			Parameter.FileID,
			"DMFile");
		If String = Undefined Then
			NeedUpdate = False;
		Else
			NeedUpdate = Not String.IsBeingEdited;
		EndIf;
	EndIf;
	If NeedUpdate Then
		If Parameter.FormUniqueID = Undefined Then
			OutputIdleWindow = (Source = ThisObject);
		Else
			OutputIdleWindow = (UUID = Parameter.FormUniqueID);
		EndIf;
		UpdateOverview(Parameter.FileID, OutputIdleWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessCommunicationFileRecordingEvent(Parameter, Source)
	
	OwnerRow = IntegrationWith1CDocumentManagement3ClientServer.LinkByID(
		LinkTree.GetItems(),
		Parameter.FileOwner);
	If OwnerRow <> Undefined Then
		If Parameter.FormUniqueID = Undefined Then
			OutputIdleWindow = (Source = ThisObject);
		Else
			OutputIdleWindow = (UUID = Parameter.FormUniqueID);
		EndIf;
		UpdateConnections(OutputIdleWindow);
	EndIf;
	
EndProcedure

// Handler for the "GETTHTML Object view" event.
//
// Parameters:
//   Parameter - See IntegrationWith1CDocumentManagementCoreClientServer.NotificationParametersReceivedHTMLObjectPreview
//   Source - Arbitrary - event source.
//
&AtClient
Procedure ProcessEventOfReceivingHTMLPreviewReview(Parameter, Source)
	
	String = IntegrationWith1CDocumentManagement3Client.FileTreeStringByID(
		FilesTree,
		UseFileRoles,
		Parameter.ID,
		Parameter.Type);
	If String <> Undefined Then
		String.WaitingForPreview = False;
		If TypeOf(Parameter.BinaryData) = Type("BinaryData") And Lower(Parameter.Extension) = "pdf" Then
			String.PresentationHTML = "";
			String.PreviewCut = False;
			String.AddressInPreviewFileStorage = PutToTempStorage(
				Parameter.BinaryData,
				UUID);
		Else
			String.PresentationHTML = Parameter.PresentationHTML;
			String.PreviewCut = Parameter.PreviewCut;
		EndIf;
		RefreshFilePreview();
	EndIf;
	
EndProcedure

// Handler for the "GETTHTML Object view" event.
//
// Parameters:
//   Parameter - See IntegrationWith1CDocumentManagementCoreClientServer.NotificationParametersReceivedHTMLObjectPreview
//   Source - Arbitrary - event source.
//
&AtClient
Procedure ProcessEventOfReceivingHTMLLinkPreview(Parameter, Source)
	
	String = IntegrationWith1CDocumentManagement3ClientServer.LinkByID(
		LinkTree.GetItems(),
		Parameter.ID,
		Parameter.Type);
	If String <> Undefined Then
		String.WaitingForPreview = False;
		If TypeOf(Parameter.BinaryData) = Type("BinaryData") And Lower(Parameter.Extension) = "pdf" Then
			String.PresentationHTML = "";
			String.PreviewCut = False;
			String.AddressInPreviewFileStorage = PutToTempStorage(
				Parameter.BinaryData,
				UUID);
		Else
			String.PresentationHTML = Parameter.PresentationHTML;
			String.PreviewCut = Parameter.PreviewCut;
		EndIf;
		UpdateLinkPreview();
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenCurrentFileInLinkTreeForEditing(RelationshipTreeCurrentData)
	
	If RelationshipTreeCurrentData = Undefined Or RelationshipTreeCurrentData.LinkedObjectType <> "DMFile" Then
		Return;
	EndIf;
	
	OwnerID = Undefined;
	DocumentLine = IntegrationWith1CDocumentManagement3ClientServer.DocumentStringInLinkTree(RelationshipTreeCurrentData);
	If DocumentLine <> Undefined Then
		OwnerID = DocumentLine.LinkedObjectID;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.OpenFile(
		RelationshipTreeCurrentData.LinkedObjectID,
		RelationshipTreeCurrentData.LinkedObject,
		RelationshipTreeCurrentData.FileExtention,
		UUID,
		False,,
		OwnerID);
	
EndProcedure

&AtClient
Procedure OpenCurrentFileInLinkTreeForReading(RelationshipTreeCurrentData)
	
	If RelationshipTreeCurrentData = Undefined Or RelationshipTreeCurrentData.LinkedObjectType <> "DMFile" Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.OpenFile(
		RelationshipTreeCurrentData.LinkedObjectID,
		RelationshipTreeCurrentData.LinkedObject,
		RelationshipTreeCurrentData.FileExtention,
		UUID);
	
EndProcedure

&AtClient
Procedure OpenCurrentFileInFileTreeForEditing()
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.Type <> "DMFile" Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.OpenFile(
		CurrentData.ID,
		CurrentData.Description,
		CurrentData.Extension,
		UUID,
		False,,
		ObjectBeforeID);
	
EndProcedure

&AtClient
Procedure OpenCurrentFileInFileTreeForReading()
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.Type = "DMDocument" Then
		Return;
	EndIf;
	
	ObjectUPForViewing = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		CurrentData.ID,
		CurrentData.Type,
		CurrentData.Description,,
		CurrentData.URL);
	IntegrationWith1CDocumentManagement3Client.OpenPlaceForViewing(
		Undefined,
		ObjectUPForViewing,
		CurrentData.Extension,
		UUID);
	
EndProcedure

&AtClientAtServerNoContext
Function ParametersOfProcessingAction()
	
	ParametersOfProcessingAction = New Structure;
	ParametersOfProcessingAction.Insert("ReasonForInterruption", "");
	ParametersOfProcessingAction.Insert("DataUpdateRequired", True);
	ParametersOfProcessingAction.Insert("RequiredInteractiveAction",
		IntegrationWith1CDocumentManagement3ClientServer.RequiredInteractiveAction());
	
	Return ParametersOfProcessingAction;
	
EndFunction

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
	ParametersForStartOfCreation.OwnerID = ObjectBeforeID;
	ParametersForStartOfCreation.OwnerType = ObjectBeforeType;
	ParametersForStartOfCreation.FormUniqueID = UUID;
	ParametersForStartOfCreation.OwnerPresentation = String(ExternalObject);
	ParametersForStartOfCreation.Owner = ExternalObject;
	
	Return ParametersForStartOfCreation;
	
EndFunction

&AtClient
Procedure SignDocumentCompletion(Result, NotificationParameters) Export
	
	OriginalSignatures = IntegrationWith1CDocumentManagementCoreClient.SignaturesArray(SignatureTree);
	AddSignatures(NotificationParameters.AddedObjectSignatures);
	NewNumberOfItemInstances = 0;
	For Each Item In NotificationParameters.AddedObjectSignatures Do
		NewNumberOfItemInstances = NewNumberOfItemInstances + Item.Value.SignaturesArray.Count();
	EndDo;
	
	If OriginalSignatures.Count() <> NewNumberOfItemInstances Then
		IntegrationWith1CDocumentManagementCoreClient.InformAboutSigning(
			ObjectBefore,
			NotificationParameters.AddedObjectSignatures,
			ObjectBeforeID,
			UUID);
		UpdateOverview();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterDeletingFiles(Result, NotificationParameters) Export
	
	If ValueIsFilled(Result) Then
		OutputIdleWindow = True;
		ReviewIsFull = False;
		StartUpdatingForm(Items.OverviewPage, OutputIdleWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenConnecting()
	
	If ProcessFormAccordingToServiceVersion() Then
		StartReceivingDataFromLinkedObjectDM(Items.GroupPages.CurrentPage, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckForErrorsWhenUpdatingForm(Result, NeedToProcessForm)
	
	If Result <> Undefined Then
		If Result.Status = "Error" And IsInitialized = False Then
			ShowErrorWhenUpdating(Result.BriefErrorDescription);
		ElsIf Items.ConnectionPageGroup.CurrentPage = Items.PageUpdateError Then
			TextOfUpdateError = "";
			NeedToProcessForm = True;
		EndIf;
	EndIf;
	
EndProcedure

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
Procedure VerifySignatureCompletion(SignatureTable, NotificationParameters) Export
	
	IntegrationWith1CDocumentManagementCoreClient.SetStatusOfSignatures(SignatureTree, SignatureTable);
	
EndProcedure

&AtClient
Procedure ContinueInterruptingProcessingAfterEnteringReasonForInterruption(InterruptParameters,
		AdditionalParameters) Export
	
	If InterruptParameters = Undefined Or InterruptParameters = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	OperationType = IntegrationWith1CDocumentManagement3ClientServer.TypeOfOperationWithProcessing();
	OperationType.Abort = True;
	ParametersOfProcessingAction = ParametersOfProcessingAction();
	ParametersOfProcessingAction.ReasonForInterruption = InterruptParameters.ReasonForInterruption;
	ActionWithProcessing(OperationType, ParametersOfProcessingAction);
	
EndProcedure

&AtClient
Async Procedure CreateFileFromDisk()
	
	YouNeedToAddScannedCopy =
		Await IntegrationWith1CDocumentManagementCoreClient.YouNeedToAddScannedCopyAsync(
			StateAllowsAddingScannedCopy,
			StateAllowsFileAddition);
	
	If YouNeedToAddScannedCopy = DialogReturnCode.Yes Then
		ParametersForStartOfCreation = FileCreationStartParameters();
		If UseFileRoles Then
			ParametersForStartOfCreation.CurrentFile.FileRoleID = IntegrationWith1CDocumentManagement3Client.CurCurrentFileRole(
				FilesTree,
				Items.FilesTree.CurrentRow);
		EndIf;
		IntegrationWith1CDocumentManagementCoreClient.CreateFileFromDisk(ParametersForStartOfCreation);
	EndIf;
	
EndProcedure

&AtClient
Procedure RemoveAvailabilityOfFileListCommands()
	
	Items.FilesOpenFile.Enabled = False;
	Items.FilesOpenContextFile.Enabled = False;
	
	Items.EditFiles.Enabled = False;
	Items.FilesEditContext.Enabled = False;
	
	Items.FilesFinishEditing.Enabled = False;
	Items.FilesFinishEditingContext.Enabled = False;
	
	Items.ReleaseFiles.Enabled = False;
	Items.FilesFreeContext.Enabled = False;
	
	Items.UpdateFilesFromFileOnDisk.Enabled = False;
	Items.FilesUpdateFromFileOnDiskContext.Enabled = False;
	
	Items.FilesPrint.Enabled = False;
	Items.FilesPrintContext.Enabled = False;
	
	Items.ChangeFiles.Enabled = False;
	Items.FilesChangeContext.Enabled = False;
	
	Items.FilesDelete.Enabled = False;
	Items.FilesDeleteContext.Enabled = False;
	
	Items.FilesSelectRoleOfContextFile.Enabled = False;
	
	Items.FilesSaveChanges.Enabled = False;
	Items.FilesSaveChangesContext.Enabled = False;
	
	Items.EPEncryptionGroup.Enabled = False;
	Items.EPIGroupEncryptionContext.Enabled = False;
	
	Items.FilesSignFile.Enabled = False;
	Items.FilesSignContextFile.Enabled = False;
	
	Items.FilesAddDigitalSignatureFromFile.Enabled = False;
	Items.FilesAddItemInstancesFromContextFile.Enabled = False;
	
	Items.FilesSaveWithDigitalSignature.Enabled = False;
	Items.FilesSaveTogetherSEPContext.Enabled = False;
	
EndProcedure

&AtClient
Procedure DeleteSignatureCompletion(Result, NotificationParameters) Export
	
	If Result <> True Then
		Return;
	EndIf;
	
	UpdateOverview();
	
EndProcedure

&AtClient
Procedure DeleteLink()
	
	ClearObjectDataDM();
	UpdatePagesVisibility(ObjectBeforeType);
	UpdateSceneryOfObjectTO();
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfFileListCommands()
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.Type <> "DMFile" Then
		
		Items.FilesUpdatePreview.Visible = False;
		Items.PresentationOfHTMLDocumentContextMenuUpdateOverview.Visible = True;
		
		RemoveAvailabilityOfFileListCommands();
		
		ObjectCanBeSavedToDisk = (CurrentData = Undefined)
			Or IntegrationWith1CDocumentManagement3Client.ObjectCanBeSavedToDisk(CurrentData.Type);
		Items.SaveFilesAs.Enabled = ObjectCanBeSavedToDisk;
		Items.SaveFilesAsContext.Enabled = ObjectCanBeSavedToDisk;
		
	Else
		
		Items.FilesUpdatePreview.Visible = True;
		Items.PresentationOfHTMLDocumentContextMenuUpdateOverview.Visible = False;
		
		IsBeingEdited = CurrentData.IsBeingEdited;
		EditedByCurUser = CurrentData.EditedByCurUser;
		HasSignatures = CurrentData.SignedWithDS;
		Encrypted = CurrentData.Encrypted;
		
		EditedByAnotherUser =
			IsBeingEdited
			And Not EditedByCurUser;
		CanBeCaptured =
			StateAllowsFileEditing
			And Not EditedByAnotherUser
			And Not Encrypted
			And Not HasSignatures;
		YouCanLetGo =
			StateAllowsFileEditing
			And EditedByCurUser
			And Not Encrypted
			And Not HasSignatures;
		
		Items.FilesOpenFile.Enabled = Not Encrypted;
		Items.FilesOpenContextFile.Enabled = Not Encrypted;
		
		Items.EditFiles.Enabled = CanBeCaptured;
		Items.FilesEditContext.Enabled = CanBeCaptured;
		
		Items.FilesFinishEditing.Enabled = YouCanLetGo;
		Items.FilesFinishEditingContext.Enabled = YouCanLetGo;
		
		Items.ReleaseFiles.Enabled = YouCanLetGo;
		Items.FilesFreeContext.Enabled = YouCanLetGo;
		
		Items.UpdateFilesFromFileOnDisk.Enabled = CanBeCaptured;
		Items.FilesUpdateFromFileOnDiskContext.Enabled = CanBeCaptured;
		
		Items.FilesPrint.Enabled = Not Encrypted;
		Items.FilesPrintContext.Enabled = Not Encrypted;
		
		Items.ChangeFiles.Enabled = True;
		Items.FilesChangeContext.Enabled = True;
		
		Items.FilesDelete.Enabled = StateAllowsFileDeletion And Not IsBeingEdited And Not SignedWithDS;
		Items.FilesDeleteContext.Enabled = StateAllowsFileDeletion And Not IsBeingEdited And Not SignedWithDS;
		
		Items.SaveFilesAs.Enabled = Not Encrypted;
		Items.SaveFilesAsContext.Enabled = Not Encrypted;
		
		Items.FilesSelectRoleOfContextFile.Enabled = StateAllowsFileAddition;
		
		Items.FilesSaveChanges.Enabled = YouCanLetGo;
		Items.FilesSaveChangesContext.Enabled = YouCanLetGo;
		
		Items.EPEncryptionGroup.Enabled = StateAllowsChangesToItemInstance;
		Items.EPIGroupEncryptionContext.Enabled = StateAllowsChangesToItemInstance;
		
		Items.FilesSignFile.Enabled = Not IsBeingEdited And Not Encrypted;
		Items.FilesSignContextFile.Enabled = Not IsBeingEdited And Not Encrypted;
		
		Items.FilesAddDigitalSignatureFromFile.Enabled = Not IsBeingEdited And Not Encrypted;
		Items.FilesAddItemInstancesFromContextFile.Enabled = Not IsBeingEdited And Not Encrypted;
		
		Items.FilesSaveWithDigitalSignature.Enabled = HasSignatures;
		Items.FilesSaveTogetherSEPContext.Enabled = HasSignatures;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetAvaliabilityOfDSCommandsList()
	
	HasSignatures = (SignatureTree.GetItems().Count() > 0);
	ThisIsSignature = IntegrationWith1CDocumentManagementCoreClient.ThisIsSignature(
		Items.SignatureTree.CurrentData);
	
	Items.SignatureTreeOpen.Enabled = HasSignatures;
	Items.SignatureTreeOpenContext.Enabled = HasSignatures;
	
	Items.CheckSignatureTree.Enabled = HasSignatures;
	Items.SignatureTreeCheckContext.Enabled = HasSignatures;
	
	Items.SignatureTreeCheckEverything.Enabled = HasSignatures;
	Items.SignatureTreeCheckAllContext.Enabled = HasSignatures;
	
	Items.SaveSignatureTree.Enabled = ThisIsSignature;
	Items.SignatureTreeSaveContext.Enabled = ThisIsSignature;
	
	Items.DeleteSignatureTree.Enabled = HasSignatures;
	Items.SignatureTreeDeleteContext.Enabled = HasSignatures;
	
EndProcedure

#EndRegion

#Region Server

&AtServer
Procedure AddSignatures(AddedObjectSignatures)
	
	IntegrationWith1CDocumentManagementCore.SignDocument(AddedObjectSignatures, SignatureTree);
	
EndProcedure

&AtServer
Procedure EditAttributeIsOriginal(FileBeingModified)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	XDTOFile = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, FileBeingModified.Type);
	XDTOFile.name = FileBeingModified.Description;
	XDTOFile.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		FileBeingModified.ID,
		FileBeingModified.Type);
	XDTOFile.scannedOriginal = FileBeingModified.IsOriginal;
	
	IntegrationWith1CDocumentManagementCore.WriteObject(Proxy, XDTOFile);
	
EndProcedure

&AtServer
Function ColumnsForGettingObjectUPTO(ObjectTypeDM, CurrentPage_Name, ReceiveFiles = False)
	
	Columns = New Array;
	Columns.Add("name");
	If ObjectTypeDM = "DMDocument" Then
		Columns.Add("documentType");
	ElsIf ObjectTypeDM = "DMMeeting" Then
		Columns.Add("type");
	EndIf;
	
	If OverviewIsAvailable And (CurrentPage_Name = "OverviewPage" Or CurrentPage_Name = "ItemInstancePage") Then
		Columns.Add("files");
		If ShowPDFUsing1C Then
			Columns.Add("binaryData");
		EndIf;
		Columns.Add("htmlView");
		If IntegrationWith1CDocumentManagement3.IsDocumentBefore3(ObjectTypeDM) Then
			Columns.Add("documentType");
			Columns.Add("enabledProperties");
		EndIf;
		If FilesShowDeleted Then
			Columns.Add("ignoreDeletionMark");
		EndIf;
		// Add fields to get a group of States and EDI documents.
		If ReceivingFormDataIsAvailable Then
			Columns.Add("form");
			Columns.Add("EDIDocuments");
		EndIf;
		ReceiveFiles = True;
		
		If UseDigitalSignatureBefore Then
			Columns.Add("comment");
			Columns.Add("keyPropertiesValue");
			Columns.Add("signatures");
			Columns.Add("signatureStatus");
			Columns.Add("signatureStatusDescription");
		EndIf;
	EndIf;
	
	Return Columns;
	
EndFunction

// It is called when data about a linked object is received and changed, when a link is deleted, or when
// integration settings are changed. Determines the availability of functionality and changes the visibility of the corresponding Form pages.
//
&AtServer
Procedure UpdatePagesVisibility(Val ObjectTypeDM)
	
	Items.OverviewPage.Visible = True;
	OverviewIsAvailable = True;
	If IntegrationWith1CDocumentManagement3.ThisIsWellKnownObjectOfReview(ObjectTypeDM) Then
		If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.9.18") Then
			OverviewIsAvailable = False;
			Items.DecorationDescriptionReviewIsNotAvailable.Title = NStr(
				"vi = 'Việc xem tổng quan không được hỗ trợ trong phiên bản này của 1C:Document Management.
				| Cần 1C:Document Management phiên bản 3.0.9 hoặc cao hơn.';
				|ru = 'Просмотр обзора не поддерживается в данной версии 1С:Документооборота.
				|Требуется 1С:Документооборот версии 3.0.9 или выше.';
				|en = 'Overview is not supported in this version of 1C:Document Management.
				|Version 3.0.9 or later is required.'; fa = 'نمای کلی در این نسخه از 1C:Document Management پشتیبانی نمی‌شود.
				|نسخه 3.0.9 یا بالاتر الزامی است.';
				|it = 'Просмотр обзора не поддерживается в данной версии 1С:Документооборота.
				|Требуется 1С:Документооборот версии 3.0.9 или выше.';
				|pl = 'Overview is not supported in this version of 1C:Document Management.
				|Version 3.0.9 or later is required.';
				|tr = 'İşlemlerin görüntülenmesi 1C:Document Management''ın bu sürümünde desteklenmemektedir.
				|1C:Document Management''ın 3.0.9 veya daha üst sürümü gereklidir.'");
		EndIf;
	Else
		Items.OverviewPage.Visible = False;
		OverviewIsAvailable = False;
		Items.DecorationDescriptionReviewIsNotAvailable.Title = NStr(
			"vi = 'Đối tượng tích hợp không hỗ trợ xem tổng quan.';
			|ru = 'Интегрированный объект не поддерживает просмотр обзора.';
			|en = 'The integrated object does not support overview.'; fa = 'The integrated object does not support overview.';
			|it = 'The integrated object does not support overview.';
			|pl = 'The integrated object does not support overview.';
			|tr = 'Entegre nesne, genel bakış görüntülemeyi desteklemiyor.'");
	EndIf;
	
	Items.ProcessingPage.Visible = True;
	ProcessingViewIsAvailable = True;
	If UseProcessingOf1CDocumentManagementObjects Then
		If IntegrationWith1CDocumentManagement3.DMObjectSupportsProcessing(ObjectTypeDM) Then
			If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.12.22") Then
				ProcessingViewIsAvailable = False;
				Items.DecorationDescriptionProcessingIsNotAvailable.Title = NStr(
					"vi = 'Việc xem xử lý không được hỗ trợ trong phiên bản này của 1C:Document Management.
					| Cần 1C:Document Management phiên bản 3.0.12 hoặc cao hơn.';
					|ru = 'Просмотр обработки не поддерживается в данной версии 1С:Документооборота.
					|Требуется 1С:Документооборот версии 3.0.12 или выше.';
					|en = 'Viewing the data processor is not supported in this version of 1C:Document Management.
					|Version 3.0.12 or later is required.'; fa = 'مشاهده پردازشگر داده در این نسخه از 1C:Document Management پشتیبانی نمی‌شود.
					|نسخه 3.0.12 یا بالاتر الزامی است.';
					|it = 'Просмотр обработки не поддерживается в данной версии 1С:Документооборота.
					|Требуется 1С:Документооборот версии 3.0.12 или выше.';
					|pl = 'Viewing the data processor is not supported in this version of 1C:Document Management.
					|Version 3.0.12 or later is required.';
					|tr = 'İşlemlerin görüntülenmesi 1C:Document Management''ın bu sürümünde desteklenmemektedir.
					|1C:Document Management''ın 3.0.12 veya daha üst sürümü gereklidir.'");
			EndIf;
		Else
			Items.ProcessingPage.Visible = False;
			ProcessingViewIsAvailable = False;
			Items.DecorationDescriptionProcessingIsNotAvailable.Title = NStr(
				"vi = 'Đối tượng tích hợp không hỗ trợ chức năng xử lý.';
				|ru = 'Интегрированный объект не поддерживает функционал обработки.';
				|en = 'The integrated object does not support the data processor functionality.'; fa = 'The integrated object does not support the data processor functionality.';
				|it = 'Интегрированный объект не поддерживает функционал обработки.';
				|pl = 'The integrated object does not support the data processor functionality.';
				|tr = 'Entegre nesne işleme işlevini desteklememektedir.'");
		EndIf;
	Else
		Items.ProcessingPage.Visible = False;
		ProcessingViewIsAvailable = False;
		Items.DecorationDescriptionProcessingIsNotAvailable.Title = NStr(
			"vi = 'Đã tắt sử dụng chức năng xử lý trong các tùy chỉnh tích hợp.';
			|ru = 'Функционал обработки выключен в настройках интеграции.';
			|en = 'The data processor functionality is disabled in the integration settings.'; fa = 'The data processor functionality is disabled in the integration settings.';
			|it = 'Функционал обработки выключен в настройках интеграции.';
			|pl = 'The data processor functionality is disabled in the integration settings.';
			|tr = 'İşleme işlevi entegrasyon ayarlarında devre dışı bırakılmıştır.'");
	EndIf;
	
	Items.LinkPage.Visible = True;
	LinkTreeIsAvailable = True;
	If IntegrationWith1CDocumentManagement3.IsDocumentBefore3(ObjectTypeDM) Or ObjectTypeDM = "DMMeeting" Then
		If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.17.36") Then
			LinkTreeIsAvailable = False;
			Items.DecorationDescriptionConnectionsAreNotAvailable.Title = NStr(
				"vi = 'Phiên bản 1C:Document Management này không hỗ trợ xem cây liên kết.
				|Cần có phiên bản 1C:Document Management từ 3.0.17 trở lên.';
				|ru = 'Просмотр дерева связей не поддерживается в данной версии 1С:Документооборота.
				|Требуется 1С:Документооборот версии 3.0.17 или выше.';
				|en = 'Viewing the relation tree is not supported in this version of 1C:Document Management.
				|Version 3.0.17 or later is required.'; fa = 'Viewing the relation tree is not supported in this version of 1C:Document Management.
				|Version 3.0.17 or later is required.';
				|it = 'Viewing the relation tree is not supported in this version of 1C:Document Management.
				|Version 3.0.17 or later is required.';
				|pl = 'Viewing the relation tree is not supported in this version of 1C:Document Management.
				|Version 3.0.17 or later is required.';
				|tr = 'Bağlantı ağacının görüntülenmesi 1C:Document Management''ın bu sürümünde desteklenmemektedir.
				|1C:Document Management''ın 3.0.17 veya daha üst sürümü gereklidir.'");
		EndIf;
	Else
		Items.LinkPage.Visible = False;
		LinkTreeIsAvailable = False;
		Items.DecorationDescriptionConnectionsAreNotAvailable.Title = NStr(
			"vi = 'Đối tượng tích hợp không hỗ trợ chức năng liên kết.';
			|ru = 'Интегрированный объект не поддерживает функционал связей.';
			|en = 'The integrated object does not support the link functionality.'; fa = 'The integrated object does not support the link functionality.';
			|it = 'The integrated object does not support the link functionality.';
			|pl = 'The integrated object does not support the link functionality.';
			|tr = 'Entegre nesne, bağlantı işlevini desteklememektedir.'");
	EndIf;
	
	Items.ItemInstancePage.Visible = True;
	SignatureTreeIsAvailable = True;
	If UseDigitalSignatureBefore And IntegrationWith1CDocumentManagement3.ThisIsWellKnownObjectOfReview(ObjectTypeDM) Then
		If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.9.18") Then
			SignatureTreeIsAvailable = False;
			Items.DecorationDescriptionCaptionsAreNotAvailable.Title = NStr(
				"ru = 'Просмотр электронных подписей не поддерживается в данной версии 1С:Документооборота.
				|Требуется 1С:Документооборот версии 3.0.9 или выше.';
				|vi = 'Viewing digital signatures is not supported in this version of 1C:Document Management.
				|Version 3.0.9 or later is required.';
				|en = 'Viewing digital signatures is not supported in this version of 1C:Document Management.
				|Version 3.0.9 or later is required.'; fa = 'مشاهده امضاهای دیجیتال در این نسخه از 1C:Document Management پشتیبانی نمی‌شود.
				|نسخه 3.0.9 یا بالاتر الزامی است.';
				|it = 'Viewing digital signatures is not supported in this version of 1C:Document Management.
				|Version 3.0.9 or later is required.';
				|pl = 'Viewing digital signatures is not supported in this version of 1C:Document Management.
				|Version 3.0.9 or later is required.';
				|tr = 'E-imza görüntüleme 1C:Document Management''ın bu sürümünde desteklenmiyor.
				|1C:Document Management 3.0.9 veya üzeri sürümü gereklidir.'");
		EndIf;
	Else
		Items.ItemInstancePage.Visible = False;
		SignatureTreeIsAvailable = False;
		Items.DecorationDescriptionCaptionsAreNotAvailable.Title = NStr(
			"ru = 'Использование электронных подписей выключено.';
			|vi = 'Digital signatures are disabled.';
			|en = 'Digital signatures are disabled.'; fa = 'Digital signatures are disabled.';
			|it = 'Digital signatures are disabled.';
			|pl = 'Digital signatures are disabled.';
			|tr = 'E-imza kullanımı kapalı.'");
	EndIf;
	
	ViewActionsAvailable =
		IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.13.29");
	CreatingLinksIsAvailable = IntegrationWith1CDocumentManagement3.CreatingLinksIsAvailable();
	ReceivingFormDataIsAvailable =
		IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.20.21");
	
	Items.SignDocument.Visible = UseDigitalSignatureBefore
		And UseDigitalSignatureIS
		And IntegrationWith1CDocumentManagement3.IsDocumentBefore3(ObjectTypeDM);
	Items.SignContextDocument.Visible = UseDigitalSignatureBefore
		And UseDigitalSignatureIS
		And IntegrationWith1CDocumentManagement3.IsDocumentBefore3(ObjectTypeDM);
	
	If Not CreatingLinksIsAvailable Then
		Items.LinkTreeAdd.Visible = False;
		Items.LinkTreeContextMenuAdd.Visible = False;
		Items.LinkTreeContextMenuDelete.Visible = False;
	EndIf;
	
	AvailableBookmarks = New Array;
	If Items.OverviewPage.Visible Then
		AvailableBookmarks.Add("OverviewPage");
	EndIf;
	If Items.ProcessingPage.Visible Then
		AvailableBookmarks.Add("ProcessingPage");
	EndIf;
	If Items.LinkPage.Visible Then
		AvailableBookmarks.Add("LinkPage");
	EndIf;
	If Items.ItemInstancePage.Visible Then
		AvailableBookmarks.Add("ItemInstancePage");
	EndIf;
	
	// The saved bookmark may be irrelevant.
	If ValueIsFilled(CurBookmark) And AvailableBookmarks.Find(CurBookmark) = Undefined Then
		CurBookmark = "";
	EndIf;
	If CurBookmark = "" And AvailableBookmarks.Count() > 0 Then
		CurBookmark = AvailableBookmarks[0];
	EndIf;
	
	If ValueIsFilled(CurBookmark) And Items.GroupPages.CurrentPage <> Items[CurBookmark] Then
		Items.GroupPages.CurrentPage = Items[CurBookmark];
	EndIf;
	
	If AvailableBookmarks.Count() > 1 Then
		Items.GroupPages.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
	Else
		Items.GroupPages.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;
	
EndProcedure

// Called when the Form is opened, when the integration rules are changed, when data about
// the linked object is received and changed. Fills in the decoration of the header of the linked object, as well as information about the unavailability
// of integration rules.
//
&AtServer
Procedure UpdateTitleOfLinkedObject()
	
	If ValueIsFilled(ObjectBeforeType) Then
		
		ObjectTypePresentationBefore = IntegrationWith1CDocumentManagement3ClientServer.ObjectTypePresentationXDTO(ObjectBeforeType);
		Items.DecorationObjectTitle.Title = StrTemplate("%1:", ObjectTypePresentationBefore);
		
	Else
		
		If ValueIsFilled(PresentationOfObjectBeingCreated) Then
			Items.DecorationObjectTitle.Title = StrTemplate("%1:", PresentationOfObjectBeingCreated);
			
		ElsIf ValueIsFilled(TypeOfObjectToCreate) Then
			Items.DecorationObjectTitle.Title = StrTemplate("%1:",
				IntegrationWith1CDocumentManagement3ClientServer.ObjectTypePresentationXDTO(TypeOfObjectToCreate));
			
		Else
			// There are no suitable rules.
			Items.DecorationObjectTitle.Title = NStr("vi = 'So sánh trong 1C:Document Management:';
													|ru = 'Соответствие в 1С:Документообороте:';
													|en = 'Correspondence in 1C:Document Management:'; fa = 'مکاتبات در 1C:Document Management:';
													|it = 'Corrispondenza in 1C:Document Management:';
													|pl = 'Zgodność w 1C:Document Management:';
													|tr = '1C:Document Management''te uygunluk:'");
			
		EndIf;
		
	EndIf;
	
	If Items.InfoGroup.Visible Then
		
		If NumberOfSuitableIntegrationRules = 0 Then
			
			FullNameOfConsumerInParts = StrSplit(FullNameOfConsumer, ".");
			If FullNameOfConsumerInParts[0] = "Document" Then
				PresentationOfIPObjectType = NStr("vi = 'chứng từ';
													|ru = 'документа';
													|en = 'document'; fa = 'document';
													|it = 'документа';
													|pl = 'document';
													|tr = 'belgenin'");
			ElsIf FullNameOfConsumerInParts[0] = "Catalog" Then
				PresentationOfIPObjectType = NStr("vi = 'danh mục';
													|ru = 'справочника';
													|en = 'catalog'; fa = 'catalog';
													|it = 'справочника';
													|pl = 'catalog';
													|tr = 'kataloğun'");
			Else
				PresentationOfIPObjectType = NStr("vi = 'đối tượng';
													|ru = 'объекта';
													|en = 'object'; fa = 'object';
													|it = 'объекта';
													|pl = 'object';
													|tr = 'nesnenin'");
			EndIf;
			If ValueIsFilled(ExternalObject) Then
				ObjectPresentationIS = String(ExternalObject);
			Else
				ObjectPresentationIS = ConsumerName;
			EndIf;
			
			If ValueIsFilled(ObjectBeforeType) Then
				// The linked object is already there.
				Try
					ObjectTypePresentationBefore = Lower(GetStringDeclensions(
						ObjectTypePresentationBefore,
						"L=ru_RU",
						"CS=Genitive")[0]);
				Except
					ObjectTypePresentationBefore = NStr("vi = 'đối tượng';
														|ru = 'объекта';
														|en = 'object'; fa = 'object';
														|it = 'объекта';
														|pl = 'object';
														|tr = 'nesnesin'");
				EndTry;
				Info = StrTemplate(NStr(
					"vi = 'Chưa thiết lập quy tắc tích hợp để điền %1 1C:Document Management ""%2"" trong số %3 ""%4"". ';
					|ru = 'Не настроено правило интеграции для заполнения %1 1С:Документооборота ""%2"" из %3 ""%4"".';
					|en = 'The integration rule to fill %1 of 1C:Document Management %2 from %3 %4 is not configured.'; fa = 'The integration rule to fill %1 of 1C:Document Management %2 from %3 %4 is not configured.';
					|it = 'Не настроено правило интеграции для заполнения %1 1С:Документооборота ""%2"" из %3 ""%4"".';
					|pl = 'The integration rule to fill %1 of 1C:Document Management %2 from %3 %4 is not configured.';
					|tr = '""%4"" %3 üzerinden ""%2"" 1C:Document Management %1 kapsamının doldurulması için entegrasyon kuralı ayarlanmadı.'"),
					ObjectTypePresentationBefore,
					ObjectBefore,
					PresentationOfIPObjectType,
					ObjectPresentationIS);
			Else
				// The linked object has not been created yet.
				Info = StrTemplate(NStr(
					"vi = 'Chưa thiết lập quy tắc tích hợp để tạo đối tượng 1C:Document Management từ %1 ""%2"". ';
					|ru = 'Не настроено правило интеграции для создания объекта 1С:Документооборота из %1 ""%2"".';
					|en = 'The integration rule for creating a 1C:Document Management object from %1 ""%2"" is not configured.'; fa = 'The integration rule for creating a 1C:Document Management object from %1 ""%2"" is not configured.';
					|it = 'Не настроено правило интеграции для создания объекта 1С:Документооборота из %1 ""%2"".';
					|pl = 'The integration rule for creating a 1C:Document Management object from %1 ""%2"" is not configured.';
					|tr = '""%2"" %1 üzerinden 1C:Document Management nesnesinin oluşturulması için entegrasyon kuralı ayarlanmadı.'"),
					PresentationOfIPObjectType,
					ObjectPresentationIS);
			EndIf;
			
			Command = "ItemForm";
			
		Else
			
			Info = StrTemplate(NStr(
				"vi = 'Đã tùy chỉnh điền các kiểu đối tượng 1C:Document Management khác nhau từ ""%1"".
				|Hãy thay đổi quy tắc hoặc xóa các quy tắc thừa.';
				|ru = 'Настроено заполнение разных типов объектов 1С:Документооборота из ""%1"".
				|Измените правила или удалите лишние.';
				|en = 'Filling of different 1C:Document Management object types from ""%1"" is configured.
				|Change the rules or delete unnecessary ones.'; fa = 'Filling of different 1C:Document Management object types from ""%1"" is configured.
				|Change the rules or delete unnecessary ones.';
				|it = 'Configurato per compilare diversi tipi di oggetti di 1C:Document Management da ""%1"".
				|Modificare le regole o eliminare quelle in eccesso.';
				|pl = 'Ustawiono wypełnienie różnych typów obiektów 1C:Document Management z ""%1"".
				|Zmień reguły lub usuń zbędne.';
				|tr = '1C:Document Management farklı nesne türlerinin ""%1"" den doldurulması.
				|Kuralları değiştir veya gereksiz olanları sil.'"),
				ConsumerName);
			Command = "ListForm";
			
		EndIf;
		
		If AccessRight("Insert", Metadata.Catalogs.RulesForIntegrationWith1CDocumentManagement3) Then
			Info = StringFunctions.FormattedString(
				StrTemplate("%1 <a href = ""%2||%3"">%4.</a>",
					Info,
					Command,
					FullNameOfConsumer,
					NStr("vi = 'Tùy chỉnh';
						|ru = 'Настроить';
						|en = 'Set up'; fa = 'تنظیم';
						|it = 'Настроить';
						|pl = 'Set up';
						|tr = 'Ayarla'")));
		EndIf;
		
		Items.InfoDecoration.Title = Info;
		
	EndIf;
	
EndProcedure

// Called when the Form is opened and the integration rules are changed. Fills in the Presentation of an object
// that can be created using the integration rules.
//
&AtServer
Procedure UpdateViewOfObjectBeingCreated()
	
	TypeOfObjectToCreate = "";
	PresentationOfObjectBeingCreated = "";
	DocumentTypeFromRules = "";
	DocumentTypeFromRulesID = "";
	
	// We get the type and representation of the object being created, if they are unambiguous.
	SuitableIntegrationRules = IntegrationWith1CDocumentManagement3ServerCall.SuitableObjectIntegrationRules(
		ExternalObject);
	NumberOfSuitableIntegrationRules = SuitableIntegrationRules.Count();
	RulesAttributes = Common.ObjectsAttributesValues(
		SuitableIntegrationRules,
		"ObjectTypeDM, ObjectPresentationDM, DocumentKindDM, DocumentKindDMID");
	For Each Rule In SuitableIntegrationRules Do
		If Not ValueIsFilled(TypeOfObjectToCreate) Then
			TypeOfObjectToCreate = RulesAttributes[Rule].ObjectTypeDM;
		ElsIf TypeOfObjectToCreate <> RulesAttributes[Rule].ObjectTypeDM Then
			TypeOfObjectToCreate = "";
			Break;
		EndIf;
	EndDo;
	For Each Rule In SuitableIntegrationRules Do
		If Not ValueIsFilled(PresentationOfObjectBeingCreated) Then
			PresentationOfObjectBeingCreated = RulesAttributes[Rule].ObjectPresentationDM;
		ElsIf PresentationOfObjectBeingCreated <> RulesAttributes[Rule].ObjectPresentationDM Then
			PresentationOfObjectBeingCreated = "";
			Break;
		EndIf;
	EndDo;
	For Each Rule In SuitableIntegrationRules Do
		If Not ValueIsFilled(DocumentTypeFromRulesID) Then
			DocumentTypeFromRules = RulesAttributes[Rule].DocumentKindDM;
			DocumentTypeFromRulesID = RulesAttributes[Rule].DocumentKindDMID;
		ElsIf DocumentTypeFromRulesID <> RulesAttributes[Rule].DocumentKindDMID Then
			DocumentTypeFromRules = "";
			DocumentTypeFromRulesID = "";
			Break;
		EndIf;
	EndDo;
	
	Items.InfoGroup.Visible = Not ValueIsFilled(PresentationOfObjectBeingCreated)
		And Not ValueIsFilled(TypeOfObjectToCreate);
	UpdateTitleOfLinkedObject();
	
EndProcedure

// Modifies the form according to the availability of the service BEFORE and its version number.
//
&AtServer
Function ProcessFormAccordingToServiceVersion()
	
	ServiceVersion = IntegrationWith1CDocumentManagementCore.ServiceVersion();
	
	FormProcessedSuccessfully = True;
	
	If Not IntegrationWith1CDocumentManagementCoreClientServer.ServiceIsAvailable(ServiceVersion) Then
		
		Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsUnavailable;
		FormProcessedSuccessfully = False;
		
	ElsIf IntegrationWith1CDocumentManagement3.FileFunctionalityIsAvailable() Then
		
		Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsAvailable;
		
		SettingsOf1CDocumentManagement = IntegrationWith1CDocumentManagementCoreCached.GetSettings();
		TitleOfMessageInPreviewArea = SettingsOf1CDocumentManagement.TitleOfMessageInPreviewArea;
		UseDigitalSignatureBefore = (SettingsOf1CDocumentManagement.UseElectronicDigitalSignatures = True);
		ShowPDFUsing1C = SettingsOf1CDocumentManagement.ShowPDFUsing1C;
		ListOfExtensionsOfScannedCopiesOfOriginals = SettingsOf1CDocumentManagement.ListOfExtensionsOfScannedCopiesOfOriginals;
		
		Items.FilesSignedEncrypted.Visible = UseDigitalSignatureBefore;
		Items.FilesSignFile.Visible = (UseDigitalSignatureBefore And UseDigitalSignatureIS);
		Items.FilesSignContextFile.Visible = (UseDigitalSignatureBefore And UseDigitalSignatureIS);
		Items.FilesAddDigitalSignatureFromFile.Visible = (UseDigitalSignatureBefore And UseDigitalSignatureIS);
		Items.FilesAddItemInstancesFromContextFile.Visible = (UseDigitalSignatureBefore And UseDigitalSignatureIS);
		Items.FilesSaveWithDigitalSignature.Visible = (UseDigitalSignatureBefore And UseDigitalSignatureIS);
		Items.FilesSaveTogetherSEPContext.Visible = (UseDigitalSignatureBefore And UseDigitalSignatureIS);
		
		If ShowPDFUsing1C Then
			IntegrationWith1CDocumentManagement3.OutputPDFDocumentToForm(
				ThisObject,
				"PageGroupPDFOverview",
				"PDFDocumentOverviewField",
				"PDFDocumentOverviewAttributes");
			IntegrationWith1CDocumentManagement3.OutputPDFDocumentToForm(
				ThisObject,
				"PDFLinkGroupPage",
				"PDFDocumentCommunicationField",
				"PDFDocumentCommunicationAttributes");
		EndIf;
		
		IntegrationWith1CDocumentManagementCoreClientServer.SetValuesOfAllNDPSFields(
			ThisObject,
			True);
		
	Else
		
		Items.ConnectionPageGroup.CurrentPage = Items.VersionPageIsNotSupported;
		FormProcessedSuccessfully = False;
		
	EndIf;
	
	Return FormProcessedSuccessfully;
	
EndFunction

&AtServer
Procedure ClearObjectDataDM()
	
	ObjectBefore = "";
	ObjectBeforeID = "";
	ObjectBeforeType = "";
	UpdateTitleOfLinkedObject();
	ObjectKindBefore = "";
	ObjectKindBeforeID = "";
	ObjectKindBeforeType = "";
	MapItemDMNavigationLink = "";
	PresentationHTML = "";
	Actions.GetItems().Clear();
	
EndProcedure

&AtServer
Procedure ReReadFunctionalOptions(Val ObjectTypeDM)
	
	UseProcessingOf1CDocumentManagementObjects =
		Constants.UseProcessingOf1CDocumentManagementObjects.Get();
	
	UpdatePagesVisibility(ObjectTypeDM);
	
EndProcedure

&AtServer
Procedure ShowErrorWhenUpdating(Error)
	
	TextOfUpdateError = Error;
	Items.ConnectionPageGroup.CurrentPage = Items.PageUpdateError;
	
	ReviewIsFull = False;
	CurBookmark = "OverviewPage";
	Items.GroupPages.CurrentPage = Items.OverviewPage;
	
EndProcedure

#EndRegion

#Region UpdateForm

&AtClient
Procedure StartUpdatingForm(CurrentPage, OutputIdleWindow = True, OnCurrentPageChange = False)
	
	If IsBlankString(ObjectBeforeID) Or IsBlankString(ObjectBeforeType) Then
		StartReceivingDataFromLinkedObjectDM(Items.GroupPages.CurrentPage, True);
		Return;
	EndIf;
	
	TimeConsumingOperation = UpdateForm(CurrentPage.Name, OutputIdleWindow);
	If TimeConsumingOperation = Undefined Then
		// You don't need to get data from before.
		Return;
	EndIf;
	
	NotificationParameters = New Structure("CurrentPage_Name, OutputIdleWindow, OnCurrentPageChange",
		CurrentPage.Name,
		OutputIdleWindow,
		OnCurrentPageChange);
	CallbackOnCompletion = New CallbackDescription(
		"UpdatingFormEnd",
		ThisObject,
		NotificationParameters);
	IntegrationWith1CDocumentManagementCoreClient.ExecuteRequestAsynchronously(
		ThisObject,
		TimeConsumingOperation,
		CallbackOnCompletion,
		OutputIdleWindow,
		NStr("vi = 'Nhận dữ liệu từ 1C:Document Management.';
			|ru = 'Получение данных из 1С:Документооборота.';
			|en = 'Get data from 1C:Document Management.'; fa = 'Get data from 1C:Document Management.';
			|it = 'Получение данных из 1С:Документооборота.';
			|pl = 'Get data from 1C:Document Management.';
			|tr = '1C:Document Management üzerinden verilerin alınması.'"),
		False);
	
EndProcedure

&AtServer
Function UpdateForm(Val CurrentPage_Name, Val OutputIdleWindow)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	PackageQueries = New Array;
	
	If OverviewIsAvailable And Not ReviewIsFull
			And (CurrentPage_Name = "OverviewPage" Or CurrentPage_Name = "ItemInstancePage") Then
		ObjectToGetFromTO = New Structure;
		ObjectToGetFromTO.Insert("ID", ObjectBeforeID);
		ObjectToGetFromTO.Insert("Type", ObjectBeforeType);
		ObjectToGetFromTO.Insert("ExternalIPObject", ExternalObject);
		Columns = ColumnsForGettingObjectUPTO(ObjectBeforeType, CurrentPage_Name);
		PackageQueries.Add(
			IntegrationWith1CDocumentManagementCore.GetRequestObjects(
				Proxy,
				CommonClientServer.ValueInArray(ObjectToGetFromTO),
				Columns));
		PackageQueries.Add(
			IntegrationWith1CDocumentManagement3.HTMLPreviewOfRequestObject(
				Proxy,
				ObjectBeforeID,
				ObjectBeforeType));
		If Not OutputIdleWindow Then
			Items.GroupOfDataCollectionPageOverview.CurrentPage = Items.PageDownloadFromDMReview;
			Items.SignatureDataPageGroup.CurrentPage = Items.PageLoadingFromBEFORESigning;
		EndIf;
	EndIf;
	
	If ProcessingViewIsAvailable And Not ProcessingIsFilled And CurrentPage_Name = "ProcessingPage" Then
		PackageQueries.Add(
			IntegrationWith1CDocumentManagement3.CurProcessingOfRequestObject(
				Proxy,
				ObjectBeforeID,
				ObjectBeforeType));
		If Not OutputIdleWindow Then
			Items.DataCollectionPageGroupProcessing.CurrentPage = Items.PageLoadingFromDMProcessing;
		EndIf;
	EndIf;
	
	If LinkTreeIsAvailable And Not LinkTreeIsFull And CurrentPage_Name = "LinkPage" Then
		If TreeOfLinksIsExpandedString <> 0 Then
			LinkTreeString = LinkTree.FindByID(TreeOfLinksIsExpandedString).GetParent();
			ObjectAttributes =
				IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
					LinkTreeString.LinkedObjectID, LinkTreeString.LinkedObjectType);
		Else
			ObjectAttributes =
				IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
					ObjectBeforeID, ObjectBeforeType);
		EndIf;
		PackageQueries.Add(IntegrationWith1CDocumentManagement3.ConnectionsOfRequestObject(Proxy, ObjectAttributes));
		If Not OutputIdleWindow And TreeOfLinksIsExpandedString = 0 Then
			Items.GroupOfPageForReceivingCommunicationData.CurrentPage = Items.PageLoadingFromBEFORECommunication;
		EndIf;
	EndIf;
	
	If PackageQueries.Count() > 0 Then
		Return IntegrationWith1CDocumentManagementCore.ExecuteBatchRequestAsynchronously(
			Proxy,
			PackageQueries,
			UUID,
			NStr("vi = 'Nhận dữ liệu từ 1C:Document Management...';
				|ru = 'Получение данных из 1С:Документооборота';
				|en = 'Get data from 1C:Document Management'; fa = 'Get data from 1C:Document Management';
				|it = 'Получение данных из 1С:Документооборота';
				|pl = 'Get data from 1C:Document Management';
				|tr = '1C:Document Management üzerinden verilerin alınması'"));
	EndIf;
	
EndFunction

&AtClient
Procedure UpdatingFormEnd(Result, NotificationParameters) Export
	
	ProcessAForm = False;
	CheckForErrorsWhenUpdatingForm(Result, ProcessAForm);
	If ProcessAForm Then
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
	If Result <> Undefined And Result.Status = "Error" Then
		TextOfUpdateError = Result.BriefErrorDescription;
		If Not NotificationParameters.OutputIdleWindow Then
			ShowErrorWhenUpdating(Result.BriefErrorDescription);
		EndIf;
	EndIf;
	
	If IntegrationWith1CDocumentManagementCoreClient.ActionCompleted(Result, ProcessAForm) Then
		TreeType = IntegrationWith1CDocumentManagement3Client.TreeType();
		TreeType.ThisIsProcessingTree = True;
		StateOfProcessingTree = IntegrationWith1CDocumentManagement3Client.CurCurrentStateOfTree(
			TreeType,
			Actions.GetItems(),
			Items.Actions);
		ProcessingTreeIsBeingUpdated = True;
		UpdateFormCompletion(Result.ResultLongOperation, NotificationParameters);
		UpdateSceneryOfObjectTO(NotificationParameters.OnCurrentPageChange);
		ProcessingTreeIsBeingUpdated = False;
	ElsIf ProcessAForm Then
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateFormCompletion(Val ResponseToPackageRequestsString, Val NotificationParameters)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	ResponseToPackageRequests = IntegrationWith1CDocumentManagementCore.StringInXDTOObject(
		Proxy,
		ResponseToPackageRequestsString);
	
	If OverviewIsAvailable
			And (NotificationParameters.CurrentPage_Name = "OverviewPage"
				Or NotificationParameters.CurrentPage_Name = "ItemInstancePage") Then
		ResponseReceivingData = ResponseToPackageRequests.responses[0];
		ResponseHTMLRepresentation = ResponseToPackageRequests.responses[1];
		If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, ResponseReceivingData, "DMError") Then
			ShowErrorWhenUpdating(ResponseReceivingData.description);
		ElsIf IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, ResponseHTMLRepresentation, "DMError") Then
			ShowErrorWhenUpdating(ResponseHTMLRepresentation.description);
		Else
			XDTODataObject = ResponseReceivingData.objects[0];
			IntegrationWith1CDocumentManagement3.FillInOverviewTabInForm(
				ThisObject,
				ResponseHTMLRepresentation,
				XDTODataObject);
			ReviewIsFull = True;
			If Items.ConnectionPageGroup.CurrentPage = Items.PageUpdateError Then
				Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsAvailable;
			EndIf;
			If Not NotificationParameters.OutputIdleWindow Then
				Items.GroupOfDataCollectionPageOverview.CurrentPage = Items.PageDataReceivedOverview;
				Items.SignatureDataPageGroup.CurrentPage = Items.SignatureReceivedDataPage;
			EndIf;
		EndIf;
	EndIf;
	
	If ProcessingViewIsAvailable And NotificationParameters.CurrentPage_Name = "ProcessingPage" Then
		ResponseProcessing = ResponseToPackageRequests.responses[0];
		If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, ResponseProcessing, "DMError") Then
			ShowErrorWhenUpdating(ResponseProcessing.description);
		Else
			IntegrationWith1CDocumentManagement3.FillInProcessingInForm(ThisObject, ResponseProcessing);
			ProcessingIsFilled = True;
			If Items.ConnectionPageGroup.CurrentPage = Items.PageUpdateError Then
				Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsAvailable;
			EndIf;
			If Not NotificationParameters.OutputIdleWindow Then
				Items.DataCollectionPageGroupProcessing.CurrentPage = Items.PageDataReceivedProcessing;
			EndIf;
		EndIf;
	EndIf;
	
	If LinkTreeIsAvailable And NotificationParameters.CurrentPage_Name = "LinkPage" Then
		CommunicationResponse = ResponseToPackageRequests.responses[0];
		If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, CommunicationResponse, "DMError") Then
			ShowErrorWhenUpdating(CommunicationResponse.description);
		Else
			IntegrationWith1CDocumentManagement3.FillInLinkTreeInForm(ThisObject, CommunicationResponse);
			LinkTreeIsFull = True;
			LinkTreeIsExpanded = False;
			If Items.ConnectionPageGroup.CurrentPage = Items.PageUpdateError Then
				Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsAvailable;
			EndIf;
			If Not NotificationParameters.OutputIdleWindow Then
				Items.GroupOfPageForReceivingCommunicationData.CurrentPage = Items.PageDataReceivedLinks;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region RetrievingDataFromLinkedObject

&AtClient
Procedure StartReceivingDataFromLinkedObjectDM(CurrentPage, OnOpen = False)
	
	ReviewIsFull = False;
	ProcessingIsFilled = False;
	LinkTreeIsFull = False;
	HTMLLinkPresentation =
		IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
			TitleOfMessageInPreviewArea);
	ReadLinks = 0;
	TotalConnections = 0;
	
	OnlyImportantConnections = True;
	ShowOnlyOriginalsInLinks = False;
	Items.LinkTreeShowAllLinks.Enabled = True;
	Items.InfoCommunicationGroup.Visible = True;
	
	If Not ValueIsFilled(CurBookmark) Then
		CurBookmark = CurrentPage.Name;
	EndIf;
	
	NotificationParameters = New Structure("SelectionObjectIdDM, ObjectTypeSelectionBefore", "", "");
	TimeConsumingOperation = GetDataOfLinkedObjectDM(
		NotificationParameters.SelectionObjectIdDM,
		NotificationParameters.ObjectTypeSelectionBefore);
	If TimeConsumingOperation = Undefined Then
		// There is no associated object.
		UpdateSceneryOfObjectTO();
		Return;
	EndIf;
	
	NotificationParameters.Insert("CurrentPage_Name", CurBookmark);
	NotificationParameters.Insert("OnOpen", OnOpen);
	CallbackOnCompletion = New CallbackDescription(
		"RetrievingDataFromLinkedObjectBeforeCompletion",
		ThisObject,
		NotificationParameters);
	IntegrationWith1CDocumentManagementCoreClient.ExecuteRequestAsynchronously(
		ThisObject,
		TimeConsumingOperation,
		CallbackOnCompletion);
	
EndProcedure

&AtServer
Function GetDataOfLinkedObjectDM(SelectionObjectIdDM, ObjectTypeSelectionBefore)
	
	ClearObjectDataDM();
	
	PackageQueries = New Array;
	
	Query = New Query(
		"SELECT
		|	ObjectsIntegratedWith1CDocumentManagement.ObjectTypeDM AS ObjectTypeDM,
		|	ObjectsIntegratedWith1CDocumentManagement.ObjectIDDM AS ObjectIDDM
		|FROM
		|	InformationRegister.ObjectsIntegratedWith1CDocumentManagement AS ObjectsIntegratedWith1CDocumentManagement
		|WHERE
		|	ObjectsIntegratedWith1CDocumentManagement.Object = &ExternalObject");
	Query.SetParameter("ExternalObject", ExternalObject);
	
	Selection = Query.Execute().Select();
	LinkCount = Selection.Count();
	
	If LinkCount = 0 Then
		
		UpdatePagesVisibility(ObjectBeforeType);
		
	ElsIf LinkCount = 1 Then
		
		Selection.Next();
		SelectionObjectIdDM = Selection.ObjectIDDM;
		ObjectTypeSelectionBefore = Selection.ObjectTypeDM;
		
		UpdatePagesVisibility(Selection.ObjectTypeDM);
		
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		
		ObjectToGetFromTO = New Structure;
		ObjectToGetFromTO.Insert("ID", SelectionObjectIdDM);
		ObjectToGetFromTO.Insert("Type", ObjectTypeSelectionBefore);
		ObjectToGetFromTO.Insert("ExternalIPObject", ExternalObject);
		
		ReceiveFiles = False;
		Columns = ColumnsForGettingObjectUPTO(ObjectTypeSelectionBefore, CurBookmark, ReceiveFiles);
		PackageQueries.Add(
			IntegrationWith1CDocumentManagementCore.GetRequestObjects(
				Proxy,
				CommonClientServer.ValueInArray(ObjectToGetFromTO),
				Columns));
		
		If ReceiveFiles Then
			PackageQueries.Add(
				IntegrationWith1CDocumentManagement3.HTMLPreviewOfRequestObject(
					Proxy,
					SelectionObjectIdDM,
					ObjectTypeSelectionBefore));
		EndIf;
		
		If ProcessingViewIsAvailable And CurBookmark = "ProcessingPage" Then
			PackageQueries.Add(
				IntegrationWith1CDocumentManagement3.CurProcessingOfRequestObject(
					Proxy,
					SelectionObjectIdDM,
					ObjectTypeSelectionBefore));
		EndIf;
		
		If LinkTreeIsAvailable And CurBookmark = "LinkPage" Then
			ObjectAttributes =
				IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
					SelectionObjectIdDM, ObjectTypeSelectionBefore);
			PackageQueries.Add(IntegrationWith1CDocumentManagement3.ConnectionsOfRequestObject(Proxy, ObjectAttributes));
		EndIf;
		
		Return IntegrationWith1CDocumentManagementCore.ExecuteBatchRequestAsynchronously(
			Proxy,
			PackageQueries,
			UUID,
			NStr("vi = 'Mở biểu mẫu Document Management';
				|ru = 'Открытие формы Документооборот';
				|en = 'Open the Document Management form'; fa = 'Open the Document Management form';
				|it = 'Открытие формы Документооборот';
				|pl = 'Open the Document Management form';
				|tr = 'İş Akışı formunu açma'"));
		
	ElsIf LinkCount > 1 Then
		
		Raise StrTemplate(NStr("vi = 'Đối tượng ""%1"" liên kết với hơn một đối tượng trong 1C:Document Management.
			|Tổng số liên kết: %2';
			|ru = 'С объектом ""%1"" связано более одного объекта в 1С:Документооборот.
			|Общее количество связей: %2';
			|en = 'More than one object is linked to the ""%1"" object in 1C:Document Management.
			|Total number of links: %2'; fa = 'More than one object is linked to the ""%1"" object in 1C:Document Management.
			|Total number of links: %2';
			|it = 'L''oggetto ""%1"" è collegato a più oggetti in 1C:Document Management.
			|Collegamenti totali:%2';
			|pl = 'Z obiektem ""%1"" powiązano ponad jeden obiekt w 1C:Document Management.
			|Ogólna ilość powiązań: %2';
			|tr = '1C:Document Management''ta ""%1"" nesnesi birden fazla nesneyle ilişkilendirilir.
			|Toplam bağlantılar: %2'"),
			ExternalObject,
			LinkCount);
		
	EndIf;
	
EndFunction

&AtClient
Procedure RetrievingDataFromLinkedObjectBeforeCompletion(Result, NotificationParameters) Export
	
	ProcessAForm = False;
	CheckForErrorsWhenUpdatingForm(Result, ProcessAForm);
	If ProcessAForm Then
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
	If IntegrationWith1CDocumentManagementCoreClient.ActionCompleted(Result, ProcessAForm) Then
		ProcessingTreeIsBeingUpdated = True;
		GetDataOfLinkedObjectDMCompletion(Result.ResultLongOperation, NotificationParameters);
		UpdateSceneryOfObjectTO(NotificationParameters.OnOpen);
		ProcessingTreeIsBeingUpdated = False;
		IsInitialized = True;
	ElsIf ProcessAForm Then
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
EndProcedure

&AtServer
Procedure GetDataOfLinkedObjectDMCompletion(Val ResponseToPackageRequestsString, Val NotificationParameters)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	ResponseToPackageRequests = IntegrationWith1CDocumentManagementCore.StringInXDTOObject(
		Proxy,
		ResponseToPackageRequestsString);
	
	Items.GroupPages.Visible = True;
	
	ResponseReceivingData = ResponseToPackageRequests.responses[0];
	Try
		IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, ResponseReceivingData);
	Except
		Common.MessageToUser(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Items.GroupPages.Visible = False;
		// There is no such document on the side. Then you can not check anything.
		// We do not show the error page during the update because you need to leave the option to clear the link, and select
		// another object BEFORE.
		Return;
	EndTry;
	
	If ResponseReceivingData.objects.Count() = 1 Then
		XDTODataObject = ResponseReceivingData.objects[0];
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "name") Then
			ObjectBefore = XDTODataObject.name;
			ObjectBeforeID = NotificationParameters.SelectionObjectIdDM;
			ObjectBeforeType = NotificationParameters.ObjectTypeSelectionBefore;
			UpdateTitleOfLinkedObject();
			MapItemDMNavigationLink = XDTODataObject.objectID.navigationRef;
		EndIf;
		If ObjectBeforeType = "DMDocument"
				And IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "documentType") Then
			ObjectKindBefore = XDTODataObject.documentType.name;
			ObjectKindBeforeID = XDTODataObject.documentType.objectID.id;
			ObjectKindBeforeType = XDTODataObject.documentType.objectID.type;
		ElsIf ObjectBeforeType = "DMMeeting"
				And IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "type") Then
			ObjectKindBefore = XDTODataObject.type.name;
			ObjectKindBeforeID = XDTODataObject.type.objectID.id;
			ObjectKindBeforeType = XDTODataObject.type.objectID.type;
		EndIf;
	EndIf;
	
	If OverviewIsAvailable
			And (NotificationParameters.CurrentPage_Name = "OverviewPage"
				Or NotificationParameters.CurrentPage_Name = "ItemInstancePage") Then
		ResponseHTMLRepresentation = ResponseToPackageRequests.responses[1];
		If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, ResponseHTMLRepresentation, "DMError") Then
			ShowErrorWhenUpdating(ResponseHTMLRepresentation.description);
		Else
			IntegrationWith1CDocumentManagement3.FillInOverviewTabInForm(
				ThisObject,
				ResponseHTMLRepresentation,
				XDTODataObject);
			ReviewIsFull = True;
		EndIf;
	EndIf;
	
	If ProcessingViewIsAvailable And NotificationParameters.CurrentPage_Name = "ProcessingPage" Then
		ResponseProcessing = ResponseToPackageRequests.responses[1];
		If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, ResponseProcessing, "DMError") Then
			ShowErrorWhenUpdating(ResponseProcessing.description);
		Else
			IntegrationWith1CDocumentManagement3.FillInProcessingInForm(ThisObject, ResponseProcessing);
			ProcessingIsFilled = True;
		EndIf;
	EndIf;
	
	If LinkTreeIsAvailable And NotificationParameters.CurrentPage_Name = "LinkPage" Then
		CommunicationResponse = ResponseToPackageRequests.responses[1];
		If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, CommunicationResponse, "DMError") Then
			ShowErrorWhenUpdating(CommunicationResponse.description);
		Else
			IntegrationWith1CDocumentManagement3.FillInLinkTreeInForm(ThisObject, CommunicationResponse);
			LinkTreeIsFull = True;
			LinkTreeIsExpanded = False;
			TreeOfLinksIsExpandedString = 0;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region ActionWithProcessing

&AtClient
Procedure ActionWithProcessing(OperationType, ParametersOfProcessingAction = Undefined) Export
	
	If ParametersOfProcessingAction = Undefined Then
		ParametersOfProcessingAction = ParametersOfProcessingAction();
	EndIf;
	
	DataProcessorData = IntegrationWith1CDocumentManagement3ClientServer.DataProcessorData(
		ObjectBeforeID,
		ObjectBeforeType,
		ProcessingState,
		ParametersOfProcessingAction.ReasonForInterruption);
	DataProcessorData.RequiredInteractiveAction = ParametersOfProcessingAction.RequiredInteractiveAction;
	
	ObjectIsBeingUpdated = False;
	ControlOverSendingFiles = Undefined;
	
	Try
		LongOfOperationWithProcessing = IntegrationWith1CDocumentManagement3ServerCall.LongOfOperationWithProcessing(
			OperationType,
			DataProcessorData,
			ExternalObject,
			UUID,
			ParametersOfProcessingAction.DataUpdateRequired,
			ObjectIsBeingUpdated,
			ControlOverSendingFiles);
	Except
		ErrorInfo = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(ErrorInfo) Then
			ProcessFormAccordingToServiceVersion();
		EndIf;
	EndTry;
	
	NotificationParameters = New Structure("OperationType, DataProcessorData, ParametersOfProcessingAction",
		OperationType, DataProcessorData, ParametersOfProcessingAction);
	NotificationParameters.Insert("ObjectIsBeingUpdated", ObjectIsBeingUpdated);
	NotificationParameters.Insert("ControlOverSendingFiles", ControlOverSendingFiles);
	CallbackOnCompletion = New CallbackDescription(
		"ActionWithProcessingCompletion",
		ThisObject,
		NotificationParameters);
	
	IntegrationWith1CDocumentManagementCoreClient.ExecuteRequestAsynchronously(
		ThisObject,
		LongOfOperationWithProcessing,
		CallbackOnCompletion,
		True,
		NStr("vi = 'Đang thực hiện thao tác với bộ xử lý.';
			|ru = 'Выполняется действие с обработкой.';
			|en = 'Performing a data processor action.'; fa = 'Performing a data processor action.';
			|it = 'Выполняется действие с обработкой.';
			|pl = 'Performing a data processor action.';
			|tr = 'İşleme ile eylem gerçekleştirilmektedir.'"));
	
EndProcedure

&AtClient
Procedure ActionWithProcessingCompletion(Result, NotificationParameters) Export
	
	ProcessAForm = False;
	If IntegrationWith1CDocumentManagementCoreClient.ActionCompleted(Result, ProcessAForm) Then
		ProcessingTreeIsBeingUpdated = True;
		ActionResult = ActionWithProcessingOnServerEnd(
			Result.ResultLongOperation,
			NotificationParameters.ObjectIsBeingUpdated,
			NotificationParameters.ControlOverSendingFiles);
		RepeatedAction = New CallbackDescription(
			"ActionWithProcessing",
			ThisObject,
			NotificationParameters.ParametersOfProcessingAction);
		If IntegrationWith1CDocumentManagement3Client.InteractiveProcessingTriggered(
				ActionResult, NotificationParameters.OperationType, RepeatedAction) Then
			Return;
		EndIf;
		If ActionResult.Success Then
			UpdateSceneryOfObjectTO();
			Notify("Workflow_ActionWithProcessing", NotificationParameters, ThisObject);
		Else
			IntegrationWith1CDocumentManagement3Client.ShowWarningFromBEFORE(,ActionResult.WarningText);
		EndIf;
		ProcessingTreeIsBeingUpdated = False;
		If NotificationParameters.OperationType.Abort Then
			OperationType = IntegrationWith1CDocumentManagement3ClientServer.TypeOfOperationWithProcessing();
			OperationType.Fill = True;
			ActionWithProcessing(OperationType);
		EndIf;
	ElsIf ProcessAForm Then
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
EndProcedure

&AtServer
Function ActionWithProcessingOnServerEnd(Val ResultOfActionIsString, Val ObjectIsBeingUpdated,
		Val ControlOverSendingFiles)
	
	DataForUpdate = Undefined;
	ActionResult = IntegrationWith1CDocumentManagement3.ResultOfCommandOnObject(
		ResultOfActionIsString,
		DataForUpdate,
		ObjectIsBeingUpdated,
		ControlOverSendingFiles);
	
	If ActionResult.Success And DataForUpdate <> Undefined Then
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, DataForUpdate, "DMError") Then
			TextOfUpdateError = DataForUpdate.description;
			Items.ConnectionPageGroup.CurrentPage = Items.PageUpdateError;
		Else
			IntegrationWith1CDocumentManagement3.FillInProcessingInForm(ThisObject, DataForUpdate);
			ProcessingIsFilled = True;
		EndIf;
	EndIf;
	
	Return ActionResult;
	
EndFunction

#EndRegion

#EndRegion