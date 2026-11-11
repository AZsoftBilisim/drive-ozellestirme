
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	RestoreSettings(Parameters);
	
	CommonClientServer.SetDynamicListFilterItem(
		ToRegister,
		"AdvanceHolder",
		AdvanceHolder,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(AdvanceHolder));
		
	CommonClientServer.SetDynamicListFilterItem(
		ToRegister,
		"Organization",
		Organization,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Organization));
		
	CommonClientServer.SetDynamicListFilterItem(
		ToRegister,
		"Department",
		Department,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Department));
	
	ToRegister.Parameters.SetParameterValue("CurrentDate", New Boundary(EndOfDay(CurrentSessionDate())));
	
	ControlIssueOfCashByPurposes = GetFunctionalOption("ControlIssueOfCashByPurposes");
	Items.ToRegisterIssuancePurpose.Visible = ControlIssueOfCashByPurposes;
	Items.ToRegisterOrganization.Visible = GetFunctionalOption("UseMultipleCompanies");
	Items.ToRegisterDepartment.Visible = GetFunctionalOption("UseBusinessUnits");
	Items.ToRegisterCurrency.Visible = GetFunctionalOption("UseMultipleCurrencies");
	
	Items.AdvancesAdvanceReport.Visible = AccessRight("Update", Metadata.Documents.ExpenseReport);
	Items.AdvancesCashReceiptOrder.Visible = AccessRight("Update", Metadata.Documents.CashAccountReceiptNote);
	Items.AdvancesNonCashCashReceipts.Visible = AccessRight("Update", Metadata.Documents.PaymentRequest);
	Items.AdvancesRequestForARefund.Visible = AccessRight("Update", Metadata.Documents.PaymentRequest);
	Items.AdvancesExpenseCashOrder.Visible = AccessRight("Update", Metadata.Documents.CashVoucher);
	Items.AdvancesWriteOffOfNonCashFunds.Visible = AccessRight("Update", Metadata.Documents.BankAccountIssue);
	
	CustomizeWithLinkSeeAlso();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		ShouldSaveSettings();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ExpenseReport"
		Or EventName = "Write_VendorInvoice"
		Or EventName = "Write_CashAccountReceiptNote"
		Or EventName = "Write_CashVoucher"
		Or EventName = "Write_BankAccountReceiptNote"
		Or EventName = "Write_BankAccountIssue" Then
		
		Items.ToRegister.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AdvanceHolderOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		ToRegister,
		"AdvanceHolder",
		AdvanceHolder,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(AdvanceHolder));
		
	CustomizeWithLinkSeeAlso();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		ToRegister,
		"Organization",
		Organization,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Organization));
		
	CustomizeWithLinkSeeAlso();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		ToRegister,
		"Department",
		Department,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Department));
		
	CustomizeWithLinkSeeAlso();

EndProcedure

#EndRegion

&AtClient
Procedure SeeAlsoInProgressURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	KeyOperationName = StrTemplate(
		"DataProcessor.JournalOfDocumentsExpenseReports.Form.DocumentsList.SeeAlso.%1", FormattedStringURL);
	PerformanceMonitorClient.StartTimeMeasurement(True, KeyOperationName);
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization", Organization);
	QuickFilterStructure.Insert("AdvanceHolder" ,AdvanceHolder);
	QuickFilterStructure.Insert("Department" ,Department);
	FormParameters.Insert("QuickFilterStructure", QuickFilterStructure);
	FormParameters.Insert("CurrentPageName", "PageOfTheOrderForRegistration");
	
	If FormattedStringURL = "DataProcessor.LogOfPurchaseDocuments.Form.DocumentsList" Then
		FormParameters.Insert("PurposeUseKey", "PurchaseViaAdvanceHolder");
	EndIf;
	
	Form = OpenForm(FormattedStringURL, FormParameters);
	
	If FormattedStringURL = "DataProcessor.LogOfPurchaseDocuments.Form.DocumentsList" Then
		
		If ValueIsFilled(AdvanceHolder) Then
			CommonClientServer.SetDynamicListFilterItem(
				Form.ListPurchaseDocuments,
				"Ref.AdvanceHolder",
				AdvanceHolder,
				DataCompositionComparisonType.Equal,,
				True,
				DataCompositionSettingsItemViewMode.QuickAccess);
		EndIf;
		
		CommonClientServer.SetDynamicListFilterItem(
			Form.ListPurchaseDocuments,
			"Ref.ExpenseReport",,
			DataCompositionComparisonType.NotFilled);
	EndIf;
	
EndProcedure

#Region FormCommandsEventHandlers

&AtClient
Procedure RegisterExpenseReportByInstruction(Command)
	
	RequirementsForRegistration_ = New Array;
	ArrayOfCurrencies = New Array;
	PurchaseDocumentsAll = New Array;
	Cancel = False;
	
	For Each LineToDesign In Items.ToRegister.SelectedRows Do
		
		If TypeOf(LineToDesign) = Type("DynamicListGroupRow") Then
			Continue;
		EndIf;
		
		RowData = Items.ToRegister.RowData(LineToDesign);
		
		If Not ValueIsFilled(RowData.SumBalance)
			And Not ValueIsFilled(RowData.PurchaseAmount) Then
			Continue;
		EndIf;
		
		DesignRequirements = New Structure("AdvanceHolder, Organization, Department, IssuancePurpose, Currency, SumBalance, PurchaseAmount");
		FillPropertyValues(DesignRequirements, RowData);
		RequirementsForRegistration_.Add(DesignRequirements);
		ArrayOfCurrencies.Add(DesignRequirements.Currency);
	EndDo;
	
	If Not RequirementsForRegistration_.Count() Then
		ClearMessages();
		WarningText = NStr("vi = 'Trong các dòng đã chọn không có dữ liệu để lập Giấy thanh toán tạm ứng.';
							|ru = 'В выделенных строках нет данных для формирования Авансового отчета.';
							|en = 'No data for generating Expense report in the selected lines.'; fa = 'No data for generating Expense report in the selected lines.';
							|it = 'Nelle righe selezionate non ci sono dati per la generazione di nota spese.';
							|pl = 'W wybranych wierszach nie ma danych do utworzenia Raportu zaliczkowego.';
							|tr = 'Gider raporu oluşturmak için seçili satırlarda veri yok.'");
		ShowMessageBox(Undefined, WarningText);
		Return;
	EndIf;
	
	ClearMessages();

	IssueAdvanceReportOnOrderOnServer(RequirementsForRegistration_, PurchaseDocumentsAll, ArrayOfCurrencies, Cancel);
	
	If Not Cancel Then
		
		Multicurrency = ArrayOfCurrencies.Count() > 1;
		
		Basis = New Structure;
		Basis.Insert("ToRegister", RequirementsForRegistration_);
		Basis.Insert("Multicurrency", Multicurrency);
		
		ParametersStructure1 = New Structure("Basis, PurchaseDocumentsAll", Basis, PurchaseDocumentsAll);
		OpenForm("Document.ExpenseReport.ObjectForm", ParametersStructure1, ThisForm);
	EndIf;
	
EndProcedure

&AtServer
Procedure IssueAdvanceReportOnOrderOnServer(RequirementsForRegistration_, PurchaseDocumentsAll, ArrayOfCurrencies, Cancel)
	
	If Not DocumentFormationIsPossible(RequirementsForRegistration_) Then
		Cancel = True;
		Return;
	EndIf;
	
	Header = RequirementsForRegistration_[0];
	
	Indus = 0;
	QueryTexts = New Array;
	Query = New Query;
	
	For Each LineToDesign In RequirementsForRegistration_ Do
		
		If LineToDesign.PurchaseAmount = 0 Then
			Continue;
		EndIf;
		
		QueryText = QueryTextPurchaseDocumentsAll();
		QueryText = StrReplace(QueryText, "&IssuancePurpose", "&IssuancePurpose" + Indus);
		QueryText = StrReplace(QueryText, "&Currency", "&Currency" + Indus);
		QueryTexts.Add(?(QueryTexts.Count(), "UNION ALL", "") + " " + QueryText);
		
		Query.SetParameter("IssuancePurpose" + Indus, LineToDesign.IssuancePurpose);
		Query.SetParameter("Currency" + Indus, LineToDesign.Currency);
		
		Indus = Indus + 1;
	EndDo;
	
	If QueryTexts.Count() Then
		Query.Text = StrConcat(QueryTexts);
		Query.SetParameter("Organization", Header.Organization);
		Query.SetParameter("Department", Header.Department);
		Query.SetParameter("AdvanceHolder", Header.AdvanceHolder);
		PurchaseDocumentsAll = TMCommonUse.DeleteDuplicateElementsFromArray(Query.Execute().Unload().UnloadColumn("Ref"));
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DocumentData.Currency AS Currency
	|FROM
	|	Document.VendorInvoice AS DocumentData
	|WHERE
	|	DocumentData.Ref IN (&PurchaseDocumentsAll)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Currency AS Currency
	|FROM
	|	Document.ElectronicTicketTransaction AS DocumentData
	|WHERE
	|	DocumentData.Ref IN (&PurchaseDocumentsAll)
	|
	|";
	
	Query.SetParameter("PurchaseDocumentsAll", PurchaseDocumentsAll);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ArrayOfCurrencies.Add(Selection.Currency);
	EndDo;
	
	TMCommonUse.DeleteDuplicateElementsFromArray(ArrayOfCurrencies);
	
EndProcedure

&AtClient
Procedure CashAccountReceiptNote(Command)
	
	CurrentData = Items.ToRegister.CurrentData;
	
	If CurrentData <> Undefined Then
	
		StructureFilter = New Structure;
		StructureFilter.Insert("BusinessOperation",
			PredefinedValue("Enum.BusinessTransactions.CashReturnByAdvanceHolder"));
		StructureFilter.Insert("AdvanceHolder", CurrentData.AdvanceHolder);
		StructureFilter.Insert("Organization", CurrentData.Organization);
		StructureFilter.Insert("Currency", CurrentData.Currency);
		StructureFilter.Insert("CashFlowItem", CurrentData.IssuancePurpose);
		StructureFilter.Insert("Department", CurrentData.Department);
		StructureFilter.Insert("DocumentAmount", CurrentData.SumBalance);
		StructureFilter.Insert("Sum", CurrentData.SumBalance);
		
		ParametersStructure1 = New Structure("Basis", StructureFilter);
		
		OpenForm("Document.CashAccountReceiptNote.ObjectForm", ParametersStructure1, ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure BankAccountReceiptNote(Command)
	
	CurrentData = Items.ToRegister.CurrentData;
	
	If CurrentData <> Undefined Then
		
		StructureFilter = New Structure;
		StructureFilter.Insert("BusinessOperation",
			PredefinedValue("Enum.BusinessTransactions.CashReturnByAdvanceHolder"));
		StructureFilter.Insert("AdvanceHolder", CurrentData.AdvanceHolder);
		StructureFilter.Insert("Organization", CurrentData.Organization);
		StructureFilter.Insert("Currency", CurrentData.Currency);
		StructureFilter.Insert("CashFlowItem", CurrentData.IssuancePurpose);
		StructureFilter.Insert("Department", CurrentData.Department);
		StructureFilter.Insert("DocumentAmount", CurrentData.SumBalance);
		StructureFilter.Insert("Sum", CurrentData.SumBalance);
		
		ParametersStructure1 = New Structure("Basis", StructureFilter);
		
		OpenForm("Document.BankAccountReceiptNote.ObjectForm", ParametersStructure1, ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure RequestForIssueOfFundsToBeAccountedFor(Command)
	
	CurrentData = Items.ToRegister.CurrentData;
	
	If CurrentData <> Undefined Then
		
		StructureFilter = New Structure;
		StructureFilter.Insert("BusinessOperation",
			PredefinedValue("Enum.BusinessTransactions.IssueCashToAdvanceHolder"));
		StructureFilter.Insert("AdvanceHolder", CurrentData.AdvanceHolder);
		StructureFilter.Insert("Organization", CurrentData.Organization);
		StructureFilter.Insert("Currency", CurrentData.Currency);
		StructureFilter.Insert("CashFlowItem", CurrentData.IssuancePurpose);
		StructureFilter.Insert("Department", CurrentData.Department);
		StructureFilter.Insert("DocumentAmount", CurrentData.overspending);
		StructureFilter.Insert("Sum", CurrentData.overspending);
		StructureFilter.Insert("ExpenseReportDate", CommonClient.SessionDate());
		
		ParametersStructure1 = New Structure("Basis", StructureFilter);
		
		OpenForm("Document.PaymentRequest.ObjectForm", ParametersStructure1, ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure CashVoucher(Command)
	
	CurrentData = Items.ToRegister.CurrentData;
	
	If CurrentData <> Undefined Then
		
		StructureFilter = New Structure;
		StructureFilter.Insert("BusinessOperation",
			PredefinedValue("Enum.BusinessTransactions.IssueCashToAdvanceHolder"));
		StructureFilter.Insert("AdvanceHolder", CurrentData.AdvanceHolder);
		StructureFilter.Insert("Organization", CurrentData.Organization);
		StructureFilter.Insert("Currency", CurrentData.Currency);
		StructureFilter.Insert("CashFlowItem", CurrentData.IssuancePurpose);
		StructureFilter.Insert("Department", CurrentData.Department);
		StructureFilter.Insert("DocumentAmount", CurrentData.overspending);
		StructureFilter.Insert("Sum", CurrentData.overspending);
		StructureFilter.Insert("ExpenseReportDate", CommonClient.SessionDate());
		
		ParametersStructure1 = New Structure("Basis", StructureFilter);
		
		OpenForm("Document.CashVoucher.ObjectForm", ParametersStructure1, ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure BankAccountIssue(Command)
	
	CurrentData = Items.ToRegister.CurrentData;
	
	If CurrentData <> Undefined Then
		
		StructureFilter = New Structure;
		StructureFilter.Insert("BusinessOperation",
			PredefinedValue("Enum.BusinessTransactions.IssueCashToAdvanceHolder"));
		StructureFilter.Insert("AdvanceHolder", CurrentData.AdvanceHolder);
		StructureFilter.Insert("Organization", CurrentData.Organization);
		StructureFilter.Insert("Currency", CurrentData.Currency);
		StructureFilter.Insert("CashFlowItem", CurrentData.IssuancePurpose);
		StructureFilter.Insert("Department", CurrentData.Department);
		StructureFilter.Insert("DocumentAmount", CurrentData.overspending);
		StructureFilter.Insert("Sum", CurrentData.overspending);
		StructureFilter.Insert("ExpenseReportDate", CommonClient.SessionDate());
		
		ParametersStructure1 = New Structure("Basis", StructureFilter);
		
		OpenForm("Document.BankAccountIssue.ObjectForm", ParametersStructure1, ThisForm);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ListOfConditionalAppearance = ToRegister.SettingsComposer.Settings.ConditionalAppearance;
	ListOfConditionalAppearance.Items.Clear();
	
	//
	
	Item = ListOfConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("AmountOverdue");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);
	
EndProcedure

&AtServer
Procedure CustomizeWithLinkSeeAlso()
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("AdvanceHolder", AdvanceHolder);
	GenerationParameters.Insert("Organization", Organization);
	GenerationParameters.Insert("Department", Department);
	GenerationParameters.Insert("ThisIsHyperlinkCalculation", True);
	GenerationParameters.Insert("PurposeUseKey", "ExpenseReport");
	
	ArrayCalculationManagersSeeAlsoInWork = New Array();
	ArrayCalculationManagersSeeAlsoInWork.Add("DataProcessor.JournalOfDocumentsExpenseReports");
	
	SeeAlsoInProgress = TMCommonUse.CreateHyperlinkSeeAlsoIn(ArrayCalculationManagersSeeAlsoInWork, GenerationParameters);
	Items.SeeAlsoInProgress.Visible = ValueIsFilled(SeeAlsoInProgress);
	
EndProcedure

&AtServerNoContext
Function DocumentFormationIsPossible(ArrayOfAdvances)
	
	Result = True;
	
	CompanyArray = New Array;
	ArrayOfAccountablePersons = New Array;
	ArrayOfDivisions = New Array;
	
	For Each Prepayment_ In ArrayOfAdvances Do
		CompanyArray.Add(Prepayment_.Organization);
		ArrayOfAccountablePersons.Add(Prepayment_.AdvanceHolder);
		ArrayOfDivisions.Add(Prepayment_.Department);
	EndDo;
	
	CompanyArray = TMCommonUse.DeleteDuplicateElementsFromArray(CompanyArray);
	ArrayOfAccountablePersons = TMCommonUse.DeleteDuplicateElementsFromArray(ArrayOfAccountablePersons);
	ArrayOfDivisions = TMCommonUse.DeleteDuplicateElementsFromArray(ArrayOfDivisions);
	
	ErrorText = NStr("vi = 'Không thể nhập một chứng từ Giấy thanh toán tạm ứng với nhiều %1.';
					|ru = 'Ввод одного документа Авансовый отчет с несколькими %1 невозможен.';
					|en = 'Cannot enter one Expense report document with multiple %1.'; fa = 'Cannot enter one Expense report document with multiple %1.';
					|it = 'L''immissione di un documento di nota spese con alcuni %1è impossibile.';
					|pl = 'Wprowadzanie jednego dokumentu Raportu zaliczkowego z kilkoma %1 nie jest możliwy.';
					|tr = 'Birden çok %1içeren gider raporu belgesi girilemez'");
	If CompanyArray.Count() > 1 Then
		Result = False;
		ErrorText = StrTemplate(ErrorText, NStr("vi = 'doanh nghiệp';
												|ru = 'организациями';
												|en = 'by companies'; fa = 'by companies';
												|it = 'aziende';
												|pl = 'firmami';
												|tr = 'iş yerlerine'"));
	ElsIf ArrayOfAccountablePersons.Count() > 1 Then
		Result = False;
		ErrorText = StrTemplate(ErrorText, NStr("vi = 'người có trách nhiệm';
												|ru = 'подотчетными лицами';
												|en = 'by advance holders'; fa = 'by advance holders';
												|it = 'responsabili';
												|pl = 'zaliczkobiorcami';
												|tr = 'sorumlu kişilere'"));
	ElsIf ArrayOfDivisions.Count() > 1 Then
		Result = False;
		ErrorText = StrTemplate(ErrorText, NStr("vi = 'bởi bộ phận';
												|ru = 'подразделениями';
												|en = 'by business units'; fa = 'by business units';
												|it = 'reparti';
												|pl = 'działami';
												|tr = 'Departmanlara'"));
	EndIf;
	
	If Not Result Then
		CommonClientServer.MessageToUser(ErrorText);
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function QueryTextPurchaseDocumentsAll()
	
	QueryText = "
	|SELECT
	|	RegisterData.Recorder AS Ref
	|FROM
	|	AccumulationRegister.AdvanceHolderCash AS RegisterData
	|WHERE
	|	RegisterData.Organization = &Organization
	|	AND RegisterData.AdvanceHolder = &AdvanceHolder
	|	AND RegisterData.Department = &Department
	|	AND RegisterData.IssuancePurpose = &IssuancePurpose
	|	AND RegisterData.Currency = &Currency
	|	AND RegisterData.PurchaseAmount <> 0
	|";
	
	Return QueryText;
	
EndFunction

&AtServer
Procedure ShouldSaveSettings()
	
	Settings = New Structure("AdvanceHolder, Organization");
	FillPropertyValues(Settings, ThisForm);
	
	Common.CommonSettingsStorageSave(
		"DataProcessor.JournalOfDocumentsExpenseReports.Form.ExpenseReportsForRegistration", PurposeUseKey, Settings);
	
EndProcedure

&AtServer
Procedure RestoreSettings(Var_Parameters)
	
	If Var_Parameters.Property("QuickFilterStructure") Then
		QuickFilterStructure = Var_Parameters.QuickFilterStructure;
		QuickFilterStructure.Property("Organization", Organization);
		QuickFilterStructure.Property("AdvanceHolder", AdvanceHolder);
		QuickFilterStructure.Property("Department", Department);
	Else
		Settings = Common.CommonSettingsStorageLoad(
			"DataProcessor.JournalOfDocumentsExpenseReports.Form.ExpenseReportsForRegistration", PurposeUseKey);
		If TypeOf(Settings) = Type("Structure") Then
			FillPropertyValues(ThisForm, Settings);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion