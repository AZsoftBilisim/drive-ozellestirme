
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	CurrentAction1 = Object.Action;
	
	If Not ValueIsFilled(Object.Ref) Then
		
		If Not ValueIsFilled(Object.Owner) Then
			OwnerValue = Undefined;
			If Not Parameters.FillingValues.Property("Owner", OwnerValue) 
				Or Not ValueIsFilled(OwnerValue) Then
				
				Raise NStr("vi = 'Đối với giai đoạn mới chuẩn bị ngân sách, một mô hình ngân sách không được xác định.';
							|ru = 'Для нового этапа подготовки бюджетов не задана модель бюджетирования.';
							|en = 'Budgeting model is not specified for a new budgeting step.'; fa = 'Budgeting model is not specified for a new budgeting step.';
							|it = 'Per la nuova fase di preparazione dei bilancio non è fornito il modello di budgeting.';
							|pl = 'Dla nowego etapu przygotowania budżetów nie określono modelu budżetowania.';
							|tr = 'Bütçe hazırlığının yeni aşaması için herhangi bir bütçeleme modeli belirlenmedi.'");
				
			EndIf;
		EndIf;
		
		CopyValue = Undefined;
		If Parameters.Property("CopyingValue", CopyValue) Then
			
			ActionSettingsStore = CopyValue.SettingOfAction; // ValueStorage
			SettingsTable = ActionSettingsStore.Get();
			If SettingsTable <> Undefined Then
				 PlaceActionSettingsInTemporaryStorage(SettingsTable);
			EndIf;
			
			StorageOfControlReportSettings = CopyValue.MonitoringReportSettings; // ValueStorage
			ControlReportConfigurationTable = StorageOfControlReportSettings.Get();
			If ControlReportConfigurationTable <> Undefined Then
				MonitoringReportSettings.Load(ControlReportConfigurationTable);
			EndIf;
			
		EndIf;
	EndIf;
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
	
	FormControl();
		
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	SettingsTable = CurrentObject.SettingOfAction.Get();
	If SettingsTable <> Undefined Then
		 PlaceActionSettingsInTemporaryStorage(SettingsTable);
	EndIf;
	
	ControlReportConfigurationTable = CurrentObject.MonitoringReportSettings.Get();
	If ControlReportConfigurationTable <> Undefined Then
		MonitoringReportSettings.Load(ControlReportConfigurationTable);
	EndIf;
	
	ExecuteAutomatically = Object.ExecuteAutomatically;

	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	SettingsTable = GetActionSettingsFromTemporaryStorage();

	CurrentObject.SettingOfAction = New ValueStorage(SettingsTable);

	CurrentObject.MonitoringReportSettings = New ValueStorage(MonitoringReportSettings.Unload());
	
	If CurrentObject.ExecuteAutomatically Then
		CurrentObject.EmployeeResponsible = Undefined;
	EndIf;
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	Errors = Undefined;
	
	If Object.Action <> Enums.TypesOfBudgetingStepActions.ApprovalOfBudgets
		And Object.Action <> Enums.TypesOfBudgetingStepActions.ApprovalOfGeneratedBudgetTurnover Then
		
		SettingOfAction = GetActionSettingsFromTemporaryStorage();
		
		CheckStructure = New Structure;
		For Each ActionString In SettingOfAction Do
			CheckStructure.Insert(ActionString.Name, ActionString.Value);
		EndDo;
		
		If Object.Action = Enums.TypesOfBudgetingStepActions.SetValuesForNonFinancialItems Then
			If Not CheckStructure.Property("OperationKind") Then
				CheckStructure.Insert("OperationKind", Undefined);
			EndIf;
			If Not CheckStructure.Property("NonFinancialItem") Then
				CheckStructure.Insert("NonFinancialItem", Undefined);
			EndIf;
			If Not CheckStructure.Property("InputTemplate") Then
				CheckStructure.Insert("InputTemplate", Undefined);
			EndIf;
		EndIf;
		
		VerificationDetails_ = Enums.TypesOfBudgetingStepActions.DetailsByActionType(
																	CheckStructure, Object.Action, Object.Owner);
		
		For Each Attribute In VerificationDetails_ Do
			FoundRows = SettingOfAction.FindRows(New Structure("Name", Attribute));
			If Not FoundRows.Count() Or Not ValueIsFilled(FoundRows[0].Value) Then
				ErrorText = NStr("vi = 'Không chỉ định cài đặt hành động';
								|ru = 'Не заданы настройки действия';
								|en = 'Action settings are not specified'; fa = 'Action settings are not specified';
								|it = 'Nessuna impostazione di azione specificata';
								|pl = 'Nie określono ustawień działania';
								|tr = 'Herhangi bir eylem ayarı yapılmadı'");
				CommonClientServer.AddUserError(Errors, "", ErrorText, "");
				Break;
			EndIf;
		EndDo;
		
	EndIf;
	
	CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ActionOnChange(Item)
	
	ActionOnChangeServer();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ConfigureAction(Command)
	
	Cancel = False;
	If Object.Action = PredefinedValue("Enum.TypesOfBudgetingStepActions.ApprovalOfBudgets")
		Or Object.Action = PredefinedValue("Enum.TypesOfBudgetingStepActions.ApprovalOfGeneratedBudgetTurnover") Then
		If Not ValueIsFilled(Object.Ref) Then
			QueryText = NStr("vi = 'Để thiết lập hiệu lực, cần ghi lại đối tượng. Ghi lại?';
							|ru = 'Для настройки действия необходимо записать объект. Записать?';
							|en = 'To configure the action, save the object. Do you want to save it?'; fa = 'To configure the action, save the object. Do you want to save it?';
							|it = 'Per impostare l''azione è necessario registrare l''oggetto. Registrarlo?';
							|pl = 'Aby skonfigurować akcję, musisz zapisać obiekt. Chcesz zapisać?';
							|tr = 'Eylem ayarlamak için nesneyi kaydetmek gerekiyor. Kaydedilsin mi?'");
			CallbackDescription = New CallbackDescription("ConfigureActionCompletion", ThisObject);
			
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
			Return;
		EndIf;
	EndIf;
	
	ConfigureFragmentAction(Cancel);
	
EndProcedure

&AtClient
Procedure ConfigureActionCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		Cancel = Not Write();
	Else
		Cancel = True;
	EndIf;
	
	ConfigureFragmentAction(Cancel);

EndProcedure

&AtClient
Procedure ConfigureFragmentAction(Val Cancel)
	
	If Cancel Then
		Return;
	EndIf;
	
	Address = ?(ValueIsFilled(AddressActionSetting), AddressActionSetting, PlaceActionSettingsInTemporaryStorage());
	FormParameters = New Structure();
	FormParameters.Insert("Address", Address);
	FormParameters.Insert("BudgetingStep",	Object.Ref);
	FormParameters.Insert("BudgetingModel", Object.Owner);
	FormParameters.Insert("ActionType", Object.Action);
	
	Notification = New CallbackDescription("WhenClosingActionSettingsForm", ThisObject);
	
	NameOfConfigurationForm = NameOfConfigurationFormOnServer(Object.Action);
	OpenForm(NameOfConfigurationForm, FormParameters, ThisObject, , , , Notification);

EndProcedure

&AtClient
Procedure SetUpMonitoringReports(Command)
	
	FormParameters = New Structure();
	FormParameters.Insert("Address",					PlaceMonitoringReportSettingsInTemporaryStorage());
	FormParameters.Insert("BudgetingStep",	Object.Ref);
	FormParameters.Insert("BudgetingModel",		Object.Owner);
	FormParameters.Insert("ActionType", Object.Action);
	
	Notification = New CallbackDescription("WhenClosingControlReportConfigurationForm", ThisObject);
	
	OpenForm("Catalog.BudgetingSteps.Form.SetUpMonitoringReports", 
		FormParameters, ThisObject, , , , Notification);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisObject);
	
EndProcedure

&AtServer
Procedure ConfigureListOfStepActions()
	
	ModelDetails = Common.ObjectAttributesValues(
						Object.Owner, "UseBudgetConfirmation");
		
	If Not ModelDetails.UseBudgetConfirmation Then
		If Not Object.Action = Enums.TypesOfBudgetingStepActions.ApprovalOfBudgets Then
			RemoveActionFromList(Enums.TypesOfBudgetingStepActions.ApprovalOfBudgets);
		EndIf;
		If Not Object.Action = Enums.TypesOfBudgetingStepActions.ApprovalOfGeneratedBudgetTurnover Then
			RemoveActionFromList(Enums.TypesOfBudgetingStepActions.ApprovalOfGeneratedBudgetTurnover);
		EndIf;
	EndIf;

	If Not (GetFunctionalOption("UsePurchasePlanning")
		Or GetFunctionalOption("UseSalesPlans")
		Or GetFunctionalOption("UseProductionPlanning")
		Or GetFunctionalOption("UseAssemblyDisassemblyPlanning")
		Or GetFunctionalOption("UsePlanningOfInventoryConsumption")) Then
		RemoveActionFromList(Enums.TypesOfBudgetingStepActions.PlanEntry);
	EndIf;
	
EndProcedure

&AtServer
Procedure RemoveActionFromList(ActionType)
	
	ListItem = Items.Action.ChoiceList.FindByValue(ActionType);
	If ListItem <> Undefined Then
		Items.Action.ChoiceList.Delete(ListItem);
	EndIf;
	
EndProcedure

&AtServer
Procedure ActionOnChangeServer()
	
	If Object.Action = CurrentAction1 Then
		Return;
	EndIf;
	
	If Object.Action = Enums.TypesOfBudgetingStepActions.StepGroupRepetition
		And Not Object.ExecuteAutomatically Then
		
		Object.ExecuteAutomatically = True;
		ExecuteAutomatically = Object.ExecuteAutomatically;
		
	EndIf;
	
	AddressActionSetting = "";
	CurrentAction1 = Object.Action;
	
	If CurrentAction1 <> Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules
		And CurrentAction1 <> Enums.TypesOfBudgetingStepActions.ApprovalOfGeneratedBudgetTurnover Then
		Counter = 0;
		While Counter < MonitoringReportSettings.Count() Do
			If TypeOf(MonitoringReportSettings[Counter].BudgetProfile) <> Type("CatalogRef.BudgetProfiles") Then
				MonitoringReportSettings.Delete(Counter);
			Else
				Counter = Counter + 1;
			EndIf;
		EndDo;
	EndIf;
	
	FormControl();
	
EndProcedure

&AtServerNoContext
Function NameOfConfigurationFormOnServer(Val Action)
	
	If Action = Enums.TypesOfBudgetingStepActions.AdjustCorrectBudgets
		Or Action = Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules Then
		Action = Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm;
	ElsIf Action = Enums.TypesOfBudgetingStepActions.ApprovalOfGeneratedBudgetTurnover Then
		Action = Enums.TypesOfBudgetingStepActions.ApprovalOfBudgets;
	EndIf;
	
	Return Enums.TypesOfBudgetingStepActions.FormName(Action)
	
EndFunction

&AtServer
Procedure FormControl()
	
	ActionSelectionList = Items.Action.ChoiceList;
	ActionSelectionList.Clear();
	If ExecuteAutomatically Then
		ActionSelectionList.Add(Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm);
		ActionSelectionList.Add(Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules);
		ActionSelectionList.Add(Enums.TypesOfBudgetingStepActions.SetValuesForNonFinancialItems);
		ActionSelectionList.Add(Enums.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance);
		ActionSelectionList.Add(Enums.TypesOfBudgetingStepActions.StepGroupRepetition);
	Else
		ActionSelectionList.Add(Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm);
		ActionSelectionList.Add(Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules);
		ActionSelectionList.Add(Enums.TypesOfBudgetingStepActions.PlanEntry);
		ActionSelectionList.Add(Enums.TypesOfBudgetingStepActions.SetValuesForNonFinancialItems);
		ActionSelectionList.Add(Enums.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance);
		ActionSelectionList.Add(Enums.TypesOfBudgetingStepActions.ApprovalOfBudgets);
		ActionSelectionList.Add(Enums.TypesOfBudgetingStepActions.ApprovalOfGeneratedBudgetTurnover);
		ActionSelectionList.Add(Enums.TypesOfBudgetingStepActions.AdjustCorrectBudgets);
		ActionSelectionList.Add(Enums.TypesOfBudgetingStepActions.StepGroupRepetition);
		ActionSelectionList.Add(Enums.TypesOfBudgetingStepActions.Other);
	EndIf;
	
	ConfigureListOfStepActions();
	
	ThisIsBudgetInput = (Object.Action = Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm
		Or Object.Action = Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules
		Or Object.Action = Enums.TypesOfBudgetingStepActions.AdjustCorrectBudgets);
	ThisActionIsOther = (Object.Action = Enums.TypesOfBudgetingStepActions.Other);
	ThisIsAssertionAction = (Object.Action = Enums.TypesOfBudgetingStepActions.ApprovalOfBudgets
		Or Object.Action = Enums.TypesOfBudgetingStepActions.ApprovalOfGeneratedBudgetTurnover);
	
	VisibilityOfSettings = ValueIsFilled(Object.Action) And Not ThisActionIsOther;
	Items.StepActionGroupSettings.Visible = VisibilityOfSettings;
	
	SettingOfAction = GetActionSettingsFromTemporaryStorage();
	PresentationAction = Enums.TypesOfBudgetingStepActions.GetActionPresentation(
		SettingOfAction, Object.Action);
	Items.DecorationSettings.Title = PresentationAction;
	
	TitleControlReports = NStr("vi = 'Thiết lập báo cáo kiểm toán (%1)';
								|ru = 'Настроить контрольные отчеты (%1)';
								|en = 'Set up monitoring reports (%1)'; fa = 'Set up monitoring reports (%1)';
								|it = 'Impostare i report di controllo (%1)';
								|pl = 'Ustaw raporty kontrolne (%1)';
								|tr = 'Kontrol raporlarını ayarla (%1)'");
	Items.SetUpMonitoringReports.Title = 
		StringFunctionsClientServer.SubstituteParametersToString(
			TitleControlReports, 
			MonitoringReportSettings.Count());
	
	Items.SetUpMonitoringReports.Visible = ThisActionIsOther Or ThisIsAssertionAction Or ThisIsBudgetInput;
	
	Items.EmployeeResponsible.Enabled = Not ExecuteAutomatically;
	Items.GroupBasicDuration.Enabled = Not ExecuteAutomatically;
	
	Items.EmployeeResponsible.Enabled = Not ExecuteAutomatically;
	Items.GroupBasicDuration.Enabled = Not ExecuteAutomatically;
	
	Items.ExecuteAutomatically.Enabled = Object.Action <> Enums.TypesOfBudgetingStepActions.StepGroupRepetition
	                                            And Not ReadOnly;
	
	Items.DecorationSettings.Enabled = Not ReadOnly;
	
EndProcedure

&AtServer
Function PlaceMonitoringReportSettingsInTemporaryStorage()
	
	Return PutToTempStorage(MonitoringReportSettings.Unload(), UUID);
	
EndFunction

&AtServer
Function PlaceActionSettingsInTemporaryStorage(Val SettingsTable = Undefined)
	
	If SettingsTable = Undefined Then
		SettingsTable = New ValueTable;
		SettingsTable.Columns.Add("Name");
		SettingsTable.Columns.Add("Value");
		SettingsTable.Columns.Add("Presentation");
	EndIf;

	If ValueIsFilled(AddressActionSetting) Then
		AddressActionSetting = PutToTempStorage(SettingsTable, AddressActionSetting);
	Else
		AddressActionSetting = PutToTempStorage(SettingsTable, UUID);
	EndIf;
	
	Return AddressActionSetting;
	
EndFunction

&AtServer
Function GetActionSettingsFromTemporaryStorage()
	
	SettingsTable = New ValueTable;
	SettingsTable.Columns.Add("Name");
	SettingsTable.Columns.Add("Value");
	SettingsTable.Columns.Add("Presentation");

	If ValueIsFilled(AddressActionSetting) Then
		SettingsTable = GetFromTempStorage(AddressActionSetting);
	EndIf;
	
	Return SettingsTable;
	
EndFunction

&AtServer
Procedure FillInControlReportSettingsServer(Address)
	
	MonitoringReportSettings.Load(GetFromTempStorage(Address));
	FormControl();
	
EndProcedure

&AtClient
Procedure WhenClosingActionSettingsForm(Address, AdditionalParameters) Export
	
	If Address = Undefined Then
		Return;
	EndIf;
	
	Modified = True;
	
	FormControl();
	
EndProcedure

&AtClient
Procedure WhenClosingControlReportConfigurationForm(Address, AdditionalParameters) Export
	
	If Address = Undefined Then
		Return;
	EndIf;
	
	FillInControlReportSettingsServer(Address);
	
EndProcedure

&AtClient
Procedure ExecuteAutomaticallyOnChange(Item)
	
	Object.ExecuteAutomatically = ExecuteAutomatically;
	
	If ExecuteAutomatically Then
		Object.Duration = 1;
		Object.DurationType = PredefinedValue("Enum.TypesOfBudgetingStepDurations.CalendarDays");
		If Object.Action <> PredefinedValue("Enum.TypesOfBudgetingStepActions.FillingBudgetEntryForm")
			And Object.Action <> PredefinedValue("Enum.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules")
			And Object.Action <> PredefinedValue("Enum.TypesOfBudgetingStepActions.SetValuesForNonFinancialItems")
			And Object.Action <> PredefinedValue("Enum.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance")
			And Object.Action <> PredefinedValue("Enum.TypesOfBudgetingStepActions.StepGroupRepetition") Then
			
			Object.Action = PredefinedValue("Enum.TypesOfBudgetingStepActions.FillingBudgetEntryForm");
			ActionOnChangeServer();
			Return;
			
		EndIf;
	EndIf;
	
	FormControl();
	
EndProcedure

#EndRegion
