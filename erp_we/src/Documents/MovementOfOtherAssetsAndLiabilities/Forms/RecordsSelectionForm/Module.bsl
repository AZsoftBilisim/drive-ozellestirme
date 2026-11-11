
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
	
	TableSide = Parameters.TableSide;
	DocumentCurrency = Parameters.Currency;
	SetItemsVisibility();
	FillInExpenseTable();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not Exit
		And Modified
		And ExpensesTable.FindRows(New Structure("RowIsSelected", True)).Count() > 0 Then
		Notification = New CallbackDescription("BeforeCloseCompletion", ThisForm);
		CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit, NStr("vi = 'Đã chọn nhiều dòng. Thêm các dòng vào chứng từ?';
																					|ru = 'Некоторые строки были выбраны. Добавить их в документ?';
																					|en = 'You have selected several lines. Add them to the document?'; fa = 'You have selected several lines. Add them to the document?';
																					|it = 'Alcune righe sono state selezionate. Aggiungerle al documento?';
																					|pl = 'Wybrano niektóre wiersze. Czy dodać je do dokumentu?';
																					|tr = 'Bazı satırlar seçildi. Belgeye eklensinler mi?'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfirmationOfClosing(Response, Var_Parameters) Export
	
	If Response = DialogReturnCode.Yes Then
		
		TransferExpensesToDocument();
		
	ElsIf Not Response = DialogReturnCode.Cancel Then
		
		Modified = False;
		Close();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	FilterItems1 = New Array;
	FilterItems1.Add("FilterAssetRef");
	FilterItems1.Add("FilterDepartment");
	FilterItems1.Add("FilterAllocationOption");
	
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

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.ExpensesTable);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.ExpensesTable, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.ExpensesTable);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtServer
Procedure SetItemsVisibility()
	
	AssetBalanceSheetName  = ?(Parameters.ArticleType = Enums.TypesOfAssetAndLiabilityItems.AssetItem,  True, False);
	Liabilities = ?(Parameters.ArticleType = Enums.TypesOfAssetAndLiabilityItems.LiabilityItem, True, False);
	Income_2  = ?(Parameters.ArticleType = Enums.TypesOfAssetAndLiabilityItems.IncomeItem,  True, False);
	Expense = ?(Parameters.ArticleType = Enums.TypesOfAssetAndLiabilityItems.ExpenseItem, True, False);
	
	Items.FilterAssetsLiabilitiesDimension.Visible = AssetBalanceSheetName Or Liabilities;
	Items.ExpensesTableAssetsLiabilitiesDimension.Visible = AssetBalanceSheetName Or Liabilities;
	
	Items.FilterDimensionOfRevenue.Visible = Income_2;
	Items.ExpensesTableDimensionOfRevenue.Visible = Income_2;
	
	Items.FilterDimensionOfExpenses.Visible = Expense;
	Items.ExpensesTableDimensionOfExpenses.Visible = Expense;
	
	Items.FilterAllocationOption.Visible = Expense;
	Items.ExpensesTableAllocationOption.Visible = Expense;
	
	Items.ExpensesTableDepartment.Visible = Income_2 Or Expense;
	Items.FilterDepartment.Visible = Income_2 Or Expense;
	
	RestrictionType = ?(AssetBalanceSheetName Or Liabilities, "AssetLiabilityItems", ?(Expense, "ExpenseItems", "IncomeItems"));
	Items.FilterAssetRef.TypeRestriction = New TypeDescription("ChartOfCharacteristicTypesRef." + RestrictionType);
	
	If AssetBalanceSheetName Or Liabilities Then
		
		TypeAssetLiability = Enums.KindsOfBalanceSheetStatementItems[?(AssetBalanceSheetName, "AssetBalanceSheetName", "Liabilities")];
		ChoiceParameters = New Array(1);
		ChoiceParameters[0] = New ChoiceParameter("Filter.AssetLiability", TypeAssetLiability);
		Items.FilterAssetRef.ChoiceParameters = New FixedArray(ChoiceParameters);
		
	EndIf;
	
	Title = ?(AssetBalanceSheetName, NStr("vi = 'tài sản';
											|ru = 'активов';
											|en = 'assets'; fa = 'assets';
											|it = 'attivi';
											|pl = 'aktywów';
											|tr = 'varlıkların'"), ?(Liabilities, NStr("vi = 'nguồn vốn';
																				|ru = 'пассивов';
																				|en = 'liabilities'; fa = 'liabilities';
																				|it = 'passivi';
																				|pl = 'zobowiązań';
																				|tr = 'yükümlülüklerin'"), ?(Income_2, NStr("vi = 'thu nhập';
																														|ru = 'доходов';
																														|en = 'income'; fa = 'income';
																														|it = 'dei ricavi';
																														|pl = 'dochodów';
																														|tr = 'gelirlerin'"), NStr("vi = 'chi phí';
																																				|ru = 'расходов';
																																				|en = 'expenses'; fa = 'expenses';
																																				|it = 'dei costi';
																																				|pl = 'rozchodów';
																																				|tr = 'giderlerin'"))));
	Title = SelectGoodsClientServer.CreateSelectionFormHeader(
		NStr("vi = 'Chọn';
			|ru = 'Подбор';
			|en = 'Pick'; fa = 'انتخاب';
			|it = 'Selezione';
			|pl = 'Selekcja';
			|tr = 'Seçim'") + " " + Title,
		Parameters.DocumentRef);
	
EndProcedure

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
	ItemField.Field = New DataCompositionField(Items.ExpensesTableAssetRef.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FilterAssetRef");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExpensesTableAllocationOption.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FilterAllocationOption");
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
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExpensesTableDimensionOfRevenue.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FilterDimensionOfRevenue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExpensesTableAssetsLiabilitiesDimension.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FilterAssetsLiabilitiesDimension");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

&AtServer
Procedure SelectAllExpensesOnServer(SelectionValue = True)
	
	FilterStructure1 = New Structure("RowIsSelected", Not SelectionValue);
	
	For Each TableRow In ExpensesTable.FindRows(FilterStructure1) Do
		TableRow.RowIsSelected = SelectionValue;
	EndDo;
	
EndProcedure

&AtServer
Function PutExpensesInStorage()
	
	FilterStructure1 = New Structure("RowIsSelected", True);
	BalanceTable = ExpensesTable.Unload(FilterStructure1);
	
	For Each Column In BalanceTable.Columns Do
		If Not Lower(Column.Name) = "sum" Then
			Column.Name = Column.Name + TableSide;
		EndIf;
	EndDo;
	
	Return PutToTempStorage(BalanceTable);
	
EndFunction

&AtServer
Procedure FillInExpenseTable()

	SelectionData_ = New Structure();
	SelectionData_.Insert("Organization",	Parameters.Organization);
	SelectionData_.Insert("Ref",			Parameters.DocumentRef);
	SelectionData_.Insert("Currency",			DocumentCurrency);
	SelectionData_.Insert("Date",			DocumentDate);
	SelectionData_.Insert("ArticleType",		Parameters.ArticleType);
	
	Documents.MovementOfOtherAssetsAndLiabilities.FillInBalancesInRegister(
		SelectionData_,
		ExpensesTable);
	
	// Fill in the selection lists for the selection elements
	Columns = "AllocationOption, Department, AssetRef, DimensionOfExpenses, DimensionOfRevenue, AssetsLiabilitiesDimension";
	VT = ExpensesTable.Unload(, Columns);
	
	EmptyArticle = Items.FilterAssetRef.TypeRestriction.AdjustValue();
	EmptySUBR = Catalogs.BusinessStructure.EmptyRef();
	EmptyOption = Enums.CostAllocationOptions.EmptyRef();
	
	FillInItemSelectionParameters(VT, "DimensionOfRevenue",         "FilterDimensionOfRevenue");
	FillInItemSelectionParameters(VT, "AssetsLiabilitiesDimension", "FilterAssetsLiabilitiesDimension");
	FillInItemSelectionParameters(VT, "DimensionOfExpenses",        "FilterDimensionOfExpenses");
	
	FillItemSelectionList(VT, "AssetRef", EmptyArticle, NStr("vi = 'theo tất cả dạng';
															|ru = 'по всем статьям';
															|en = 'by all items'; fa = 'by all items';
															|it = 'per tutte le voci';
															|pl = 'według wszystkich pozycji';
															|tr = 'tüm kalemlere göre'"), "FilterAssetRef");
	FillItemSelectionList(VT, "Department", EmptySUBR, NStr("vi = 'theo tất cả bộ phận';
															|ru = 'по всем подразделениям';
															|en = 'by all business units'; fa = 'by all business units';
															|it = 'per tutti i reparti';
															|pl = 'według wszystkich działów';
															|tr = 'tüm departmanlara göre'"), "FilterDepartment");
	FillItemSelectionList(VT, "AllocationOption", EmptyOption, NStr("vi = 'theo tất cả phương án';
																	|ru = 'по всем вариантам';
																	|en = 'by all options'; fa = 'by all options';
																	|it = 'per tutte le varianti';
																	|pl = 'według wszystkich wariantów';
																	|tr = 'tüm seçeneklere göre'"), "FilterAllocationOption");
	
EndProcedure

&AtServer
Function FillInItemSelectionParameters(VT, ColumnName, FilterElementName)
	
	List = TMCommonUse.DeleteDuplicateElementsFromArray(VT.UnloadColumn(ColumnName));
	
	ChoiceParameters = New Array;
	ChoiceParameters.Add(New ChoiceParameter("Filter.Ref", New FixedArray(List)));
	
	Items[FilterElementName].ChoiceParameters = New FixedArray(ChoiceParameters);
	
EndFunction

&AtServer
Function FillItemSelectionList(VT, ColumnName, EmptyValue, DescriptionOfEmptyValue, FilterElementName)
	
	List = TMCommonUse.DeleteDuplicateElementsFromArray(VT.UnloadColumn(ColumnName));
	
	Items[FilterElementName].ChoiceList.LoadValues(List);
	Items[FilterElementName].ChoiceList.Insert(0, EmptyValue, DescriptionOfEmptyValue);
	
EndFunction

&AtClient
Procedure TransferExpensesToDocument()
	
	// Removal of modification, because before closing, the attribute is checked.
	Modified = False;
	Close();
	NotifyChoice(New Structure("AddressOfBalancesInStorage", PutExpensesInStorage()));
	
EndProcedure

&AtClient
Procedure FilterDepartmentOnChange(Item)
	
	UpdateSelection_(ThisForm);
	
EndProcedure

&AtClient
Procedure FilterFilterAllocationOptionOnChange(Item)
	
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
	
	FilterItems1 = New Array;
	FilterFields = New Map;
	
	FilterItems1.Add("FilterAssetRef");
	FilterFields.Insert(FilterItems1[FilterItems1.UBound()], "AssetRef");
	
	FilterItems1.Add("FilterDimensionOfExpenses");
	FilterFields.Insert(FilterItems1[FilterItems1.UBound()], "DimensionOfExpenses");
	
	FilterItems1.Add("FilterDimensionOfRevenue");
	FilterFields.Insert(FilterItems1[FilterItems1.UBound()], "DimensionOfRevenue");
	
	FilterItems1.Add("FilterAssetsLiabilitiesDimension");
	FilterFields.Insert(FilterItems1[FilterItems1.UBound()], "AssetsLiabilitiesDimension");
	
	If Form.Expense Or Form.Income_2 Then
		FilterItems1.Add("FilterDepartment");
		FilterFields.Insert(FilterItems1[FilterItems1.UBound()], "Department");
	EndIf;
	If Form.Expense Then
		FilterItems1.Add("FilterAllocationOption");
		FilterFields.Insert(FilterItems1[FilterItems1.UBound()], "AllocationOption");
	EndIf;
	
	
	Filter = New Structure;
	For Each FilterElement In FilterItems1 Do
		If ValueIsFilled(Form[FilterElement]) Then
			Filter.Insert(FilterFields[FilterElement], Form[FilterElement]);
		ElsIf StrFind(Lower(FilterElement), "dimension") = 0 Then
			// for the cleared element, set an empty value from the selection list
			Form[FilterElement] = Form.Items[FilterElement].ChoiceList[0].Value;
		EndIf;
	EndDo;
	
	Form.Items.ExpensesTable.RowFilter = New FixedStructure(Filter);
	
EndProcedure

#EndRegion
