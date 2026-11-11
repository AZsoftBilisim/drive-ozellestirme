
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	OnCreatReadAtServer();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnCreatReadAtServer();

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	// The end of the handler of the "Date-change" mechanism
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If UseAccrualRule = 1 And Not ValueIsFilled(Object.AccrualRule) Then
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Quy tắc tính"".';
				|ru = 'Поле ""Правило начисления"" не заполнено.';
				|en = '""Accrual rule"" is required.'; fa = '""Accrual rule"" is required.';
				|it = 'Il campo ""Metodo di accredito"" non è compilato.';
				|pl = 'Nie wypełniono pola ""Правило начисления"".';
				|tr = '""Tahakkuk Kuralları"" alanı doldurulmadı.'"),,"Object.AccrualRule",, Cancel);
		
	EndIf;
	
	If UseValidityPeriod = 2 And Not ValueIsFilled(Object.ValidTo) Then
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Ngày hết hạn hiệu lực"".';
				|ru = 'Поле ""Дата окончания срока действия"" не заполнено.';
				|en = '""Validity period end date"" is required.'; fa = '""Validity period end date"" is required.';
				|it = 'Il campo ""Data termine di validità"" non è compilato.';
				|pl = 'Nie wypełniono pola ""Data zakończenia срока действия"".';
				|tr = '""Geçerlilik bitiş tarihi"" alanı doldurulmadı.'"),,"Object.ValidTo",, Cancel);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure  AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If ManualCalculationOption = 1 Then
		CurrentObject.RuleKind = Enums.KindsOfBonusPointAccrualRules.Accrual;
	ElsIf ManualCalculationOption = 2 Then
		CurrentObject.RuleKind = Enums.KindsOfBonusPointAccrualRules.WriteOff;
	Else
		CurrentObject.RuleKind = Enums.KindsOfBonusPointAccrualRules.EmptyRef();
	EndIf;
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AccrualRuleOnChange(Item)
	AccrualRuleForChangesOnServer();
EndProcedure

&AtClient
Procedure UseValidityPeriodOnChange(Item)
	
	If UseValidityPeriod = 1 Then
		Object.NumberOfValidityPeriods = 1;
	Else
		Object.NumberOfValidityPeriods = 0;
	EndIf;
	
	If UseValidityPeriod <> 2 Then
		Object.ValidTo = Undefined;
	EndIf;
	
	ChangeAvailability(ThisForm);
	
EndProcedure

&AtClient
Procedure UseActionStartDelayOnChange(Item)
	
	Object.NumberOfActionStartDelayPeriods = UseActionStartDelay;
	
	ChangeAvailability(ThisForm);
	
EndProcedure

&AtClient
Procedure UseAccrualRuleOnChange(Item)
	
	ManualCalculationOption = 0;
	
	Object.AccrualRule = PredefinedValue("Catalog.CustomerRewardProgramRules.EmptyRef");
	
	AccrualRuleForChangesOnServer();
	
EndProcedure

&AtClient
Procedure RuleKindOnChange()
	
	WriteOff = PredefinedValue("Enum.KindsOfBonusPointAccrualRules.WriteOff");
	Accrual = PredefinedValue("Enum.KindsOfBonusPointAccrualRules.Accrual");
	
	If (Object.RuleKind = WriteOff) Then
		
		UseValidityPeriod                      = 0;
		Object.NumberOfValidityPeriods               = 0;
		UseActionStartDelay              = 0;
		Object.NumberOfActionStartDelayPeriods = 0;
		Object.ValidTo               = Undefined;
		
	EndIf;
	
	Items.Accruals.Visible = (Object.RuleKind = Accrual);
	Items.WriteOffs.Visible   = (Object.RuleKind = WriteOff);
	
	Items.GroupExpirationDates.Visible = (Object.RuleKind = Accrual);
	
	ChangeAvailability(ThisForm);
	
EndProcedure

&AtClient
Procedure ToUseTheRuleOfChargingManualChargingOnChange(Item)
	
	Object.AccrualRule = PredefinedValue("Catalog.CustomerRewardProgramRules.EmptyRef");
	UseAccrualRule = 0;
	
	AccrualRuleForChangesOnServer();
	
	Object.RuleKind = PredefinedValue("Enum.KindsOfBonusPointAccrualRules.Accrual");
	
	RuleKindOnChange();
	
EndProcedure

&AtClient
Procedure ToUseAccrualRulesManualWriteOffOnChange(Item)
	
	Object.AccrualRule = PredefinedValue("Catalog.CustomerRewardProgramRules.EmptyRef");
	UseAccrualRule = 0;
	
	AccrualRuleForChangesOnServer();
	
	Object.RuleKind = PredefinedValue("Enum.KindsOfBonusPointAccrualRules.WriteOff");
	
	RuleKindOnChange();
	
EndProcedure

&AtClient
Procedure ActionPeriodClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure PeriodOfActionStartDelayClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ValidToOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Not ExpirationDateEnteredCorrectly() Then
		Object.ValidTo = '0001-01-01';
	EndIf;
	
EndProcedure

&AtClient
Procedure ValidToChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If Not ExpirationDateEnteredCorrectly(ValueSelected) Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure Fill(Command)
	
	FillAtServer();
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure ChangeAvailability(Form)
	
	Accrual = PredefinedValue("Enum.KindsOfBonusPointAccrualRules.Accrual");
	WriteOff = PredefinedValue("Enum.KindsOfBonusPointAccrualRules.WriteOff");
	
	If Form.UseAccrualRule = 1 Then
		Form.Items.Accruals.Visible = (Form.RuleKind = Accrual);
		Form.Items.WriteOffs.Visible   = (Form.RuleKind = WriteOff);
		
		Form.Items.GroupExpirationDates.Visible = (Form.RuleKind = Accrual);
	Else
		Form.Items.Accruals.Visible = (Form.Object.RuleKind = Accrual);
		Form.Items.WriteOffs.Visible   = (Form.Object.RuleKind = WriteOff);
		
		Form.Items.GroupExpirationDates.Visible = (Form.Object.RuleKind = Accrual);
	EndIf;
	
	Form.Items.ActionPeriod.Enabled             = (Form.UseValidityPeriod = 1);
	Form.Items.NumberOfValidityPeriods.Enabled = (Form.UseValidityPeriod = 1);
	
	Form.Items.ValidTo.Enabled = (Form.UseValidityPeriod = 2);
	
	Form.Items.NumberOfActionStartDelayPeriods.Enabled = (Form.UseActionStartDelay = 1);
	Form.Items.PeriodOfActionStartDelay.Enabled             = (Form.UseActionStartDelay = 1);
	
	Form.Items.AccrualRule.Enabled           = (Form.UseAccrualRule = 1);
	Form.Items.AccrualRuleRuleKind.Enabled = (Form.UseAccrualRule = 1);
	
	Form.Items.AccrualsFill.Visible = (Form.UseAccrualRule = 1) And ValueIsFilled(Form.Object.AccrualRule);
	Form.Items.WriteOffsFill.Visible   = (Form.UseAccrualRule = 1) And ValueIsFilled(Form.Object.AccrualRule);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillFormSettings(Form)
	
	Form.UseAccrualRule      = ?(ValueIsFilled(Form.Object.AccrualRule), 1, 0);
	Form.UseActionStartDelay = ?(Form.Object.NumberOfActionStartDelayPeriods > 0, 1, 0);
	
	Accrual = PredefinedValue("Enum.KindsOfBonusPointAccrualRules.Accrual");
	WriteOff = PredefinedValue("Enum.KindsOfBonusPointAccrualRules.WriteOff");
	
	If Form.UseAccrualRule = 0 Then
		If Form.Object.RuleKind = Accrual Then
			Form.ManualCalculationOption = 1;
		ElsIf Form.Object.RuleKind = WriteOff Then
			Form.ManualCalculationOption = 2;
		Else
			Form.ManualCalculationOption         = 0;
			Form.UseAccrualRule = 1;
		EndIf;
	Else
		Form.ManualCalculationOption = 0;
	EndIf;
	
	If Form.Object.NumberOfValidityPeriods > 0 Then
		Form.UseValidityPeriod = 1;
	ElsIf ValueIsFilled(Form.Object.ValidTo) Then
		Form.UseValidityPeriod = 2;
	Else
		Form.UseValidityPeriod = 0;
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureAvailabilityOfItemsThatAreNotRelatedToItem()

	HasEditPermission = AccessRight("Update", Object.Ref.Metadata());
	Items.GroupAccrualRule.ReadOnly = (Not HasEditPermission);
	Items.ValidityGroup.ReadOnly = (Not HasEditPermission);
	Items.DeferredActionGroup.ReadOnly = (Not HasEditPermission);
	
EndProcedure

&AtServer
Procedure AccrualRuleForChangesOnServer()
	
	Query = New Query(
	"SELECT
	|	CustomerRewardProgramRules.ActionPeriod                           AS ActionPeriod,
	|	CustomerRewardProgramRules.NumberOfValidityPeriods               AS NumberOfValidityPeriods,
	|	CustomerRewardProgramRules.NumberOfActionStartDelayPeriods AS NumberOfActionStartDelayPeriods,
	|	CustomerRewardProgramRules.PeriodOfActionStartDelay             AS PeriodOfActionStartDelay,
	|	CustomerRewardProgramRules.RuleKind                               AS RuleKind
	|FROM
	|	Catalog.CustomerRewardProgramRules AS CustomerRewardProgramRules
	|WHERE
	|	CustomerRewardProgramRules.Ref = &AccrualRule
	|");
	
	Query.SetParameter("AccrualRule", Object.AccrualRule);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		
		RuleKind = Selection.RuleKind;
		
		Object.NumberOfValidityPeriods               = Selection.NumberOfValidityPeriods;
		Object.NumberOfActionStartDelayPeriods = Selection.NumberOfActionStartDelayPeriods;
		Object.PeriodOfActionStartDelay             = Selection.PeriodOfActionStartDelay;
		Object.ActionPeriod                           = Selection.ActionPeriod;
		Object.ValidTo               = Undefined;
		
	Else
		
		RuleKind = Undefined;
		
		If (Object.RuleKind = PredefinedValue("Enum.KindsOfBonusPointAccrualRules.WriteOff")) Then
			
			UseValidityPeriod                      = 0;
			Object.NumberOfValidityPeriods               = 0;
			UseActionStartDelay              = 0;
			Object.NumberOfActionStartDelayPeriods = 0;
			Object.ValidTo               = Undefined;
			
		EndIf;
		
	EndIf;
	
	ChangeAvailability(ThisForm);
	
EndProcedure

&AtServer
Procedure FillAtServer()
	
	Object.Accrual.Clear();
	Object.WriteOff.Clear();
	
	RuleKind = Common.ObjectAttributeValue(Object.AccrualRule, "RuleKind");
	
	AccrualAndWriteOffTable = BonusPointsServer.AccrualAndWriteOffTable(Object.AccrualRule, Object.Date);
	For Each TSRow In AccrualAndWriteOffTable Do
		
		If RuleKind = Enums.KindsOfBonusPointAccrualRules.Accrual Then
			NewRow = Object.Accrual.Add();
		Else
			NewRow = Object.WriteOff.Add();
		EndIf;
		
		NewRow.Partner = TSRow.Partner;
		NewRow.Points = TSRow.AccrualAmount;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure OnCreatReadAtServer()
	
	RuleKind = Common.ObjectAttributeValue(Object.AccrualRule, "RuleKind");

	ConfigureAvailabilityOfItemsThatAreNotRelatedToItem();
	
	FillFormSettings(ThisForm);
	
	ChangeAvailability(ThisForm);
	
EndProcedure

&AtServerNoContext
Function SessionDate()
	
	Return CurrentSessionDate();
	
EndFunction

&AtClient
Function ExpirationDateEnteredCorrectly(EnteredEndDate = Undefined)
	
	If EnteredEndDate = Undefined Then
		EnteredEndDate = Object.ValidTo;
	EndIf;
	
	If Parameters.Key.IsEmpty() Then
		DateMinimum = BegOfDay(SessionDate());
	Else
		DateMinimum = BegOfDay(Object.Date);
	EndIf;
	
	If EnteredEndDate >= DateMinimum Then
		Return True;
	EndIf;
	
	PatternOfTheWarningText = NStr("vi = 'Ngày hết hạn không thể nhỏ hơn %1.';
									|ru = 'Дата окончания срока действия не может быть меньше %1.';
									|en = 'Expiration date cannot be less than %1.'; fa = 'Expiration date cannot be less than %1.';
									|it = 'La data di fine termine di validità non può essere antecedente %1.';
									|pl = 'Data terminu wygaśnięcia nie może być mniejsza niż %1.';
									|tr = 'Geçerlilik bitiş tarihi, %1 tarihinden önce olamaz.'");
	WarningText = StringFunctionsClientServer.SubstituteParametersToString(PatternOfTheWarningText, Format(DateMinimum, "DLF=D"));
	ShowMessageBox(, WarningText);
	
	Return False;
	
EndFunction

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
	If Item.Name = "sh_ShamsiInput_ValidTo" Then
		ValidToOnChange(Items.ValidTo);
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
