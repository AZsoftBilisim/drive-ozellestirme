
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ChartOfAccounts = Parameters.ChartOfAccounts;
	If Parameters.Filter.Property("ChartOfAccounts") And ValueIsFilled(Parameters.Filter.ChartOfAccounts) Then
		ChartOfAccounts = Parameters.Filter.ChartOfAccounts;
		Parameters.Filter.Delete("ChartOfAccounts");
		Items.ChartOfAccounts.Enabled = False;
	EndIf;
	If Not ValueIsFilled(ChartOfAccounts) Then
		ChartOfAccounts = Catalogs.FinancialAccountingChartsOfAccounts.DefaultChartOfAccounts();
	EndIf;
	CommonClientServer.SetDynamicListFilterItem(List, "ChartOfAccounts", ChartOfAccounts);
	
	SetConditionalAppearance();
	SetColumnHeaders();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ChartOfAccountsOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "ChartOfAccounts", ChartOfAccounts);
	
EndProcedure

&AtClient
Procedure FilterAccountOnChange(Item)
	
	ListSelectionsClientServer.ChangeListSelectionElement(List, "Account", FilterAccount, ValueIsFilled(FilterAccount), DataCompositionComparisonType.InHierarchy);
	
EndProcedure

&AtClient
Procedure FilterOrganizationOnChange(Item)
	
	ListSelectionsClientServer.ChangeListSelectionElement(List, "Organization", FilterOrganization, ValueIsFilled(FilterOrganization));

EndProcedure

&AtClient
Procedure FilterRecorderOnChange(Item)
	
	ListSelectionsClientServer.ChangeListSelectionElement(List, "Recorder", FilterRecorder, ValueIsFilled(FilterRecorder));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If TypeOf(Item.CurrentData.Recorder) = Type("DocumentRef.TransactionFinancialAccounting") Then
		
		StandardProcessing = False;
		
		OpenForm("Document.TransactionFinancialAccounting.ObjectForm",
					New Structure("CurrentLineParameter,Key", Item.CurrentData.LineNumber,Item.CurrentData.Recorder));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SwitchPostingActivity(Command)
	
	CurDocument = GetDocument();
	
	If CurDocument <> Undefined Then
		
		SwitchPostingActivityServer(CurDocument);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SwitchPostingActivityServer(Document)
	
	SwitchEntriesActivityIFA(Document);
	
	Items.List.Refresh();
	
EndProcedure

&AtClient
Function GetDocument()
	
	curData = Items.List.CurrentData;
	
	If curData = Undefined Then
		ShowMessageBox(,NStr("vi = 'Chưa chọn chứng từ';
							|ru = 'Не выбран документ';
							|en = 'No document is selected'; fa = 'No document is selected';
							|it = 'Non è stato selezionato il documento';
							|pl = 'Nie wybrano dokumentu';
							|tr = 'Belge seçilmedi'"));
		Return Undefined;
	EndIf;
	
	CurDocument = curData.Recorder;
	If Not ValueIsFilled(CurDocument) Then
		ShowMessageBox(,NStr("vi = 'Chưa chọn chứng từ';
							|ru = 'Не выбран документ';
							|en = 'No document is selected'; fa = 'No document is selected';
							|it = 'Non è stato selezionato il documento';
							|pl = 'Nie wybrano dokumentu';
							|tr = 'Belge seçilmedi'"));
		Return Undefined;
	EndIf;
	
	Return CurDocument;
	
EndFunction

&AtServer
Procedure SwitchEntriesActivityIFA(Document)
	
	If Document.DeletionMark Then
		Return;
	EndIf;

	DocumentTransactions = AccountingRegisters.International.CreateRecordSet();
	DocumentTransactions.Filter.Recorder.Set(Document);
	DocumentTransactions.Read();

	NumberOfTransactions_ = DocumentTransactions.Count();
	If Not (NumberOfTransactions_ = 0) Then
		
		// We determine the current activity of transactions by the first transaction
		CurTransactionActivity = DocumentTransactions[0].Active;

		// Invert the current activity of transactions
		DocumentTransactions.SetActive(Not CurTransactionActivity);
		DocumentTransactions.Write();

	EndIf;
		
EndProcedure

&AtServer
Procedure SetColumnHeaders()

	If GetFunctionalOption("UseMultipleCompanies") Then
		Items.Recorder.Title = Items.Recorder.Title + ", " + NStr("vi = 'Doanh nghiệp';
																	|ru = 'Организация';
																	|en = 'Company'; fa = 'Company';
																	|it = 'Azienda';
																	|pl = 'Firma';
																	|tr = 'İş yeri'");
	EndIf;
	
	FinancialAccountingOfGeneralPurpose.SetUnitHeaders(Items.DepartmentDr, NStr("vi = 'Nợ';
																				|ru = 'Дт';
																				|en = 'Dr'; fa = 'بد';
																				|it = 'Debito';
																				|pl = 'Wn';
																				|tr = 'Borç'"));
	FinancialAccountingOfGeneralPurpose.SetUnitHeaders(Items.DepartmentCr, NStr("vi = 'Có';
																				|ru = 'Кт';
																				|en = 'Cr'; fa = 'بس';
																				|it = 'Credito';
																				|pl = 'Ma';
																				|tr = 'Alacak'"));
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
#Region TextNormalPosting
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("PostingType");
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.PostingType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Thường';
													|ru = 'Обычная';
													|en = 'Normal'; fa = 'عادی';
													|it = 'Regolare';
													|pl = 'Normal';
													|tr = 'Normal'"));
#EndRegion

#Region PostingTemplate
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("PostingTemplate");
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.PostingTemplate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	MatchSelectionGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	MatchSelectionGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	ItemFilter = MatchSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.AccountComplianceDr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter = MatchSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.AccountComplianceCr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter = MatchSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.EqualityOfTurnoverTotals");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", False);
#EndRegion

#Region ComplianceOfAccountsAndTurnover
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("AccountComplianceDr");
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.AccountComplianceDr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.AccountComplianceCr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Visible", False);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("AccountComplianceCr");
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.AccountComplianceCr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.AccountComplianceDr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Visible", False);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("EqualityOfTurnoverTotals");
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.EqualityOfTurnoverTotals");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Visible", False);
#EndRegion

EndProcedure

#EndRegion
