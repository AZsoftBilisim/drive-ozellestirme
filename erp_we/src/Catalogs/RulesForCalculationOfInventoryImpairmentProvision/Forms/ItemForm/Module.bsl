#Region Variables

&AtClient
Var ParametersForRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	Schema = Catalogs.RulesForCalculationOfInventoryImpairmentProvision.GetTemplate("InventoryCost");
	AddressOfDataCompositionSchema = PutToTempStorage(Schema, UUID);
	
	GenerateTasksForTheEndOfTheMonth = False;
	
	ConfigureFieldHeaders();
	
	If Not GetFunctionalOption("UseMultipleCompanies")
	 And ValueIsFilled(Object.Owner) Then
	 	Items.Organization.Visible = False;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	// End StandardSubsystems.Core
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	StartOfActionString = TMCommonUseClient.GetPresentationOfRegistrationPeriod(Object.ValidOnDate);
	EndOfActionString = TMCommonUseClient.GetPresentationOfRegistrationPeriod(Object.ValidToDate);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Not GenerateTasksForTheEndOfTheMonth
	 And ChangedKeyDetailsOfRule()
	 And Not ThereAreTasksToCalculateCostByEndOfMonth(Object.Owner, ThePeriodOfTaskFormation) Then
	 	Cancel = True;
	 	ForceCloseTheForm = True;
	 	
	 	QueryText = NStr("vi = 'Sau khi thay đổi quy tắc, cần thực hiện
	 	|đóng tháng, bắt đầu từ ""%1"", tiếp tục?';
	 	|ru = 'После изменения правила потребуется выполнить
	 	|закрытия месяца, начиная с ""%1"", продолжить?';
	 	|en = 'After changing the rule you will need to run
	 	|month-end closing starting from ""%1"". Continue?'; fa = 'After changing the rule you will need to run
	 	|month-end closing starting from ""%1"". Continue?';
	 	|it = 'Dopo la modifica della regole è necessario completare 
	 	|la chiusura del mese, iniziando da ""%1"", continuare?';
	 	|pl = 'Po zmianie reguły trzeba będzie wykonać
	 	|zamknięcia miesiąca, zaczynając od ""%1"", kontynuować?';
	 	|tr = 'Kuralı değiştirdikten sonra ""%1""den başlayarak
	 	|ayı kapatmanız gerekecek, devam edilsin mi?'");
	 	QueryText = StrReplace(QueryText, "%1", Format(ThePeriodOfTaskFormation, "DF=MM.yyyy"));
	 	
	 	AdditionalParameters = New Structure;
		AdditionalParameters.Insert("WriteParameters", WriteParameters);
	 	
	 	CallbackDescription = New CallbackDescription("BeforeWriteCompletion", ThisObject, AdditionalParameters);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);

EndProcedure

&AtClient
Procedure BeforeWriteCompletion(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.No Then
		GenerateTasksForTheEndOfTheMonth = True;
		TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If IsTempStorageURL(AddressOfTheCDSettings) Then
	
		DCSettings = GetFromTempStorage(AddressOfTheCDSettings);
		CurrentObject.StorageOfDataCompositionSettings = New ValueStorage(DCSettings);

	Else
	
		CurrentObject.StorageOfDataCompositionSettings = New ValueStorage(Undefined);
	
	EndIf;
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	// End StandardSubsystems.Core
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	GenerateTasksForTheEndOfTheMonth = False;
	
	DCSettings = CurrentObject.StorageOfDataCompositionSettings.Get();
	If DCSettings = Undefined Then
		DCSettings = New DataCompositionSettings();
	EndIf;
	If ValueIsFilled(DCSettings) Then
		AddressOfTheCDSettings = PutToTempStorage(DCSettings, UUID);
	EndIf;
	
	ConfigureFieldHeaders();
	
	DataBanTemplate = PeriodClosingDates.DataToCheckTemplate();
	TemplateRow = DataBanTemplate.Add();
	TemplateRow.Section = "RoutineOperations";
	TemplateRow.Date = BegOfMonth(CurrentObject.ValidOnDate);
	ThereIsBanOnChanges = PeriodClosingDates.PeriodEndClosingFound(DataBanTemplate);
	If ThereIsBanOnChanges Then
		Items.Organization.ReadOnly = True;
		Items.PriceKind.ReadOnly = True;
		Items.LocalAccounting.ReadOnly = True;
		Items.ManagementAccounting.ReadOnly = True;
		Items.StartOfActionString.ReadOnly = True;
		Items.AddlOrderingAttribute.ReadOnly = True;
		Items.ConfigureTheSelectionOfLeftoversHyperlink.Enabled = False;
	EndIf;
	
	If ValueIsFilled(CurrentObject.ValidToDate) Then
		DataBanTemplate = PeriodClosingDates.DataToCheckTemplate();
		TemplateRow = DataBanTemplate.Add();
		TemplateRow.Section = "RoutineOperations";
		TemplateRow.Date = BegOfMonth(CurrentObject.ValidToDate);
		ThereIsBanOnChanges = PeriodClosingDates.PeriodEndClosingFound(DataBanTemplate);
		If ThereIsBanOnChanges Then
			Items.EndOfActionString.ReadOnly = True;
		EndIf;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If GenerateTasksForTheEndOfTheMonth Then
		PeriodOfFirstRegisteredRecords = BatchAccountingServer.PeriodOfFirstRegisteredRecordsBatchAccountingVersion22();
		Period = ThePeriodOfTaskFormation; 
		If PeriodOfFirstRegisteredRecords > Period Then
			Period = PeriodOfFirstRegisteredRecords;
		EndIf;
		InformationRegisters.JobsForMonthEndClosing.CreateRegisterEntry(Period,,
			Object.Owner,
			Catalogs.MonthEndClosingOperations.AccualOfInventoryImpairmentProvision);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StartOfActionStringStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	
	CloseHandler = New CallbackDescription("StartActionSelectEnd", ThisObject);
	FormParameters 	   = New Structure("Value, PeriodSelectionMode", Object.ValidOnDate, "MONTH");
	
	OpenForm("CommonForm.PeriodSelection",
		FormParameters, 
		ThisObject, 
		UUID,
		,
		, 
		CloseHandler,
		FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure StartActionSelectEnd(SelectedPeriod, AdditionalParameters) Export 
	If SelectedPeriod <> Undefined Then
		Object.ValidOnDate = SelectedPeriod;
		StartOfActionString = TMCommonUseClient.GetPresentationOfRegistrationPeriod(SelectedPeriod);
	EndIf;
EndProcedure

&AtClient
Procedure StartOfActionStringTuning(Item, Direction, StandardProcessing)
	StandardProcessing = False;
	Object.ValidOnDate = AddMonth(Object.ValidOnDate, Direction);
	StartOfActionString = TMCommonUseClient.GetPresentationOfRegistrationPeriod(Object.ValidOnDate);
EndProcedure

&AtClient
Procedure StartOfActionStringClearing(Item, StandardProcessing)
	Object.ValidOnDate = "";
EndProcedure

&AtClient
Procedure EndOfActionStringStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	
	CloseHandler = New CallbackDescription("EndOfActionSelectionCompletion", ThisObject);
	FormParameters 	   = New Structure("Value, PeriodSelectionMode", Object.ValidToDate, "MONTH");
	
	OpenForm("CommonForm.PeriodSelection",
		FormParameters, 
		ThisObject, 
		UUID,
		,
		, 
		CloseHandler,
		FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure EndOfActionSelectionCompletion(SelectedPeriod, AdditionalParameters) Export 
	If SelectedPeriod <> Undefined Then
		Object.ValidToDate = SelectedPeriod;
		If ValueIsFilled(Object.ValidToDate) Then
			Object.ValidToDate = EndOfMonth(Object.ValidToDate);
		EndIf;
		EndOfActionString = TMCommonUseClient.GetPresentationOfRegistrationPeriod(SelectedPeriod);
	EndIf;
EndProcedure

&AtClient
Procedure EndOfActionStringTuning(Item, Direction, StandardProcessing)
	StandardProcessing = False;
	Object.ValidToDate = AddMonth(Object.ValidToDate, Direction);
	EndOfActionString = TMCommonUseClient.GetPresentationOfRegistrationPeriod(Object.ValidToDate);
EndProcedure

&AtClient
Procedure EndOfActionStringClearing(Item, StandardProcessing)
	Object.ValidToDate = "";
EndProcedure

&AtClient
Procedure ConfigureTheSelectionOfLeftoversHyperlinkClick(Item)

	FormParameters = New Structure;
	FormParameters.Insert("DoNotPlaceSettingsToTheDataCompositionSchema", True);
	FormParameters.Insert("DoNotLoadADataLayoutDiagramFromAFile", True);
	FormParameters.Insert("DoNotConfigureSettings", True);
	FormParameters.Insert("NotEditDataCompositionSchema", True);
	FormParameters.Insert("DoNotConfigureConditionalFormatting", True);
	FormParameters.Insert("DoNotConfigureTheSelection", True);
	FormParameters.Insert("DonTAdjustTheOrder", True);
	FormParameters.Insert("UUID", UUID);
	FormParameters.Insert("AddressOfDataCompositionSchema", AddressOfDataCompositionSchema);
	FormParameters.Insert("AddressOfDataCompositionSettings", AddressOfTheCDSettings);
	FormParameters.Insert("Title", "Filter");
	
	OpenForm("CommonForm.SimplifiedSettingOfDataCompositionSchema",
		FormParameters,,,,,
		New CallbackDescription("ConfigureBalanceSelectionEnd",
			ThisObject),
		FormWindowOpeningMode.LockWholeInterface);

EndProcedure

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtServer
Procedure ConfigureFieldHeaders()
	
	PresentationOfHyperlinks = New Map();
	PresentationOfHyperlinks.Insert(True, NStr("vi = 'Đã đặt bộ lọc, thay đổi';
												|ru = 'Отбор установлен, изменить';
												|en = 'Filter is set, change'; fa = 'Filter is set, change';
												|it = 'Selezione impostata, modificare';
												|pl = 'Ustawiono filtr, zmień';
												|tr = 'Filtre ayarlandı, değiştir'"));
	PresentationOfHyperlinks.Insert(False, NStr("vi = 'Chưa đặt bộ lọc, thêm';
												|ru = 'Отбор не установлен, добавить';
												|en = 'Filter not set, add'; fa = 'Filter not set, add';
												|it = 'La selezione non è impostata, aggiungere';
												|pl = 'Nie ustawiono filtru, dodaj';
												|tr = 'Filtre ayarlanmadı, ekle'"));
	
	FilterIs_Specified = Object.VersionOfSelectionSettings > 0;
	Items.ConfigureTheSelectionOfLeftoversHyperlink.Title = PresentationOfHyperlinks.Get(FilterIs_Specified);
	
EndProcedure

&AtClient
Procedure ConfigureBalanceSelectionEnd(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	AddressOfTheCDSettings = Result;
	
	ConfigureSelectionOfBalancesOnServer();
	
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure ConfigureSelectionOfBalancesOnServer()
	DCSettings = GetFromTempStorage(AddressOfTheCDSettings);
	Object.FilterPresentation = String(DCSettings.Filter);
	If FilterIs_Specified(DCSettings) Then
		Object.VersionOfSelectionSettings = Object.VersionOfSelectionSettings + 1;
	Else
		Object.VersionOfSelectionSettings = 0;
	EndIf;
	ConfigureFieldHeaders();
EndProcedure

&AtServerNoContext
Function FilterIs_Specified(NewSettings1)
	
	FilterIs_Specified = False;
	ComposerSettings = NewSettings1; // DataCompositionSettings
	For Each FilterElement In ComposerSettings.Filter.Items Do
		If FilterElement.Use Then
			
			FilterIs_Specified = True;
			Break;
			
		EndIf;
	EndDo;
	
	For Each DataParameter In ComposerSettings.DataParameters.Items Do
		
		If (TypeOf(DataParameter.Value) = Type("Boolean") 
			And DataParameter.Value) Or FilterIs_Specified Then
			
			FilterIs_Specified = True;
			Break;
			
		EndIf;
		
	EndDo;
	
	Return FilterIs_Specified;
	
EndFunction

&AtServer
Function ChangedKeyDetailsOfRule()
	
	If Object.Ref.IsEmpty() Then
		ThePeriodOfTaskFormation = Object.ValidOnDate;
		Return True;
	EndIf;
	
	Query = New Query("
	|SELECT
	|	Rule.Ref,
	|	Rule.ValidOnDate,
	|	Rule.ValidToDate,
	|	Rule.Owner,
	|	Rule.PriceKind,
	|	Rule.LocalAccounting,
	|	Rule.ManagementAccounting,
	|	Rule.Priority,
	|	Rule.VersionOfSelectionSettings
	|FROM
	|	Catalog.RulesForCalculationOfInventoryImpairmentProvision AS Rule
	|WHERE
	|	Rule.Ref = &Ref
	|	AND (Rule.Owner <> &Owner
	|		OR Rule.PriceKind <> &PriceKind
	|		OR Rule.ValidOnDate <> &ValidOnDate
	|		OR Rule.ValidToDate <> &ValidToDate
	|		OR Rule.LocalAccounting <> &LocalAccounting
	|		OR Rule.ManagementAccounting <> &ManagementAccounting
	|		OR Rule.Priority <> &Priority
	|		OR Rule.VersionOfSelectionSettings <> &VersionOfSelectionSettings
	|	)
	|");
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Owner", Object.Owner);
	Query.SetParameter("PriceKind", Object.PriceKind);
	Query.SetParameter("ValidOnDate", Object.ValidOnDate);
	Query.SetParameter("ValidToDate", Object.ValidToDate);
	Query.SetParameter("LocalAccounting", Object.LocalAccounting);
	Query.SetParameter("ManagementAccounting", Object.ManagementAccounting);
	Query.SetParameter("Priority", Object.Priority);
	Query.SetParameter("VersionOfSelectionSettings", Object.VersionOfSelectionSettings);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		
		// If key parameters have been changed, tasks will need to be generated
		// starting from the previous start date.
		If Selection.Owner <> Object.Owner
		 Or Selection.PriceKind <> Object.PriceKind
		 Or Selection.LocalAccounting <> Object.LocalAccounting
		 Or Selection.ManagementAccounting <> Object.ManagementAccounting
		 Or Selection.Priority <> Object.Priority
		 Or Selection.VersionOfSelectionSettings <> Object.VersionOfSelectionSettings Then
			ThePeriodOfTaskFormation = Selection.ValidOnDate;
			
		// If the new expiration date of the rule is longer than the previous one, then tasks will need to be generated
		// starting from the next month, after the previous expiration date.
		ElsIf ValueIsFilled(Selection.ValidToDate)
		 And ValueIsFilled(Object.ValidToDate)
		 And Selection.ValidToDate < Object.ValidToDate Then
			ThePeriodOfTaskFormation =  AddMonth(Selection.ValidToDate, 1);
			
		// If the new expiration date of the rule is less than the previous one, then tasks will need to be generated
		// starting from the next month, after the new expiration date.
		ElsIf ValueIsFilled(Object.ValidToDate)
		 And ValueIsFilled(Selection.ValidToDate)
		 And Selection.ValidToDate > Object.ValidToDate Then
			ThePeriodOfTaskFormation = AddMonth(Object.ValidToDate, 1);
			
		// If the previous expiration date was not filled in, but the new one is filled in, then the tasks will need to be generated
		// starting from the next month, after the new expiration date.
		ElsIf Not ValueIsFilled(Selection.ValidToDate)
		 And ValueIsFilled(Object.ValidToDate) Then
			ThePeriodOfTaskFormation = AddMonth(Object.ValidToDate, 1);
			
		// If the new expiration date is not filled in, but the previous one was filled in, then the tasks will need to be generated
		// starting from the next month, after the previous expiration date.
		ElsIf Not ValueIsFilled(Object.ValidToDate)
		 And ValueIsFilled(Selection.ValidToDate) Then
			ThePeriodOfTaskFormation = AddMonth(Selection.ValidToDate, 1);
			
		// In other cases, when the start date of the action changes, the tasks will need to be generated
		// starting from the previous start date of the action.
		Else
			ThePeriodOfTaskFormation = Selection.ValidOnDate;
		EndIf;
		KeyDetailsChanged = True;
	Else
		KeyDetailsChanged = False;
	EndIf;
	
	Return KeyDetailsChanged;
	
EndFunction

&AtServerNoContext
Function ThereAreTasksToCalculateCostByEndOfMonth(Organization, Period)
	
	PeriodOfFirstRegisteredRecords = BatchAccountingServer.PeriodOfFirstRegisteredRecordsBatchAccountingVersion22();
	If PeriodOfFirstRegisteredRecords > Period Then
		Period = PeriodOfFirstRegisteredRecords;
	EndIf;
	
	Query = New Query("
	|SELECT TOP 1
	|	Jobs.Month
	|FROM
	|	InformationRegister.JobsForCalculatingCost AS Jobs
	|WHERE
	|	Jobs.Organization = &Organization
	|	AND Jobs.Month <= &Period
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	Jobs.Month
	|FROM
	|	InformationRegister.JobsForMonthEndClosing AS Jobs
	|WHERE
	|	Jobs.Operation = VALUE(Catalog.MonthEndClosingOperations.AccualOfInventoryImpairmentProvision)
	|	AND Jobs.Organization = &Organization
	|	AND Jobs.Month <= &Period
	|");
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Period", BegOfMonth(Period));
	
	Selection = Query.Execute().Select();
	Return Selection.Next();
	
EndFunction

#EndRegion
