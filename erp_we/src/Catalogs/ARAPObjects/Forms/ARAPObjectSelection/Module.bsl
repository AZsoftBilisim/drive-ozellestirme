
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not AccessRight("Read", Metadata.Catalogs.CounterpartyContracts)
		Or Not AccessRight("Read", Metadata.Catalogs.IntercompanyContracts)
		Or Not AccessRight("Read", Metadata.Catalogs.Partners)
		Or Not AccessRight("Read", Metadata.Catalogs.Counterparties)
		Or Not AccessRight("Read", Metadata.Catalogs.LinesOfBusiness) Then
		Text = NStr("vi = 'Không đủ quyền để mở biểu mẫu chọn đối tượng hạch toán.';
					|ru = 'Недостаточно прав для открытия формы подбора объекта расчетов.';
					|en = 'Insufficient rights to open the pick form of an AR/AP object.'; fa = 'Insufficient rights to open the pick form of an AR/AP object.';
					|it = 'Недостаточно прав для открытия формы подбора объекта расчетов.';
					|pl = 'Insufficient rights to open the pick form of an AR/AP object.';
					|tr = 'Alacak/Borç nesnesi seçimi formunu açmak için yetki eksik.'");
		Common.MessageToUser(Text,,,,Cancel);
		Return;
	EndIf;
	
	SetConditionalAppearance();
	
	ObjectRef         = Parameters.ObjectRef;
	PaymentType_          = Parameters.PaymentType_;
	ARAPCurrency = Parameters.ARAPCurrency;
	Organization          = Parameters.Organization;
	Partner              = Parameters.Partner;
	If ValueIsFilled(Partner) Then
		Items.Partner.Enabled = False;
	EndIf;
	Counterparty           = Parameters.Counterparty;
	If ValueIsFilled(Counterparty) Then
		Items.Counterparty.Enabled = False;
	EndIf;
	PaymentID = Parameters.PaymentID;
	
	DocumentAmount = Parameters.DocumentAmount;
	DocumentCurrency = Parameters.DocumentCurrency;
	
	DocumentDate  = Parameters.DocumentDate;
	OneARAPCurrency = ?(Parameters.Property("OneARAPCurrency"),Parameters.OneARAPCurrency,False);
	
	AddressOfPaymentsInTheStorage = Parameters.AddressOfPaymentsInTheStorage;
	PartnerOtherRelations = Parameters.PartnerOtherRelations;
	SelectAccountsReceivable = Parameters.SelectAccountsReceivable;
	SelectOnlyUnconditionalDebt = Parameters.SelectOnlyUnconditionalDebt;
	RecordBranches = Parameters.RecordBranches;
	FillInVATInDecryption = Parameters.FillInVATInDecryption;
	SelectionOfPaymentByRequest = Parameters.SelectionOfPaymentByRequest;
	
	If Counterparty = Undefined Then
		Counterparty = Catalogs.Counterparties.EmptyRef();
	EndIf;
	
	// Additional selections are a match, so a list of values is used to cache selections in the form details
	If Parameters.AdditionalFilters <> Undefined Then
		For Each KeyAndValue In Parameters.AdditionalFilters Do
			ParameterAdditionalSelections.Add(KeyAndValue.Value, KeyAndValue.Key);
		EndDo;
	EndIf;
	ParameterAdditionalSelections.Add(False, "DeletionMark");
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If DocumentAmount = 0 Then 
		SelectByAmount = False;
	EndIf;
	
	SetRowSelection();
	WhenOpenedOnServer();
	MatchByAmountCalculate();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PartnerOnChange(Item)
	
	FillInTableForSettlementsWithPartners();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	FillInTableForSettlementsWithPartners();
	
EndProcedure

&AtClient
Procedure PaymentBalanceTableOnEditEnd(Item, NewRow, CancelEdit)
	
	If Item.CurrentItem = Undefined 
		Or Item.CurrentItem.Name <> Items.PaymentBalanceTableSelected.Name Then
		ModifiedRows = CommonClientServer.ValueInArray(Item.CurrentData.GetID());
		SetRemoveRowSelection(ModifiedRows, Item.CurrentData.Selected, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure PaymentBalanceTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "PaymentBalanceTableARAPObject" Then
		TableRow = Items.PaymentBalanceTable.CurrentData;
		If TableRow <> Undefined And ValueIsFilled(TableRow.ARAPObject) Then
			ShowValue(Undefined, TableRow.ARAPObject);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure PaymentBalanceTableSelectedOnChange(Item)
	
	CurrentData = Items.PaymentBalanceTable.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	ModifiedRows = CommonClientServer.ValueInArray(CurrentData.GetID());
	SetRemoveRowSelection(ModifiedRows, CurrentData.Selected);
	
EndProcedure

&AtClient
Procedure SelectByAmountOnChange(Item)
	MatchByAmountCalculate();
EndProcedure

&AtClient
Procedure ByPaymentDatesOnChange(Item)
	Items.PaymentBalanceTablePaymentDate.Visible = ByPaymentDates;
	FillInTableForSettlementsWithPartners();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocumentExecute()

	If OneARAPCurrency Then
		ClearMessages();
		RowsSelected = PaymentBalanceTable.FindRows(New Structure("Selected", True));
		Currency = Undefined;
		For Each String In RowsSelected Do
			If Currency = Undefined Then
				Currency = String.ARAPCurrency;
			EndIf;
			If Currency <> String.ARAPCurrency Then
				CommonClient.MessageToUser(NStr("vi = 'Trong chứng từ hiện tại chỉ cho phép chọn theo một tiền tệ hạch toán công nợ.';
												|ru = 'В текущем документе разрешен подбор только в одной валюте взаиморасчетов.';
												|en = 'You can select only one AR/AP currency in the current document.'; fa = 'You can select only one AR/AP currency in the current document.';
												|it = 'В текущем документе разрешен подбор только в одной валюте взаиморасчетов.';
												|pl = 'You can select only one AR/AP currency in the current document.';
												|tr = 'Mevcut belgede, alacak/borç muhasebesinin sadece tek para biriminde seçimine izin verilmektedir.'"));
				Return;
			EndIf;
		EndDo;
	EndIf;
	
	PlacePaymentsInStorage();
	Structure = New Structure("AddressOfPaymentsInTheStorage", AddressOfPaymentsInTheStorage);
	Structure.Insert("BusinessOperation", ?(SelectAccountsReceivable, 
		PredefinedValue("Enum.BusinessTransactions.ARWriteOff"),
		PredefinedValue("Enum.BusinessTransactions.APWriteOff")));
	Close(Structure);
	
	NotifyChoice(Structure);
	
EndProcedure

&AtClient
Procedure SelectPaymentsExecute()
	
	AmountOfSelection = DocumentAmount;
	For Each TableRow In PaymentBalanceTable Do
		If Items.PaymentBalanceTable.CheckRow(TableRow.GetID()) 
			And GetFullAmountOfLine(TableRow) > 0 Then
			TableRow.Selected = True;
			TableRow.Sum = GetFullAmountOfLine(TableRow);
			AmountOfSelection = AmountOfSelection - TableRow.Sum;
		EndIf;
		If SelectByAmount
			And AmountOfSelection <= 0 Then
			TableRow.Selected = False;
		EndIf;
	EndDo;
	CalculateAmountOfPayments();
	SetRowSelection();
	
EndProcedure

&AtClient
Procedure ExcludePaymentsExecute()

	For Each TableRow In PaymentBalanceTable Do
		TableRow.Selected = False
	EndDo;
	CalculateAmountOfPayments();
	SetRowSelection();
	
EndProcedure

&AtClient
Procedure SelectSelectedPayments(Command)
	
	RowsArray = Items.PaymentBalanceTable.SelectedRows;
	SetRemoveRowSelection(RowsArray, True);
	
EndProcedure

&AtClient
Procedure ExcludeSelectedPayments(Command)
	
	RowsArray = Items.PaymentBalanceTable.SelectedRows;
	SetRemoveRowSelection(RowsArray, False);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentBalanceTable.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentBalanceTable.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentBalanceTable.EntireAmountIsPaid");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", WebColors.RosyBrown);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentBalanceTablePaymentID.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentBalanceTable.PaymentID");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = TrimAll(PaymentID);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentBalanceTable.PaymentID");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Seagreen);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentBalanceTable.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentBalanceTable.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentBalanceTable.BeingPaid");
	ItemFilter.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	ItemFilter.RightValue = New DataCompositionField("PaymentBalanceTable.AmountDue");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentBalanceTable.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentBalanceTable.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentBalanceTable.BeingPaid");
	ItemFilter.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	ItemFilter.RightValue = New DataCompositionField("PaymentBalanceTable.AmountDue");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentBalanceTableSum.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentBalanceTable.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

#Region FormItemsManagement

&AtServer
Procedure SetVisibility1()
	
	ItemArray = New Array;
	
	If PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then
		If SelectAccountsReceivable Then
			ItemArray.Add("PaymentBalanceTableAccountsPayableOfCompany");
			ItemArray.Add("TableOfSettlementBalancesSettlementCurrencyOurDebt");
		Else
			ItemArray.Add("PaymentBalanceTablePartnerDebt_");
			ItemArray.Add("PaymentBalanceTableAmountDue");
			ItemArray.Add("TableOfSettlementBalancesCurrencyOfMutualSettlementsPartnerSDebt");
			ItemArray.Add("PaymentBalanceTableARAPCurrency");
		EndIf;
	ElsIf PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting Then
		If Not SelectAccountsReceivable Then
			ItemArray.Add("PaymentBalanceTablePartnerDebt_");
			ItemArray.Add("TableOfSettlementBalancesCurrencyOfMutualSettlementsPartnerSDebt");
		Else
			ItemArray.Add("PaymentBalanceTableAccountsPayableOfCompany");
			ItemArray.Add("PaymentBalanceTableAmountDue");
			ItemArray.Add("TableOfSettlementBalancesSettlementCurrencyOurDebt");
			ItemArray.Add("PaymentBalanceTableARAPCurrency");
		EndIf;
	EndIf;
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items, ItemArray, "Visible", False);

	
	If TypeOf(Counterparty) = Type("CatalogRef.Companies") Then
		Title = NStr("vi = 'Chọn theo công nợ giữa các doanh nghiệp';
					|ru = 'Подбор по расчетам между организациями';
					|en = 'Pick by intercompany AR/AP open items'; fa = 'Pick by intercompany AR/AP open items';
					|it = 'Selezione per pagamenti tra aziende';
					|pl = 'Wybór wg rozliczeń pomiędzy firmami';
					|tr = 'İş yerleri arasında hesaplaşma seçimi'");
		AutoTitle = False;
	EndIf;
	
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
		ThisObject, "PaymentBalanceTablePartnerDebt_", NStr("vi = 'Công nợ đối tác';
															|ru = 'Долг контрагента';
															|en = 'Counterparty debt'; fa = 'بدهی طرف حساب';
															|it = 'Debito di contraente';
															|pl = 'Zobowiązanie kontrahenta';
															|tr = 'Cari hesap borcu'"));
	
	ThereAreBranches = Catalogs.Companies.BranchesWithPaymentsThroughParentOrganization(Organization).Count() > 0;
	Items.PaymentBalanceTableOrganization.Visible = ThereAreBranches;
	
	If DocumentAmount = 0 Then
		Items.DocumentAmount.Visible = False;
	EndIf; 
	
	Items.PaymentBalanceTablePaymentDate.Visible = ByPaymentDates;
	
	If DocumentAmount = 0 Then 
		Items.SelectByAmount.Visible = False;
	Else
		PresentationLies = NStr("vi = 'không hạn chế';
								|ru = 'без ограничения';
								|en = 'without restrictions'; fa = 'بدون محدودیت';
								|it = 'senza restrizioni';
								|pl = 'bez ograniczenia';
								|tr = 'kısıtlamasız'");
		PresentationTruth = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'với số tiền %1 %2';
																							|ru = 'на сумму %1 %2';
																							|en = 'in the amount of %1 %2'; fa = 'in the amount of %1 %2';
																							|it = 'importo %1 %2';
																							|pl = 'na kwotę %1 %2';
																							|tr = '%1 %2 tutarında'"), DocumentAmount, DocumentCurrency);
		
		Items.SelectByAmount.EditFormat = "BF='"+PresentationLies+"'; BT='"+PresentationTruth+"'";
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure PlacePaymentsInStorage()
	
	Payments_2 = PaymentBalanceTable.Unload(, "Selected, Sum, ARAPObject, ARAPCurrency, Partner, Counterparty, Contract, Organization, PartnerDebt_, AccountsPayableOfCompany, PaymentType_, CashFlowItem, MaturityDate");
	
	Cnt = 0;
	While Cnt < Payments_2.Count() Do
		If Not Payments_2[Cnt].Selected Then
			Payments_2.Delete(Cnt);
		Else 
			Cnt = Cnt + 1;
		EndIf;
	EndDo;
	
	If Payments_2.Total("Sum") < DocumentAmount And DocumentAmount > 0 Then
		TableRow = Payments_2.Add();
		TableRow.Sum = DocumentAmount - Payments_2.Total("Sum");
		If ValueIsFilled(Partner) Then
			TableRow.Partner = Partner;
		Else
			TableRow.Partner = CashServer.GetCounterpartyPartner(Counterparty);
		EndIf;
		AdditionalCriteria_ = ARAPObjectsServer.AdditionalSearchCriteria_1();
		AdditionalCriteria_.Counterparty = Counterparty;
		AdditionalCriteria_.Partner = TableRow.Partner;
		TableRow.ARAPObject = ARAPObjectsServer.GetCalculationObjectFromLink(ObjectRef, Organization, PaymentType_, AdditionalCriteria_);
		TableRow.ARAPCurrency = DocumentCurrency;
	EndIf;
	
	PaymentFromCustomer = (PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
	
	If FillInVATInDecryption Then
		VATTable = CashServer.TranscriptOfVATPayment(Organization, DocumentDate, DocumentCurrency, Payments_2.UnloadColumn("ARAPObject"), PaymentFromCustomer);
		CashServer.FillInNDSInDecryption(Payments_2, VATTable);
	EndIf;
	
	Payments_2.Columns.Add("PaymentPurpose");
	ARAPObjects = Payments_2.UnloadColumn("ARAPObject");
	Objects = Common.ObjectsAttributeValue(ARAPObjects, "Object");
	For Each Page1 In Payments_2 Do
		Page1.PaymentPurpose = Objects[Page1.ARAPObject] 
	EndDo;
	
	AddressOfPaymentsInTheStorage = PutToTempStorage(Payments_2, UUID);
	
EndProcedure

&AtServer
Procedure WhenOpenedOnServer()
	
	FillInTableForSettlementsWithPartners();
	SetVisibility1();
	
EndProcedure

&AtServer
Procedure FillInTableForSettlementsWithPartners()
	
	Attributes = New Structure;
	Attributes.Insert("Date", DocumentDate);
	Attributes.Insert("Organization", Organization);
	Attributes.Insert("DocumentAmount", DocumentAmount);
	Attributes.Insert("Currency", DocumentCurrency);
	Attributes.Insert("Counterparty", Counterparty);
	Attributes.Insert("Partner", Partner);
	
	If ValueIsFilled(PaymentType_) Then
		Attributes.Insert("PaymentType_", PaymentType_);
	EndIf;
	
	Attributes.Insert("PartnerOtherRelations", PartnerOtherRelations);
	Attributes.Insert("SelectAccountsReceivable", SelectAccountsReceivable);
	Attributes.Insert("SelectOnlyUnconditionalDebt", SelectOnlyUnconditionalDebt);
	Attributes.Insert("SelectionOfPaymentByRequest", SelectionOfPaymentByRequest);
	
	Attributes.Insert("RecordBranches", RecordBranches);
	Attributes.Insert("ByPaymentDates", ByPaymentDates);
	
	AdditionalFilters = New Map();
	For Each ListItem In ParameterAdditionalSelections Do
		AdditionalFilters.Insert(ListItem.Presentation, ListItem.Value);
	EndDo;
	
	ARAPAccountingServer.FillInTableOfSettlementBalances(Attributes, AddressOfPaymentsInTheStorage, PaymentBalanceTable, AdditionalFilters);
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	SettlementCurrencyRates_.Currency AS Currency,
	|	ExchangeRates.CourseNumerator * ISNULL(SettlementCurrencyRates_.CourseDenominator,1) 
	|		/ (ExchangeRates.CourseDenominator * ISNULL(SettlementCurrencyRates_.CourseNumerator,1)) AS ZoomRatio
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS ExchangeRates
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS SettlementCurrencyRates_
	|			ON SettlementCurrencyRates_.Currency IN (&SettlementCurrencies)
	|WHERE ExchangeRates.Currency = &DocumentCurrency";
	Query.SetParameter("Date",DocumentDate);
	Query.SetParameter("DocumentCurrency",DocumentCurrency);
	Query.SetParameter("SettlementCurrencies",PaymentBalanceTable.Unload(,"ARAPCurrency").UnloadColumn("ARAPCurrency"));
	Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization));
	ConversionFactor.Load(Query.Execute().Unload());
	
	AmountByPayments = 0;
	For Each TableRow In PaymentBalanceTable Do
		
		If TableRow.Selected Then
			AmountByPayments = AmountByPayments + TableRow.Sum;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure CalculateAmountOfPayments(IdOfModifiedRow = Undefined, EditingAmount = False)
	
	CalculateSelectionForAmount(IdOfModifiedRow, EditingAmount);
	
	AmountByPayments = 0;
	For Each TableRow In PaymentBalanceTable Do
		
		If TableRow.Selected Then
			AmountByPayments = AmountByPayments + TableRow.Sum;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure SetRowSelection()
	
EndProcedure

&AtClient
Procedure CalculateSelectionForAmount(IdOfModifiedRow, EditingAmount)
	
	If Not SelectByAmount Then
		Return;
	EndIf;
	
	NewPaymentAmount = 0;
	RowsSelected = PaymentBalanceTable.FindRows(New Structure("Selected", True));
	For Each TableRow In RowsSelected Do
		NewPaymentAmount = NewPaymentAmount + TableRow.Sum;
	EndDo;
	
	If IdOfModifiedRow = Undefined Then
		If RowsSelected.Count() = 0 Then
			Return;
		EndIf;
		CurrentRow = RowsSelected[0];
	Else
		CurrentRow = PaymentBalanceTable.FindByID(IdOfModifiedRow);
	EndIf;
	
	If NewPaymentAmount > DocumentAmount Then
		// It is necessary to reduce the sum of the selected lines to the sum of the document, starting from the end
		ShouldReduce = NewPaymentAmount - DocumentAmount;
		KeyAttributesOfCurrentLine = KeyAttributes();
		FillPropertyValues(KeyAttributesOfCurrentLine, CurrentRow);
		Counter = RowsSelected.UBound();
		While Counter >= 0 Do
			KeyAttributes = KeyAttributes();
			FillPropertyValues(KeyAttributes, RowsSelected[Counter]);
			If TMCommonUseClientServer.StructuresAreEqual(KeyAttributes, KeyAttributesOfCurrentLine) 
				And PaymentBalanceTable.IndexOf(CurrentRow) >= PaymentBalanceTable.IndexOf(RowsSelected[Counter]) Then
				Counter = Counter - 1;
				Continue;
			EndIf;
			If RowsSelected[Counter].Sum <= ShouldReduce Then
				RowsSelected[Counter].Selected = False;
				ShouldReduce = ShouldReduce - RowsSelected[Counter].Sum;
				RowsSelected[Counter].Sum = GetFullAmountOfLine(RowsSelected[Counter]);
			Else
				RowsSelected[Counter].Sum = RowsSelected[Counter].Sum - ShouldReduce;
				ShouldReduce = 0;
			EndIf;
			Counter = Counter - 1;
		EndDo;
		// Now we reduce the rows for the selected calculation object, if the rest were not enough
		If ShouldReduce > 0 Then
			KeyAttributesOfCurrentLine.Insert("Selected", True);
			PaymentDateStrings = PaymentBalanceTable.FindRows(KeyAttributesOfCurrentLine);
			Counter = PaymentDateStrings.UBound();
			While Counter >= 0 Do
				ShowMessage = False;
				If PaymentDateStrings[Counter].Sum <= ShouldReduce Then
					PaymentDateStrings[Counter].Selected = False;
					ShouldReduce = ShouldReduce - PaymentDateStrings[Counter].Sum;
					PaymentDateStrings[Counter].Sum = GetFullAmountOfLine(PaymentDateStrings[Counter]);
					If PaymentDateStrings[Counter] = CurrentRow Then
						ShowMessage = True;
					EndIf;
				Else
					PaymentDateStrings[Counter].Sum = PaymentDateStrings[Counter].Sum - ShouldReduce;
					ShouldReduce = 0;
					If PaymentDateStrings[Counter] = CurrentRow And EditingAmount Then
						ShowMessage = True;
					EndIf;
				EndIf;
				// If earlier payment milestones have already been selected, it is impossible to select a line or set the entered amount
				If ShowMessage Then
					MessageText = NStr("vi = 'Để chọn dòng với số tiền lớn, hãy đặt nút gạt sang chế độ ""không hạn chế""';
										|ru = 'Для выбора строк на большую сумму установите переключатель в режим ""без ограничения""';
										|en = 'To select lines for a big amount, set the radio button to the Unrestricted mode'; fa = 'To select lines for a big amount, set the radio button to the Unrestricted mode';
										|it = 'Для выбора строк на большую сумму установите переключатель в режим ""без ограничения""';
										|pl = 'To select lines for a big amount, set the radio button to the Unrestricted mode';
										|tr = 'Daha fazla tutarda satır seçimi için anahtarı ""kısıtlamasız"" moduna ayarlayın'");
					ClearMessages();
					CommonClient.MessageToUser(MessageText);
				EndIf;
				Counter = Counter - 1;
			EndDo;
		EndIf;
	Else
		
		// If the amount of the selected payments has decreased, we will first try to place the difference in the already selected lines with an incomplete amount 
		EnlargeSelected = 0;
		If NewPaymentAmount < DocumentAmount Then
			EnlargeSelected = DocumentAmount - NewPaymentAmount;
		EndIf;
		
		Select = DocumentAmount;
		Found1 = False;
		UnselectedStages = New Map;
		
		For Each Page1 In PaymentBalanceTable Do
			
			KeyAttributes = KeyAttributes();
			FillPropertyValues(KeyAttributes, Page1);
			
			If (Not Page1.Selected 
				Or Page1.Sum < GetFullAmountOfLine(Page1))
					And GetValueByKeyAttributes(KeyAttributes, UnselectedStages) = Undefined Then
				SetValueByKeyDetails(KeyAttributes, UnselectedStages, Page1.GetID());
			EndIf;
			
			If Page1 = CurrentRow Then
				Found1 = True;
				If Not Page1.Selected Then
					Continue;
				EndIf;
			EndIf;
			
			If Not Found1 Then
				If Page1.Selected Then 
					FullAmount = GetFullAmountOfLine(Page1);
					If EnlargeSelected > 0 And Page1.Sum < FullAmount Then
						If EnlargeSelected > FullAmount - Page1.Sum Then
							EnlargeSelected = EnlargeSelected + Page1.Sum - FullAmount;
							Page1.Sum = FullAmount;
						Else
							Page1.Sum = Page1.Sum + EnlargeSelected;
							EnlargeSelected = 0;
						EndIf;
					EndIf;
					Select = Select - Page1.Sum;
				EndIf;
				Continue;
			EndIf;
			
			If Page1.ARAPCurrency = DocumentCurrency Then
				AmountDue = Page1.AmountDue - Page1.BeingPaid;
			Else
				For Each String In ConversionFactor Do
					If String.Currency = Page1.ARAPCurrency Then
						AmountDue = (Page1.AmountDue - Page1.BeingPaid) / String.ZoomRatio;
					EndIf;
				EndDo;
			EndIf;
			
			IdOfUnselectedStage = GetValueByKeyAttributes(KeyAttributes, UnselectedStages);
			EarlierStageIsSelected = IdOfUnselectedStage = Undefined
									Or IdOfUnselectedStage = Page1.GetID();
			
			If Select <= 0 Or Not EarlierStageIsSelected Then
				Page1.Selected = False;
				Page1.Sum = GetFullAmountOfLine(Page1);
				SetValueByKeyDetails(KeyAttributes, UnselectedStages, Page1.GetID());
			ElsIf EditingAmount And Page1 = CurrentRow Then
				If Page1.Sum = 0 Then
					Page1.Selected = False;
					SetValueByKeyDetails(KeyAttributes, UnselectedStages, Page1.GetID());
				EndIf;
				Select = Select - Page1.Sum;
			ElsIf Select < AmountDue Then
				Page1.Sum = Select;
				Page1.Selected = True;
				Select = 0;
				SetValueByKeyDetails(KeyAttributes, UnselectedStages, Undefined)
			ElsIf AmountDue > 0 Then
				// If the user entered an amount less than the full amount, then it must be left
				Page1.Sum = AmountDue;
				Page1.Selected = True;
				Select = Select - Page1.Sum;
				SetValueByKeyDetails(KeyAttributes, UnselectedStages, Undefined)
			ElsIf Page1.Selected Then
				Select = Select - Page1.Sum;
			EndIf;
				
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetRemoveRowSelection(ModifiedRows, SetSelection_, EditingAmount = False)
	
	ArrayOfPaymentDatesByAttributes = GetPaymentDatesByKeyAttributes(ModifiedRows, Not SetSelection_);
	
	For Each StructureWithDate In ArrayOfPaymentDatesByAttributes Do
		KeyAttributes = KeyAttributes();
		FillPropertyValues(KeyAttributes, StructureWithDate);
		TableRowsByDetails = PaymentBalanceTable.FindRows(KeyAttributes);
		Counter = TableRowsByDetails.Count();
		While Counter > 0 Do
			Counter = Counter - 1;
			If SetSelection_ And TableRowsByDetails[Counter].PaymentDate <= StructureWithDate.PaymentDate
				Or Not SetSelection_ And TableRowsByDetails[Counter].PaymentDate >= StructureWithDate.PaymentDate Then
				// When setting the selection of previous lines, the selection for the amount must be started from the very first selected line
				If SetSelection_
					And (Not TableRowsByDetails[Counter].Selected 
						Or TableRowsByDetails[Counter].Sum < GetFullAmountOfLine(TableRowsByDetails[Counter])) Then
					Items.PaymentBalanceTable.CurrentRow = TableRowsByDetails[Counter].GetID();
				EndIf;
				TableRowsByDetails[Counter].Selected = SetSelection_;
				If Not SetSelection_ Then
					TableRowsByDetails[Counter].Sum = GetFullAmountOfLine(TableRowsByDetails[Counter]);
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	If EditingAmount Then
		For Each RowID In ModifiedRows Do
			TableRow = PaymentBalanceTable.FindByID(RowID);
			If TableRow.Sum = 0 Then
				TableRow.Selected = False;
			EndIf;
		EndDo;
	EndIf;
	
	CalculateAmountOfPayments(Items.PaymentBalanceTable.CurrentRow, EditingAmount);
	SetRowSelection();
	
EndProcedure

&AtClient
Function KeyAttributes()
	
	Result = New Structure;
	
	Result.Insert("ARAPObject", PredefinedValue("Catalog.ARAPObjects.EmptyRef"));
	Result.Insert("Partner", PredefinedValue("Catalog.Partners.EmptyRef"));
	Result.Insert("ARAPCurrency", PredefinedValue("Catalog.Currencies.EmptyRef"));
	
	Return Result;
	
EndFunction

&AtClient
Function GetPaymentDatesByKeyAttributes(RowsSelected, ChooseMinimum = False)
	
	Result = New Array;
	
	// We will find the minimum or maximum payment dates in the context of key Attributes, by simple search, since there are not many selected lines
	For Each RowID In RowsSelected Do
		TableRow = PaymentBalanceTable.FindByID(RowID);
		If TableRow <> Undefined Then
			StructureWithDate = KeyAttributes();
			FillPropertyValues(StructureWithDate, TableRow);
			StructureWithDate.Insert("PaymentDate", TableRow.PaymentDate);
			FoundStructure = Undefined;
			For Each ResultStructure1 In Result Do
				If TMCommonUseClientServer.StructuresAreEqual(ResultStructure1, StructureWithDate, "ARAPObject,Partner,ARAPCurrency") Then
					FoundStructure = ResultStructure1;
					Break;
				EndIf;
			EndDo;
			If FoundStructure = Undefined Then
				Result.Add(StructureWithDate);
			ElsIf ChooseMinimum And TableRow.PaymentDate < FoundStructure.PaymentDate
				Or Not ChooseMinimum And TableRow.PaymentDate > FoundStructure.PaymentDate Then
				FoundStructure.PaymentDate = TableRow.PaymentDate;
			EndIf;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Function GetValueByKeyAttributes(KeyAttributes, Map)
	
	Result = Map;
	For Each KeyAndValue In KeyAttributes Do
		Result = Result[KeyAndValue.Value];
		If Result = Undefined Then
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Procedure SetValueByKeyDetails(KeyAttributes, Map, Value)
	
	CurrentMapping = Map;
	Counter = 1;
	For Each KeyAndValue In KeyAttributes Do
		If Counter < KeyAttributes.Count() Then
			If CurrentMapping[KeyAndValue.Value] = Undefined Then
				CurrentMapping[KeyAndValue.Value] = New Map;
			EndIf;
			CurrentMapping = CurrentMapping[KeyAndValue.Value];
		Else
			CurrentMapping[KeyAndValue.Value] = Value;
		EndIf;
		Counter = Counter + 1;
	EndDo;
	
EndProcedure

&AtClient
Function GetFullAmountOfLine(RowData)
	
	ZoomRatio = 1;
	If RowData.ARAPCurrency <> DocumentCurrency Then
		For Each String In ConversionFactor Do
			If String.Currency = RowData.ARAPCurrency Then
				ZoomRatio = String.ZoomRatio;
			EndIf;
		EndDo;
	EndIf;
	If RowData.PartnerDebt_ <> 0 And SelectAccountsReceivable
		And PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting") Then
		Return Min(RowData.PartnerDebt_, RowData.AmountDue - RowData.BeingPaid) / ZoomRatio;
	ElsIf RowData.PartnerDebt_ <> 0 And SelectAccountsReceivable
		And PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.VendorARAPAccounting") Then
		Return RowData.PartnerDebt_ / ZoomRatio;
	ElsIf RowData.AccountsPayableOfCompany <> 0 And Not SelectAccountsReceivable
		And PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.VendorARAPAccounting") Then
		Return Min(RowData.AccountsPayableOfCompany, RowData.AmountDue - RowData.BeingPaid) / ZoomRatio;
	ElsIf RowData.AccountsPayableOfCompany <> 0 And Not SelectAccountsReceivable
		And PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting") Then
		Return RowData.AccountsPayableOfCompany / ZoomRatio;
	ElsIf RowData.AmountDue <> 0 Then
		Return (RowData.AmountDue - RowData.BeingPaid) / ZoomRatio;
	EndIf;
	
EndFunction

&AtClient
Procedure MatchByAmountCalculate()
	If Not SelectByAmount Then
		For Each RemainderLine In PaymentBalanceTable Do
			If RemainderLine.Selected Then
				RemainderLine.Sum = GetFullAmountOfLine(RemainderLine);
			EndIf;
		EndDo;
		CalculateAmountOfPayments();
		SetRowSelection();
	ElsIf DocumentAmount < AmountByPayments Then
		CalculateAmountOfPayments();
		SetRowSelection();
	EndIf;
EndProcedure

#EndRegion

#EndRegion
