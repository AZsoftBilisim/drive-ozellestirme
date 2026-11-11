
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Cấm tạo trực tác chứng từ ""%1"".
				|Đang tạo tự động các chứng từ,
				|khi thực hiện giao dịch thường kỳ đóng tháng tương ứng.';
				|ru = 'Интерактивное создание документов ""%1"" запрещено.
				|Создание документов выполняется автоматически,
				|при выполнении соответствующей регламентной операции закрытия месяца.';
				|en = 'Interactive document creation ""%1"" is prohibited. 
				|Documents are created automatically 
				| while the corresponding month-end transaction is executed.'; fa = 'Interactive document creation ""%1"" is prohibited. 
				|Documents are created automatically 
				| while the corresponding month-end transaction is executed.';
				|it = 'Creazione interattiva dei documenti ""%1"" non è consentita. 
				| Creazione dei documenti viene fatta automaticamente, 
				| durante l''esecuzione della relativa operazione programmata di chiusura del mese.';
				|pl = 'Interaktywne tworzenie dokumentów ""%1"" jest zabronione.
				|Tworzenie dokumentów odbywa się automatycznie,
				|podczas wykonywania odpowiedniej planowej operacji zamykania miesiąca.';
				|tr = '""%1"" belgelerinin interaktif olarak oluşturulması yasaktır.
				|Belgelerin oluşturulması,
				|ilgili ay sonu kapanışı programlı işi gerçekleştirildiğinde otomatik olarak gerçekleştirilir.'"),
			Object.Ref.Metadata().Synonym);
		
		Raise MessageText;
		
	EndIf;
	
	SetConditionalAppearance();
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not TMDataExchange.MonthClosingOperationsAreAvailableInThisNode(Cancel) Then
		Return;
	EndIf;
	
	OneOrganizationMode = ValueIsFilled(Object.Organization); // The company is listed in the document header
	
	If GetFunctionalOption("UseMultipleCompanies") Then
		
		If Not OneOrganizationMode Then
			
			CalculatedCompanies = CostCalculationAppliedAlgorithms.CalculatedCompanies(
				Object.Companies.Unload().UnloadColumn("Organization"));
			
			If IsBlankString(CalculatedCompanies) Then 
				CalculatedCompanies = NStr("vi = 'Hãy chỉ ra doanh nghiệp để hạch toán';
											|ru = 'Укажите организацию для расчета';
											|en = 'Specify a company for settlement'; fa = 'Specify a company for settlement';
											|it = 'Indicate la società per il calcolo';
											|pl = 'Podaj firmę do kalkulacji';
											|tr = 'Mutabakat için iş yeri belirt'");
			EndIf;
			
		EndIf;
		
		Items.Organization.Visible 				= OneOrganizationMode;
		Items.CalculatedCompanies.Visible = Not OneOrganizationMode;
		
	EndIf;
	
	If ValueIsFilled(Object.MonthEndClosingMode) Then
		ViewCalculationOption = Object.MonthEndClosingMode;
	ElsIf Object.PreliminaryCalculation Then
		ViewCalculationOption = NStr("vi = 'Sơ bộ';
									|ru = 'Предварительный';
									|en = 'Preliminary'; fa = 'مقدماتی';
									|it = 'Preliminare';
									|pl = 'Wstępny';
									|tr = 'Başlangıc'");
	Else
		ViewCalculationOption = NStr("vi = 'Thực tế';
									|ru = 'Фактический';
									|en = 'Actual'; fa = 'واقعی';
									|it = 'Effettivo';
									|pl = 'Faktyczny';
									|tr = 'Gerçek'");
	EndIf;
	PresentationEvaluationMethod    = String(?(Object.PreliminaryCalculation Or GetFunctionalOption("BaseVersion"),
		Enums.InventoryValuationMethods.AveragePerMonth, Object.EvaluationMethod));
		
	Items.EntryType.Visible = ValueIsFilled(Object.EntryType);
	ReadOnly = True;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
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

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();


	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PresentationEvaluationMethod.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PreliminaryCalculation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.EvaluationMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);


	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PresentationEvaluationMethod.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PreliminaryCalculation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.EvaluationMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

EndProcedure

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
