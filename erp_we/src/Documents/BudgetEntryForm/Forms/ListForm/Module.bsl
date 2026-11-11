#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	BudgetingModel = Catalogs.BudgetingModels.BudgetingModel_UseBudgetConfirmation();
	Items.ListGroupSetStatus.Visible = ValueIsFilled(BudgetingModel);
	
	CommonClientServer.SetDynamicListParameter(List, "DateEmpty",  '00010101000000');
	CommonClientServer.SetDynamicListParameter(List, "BeginOfPeriod",'00010101000000');
	CommonClientServer.SetDynamicListParameter(List, "PeriodEnding", '00010101000000');
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.ListCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	SetVisibilityParametersForAnalyticsColumns();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If Parameters.Property("Filter") Then
		Parameters.Filter.Property("BudgetProfile", BudgetProfile);
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "BudgetProfile",  BudgetProfile, DataCompositionComparisonType.Equal, , ValueIsFilled(BudgetProfile));
		
	CommonClientServer.SetDynamicListFilterItem(
		List, "Status",  Status, DataCompositionComparisonType.Equal, , ValueIsFilled(Status));
		
	CommonClientServer.SetDynamicListFilterItem(
		List, "EmployeeResponsible",  EmployeeResponsible, DataCompositionComparisonType.Equal, , ValueIsFilled(EmployeeResponsible));
		
	CommonClientServer.SetDynamicListFilterItem(
		List, "Scenario",  Scenario, DataCompositionComparisonType.Equal, , ValueIsFilled(Scenario));
	
	CommonClientServer.SetDynamicListParameter(
		List, "BeginOfPeriod", Period.StartDate);
		
	CommonClientServer.SetDynamicListParameter(
		List, "PeriodEnding", Period.EndDate);
	
	SetVisibilityParametersForAnalyticsColumns();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterBudgetProfileOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "BudgetProfile",  BudgetProfile, DataCompositionComparisonType.Equal, , ValueIsFilled(BudgetProfile));
		
	SetVisibilityParametersForAnalyticsColumns();
	
EndProcedure

&AtClient
Procedure FilterScenarioOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Scenario",  Scenario, DataCompositionComparisonType.Equal, , ValueIsFilled(Scenario));
	
EndProcedure

&AtClient
Procedure FilterStatusOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Status",  Status, DataCompositionComparisonType.Equal, , ValueIsFilled(Status));
	
EndProcedure

&AtClient
Procedure FilterEmployeeResponsibleOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "EmployeeResponsible",  EmployeeResponsible, DataCompositionComparisonType.Equal, , ValueIsFilled(EmployeeResponsible));
	
EndProcedure

&AtClient
Procedure PeriodOnChange(Item)
	
	CommonClientServer.SetDynamicListParameter(List, "BeginOfPeriod", Period.StartDate, True);
	CommonClientServer.SetDynamicListParameter(List, "PeriodEnding", Period.EndDate, True);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetTheStatusInPreparation(Command)
	
	SetStatus("UnderPreparation", NStr("vi = 'Đang chuẩn bị';
										|ru = 'В подготовке';
										|en = 'Created'; fa = 'ایجادشده';
										|it = 'In preparazione';
										|pl = 'W przygotowaniu';
										|tr = 'Hazırlanma işleminde'"));
	
EndProcedure

&AtClient
Procedure SetTheStatusOnApproval(Command)
	
	SetStatus("AwaitingConfirmation", NStr("vi = 'Cần phê duyệt';
											|ru = 'На утверждении';
											|en = 'Pending confirmation'; fa = 'در انتظار تصدیق';
											|it = 'In approvazione';
											|pl = 'W trakcie zatwierdzenia';
											|tr = 'Onay bekliyor'"));
	
EndProcedure

&AtClient
Procedure SetTheConfirmedStatus(Command)
	
	SetStatus("Upholded", NStr("vi = 'Đã duyệt';
								|ru = 'Утвержден';
								|en = 'Confirmed'; fa = 'تأییدشده';
								|it = 'Confermato';
								|pl = 'Zatwierdzony';
								|tr = 'Onaylandı'"));
	
EndProcedure

&AtClient
Procedure SetTheStatusToCanceled(Command)
	
	SetStatus("RolledBack_", NStr("vi = 'Hủy bỏ';
									|ru = 'Отменен';
									|en = 'Canceled'; fa = 'لغوشده';
									|it = 'Annullato';
									|pl = 'Canceled';
									|tr = 'İptal edildi'"));
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	ClearMessages();
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

&AtClient
Procedure SetStatus(Status, TexStatus)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Các chứng từ được chọn trong danh sách sẽ có trạng thái ""%Status%"". Tiếp tục?';
					|ru = 'У выделенных в списке документов будет установлен статус ""%Status%"". Продолжить?';
					|en = 'The ""%Status%"" status will be set for the documents selected in the list. Continue?'; fa = 'The ""%Status%"" status will be set for the documents selected in the list. Continue?';
					|it = 'Per i documenti evidenziati nell''elenco verrà impostato lo stato ""%Status%"". Continuare?';
					|pl = 'Dla dokumentów zaznaczonych na liście zostanie ustawiony status ""%Status%"". Kontynuować?';
					|tr = 'Listede seçilen belgelerin durumu ""%Status%"" olarak kurulacak. Devam edilsin mi?'");
	QueryText = StrReplace(QueryText, "%Status%", TexStatus);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Status", Status);
	AdditionalParameters.Insert("TexStatus", TexStatus);
	AdditionalParameters.Insert("SelectedRows", SelectedRows);
	
	Notification = New CallbackDescription("SetStatusCompletion", ThisObject, AdditionalParameters);
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetStatusCompletion(Result, AdditionalParameters) Export 
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ClearMessages();
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(
		AdditionalParameters.SelectedRows, 
		AdditionalParameters.Status);
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, 
		ProcessedItemsCount, 
		AdditionalParameters.SelectedRows.Count(), 
		AdditionalParameters.TexStatus);
	
EndProcedure

// Returns a table of types of budget header Analytics.
// 
// Parameters:
// 	BudgetProfile - CatalogRef.BudgetProfiles - Type of budget.
// Returns:
// 	ValueTable - Table Of Types Of Analytics:
// 	 *LineNumber - Number - Line number,
// 	 *DimensionKind - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Type of Analytics.
// 	 *Description - String - Name of the type of analysis.
&AtServer
Function TableOfTypesOfBudgetHeaderAnalytics(BudgetProfile)
	Query = New Query;
	Query.Text = 
	"SELECT
	|	BudgetProfilesHeaderDimensions.LineNumber AS LineNumber,
	|	BudgetProfilesHeaderDimensions.DimensionKind AS DimensionKind,
	|	BudgetProfilesHeaderDimensions.DimensionKind.Description AS Description
	|FROM
	|	Catalog.BudgetProfiles.HeaderDimensions AS BudgetProfilesHeaderDimensions
	|WHERE
	|	BudgetProfilesHeaderDimensions.Ref = &BudgetProfile
	|
	|ORDER BY
	|	LineNumber";
	
	Query.SetParameter("BudgetProfile", BudgetProfile);
	
	QueryResult = Query.Execute();
	TableOfTypesOfAnalytics = QueryResult.Unload();
	
	Return TableOfTypesOfAnalytics;
EndFunction

&AtServer
Procedure SetVisibilityParametersForAnalyticsColumns()
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	If Not ValueIsFilled(BudgetProfile) Then
	
		For Cnt = 1 To 6 Do
			Items["Dimension" + Cnt].Visible = False;
		EndDo;
		
		TableOfTypesOfAnalytics = New ValueTable;
		
	Else
		
		TableOfTypesOfAnalytics = TableOfTypesOfBudgetHeaderAnalytics(BudgetProfile);
		
		For Cnt = 1 To MaximumNumberOfAnalysts Do
			FormItem = Items["Dimension" + Cnt]; // FormField - 
			FormItem.Visible = Cnt <= TableOfTypesOfAnalytics.Count();
			If FormItem.Visible Then
				FormItem.Title = TableOfTypesOfAnalytics[Cnt - 1].Description;
			EndIf;
		EndDo;
	
	EndIf;
	
	AttributesValues = Common.ObjectsAttributesValues(DimensionsThatAreAlwaysDisplayed.UnloadValues(), "Description");
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		Dimension = ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.EmptyRef();
		If Cnt <= DimensionsThatAreAlwaysDisplayed.Count() Then
			Dimension = DimensionsThatAreAlwaysDisplayed[Cnt - 1].Value;
		EndIf;
		If TableOfTypesOfAnalytics.Find(Dimension) <> Undefined Then
			Continue;
		EndIf;
		CommonClientServer.SetDynamicListParameter(List, "MandatoryAnalytics" + Cnt, Dimension, True);
		FormItem = Items["MandatoryAnalytics" + Cnt]; // FormField -
		FormItem.Visible = ValueIsFilled(Dimension);
		If FormItem.Visible Then
			FormItem.Title = AttributesValues[Dimension]["Description"];
		EndIf;
	EndDo;
	
EndProcedure
// End MenuReports

&AtClient
Procedure DimensionsDisplayedAlways(Command)
	
	CallbackDescription = New CallbackDescription("WhenChoosingAnalyst", ThisObject);
	OpenForm("Document.BudgetEntryForm.Form.DimensionsDisplayedAlways",
		New Structure("DimensionsDisplayedAlways", DimensionsThatAreAlwaysDisplayed),
			,,,,CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure WhenChoosingAnalyst(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	DimensionsThatAreAlwaysDisplayed.Clear();
	For Each ListItem In Result Do
		DimensionsThatAreAlwaysDisplayed.Add(ListItem.Value);
	EndDo;
	
	SetVisibilityParametersForAnalyticsColumns();
	
EndProcedure

#EndRegion

