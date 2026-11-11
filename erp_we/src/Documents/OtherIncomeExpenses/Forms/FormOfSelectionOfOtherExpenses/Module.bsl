
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	DocumentDate = Parameters.Date;
	If Not ValueIsFilled(DocumentDate) Then
		DocumentDate = CurrentSessionDate();
	EndIf;
	
	Items.ExpensesTableLineOfBusiness.Visible = Catalogs.LinesOfBusiness.AccountingByDirectionsIsUsed();
	CalculationOfPermanentAndTemporaryDifferencesIsKept =
		AccountingPoliciesTaxSettingsLocalization.CalculationOfPermanentAndTemporaryDifferencesIsKept(Parameters.Organization, DocumentDate);
	Items.ExpensesTablePermanentDifference.Visible = CalculationOfPermanentAndTemporaryDifferencesIsKept;
	Items.ExpensesTableCostTD.Visible  = CalculationOfPermanentAndTemporaryDifferencesIsKept;
	AITRecordsAreKept = CalculationOfCostLocalization.RecordsAreKeptAccordingToAIT(DocumentDate, Parameters.Organization);
	Items.ExpensesTableAITAmount.Visible = AITRecordsAreKept;
	
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Parameters.Organization);
	
	KeepManagementRecordsOfOrganizations = True;
	
	Items.ExpensesTableSum.Title =
		StrTemplate(NStr("vi = 'Kế toán quản trị có Thuế GTGT (%1)';
						|ru = 'Упр. учет с НДС (%1)';
						|en = 'Management accounting including VAT (%1)'; fa = 'Management accounting including VAT (%1)';
						|it = 'Contabilità gestionale con IVA (%1)';
						|pl = 'Ewid. administr. z VAT (%1)';
						|tr = 'KDV dahil yönetim muhasebesi (%1)'"), ManagementAccountingCurrency);
	Items.ExpensesTableAmountExcludingVAT.Title =
		StrTemplate(NStr("vi = 'Kế toán quản trị không có Thuế GTGT (%1)';
						|ru = 'Упр. учет без НДС (%1)';
						|en = 'Management accounting excluding VAT (%1)'; fa = 'Management accounting excluding VAT (%1)';
						|it = 'Contabilità gestionale IVA esclusa (%1)';
						|pl = 'Ewid. administr. bez VAT (%1)';
						|tr = 'KDV hariç yönetim muhasebesi (%1)'"), ManagementAccountingCurrency);
	If KeepManagementRecordsOfOrganizations Then
		Items.ExpensesTableSumMan.Title =
			StrTemplate(NStr("vi = 'Kế toán tài chính quốc tế (%1)';
							|ru = 'Международный фин. учет (%1)';
							|en = 'Financial accounting (%1)'; fa = 'Financial accounting (%1)';
							|it = 'Международный фин. учет (%1)';
							|pl = 'Financial accounting (%1)';
							|tr = 'Uluslararası fin. muhasebe (%1)'"), ManagementAccountingCurrency);
	EndIf;
	Items.ExpensesTableSumCompl.Title =
		StrTemplate(NStr("vi = 'Kế toán (%1):';
						|ru = 'Бухгалтерский учет (%1):';
						|en = 'Local accounting (%1):'; fa = 'Local accounting (%1):';
						|it = 'Contabilità (%1):';
						|pl = 'Ewidencja księgowa (%1):';
						|tr = 'Genel muhasebe (%1):'"), LocalAccountingCurrency);
	Items.ExpensesTableAmountFA.Title =
		StrTemplate(NStr("vi = 'Kế toán thuế (%1):';
						|ru = 'Налоговый учет (%1):';
						|en = 'Tax accounting (%1):'; fa = 'Tax accounting (%1):';
						|it = 'Contabilità fiscale (%1):';
						|pl = 'Ewidencja podatkowa (%1):';
						|tr = 'Vergi muhasebesi (%1):'"), LocalAccountingCurrency);
	Items.ExpensesTablePermanentDifference.Title =
		StrTemplate(NStr("vi = 'Chênh lệch vĩnh viễn (%1):';
						|ru = 'Постоянная разница (%1):';
						|en = 'Permanent difference (%1):'; fa = 'Permanent difference (%1):';
						|it = 'Differenza costante (%1):';
						|pl = 'Stała różnica (%1):';
						|tr = 'Kalıcı fark (%1):'"), LocalAccountingCurrency);
	Items.ExpensesTableCostTD.Title =
		StrTemplate(NStr("vi = 'Chênh lệch tạm thời (%1):';
						|ru = 'Временная разница (%1):';
						|en = 'Temporary difference (%1):'; fa = 'Temporary difference (%1):';
						|it = 'Differenza temporanea (%1):';
						|pl = 'Tymczasowa różnica (%1):';
						|tr = 'Geçici fark (%1):'"), LocalAccountingCurrency);
	Items.ExpensesTableAITAmount.Title =
		StrTemplate(NStr("vi = 'Thuế thu nhập bổ sung (%1):';
						|ru = 'НДД (%1):';
						|en = 'AIT (%1):'; fa = 'AIT (%1):';
						|it = 'НДД (%1):';
						|pl = 'AIT (%1):';
						|tr = 'EGV (%1):'"), LocalAccountingCurrency);
	
	FillInExpenseTable();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not Exit
		And Modified
		And ExpensesTable.FindRows(New Structure("RowIsSelected", True)).Count() > 0 Then
		
		Mode = New ValueList;
		Mode.Add(DialogReturnCode.Yes,     NStr("vi = 'Thêm';
												|ru = 'Добавить';
												|en = 'Add'; fa = 'افزودن';
												|it = 'Aggiungere';
												|pl = 'Dodaj';
												|tr = 'Ekle'"));
		Mode.Add(DialogReturnCode.No,    NStr("vi = 'Chưa thêm';
												|ru = 'Не добавлять';
												|en = 'Do not add'; fa = 'افزوده نشود';
												|it = 'Non aggiungere';
												|pl = 'Nie dodawaj';
												|tr = 'Eklemeyin'"));
		Mode.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
												|ru = 'Отмена';
												|en = 'Cancel'; fa = 'انصراف';
												|it = 'Annulla';
												|pl = 'Cancel';
												|tr = 'İptal'"));
		
		Notification = New CallbackDescription("ConfirmationOfClosing", ThisForm);
		ShowQueryBox(Notification, NStr("vi = 'Đã chọn nhiều dòng. Thêm các dòng vào chứng từ?';
										|ru = 'Некоторые строки были выбраны. Добавить их в документ?';
										|en = 'You have selected several lines. Add them to the document?'; fa = 'You have selected several lines. Add them to the document?';
										|it = 'Alcune righe sono state selezionate. Aggiungerle al documento?';
										|pl = 'Wybrano niektóre wiersze. Czy dodać je do dokumentu?';
										|tr = 'Bazı satırlar seçildi. Belgeye eklensinler mi?'"), Mode);
		
		Cancel = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfirmationOfClosing(Response, Var_Parameters) Export
	
	If Response = DialogReturnCode.Yes Then
		
		TransferExpensesToDocument();
		
	ElsIf Response = DialogReturnCode.No Then
		
		Modified = False;
		Close();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	FilterItems1 = New Array;
	FilterItems1.Add("FilterExpenseItem");
	FilterItems1.Add("FilterDepartment");
	
	For Each FilterElement In FilterItems1 Do
		If Items[FilterElement].ChoiceList.FindByValue(ThisForm[FilterElement]) = Undefined Then
			ThisForm[FilterElement] = Items[FilterElement].ChoiceList[0].Value; // empty value
		EndIf;
	EndDo;
	
	UpdateSelection_(ThisForm);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ExpensesTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	Var DataName;
	
	curData = Items.ExpensesTable.CurrentData;
	
	ForOpening = New Structure;
	ForOpening.Insert("ExpensesTableDepartment",		"Department");
	ForOpening.Insert("ExpensesTableLineOfBusiness", "LineOfBusiness");
	ForOpening.Insert("ExpensesTableExpenseItem",	"ExpenseItem");
	ForOpening.Insert("ExpensesTableDimensionOfExpenses",	"DimensionOfExpenses");
	
	If curData <> Undefined And ForOpening.Property(Field.Name, DataName) Then
		ShowValue(Undefined, curData[DataName]);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocumentExecute()
	
	TransferExpensesToDocument();
	
EndProcedure

&AtClient
Procedure SelectExpensesExecute()
	
	SelectAllExpensesOnServer();
	
EndProcedure

&AtClient
Procedure ClearExpensesExecute()
	
	SelectAllExpensesOnServer(False);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExpensesTableDepartment.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FilterDepartment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExpensesTableExpenseItem.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FilterExpenseItem");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExpensesTableDimensionOfExpenses.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FilterDimensionOfExpenses");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

&AtServer
Procedure SelectAllExpensesOnServer(SelectionValue = True)
	
	FilterStructure1 = New Structure("RowIsSelected", Not SelectionValue);
	
	If ValueIsFilled(FilterDepartment)
		And SelectionValue Then
		FilterStructure1.Insert("Department", FilterDepartment);
	EndIf;
	
	If ValueIsFilled(FilterExpenseItem)
		And SelectionValue Then
		FilterStructure1.Insert("ExpenseItem", FilterExpenseItem);
	EndIf;
	
	If ValueIsFilled(FilterDimensionOfExpenses)
		And SelectionValue Then
		FilterStructure1.Insert("DimensionOfExpenses", FilterDimensionOfExpenses);
	EndIf;
	
	For Each TableRow In ExpensesTable.FindRows(FilterStructure1) Do
		TableRow.RowIsSelected = SelectionValue;
	EndDo;
	
EndProcedure

&AtServer
Function PutExpensesInStorage(Var_UUID)
	
	SelectionResult = ExpensesTable.Unload(New Structure("RowIsSelected", True));
	Return PutToTempStorage(SelectionResult, Var_UUID);
	
EndFunction

&AtServer
Procedure FillInExpenseTable()

	SelectionData_ = New Structure();
	SelectionData_.Insert("Organization",	Parameters.Organization);
	SelectionData_.Insert("Ref",			Parameters.Ref);
	SelectionData_.Insert("Date",			DocumentDate);
	
	Documents.OtherIncomeExpenses.GetBalancesOfOtherExpenses(
		SelectionData_,
		ExpensesTable);
	
	// Fill in the selection lists for the selection elements
	Columns = "Department, LineOfBusiness, ExpenseItem, DimensionOfExpenses";
	VT = ExpensesTable.Unload(, Columns);
	
	EmptyArticle = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
	EmptySUBR = Catalogs.BusinessStructure.EmptyRef();
	EmptyOption = Enums.CostAllocationOptions.EmptyRef();
	
	FillInItemSelectionParameters(VT, "DimensionOfExpenses");
	
	FillItemSelectionList(VT, "ExpenseItem", EmptyArticle, NStr("vi = '<theo tất cả các dạng>';
																|ru = '<по всем статьям>';
																|en = '<by all items>'; fa = '<by all items>';
																|it = '<per tutte le voci>';
																|pl = '<dla wszystkich pozycji>';
																|tr = '<tüm öğeler genelinde>'"));
	FillItemSelectionList(VT, "Department", EmptySUBR, NStr("vi = '<theo tất cả bộ phận>';
															|ru = '<по всем подразделениям>';
															|en = '<by all business units>'; fa = '<by all business units>';
															|it = '<per tutti i reparti>';
															|pl = '<dla wszystkich działów>';
															|tr = '<tüm departmanlar genelinde>'"));
	
EndProcedure

&AtServer
Function FillInItemSelectionParameters(VT, ColumnName)
	
	List = TMCommonUse.DeleteDuplicateElementsFromArray(VT.UnloadColumn(ColumnName));
	
	ChoiceParameters = New Array;
	ChoiceParameters.Add(New ChoiceParameter("Filter.Ref", New FixedArray(List)));
	
	Items[NameOfFormElement(ColumnName)].ChoiceParameters = New FixedArray(ChoiceParameters);
	
EndFunction

&AtServer
Function FillItemSelectionList(VT, ColumnName, EmptyValue, DescriptionOfEmptyValue)
	
	List = TMCommonUse.DeleteDuplicateElementsFromArray(VT.UnloadColumn(ColumnName));
	
	Items[NameOfFormElement(ColumnName)].ChoiceList.LoadValues(List);
	Items[NameOfFormElement(ColumnName)].ChoiceList.Insert(0, EmptyValue, DescriptionOfEmptyValue);
	
EndFunction

&AtServer
Function NameOfFormElement(ColumnName)
	
	ElementName = "";
	
	If ColumnName = "DimensionOfExpenses" Then
		ElementName = "FilterDimensionOfExpenses";
	ElsIf ColumnName = "ExpenseItem" Then
		ElementName = "FilterExpenseItem";
	ElsIf ColumnName = "Department" Then
		ElementName = "FilterDepartment";
	EndIf;
	
	Return ElementName;
	
EndFunction

&AtClient
Procedure TransferExpensesToDocument()
	
	Modified = False;
	AddressInTempStorage = PutExpensesInStorage(ThisForm.FormOwner.UUID);
	Close(AddressInTempStorage);
	
EndProcedure

&AtClient
Procedure FilterDepartmentOnChange(Item)
	
	UpdateSelection_(ThisForm);
	
EndProcedure

&AtClient
Procedure FilterExpenseItemOnChange(Item)
	
	UpdateSelection_(ThisForm);
	
EndProcedure

&AtClient
Procedure FilterDimensionOfExpensesOnChange(Item)
	
	UpdateSelection_(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateSelection_(Form)
	
	FilterItems1 = New Structure();
	FilterItems1.Insert("FilterExpenseItem", "ExpenseItem");
	FilterItems1.Insert("FilterDimensionOfExpenses", "DimensionOfExpenses");
	FilterItems1.Insert("FilterDepartment", "Department");
			
	Filter = New Structure;
	For Each FilterElement In FilterItems1 Do
		If ValueIsFilled(Form[FilterElement.Key]) Then
			Filter.Insert(FilterElement.Value, Form[FilterElement.Key]);
		EndIf;
	EndDo;
	
	Form.Items.ExpensesTable.RowFilter = New FixedStructure(Filter);
	
EndProcedure

#EndRegion
