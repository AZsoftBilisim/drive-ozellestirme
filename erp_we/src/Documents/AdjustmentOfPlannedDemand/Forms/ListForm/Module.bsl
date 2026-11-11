
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("Plan") 
		And ValueIsFilled(Parameters.Plan) Then
		
		AutoTitle = False;
		
		Title = StrTemplate(
			NStr("vi = 'Điều chỉnh nhu cầu theo kế hoạch: %1';
				|ru = 'Корректировка потребностей по плану: %1';
				|en = 'Demands adjustment by plan: %1'; fa = 'Demands adjustment by plan: %1';
				|it = 'Rettifica dei fabbisogni nel piano: %1';
				|pl = 'Korekta zapotrzebowania według planu: %1';
				|tr = 'Plana göre gereksinimlerin düzeltilmesi: %1'"),
			Parameters.Plan);
		
	EndIf;
		
	If Parameters.Property("PlanProfileStage", PlanProfile) Then
		
		AutoTitle = False;
		
		Title = StrTemplate(
			NStr("vi = 'Điều chỉnh theo nhu cầu theo công đoạn: %1';
				|ru = 'Корректировка потребностей по этапу: %1';
				|en = 'Demands adjustment by stage: %1'; fa = 'Demands adjustment by stage: %1';
				|it = 'Rettifica dei fabbisogni nella fase: %1';
				|pl = 'Korekta zapotrzebowania według etapu: %1';
				|tr = 'Etaba göre gereksinimlerin düzeltilmesi: %1'"));
			
		SetSelectionTypeOfPlanStage();
			
	EndIf;
		
	If Parameters.Property("Status") Then
		
		Status = Parameters.Status;
		SetSelectionByStatus();
		
	EndIf;

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.ListCommandBar);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterScenarioOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Scenario",  Scenario, DataCompositionComparisonType.Equal,, ValueIsFilled(Scenario));
	
EndProcedure

&AtClient
Procedure StatusFilterOnChange(Item)
	SetSelectionByStatus();
EndProcedure

&AtClient
Procedure ProductsOnChange(Item)
	
	SetSelectionByProductRange();
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleOnChange(Item)
	SetSelectionByResponsible();
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

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
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

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure SetCanceledStatus(Command)
	
	SetStatus("RolledBack", NStr("vi = 'Đã hủy bỏ';
								|ru = 'Отменена';
								|en = 'Canceled'; fa = 'لغوشده';
								|it = 'Annullata';
								|pl = 'Canceled';
								|tr = 'İptal edildi'"));
	
EndProcedure

&AtClient
Procedure SetStatusForChecking(Command)
	
	SetStatus("ForChecking", NStr("vi = 'Cần kiểm tra';
									|ru = 'К проверке';
									|en = 'To verify'; fa = 'برای تأیید';
									|it = 'Da verificare';
									|pl = 'Do sprawdzenia';
									|tr = 'Kontrol edilecek'"));
	
EndProcedure

&AtClient
Procedure SetTheConfirmedStatus(Command)
	
	SetStatus("Upholded_", NStr("vi = 'Đã duyệt';
								|ru = 'Утверждена';
								|en = 'Confirmed'; fa = 'تأییدشده';
								|it = 'Approvato';
								|pl = 'Confirmed';
								|tr = 'Onaylandı'"));
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetStatus(Status, TexStatus)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Các điều chỉnh được tô sáng trong danh sách sẽ được đặt thành trạng thái ""%Status%"". Tiếp tục?';
					|ru = 'У выделенных в списке корректировок будет установлен статус ""%Status%"". Продолжить?';
					|en = 'The ""%Status%"" status will be set for the documents selected in the adjustment list. Continue?'; fa = 'The ""%Status%"" status will be set for the documents selected in the adjustment list. Continue?';
					|it = 'Per le rettifiche evidenziate nell''elenco verrà impostato lo stato ""%Status%"". Continuare?';
					|pl = 'U zaznaczonych na liście korekt zostanie ustawiony status ""%Status%"". Kontynuować?';
					|tr = 'Listede seçili belgelerin durumu ""%Status%"" olarak kurulacak. Devam edilsin mi?'");
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

#Region Filters

&AtServer
Procedure SetSelectionByStatus()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Status",
		Status,
		DataCompositionComparisonType.Equal,
		, // Presentation - automatically
		ValueIsFilled(Status));
	
EndProcedure
	
&AtServer
Procedure SetSelectionTypeOfPlanStage()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"PlanProfile",
		PlanProfile,
		DataCompositionComparisonType.Equal,
		, // Presentation - automatically
		ValueIsFilled(PlanProfile));
	
EndProcedure

&AtServer
Procedure SetSelectionByResponsible()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"EmployeeResponsible",
		EmployeeResponsible,
		DataCompositionComparisonType.Equal,
		, // Presentation - automatically
		ValueIsFilled(EmployeeResponsible));
	
EndProcedure

&AtServer
Procedure SetSelectionByProductRange()
	
	FilterRemainingGoodsByShelfLives = CommonClientServer.CreateFilterItemGroup(
		List.SettingsComposer.FixedSettings.Filter.Items,
		NStr("vi = 'Lọc theo mặt hàng';
			|ru = 'Отбор по номенклатуре';
			|en = 'Filter by items'; fa = 'فیلتر بر اساس اقلام';
			|it = 'La selezione in base all''elenco articoli';
			|pl = 'Filtr wg towaru';
			|tr = 'Öğeye göre filtre'"),
		DataCompositionFilterItemsGroupType.OrGroup);
		
	CommonClientServer.AddCompositionItem(
		FilterRemainingGoodsByShelfLives,
		"Ref.IncreasedDemand.Products",
		DataCompositionComparisonType.Equal,
		Products,
		,
		ValueIsFilled(Products));
	
	CommonClientServer.AddCompositionItem(
		FilterRemainingGoodsByShelfLives,
		"Ref.DecreasedDemands.Products",
		DataCompositionComparisonType.Equal,
		Products,
		,
		ValueIsFilled(Products));
		
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Number.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Date.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Status.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Period.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Status.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EmployeeResponsible.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Comment.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Comment.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StatusesOfPlanAdjustments.RolledBack;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.OutdatedListTextColor);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
EndProcedure

#EndRegion

#EndRegion
