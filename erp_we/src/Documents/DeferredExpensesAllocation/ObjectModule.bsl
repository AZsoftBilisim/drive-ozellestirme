#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		FillPropertyValues(ThisObject, FillingData);
		
		CompositionAndDistributionRules = "BeginOfPeriod,DeferredExpensesDistributionBase,NumberOfMonths";
		CompositionOfAccountingSettings = "CostAllocationOptionManag,CostAllocationOptionLocal";
		CompositionOfAccountingSettings = CompositionOfAccountingSettings + ",CostAllocationOptionTax";
		RecordsAreKeptAccordingToAIT = CalculationOfCostLocalization.GetFunctionalOptionAITAccounting();
		
		If Not FillingData.Property("RBPRule") Then
			
			Query = New Query;
			Query.Text = 
				"SELECT
				|	CASE
				|		WHEN ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
				|			THEN ISNULL(ExpenseItems.CostAllocationRuleLocal.BeginOfPeriod, """")
				|		WHEN ExpenseItems.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
				|			THEN ISNULL(ExpenseItems.CostAllocationRuleManag.BeginOfPeriod, """")
				|		WHEN ExpenseItems.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
				|			THEN ISNULL(ExpenseItems.CostAllocationRuleTax.BeginOfPeriod, """")
				|		ELSE """"
				|	END AS BeginOfPeriod,
				|	CASE
				|		WHEN ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
				|			THEN ISNULL(ExpenseItems.CostAllocationRuleLocal.DeferredExpensesDistributionBase, UNDEFINED)
				|		WHEN ExpenseItems.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
				|			THEN ISNULL(ExpenseItems.CostAllocationRuleManag.DeferredExpensesDistributionBase, UNDEFINED)
				|		WHEN ExpenseItems.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
				|			THEN ISNULL(ExpenseItems.CostAllocationRuleTax.DeferredExpensesDistributionBase, UNDEFINED)
				|		ELSE UNDEFINED
				|	END AS DeferredExpensesDistributionBase,
				|	CASE
				|		WHEN ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
				|			THEN ISNULL(ExpenseItems.CostAllocationRuleLocal.NumberOfMonths, 0)
				|		WHEN ExpenseItems.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
				|			THEN ISNULL(ExpenseItems.CostAllocationRuleManag.NumberOfMonths, 0)
				|		WHEN ExpenseItems.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
				|			THEN ISNULL(ExpenseItems.CostAllocationRuleTax.NumberOfMonths, 0)
				|		ELSE 0
				|	END AS NumberOfMonths,
				|	ExpenseItems.CostAllocationOptionLocal AS CostAllocationOptionLocal,
				|	ExpenseItems.CostAllocationOptionTax AS CostAllocationOptionTax,
				|	ExpenseItems.CostAllocationOptionManag AS CostAllocationOptionManag
				|FROM
				|	ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
				|WHERE
				|	ExpenseItems.Ref = &Ref";
			
			Query.SetParameter("Ref", ExpenseItem);
			If Not ValueIsFilled(ExpenseItem) Then
				
				Query.Text = StrReplace(Query.Text, "ChartOfCharacteristicTypes.ExpenseItems", "Catalog.CostCenters");
				Query.SetParameter("Ref", DimensionOfExpenses);
				
			EndIf;
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				PopulationSettings = New Structure(CompositionAndDistributionRules);
				FillPropertyValues(PopulationSettings, Selection);
				AccountingSettings = New Structure(CompositionOfAccountingSettings);
				FillPropertyValues(AccountingSettings, Selection);
			Else
				PopulationSettings = Undefined;
			EndIf;
			
		Else
			
			PopulationSettings = Common.ObjectAttributesValues(FillingData.RBPRule, CompositionAndDistributionRules);
			AccountingSettings = Common.ObjectAttributesValues(ExpenseItem, CompositionOfAccountingSettings);
			If Not ValueIsFilled(ExpenseItem) And TypeOf(DimensionOfExpenses) = Type("CatalogRef.CostCenters") Then
				
				AccountingSettings = Common.ObjectAttributesValues(DimensionOfExpenses, CompositionOfAccountingSettings);
				
			EndIf;
			
		EndIf;
		
		RBPDistributionOption = Enums.CostAllocationOptions.ToDeferredExpenses;
		
		If AccountingSettings <> Undefined Then
			If Not FillingData.Property("ManagementAccounting") Then
				FillingData.Insert("ManagementAccounting", AccountingSettings.CostAllocationOptionManag = RBPDistributionOption);
			EndIf;
			If Not FillingData.Property("LocalAccounting") Then
				FillingData.Insert("LocalAccounting", AccountingSettings.CostAllocationOptionLocal = RBPDistributionOption);
			EndIf;
			If Not FillingData.Property("TaxAccounting") Then
				FillingData.Insert("TaxAccounting", 
					Not GetFunctionalOption("UseLocal") Or AccountingSettings.CostAllocationOptionTax = RBPDistributionOption);
			EndIf;
			If RecordsAreKeptAccordingToAIT And Not FillingData.Property("AIT") Then
				FillingData.Insert("AIT",  AccountingSettings.CostAllocationOptionTax = RBPDistributionOption);
			EndIf;
		EndIf;
			
		If Not PopulationSettings = Undefined Then
		
			If PopulationSettings.BeginOfPeriod = "FromDateOfOccurrence" Then
				If ValueIsFilled(FillingData.Period) Then
					BeginOfPeriod = Documents.DeferredExpensesAllocation.GetDateOfOccurrenceOfRBP(FillingData);
				ElsIf ValueIsFilled(FillingData.Date) Then
					BeginOfPeriod = EndOfMonth(FillingData.Date) + 1;
				Else
					BeginOfPeriod = CurrentSessionDate();
				EndIf;
			ElsIf PopulationSettings.BeginOfPeriod = "SinceBeginningOfMonth" Then
				If ValueIsFilled(FillingData.Date) Then
					BeginOfPeriod = EndOfMonth(FillingData.Date) + 1;
				ElsIf ValueIsFilled(FillingData.Period) Then
					BeginOfPeriod = EndOfMonth(FillingData.Period) + 1;
				Else
					BeginOfPeriod = EndOfMonth(CurrentSessionDate()) + 1;
				EndIf;
			EndIf;
			If ValueIsFilled(FillingData.Date) Then
				Date = FillingData.Date;
			ElsIf ValueIsFilled(FillingData.Period) Then
				Date = FillingData.Period;
			Else
				Date = CurrentSessionDate();
			EndIf;
			
			NumberOfMonths = PopulationSettings.NumberOfMonths;
			AllocatedAccordingToRule = PopulationSettings.DeferredExpensesDistributionBase;
		EndIf;
		
		If FillingData.Property("ManagementAccounting") And Not FillingData.ManagementAccounting Then
			DocumentAmount = 0;
			DocumentAmountManag = 0;
		EndIf;
		
		If FillingData.Property("LocalAccounting") And Not FillingData.LocalAccounting Then
			TheAmountOfTheDocumentRegl = 0;
		EndIf;
		If FillingData.Property("TaxAccounting") And Not FillingData.TaxAccounting Then
			DocumentAmountTD = TheAmountOfTheDocumentRegl;
			TheAmountOfTheDocumentRegl = 0;
			DocumentAmountPD = 0;
		EndIf;
		If RecordsAreKeptAccordingToAIT And FillingData.Property("AIT") And Not FillingData.AIT Then
			DocumentAmountAIT = 0;
		EndIf;
		
		If DocumentAmount <> 0 Or DocumentAmountManag <> 0 Then
			AmountEntryOptionMan = Enums.OptionsOfDEAmountSpecification.SpecifiedManually;
		EndIf;
		If TheAmountOfTheDocumentRegl <> 0 Or DocumentAmountPD <> 0 Or DocumentAmountTD <> 0
			Or DocumentAmountAIT <> 0
			 
			Then
			AmountEntryOptionLocal = Enums.OptionsOfDEAmountSpecification.SpecifiedManually;
		EndIf;
		
	EndIf;
		
	InitializeDocument(FillingData);
	
	ItemsAndDimensionsSelectionParameters = Documents.DeferredExpensesAllocation.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	DeferredExpensesAllocationLocalization.Filling(ThisObject, FillingData, StandardProcessing);

EndProcedure

Procedure OnCopy(CopiedObject)

	CostAllocation.Clear();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "CostAllocation");
	
	DeferredExpensesAllocationLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	// Let's check the correspondence of the amounts of the document and the tabular part.
	If DocumentAmount <> CostAllocation.Total("Sum")
	 Or TheAmountOfTheDocumentRegl <> CostAllocation.Total("SumCompl")
	 Or DocumentAmountPD <> CostAllocation.Total("PermanentDifference")
	 Or DocumentAmountTD <> CostAllocation.Total("CostTD")
	 Or DocumentAmountAIT <> CostAllocation.Total("AITAmount")
	 Then
		Text = NStr("vi = 'Số tiền theo dòng trong phần bảng phải bằng số tiền trong chứng từ';
					|ru = 'Сумма по строкам в табличной части должна равняться соответствующим суммам документа';
					|en = 'Amount of rows in the table should be equal to the corresponding document amount'; fa = 'Amount of rows in the table should be equal to the corresponding document amount';
					|it = 'L''importo nelle righe nella tabella deve corrispondere ai relativi importi del documento';
					|pl = 'Wartość w wierszach w sekcji tabelarycznej powinna być równa odpowiedniom kwotom dokumentu.';
					|tr = 'Tablo bölümündeki satırların toplamı, belgenin uygun gelen miktarlarına eşit olmalıdır'");
		CommonClientServer.MessageToUser(
			Text,
			ThisObject,
			"CostAllocation[0].Date",
			,
			Cancel);
	EndIf;
	
	// When automatically determining the amount, it is unacceptable to attribute to the expenses of the past or current period 
	// (the exception is articles with distribution options "On the fin. result" and "Do not distribute")
	AutomaticDistributionOfMan = ManagementAccounting And AmountEntryOptionMan = Enums.OptionsOfDEAmountSpecification.DeterminedAutomatically;
	LocalAutoDistribution = LocalAccounting And AmountEntryOptionMan = Enums.OptionsOfDEAmountSpecification.DeterminedAutomatically; 
	If AutomaticDistributionOfMan Or LocalAutoDistribution Then
		
		ExclusionOptions = New Array();
		ExclusionOptions.Add(Enums.CostAllocationOptions.ToNonCurrentAssetCost);
		ExclusionOptions.Add(Enums.CostAllocationOptions.ToLinesOfBusiness);
		ExclusionOptions.Add(Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly);
		ExclusionOptions.Add(Enums.CostAllocationOptions.DoNotAllocate);
		
		DistributionArticles = CostAllocation.Unload(, "ExpenseItem");
		DistributionArticles.GroupBy("ExpenseItem");
		DistributionOptions = Common.ObjectsAttributesValues(
			DistributionArticles.UnloadColumn("ExpenseItem"), 
			"CostAllocationOptionManag,CostAllocationOptionLocal");
		NextMonth = EndOfMonth(Date) + 1;
		MessageTemplate = NStr(
			"vi = 'Dòng %1: đối với dạng có phương án phân bổ ""%2"" ngày phân bổ không được liên quan đến kỳ hiện tại khi tự động xác định số tiền chi phí trả trước';
			|ru = 'Строка %1: для статьи с вариантом распределения ""%2"" дата распределения не может относится к текущему периоду при автоматическом определении суммы РБП';
			|en = 'Line %1: for the item with the ""%2"" allocation option, the allocation date cannot be related to the current period when the deferred expense amount is determined automatically'; fa = 'Line %1: for the item with the ""%2"" allocation option, the allocation date cannot be related to the current period when the deferred expense amount is determined automatically';
			|it = 'Riga %1: per la voce con opzione di ripartizione ""%2"" la data di ripartizione non può far riferimento al periodo corrente con importo di spese dei periodi futuri determinati automaticamente';
			|pl = 'Wiersz %1: dla pozycji z wariantem przydzielenia ""%2"" data przydzielenia nie może należeć do bieżącego okresu podczas automatycznego przydzielenia wartości rozchodów przyszłych okresów';
			|tr = 'Satır %1: ""%2"" dağıtım seçeneğine sahip bir kalem için, ertelenmiş giderler tutarı otomatik olarak belirlenirken dağıtım tarihi cari dönemle ilişkilendirilemez'");
		
		For Each RBPLine In CostAllocation Do
			ExpenseItemSettings = DistributionOptions.Get(RBPLine.ExpenseItem);
			If AutomaticDistributionOfMan 
				 And RBPLine.Date < NextMonth
				 And ExclusionOptions.Find(ExpenseItemSettings.CostAllocationOptionManag) = Undefined
			Then
				Text = StrTemplate(
					MessageTemplate, 
					Format(RBPLine.LineNumber, "NG=0;"), 
					String(ExpenseItemSettings.CostAllocationOptionManag));
				Common.MessageToUser(
					Text,
					ThisObject,
					StrTemplate("CostAllocation[%1].Date",Format(RBPLine.LineNumber-1, "NG=0;")),
					,
					Cancel);
			EndIf;
			If LocalAutoDistribution 
				 And RBPLine.Date < NextMonth
				 And ExclusionOptions.Find(ExpenseItemSettings.CostAllocationOptionLocal) = Undefined
			Then
				Text = StrTemplate(
					MessageTemplate, 
					Format(RBPLine.LineNumber, "NG=0;"), 
					String(ExpenseItemSettings.CostAllocationOptionLocal));
				Common.MessageToUser(
					Text,
					ThisObject,
					StrTemplate("CostAllocation[%1].Date",Format(RBPLine.LineNumber-1, "NG=0;")),
					,
					Cancel);
			EndIf;
		EndDo;
	EndIf;

	NotCheckedAttributeArray = New Array;
	If CostAllocationFromCostCenter Then
		NotCheckedAttributeArray.Add("ExpenseItem");
	EndIf;
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	ItemsAndDimensionsSelectionParameters = Documents.DeferredExpensesAllocation.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	DeferredExpensesAllocationLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If WriteMode = DocumentWriteMode.UndoPosting Then
		PeriodEndClosingDatesTM.EnableVerificationOfDateWhenChangesWereBanned(ThisObject);
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting Then
		ClearManAmounts = False;
		ClearSummyregl = False;
		If AmountEntryOptionMan = Enums.OptionsOfDEAmountSpecification.DeterminedAutomatically Then
			If DocumentAmount <> 0 Or DocumentAmountManag <> 0 Then
				DocumentAmount = 0;
				DocumentAmountManag = 0;
			EndIf;
			If CostAllocation.Total("Sum") <> 0 Or CostAllocation.Total("SumMan") <> 0 Then
				ClearManAmounts = True;
			EndIf;
		EndIf;
		If AmountEntryOptionLocal = Enums.OptionsOfDEAmountSpecification.DeterminedAutomatically Then
			If TheAmountOfTheDocumentRegl <> 0 Or DocumentAmountPD <> 0 Or DocumentAmountTD <> 0 
				Or DocumentAmountAIT <> 0
				Then
				TheAmountOfTheDocumentRegl = 0;
				DocumentAmountPD = 0;
				DocumentAmountTD = 0;
				DocumentAmountAIT = 0;
			EndIf;
			If CostAllocation.Total("SumCompl") <> 0
			 Or CostAllocation.Total("PermanentDifference") <> 0
			 Or CostAllocation.Total("CostTD") <> 0
			 Or CostAllocation.Total("AITAmount") <> 0
			 Then
				ClearSummyregl = True;
			EndIf;
		EndIf;
		If ClearManAmounts Or ClearSummyregl Then
			For Each String In CostAllocation Do
				If ClearManAmounts Then
					String.Sum = 0;
					String.SumMan = 0;
				EndIf;
				If ClearSummyregl Then
					String.SumCompl = 0;
					String.PermanentDifference = 0;
					String.CostTD = 0;
					String.AITAmount = 0;
				EndIf;
			EndDo;
		EndIf;
		
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "CostAllocation");
	
	ItemsAndDimensionsSelectionParameters = Documents.DeferredExpensesAllocation.ItemsAndDimensionsSelectionParameters();
	If Not CostAllocationFromCostCenter Then
		IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	EndIf;
	
	DeferredExpensesAllocationLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure
	
Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)

	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	// Registration of a task for calculating the cost price.
	AttributesNames = "CostAllocationOptionManag, CostAllocationOptionLocal, CostAllocationOptionTax";
	Attributes = Common.ObjectAttributesValues(
		?(ValueIsFilled(ExpenseItem), ExpenseItem, DimensionOfExpenses), AttributesNames);
	
	If (AmountEntryOptionMan = Enums.OptionsOfDEAmountSpecification.DeterminedAutomatically
		And Attributes.CostAllocationOptionManag = Enums.CostAllocationOptions.ToDeferredExpenses 
		And ManagementAccounting)
	Or (AmountEntryOptionLocal = Enums.OptionsOfDEAmountSpecification.DeterminedAutomatically
		And Attributes.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToDeferredExpenses
		And LocalAccounting)
	Or (AmountEntryOptionLocal = Enums.OptionsOfDEAmountSpecification.DeterminedAutomatically
		And Attributes.CostAllocationOptionTax = Enums.CostAllocationOptions.ToDeferredExpenses
		And LocalAccounting)
	Or (AmountEntryOptionLocal = Enums.OptionsOfDEAmountSpecification.DeterminedAutomatically
		And Attributes.CostAllocationOptionTax = Enums.CostAllocationOptions.ToDeferredExpenses
		And AIT)
	Then
		DataBanTemplate = PeriodClosingDates.DataToCheckTemplate();
		TemplateRow = DataBanTemplate.Add();
		TemplateRow.Section = "RoutineOperations";
		TemplateRow.Date = BegOfMonth(Date);
		ThereIsBanOnChangingDateOfDocument = PeriodClosingDates.PeriodEndClosingFound(DataBanTemplate);
		If Not ThereIsBanOnChangingDateOfDocument Then
			InformationRegisters.JobsForCalculatingCost.CreateRegisterEntry(Date, Ref, Organization);
		EndIf;
	EndIf;
	
	Query = New Query();
	Query.Text = "
	|SELECT TOP 1 
	|	TRUE
	|FROM Document.DeferredExpensesAllocation AS Doc
	|WHERE
	|	Doc.Date BETWEEN &StartDate AND &EndDate
	|	AND Doc.Posted
	|	AND NOT Doc.Ref = &Ref
	|	AND Doc.Organization = &Organization
	|	AND Doc.Department = &Department
	|	AND Doc.ExpenseItem = &ExpenseItem
	|	AND Doc.DimensionOfExpenses = &DimensionOfExpenses
	|	AND (Doc.ManagementAccounting AND Doc.AmountEntryOptionMan = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically) AND &ManagementAccounting
	|		OR Doc.LocalAccounting AND Doc.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically) AND &LocalAccounting
	|		OR Doc.TaxAccounting AND Doc.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically) AND &TaxAccounting
	|		OR Doc.AIT AND Doc.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically) AND &AIT
	|	)";
	
	Query.Parameters.Insert("StartDate", BegOfMonth(Date));
	Query.Parameters.Insert("EndDate", EndOfMonth(Date));
	Query.Parameters.Insert("Ref", Ref);
	Query.Parameters.Insert("ManagementAccounting", ManagementAccounting);
	Query.Parameters.Insert("LocalAccounting", LocalAccounting);
	Query.Parameters.Insert("TaxAccounting", TaxAccounting);
	Query.Parameters.Insert("AIT", AIT);
	Query.Parameters.Insert("Organization", Organization);
	Query.Parameters.Insert("Department", Department);
	Query.Parameters.Insert("ExpenseItem", ExpenseItem);
	Query.Parameters.Insert("DimensionOfExpenses", DimensionOfExpenses);
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		MessageText = NStr("vi = 'Đã kết chuyển chứng từ với các tùy chỉnh như vậy trong tháng này';
							|ru = 'Документ с такими настройками уже проведен в данном месяце';
							|en = 'The document with these settings has already been posted this month'; fa = 'The document with these settings has already been posted this month';
							|it = 'Un documento con queste impostazioni è già stato registrato questo mese';
							|pl = 'Dokument z takimi ustawieniami jest już zatwierdzony w bieżącym miesiącu';
							|tr = 'Bu ayarlara sahip belge verilen ayda artık kaydedildi'");
		Common.MessageToUser(MessageText,, "Object.Date",, Cancel);
	EndIf;
	
	DeferredExpensesAllocationLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	DeferredExpensesAllocationLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	EmployeeResponsible = Users.CurrentUser();
	
	If Not ValueIsFilled(Organization) Then
		
		Organization = Common.CommonSettingsStorageLoad("CurrentCompany", "");
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
