
#Region FormEventHandlers
// Code of procedures and functions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Employee = Common.ObjectAttributeValue(Users.CurrentUser(), "Individual");
	ShowProductPhotos = Parameters.ShowProductPhotos;
	CurrentWarehouse = Parameters.CurrentWarehouse;
	EmployeeType = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.EmployeeTypeCourier();
	CalculationsPeriod.Variant = StandardPeriodVariant.Today;
	
	UpdateFormData();
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	CurrentCashAccount = Settings.Get("CurrentCashAccount");
	CurrentTab = Settings.Get("CurrentTab");
	
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	CreateMenu_();
	GeneratePresentationOfSettlementPeriod();

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("Catalog.Warehouses.Form.ChoiceForm") Then
		
		CurrentWarehouse = ValueSelected;
		PhotographPresentationOfSelections();
		UpdateFormData();
		
	ElsIf Upper(ChoiceSource.FormName) = Upper("Catalog.CashAccounts.Form.ChoiceForm") Then
		
		CurrentCashAccount = ValueSelected;
		PhotographPresentationOfSelections();
		UpdateFormData();

	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "UpdateListOfOrders" Then
		UpdateFormData();
		CreateMenu_();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfOrders_

&AtClient
Procedure ListOfOrders_Selection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentRow = Items.ListOfOrders_.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("ReferenceOrder", CurrentRow.ReferenceOrder);
	FormOpenParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		
	OpenForm(
		"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.ReferenceCard",
		FormOpenParameters,
		ThisForm,,,,,
		FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure ListReceiptSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure ListExpenseSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdateForm(Command)
	
	UpdateFormData();
	CreateMenu_();
	
EndProcedure

&AtClient
Procedure TheSelectionsOfTheStoreClean(Command)
	
	CurrentWarehouse = Undefined;
	PhotographPresentationOfSelections();
	UpdateFormData();

EndProcedure

&AtClient
Procedure SelectionShopToOpen(Command)
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("ChoiceMode", True);
	FormOpenParameters.Insert("MultipleChoice", False);
	FormOpenParameters.Insert("CloseOnChoice", True);
	FormOpenParameters.Insert("Filter", New Structure("Ref", AvailableWarehouses()));
		
	OpenForm(
		"Catalog.Warehouses.Form.ChoiceForm",
		FormOpenParameters,
		ThisForm,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SelectionsBoxOfficeToOpen(Command)
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("ChoiceMode", True);
	FormOpenParameters.Insert("MultipleChoice", False);
	FormOpenParameters.Insert("CloseOnChoice", True);
	FormOpenParameters.Insert("Filter", New Structure("Ref", AvailableCashRegisters_()));
		
	OpenForm(
		"Catalog.CashAccounts.Form.ChoiceForm",
		FormOpenParameters,
		ThisForm,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SelectionsCashRegisterClear(Command)
	
	CurrentCashAccount = Undefined;
	PhotographPresentationOfSelections();
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure TheSelectionPeriodIsOpen(Command)
	
	CallbackDescriptionOnClose = New CallbackDescription("SelectionOfSettlementPeriodCompletion", ThisForm);
	Dialog = New StandardPeriodEditDialog();
	Dialog.Period = CalculationsPeriod;
	Dialog.Show(CallbackDescriptionOnClose); 
	
EndProcedure


// The treatment of choice period
// 
// Parameters:
// 	Result - StandardPeriod - the dialog was closed by clicking "OK"; Undefined-otherwise
// 	Var_Parameters - Arbitrary
&AtClient
Procedure SelectionOfSettlementPeriodCompletion(Result, Var_Parameters) Export
	
	If Result <> Undefined Then
		
		If Result.StartDate > Result.EndDate Then
			
			ErrorText = NStr("vi = 'Đã đặt sai kỳ.
									|Ngày đầu kỳ phải nhỏ hơn ngày kết thúc.';
									|ru = 'Период задан неверно.
									|Дата начала периода должна быть меньше даты окончания.';
									|en = 'The period is invalid.
									|The period start date must be less than the end date.'; fa = 'The period is invalid.
									|The period start date must be less than the end date.';
									|it = 'Periodo dato errato.
									| La data di inizio periodo deve essere precedente alla data di completamento.';
									|pl = 'Okres jest zadany niepoprawnie.
									|Data początku okresu powinno być mniejsze niż data zakończenia.';
									|tr = 'Dönem yanlış ayarlandı.
									|Dönemin başlangıç ​​tarihi, bitiş tarihinden önce olmalıdır.'");
			CommonClient.MessageToUser(ErrorText);
			Return;
		EndIf;
		
		CalculationsPeriod = Result;
		GeneratePresentationOfSettlementPeriod();
		UpdateFormData();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToOrders(Command)
	
	If CurrentTab = 1 Then
		GoToTab(0);
	EndIf;
	
EndProcedure

&AtClient
Procedure SwitchToCash(Command)
	
	If CurrentTab = 0 Then
		GoToTab(1);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpandCollapseAParish(Command)
	
	TheParishIsOpen = Not TheParishIsOpen;
	Items.GroupListReceipt.Visible = TheParishIsOpen;
	Items.ExpandCollapseAParish.Picture = ?(TheParishIsOpen, PictureLib.UpArrowAssemblyAndDelivery, PictureLib.DownArrowAssemblyAndDelivery);
	
EndProcedure

&AtClient
Procedure ShowMoreShowLessConsumption(Command)

	ConsumptionIsOpen = Not ConsumptionIsOpen;
	Items.GroupListExpense.Visible = ConsumptionIsOpen;
	Items.ShowMoreShowLessConsumption.Picture = ?(ConsumptionIsOpen, PictureLib.UpArrowAssemblyAndDelivery, PictureLib.DownArrowAssemblyAndDelivery);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure GoToTab(TabCode = 0)
	
	CurrentTab = TabCode;
	UpdateFormData();
	CreateMenu_();
	
EndProcedure

&AtServer
Procedure UpdateFormData()
	
	Query = New Query();
	QueryText = "SELECT
	               |	AssemblyAndDeliveryStatuses.ReferenceOrder AS ReferenceOrder,
	               |	AssemblyAndDeliveryStatuses.Status AS Status,
	               |	Documents.Warehouse AS Warehouse,
	               |	Documents.Number AS Number,
	               |	Documents.DateOfShipment DeliveryDate,
	               |	Documents.DeliveryTimeFrom AS DeliveryTimeFrom,
	               |	Documents.DeliveryTimeTo AS DeliveryTimeTo,
	               |	Documents.DocumentAmount AS DocumentAmount,
	               |	Documents.AdditionalDeliveryInformation AS Comment,
	               |	Documents.Currency AS Currency,
	               |	Documents.PaymentMethod AS PaymentMethod,
	               |	Documents.Warehouse.Description AS WarehouseName,
	               |	AssemblyAndDeliveryStatuses.CancellationReason.Description AS ReasonForCancellationName
	               |INTO TemporaryDisposalTable
	               |FROM
	               |	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	               |		INNER JOIN Document.SalesOrder AS Documents
	               |		ON ((CAST(AssemblyAndDeliveryStatuses.ReferenceOrder AS Document.SalesOrder)) = Documents.Ref)
	               |WHERE
	               |	AssemblyAndDeliveryStatuses.Status IN(&Status)
	               |	AND Documents.Courier = &Employee
	               |	AND Documents.Posted
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	AssemblyAndDeliveryStatuses.ReferenceOrder,
	               |	AssemblyAndDeliveryStatuses.Status,
	               |	Documents.Warehouse,
	               |	Documents.Number,
	               |	Documents.Date,
	               |	Documents.DeliveryTimeFrom,
	               |	Documents.DeliveryTimeTo,
	               |	Documents.DocumentAmount,
	               |	Documents.AdditionalDeliveryInformation,
	               |	Documents.Currency,
	               |	Documents.PaymentMethod,
	               |	Documents.Warehouse.Description,
	               |	AssemblyAndDeliveryStatuses.CancellationReason.Description
	               |FROM
	               |	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	               |		INNER JOIN Document.CustomerInvoice AS Documents
	               |		ON ((CAST(AssemblyAndDeliveryStatuses.ReferenceOrder AS Document.CustomerInvoice)) = Documents.Ref)
	               |WHERE
	               |	AssemblyAndDeliveryStatuses.Status IN(&Status)
	               |	AND Documents.Courier = &Employee
	               |	AND Documents.Posted
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	SUM(1) AS NumberOfReferences
	               |FROM
	               |	TemporaryDisposalTable AS Documents
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT DISTINCT
	               |	Documents.Warehouse AS Warehouse,
	               |	Documents.WarehouseName AS WarehouseName
	               |FROM
	               |	TemporaryDisposalTable AS Documents
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	CashAccounts.Ref AS CashAccount,
	               |	CashAccounts.CashCurrency AS Currency,
	               |	CashAccounts.Description AS CheckoutName
	               |FROM
	               |	Catalog.CashAccounts AS CashAccounts
	               |WHERE
	               |	CashAccounts.Individual = &Employee
	               |	AND CashAccounts.OperationalCashAccount = TRUE
	               |
	               |ORDER BY
	               |	CashAccount
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	Documents.ReferenceOrder AS ReferenceOrder,
	               |	Documents.Status AS Status,
	               |	Documents.Warehouse AS Warehouse,
	               |	Documents.Number AS Number,
	               |	Documents.DeliveryDate AS DeliveryDate,
	               |	Documents.DeliveryTimeFrom AS DeliveryTimeFrom,
	               |	Documents.DeliveryTimeTo AS DeliveryTimeTo,
	               |	Documents.DocumentAmount AS DocumentAmount,
	               |	Documents.Comment AS Comment,
	               |	Documents.Currency AS Currency,
	               |	Documents.PaymentMethod AS PaymentMethod,
	               |	Documents.WarehouseName AS WarehouseName,
	               |	Documents.ReasonForCancellationName AS ReasonForCancellationName
	               |INTO TemporaryTableOfWarehouseOrders
	               |FROM
	               |	TemporaryDisposalTable AS Documents
	               |WHERE
	               |	(&Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	               |			OR Documents.Warehouse IN HIERARCHY (&Warehouse))
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	Documents.ReferenceOrder AS ReferenceOrder,
	               |	SUM(1) AS NumberOfRows,
	               |	SUM(Goods.NumberOfPackages * &QueryTextPackageWeight) AS Weight
	               |INTO TemporaryTableOfGoods_
	               |FROM
	               |	TemporaryTableOfWarehouseOrders AS Documents
	               |		LEFT JOIN Document.SalesOrder.Goods AS Goods
	               |		ON Documents.ReferenceOrder = Goods.Ref
	               |		INNER JOIN Catalog.Products AS CatalogProducts
	               |		ON (Goods.Products = CatalogProducts.Ref)
	               |		INNER JOIN Catalog.ItemKinds AS CatalogItemKinds
	               |		ON (CatalogProducts.ProductKind = CatalogItemKinds.Ref)
	               |		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	               |		ON (Goods.Package = PackagesAndUnitsOfMeasure.Ref)
	               |WHERE
	               |	NOT Goods.Canceled
	               |
	               |GROUP BY
	               |	Documents.ReferenceOrder
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	Documents.ReferenceOrder,
	               |	SUM(1),
	               |	SUM(Goods.NumberOfPackages * &QueryTextPackageWeight)
	               |FROM
	               |	TemporaryTableOfWarehouseOrders AS Documents
	               |		LEFT JOIN Document.CustomerInvoice.Goods AS Goods
	               |		ON Documents.ReferenceOrder = Goods.Ref
	               |		INNER JOIN Catalog.Products AS CatalogProducts
	               |		ON (Goods.Products = CatalogProducts.Ref)
	               |		INNER JOIN Catalog.ItemKinds AS CatalogItemKinds
	               |		ON (CatalogProducts.ProductKind = CatalogItemKinds.Ref)
	               |		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	               |		ON (Goods.Package = PackagesAndUnitsOfMeasure.Ref)
	               |
	               |GROUP BY
	               |	Documents.ReferenceOrder
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	Documents.ReferenceOrder AS ReferenceOrder,
	               |	Documents.Status AS Status,
	               |	Documents.Warehouse AS Warehouse,
	               |	Documents.Number AS Number,
	               |	Documents.DeliveryDate AS DeliveryDate,
	               |	Documents.DeliveryTimeFrom AS DeliveryTimeFrom,
	               |	Documents.DeliveryTimeTo AS DeliveryTimeTo,
	               |	Documents.DocumentAmount AS DocumentAmount,
	               |	Documents.Comment AS Comment,
	               |	Documents.Currency AS Currency,
	               |	Documents.PaymentMethod AS PaymentMethod,
	               |	Documents.WarehouseName AS WarehouseName,
	               |	Documents.ReasonForCancellationName AS ReasonForCancellationName,
	               |	Goods.NumberOfRows AS NumberOfRows,
	               |	Goods.Weight AS Weight
	               |FROM
	               |	TemporaryTableOfWarehouseOrders AS Documents
	               |		LEFT JOIN TemporaryTableOfGoods_ AS Goods
	               |		ON Documents.ReferenceOrder = Goods.ReferenceOrder
	               |
	               |ORDER BY
	               |	DeliveryDate,
	               |	DeliveryTimeTo
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	CASE
	               |		WHEN CashAccountBalanceBalanceAndTurnovers.Recorder REFS Document.CashAccountReceiptNote
	               |			THEN CAST(CashAccountBalanceBalanceAndTurnovers.Recorder AS Document.CashAccountReceiptNote).Number
	               |		WHEN CashAccountBalanceBalanceAndTurnovers.Recorder REFS Document.CashVoucher
	               |			THEN CAST(CashAccountBalanceBalanceAndTurnovers.Recorder AS Document.CashVoucher).Number
	               |		ELSE ""Other""
	               |	END AS Number,
	               |	CashAccountBalanceBalanceAndTurnovers.Period AS Date,
	               |	CashAccountBalanceBalanceAndTurnovers.SumReceipt AS SumReceipt,
	               |	CashAccountBalanceBalanceAndTurnovers.SumExpense AS SumExpense,
	               |	CashAccountBalanceBalanceAndTurnovers.SumOpeningBalance AS SumOpeningBalance,
	               |	CashAccountBalanceBalanceAndTurnovers.SumClosingBalance AS SumClosingBalance,
	               |	CashAccountBalanceBalanceAndTurnovers.CashAccount.CashCurrency AS Currency,
	               |	CashAccountBalanceBalanceAndTurnovers.Period AS Period,
	               |	CashAccountBalanceBalanceAndTurnovers.CashAccount AS CashAccount
	               |FROM
	               |	AccumulationRegister.CashAccountBalance.BalanceAndTurnovers(
	               |			&StartDate,
	               |			&EndDate,
	               |			Recorder,
	               |			,
	               |			CashAccount IN
	               |				(SELECT TOP 1
	               |					CashAccounts.Ref AS CashAccount
	               |				FROM
	               |					Catalog.CashAccounts AS CashAccounts
	               |				WHERE
	               |					CashAccounts.DeletionMark = FALSE
	               |					AND CashAccounts.OperationalCashAccount = TRUE
	               |					AND CashAccounts.Individual = &Employee
	               |					AND (&CashAccount = VALUE(Catalog.CashAccounts.EmptyRef)
	               |						OR CashAccounts.Ref = &CashAccount)
	               |				ORDER BY
	               |					CashAccount)) AS CashAccountBalanceBalanceAndTurnovers
	               |
	               |ORDER BY
	               |	Period";
	
	Query.SetParameter("Employee", Employee);
	Query.SetParameter("Warehouse", CurrentWarehouse);
	Query.SetParameter("CashAccount", CurrentCashAccount);
	Query.SetParameter("StartDate", CalculationsPeriod.StartDate);
	Query.SetParameter("EndDate", CalculationsPeriod.EndDate);
	Query.SetParameter("Date", CurrentSessionDate());
	Query.SetParameter("Status", WarehousesServer.StatusesOfCanceledOrders());
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackageWeight", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
			"PackagesAndUnitsOfMeasure", 
			"CatalogProducts"));
	
	Query.Text = QueryText;
	Results = Query.ExecuteBatch();
	
	ResultIsSummarized = Results[1].Unload();
	WarehousesList.Load(Results[2].Unload());
	CashAccountList.Load(Results[3].Unload());
	
	NumberOfReferences = ResultIsSummarized[0].NumberOfReferences;
	
	ListOfOrders_.Clear();
	
	SamplingByOrders = Results[6].Select();
	
	While SamplingByOrders.Next() Do
		
		NewRow = ListOfOrders_.Add();
		
		FillPropertyValues(NewRow, SamplingByOrders);
		
		If ValueIsFilled(NewRow.Comment) Then
			NewRow.CommentPicture_2 = 1;
		EndIf;
		
		Module = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery;
		
		NewRow.DateTimeOfDeliveryPresentation = Module.DateTimeOfDeliveryPresentation(NewRow);
		NewRow.SumPresentation = Module.SumPresentation(NewRow);
		NewRow.PaymentMethodPresentation = Module.PaymentMethodPresentation(NewRow);
		NewRow.NumberOfRowsPresentation = Module.NumberOfRowsPresentation(NewRow);
		NewRow.WeightPresentation = Module.WeightPresentation(NewRow.Weight);
		
	EndDo;
	
	NumberOfOrdersPerWarehouse = ListOfOrders_.Count();
	
	SampleByCalculation = Results[7].Select();
	
	ThisIsFirstOne = True;
	NewRow = Undefined;
	BalanceAtTheBeginningOfThePeriod_3 = 0;
	BalanceAtTheEndOfThePeriod_3 = 0;
	SumReceipt = 0;
	SumExpense = 0;
	ListReceipt.Clear();
	ListExpense.Clear();
	
	While SampleByCalculation.Next() Do
		
		If ThisIsFirstOne Then
			ThisIsFirstOne = False;
			BalanceAtTheBeginningOfThePeriod_3 = SampleByCalculation.SumOpeningBalance;
			CurrentCashAccount = SampleByCalculation.CashAccount;
			Currency = SampleByCalculation.Currency;
		EndIf;
		
		BalanceAtTheEndOfThePeriod_3 = SampleByCalculation.SumClosingBalance;
		
		If SampleByCalculation.SumReceipt <> 0 Then
			
			NewRow = ListReceipt.Add();
			SumReceipt = SumReceipt + SampleByCalculation.SumReceipt;
			NewRow.DocumentAmount = SampleByCalculation.SumReceipt;
			
		ElsIf SampleByCalculation.SumExpense <> 0 Then
			
			NewRow = ListExpense.Add();
			SumExpense = SumExpense + SampleByCalculation.SumExpense;
			NewRow.DocumentAmount = SampleByCalculation.SumExpense;
			
		Else
			 Continue;
		EndIf;
		
		FillPropertyValues(NewRow, SampleByCalculation);
		
		Module = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery;
		
		NewRow.DocumentPresentation = StrTemplate(NStr("vi = 'Số %1 (%2)';
														|ru = '№ %1 (%2)';
														|en = 'No. %1 (%2)'; fa = 'No. %1 (%2)';
														|it = '№ %1 (%2)';
														|pl = 'Nr %1 (%2)';
														|tr = '№ %1 (%2)'"), NewRow.Number, Format(NewRow.Date, "DF=MM/dd/yy"));
		NewRow.SumPresentation = Module.SumPresentation(NewRow);
		
	EndDo;
	
	If CashAccountList.Count() = 0 Then
		
		CurrentCashAccount = Undefined;
		Currency = Undefined;
		CurrentTab = 0;
		
	ElsIf CashAccountList.Count() = 1 Then
		
		CurrentCashAccount = CashAccountList[0].CashAccount;
		Currency = CashAccountList[0].Currency;
		
	Else
		
		If CurrentCashAccount = Undefined Then
			
			CurrentCashAccount = CashAccountList[0].CashAccount;
			Currency = CashAccountList[0].Currency;
			
		Else
			FoundRows = CashAccountList.FindRows(New Structure("CashAccount", CurrentCashAccount));
			Currency = FoundRows[0].Currency;
		EndIf;
		
	EndIf;
	
	PhotographPresentationOfSelections();
	TakePictureOfPresentationOfGroupHeadings();
	
EndProcedure

&AtServer
Procedure PhotographPresentationOfSelections()
	
	PresentationsOfSelections = "";
	
	If ValueIsFilled(CurrentWarehouse) Then
		PresentationsOfSelections = CurrentWarehouse;
		Items.TeamSelectionsForTheStoreToOpen.TextColor = StyleColors.TextColorMainKittingAndDelivery;
		Items.GroupTeamSelectionsStoreTheNumberOfClean.Visible = True;
		Items.FrameSelectionsTheStoreToOpen.Picture = PictureLib.BorderMenuBlack;
		Items.GroupSelectionsStore.Visible = True;
		Items.TeamSelectionsForTheStoreToOpen.Title = PresentationsOfSelections;
	ElsIf WarehousesList.Count() > 1 Then
		PresentationsOfSelections = NStr("vi = 'Chọn cửa hàng/kho bãi';
										|ru = 'Выбрать магазин/склад';
										|en = 'Select store/warehouse'; fa = 'Select store/warehouse';
										|it = 'Selezionare punto vendita/ magazzino';
										|pl = 'Wybierz sklep/magazyn';
										|tr = 'Mağaza/ambar seç'");
		Items.TeamSelectionsForTheStoreToOpen.TextColor = StyleColors.TextColorAdditionalAssemblyAndDelivery;
		Items.GroupTeamSelectionsStoreTheNumberOfClean.Visible = False;
		Items.FrameSelectionsTheStoreToOpen.Picture = PictureLib.BorderMenuGray;
		Items.GroupSelectionsStore.Visible = True;
		Items.TeamSelectionsForTheStoreToOpen.Title = PresentationsOfSelections;
	Else
		Items.GroupSelectionsStore.Visible = False;
	EndIf;
	
	If CashAccountList.Count() = 0 Then
		
		Items.CashPage.Visible = False;
		
	ElsIf CashAccountList.Count() = 1 Then
		
		Items.GroupSelectionsCheckout.Visible = False;
		Items.GroupCashFrameSelections.Visible = False;
		
	ElsIf ValueIsFilled(CurrentCashAccount) Then
		
		PresentationsOfSelections = CurrentCashAccount;
		Items.CommandSelectionsToTheCashierToOpen.TextColor = StyleColors.TextColorMainKittingAndDelivery;
		Items.FrameSelectionsTheCashierToOpen.Picture = PictureLib.BorderMenuBlack;
		Items.GroupSelectionsCheckout.Visible = True;
		Items.CommandSelectionsToTheCashierToOpen.Title = PresentationsOfSelections;
		
	Else
		PresentationsOfSelections = NStr("vi = 'Chọn quỹ tiền mặt';
										|ru = 'Выбрать кассу';
										|en = 'Select cash account'; fa = 'انتخاب صندوق';
										|it = 'Selezionare cassa';
										|pl = 'Wybierz kasę';
										|tr = 'Kasa seç'");
		Items.CommandSelectionsToTheCashierToOpen.TextColor = StyleColors.TextColorAdditionalAssemblyAndDelivery;
		Items.FrameSelectionsTheCashierToOpen.Picture = PictureLib.BorderMenuGray;
		Items.GroupSelectionsCheckout.Visible = True;
		Items.CommandSelectionsToTheCashierToOpen.Title = PresentationsOfSelections;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure TakePictureOfPresentationOfGroupHeadings()
	
	If CurrentTab = 1 Then
	
		Module = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery;
		
		Items.DecorationBalanceAtTheBeginningOfThePeriod.Title = Module.SumPresentationTotal(BalanceAtTheBeginningOfThePeriod_3, Currency);
		Items.DecorationBalanceAtTheEndOfThePeriod.Title = Module.SumPresentationTotal(BalanceAtTheEndOfThePeriod_3, Currency);
		
		ArrayDecoration = New Array();
		ArrayDecoration.Add(PictureLib.PlusIcon);
		ArrayDecoration.Add(Module.SumPresentationTotal(SumReceipt, Currency));
		Items.DecorationReceipt.Title = New FormattedString(ArrayDecoration);
		
		ArrayDecoration = New Array();
		ArrayDecoration.Add(PictureLib.MinusSign);
		ArrayDecoration.Add(Module.SumPresentationTotal(SumExpense, Currency));
		Items.DecorationExpense.Title = New FormattedString(ArrayDecoration);
		
		Items.ExpandCollapseAParish.Visible = ListReceipt.Count() > 0;
		Items.ExpandCollapseAParish.Picture = ?(TheParishIsOpen, PictureLib.UpArrowAssemblyAndDelivery, PictureLib.DownArrowAssemblyAndDelivery);
		
		Items.ShowMoreShowLessConsumption.Visible = ListExpense.Count() > 0;
		Items.ShowMoreShowLessConsumption.Picture = ?(ConsumptionIsOpen, PictureLib.UpArrowAssemblyAndDelivery, PictureLib.DownArrowAssemblyAndDelivery);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateMenu_()
	
	If CurrentTab = 0 Then
		NameOfFrameElement    = "OrderFrame";
		NameOfCommandElement  = "OrderCommand";
		PageElementName = "PageOfOrder";
	Else
		NameOfFrameElement    = "CashFrame";
		NameOfCommandElement  = "TeamCash";
		PageElementName = "CashPage";
	EndIf;
	
	ThereAreCashRegisters = CashAccountList.Count() <> 0;
	
	Items.CashMenuGroup.Visible = ThereAreCashRegisters;
	
	Items.OrderFrame.Picture = PictureLib.BorderMenuWhite;
	Items.OrderCommand.TextColor = WebColors.Gray;
	                                                           
	Items.CashFrame.Picture = PictureLib.BorderMenuWhite;
	Items.TeamCash.TextColor = WebColors.Gray;
	
	If ThereAreCashRegisters Then
		Items[NameOfFrameElement].Picture = PictureLib.BorderMenuBlack;
		Items[NameOfCommandElement].TextColor = WebColors.Black;
	EndIf;
	
	Items.GroupPages.CurrentPage = Items[PageElementName];
	
	GenerateMenuCommandHeaders();
	
EndProcedure

&AtClient
Procedure GenerateMenuCommandHeaders()
	
	Items.OrderCommand.Title = StrTemplate(NStr("vi = 'Đơn hàng (%1)';
												|ru = 'Заказы (%1)';
												|en = 'Orders (%1)'; fa = 'Orders (%1)';
												|it = 'Ordini (%1)';
												|pl = 'Zamówienia (%1)';
												|tr = 'Siparişler (%1)'"), NumberOfReferences);
	
EndProcedure

&AtClient
Procedure GeneratePresentationOfSettlementPeriod()
	
	If BegOfDay(CalculationsPeriod.StartDate) <> BegOfDay(CalculationsPeriod.EndDate) Then
		Items.TeamSelectionsPeriodOpen.Title = StrTemplate(NStr("vi = '%1 - %2';
																|ru = '%1 - %2';
																|en = '%1 - %2'; fa = '%1 - %2';
																|it = '%1 - %2';
																|pl = '%1 - %2';
																|tr = '%1 - %2'"), 
			Format(CalculationsPeriod.StartDate, "DF=MM/dd/yy"),
			Format(CalculationsPeriod.EndDate, "DF=MM/dd/yy"));
	Else
		Items.TeamSelectionsPeriodOpen.Title = StrTemplate(NStr("vi = '%1';
																|ru = '%1';
																|en = '%1'; fa = '%1';
																|it = '%1';
																|pl = '%1';
																|tr = '%1'"), 
			Format(CalculationsPeriod.StartDate, "DF=MM/dd/yy"));
	EndIf;
	
EndProcedure

&AtServer
Function AvailableWarehouses()
	
	Return WarehousesList.Unload(,"Warehouse").UnloadColumn("Warehouse");
	
EndFunction

&AtServer
Function AvailableCashRegisters_()
	
	Return CashAccountList.Unload(,"CashAccount").UnloadColumn("CashAccount");
	
EndFunction

#EndRegion
