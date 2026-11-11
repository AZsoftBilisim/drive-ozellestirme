
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	URL = "e1cib/list/Document.WorkOutput";
	
	AccessRight = AccessRight("Update", Metadata.Documents.WorkOutput);
	
	If Not AccessRight Then
		Items.BrigadeSquadsCreateGroupGeneratedBy.Visible = False;
		Items.GroupLaborCostsForRegistration.Visible = False;
	EndIf;
	
	ChangeSelectedAvailable = ProductionServer.CommandChangeSelectedIsAvailable(Metadata.Documents.WorkOutput);
	Items.TeamWorkOrdersChangeSelectedItems.Visible                = ChangeSelectedAvailable;
	Items.TeamWorkOrdersContextMenuChangeSelectedItems.Visible = ChangeSelectedAvailable;
	
	UseOutputRegistrationFrequency = Constants.UseOutputRegistrationFrequency.Get();
	
	If Not UseOutputRegistrationFrequency Then
		Items.OutputRegistrationFrequency.InputHint = "";
		Periodicity = Enums.FrequencyOfWorkOutputRegistration.Month;
	EndIf;
	
	If Not ProcessFormParameters(Parameters) Then
		
		FilterParameters = FormDataSettingsStorage.Load("EmployeeDevelopmentListForm", "FilterParameters");
		If ValueIsFilled(FilterParameters) Then
			FillPropertyValues(ThisForm, FilterParameters);
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(Period) Then
		Period = CurrentSessionDate();
	EndIf;
	
	If Not ValueIsFilled(DesignMode) Then
		DesignMode = "IncludeInPeriodOfWork";
	EndIf;
	
	AmountHeaderText = NStr("vi = 'Số tiền (%1)';
							|ru = 'Сумма (%1)';
							|en = 'Amount (%1)'; fa = 'Amount (%1)';
							|it = 'Totale (%1)';
							|pl = 'Wartość (%1)';
							|tr = 'Tutar (%1)'");
	Items.LaborCostsToRegisterSum.Title = StringFunctionsClientServer.SubstituteParametersToString(
		AmountHeaderText,
		Constants.CurrencyOfActivityKindRates.Get());
		
	GenerateCreationCommands();
	
	WhenChangingSelections();
	
	DocumentTypesUsed = New Array();
	DocumentTypesUsed.Add(Type("DocumentRef.WorkOutput"));
	DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.TeamWorkOrdersCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FilterDocumentTypes.Add(Common.MetadataObjectID(Metadata.Documents.WorkOutput));
	
	FillInFormDetailsWhenCreating();
	ConfigureDocumentManagementButtons();
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.TeamWorkOrdersFormCommands);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	TeamWorkOrders.Parameters.SetParameterValue("RefType",
		Common.MetadataObjectID("Document.WorkOutput"));
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.TeamWorkOrders,
		Metadata.Documents.WorkOutput.FullName());
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "TeamWorkOrders", "TeamWorkOrdersDate");
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If Parameters.Property("Period")
		And Not Settings.Get("Period") = Undefined Then
		Settings.Delete("Period");
	EndIf;
	
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	TimesheetChargePeriodOfEmployeesWorkOut = Settings.Get("TimesheetChargePeriodOfEmployeesWorkOut");
	
	If Not Parameters.Property("Period") Then
		Period = Settings.Get("Period");
		If Not ValueIsFilled(Period) Then
			Period = CurrentSessionDate();
		EndIf;
	EndIf;
	
	SetSelectionByPeriod();
	
	FillInLaborCostsForRegistration();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	MonthLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(Period);
	
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_WorkOutput"
		Or EventName = "Write_RMOrder"
		Or EventName = "Write_ProductionStages"
		Or EventName = "Write_ProductionOperation2_2"
		Or EventName = "Write_BackflushProduction" Then
		FillInLaborCostsForRegistration();
	EndIf;
	
	If EventName = "Write_WorkOutput" Then
		Items.TeamWorkOrders.Refresh();
	EndIf;
	
	
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	Settings.Insert("TimesheetChargePeriodOfEmployeesWorkOut", TimesheetChargePeriodOfEmployeesWorkOut);
	Settings.Insert("Period", Period);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DepartmentOnChange(Item)
	
	DivisionWhenChangingServerCall();
	
EndProcedure

&AtClient
Procedure FilterWorkOrderKindOnChange(Item)
	
	TypeOfOutfitWhenChangingServerCall();
	
EndProcedure

&AtClient
Procedure TeamOnChange(Item)
	
	BrigadeWhenChangingServerCall();
	
EndProcedure

&AtClient
Procedure MonthLineStartChoice(Item, ChoiceData, StandardProcessing)
	Notification = New CallbackDescription("MonthLineStartChoiceCompletion", ThisObject);
	TMCommonUseClient.StartSelectingRegistrationPeriodPresentation(Item, StandardProcessing, Period, ThisForm, Notification);
EndProcedure

&AtClient
Procedure MonthLineStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export 
	
	If SelectedPeriod <> Undefined Then
		Period = SelectedPeriod;
		MonthLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(Period);
	EndIf;
	FillInLaborCostsForRegistration();
	
EndProcedure

&AtClient
Procedure MonthLineClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure MonthLineTuning(Item, Direction, StandardProcessing)
	StandardProcessing = False;
	Period = AddMonth(Period, Direction);
	MonthLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(Period);
	FillInLaborCostsForRegistration();
EndProcedure

&AtClient
Procedure OutputRegistrationFrequencyOnChange(Item)
	FillInLaborCostsForRegistration();
EndProcedure

&AtClient
Procedure DesignModeOnChange(Item)
	SaveSelectionParameters();
EndProcedure

&AtClient
Procedure TeamWorkOrdersURLGetProcessing(Item, Var_Key, Presentation, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	
	Ref = Items.TeamWorkOrders.CurrentData.Ref;
	Var_URL = GetURL(Ref);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTeamWorkOrders

&AtClient
Procedure TeamWorkOrdersOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure TeamWorkOrdersSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.TeamWorkOrdersStatusPresentation Then
	EndIf;
	
EndProcedure

&AtClient
Procedure TeamWorkOrdersBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	If Copy Then
		TMCommonUseClient.CopyItem(Item);
	Else
		OpenForm("Document.WorkOutput.ObjectForm");
	EndIf;
	Cancel = True;
	
EndProcedure

&AtClient
Procedure TeamWorkOrdersBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure TeamWorkOrdersBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.SetDeletionMark(Items.TeamWorkOrders, Title);
	
EndProcedure

#EndRegion

#Region EventHandlersForFormTableElementsListOfProductionLaborCosts

&AtClient
Procedure LaborCostsToRegisterSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Item.CurrentData;
	If CurrentData <> Undefined Then
		If Field.Name = "LaborCostsToRegisterPerformer" Then
			ShowValue(Undefined, CurrentData.Performer);
		ElsIf Field.Name = "LaborCostsForRegistrationTypeOfWork" Then
			ShowValue(Undefined, CurrentData.WorkKind);
		ElsIf Field.Name = "LaborCostsToRegisterDepartment" Then
			ShowValue(Undefined, CurrentData.Department);
		ElsIf Field.Name = "LaborCostsToRegisterReferenceOrder" Then
			ShowValue(Undefined, CurrentData.ReferenceOrder);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdateDataCommand(Command)
	
	FillInLaborCostsForRegistration();
	
EndProcedure

&AtClient
Procedure TheDeployCommandOnTheOrders(Command)
	
	DeployOnOrdersWhenChangingServerCall();
	
EndProcedure

&AtClient
Procedure TheCommandToIssueInOrder(Command)
	
	ClearMessages();
	
	If Items.LaborCostsToRegister.SelectedRows.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chọn.';
										|ru = 'Команда не может быть выполнена для указанного объекта.';
										|en = 'Command cannot be executed for the specified object.'; fa = 'Command cannot be executed for the specified object.';
										|it = 'Il comando non può essere eseguito per l''oggetto indicato.';
										|pl = 'Nie można wykonać polecenia dla określonego obiektu.';
										|tr = 'Belirtilen nesne için komut gerçekleştirilemez.'"));
		Return;
	EndIf;
	
	DesignParameters = DesignParametersOnServer(Items.LaborCostsToRegister.SelectedRows);
	
	If DesignParameters = Undefined Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Theo các đơn đặt hàng đã chọn, sự phát triển của nhân viên đã được ban hành hoặc không cần đăng ký.';
				|ru = 'По выбранным распоряжениям выработка сотрудников уже оформлена или оформление не требуется.';
				|en = 'Timesheets charge for the selected references has already been registered or registration is not required.'; fa = 'Timesheets charge for the selected references has already been registered or registration is not required.';
				|it = 'Per le disposizioni selezionate, la produttività dei dipendenti è già stata formalizzata o la formalizzazione non è richiesta.';
				|pl = 'Wg wybranych zamówień wytwarzanie pracowników już jest sporządzone lub sporządzenie nie jest wymagane.';
				|tr = 'Seçili talimatlara göre zaman çizelgesi bazlı ücretlendirmesi zaten düzenlenmiş veya düzenleme gerekli değil.'"));
		Return;
	EndIf;
	
	DesignParameters.Insert("Periodicity",   Periodicity);
	
	If DesignMode = "IncludeInPeriodOfWork" Then
		DesignParameters.Insert("IncludeInPeriodOfWork", True);
	Else
		DesignParameters.Insert("IncludeInPeriodOfWork", False);
	EndIf;
	
	If DesignParameters.OneDocumentIsRequired Then
		
		DesignParameters.Insert("FillInByPicking", True);
		
		FormParameters = New Structure("FillingValues", DesignParameters);
		OpenForm("Document.WorkOutput.ObjectForm", FormParameters);
		
	Else
		
		DesignParameters.Insert("BeginOfPeriod",   BegOfMonth(Period));
		DesignParameters.Insert("EndOfPeriod",    EndOfMonth(Period));
		
		TimeConsumingOperation = FormInBackground(DesignParameters);
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		CallbackDescription = New CallbackDescription("GenerateDocumentsCompletion", ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	
	TMCommonUseClient.EditPeriod(TimesheetChargePeriodOfEmployeesWorkOut, , Notification);
	
EndProcedure

&AtClient
Procedure CreateACustomOutfitCommand(Command)
	
	CreateOutfit(PredefinedValue("Enum.TeamWorkOrderKinds.Personal"));
	
EndProcedure

&AtClient
Procedure CreateTeamOutfitCommand(Command)
	
	CreateOutfit(PredefinedValue("Enum.TeamWorkOrderKinds.TeamKind"));
	
EndProcedure

&AtClient
Procedure CreateAProductionByOrder21(Command)
	CreateOutfit(PredefinedValue("Enum.TeamWorkOrderKinds.TeamByOrder21"));
	Return; // in KA empty
	
EndProcedure

&AtClient
Procedure CreateOutputWithoutOrder21(Command)
	CreateOutfit(PredefinedValue("Enum.TeamWorkOrderKinds.TeamWithoutOrder21"));
EndProcedure

&AtClient
Procedure ChangeSelectedItems(Command)
	
	References = New Array;
	For Each RowSelected In Items.TeamWorkOrders.SelectedRows Do
		RowData = Items.TeamWorkOrders.RowData(RowSelected);
		References.Add(RowData.Ref);
	EndDo;
	
	If References.Count() = 0 Then
		Return;
	EndIf;
	
	BatchEditObjectsClient.ChangeSelectedItems(References);
	
EndProcedure

&AtClient
Procedure BrigadeSquadsToConduct(Command)
	
	TMCommonUseClient.PostDocuments(Items.TeamWorkOrders, Title);
	
EndProcedure

&AtClient
Procedure BrigadeSquadsCancelEvent(Command)
	
	TMCommonUseClient.UndoPosting(Items.TeamWorkOrders, Title);
	
EndProcedure

&AtClient
Procedure BrigadeOutfitsToUpdate(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.WorkOutput.Form.DocumentsListForm.BrigadeOutfitsToUpdate");
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.TeamWorkOrders);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.TeamWorkOrders, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.TeamWorkOrders);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.TeamWorkOrders);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure


#EndRegion

#Region Private

#Region FormControl

&AtServer
Procedure GenerateCreationCommands()
	
	CreationCommands = New Array;
	CreationCommands.Add("CreateABrigadeOutfit");
	CreationCommands.Add("CreateAPersonalOutfit");
	CreationCommands.Add("CreateAProductionByOrder");
	CreationCommands.Add("CreateOutputWithoutOrder");
	
	ProductionIsUsed22 = GetFunctionalOption("UseProductionManagement2_2");
	TitleTemplate1 = NStr("vi = '%1 (2.1)';
							|ru = '%1 (2.1)';
							|en = '%1 (2.1)'; fa = '%1 (2.1)';
							|it = '%1 (2.1)';
							|pl = '%1 (2.1)';
							|tr = '%1 (2.1)'");
	
	For Each CreationCommand In CreationCommands Do
		
		NewButton = Items.Add(CreationCommand, Type("FormButton"), Items.BrigadeSquadsCreateGroupGeneratedBy);
		NewButton.CommandName = CreationCommand;
		
		If ProductionIsUsed22
			And (CreationCommand = "CreateOutputWithoutOrder"
				Or CreationCommand = "CreateAProductionByOrder") Then
			NewButton.Title = StrTemplate(TitleTemplate1, Commands.Find(CreationCommand).Title);
		EndIf;
			
	EndDo;
		
EndProcedure

#EndRegion

#Region Filters

&AtServer
Procedure WhenChangingSelections()
	
	SetSelectionByDivision();
	SetSelectionByTypeOfOutfit();
	EstablishSelectionByBrigade();
	
	FillInLaborCostsForRegistration();
	
	SaveSelectionParameters();
	
EndProcedure

&AtServer
Procedure SaveSelectionParameters()
	
	FilterParameters = New Structure("Team,FilterWorkOrderKind,Department,DesignMode,Period");
	FillPropertyValues(FilterParameters, ThisForm);
	FormDataSettingsStorage.Save("EmployeeDevelopmentListForm", "FilterParameters", FilterParameters);
	
EndProcedure

&AtServer
Procedure DivisionWhenChangingServerCall()
	
	SetSelectionByDivision();
	FillInLaborCostsForRegistration();
	
	SaveSelectionParameters();
	
EndProcedure

&AtServer
Procedure TypeOfOutfitWhenChangingServerCall()

	SetSelectionByTypeOfOutfit();
	FillInLaborCostsForRegistration();

	SaveSelectionParameters();
	
EndProcedure

&AtServer
Procedure BrigadeWhenChangingServerCall()
	
	EstablishSelectionByBrigade();
	FillInLaborCostsForRegistration();
	
	SaveSelectionParameters();
	
EndProcedure

&AtServer
Procedure DeployOnOrdersWhenChangingServerCall()
	
	ShowReferences = Not ShowReferences;
	Items.LaborCostsToRegisterExpandByReferences.Check = ShowReferences;
	
	FillInLaborCostsForRegistration();
	
EndProcedure

&AtServer
Procedure SetSelectionByDivision()
	
	CommonClientServer.SetDynamicListFilterItem(
		TeamWorkOrders, 
		"Department", 
		Department, 
		DataCompositionComparisonType.Equal,
		, // Presentation - automatically
		ValueIsFilled(Department));
		
EndProcedure

&AtServer
Procedure EstablishSelectionByBrigade()
	
	CommonClientServer.SetDynamicListFilterItem(
		TeamWorkOrders, 
		"Team", 
		Team, 
		DataCompositionComparisonType.Equal,
		, // Presentation - automatically
		ValueIsFilled(Team));
		
EndProcedure

&AtServer
Procedure SetSelectionByTypeOfOutfit()
	
	CommonClientServer.SetDynamicListFilterItem(
		TeamWorkOrders,
		"WorkOrderKind",
		FilterWorkOrderKind,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(FilterWorkOrderKind));
	
EndProcedure

#EndRegion

#Region FillingInData

&AtServer
Procedure FillInLaborCostsForRegistration()
	
	LaborCostsToRegister.Clear();
	
	FilterStructure1 = New Structure;
	
	If ValueIsFilled(Department) Then
		FilterStructure1.Insert("Department", Department);
	EndIf;
	If ValueIsFilled(Team) Then
		FilterStructure1.Insert("Team", Team);
	EndIf;
	If ValueIsFilled(FilterWorkOrderKind) Then
		FilterStructure1.Insert("WorkOrderKind", FilterWorkOrderKind);
	EndIf;
	
	FilterStructure1.Insert("BeginOfPeriod", BegOfMonth(Period));
	FilterStructure1.Insert("EndOfPeriod", EndOfMonth(Period));
	FilterStructure1.Insert("Periodicity", Periodicity);
	FilterStructure1.Insert("CollapseOrders", Not ShowReferences);
	
	ToRegister = Documents.WorkOutput.LaborCostsToRegister(FilterStructure1);
	
	Table = ToRegister.Unload();
	Table.GroupBy("WorkOrderKind,Department,Organization,ReferenceOrder,Period,BeginOfPeriod,EndOfPeriod,ExecutionDate,Team,Performer,Employee_","Sum");
	
	LaborCostsToRegister.Load(Table);
	LaborCostsToRegister.Sort("BeginOfPeriod");
	
	For Each String In LaborCostsToRegister Do
		String.Period.StartDate = String.BeginOfPeriod;
		String.Period.EndDate = String.EndOfPeriod;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormationOfOutfits

&AtClient
Procedure CreateOutfit(WorkOrderKind)
	
	FillingValues = New Structure;
	FillingValues.Insert("WorkOrderKind", WorkOrderKind);
	
	If ValueIsFilled(Department) Then
		FillingValues.Insert("Department", Department);
	EndIf;
	
	If ValueIsFilled(Team) Then
		FillingValues.Insert("Team", Team);
	EndIf;
	
	FormParameters = New Structure("FillingValues", FillingValues);
	
	OpenForm("Document.WorkOutput.ObjectForm", FormParameters);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Function ProcessFormParameters(FormParameters)
	
	ParametersProcessed = False;
	
	If FormParameters.Property("QuickFilterStructure") Then
		
		FormParameters.QuickFilterStructure.Property("Team", Team);
		FormParameters.QuickFilterStructure.Property("WorkOrderKind", FilterWorkOrderKind);
		FormParameters.QuickFilterStructure.Property("Department", Department);
		
		ParametersProcessed = True;
		
		Return ParametersProcessed;
		
	EndIf;
	
	If FormParameters.Property("Department") Then
		Department = FormParameters.Department;
		ParametersProcessed = True;
	EndIf;
	
	If FormParameters.Property("Period") Then
		Period = FormParameters.Period;
		ParametersProcessed = True;
	EndIf;
	
	If FormParameters.Property("DesignMode") Then
		DesignMode = FormParameters.DesignMode;
		ParametersProcessed = True;
	EndIf;
	
	If FormParameters.Property("GoToList") Then
		Items.GroupPages.CurrentPage = Items.GroupBrigadierOutfits;
	EndIf;
	
	Return ParametersProcessed;
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// detailed fields are hidden if U-turn by orders is disabled
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LaborCostsForRegistrationDate.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LaborCostsToRegisterReferenceOrder.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LaborCostsToRegisterPerformer.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ShowReferences");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// the brigade is hidden when turning around by orders
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LaborCostsToRegisterTeam.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ShowReferences");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// for personal outfits, instead of a brigade, a substitute text 
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LaborCostsToRegisterTeam.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LaborCostsToRegister.Team");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<công nhân>';
													|ru = '<работники>';
													|en = '<employees>'; fa = '<employees>';
													|it = '<dipendenti>';
													|pl = '<employees>';
													|tr = '<çalışanlar>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	// the order is drawn up in color as a hyperlink
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LaborCostsToRegisterReferenceOrder.Name);
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
EndProcedure

#EndRegion

#Region DocumentJournal

&AtServer
Procedure FillInFormDetailsWhenCreating()
	
	TableOfValuesAvailable = Documents.WorkOutput.InitializeBusinessTransactionsAndDocuments(
		BusinessTransactionsAndDocuments.Unload());
	
	BusinessTransactionsAndDocuments.Load(TableOfValuesAvailable);
	
EndProcedure

&AtServer
Procedure ConfigureDocumentManagementButtons()
	
	ParametersStructure = TMCommonUse.StructureOfSettingsForDocumentManagementButtons();
	ParametersStructure.Form                                             = ThisObject;
	ParametersStructure.NameOfCreateGroup                                  = "BrigadeSquadsCreateGroupGeneratedBy";
	ParametersStructure.GroupNameCreateContext                          = "BrigadeSquadsAreGroupToCreateGeneratedContext";
	ParametersStructure.NameOfCopyButton                              = "TeamWorkOrdersCopy";
	ParametersStructure.NameOfCopyContextMenuButton               = "TeamWorkOrdersContextMenuCopy";
	ParametersStructure.ChangeButtonName                                 = "ChangeBrigadeOutfits";
	ParametersStructure.NameOfChangeContextMenuButton                  = "BrigadeSquadsContextMenuEdit";
	ParametersStructure.ButtonNamePost                                 = "BrigadeSquadsToConduct";
	ParametersStructure.NameOfHoldContextMenuButton                  = "BrigadeSquadsContextMenuToHold";
	ParametersStructure.NameOfCancelEventButton                         = "BrigadeSquadsCancellationOfEvent";
	ParametersStructure.NameOfCancelButtonIsContextMenu          = "BrigadeTeamsContextMenuCancellationOfEvent";
	ParametersStructure.NameOfMarkDeleteButton                = "BrigadeTeamsSetRemoveDeletionMark";
	ParametersStructure.ButtonNameMarkDeleteContextMenu = "BrigadeTeamsContextMenuSetUncheckDelete";
	
	TMCommonUse.ConfigureDocumentManagementButtons(ParametersStructure);
	
	Items[ParametersStructure.NameOfCreateGroup].Picture = PictureLib.CreateListItem;
	
EndProcedure

#EndRegion

#Region FormServiceCommandHandlers

&AtClient
Procedure SetDateIntervalCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	SetSelectionByPeriod();
	
EndProcedure

&AtServer
Procedure SetSelectionByPeriod()
	
	TeamWorkOrders.Parameters.SetParameterValue("BeginOfPeriod", TimesheetChargePeriodOfEmployeesWorkOut.StartDate);
	TeamWorkOrders.Parameters.SetParameterValue("EndOfPeriod", TimesheetChargePeriodOfEmployeesWorkOut.EndDate);
	
EndProcedure

&AtServer
Function FormInBackground(FilterStructure1)
	
	ProcedureName = "Documents.WorkOutput.GenerateDocuments";
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 0;
	
	Return TimeConsumingOperations.ExecuteInBackground(ProcedureName, FilterStructure1, ExecutionParameters);
	
EndFunction

&AtClient
Procedure GenerateDocumentsCompletion(Var_Parameters, AddlParameters) Export
	
	Result = GetFromTempStorage(Var_Parameters.ResultAddress);
	
	If Var_Parameters.Status = "Error" Then
		
		CommonClientServer.MessageToUser(
			StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Xảy ra lỗi trong khi xử lý chứng từ: %1';
																			|ru = 'При оформлении документов возникла ошибка: %1';
																			|en = 'An error occurred while registering the documents: %1'; fa = 'An error occurred while registering the documents: %1';
																			|it = 'Si è verificato un errore durante la formalizzazione dei documenti: %1';
																			|pl = 'Podczas sporządzenia dokumentów wystąpił błąd: %1';
																			|tr = 'Belgeler düzenlenirken hata oluştu: %1'"),
			Result.DetailErrorDescription));
		
	ElsIf Result = Undefined Then
		
		CommonClientServer.MessageToUser(NStr("vi = 'Khi lập chứng từ có lỗi không phân loại';
												|ru = 'При оформлении документов возникла неклассифицированная ошибка';
												|en = 'An unclassified error occurred while registering the documents'; fa = 'An unclassified error occurred while registering the documents';
												|it = 'Si è verificato un errore non classificato durante la formalizzazione dei documenti';
												|pl = 'Podczas sporządzenia dokumentów wystąpił nieklasyfikowany błąd';
												|tr = 'Belgeler düzenlenirken sınıflandırılmamış bir hata oluştu'"));
		
	ElsIf Result.DocumentsCount > 0 Then
		
		CallbackDescription = New CallbackDescription("UpdateListData_", ThisForm);
		OpenForm("Document.WorkOutput.Form.NewDocumentListForm",
						Result, ThisForm,,,,CallbackDescription);
			
	Else
		
		CommonClientServer.MessageToUser(
				NStr("vi = 'Nhóm không có sẵn. Chọn người thực hiện cần thiết và điền vào chứng từ theo cách thủ công';
					|ru = 'Групповое оформление недоступно. Выберете нужных исполнителей и заполните документы вручную';
					|en = 'Group registration is not available. Select the required assignees and fill in the documents manually'; fa = 'Group registration is not available. Select the required assignees and fill in the documents manually';
					|it = 'La formalizzazione di gruppo non è disponibile. Selezionare esecutori necessari e compilare i documenti manualmente';
					|pl = 'Sporządzenie grupowe jest niedostępne. Wybierz potrzebnych wykonawców i wypełnij dokumenty ręcznie';
					|tr = 'Grup düzenlenmesi mevcut değil. Gerekli atananları seçin ve belgeleri manuel olarak doldurun'"));
		
	EndIf;
	
EndProcedure

&AtServer
Function DesignParametersOnServer(Val Rows)
	
	Return ProductionAccountingServerCall.DesignParametersForEmployees(Undefined, Rows, LaborCostsToRegister);
	
EndFunction

&AtClient
Procedure UpdateListData_(Result = Undefined, AdditionalParameters = Undefined) Export
	
	FillInLaborCostsForRegistration();
	
EndProcedure

#EndRegion

#EndRegion
