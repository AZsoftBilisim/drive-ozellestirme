
#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var ResponseBeforeWrite;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	SetConditionalAppearance();
	
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	Items.AmountEntryOptionMan.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Số tiền bằng tiền kế toán quản trị (%1)';
			|ru = 'Сумма в валюте управленческого учета (%1)';
			|en = 'Amount in management accounting currency (%1)'; fa = 'Amount in management accounting currency (%1)';
			|it = 'Importo nella valuta della contabilità gestionale (%1)';
			|pl = 'Wartość w walucie ewidencji administracyjnej (%1)';
			|tr = 'Yönetim muhasebesi para biriminde (%1)'"),
		ManagementAccountingCurrency);
	Items.CostAllocationSum.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Kế toán quản trị có Thuế GTGT (%1)';
			|ru = 'Упр. учет с НДС (%1)';
			|en = 'Management accounting including VAT (%1)'; fa = 'Management accounting including VAT (%1)';
			|it = 'Contabilità gestionale con IVA (%1)';
			|pl = 'Ewid. administr. z VAT (%1)';
			|tr = 'KDV dahil yönetim muhasebesi (%1)'"),
		ManagementAccountingCurrency);
	Items.CostAllocationSumMan.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Kế toán quản trị không có Thuế GTGT (%1)';
			|ru = 'Упр. учет без НДС (%1)';
			|en = 'Management accounting excluding VAT (%1)'; fa = 'Management accounting excluding VAT (%1)';
			|it = 'Contabilità gestionale IVA esclusa (%1)';
			|pl = 'Ewid. administr. bez VAT (%1)';
			|tr = 'KDV hariç yönetim muhasebesi (%1)'"),
		ManagementAccountingCurrency);
	
	Utbazovaya = GetFunctionalOption("BaseVersion");
	Items.GroupAccountingSections.Visible = Not Utbazovaya;
	
	SetFormElementHeaders();
		
	CostSharingMode = ?(Object.CostAllocationFromCostCenter, "FromHIA", "ByArticles");
	If Object.CostAllocationFromCostCenter Then
		ConstCenter = Object.DimensionOfExpenses;
	EndIf;
	
	DocumentAmountBeforeAdjustment     = Object.DocumentAmount;
	AmountOfLocalDocumentBeforeAdjustment = Object.TheAmountOfTheDocumentRegl;
	DocumentAmountPDBeforeAdjustment   = Object.DocumentAmountPD;
	AmountOfTDDocumentBeforeAdjustment   = Object.DocumentAmountTD;
	AITDocumentAmountBeforeAdjustment  = Object.DocumentAmountAIT;
	
	Object.DocumentAmount     = Object.DocumentAmount + ?(Parameters.Property("Sum"), Parameters.Sum, 0);
	Object.TheAmountOfTheDocumentRegl = Object.TheAmountOfTheDocumentRegl + ?(Parameters.Property("SumCompl"), Parameters.SumCompl, 0);
	Object.DocumentAmountPD   = Object.DocumentAmountPD + ?(Parameters.Property("PermanentDifference"), Parameters.PermanentDifference, 0);
	Object.DocumentAmountTD   = Object.DocumentAmountTD + ?(Parameters.Property("CostTD"), Parameters.CostTD, 0);
	Object.DocumentAmountAIT  = Object.DocumentAmountAIT + ?(Parameters.Property("AITAmount"), Parameters.AITAmount, 0);
	
	If DocumentAmountBeforeAdjustment <> Object.DocumentAmount
		   Or AmountOfLocalDocumentBeforeAdjustment <> Object.TheAmountOfTheDocumentRegl
		   Or DocumentAmountPDBeforeAdjustment <> Object.DocumentAmountPD
		   Or AmountOfTDDocumentBeforeAdjustment <> Object.DocumentAmountTD
		   Or AITDocumentAmountBeforeAdjustment <> Object.DocumentAmountAIT
		   Then
		Modified = True;
	EndIf;
	If Not ValueIsFilled(Object.Ref) Then
		TheAmountOfTheDocumentIsWELL = Object.TheAmountOfTheDocumentRegl - Object.DocumentAmountPD - Object.DocumentAmountTD;
		ItemOfExpensesForChangesOnServer(True);
		FillInDetailsPermanentAndTemporaryDifferencesAreRecorded();
	EndIf;
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ItemsAndDimensionsSelectionParameters = Documents.DeferredExpensesAllocation.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(ThisForm);
	
	RecordsAreKeptAccordingToAIT = RecordsAreKeptAccordingToAIT(Object.Date, Object.Organization);
	Object.AIT = ?(RecordsAreKeptAccordingToAIT, Object.AIT, False);
	Items.AIT.Visible = RecordsAreKeptAccordingToAIT;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	ItemOfExpensesForChangesOnServer(True);
	ThereIsBanOnChanges = False;
	ThereIsBanOnChangingDateOfDocument = False;
	FillInDetailsInTablePart_(ThereIsBanOnChanges);
	If Not ThereIsBanOnChanges Then
		DataBanTemplate = PeriodClosingDates.DataToCheckTemplate();
		TemplateRow = DataBanTemplate.Add();
		TemplateRow.Section = "RoutineOperations";
		TemplateRow.Date = BegOfMonth(Object.Date);
		ThereIsBanOnChangingDateOfDocument = PeriodClosingDates.PeriodEndClosingFound(DataBanTemplate);
	EndIf;
	If ThereIsBanOnChangingDateOfDocument Or ThereIsBanOnChanges Then
		If Object.AmountEntryOptionMan = Enums.OptionsOfDEAmountSpecification.DeterminedAutomatically
		 And Object.ManagementAccounting
		 Or Object.AmountEntryOptionLocal = Enums.OptionsOfDEAmountSpecification.DeterminedAutomatically
		 And (Object.LocalAccounting Or Object.TaxAccounting Or Object.AIT) Then
			Items.Number.ReadOnly = True;
			Items.Date.ReadOnly = True;
		EndIf;
		Items.AmountEntryOptionMan.ReadOnly = True;
		Items.AmountEntryOptionLocal.ReadOnly = True;
	EndIf;
	If ThereIsBanOnChanges
	 Or (ThereIsBanOnChangingDateOfDocument
		And (Object.AmountEntryOptionMan = Enums.OptionsOfDEAmountSpecification.DeterminedAutomatically
			And Object.ManagementAccounting
		  Or Object.AmountEntryOptionLocal = Enums.OptionsOfDEAmountSpecification.DeterminedAutomatically)
		  And (Object.LocalAccounting Or Object.TaxAccounting Or Object.AIT)) Then
		Items.Organization.ReadOnly = True;
		Items.Department.ReadOnly = True;
		Items.LineOfBusiness.ReadOnly = True;
		Items.ExpenseItem.ReadOnly = True;
		Items.DimensionOfExpenses.ReadOnly = True;
		Items.AllocatedAccordingToRule.ReadOnly = True;
		Items.NumberOfMonths.ReadOnly = True;
		Items.BeginOfPeriod.ReadOnly = True;
		Items.EndOfPeriod.ReadOnly = True;
		Items.EmployeeResponsible.ReadOnly = True;
		
		Items.ManagementAccounting.ReadOnly = True;
		Items.LocalAccounting.ReadOnly = True;
		Items.LocalizationTaxAccounting.ReadOnly = True;
		Items.AIT.ReadOnly = True;
		Items.CostSharingMode.ReadOnly = True;
		
		Items.CostAllocationFillInTheDistribution.Enabled = False;
		Items.CostAllocationFillInExpenseItems.Enabled = False;
		Items.CostAllocationFillInTheDepartment.Enabled = False;
		
		If Object.AmountEntryOptionMan = Enums.OptionsOfDEAmountSpecification.DeterminedAutomatically
		 And Object.ManagementAccounting
		 Or Object.AmountEntryOptionLocal = Enums.OptionsOfDEAmountSpecification.DeterminedAutomatically
		 And (Object.LocalAccounting Or Object.TaxAccounting Or Object.AIT) Then
		 	Items.CostAllocation.ReadOnly = True;
		EndIf;
	EndIf;
	TheAmountOfTheDocumentIsWELL = Object.TheAmountOfTheDocumentRegl - Object.DocumentAmountPD - Object.DocumentAmountTD;
	AllocatedAccordingToRule = Object.AllocatedAccordingToRule;
	NumberOfMonths = Object.NumberOfMonths;
	BeginOfPeriod = Object.BeginOfPeriod;
	EndOfPeriod = Object.EndOfPeriod;
	
	FillInDetailsPermanentAndTemporaryDifferencesAreRecorded();

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	ItemsAndDimensionsSelectionParameters = Documents.DeferredExpensesAllocation.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(ThisForm);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	ThereIsBanOnChanges = False;
	FillInDetailsInTablePart_(ThereIsBanOnChanges);
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisForm);

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_DeferredExpensesAllocation", WriteParameters, Object.Ref);
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	ResponseBeforeWrite = False;
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	If CurrentObject.CostAllocationFromCostCenter Then
		CurrentObject.DimensionOfExpenses = ConstCenter;
	EndIf;
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure



&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Object.Ref.IsEmpty() Then
		FillInEndOfPeriod();
	EndIf;
	
	ManagingFormElementsOnClient();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	FillInDetailsPermanentAndTemporaryDifferencesAreRecorded();
	ManagingFormElementsOnClient();
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	SetFormElementHeaders();
	FillInDetailsPermanentAndTemporaryDifferencesAreRecorded();
	ManagingFormElementsOnClient();
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	ItemOfExpensesForChangesOnServer();
	ManagingFormElementsOnClient();
	RecalculateAmountOfAITOfDocument();
EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtServer
Procedure ItemOfExpensesForChangesOnServer(Initialize = False)
	
	AttributesNames = "CostAllocationOptionManag, CostAllocationOptionLocal, CostAllocationOptionTax";
	Attributes = Common.ObjectAttributesValues(Object.ExpenseItem, AttributesNames);
	
	If ValueIsFilled(Attributes.CostAllocationOptionManag) Then
		CostAllocationOptionManag = Attributes.CostAllocationOptionManag;
	Else
		CostAllocationOptionManag = Enums.CostAllocationOptions.ToDeferredExpenses;
	EndIf;
	
	If ValueIsFilled(Attributes.CostAllocationOptionLocal) Then
		CostAllocationOptionLocal = Attributes.CostAllocationOptionLocal;
	Else
		CostAllocationOptionLocal = Enums.CostAllocationOptions.ToDeferredExpenses;
	EndIf;
		
	If ValueIsFilled(Attributes.CostAllocationOptionTax) Then
		CostAllocationOptionTax = Attributes.CostAllocationOptionTax;
	Else
		CostAllocationOptionTax = Enums.CostAllocationOptions.ToDeferredExpenses;
	EndIf;
	
	If Not Initialize And Object.ManagementAccounting 
		And Not CostAllocationOptionManag = Enums.CostAllocationOptions.ToDeferredExpenses Then
		Object.ManagementAccounting = False;
		Modified = True;
	EndIf;
		
	If Not Initialize And Object.LocalAccounting And Not CostAllocationOptionLocal = Enums.CostAllocationOptions.ToDeferredExpenses Then
		Object.LocalAccounting = False;
		Modified = True;
	EndIf;
		
	If Not Initialize And Object.TaxAccounting And Not CostAllocationOptionTax = Enums.CostAllocationOptions.ToDeferredExpenses Then
		Object.TaxAccounting = False;
		Modified = True;
	EndIf;
		
EndProcedure

&AtClient
Procedure DimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	If TypeOf(ValueSelected) = Type("Structure") Then
		Object.DimensionOfExpenses = ValueSelected.DimensionOfExpenses;
		StandardProcessing = False;
		Modified = True;
	EndIf;

EndProcedure

&AtClient
Procedure DimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
EndProcedure

&AtClient
Procedure AmountEntryOptionManOnChange(Item)
	ManagingFormElementsOnClient();
EndProcedure

&AtClient
Procedure AmountEntryOptionLocalOnChange(Item)
	ManagingFormElementsOnClient();
EndProcedure

&AtClient
Procedure AllocatedAccordingToRuleOnChange(Item)
	ReFillTablePart();
EndProcedure

&AtClient
Procedure NumberOfMonthsOnChange(Item)
	FillInEndOfPeriod();
	ReFillTablePart();
EndProcedure

&AtClient
Procedure BeginOfPeriodOnChange(Item)
	Var WarningText;
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	If CheckDataModificationBan(Object.BeginOfPeriod, WarningText) Then
		Object.BeginOfPeriod = Date(1,1,1);
		ShowMessageBox(, WarningText);
	Else
		FillInEndOfPeriod();
		ReFillTablePart();
	EndIf;
EndProcedure

&AtClient
Procedure EndOfPeriodOnChange(Item)
	Var WarningText;
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	If CheckDataModificationBan(Object.EndOfPeriod, WarningText) Then
		Object.EndOfPeriod = Date(1,1,1);
		ShowMessageBox(, WarningText);
	Else
		ReFillTablePart();
	EndIf;
EndProcedure

&AtClient
Procedure TheAmountOfTheDocumentReglOnChange(Item)
	TheAmountOfTheDocumentIsWELL = Object.TheAmountOfTheDocumentRegl - Object.DocumentAmountPD;
	TheAmountOfTheDocumentIsWELLOnChange(Item);
EndProcedure

&AtClient
Procedure TheAmountOfTheDocumentIsWELLOnChange(Item)
	Object.DocumentAmountTD  = Object.TheAmountOfTheDocumentRegl - TheAmountOfTheDocumentIsWELL - Object.DocumentAmountPD;
	RecalculateAmountOfAITOfDocument();
EndProcedure

&AtClient
Procedure DocumentAmountPDOnChange(Item)
	TheAmountOfTheDocumentReglOnChange(Item);
	RecalculateTimeDifferenceOfDocument();
EndProcedure

&AtClient
Procedure CostSharingModeOnChange(Item)
	CostAllocationModeForChangesOnServer();
	ManagingFormElementsOnClient();
EndProcedure

&AtClient
Procedure ConstCenterOnChange(Item)
	Modified = True;
	Object.DimensionOfExpenses = ConstCenter;
EndProcedure

&AtServer
Procedure CostAllocationModeForChangesOnServer()
	Object.CostAllocationFromCostCenter = CostSharingMode = "FromHIA";
	If Object.CostAllocationFromCostCenter And Object.ExpenseItem <> ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef() Then
		Object.ExpenseItem = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
	EndIf;
	ConstCenter = Catalogs.CostCenters.EmptyRef();
	Object.DimensionOfExpenses = Undefined;
EndProcedure

&AtClient
Procedure ManagementAccountingOnChange(Item)
	ManagingFormElementsOnClient();
EndProcedure

&AtClient
Procedure LocalAccountingOnChange(Item)
	ManagingFormElementsOnClient();
	RecalculateTimeDifferenceOfDocument();
EndProcedure

&AtClient
Procedure TaxAccountingOnChange(Item)
	ManagingFormElementsOnClient();
	If Not Object.TaxAccounting Then
		TheAmountOfTheDocumentIsWELL = 0;
	EndIf;
	RecalculateTimeDifferenceOfDocument();
EndProcedure

&AtClient
Procedure AITOnChange(Item)
	ManagingFormElementsOnClient();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCostAllocation

&AtClient
Procedure CostAllocationOnStartEdit(Item, NewRow, Copy)
	
	If NewRow And Not Copy Then
		
		SumBalance     = Object.DocumentAmount - Object.CostAllocation.Total("Sum");
		AmountManBalance  = Object.DocumentAmountManag - Object.CostAllocation.Total("SumMan");
		AmountLocalBalance = Object.TheAmountOfTheDocumentRegl - Object.CostAllocation.Total("SumCompl");
		AmountBalanceTa   = TheAmountOfTheDocumentIsWELL - Object.CostAllocation.Total("AmountFA");
		AmountBalancePD   = Object.DocumentAmountPD - Object.CostAllocation.Total("PermanentDifference");
		AmountBalanceOfTD   = Object.DocumentAmountTD - Object.CostAllocation.Total("CostTD");
		AmountOfAITSBalance  = Object.DocumentAmountAIT - Object.CostAllocation.Total("AITAmount");
		
		Item.CurrentData.Sum             = SumBalance;
		Item.CurrentData.SumMan          = AmountManBalance;
		Item.CurrentData.SumCompl         = AmountLocalBalance;
		Item.CurrentData.AmountFA           = AmountBalanceTa;
		Item.CurrentData.PermanentDifference = AmountBalancePD;
		Item.CurrentData.CostTD  = AmountBalanceOfTD;
		Item.CurrentData.AITAmount          = AmountOfAITSBalance;
		
		RowsCount = Object.CostAllocation.Count();
		If RowsCount > 1 Then
			Date = AddMonth(BegOfMonth(Object.CostAllocation[RowsCount - 2].Date), 1);
			Item.CurrentData.Date = Date;
		Else
			Item.CurrentData.Date = Object.BeginOfPeriod;
		EndIf;
		
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, Item.CurrentData, "Object.CostAllocation");
	
	EndIf;
	
EndProcedure

&AtClient
Procedure CostAllocationExpenseItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure CostAllocationExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure CostAllocationDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure CostAllocationDimensionOfExpensesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	TableRow = Items.CostAllocation.CurrentData;
	If TypeOf(ValueSelected) = Type("Structure") Then
		FillPropertyValues(TableRow, ValueSelected);
		StandardProcessing = False;
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure CostAllocationDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
EndProcedure

&AtClient
Procedure CostAllocationDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
EndProcedure

&AtClient
Procedure CostAllocationDateOnChange(Item)
	Var WarningText;
	TableRow = Items.CostAllocation.CurrentData;
	If CheckDataModificationBan(TableRow.Date, WarningText) Then
		TableRow.Date = Date(1,1,1);
		ShowMessageBox(, WarningText);
	EndIf;
EndProcedure

&AtClient
Procedure CostAllocationSumComplOnChange(Item)
	TableRow = Items.CostAllocation.CurrentData;
	RecalculateTimeDifferenceOfString(TableRow);
EndProcedure

&AtClient
Procedure CostAllocationAmountFAOnChange(Item)
	TableRow = Items.CostAllocation.CurrentData;
	RecalculateTimeDifferenceOfString(TableRow);
EndProcedure

&AtClient
Procedure CostAllocationPermanentDifferenceOnChange(Item)
	TableRow = Items.CostAllocation.CurrentData;
	RecalculateTimeDifferenceOfString(TableRow);
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


&AtClient
Procedure FillInTheDistribution(Command)

	Var WarningText;
	If Object.CostAllocationFromCostCenter Then
		If Not ValueIsFilled(Object.DimensionOfExpenses) Then
			WarningText = NStr("vi = 'Chưa chỉ ra đối tượng phát sinh chi phí';
								|ru = 'Не указан объект возникновения затрат';
								|en = 'No cost center specified'; fa = 'No cost center specified';
								|it = 'Oggetto di spesa non indicato';
								|pl = 'Nie podano obiektu tworzenia się rozchodów';
								|tr = 'Gider oluşum nesnesi belirtilmedi'");
		EndIf;
	Else
	If Not ValueIsFilled(Object.ExpenseItem) Then
		WarningText = NStr("vi = 'Chưa chỉ ra dạng chi phí';
							|ru = 'Не указана статья затрат';
							|en = 'No expense item specified'; fa = 'No expense item specified';
							|it = 'Voce di spesa non indicata';
							|pl = 'Nie podano pozycji rozchodów';
							|tr = 'Gider kalemi belirtilmedi'");
	EndIf;
	EndIf;
	If ValueIsFilled(WarningText) Then
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	If CheckDataModificationBan(Object.BeginOfPeriod, WarningText) Then
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection = Object.CostAllocation;
	CheckParameters.CheckedAttributes.Insert("AllocatedAccordingToRule", NStr("vi = 'Phân bổ';
																				|ru = 'Распределить';
																				|en = 'Allocate'; fa = 'تسهیم';
																				|it = 'Ripartire';
																				|pl = 'Allocate';
																				|tr = 'Dağıt'"));
	CheckParameters.CheckedAttributes.Insert("BeginOfPeriod",        NStr("vi = 'Bắt đầu từ';
																			|ru = 'Начиная с';
																			|en = 'Starting from'; fa = 'با شروع از';
																			|it = 'A decorrere da';
																			|pl = 'Zaczynając od';
																			|tr = 'Başlayarak'"));
	CheckParameters.CheckedAttributes.Insert("EndOfPeriod",         NStr("vi = 'Đến';
																		|ru = 'По';
																		|en = 'To'; fa = 'به';
																		|it = 'Al';
																		|pl = 'To';
																		|tr = 'Göre'"));
	Notification = New CallbackDescription("FillInTheDistributionCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure FillInTheDistributionCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes
	 Or Result = True Then
		AllocateExpenses();
		AllocatedAccordingToRule = Object.AllocatedAccordingToRule;
		NumberOfMonths = Object.NumberOfMonths;
		BeginOfPeriod = Object.BeginOfPeriod;
		EndOfPeriod = Object.EndOfPeriod;
	Else
		If Object.AllocatedAccordingToRule <> AllocatedAccordingToRule
		 And ValueIsFilled(AllocatedAccordingToRule) Then
			Object.AllocatedAccordingToRule = AllocatedAccordingToRule;
		EndIf;
		If Object.NumberOfMonths <> NumberOfMonths
		 And ValueIsFilled(NumberOfMonths) Then
			Object.NumberOfMonths = NumberOfMonths;
		EndIf;
		If Object.BeginOfPeriod <> BeginOfPeriod
		 And ValueIsFilled(BeginOfPeriod) Then
			Object.BeginOfPeriod = BeginOfPeriod;
		EndIf;
		If Object.EndOfPeriod <> EndOfPeriod
		 And ValueIsFilled(EndOfPeriod) Then
			Object.EndOfPeriod = EndOfPeriod;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInExpenseItems(Command)
	
	IncomeAndExpensesClient.FillInArticleAndAnalyticsInSelectedLines(
		ThisObject, Items.CostAllocationExpenseItem, Items.CostAllocation.SelectedRows);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure FillInTheDepartment(Command)
	
	FillInDivisionInTablePart(Items.CostAllocation.SelectedRows);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm, True);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

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

#EndRegion

#Region Private

&AtClient
Procedure FillInEndOfPeriod()
	If Object.NumberOfMonths > 0 And ValueIsFilled(Object.BeginOfPeriod) Then
		Object.EndOfPeriod = AddMonth(Object.BeginOfPeriod, Object.NumberOfMonths)-1;
	EndIf;
EndProcedure

&AtClient
Procedure ReFillTablePart()
	If Object.CostAllocation.Count() > 0 Then
		QueryText = NStr("vi = 'Phần bảng chứng từ sẽ bị xóa và điền lại. Tiếp tục?';
						|ru = 'Табличная часть документа будет очищена и перезаполнена. Продолжить?';
						|en = 'The table will be cleared and refilled. Do you want to continue?'; fa = 'The table will be cleared and refilled. Do you want to continue?';
						|it = 'La tabella del documento verrà cancellata e ricompilata. Continuare?';
						|pl = 'Część tabelaryczna dokumentu zostanie wyczyszczona i ponownie wypełniona. Kontynuować?';
						|tr = 'Belgenin tablo kısmı temizlenecek ve yeniden doldurulacaktır. Devam edilsin mi?'");
		HandlerNotifications = New CallbackDescription("FillInTheDistributionCompletion", ThisForm);
		ShowQueryBox(HandlerNotifications, QueryText, QuestionDialogMode.YesNo);
	Else
		AllocatedAccordingToRule = Object.AllocatedAccordingToRule;
		NumberOfMonths = Object.NumberOfMonths;
		BeginOfPeriod = Object.BeginOfPeriod;
		EndOfPeriod = Object.EndOfPeriod;
	EndIf;
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostAllocationDate.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostAllocationDepartment.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostAllocationExpenseItem.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostAllocationDimensionOfExpenses.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostAllocationCostShare.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostAllocationSum.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostAllocationSumMan.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostAllocationSumCompl.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostAllocationAmountFA.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostAllocationAITAmount.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostAllocationPermanentDifference.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostAllocationCostTD.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CostAllocation.DataChangesDenied");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	
EndProcedure

&AtServer
Function DateDifferenceInDays(Val Date1, Val Date2)
	
	DayLength = 86400; // In seconds
	Return Round((BegOfDay(Date1) - BegOfDay(Date2)) / DayLength);
	
EndFunction

&AtServer
Procedure AllocateExpenses()
	
	Object.CostAllocation.Clear();
	
	DistributionOfNegativeSum     = Object.DocumentAmount < 0;
	DistributionOfNegativeAmountOfMan  = Object.DocumentAmountManag < 0;
	DistributionOfNegativeLocalSum = Object.TheAmountOfTheDocumentRegl < 0;
	DistributionOfNegativeAmountOfPD   = Object.DocumentAmountPD < 0;
	DistributionOfNegativeAmountOfTD   = Object.DocumentAmountTD < 0;
	DistributionOfNegativeAmountOfAIT  = Object.DocumentAmountAIT < 0;
	
	AmountForAllocation     = Object.DocumentAmount;
	AmountOfManDistribution  = Object.DocumentAmountManag;
	SumToLocalDistribution = Object.TheAmountOfTheDocumentRegl;
	AmountToBeDistributedPD   = Object.DocumentAmountPD;
	AmountToBeDistributedByTD   = Object.DocumentAmountTD;
	
	ItemIsRecognizedInAITExpenses = Not ItemOfExpensesIsRecognizedInAITExpenses(Object.ExpenseItem);
	RecordsAreKeptAccordingToAIT = RecordsAreKeptAccordingToAIT(Object.Date, Object.Organization);
	AITAmountToBeDistributed  = ?(Not ItemIsRecognizedInAITExpenses Or Not RecordsAreKeptAccordingToAIT, 0, Object.DocumentAmountAIT);
	
	If Object.BeginOfPeriod = BegOfMonth(Object.BeginOfPeriod) Then
		If Object.AllocatedAccordingToRule = Enums.RulesOfDeferredExpenseAllocation.ByMonths
		 And Object.NumberOfMonths <> 0 Then
			TotalMonths = Object.NumberOfMonths - 1;
		Else
			CurrentMonth = BegOfMonth(Object.BeginOfPeriod);
			TotalMonths = 0;
			While EndOfMonth(CurrentMonth) < EndOfMonth(Object.EndOfPeriod) Do
				CurrentMonth = AddMonth(CurrentMonth, 1);
				TotalMonths = TotalMonths + 1;
			EndDo;
		EndIf;
	Else
		If Object.AllocatedAccordingToRule = Enums.RulesOfDeferredExpenseAllocation.ByMonths
		 And Object.NumberOfMonths <> 0 Then
			TotalMonths = Object.NumberOfMonths;
		Else
			CurrentMonth = BegOfMonth(Object.BeginOfPeriod);
			TotalMonths = 0;
			While EndOfMonth(CurrentMonth) < EndOfMonth(Object.EndOfPeriod) Do
				CurrentMonth = AddMonth(CurrentMonth, 1);
				TotalMonths = TotalMonths + 1;
			EndDo;
		EndIf;
	EndIf;
	
	StartDateOfDebiting = BegOfDay(Object.BeginOfPeriod);
	WriteOffEndDate = EndOfDay(Object.EndOfPeriod);
	
	CorrectionForLeapYearAtBeginningOfPeriod = 0;
	CorrectionForLeapYearAtEndOfPeriod  = 0;
	If Day(EndOfMonth(StartDateOfDebiting)) = 29 And Day(StartDateOfDebiting) <> 1 Then
		CorrectionForLeapYearAtBeginningOfPeriod = -1;
	EndIf;
	If Day(EndOfMonth(WriteOffEndDate)) = 29 And Day(WriteOffEndDate) <> 29 Then
		CorrectionForLeapYearAtEndOfPeriod = -1;
	EndIf;
	
	ItemOfExpenditureDistribution = Undefined;
	CostAnalyticsDistribution = Undefined;
	
	DetailsToReceive = New Structure(
		"CostAllocationOptionLocal, CostAllocationOptionManag, CostAllocationOptionTax, 
		|RuleOfDistributionOfExpensesLocalItemWriteOffRBP, RuleForDistributionOfExpensesOfManItemWriteOffRBP, RuleOfDistributionOfExpensesTaItemWriteOffRBP,
		|RuleOfDistributionOfExpensesLocalAnalyticsOfExpensesRBP, RuleOfDistributionOfExpensesManAnalysisOfExpensesRBP, CostAllocationRuleTaRBPCostAnalytics,
		|LocalDivisionCostSharingRule, ManDivisionCostSharingRule, TaDivisionCostSharingRule",
		
		"CostAllocationOptionLocal", "CostAllocationOptionManag", "CostAllocationOptionTax", 
		"CostAllocationRuleLocal.DeferredExpensesWriteOffItem", "CostAllocationRuleManag.DeferredExpensesWriteOffItem", "CostAllocationRuleTax.DeferredExpensesWriteOffItem",
		"CostAllocationRuleLocal.DeferredExpensesDimension", "CostAllocationRuleManag.DeferredExpensesDimension", "CostAllocationRuleTax.DeferredExpensesDimension",
		"CostAllocationRuleLocal.Department", "CostAllocationRuleManag.Department", "CostAllocationRuleTax.Department"
		);

	ValuesOfDetailsOfExpenditureItem = Common.ObjectAttributesValues(
		?(ValueIsFilled(Object.ExpenseItem), Object.ExpenseItem, Object.DimensionOfExpenses),
		DetailsToReceive);
	
	If ValuesOfDetailsOfExpenditureItem.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToDeferredExpenses Then
		
		ItemOfExpenditureDistribution = ValuesOfDetailsOfExpenditureItem.RuleOfDistributionOfExpensesLocalItemWriteOffRBP;
		CostAnalyticsDistribution = ValuesOfDetailsOfExpenditureItem.RuleOfDistributionOfExpensesLocalAnalyticsOfExpensesRBP;
		SubdivisionDistribution = ValuesOfDetailsOfExpenditureItem.LocalDivisionCostSharingRule;
		
	ElsIf ValuesOfDetailsOfExpenditureItem.CostAllocationOptionManag = Enums.CostAllocationOptions.ToDeferredExpenses Then
		
		ItemOfExpenditureDistribution = ValuesOfDetailsOfExpenditureItem.RuleForDistributionOfExpensesOfManItemWriteOffRBP;
		CostAnalyticsDistribution = ValuesOfDetailsOfExpenditureItem.RuleOfDistributionOfExpensesManAnalysisOfExpensesRBP;
		SubdivisionDistribution = ValuesOfDetailsOfExpenditureItem.ManDivisionCostSharingRule;
		
	ElsIf ValuesOfDetailsOfExpenditureItem.CostAllocationOptionTax = Enums.CostAllocationOptions.ToDeferredExpenses Then
		
		ItemOfExpenditureDistribution = ValuesOfDetailsOfExpenditureItem.RuleOfDistributionOfExpensesTaItemWriteOffRBP;
		CostAnalyticsDistribution = ValuesOfDetailsOfExpenditureItem.CostAllocationRuleTaRBPCostAnalytics;
		SubdivisionDistribution = ValuesOfDetailsOfExpenditureItem.TaDivisionCostSharingRule;
		
	EndIf;
	
	ShareOfLastMonth = Day(WriteOffEndDate) / (Day(EndOfMonth(WriteOffEndDate)) + CorrectionForLeapYearAtEndOfPeriod);
	
	For Counter = 0 To TotalMonths Do
		
		If Counter <> 0 Then
			StartDateOfDebiting = BegOfMonth(AddMonth(StartDateOfDebiting, 1));
		EndIf;
		
		If Object.AllocatedAccordingToRule = Enums.RulesOfDeferredExpenseAllocation.ByCalendarDays Then
			DaysCount = DateDifferenceInDays(WriteOffEndDate, StartDateOfDebiting) + 1;
			PriceOfDay     = AmountForAllocation / DaysCount;
			PriceOfDayMan  = AmountOfManDistribution / DaysCount;
			LocalDayPrice = SumToLocalDistribution / DaysCount;
			PriceOfDayPD   = AmountToBeDistributedPD / DaysCount;
			PriceOfDayTD   = AmountToBeDistributedByTD / DaysCount;
			AITPriceOfDay  = AITAmountToBeDistributed / DaysCount;
			
			If EndOfMonth(WriteOffEndDate) = EndOfMonth(StartDateOfDebiting) Then 
				NumberOfDaysOfCurMonth = Day(WriteOffEndDate);
				DaysCount = NumberOfDaysOfCurMonth;
				DebitedAmount     = AmountForAllocation;
				AmountOfManDebiting  = AmountOfManDistribution;
				AmountOfLocalTaxDebited = SumToLocalDistribution;
				AmountPermanentDifference   = AmountToBeDistributedPD;
				AmountTemporaryDifference   = AmountToBeDistributedByTD;
				AITWriteOffAmount  = AITAmountToBeDistributed;
			Else
				NumberOfDaysOfCurMonth = DateDifferenceInDays(EndOfMonth(StartDateOfDebiting), StartDateOfDebiting) + 1;
				DebitedAmount     = PriceOfDay * NumberOfDaysOfCurMonth;
				AmountOfManDebiting  = PriceOfDayMan * NumberOfDaysOfCurMonth;
				AmountOfLocalTaxDebited = LocalDayPrice * NumberOfDaysOfCurMonth;
				AmountPermanentDifference   = PriceOfDayPD * NumberOfDaysOfCurMonth;
				AmountTemporaryDifference   = PriceOfDayTD * NumberOfDaysOfCurMonth;
				AITWriteOffAmount  = AITPriceOfDay * NumberOfDaysOfCurMonth;
			EndIf;
			CurMonthShare = NumberOfDaysOfCurMonth;
			
		Else
			If EndOfMonth(StartDateOfDebiting) = EndOfMonth(WriteOffEndDate) Then
				CurMonthShare = ShareOfLastMonth;
				NumberOfMonthsOfCalculation  = ShareOfLastMonth;
			Else
				CurMonthShare = (DateDifferenceInDays(EndOfMonth(StartDateOfDebiting), StartDateOfDebiting) + 1 + CorrectionForLeapYearAtBeginningOfPeriod)
					/ (Day(EndOfMonth(StartDateOfDebiting)) + CorrectionForLeapYearAtBeginningOfPeriod);
				NumberOfMonths_ = 0;
				CurrentDate = AddMonth(EndOfMonth(StartDateOfDebiting), 1);
				While EndOfMonth(WriteOffEndDate) >= CurrentDate Do
					NumberOfMonths_ = NumberOfMonths_ + 1;
					CurrentDate = AddMonth(CurrentDate, 1);
				EndDo;
				NumberOfMonthsOfCalculation = NumberOfMonths_ - 1 + ShareOfLastMonth + CurMonthShare;
			EndIf;
			DebitedAmount     = ?(NumberOfMonthsOfCalculation = 0, 0, Round(AmountForAllocation * CurMonthShare / NumberOfMonthsOfCalculation, 2, 1));
			AmountOfManDebiting  = ?(NumberOfMonthsOfCalculation = 0, 0, Round(AmountOfManDistribution * CurMonthShare / NumberOfMonthsOfCalculation, 2, 1));
			AmountOfLocalTaxDebited = ?(NumberOfMonthsOfCalculation = 0, 0, Round(SumToLocalDistribution * CurMonthShare / NumberOfMonthsOfCalculation, 2, 1));
			AmountPermanentDifference   = ?(NumberOfMonthsOfCalculation = 0, 0, Round(AmountToBeDistributedPD * CurMonthShare / NumberOfMonthsOfCalculation, 2, 1));
			AmountTemporaryDifference   = ?(NumberOfMonthsOfCalculation = 0, 0, Round(AmountToBeDistributedByTD * CurMonthShare / NumberOfMonthsOfCalculation, 2, 1));
			AITWriteOffAmount  = ?(NumberOfMonthsOfCalculation = 0, 0, Round(AITAmountToBeDistributed * CurMonthShare / NumberOfMonthsOfCalculation, 2, 1));
		EndIf;
		
		NewRow = Object.CostAllocation.Add();
		NewRow.Date = StartDateOfDebiting;
		NewRow.CostShare = CurMonthShare;
		
		If Not DistributionOfNegativeSum Then
			NewRow.Sum = Min(DebitedAmount, AmountForAllocation);
		Else
			NewRow.Sum = Max(DebitedAmount, AmountForAllocation);
		EndIf;
		If Not DistributionOfNegativeAmountOfMan Then
			NewRow.SumMan = Min(AmountOfManDebiting, AmountOfManDistribution);
		Else
			NewRow.SumMan = Max(AmountOfManDebiting, AmountOfManDistribution);
		EndIf;
		If Not DistributionOfNegativeLocalSum Then
			NewRow.SumCompl = Min(AmountOfLocalTaxDebited, SumToLocalDistribution);
		Else
			NewRow.SumCompl = Max(AmountOfLocalTaxDebited, SumToLocalDistribution);
		EndIf;
		If Not DistributionOfNegativeAmountOfPD Then
			NewRow.PermanentDifference = Min(AmountPermanentDifference, AmountToBeDistributedPD);
		Else
			NewRow.PermanentDifference = Max(AmountPermanentDifference, AmountToBeDistributedPD);
		EndIf;
		If Not DistributionOfNegativeAmountOfTD Then
			NewRow.CostTD = Min(AmountTemporaryDifference, AmountToBeDistributedByTD);
		Else
			NewRow.CostTD = Max(AmountTemporaryDifference, AmountToBeDistributedByTD);
		EndIf;
		If Not DistributionOfNegativeAmountOfAIT Then
			NewRow.AITAmount = Min(AITWriteOffAmount, AITAmountToBeDistributed);
		Else
			NewRow.AITAmount = Max(AITWriteOffAmount, AITAmountToBeDistributed);
		EndIf;
		
		NewRow.AmountFA = NewRow.SumCompl - NewRow.PermanentDifference - NewRow.CostTD;
		
		If Not ValueIsFilled(SubdivisionDistribution) Then
			NewRow.Department = Object.Department;
		Else
			NewRow.Department = SubdivisionDistribution;
		EndIf;
		
		If ValueIsFilled(ItemOfExpenditureDistribution) Then
			NewRow.ExpenseItem = ItemOfExpenditureDistribution;
			If ValueIsFilled(Object.ExpenseItem) And Not ValueIsFilled(CostAnalyticsDistribution)
				And TypeOf(Object.ExpenseItem) = TypeOf(CostAnalyticsDistribution) Then
					NewRow.DimensionOfExpenses = Object.DimensionOfExpenses;
			Else
				NewRow.DimensionOfExpenses = CostAnalyticsDistribution;
			EndIf;
		EndIf;
		
		AmountForAllocation     = AmountForAllocation - NewRow.Sum;
		AmountOfManDistribution  = AmountOfManDistribution - NewRow.SumMan;
		SumToLocalDistribution = SumToLocalDistribution - NewRow.SumCompl;
		AmountToBeDistributedPD   = AmountToBeDistributedPD - NewRow.PermanentDifference;
		AmountToBeDistributedByTD   = AmountToBeDistributedByTD - NewRow.CostTD;
		AITAmountToBeDistributed  = AITAmountToBeDistributed - NewRow.AITAmount;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ManagingFormElementsOnClient()
	
	DistributeMan = Object.ManagementAccounting And (CostAllocationOptionManag
		= PredefinedValue("Enum.CostAllocationOptions.ToDeferredExpenses"));
		
	SpecifyManAmountManually =
		(Object.AmountEntryOptionMan = PredefinedValue("Enum.OptionsOfDEAmountSpecification.SpecifiedManually"));
	Items.DocumentAmount.Visible = SpecifyManAmountManually And DistributeMan;
	Items.DocumentAmountManag.Visible = SpecifyManAmountManually And DistributeMan;
	Items.LabelDistributionOfTheAmountOfUpr.Visible = Not SpecifyManAmountManually And DistributeMan;
		
	Items.CostAllocationUprGroup.Visible = SpecifyManAmountManually And DistributeMan And Not Object.CostAllocationFromCostCenter;
		
	DistributeLocal = Object.LocalAccounting And CostAllocationOptionLocal
		= PredefinedValue("Enum.CostAllocationOptions.ToDeferredExpenses");
	
	DistributeTa = Object.TaxAccounting And CostAllocationOptionTax
		= PredefinedValue("Enum.CostAllocationOptions.ToDeferredExpenses");
	
	DistributePersonalIncomeTax = Object.AIT;
	RecordsAreKeptAccordingToAIT = RecordsAreKeptAccordingToAIT(Object.Date, Object.Organization);
	ItemIsRecognizedInAITExpenses = ItemOfExpensesIsRecognizedInAITExpenses(Object.ExpenseItem);
	Items.AIT.Visible = RecordsAreKeptAccordingToAIT;
	
	SpecifyLocalAmountManually =
		(Object.AmountEntryOptionLocal = PredefinedValue("Enum.OptionsOfDEAmountSpecification.SpecifiedManually"));
	Items.TheAmountOfTheDocumentRegl.Visible = SpecifyLocalAmountManually And DistributeLocal;
	Items.TheAmountOfTheDocumentIsWELL.Visible   = SpecifyLocalAmountManually And DistributeTa;
	Items.DocumentAmountPD.Visible   = SpecifyLocalAmountManually And DistributeTa
		And CalculationOfPermanentAndTemporaryDifferencesIsKept;
	Items.DocumentAmountTD.Visible   = SpecifyLocalAmountManually And DistributeTa
		And CalculationOfPermanentAndTemporaryDifferencesIsKept;
	
	Items.DocumentAmountAIT.Visible   = SpecifyLocalAmountManually And DistributePersonalIncomeTax And RecordsAreKeptAccordingToAIT;
	Items.DocumentAmountAIT.Enabled = ItemIsRecognizedInAITExpenses And RecordsAreKeptAccordingToAIT;
	
	Items.LabelDistributionOfTheAmountRegl.Visible = Not SpecifyLocalAmountManually And (DistributeLocal Or DistributeTa);
	
	Items.ExpensesAllocationGroupRegul.Visible = SpecifyLocalAmountManually And (DistributeLocal Or DistributeTa)
		And Not Object.CostAllocationFromCostCenter;

	Items.CostAllocationSumCompl.Visible = SpecifyLocalAmountManually And DistributeLocal;
	Items.CostAllocationAmountFA.Visible = SpecifyLocalAmountManually And DistributeTa;
	Items.CostAllocationPermanentDifference.Visible = SpecifyLocalAmountManually And DistributeTa
		And CalculationOfPermanentAndTemporaryDifferencesIsKept;
	Items.CostAllocationCostTD.Visible = SpecifyLocalAmountManually And DistributeTa
		And CalculationOfPermanentAndTemporaryDifferencesIsKept;
	Items.CostAllocationAITAmount.Visible = SpecifyLocalAmountManually And DistributePersonalIncomeTax And RecordsAreKeptAccordingToAIT;
	
	Items.CostAllocationCostShare.Visible =
		Object.CostAllocationFromCostCenter
		Or (Not SpecifyManAmountManually And DistributeMan)
		Or (Not SpecifyLocalAmountManually And (DistributeLocal Or DistributeTa));
		
	Items.GroupExpenseByItem.Visible = Not Object.CostAllocationFromCostCenter;
	Items.GroupAmountsMan.Visible = DistributeMan And Not Object.CostAllocationFromCostCenter;
	Items.ReglSumGroup.Visible = (DistributeLocal Or DistributeTa) And Not Object.CostAllocationFromCostCenter;
	Items.GroupHIAExpense.Visible = Object.CostAllocationFromCostCenter;
	Items.AmountOfHIA.Visible = Object.CostAllocationFromCostCenter;
	
	Items.ManagementAccounting.Enabled = CostAllocationOptionManag
		= PredefinedValue("Enum.CostAllocationOptions.ToDeferredExpenses");
	Items.LocalAccounting.Enabled = CostAllocationOptionLocal
		= PredefinedValue("Enum.CostAllocationOptions.ToDeferredExpenses");
	Items.LocalizationTaxAccounting.Enabled = CostAllocationOptionTax
		= PredefinedValue("Enum.CostAllocationOptions.ToDeferredExpenses");
	
EndProcedure

&AtServer
Procedure FillInDetailsPermanentAndTemporaryDifferencesAreRecorded()
	
	CalculationOfPermanentAndTemporaryDifferencesIsKept = True;
	CalculationOfPermanentAndTemporaryDifferencesIsKept = GetFunctionalOption("UseLocal")
		And AccountingPoliciesTaxSettingsLocalization.CalculationOfPermanentAndTemporaryDifferencesIsKept(Object.Organization, Object.Date);
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtClient
Procedure FillInDivisionInTablePart(SelectedRows)
	
	If Object.CostAllocation.Count() > 0 Then
	
		FilterByCompany = New Structure;
		FilterByCompany.Insert("Organization", Object.Organization);
		OpenForm(
			"Catalog.BusinessStructure.Form.ChoiceForm",
			FilterByCompany,
			ThisForm,,,, 
			New CallbackDescription("FillInDivisionInTablePartCompletion",
				ThisObject,
				New Structure("SelectedRows", SelectedRows)),
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInDivisionInTablePartCompletion(Result, AdditionalParameters) Export

	SelectedRows = AdditionalParameters.SelectedRows;
	If ValueIsFilled(Result) Then
		If ValueIsFilled(SelectedRows) Then
			For Each String In SelectedRows Do
				TableRow = Object.CostAllocation.FindByID(String);
				If TableRow <> Undefined Then
					TableRow.Department = Result;
				EndIf;
			EndDo;
		Else
			For Each TableRow In Object.CostAllocation Do
				TableRow.Department = Result;
			EndDo;
		EndIf;
	EndIf;

EndProcedure

&AtServer
Procedure FillInDetailsInTablePart_(ThereIsBanOnChanges)
	DataBanTemplate = PeriodClosingDates.DataToCheckTemplate();
	TemplateRow = DataBanTemplate.Add();
	TemplateRow.Section = "RoutineOperations";
	For Each String In Object.CostAllocation Do
		TemplateRow.Date = BegOfDay(String.Date);
		String.DataChangesDenied = PeriodClosingDates.PeriodEndClosingFound(DataBanTemplate);
		String.AmountFA = String.SumCompl - String.PermanentDifference - String.CostTD;
		If String.DataChangesDenied Then
			ThereIsBanOnChanges = True;
		EndIf;
	EndDo;
EndProcedure

&AtServer
Function CheckDataModificationBan(Val Date, WarningText)
	WarningText = "";
	
	DataBanTemplate = PeriodClosingDates.DataToCheckTemplate();
	TemplateRow = DataBanTemplate.Add();
	TemplateRow.Date = BegOfDay(Date);
	TemplateRow.Section = "RoutineOperations";
	
	If PeriodClosingDates.PeriodEndClosingFound(DataBanTemplate) Then
		BanDateSet = True;
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đối với %1 đã thiết lập ngày cấm soạn. Hãy chỉ ra ngày khác';
				|ru = 'На %1 установлена дата запрета редактирования. Укажите другую дату';
				|en = 'Editing closing date is set for %1. Specify another date'; fa = 'Editing closing date is set for %1. Specify another date';
				|it = 'Al %1è impostata la data del divieto di modifica. Indicate una data diversa';
				|pl = 'Na %1 jest ustawiony zakaz edytowania. Wprowadź inną datę';
				|tr = 'Düzenleme yasağı tarihi %1 olarak ayarlanmadı. Farklı tarih belirt'"),
			Format(Date, "DLF=D"));
	Else
		BanDateSet = False;
	EndIf;
	Return BanDateSet;
EndFunction

&AtServer
Procedure SetFormElementHeaders()
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	Items.AmountEntryOptionLocal.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Số tiền theo tiền tệ kế toán tài chính (%1)';
			|ru = 'Сумма в валюте регламентированного учета (%1)';
			|en = 'Amount in local accounting currency (%1)'; fa = 'Amount in local accounting currency (%1)';
			|it = 'Importo nella valuta della contabilità regolamentata (%1)';
			|pl = 'Wartość w walucie ewidencji reglamentowanej (%1)';
			|tr = 'Yerel muhasebe para biriminde tutar (%1)'"),
		LocalAccountingCurrency);
	Items.CostAllocationSumCompl.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Kế toán doanh nghiệp (%1)';
			|ru = 'Бухгалтерский учет (%1)';
			|en = 'Local accounting (%1):'; fa = 'Local accounting (%1):';
			|it = 'Contabilità (%1)';
			|pl = 'Ewidencja księgowa (%1)';
			|tr = 'Genel muhasebe (%1)'"),
		LocalAccountingCurrency);
	Items.CostAllocationAmountFA.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Kế toán thuế (%1)';
			|ru = 'Налоговый учет (%1)';
			|en = 'Tax accounting (%1)'; fa = 'Tax accounting (%1)';
			|it = 'Contabilità fiscale (%1)';
			|pl = 'Ewidencja podatkowa (%1)';
			|tr = 'Vergi muhasebesi (%1)'"),
		LocalAccountingCurrency);
	Items.CostAllocationPermanentDifference.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Chênh lệch vĩnh viễn (%1)';
			|ru = 'Постоянная разница (%1)';
			|en = 'Permanent difference (%1)'; fa = 'Permanent difference (%1)';
			|it = 'Differenza costante (%1)';
			|pl = 'Stała różnica (%1)';
			|tr = 'Kalıcı fark (%1)'"),
		LocalAccountingCurrency);
	Items.CostAllocationCostTD.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Chênh lệch tạm thời (%1)';
			|ru = 'Временная разница (%1)';
			|en = 'Temporary difference (%1)'; fa = 'Temporary difference (%1)';
			|it = 'Differenza temporanea (%1)';
			|pl = 'Tymczasowa różnica (%1)';
			|tr = 'Geçici fark (%1)'"),
		LocalAccountingCurrency);
	Items.CostAllocationAITAmount.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Thuế thu nhập bổ sung (%1)';
			|ru = 'НДД (%1)';
			|en = 'AIT (%1)'; fa = 'AIT (%1)';
			|it = 'НДД (%1)';
			|pl = 'AIT (%1)';
			|tr = 'EGV (%1)'"),
		LocalAccountingCurrency);
EndProcedure

&AtServer
Procedure RecalculateTimeDifferenceOfDocument()

	Object.DocumentAmountTD = Object.TheAmountOfTheDocumentRegl - TheAmountOfTheDocumentIsWELL - Object.DocumentAmountPD;

EndProcedure

&AtClient
Procedure RecalculateTimeDifferenceOfString(TableRow)

	TableRow.CostTD = TableRow.SumCompl - TableRow.AmountFA - TableRow.PermanentDifference;

EndProcedure

&AtServerNoContext
Function ItemOfExpensesIsRecognizedInAITExpenses(ExpenseItem)
	Return CalculationOfCostLocalization.ItemOfExpensesIsRecognizedInAITExpenses(ExpenseItem)
EndFunction

&AtClient
Procedure RecalculateAmountOfAITOfDocument()
	
	If ItemOfExpensesIsRecognizedInAITExpenses(Object.ExpenseItem)
		 And RecordsAreKeptAccordingToAIT(Object.Date, Object.Organization) Then
		Object.DocumentAmountAIT = Object.DocumentAmountAIT;
	Else
		Object.DocumentAmountAIT = 0;
	EndIf;

EndProcedure

// Checking the item of expenses for recognition in AIT expenses.
// 
// Parameters:
//  The article for the verification is a kind of characteristicslink.Expenditure statesreferences
//  Period - Date - document date.
//  Organization - CatalogRef.Companies - auditee.
// 
// Returns:
//  Boolean - True if the expense item is recognized in AIT expenses.
&AtServerNoContext
Function RecordsAreKeptAccordingToAIT(Period, Organization)
	Return CalculationOfCostLocalization.RecordsAreKeptAccordingToAIT(Period, Organization);
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
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
	ElsIf Item.Name = "sh_ShamsiInput_BeginOfPeriod" Then
		BeginOfPeriodOnChange(Items.BeginOfPeriod);
	ElsIf Item.Name = "sh_ShamsiInput_EndOfPeriod" Then
		EndOfPeriodOnChange(Items.EndOfPeriod);
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
