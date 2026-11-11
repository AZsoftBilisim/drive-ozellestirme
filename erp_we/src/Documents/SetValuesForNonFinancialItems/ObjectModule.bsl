#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	EmployeeResponsible = Users.CurrentUser();
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	Var TempTableManager;
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	Indicators = New Array;
	If OperationKind = Enums.OperationKindsOfSettingOfNonFinancialItemValues.EnterValuesFromTemplate Then
		If ValueIsFilled(InputTemplate) Then
			Documents.SetValuesForNonFinancialItems.PrepareTemplateTables(InputTemplate, TempTableManager);
			PeriodType = Documents.SetValuesForNonFinancialItems.TypeOfDocumentFormPeriod(InputTemplate, TempTableManager);
			TableOfIndicators = Common.ObjectAttributeValue(InputTemplate,
				"TemplateIndicators.Factor").Unload();
			Indicators = TableOfIndicators.UnloadColumn("Factor");
		EndIf;
	Else
		If ValueIsFilled(NonFinancialItem) Then
			Documents.SetValuesForNonFinancialItems.PrepareTemplateTables(NonFinancialItem, TempTableManager);
			PeriodType = Documents.SetValuesForNonFinancialItems.TypeOfDocumentFormPeriod(
				NonFinancialItem, TempTableManager);
			Indicators.Add(NonFinancialItem);
		EndIf;
	EndIf;
	
	If PeriodType = "ValidFrom" Then
		PeriodPresentation = NStr("vi = 'Thực hiện từ %1';
									|ru = 'Действует с %1';
									|en = 'Valid from %1'; fa = 'Valid from %1';
									|it = 'In vigore dal %1';
									|pl = 'Obowiązuje od %1';
									|tr = '%1 itibarıyla geçerli'");
		PeriodPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			PeriodPresentation,
			Format(BeginOfPeriod, "DLF=D"));
	ElsIf PeriodType = "Period" Then
		PeriodPresentation = NStr("vi = 'Kỳ từ %1 đến %2';
									|ru = 'Период с %1 по %2';
									|en = 'Period from %1 to %2'; fa = 'Period from %1 to %2';
									|it = 'Periodo da %1 a %2';
									|pl = 'Okres od %1 do %2';
									|tr = '%1 tarihinden %2 tarihine kadar dönem'");
		PeriodPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			PeriodPresentation,
			Format(BeginOfPeriod, "DLF=D"),
			Format(PeriodEnding, "DLF=D"));
	Else
		Array = New Array;
		CommonClientServer.SupplementArray(Array, DocumentRows.UnloadColumn("Period"), True);
		CommonClientServer.SupplementArray(Array, DocumentColumns.UnloadColumn("Period"), True);
		List = New ValueList;
		List.LoadValues(Array);
		List.SortByValue();
		If List.Count() Then
			MinDate_ = List[0].Value;
			MaxDate_ = List[List.Count() - 1].Value;
			PeriodPresentation = NStr("vi = 'Kỳ từ %1 đến %2';
										|ru = 'Периоды с %1 по %2';
										|en = 'Periods from %1 to %2'; fa = 'Periods from %1 to %2';
										|it = 'Periodi da %1 a %2';
										|pl = 'Okresy od %1 do %2';
										|tr = '%1 ''den  %2''e kadar dönemler'");
			PeriodPresentation = StringFunctionsClientServer.SubstituteParametersToString(
				PeriodPresentation,
				Format(MinDate_, "DLF=D"),
				Format(MaxDate_, "DLF=D"));
		EndIf;
	EndIf;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	ReplacedEmptyValues = BudgetingServerCall.ReplacedEmptyValues();
	SearchDetailsForEmptyAnalytics = New Array;
	
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		SearchDetailsForEmptyAnalytics.Add("Dimension" + Cnt);
		SearchDetailsForEmptyAnalytics.Add("DocumentRows.Dimension" + Cnt);
		SearchDetailsForEmptyAnalytics.Add("DocumentColumns.Dimension" + Cnt);
	EndDo;
	
	For Each TSRow In ColumnValues Do
		If ValueIsFilled(TSRow.Dimension) Then
			If Not ReplacedEmptyValues.Find(TSRow.Value) = Undefined Then
				TSRow.Value = BudgetingClientServer.EmptyDimensionValue();
			EndIf;
		EndIf;
	EndDo;
	
	BudgetingServerCall.ReplaceValuesInObject(ThisObject,
			SearchDetailsForEmptyAnalytics,
			ReplacedEmptyValues,
			BudgetingClientServer.EmptyDimensionValue());
	
	NonFinancialItemPresentation = StrConcat(Indicators, ", ");
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	Var TempTableManager;
	
	VerifiedObjectAttributes = New Array;
	If OperationKind = Enums.OperationKindsOfSettingOfNonFinancialItemValues.EnterValuesFromTemplate Then
		VerifiedObjectAttributes.Add("NonFinancialItem");
		Documents.SetValuesForNonFinancialItems.PrepareTemplateTables(InputTemplate, TempTableManager);
		PeriodType = Documents.SetValuesForNonFinancialItems.TypeOfDocumentFormPeriod(InputTemplate, TempTableManager);
	Else
		VerifiedObjectAttributes.Add("InputTemplate");
		Documents.SetValuesForNonFinancialItems.PrepareTemplateTables(NonFinancialItem, TempTableManager);
		PeriodType = Documents.SetValuesForNonFinancialItems.TypeOfDocumentFormPeriod(NonFinancialItem, TempTableManager);
	EndIf;
	
	If PeriodType <> "Period" Then
		VerifiedObjectAttributes.Add("PeriodEnding");
	EndIf;
	
	If PeriodType = "None" Then
		VerifiedObjectAttributes.Add("BeginOfPeriod");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, VerifiedObjectAttributes);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	EmployeeResponsible = Users.CurrentUser();
	
EndProcedure

#EndRegion

#EndIf
