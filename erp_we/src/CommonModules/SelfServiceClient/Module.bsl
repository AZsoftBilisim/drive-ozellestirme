
#Region Private

#Region Other

// Forms the structure of the parameters of the opening of the product selection form, characteristic of the self-service subsystem.
//
// Parameters:
//  Form parameters - Structure - parameters of the calling form
// Returns:
//   Structure   - the formed structure of parameters.
//
Function StructureOfParametersForSelection(Parameters) Export

	TypeOfTaxationENVD = Parameters.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToUTII");
	
	FormParameters = New Structure;
	FormParameters.Insert("TransferButtonTitle",                      Parameters.TransferHeader);
	FormParameters.Insert("Terms",                                    Parameters.Terms);
	FormParameters.Insert("Warehouse",                                         Parameters.Warehouse);
	FormParameters.Insert("Currency",                                        Parameters.Currency);
	FormParameters.Insert("Title",                                     Parameters.Title);
	FormParameters.Insert("ProductSegment",                           Parameters.ProductSegment);
	FormParameters.Insert("Document",                                      Parameters.Document);
	FormParameters.Insert("PriceIncludesVAT",                               Parameters.PriceIncludesVAT);
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", ?(Parameters.Property("SelectionModeUseWarehousesInTabularSection"),
	                                                                           Parameters.SelectionModeUseWarehousesInTabularSection, 
	                                                                           False));
	If Parameters.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent") Then
		FormParameters.Insert("FilterByProductType", New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer()));
	EndIf;
	FormParameters.Insert("HideTheViewPriceColumn",                     True);
	FormParameters.Insert("HideTheRequestQuantityButton",        False);
	FormParameters.Insert("HideTheItemPricesCommand",            True);
	FormParameters.Insert("HideCommandRemainingQuantityInWarehouses",            Parameters.HideCommandRemainingQuantityInWarehouses);
	FormParameters.Insert("UseItemHierarchySelection",    True);
	FormParameters.Insert("ToHideTheSettingOfTheSelection",                   True);
	FormParameters.Insert("UseSelectionByItemType",       True);
	FormParameters.Insert("UnavailabilityOfFilterByProductSegment", True);
	FormParameters.Insert("ShowSelectedGoods",                True);
	FormParameters.Insert("ToHideTheItem",                  True);
	FormParameters.Insert("HideManualDiscounts",                       True);
	FormParameters.Insert("Date",                                       CommonClient.SessionDate());
	FormParameters.Insert("HideExcisableGoods",                  TypeOfTaxationENVD);
	FormParameters.Insert("DisplayTheHideExcisableGoodsFlag",    TypeOfTaxationENVD);
	FormParameters.Insert("RequestQuantity",                      False);
	FormParameters.Insert("ProhibitionOfSetContent",          True);
	FormParameters.Insert("ProhibitionOfEditingSetPrice",             True);
	FormParameters.Insert("SelectionModeWithoutAmountParameters",          ?(Parameters.Property("SelectionModeWithoutAmountParameters"),
	                                                                        Parameters.SelectionModeWithoutAmountParameters,
	                                                                        False));
	
	Return FormParameters;
	
EndFunction

// Forms the structure of parameters for opening the form of applied discounts that are specific to the self-service subsystem.
//
// Returns:
//   Structure   - the formed structure of parameters.
//
Function AdditionalParametersAppliedDiscounts() Export

	Return New Structure("DoNotDisplayInformationAboutManualDiscounts", True);

EndFunction

// Generates an information label on the sales Plan document form for the selected cell.
//
// Parameters:
//  Item - FormTable - activated control.
//  Form    - ClientApplicationForm - the form for which actions are performed.
//
Procedure PlanSalesOfGoodsByPeriodWhenActivatingCell(Item, Form) Export
	
	Object = Form.Object;
	
	If Not Object.PlanByAmount Then
		Return;
	EndIf; 
	
	FormItems = Form.Items; // FormAllItems 
	
	CurrentData = FormItems.GoodsByPeriod.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf; 
	
	TotalByColumn = "";
	TotalByLine = NStr("vi = 'Toàn bộ theo dòng: %LineAmount_% %Currency%';
						|ru = 'Всего по строке: %LineAmount_% %Currency%';
						|en = 'Line total: %LineAmount_% %Currency%'; fa = 'Line total: %LineAmount_% %Currency%';
						|it = 'Totale per riga: %LineAmount_% %Currency%';
						|pl = 'Tylko w wierszu: %LineAmount_% %Currency%';
						|tr = 'Satır toplamı: %LineAmount_% %Currency%'");
		
	TotalByLine = StrReplace(TotalByLine, "%Currency%", String(Object.Currency));
	TotalByLine = StrReplace(TotalByLine, "%LineAmount_%", Format(CurrentData.Sum, "NFD=2; NZ=0,00"));	
	
	If Item.CurrentItem <> Undefined Then
		For Each ElmentPeriod In Form.TimeIntervals.FindRows(New Structure("Active_", True)) Do
			Period = ElmentPeriod; // FormField
			If Item.CurrentItem.Name = "GoodsByPeriodPrice_"+Period.ColumnName 
				Or Item.CurrentItem.Name = "ProductsByPeriodQuantity_"+Period.ColumnName 
				Or Item.CurrentItem.Name = "GoodsByPeriodSum_"+Period.ColumnName Then
				SumByColumn = Form["GoodsByPeriodSum_"+ Period.ColumnName];
				TotalByColumn = NStr("vi = 'Tổng trong kỳ %PeriodHeader_%: %SumByColumn% %Currency%';
									|ru = 'Всего за период %PeriodHeader_%: %SumByColumn% %Currency%';
									|en = 'Total for the period %PeriodHeader_%: %SumByColumn% %Currency%'; fa = 'Total for the period %PeriodHeader_%: %SumByColumn% %Currency%';
									|it = 'Totale per periodo %PeriodHeader_%: %SumByColumn% %Currency%';
									|pl = 'Razem za okres %PeriodHeader_%:%SumByColumn% %Currency%';
									|tr = 'Dönem toplamı %PeriodHeader_%: %SumByColumn% %Currency%'");
				TotalByColumn = StrReplace(TotalByColumn, "%PeriodHeader_%", Period.Title);
				TotalByColumn = StrReplace(TotalByColumn, "%SumByColumn%", Format(SumByColumn, "NFD=2; NZ=0,00"));
				TotalByColumn = StrReplace(TotalByColumn, "%Currency%", String(Object.Currency));
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Form.TotalByLineByColumn = TotalByLine + " " + TotalByColumn;
	
EndProcedure

// Populates the list of action selection when the divergence in Actpresentation 
//
// Parameters:
//  ChoiceList - ValueList - list to fill in
//  Discrepancies  - Number - detected discrepancies in the number in the line.
//  DiscrepanciesPostingMethod - EnumRef.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue - how will the impact of the differences on line.
//
Procedure FillInListOfSelectedActionsInCaseOfDivergence(ChoiceList, Discrepancies, DiscrepanciesPostingMethod) Export

	If Discrepancies > 0 Then
		
		ChoiceList.Add(PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered"));
		ChoiceList.Add(PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery"));
		
	ElsIf Discrepancies < 0 Then
		
		ChoiceList.Add(PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired"));
		ChoiceList.Add(PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired"));
		
	Else
		
		Return;
		
	EndIf;

EndProcedure

Procedure OpenProductBalancesAndAvailabilityReport(Form) Export
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("GenerateOnOpen",True);
	OpeningParameters.Insert("VariantKey","StockAvailability");
	
	Filter = New Structure;
	If ValueIsFilled(Form.ProductSegment) Then
		Filter.Insert("ProductSegment",Form.ProductSegment);
	EndIf;
	If Form.WarehouseIsDeterminedByTheAgreement Then
		If Form.FormName = "DataProcessor.SelfServiceWorkplacePartners.Form.CustomerShoppingCart" Then
			Filter.Insert("Warehouse",Form.Warehouse)
		Else
			Filter.Insert("Warehouse",Form.Object.Warehouse);
		EndIf;
	Else
		Filter.Insert("Warehouse",Form.Items.Warehouse.ChoiceList.Copy());
	EndIf;
	
	If Filter.Count() > 0 Then
		OpeningParameters.Insert("Filter",Filter);
	EndIf;
	
	OpenForm("Report.StockAvailability.Form.SelfServiceWorkplaceReportForm", OpeningParameters);
	
EndProcedure

#EndRegion

#Region AcceptanceCertificateFromClient

Function StructureOfBaseSelectionFormParameters() Export

	ParametersStructure = New Structure(
	"Partner,
	|Currency,
	|ContractIsNotRequired,
	|Contract,
	|BasisDocuments,
	|VATTaxation,
	|Organization,
	|Terms,
	|Partner,
	|Counterparty,
	|BusinessOperation,
	|PriceIncludesVAT,
	|TabularSectionIsNotEmpty,
	|TypeOfBaseDocumentForNonConformanceCertificate,
	|GoodsReceiptOption");
	
	Return ParametersStructure;

EndFunction

// Handler for changing the products table part in the "Implementation" document"
// 
// Parameters:
//  Form - ClientApplicationForm - the form of the document.
//  FoundRow - LineOfATabularSection - 
//
Procedure ProductsImplementationWhenChanged(Form, FoundRow = Undefined) Export
	
	CurrentData = Form.Items.Goods.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(CurrentData.SaleOfGoodsAndServices) Then
		CurrentData.Warehouse        = PredefinedValue("Catalog.Warehouses.EmptyRef");
		CurrentData.SalesOrder = PredefinedValue("Document.SalesOrder.EmptyRef");
		Return;
	EndIf;
	
	FoundRows = Form.BasisDocuments.FindRows(New Structure("SaleOfGoodsAndServices", CurrentData.SaleOfGoodsAndServices));
	If FoundRows.Count() = 0 Then
		CurrentData.Warehouse        = PredefinedValue("Catalog.Warehouses.EmptyRef");
		CurrentData.SalesOrder = PredefinedValue("Document.SalesOrder.EmptyRef");
		Return;
	EndIf;
	
	FoundRow = FoundRows[0];

	If ValueIsFilled(CurrentData.SalesOrder) Then
		If FoundRow.BasisOrders.FindByValue(CurrentData.SalesOrder) = Undefined Then
			CurrentData.SalesOrder = PredefinedValue("Document.SalesOrder.EmptyRef");
		EndIf;
	EndIf;
	
	If ValueIsFilled(CurrentData.Warehouse) Then
		If FoundRow.BasisWarehouses.FindByValue(CurrentData.Warehouse) = Undefined Then
			CurrentData.Warehouse = PredefinedValue("Catalog.Warehouses.EmptyRef");
		EndIf;
	EndIf;
	
	SelfServiceClientServer.SetDocumentBasedOnOrderAttribute(CurrentData, FoundRow, True);
	SelfServiceClientServer.FillInOrderAndWarehouseInLine(CurrentData, Form.BasisDocuments, True);
	
EndProcedure

// Sets the action option for the selected lines of the discrepancy report
// 
// Parameters:
//  Form           - ClientApplicationForm                                          - the form of the document.
//  PossibleAction - EnumRef.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue - action to set.
//
Procedure SetActionOption(Form, PossibleAction) Export
	
	NumberOfRowsChanged = 0;
	
	For Each SelectedRow In Form.Items.Goods.SelectedRows Do
		
		CurrentData = Form.Object.Goods.FindByID(SelectedRow);
		If CurrentData["Action"] = PossibleAction Then
			Continue;
		EndIf;
		
		If PossibleAction = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery")
			Or PossibleAction = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered")
			Or PossibleAction = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnWithoutRegistration")
			Or PossibleAction = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage") Then
			
			If Not CurrentData.NumberOfDiscrepancyPackaging > 0  Then
				Continue;
			EndIf;
			
		ElsIf PossibleAction = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired")
			Or PossibleAction = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired")
			Or PossibleAction = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow")
			Or PossibleAction = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial") Then
			
			If Not CurrentData.NumberOfDiscrepancyPackaging < 0 Then
				Continue;
			EndIf;
			
		EndIf;
		
		CurrentData["Action"]  = PossibleAction;
		NumberOfRowsChanged = NumberOfRowsChanged + 1;
		
	EndDo;
	
	NotificationText1 =  NStr("vi = 'Thiết lập phương án thao tác trong dòng';
								|ru = 'Установка варианта действия строк';
								|en = 'Set line validity option'; fa = 'Set line validity option';
								|it = 'Impostazione dell''opzione di validità delle righe';
								|pl = 'Ustawianie opcji ważności termin';
								|tr = 'Satış işlemi seçeneğinin ayarlanması'");
	ExplanationText = NStr("vi = 'Dòng có đặt phương án thao tác %Action%: %RowsCount%.';
							|ru = 'Строк, у которых установлен вариант действия %Action%: %RowsCount%.';
							|en = 'Lines for which possible action %Action% is set: %RowsCount%.'; fa = 'Lines for which possible action %Action% is set: %RowsCount%.';
							|it = 'Righe per cui è stata impostata l''opzione di azione %Action%: %RowsCount%.';
							|pl = 'Wierszy, w których zainstalowana opcja czynności %Action%: %RowsCount%.';
							|tr = 'İşlem seçeneği ayarlanmış olan satırlar %Action%: %RowsCount%.'");
	ExplanationText = StrReplace(ExplanationText, "%action%", String(PossibleAction));
	ExplanationText = StrReplace(ExplanationText, "%RowsCount%", String(NumberOfRowsChanged));
	
	ShowUserNotification(NotificationText1,,ExplanationText);

EndProcedure

// Handler for starting a comment selection in a document
// 
// Parameters:
//  Form - ClientApplicationForm - the form of the document.
//
Procedure CustomerCommentStartOfSelection(Form) Export

	CurrentData = Form.Items.Goods.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CurrentData", CurrentData);
	AdditionalParameters.Insert("AttributeNameComment", "CustomerComment");
	AdditionalParameters.Insert("PropsNameHasComment", "ThereIsACustomerComment");
	AdditionalParameters.Insert("Form", Form);

	CallbackDescriptionCompletion = New CallbackDescription("EditCommentCompletion", ThisObject, AdditionalParameters);
	CommonClient.ShowMultilineTextEditingForm(CallbackDescriptionCompletion, CurrentData.CustomerComment);
	

EndProcedure

Procedure EditCommentCompletion(EditResult, AdditionalParameters) Export
	
	If EditResult = Undefined Then
		Return;
	EndIf;
		
	If EditResult <> AdditionalParameters.CurrentData[AdditionalParameters.AttributeNameComment] Then
		AdditionalParameters.CurrentData[AdditionalParameters.AttributeNameComment]     = EditResult;
		AdditionalParameters.CurrentData[AdditionalParameters.PropsNameHasComment] = Not IsBlankString(EditResult);
		AdditionalParameters.Form.Modified = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region Print

// Displays the printed form of the "Customer Order" document by default
//
// Parameters:
//  PrintObject  - DocumentRef.SalesOrder, Array - documents whose printed forms are displayed.
//
Procedure PrintOrderDocument(PrintObject) Export

	PrintManagementClient.ExecutePrintCommand(
		"DataProcessor.PrintOrderForGoodsServices",
		"SalesOrder",
		PrintData(PrintObject),
		Undefined,
		Undefined);
	
EndProcedure

// Displays the printed form of the "Customer Order" document by default
//
// Parameters:
//  PrintObject  - DocumentRef.SalesOrder, Array - documents whose printed forms are displayed.
//
Procedure PrintDocumentPlan(PrintObject) Export
	
	PrintParameters = New Structure;
	PrintParameters.Insert("OutputScript"     , False);
	PrintParameters.Insert("OutputDivision", False);
	PrintParameters.Insert("WithdrawVHFAgreement", False);
	PrintParameters.Insert("DisplayVHFWarehouse"     , False);
	PrintParameters.Insert("WithdrawVHFPartner"  , False);
	
	PrintManagementClient.ExecutePrintCommand(
	    "Document.SalesPlan",
	    "SalesPlan",
	     PrintData(PrintObject),
	     Undefined,
	     PrintParameters);
	
EndProcedure

// Displays the printed form of the document "Request for return of goods from the customer" by default.
//
// Parameters:
//  PrintObject  - DocumentRef.RequestForReturnOfGoodsFromCustomer, Array - documents whose printed forms are displayed.
//
Procedure PrintDocumentRequestForRefund(PrintObject) Export

	PrintManagementClient.ExecutePrintCommand(
		"Document.RequestForReturnOfGoodsFromCustomer",
		"ReturnRequest",
		PrintData(PrintObject),
		Undefined,
		Undefined);
		
EndProcedure

// Displays the printed form of the document "Act of completed works" by default
//
// Parameters:
//  PrintObject  - DocumentRef.CustomerInvoiceServices, Array - documents whose printed forms are displayed.
//
Procedure PrintCertificateOfCompletedWorks(PrintObject) Export

	PrintManagementClient.ExecutePrintCommand(
		"Document.CustomerInvoiceServices",
		"Act",
		PrintData(PrintObject),
		Undefined,
		Undefined);

EndProcedure

// Displays the printed form of the document "Sale of goods and services" by default
//
// Parameters:
//  PrintObject  - DocumentRef.CustomerInvoice, Array - documents whose printed forms are displayed.
//
Procedure PrintingSaleOfGoodsServices(PrintObject) Export

	PrintManagementClient.ExecutePrintCommand(
	         "Document.CustomerInvoice",
	         "Invoice",
	         PrintData(PrintObject),
	         Undefined,
	         Undefined);
	
EndProcedure

// Displays the printed form of the document "Sale of goods and services" by default
//
// Parameters:
//  PrintObject  - DocumentRef.CustomerInvoice, Array - documents whose printed forms are displayed.
//
Procedure PrintInvoiceForPayment(PrintObject) Export

	PrintManagementClient.ExecutePrintCommand(
		"DataProcessor.PrintCommercialInvoices",
		"ProformaInvoice",
		PrintData(PrintObject),
		Undefined,
		New Structure("Presentation", NStr("vi = 'Yêu cầu thanh toán';
											|ru = 'Счет на оплату';
											|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
											|it = 'Fattura di pagamento';
											|pl = 'Rachunek do zapłaty';
											|tr = 'Ticari fatura'")));
	
EndProcedure

// Displays the printed form of the client's claim
//
// Parameters:
//  PrintObject  - CatalogRef.Complaints, Array of CatalogRef.Complaints - claims, printed forms of which are displayed.
//
Procedure PrintCustomerClaim(PrintObject) Export

	PrintManagementClient.ExecutePrintCommand(
		"Catalog.Complaints",
		"Claim",
		PrintData(PrintObject),
		Undefined,);
	
EndProcedure

// Displays the printed form of the "Customer Order" document by default
//
// Parameters:
//  PrintObject  - DocumentRef.SalesOrder, Array - documents whose printed forms are displayed.
//
Procedure PrintDocumentCommissionAgentSReport(PrintObject) Export
	
	PrintManagementClient.ExecutePrintCommand(
		"DataProcessor.PrintCommissionReports",
		"ConsignmentReportFromCustomer",
		PrintData(PrintObject),
		Undefined,
		Undefined);
	
EndProcedure

// Displays the printed form of the "Sales Agreement" by default
//
// Parameters:
//  PrintObject  - CatalogRef.TermsOfSale, Array of CatalogRef.TermsOfSale - agreements, printed forms of which are displayed.
//
Procedure PrintClientAgreement(PrintObject) Export
	
	PrintManagementClient.ExecutePrintCommand(
		"Catalog.TermsOfSale",
		"CustomerTermsOfSales",
		PrintData(PrintObject),
		Undefined,
		Undefined);
	
EndProcedure



Function PrintData(PrintObject)

	If Not TypeOf(PrintObject)= Type("Array") Then
		ArrayOfPrintObjects = New Array;
		ArrayOfPrintObjects.Add(PrintObject);
		Return ArrayOfPrintObjects;
	Else
		Return PrintObject;
	EndIf;

EndFunction

#EndRegion

#EndRegion
