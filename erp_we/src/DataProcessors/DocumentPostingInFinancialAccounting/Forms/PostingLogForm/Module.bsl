#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ChartOfAccounts = Parameters.ChartOfAccounts;
	If Not ValueIsFilled(ChartOfAccounts) Then
		ChartOfAccounts = Catalogs.FinancialAccountingChartsOfAccounts.DefaultChartOfAccounts();
	EndIf;
	
	ChartOfAccountsOnChangeServer();
	
	SetColumnHeaders();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ChartOfAccountsOnChange(Item)
	
	ChartOfAccountsOnChangeServer();
	
EndProcedure

&AtServer
Procedure ChartOfAccountsOnChangeServer()
	
	CommonClientServer.SetDynamicListFilterItem(TransactionsWithCorrespondence, "ChartOfAccounts", ChartOfAccounts);
	CommonClientServer.SetDynamicListFilterItem(TransactionsWithoutCorrespondence, "ChartOfAccounts", ChartOfAccounts);
	
	OptionForGeneratingTransactions = Undefined;
	If ValueIsFilled(ChartOfAccounts) Then
		OptionForGeneratingTransactions = Common.ObjectAttributeValue(ChartOfAccounts, "OptionForGeneratingTransactions");
	EndIf;
	
	If OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence Then
		Items.GroupPages.CurrentPage = Items.CorrespondenceTransactionPage;
	ElsIf OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithoutCorrespondence Then
		Items.GroupPages.CurrentPage = Items.PostingPageWithoutCorrespondence;
	Else
		Items.GroupPages.CurrentPage = Items.SelectChartOfAccountsPage;
	EndIf;
	

EndProcedure

&AtClient
Procedure FilterAccountOnChange(Item)
	
	ListSelectionsClientServer.ChangeListSelectionElement(TransactionsWithCorrespondence, "Account", FilterAccount, ValueIsFilled(FilterAccount), DataCompositionComparisonType.InHierarchy);
	ListSelectionsClientServer.ChangeListSelectionElement(TransactionsWithoutCorrespondence, "Account", FilterAccount, ValueIsFilled(FilterAccount), DataCompositionComparisonType.InHierarchy);
	
EndProcedure

&AtClient
Procedure FilterOrganizationOnChange(Item)
	
	ListSelectionsClientServer.ChangeListSelectionElement(TransactionsWithCorrespondence, "Organization", FilterOrganization, ValueIsFilled(FilterOrganization));
	ListSelectionsClientServer.ChangeListSelectionElement(TransactionsWithoutCorrespondence, "Organization", FilterOrganization, ValueIsFilled(FilterOrganization));
	
EndProcedure

&AtClient
Procedure FilterRecorderOnChange(Item)
	
	ListSelectionsClientServer.ChangeListSelectionElement(TransactionsWithCorrespondence, "Recorder", FilterRecorder, ValueIsFilled(FilterRecorder));
	ListSelectionsClientServer.ChangeListSelectionElement(TransactionsWithoutCorrespondence, "Recorder", FilterRecorder, ValueIsFilled(FilterRecorder));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If TypeOf(Item.CurrentData.Recorder) = Type("DocumentRef.TransactionFinancialAccounting") Then
		
		StandardProcessing = False;
		
		OpenForm("Document.TransactionFinancialAccounting.ObjectForm",
					New Structure("CurrentLineParameter, Key", Item.CurrentData.LineNumber, Item.CurrentData.Recorder));
		
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
	
	//@skip-warning
	If Common.ObjectAttributeValue(Document, "DeletionMark") Then
		Return;
	EndIf;
	
	SwitchActivityOfPostingWithCorrespondence(Document);
	SwitchActivityOfPostingWithoutCorrespondence(Document);

EndProcedure

&AtClient
Function GetDocument()
	
	If Items.GroupPages.CurrentPage = Items.CorrespondenceTransactionPage Then
		curData = Items.TransactionsWithCorrespondence.CurrentData;
	ElsIf Items.GroupPages.CurrentPage = Items.PostingPageWithoutCorrespondence Then
		curData = Items.TransactionsWithoutCorrespondence.CurrentData;
	Else
		ShowMessageBox(,NStr("vi = 'Chưa chọn chứng từ';
							|ru = 'Не выбран документ';
							|en = 'No document is selected'; fa = 'No document is selected';
							|it = 'Non è stato selezionato il documento';
							|pl = 'Nie wybrano dokumentu';
							|tr = 'Belge seçilmedi'"));
		Return Undefined;
	EndIf;
		
	
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
Procedure SwitchActivityOfPostingWithCorrespondence(Document)
	
	BeginTransaction();
	Try
		
		DataLock = New DataLock;
		DataLockItem = DataLock.Add("AccountingRegister.International.RecordSet");
		DataLockItem.SetValue("Recorder", Document);
		DataLockItem.Mode = DataLockMode.Exclusive;
		DataLock.Lock();
		
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
		CommitTransaction();
		
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Items.TransactionsWithCorrespondence.Refresh();
	
EndProcedure


&AtServer
Procedure SwitchActivityOfPostingWithoutCorrespondence(Document)
	
	BeginTransaction();
	Try
		
		DataLock = New DataLock;
		DataLockItem = DataLock.Add("AccountingRegister.InternationalWithoutCorrespondence.RecordSet");
		DataLockItem.SetValue("Recorder", Document);
		DataLockItem.Mode = DataLockMode.Exclusive;
		DataLock.Lock();
		
		DocumentTransactions = AccountingRegisters.InternationalWithoutCorrespondence.CreateRecordSet();
		DocumentTransactions.Filter.Recorder.Set(Document);
		DocumentTransactions.Read();
	
		NumberOfTransactions_ = DocumentTransactions.Count();
		If NumberOfTransactions_ <> 0 Then
			
			// We determine the current activity of transactions by the first transaction
			CurTransactionActivity = DocumentTransactions[0].Active;
	
			// Invert the current activity of transactions
			DocumentTransactions.SetActive(Not CurTransactionActivity);
			DocumentTransactions.Write();
	
		EndIf;
		CommitTransaction();
		
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Items.TransactionsWithoutCorrespondence.Refresh();
	
EndProcedure

&AtServer
Procedure SetColumnHeaders()
	
	If GetFunctionalOption("UseMultipleCompanies") Then
		Items.Recorder.Title = 
			Items.Recorder.Title + ", " + NStr("vi = 'Doanh nghiệp';
												|ru = 'Организация';
												|en = 'Company'; fa = 'Company';
												|it = 'Azienda';
												|pl = 'Firma';
												|tr = 'İş yeri'");
		Items.TransactionsWithoutCorrespondenceRecorder.Title = 
			Items.TransactionsWithoutCorrespondenceRecorder.Title + ", " + NStr("vi = 'Doanh nghiệp';
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
	FinancialAccountingOfGeneralPurpose.SetUnitHeaders(Items.Department);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
#Region TransactionsWithCorrespondence

#Region TextNormalPosting
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PostingType.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransactionsWithCorrespondence.PostingType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Thường';
													|ru = 'Обычная';
													|en = 'Standard'; fa = 'استاندارد';
													|it = 'Regolare';
													|pl = 'Standard';
													|tr = 'Normal'"));
#EndRegion

#Region PostingTemplate
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PostingTemplate.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransactionsWithCorrespondence.PostingTemplate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	MatchSelectionGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	MatchSelectionGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	ItemFilter = MatchSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransactionsWithCorrespondence.AccountComplianceDr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter = MatchSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransactionsWithCorrespondence.AccountComplianceCr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter = MatchSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransactionsWithCorrespondence.EqualityOfTurnoverTotals");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", False);
#EndRegion

#Region ComplianceOfAccountsAndTurnover
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccountComplianceDr.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransactionsWithCorrespondence.AccountComplianceDr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransactionsWithCorrespondence.AccountComplianceCr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Visible", False);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccountComplianceCr.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransactionsWithCorrespondence.AccountComplianceCr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransactionsWithCorrespondence.AccountComplianceDr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Visible", False);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EqualityOfTurnoverTotals.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransactionsWithCorrespondence.EqualityOfTurnoverTotals");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Visible", False);
#EndRegion

#EndRegion

#Region TransactionsWithoutCorrespondence

#Region TextNormalPosting
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TransactionsWithoutCorrespondencePostingType.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransactionsWithoutCorrespondence.PostingType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Thường';
													|ru = 'Обычная';
													|en = 'Standard'; fa = 'استاندارد';
													|it = 'Regolare';
													|pl = 'Standard';
													|tr = 'Normal'"));
#EndRegion

#Region PostingTemplate
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TransactionsWithoutCorrespondencePostingTemplate.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransactionsWithoutCorrespondence.PostingTemplate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	MatchSelectionGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	MatchSelectionGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	ItemFilter = MatchSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransactionsWithoutCorrespondence.AccountComplianceDr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter = MatchSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransactionsWithoutCorrespondence.AccountComplianceCr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter = MatchSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransactionsWithoutCorrespondence.EqualityOfTurnoverTotals");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", False);
#EndRegion

#Region ComplianceOfAccountsAndTurnover
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TransactionsWithoutCorrespondenceAccountCompliance.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransactionsWithoutCorrespondence.AccountCompliance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Visible", False);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TransactionsWithoutCorrespondenceEqualityOfTurnoverTotals.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransactionsWithoutCorrespondence.EqualityOfTurnoverTotals");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Visible", False);
#EndRegion

#EndRegion

EndProcedure

#EndRegion
