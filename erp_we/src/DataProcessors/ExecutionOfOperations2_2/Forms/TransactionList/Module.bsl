
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearanceOfListOfOperations();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not FillInDetailsOfFormForListOfOperationsByParameters() Then
		Cancel = True;
		Return;
	EndIf;
	
	FillInListOfOperations();
	
	BeginningOfAccountingOfLaborCostsForEmployees = Date(1,1,1);
	
	SetTitleOfOperationsListForm();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

// Parameters:
// 	EventName - String - 
// 	Parameter - Structure - LongDesc:
// * Ref - DocumentRef.ProductionOperation2_2 - 
// * Department - CatalogRef.BusinessStructure - Always transmitted
// * OperationKey - See ProductionManagementClientServer.ProductionOperationKey
// * ModifiedDocuments - Array of DocumentRef.ProductionOperation2_2 -
// 	Source - UUID - 
&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ProductionOperation2_2"
		And Type(Parameter) = Type("Structure")
		And Parameter.Property("OperationKey")
		And ThisIsOperationKeyOfCurForm(
			Parameter.OperationKey,
			Parameters.OperationKey) Then
		
		If Parameter.Property("Ref") Then
			NewRef = DisplayedOperations.FindByValue(Parameter.Ref) = Undefined;
			If Source = ThisForm.UUID
				And NewRef Then
				DisplayedOperations.Add(Parameter.Ref);
			EndIf;
		EndIf;
		
		UpdateDataOnServer(True);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChangeRow(Command)
	
	CurrentData = Items.TransactionList.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.Ref) Then
		
		ShowValue(, CurrentData.Ref);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	UpdateDataOnServer();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure InformationLabelAddOperationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	AssignmentParameters = New Structure("Count", NumberToCreate);
	
	SetStatus_ = ?(WorkMode = OperatingModeAcceptToWork(),
		PredefinedValue("Enum.ProductionOperationStatuses.Running"),
		PredefinedValue("Enum.ProductionOperationStatuses.Executed"));
	
	ListOfFillingData = ProductionAccountingServerCall.DataForNewProductionOperations(
		Parameters.OperationKey, AssignmentParameters, SetStatus_, False);
	
	FormParameters = New Structure;
	FormParameters.Insert("FillingValues", ListOfFillingData[0]);
	
	OpenForm("Document.ProductionOperation2_2.ObjectForm",
		FormParameters,
		ThisObject,
		,
		,
		,
		,
		FormWindowOpeningMode.Independent);
		
EndProcedure

#EndRegion

#Region EventHandlersForOperationTableElements

&AtClient
Procedure TransactionListSelection(Item, RowSelected, Field, StandardProcessing)
	
	FieldName = StrReplace(Field.Name,"TransactionList","");
	If Find("WorkCenterType,WorkCenter,Performer,Status", FieldName) > 0 Then
		Return;
	EndIf;
	
	CurrentData = TransactionList.FindByID(RowSelected);
	
	If CurrentData <> Undefined
		And ValueIsFilled(CurrentData.Ref) Then
		
		ShowValue(, CurrentData.Ref);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OperationsBeforeRowChange(Item, Cancel)
	
	LinesBeforeChange = StringDataByStructure(Items.TransactionList.CurrentData);
	
EndProcedure

&AtClient
Procedure OperationsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure OperationsBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure OperationsAtTheEndOfEditing(Item, NewRow, CancelEdit)
	
	CurrentData = Items.TransactionList.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	RowData = StringDataByStructure(CurrentData);
	
	If Not LineDataChanged(RowData) Then
		Return;
	EndIf;
	
	If Not ChangeOperationAtEndOfEditingOnServer(CurrentData.Ref, RowData) Then
		
		CancelEdit = True;
		
		FillPropertyValues(CurrentData, LinesBeforeChange);
		Return;
		
	EndIf;
	
	NotifyAboutChangesInOperations(CurrentData.Ref);
	
EndProcedure

&AtClient
Procedure SetStatusInProgress(Command)
	
	SelectedRows = HighlightedOperations();
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Các hoạt động được tô sáng trong danh sách sẽ được đặt thành ""Đang thực hiện"". Tiếp tục?';
					|ru = 'У выделенных в списке операций будет установлен статус ""Выполняется"". Продолжить?';
					|en = 'Status of the operations selected in the list will be set to ""In progress"". Continue?'; fa = 'Status of the operations selected in the list will be set to ""In progress"". Continue?';
					|it = 'Alle operazioni selezionate nell''elenco verrà assegnato lo stato ""In esecuzione"". Continuare?';
					|pl = 'Dla operacji zaznaczonych na liście zostanie ustawiony status ""Trwa wykonanie"". Kontynuować?';
					|tr = 'Listede belirtilen işlemler için ""Gerçekleştiriliyor"" durumu ayarlanacaktır. Devam edilsin mi?'");
	
	AddlParameters = New Structure;
	AddlParameters.Insert("Operations", SelectedRows);
	AddlParameters.Insert("Status", "Running");
	AddlParameters.Insert("StatusPresentation", NStr("vi = 'Đang thực hiện';
													|ru = 'Выполняется';
													|en = 'In progress'; fa = 'در حال انجام';
													|it = 'In esecuzione';
													|pl = 'In progress';
													|tr = 'Gerçekleştiriliyor'"));
	
	CallbackDescription = New CallbackDescription(
		"SetStatusCompletion", 
		ThisObject, AddlParameters);
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure ToSetTheStatusToCompleted(Command)
	
	SelectedRows = HighlightedOperations();
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Các thao tác được chọn trong danh sách sẽ được đặt thành trạng thái ""Đã hoàn thành"". Tiếp tục?';
					|ru = 'У выделенных в списке операций будет установлен статус ""Выполнена"". Продолжить?';
					|en = 'Status of the operations selected in the list will be set to Completed. Continue?'; fa = 'Status of the operations selected in the list will be set to Completed. Continue?';
					|it = 'Alle operazioni selezionate nell''elenco verrà assegnato lo stato ""Eseguito"". Continuare?';
					|pl = 'Dla operacji zaznaczonych na liście zostanie ustawiony status ""Wykonana"". Kontynuować?';
					|tr = 'Listede belirtilen işlemler için ""Gerçekleştirildi"" durumu ayarlanacaktır. Devam edilsin mi?'");
	
	AddlParameters = New Structure;
	AddlParameters.Insert("Operations", SelectedRows);
	AddlParameters.Insert("Status", "Executed");
	AddlParameters.Insert("StatusPresentation", NStr("vi = 'Đã thực hiện';
													|ru = 'Выполнена';
													|en = 'Completed'; fa = 'تکمیل‌شده';
													|it = 'Completata';
													|pl = 'Completed';
													|tr = 'Gerçekleştirildi'"));
	
	CallbackDescription = New CallbackDescription(
		"SetStatusCompletion", 
		ThisObject, AddlParameters);
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure ToSetTheStatusToFailed(Command)
	
	SelectedRows = HighlightedOperations();
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Các thao tác được chọn trong danh sách sẽ được đặt thành trạng thái ""Không thành công."" Tiếp tục?';
					|ru = 'У выделенных в списке операций будет установлен статус ""Не выполнена"". Продолжить?';
					|en = 'Status of the operations selected in the list will be set to Failed. Continue?'; fa = 'Status of the operations selected in the list will be set to Failed. Continue?';
					|it = 'Alle operazioni selezionate nell''elenco verrà assegnato lo stato ""Non eseguito"". Continuare?';
					|pl = 'Dla operacji zaznaczonych na liście zostanie ustawiony status ""Nie wykonana"". Kontynuować?';
					|tr = 'Listede belirtilen işlemler için ""Gerçekleştirilmedi"" durumu ayarlanacaktır. Devam edilsin mi?'");
	
	AddlParameters = New Structure;
	AddlParameters.Insert("Operations", SelectedRows);
	AddlParameters.Insert("Status", "NotExecuted");
	AddlParameters.Insert("StatusPresentation", NStr("vi = 'Chưa thực hiện';
													|ru = 'Не выполнена';
													|en = 'Failed'; fa = 'ناموفق';
													|it = 'Non eseguito';
													|pl = 'Nie wykonana';
													|tr = 'Gerçekleştirilmedi'"));
	
	CallbackDescription = New CallbackDescription(
		"SetStatusCompletion", 
		ThisObject, AddlParameters);
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheStatusToSkipped(Command)
	
	SelectedRows = HighlightedOperations();
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Các hoạt động được tô sáng trong danh sách sẽ được đặt thành Bỏ qua. Tiếp tục?';
					|ru = 'У выделенных в списке операций будет установлен статус ""Пропущена"". Продолжить?';
					|en = 'Status of the operations selected in the list will be set to Skipped. Continue?'; fa = 'Status of the operations selected in the list will be set to Skipped. Continue?';
					|it = 'Alle operazioni selezionate nell''elenco verrà assegnato lo stato ""Omessa"". Continuare?';
					|pl = 'Operacje wybrane na liście zostaną ustawione na ""Pominięte"". Kontynuować?';
					|tr = 'Listede belirtilen işlemler için ""Atlandı"" durumu ayarlanacaktır. Devam edilsin mi?'");
	
	AddlParameters = New Structure;
	AddlParameters.Insert("Operations", SelectedRows);
	AddlParameters.Insert("Status", "IsSkipped");
	AddlParameters.Insert("StatusPresentation", NStr("vi = 'Bỏ qua';
													|ru = 'Пропущена';
													|en = 'Skipped'; fa = 'ردشده';
													|it = 'Omessa';
													|pl = 'Skipped';
													|tr = 'Atlandı'"));
	
	CallbackDescription = New CallbackDescription(
		"SetStatusCompletion", 
		ThisObject, AddlParameters);
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetStatusCompletion(QuestionResult, AddlParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ClearMessages();
	
	ProcessedItemsCount = SetStatusOnServer(AddlParameters.Operations, AddlParameters.Status);
	
	TMCommonUseClient.NotifyUserAboutSettingStatus(
		Items.TransactionList,
		ProcessedItemsCount,
		AddlParameters.Operations.Count(),
		AddlParameters.StatusPresentation);
	
	NotifyAboutChangesInOperations();
	
EndProcedure

&AtClient
Procedure TransactionListOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.TransactionList.CurrentData;
	
	AccountingForLaborCostsByEmployees = ValueIsFilled(BeginningOfAccountingOfLaborCostsForEmployees)
		And BeginningOfAccountingOfLaborCostsForEmployees <= CurrentData.Date;
	
	ProductionManagementClientServer.SetArtistType(
		CurrentData.Performer,
		UseTeamWorkOrders,
		AccountingForLaborCostsByEmployees);
	
EndProcedure

&AtClient
Procedure TransactionListPerformerStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.TransactionList.CurrentData;
	
	CallbackDescription = New CallbackDescription("TransactionListPerformerStartChoiceCompletion", ThisObject);
	
	ProductionClient.OpenArtistSelectionForm(
		Organization,
		Department,
		CurrentData.Performer,
		CurrentData.Date,
		,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure TransactionListPerformerStartChoiceCompletion(Result, Var_Parameters) Export
	
	CurrentData = Items.TransactionList.CurrentData;
	If CurrentData <> Undefined And ValueIsFilled(Result) Then
		
		CurrentData.Performer = Result;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TransactionListPerformerAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		
		PerformerGettingSelectionData(ChoiceData, Text, Organization, Department, Items.TransactionList.CurrentData.Date);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TransactionListPerformerTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		
		PerformerGettingSelectionData(ChoiceData, Text, Organization, Department, Items.TransactionList.CurrentData.Date);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function ChangeOperationAtEndOfEditingOnServer(Operation, OperationData) 
	
	Cancel = False;
	
	BeginTransaction();
	Try
		
		LockDataForEdit(Operation);
		
		If YouNeedToChangeOperation(Operation, OperationData) Then
			
			OperationObject = Operation.GetObject();
			
			FillPropertyValues(OperationObject, OperationData, "Performer, WorkCenterType, WorkCenter");
			
			If OperationObject.Status <> OperationData.Status Then
				
				OperationObject.Status = OperationData.Status;
				
				Documents.ProductionOperation2_2.FillInDetailsWhenSettingStatus(OperationObject);
				
			EndIf;
			
			If OperationObject.CheckFilling() Then
				
				OperationObject.Write(DocumentWriteMode.Posting);
				
			Else
				
				CommonClientServer.MessageToUser(
					NStr("vi = 'Lỗi thay đổi sản xuất';
						|ru = 'Ошибка изменения производственной операции';
						|en = 'An error occurred when changing the routing operation'; fa = 'An error occurred when changing the routing operation';
						|it = 'Errore modifica dell''operazione di produzione';
						|pl = 'Błąd podczas zmiany operacji produkcyjnych';
						|tr = 'Üretim işlemini değiştirme hatası'"),,,,
					Cancel);
	 			
			EndIf;
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Lỗi thay đổi sản xuất';
				|ru = 'Ошибка изменения производственной операции';
				|en = 'An error occurred when changing the routing operation'; fa = 'An error occurred when changing the routing operation';
				|it = 'Errore modifica dell''operazione di produzione';
				|pl = 'Błąd podczas zmiany operacji produkcyjnych';
				|tr = 'Üretim işlemini değiştirme hatası'"),,,,
			Cancel);
		
	EndTry;
	
	Return Not Cancel;
	
EndFunction

&AtServerNoContext
Function YouNeedToChangeOperation(Operation, OperationData)
	
	Query = New Query(
		"SELECT
		|	TRUE
		|FROM
		|	Document.ProductionOperation2_2 AS Operations
		|WHERE
		|	Operations.Ref = &Ref
		|	AND (Operations.Status <> &Status
		|		OR CASE
		|			WHEN Operations.WorkCenter REFS Catalog.WorkCenterTypes
		|				THEN Operations.WorkCenter
		|			ELSE
		|				Operations.WorkCenter.WorkCenterType
		|		END <> &WorkCenterType
		|		OR CASE
		|			WHEN Operations.WorkCenter REFS Catalog.WorkCenters
		|				THEN Operations.WorkCenter
		|			ELSE
		|				VALUE(Catalog.WorkCenters.EmptyRef)
		|		END <> &WorkCenter
		|		OR Operations.Performer <> &Performer)");
		
	Query.SetParameter("Ref", Operation);
	Query.SetParameter("Performer", OperationData.Performer);
	Query.SetParameter("WorkCenterType", OperationData.WorkCenterType);
	Query.SetParameter("WorkCenter", OperationData.WorkCenter);
	Query.SetParameter("Status", OperationData.Status);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

&AtClient
Function HighlightedOperations()
	
	Result = New Array;
	
	SelectedRows = Items.TransactionList.SelectedRows;
	For Each Id In SelectedRows Do
		RowData = TransactionList.FindByID(Id);
		Result.Add(RowData.Ref);
	EndDo;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function StringDataByStructure(CurrentData)

	RowData = New Structure("
		|Ref,
		|Performer,
		|WorkCenterType,
		|WorkCenter,
		|Status");
		
	FillPropertyValues(RowData, CurrentData);
	
	Return RowData;
	
EndFunction

&AtClient
Function LineDataChanged(RowData)
	
	Return Not TMCommonUseClientServer.StructuresAreEqual(
						RowData, 
						LinesBeforeChange,
						"Ref,Performer,WorkCenterType,WorkCenter,Status");
	
EndFunction

&AtClient
Procedure NotifyAboutChangesInOperations(DocumentRef = Undefined)
	
	NotificationParameter1 = New Structure;
	NotificationParameter1.Insert("Department", ThisForm.Department);
	NotificationParameter1.Insert("OperationKey", Parameters.OperationKey);
	
	If DocumentRef <> Undefined Then
		NotificationParameter1.Insert("Ref", DocumentRef);
	EndIf;
	
	Notify("Write_ProductionOperation2_2", NotificationParameter1, UUID);
	
EndProcedure

&AtServer
Procedure UpdateDataOnServer(ReReadListOfOperations = True)
	
	FillInDetailsOfListFormBasedOnOperationData();
	If ReReadListOfOperations Then
		ReReadListOfOperations();
	EndIf;
	
EndProcedure

// Setting the title of the "list of operations" form.
&AtServer
Procedure SetTitleOfOperationsListForm()
	
	// Setting the Form header
	#Region FormCaption
	
	If WorkMode = OperatingModeAcceptToWork() Then
		
		TextTitle_ = NStr("vi = 'Nhận giao dịch để làm việc';
							|ru = 'Принять операции в работу';
							|en = 'Accept operations for processing'; fa = 'Accept operations for processing';
							|it = 'Prendere le operazioni in carico';
							|pl = 'Akceptować działania w pracy';
							|tr = 'İşe işlemleri kabul et'");
		
	ElsIf WorkMode = ModeOfOperationMarkExecution() Then
		
		TextTitle_ = NStr("vi = 'Đánh dấu thực hiện giao dịch';
							|ru = 'Отметить выполнение операций';
							|en = 'Mark operation execution'; fa = 'Mark operation execution';
							|it = 'Segnare l''esecuzione delle operazioni';
							|pl = 'Anulować wykonanie operacji';
							|tr = 'İşlemlerin gerçekleştirilmesini işaretle'");
		
	EndIf;
	
	StageDetails = Common.ObjectAttributesValues(Stage, "Number,StageName"); 
	PresentationStage = Documents.ProductionStage2_2.PresentationStage(StageDetails);
	
	TextTitle_ = TextTitle_ + " (" + PresentationStage + ", " + Operation + ")";
	
	AutoTitle = False;
	Title = TextTitle_;
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure ReReadListOfOperations()
	
	Var Id, SelectedOperation;
	
	CurrentRow = Items.TransactionList.CurrentRow;
	
	If CurrentRow <> Undefined Then
		CurrentData = TransactionList.FindByID(CurrentRow);
		SelectedOperation = CurrentData.Ref;
	EndIf;
	
	TransactionList.Clear();
	
	Query = New Query;
	Query.Text = Documents.ProductionOperation2_2.QueryTextTransactionList();
	Query.SetParameter("TransactionList", DisplayedOperations.UnloadValues());
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		NewRow = TransactionList.Add();
		FillPropertyValues(NewRow, Selection);
		
		NewRow.UnitOfMeasurePresentation = ProductionManagementClientServer.PresentationOfUnitOfOperation(
			Selection.UnitOfMeasure,
			Selection.Count);
			
		If Selection.Ref = SelectedOperation Then
			Id = NewRow.GetID();
		EndIf;
		
	EndDo;
	
	If Id <> Undefined Then
		Items.TransactionList.CurrentRow = Id;
	EndIf;
	
EndProcedure

// Setting the conditional design of the "list of operations" form.
//
&AtServer
Procedure SetConditionalAppearanceOfListOfOperations()
	
	// Registration of the "Performer" field
	#Region FieldDesign_Performer
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.TransactionListPerformer.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	
	ItemFilter.LeftValue = New DataCompositionField("TransactionList.Performer");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra>';
													|ru = '<не указан>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non specificato>';
													|pl = '<nie określono>';
													|tr = '<belirtilmedi>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	#EndRegion 
	
	// Registration of the field "View of the work center"
	#Region FieldDesign_ViewOfWorkCenter
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.TransactionListWorkCenterType.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	
	ItemFilter.LeftValue = New DataCompositionField("TransactionList.WorkCenterType");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra>';
													|ru = '<не указан>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non specificato>';
													|pl = '<nie określono>';
													|tr = '<belirtilmedi>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	#EndRegion
	
	// Registration of the "Work Center" field
	#Region FieldDesign_WorkCenter
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.TransactionListWorkCenter.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	
	ItemFilter.LeftValue = New DataCompositionField("TransactionList.WorkCenter");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra>';
													|ru = '<не указан>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non specificato>';
													|pl = '<nie określono>';
													|tr = '<belirtilmedi>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	#EndRegion
		
EndProcedure

// Filling in the details of the "list of operations" form.
//
&AtServer
Function FillInDetailsOfFormForListOfOperationsByParameters()
	
	If Not ValueIsFilled(Parameters.Department) Then
		Return False;
	EndIf;
	
	If Not ValueIsFilled(Parameters.OperationKey) Then
		Return False;
	EndIf;
	
	If Not Parameters.Property("WorkMode", WorkMode) Then
		Return False;
	EndIf;
	
	Department       = Parameters.Department;
	UseAreas = GetFunctionalOption("UseProductionSites", New Structure("Department", Department));
	
	FillInDetailsOfListFormBasedOnOperationData();
	
	Return True;
	
EndFunction

&AtServer
Procedure FillInDetailsOfListFormBasedOnOperationData()
	
	OperationData = ProductionAccountingServerCall.OperationDataFromQueue(Parameters.OperationKey);
	
	If OperationData = Undefined Then
		Return;
	EndIf;
	
	FillPropertyValues(ThisForm, OperationData, "Organization,Stage,Operation,UnitOfMeasure");
	
	QuantityPlanned  = OperationData.Scheduled;
	QuantityCanBePerformed = OperationData.ExecutionIsAllowed;
	NumberOfRuns    = OperationData.Running;
	
	// Add an operation
	NumberToCreate = OperationData.WaitingForCreation;
	
	UseTeamWorkOrders = Documents.ProductionOperation2_2.AccountingSettings(
		Department, Undefined).UseTeamWorkOrders;
	
	If NumberToCreate > 0 Then
		Items.InformationLabelAddOperation.Visible = True;
		InformationLabelAddOperation = FormattedStringAddOperation();
	Else
		Items.InformationLabelAddOperation.Visible = False;
	EndIf;
	
	// Managing visibility
	Items.SetStatusInProgress.Visible = (WorkMode = OperatingModeAcceptToWork());
	Items.ToSetTheStatusToCompleted.Visible   = (WorkMode = ModeOfOperationMarkExecution());
	Items.ToSetTheStatusToFailed.Visible = (WorkMode = ModeOfOperationMarkExecution());
	Items.SetTheStatusToSkipped.Visible   = (WorkMode = ModeOfOperationMarkExecution())
		And OperationData.Skippable;
	Items.TheGroupIsRunning.Visible           = (WorkMode = ModeOfOperationMarkExecution());
	
	// Available operation statuses
	Statuses = New Array;
	Statuses.Add(Enums.ProductionOperationStatuses.CreatedOn_);
	Statuses.Add(Enums.ProductionOperationStatuses.Running);
	
	If WorkMode <> OperatingModeAcceptToWork() Then
		Statuses.Add(Enums.ProductionOperationStatuses.Executed);
		Statuses.Add(Enums.ProductionOperationStatuses.NotExecuted);
		If OperationData.Skippable Then
			Statuses.Add(Enums.ProductionOperationStatuses.IsSkipped);
		EndIf;
	EndIf;
	
	Items.TransactionListStatus.ChoiceList.LoadValues(Statuses);
	
	// Representation of units of measurement
	UnitOfMeasurementPlannedView = ProductionManagementClientServer.PresentationOfUnitOfOperation(
		UnitOfMeasure,
		QuantityPlanned);
	
	UnitOfMeasurementYouCanPerformAView = ProductionManagementClientServer.PresentationOfUnitOfOperation(
		UnitOfMeasure,
		QuantityCanBePerformed);

	UnitOfMeasurementPerformedByTheView = ProductionManagementClientServer.PresentationOfUnitOfOperation(
		UnitOfMeasure,
		NumberOfRuns);
		
	RouteDetails = Catalogs.ManufacturingOperations.DetailsOfOperationRoute(OperationData.OperationOwner);
	Route = RouteDetails.Route;
	Items.Route.Hyperlink = RouteDetails.RouteAvailable;
	
EndProcedure

&AtServer
Function FormattedStringAddOperation()
	
	RowsArray = New Array;
	
	If WorkMode = OperatingModeAcceptToWork() Then
		RowsArray.Add(NStr("vi = 'nhận đi làm';
							|ru = 'принять в работу';
							|en = 'accept for processing'; fa = 'accept for processing';
							|it = 'prendere in carico';
							|pl = 'akceptować do pracy';
							|tr = 'işe kabul et'"));
	ElsIf WorkMode = ModeOfOperationMarkExecution() Then
		RowsArray.Add(NStr("vi = 'đánh dấu hoàn thành';
							|ru = 'отметить выполнение';
							|en = 'mark as completed'; fa = 'mark as completed';
							|it = 'segnare completamento';
							|pl = 'zaznacz wykonanie';
							|tr = 'gerçekleştirmeyi işaretle'"));
	EndIf;
	
	RowsArray.Add(" ");
	
	RowsArray.Add(NStr("vi = 'hơn nữa';
						|ru = 'еще';
						|en = 'more'; fa = 'بیشتر';
						|it = 'altro';
						|pl = 'more';
						|tr = 'daha fazla'"));
	
	RowsArray.Add(" ");
	
	QuantityPresentation = Format(NumberToCreate, "ND=15; NFD=3; NZ=");
	RowsArray.Add(QuantityPresentation);
	
	RowsArray.Add(" ");
	
	UnitOfMeasurePresentation = TMCommonUseClientServer.DeclensionOfWord(
		NumberToCreate,
		NStr("vi = 'thao tác, thao tác, thao tác, d';
			|ru = 'операции, операций, операций, ж';
			|en = 'operation, operations'; fa = 'operation, operations';
			|it = 'операции, операций, операций, ж';
			|pl = 'operation, operations';
			|tr = 'işlemler, işlemler, işlemler, j'"));
	RowsArray.Add(UnitOfMeasurePresentation);
	
	Return New FormattedString(RowsArray,,,,"#AddOperation");

EndFunction

// Filling in the list of operations in the "list of operations" form.
//
&AtServer
Procedure FillInListOfOperations()
	
	Query = New Query(
		"SELECT
		|	Operations.Ref AS Ref
		|FROM
		|	Document.ProductionOperation2_2 AS Operations
		|WHERE
		|	Operations.Stage = &Stage
		|	AND Operations.Operation = &Operation
		|	AND Operations.OperationID = &OperationID
		|	AND Operations.Status IN (&AvailableStatuses)
		|	AND Operations.Posted");
	
	Query.SetParameter("Stage", Parameters.OperationKey.Stage);
	Query.SetParameter("Operation", Parameters.OperationKey.Operation);
	Query.SetParameter("OperationID", Parameters.OperationKey.OperationID);
	
	AvailableStatuses = New Array;
	AvailableStatuses.Add(Enums.ProductionOperationStatuses.CreatedOn_);
	If WorkMode = ModeOfOperationMarkExecution() Then
		AvailableStatuses.Add(Enums.ProductionOperationStatuses.Running);
	EndIf;
	
	Query.SetParameter("AvailableStatuses", AvailableStatuses);
	
	OperationArray = Query.Execute().Unload().UnloadColumn(0);
	DisplayedOperations.LoadValues(OperationArray);
	
	ReReadListOfOperations();
	
EndProcedure

&AtServerNoContext
Procedure PerformerGettingSelectionData(ChoiceData, Text, Organization, Department, Date)
	
	ChoiceData = New ValueList;
	FilterParameters = New Structure("Organization, Department, Date",
										Organization, Department, Date);
	
	ProductionServer.FillInSelectionDataWhenEnteringArtist(ChoiceData, Text, FilterParameters);
	
EndProcedure

&AtServer
Function SetStatusOnServer(Operations, Status)

	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(Operations, Status);
	
	If ProcessedItemsCount <> 0 Then
		
		UpdateDataOnServer();
		
	EndIf;
	
	Return ProcessedItemsCount;
	
EndFunction

&AtClientAtServerNoContext
Function OperatingModeAcceptToWork()
	
	Return "PutIntoOperation";
	
EndFunction

&AtClientAtServerNoContext
Function ModeOfOperationMarkExecution()
	
	Return "MarkCompletion";
	
EndFunction

&AtServerNoContext
Function ThisIsOperationKeyOfCurForm(OperationKey, FormOperationKey)
	
	If OperationKey.Stage                   = FormOperationKey.Stage
		And OperationKey.Operation              = FormOperationKey.Operation
		And OperationKey.OperationID = FormOperationKey.OperationID Then
		
		Return True;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

#EndRegion
