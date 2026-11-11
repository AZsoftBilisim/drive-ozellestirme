#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	TableForSorting = New ValueTable;
	TableForSorting.Columns.Add("Value");
	TableForSorting.Columns.Add("Presentation");
	TypesOfObjectsThatSupportIntegration =
		IntegrationWith1CDocumentManagementCoreCached.TypesOfObjectsThatSupportIntegration();
	For Each ValueType In TypesOfObjectsThatSupportIntegration Do
		MetadataOfIntegratedObject = Metadata.FindByType(ValueType);
		NwRw = TableForSorting.Add();
		NwRw.Value = MetadataOfIntegratedObject.FullName();
		NwRw.Presentation = MetadataOfIntegratedObject.Synonym;
	EndDo;
	TableForSorting.Sort("Presentation");
	For Each String In TableForSorting Do
		Items.ObjectTypeIS.ChoiceList.Add(String.Value, String.Presentation);
	EndDo;
	
	AbbreviatedNameOfConfiguration =
		IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration();
	If ValueIsFilled(AbbreviatedNameOfConfiguration) Then
		Items.ObjectPresentationISWithKeyFields.Title = StrTemplate(
			NStr("vi = 'Trong %1';
				|ru = 'В %1';
				|en = 'In %1'; fa = 'In %1';
				|it = 'In %1';
				|pl = 'W %1';
				|tr = '%1de'"),
			AbbreviatedNameOfConfiguration);
		Items.ObjectTypeIS.Title = StrTemplate(
			NStr("vi = 'Kiểu đối tượng %1';
				|ru = 'Тип объекта %1';
				|en = 'Object type %1'; fa = 'Object type %1';
				|it = 'Тип объекта %1';
				|pl = 'Object type %1';
				|tr = 'Nesne türü %1'"),
			AbbreviatedNameOfConfiguration);
	EndIf;
	
	If ValueIsFilled(Parameters.ObjectTypeIS) Then
		ObjectTypeIS = Parameters.ObjectTypeIS;
		UpdateSelection_();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Items.ShowDeletedItems.Check = ShowDeleted;
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"DeletionMark",
		False,
		DataCompositionComparisonType.Equal,,
		Not ShowDeleted,
		DataCompositionSettingsItemViewMode.Inaccessible);
	
	TestConnection();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "IntegrationWith1CDocumentManagement_SuccessfulConnection" And Source <> ThisObject Then
		ProcessFormAccordingToServiceVersion();
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
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
EndProcedure

&AtClient
Procedure ObjectTypeISOnChange(Item)
	
	UpdateSelection_();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
	FormParameters = New Structure;
	If ValueIsFilled(ObjectTypeIS) Then
		FormParameters.Insert("ObjectTypeIS", ObjectTypeIS);
	EndIf;
	If Copy Then
		FormParameters.Insert("CopyingValue", Items.List.CurrentRow);
	EndIf;
	
	OpenForm("Catalog.RulesForIntegrationWith1CDocumentManagement3.Form.ItemForm",
		FormParameters,
		Items.List);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShowDeletedItems(Command)
	
	ShowDeleted = Not ShowDeleted;
	Items.ShowDeletedItems.Check = ShowDeleted;
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"DeletionMark",
		False,
		DataCompositionComparisonType.Equal,,
		Not ShowDeleted,
		DataCompositionSettingsItemViewMode.Inaccessible);
	
EndProcedure

&AtClient
Async Procedure MarkToDelete(Val Command)
	
	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Check = DeletionMark(Items.List.SelectedRows);
	If Items.List.SelectedRows.Count() = 1 Then
		If Check Then
			QueryText = StrTemplate(
				NStr("vi = 'Bỏ dấu xóa ""%1""?';
					|ru = 'Снять с ""%1"" пометку на удаление?';
					|en = 'Do you want to clear the deletion mark from ""%1""?'; fa = 'Do you want to clear the deletion mark from ""%1""?';
					|it = 'Rimuovere il contrassegno per cancellazione da ""%1""?';
					|pl = 'Usunąć z ""%1"" zaznaczenie do usunięcia?';
					|tr = '""%1"" için silme işareti kaldırılsın mı?'"),
				String(CurrentData.Ref));
		Else
			QueryText = StrTemplate(
				NStr("vi = 'Đặt dấu xóa ""%1""?';
					|ru = 'Пометить ""%1"" на удаление?';
					|en = 'Do you want to mark %1 for deletion?'; fa = 'Do you want to mark %1 for deletion?';
					|it = 'Contrassegnare ""%1"" per cancellazione?';
					|pl = 'Zaznaczyć ""%1"" do usunięcia?';
					|tr = '""%1"" silinmek üzere işaretlensin mi?'"),
				String(CurrentData.Ref));
		EndIf;
	Else
		If Check Then
			QueryText = NStr("vi = 'Bỏ dấu xóa các đối tượng đã chọn?';
							|ru = 'Снять с выделенных элементов пометку на удаление?';
							|en = 'Unmark selected items for deletion?'; fa = 'Unmark selected items for deletion?';
							|it = 'Rimuovere il contrassegno per la cancellazione dagli elementi selezionati?';
							|pl = 'Usunąć z wybranych elementów zaznaczenie do usunięcia?';
							|tr = 'Seçili öğelerin silme işareti kaldırılsın mı?'");
		Else
			QueryText = NStr("vi = 'Đặt dấu xóa phần tử đã chọn?';
							|ru = 'Пометить выделенные элементы на удаление?';
							|en = 'Do you want to mark the selected items for deletion?'; fa = 'Do you want to mark the selected items for deletion?';
							|it = 'Contrassegnare gli elementi selezionati per la cancellazione?';
							|pl = 'Zaznaczyć wybrane elementy do usunięcia?';
							|tr = 'Seçilen öğeler silinmek üzere işaretlensin mi?'");
		EndIf;
	EndIf;
	
	Response = Await IntegrationWith1CDocumentManagementCoreClient.ShowQuestionYesNoAsync(
		QueryText,
		IntegrationWith1CDocumentManagementCoreClient.QuestionParametersYesNo(DialogReturnCode.Yes));
	
	If Response = DialogReturnCode.Yes Then
		MarkForDeletionClearMarkAtServer(
			Items.List.SelectedRows,
			Check);
		
		Items.List.Refresh();
		Notify("IntegrationWith1CWorkflow3_RuleWritten");
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateSelection_()
	
	If ValueIsFilled(ObjectTypeIS) Then
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"ObjectTypeIS",
			ObjectTypeIS,
			DataCompositionComparisonType.Equal);
	Else
		CommonClientServer.DeleteFilterItems(
			List.Filter,
			"ObjectTypeIS");
	EndIf;
	
EndProcedure

// Modifies the form according to the availability of the service BEFORE and its version number.
//
&AtServer
Function ProcessFormAccordingToServiceVersion()
	
	ServiceVersion = IntegrationWith1CDocumentManagementCore.ServiceVersion();
	
	FormProcessedSuccessfully = True;
	
	Try
		
		If Not IntegrationWith1CDocumentManagementCoreClientServer.ServiceIsAvailable(ServiceVersion) Then
			
			Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsUnavailable;
			FormProcessedSuccessfully = False;
			
		ElsIf IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("3.0.7.31") Then
			
			Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsAvailable;
			
		Else
			
			Items.ConnectionPageGroup.CurrentPage = Items.VersionPageIsNotSupported;
			FormProcessedSuccessfully = False;
			
		EndIf;
		
	Except
		
		If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(ErrorInfo()) Then
			ProcessFormAccordingToServiceVersion();
		EndIf;
		
	EndTry;
	
	Return FormProcessedSuccessfully;
	
EndFunction

&AtServerNoContext
Procedure MarkForDeletionClearMarkAtServer(Val ObjectsArray, CurrentDeletionMark)
	
	For Each Ref In ObjectsArray Do
		CurrentObject = Ref.GetObject();
		If CurrentObject.DeletionMark <> CurrentDeletionMark Then
			Continue;
		EndIf;
		CurrentObject.Lock();
		CurrentObject.SetDeletionMark(Not CurrentDeletionMark);
	EndDo;
	
EndProcedure

&AtServerNoContext
Function DeletionMark(Val ObjectsArray)
	
	Result = False;
	
	CurCurrentDeletionTagArray = Common.ObjectsAttributeValue(ObjectsArray, "DeletionMark");
	
	For Each CurCurrentTag In CurCurrentDeletionTagArray Do
		Result = Result Or CurCurrentTag.Value;
	EndDo;
	
	Return Result;
	
EndFunction

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
	
	ProcessFormAccordingToServiceVersion();
	
EndProcedure

#EndRegion