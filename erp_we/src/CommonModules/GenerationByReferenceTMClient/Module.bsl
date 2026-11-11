
#Region Public

#Region OrdersForTransferToProduction

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CreateProductionTransferOrders(ReferencesArrray, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	FormParameters = New Structure();
	
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		FormParameters.Insert("OrderDocument", ReferencesArrray);
	Else
		FormParameters.Insert("OrderDocument", ReferencesArrray[0]);
	EndIf;
	
	OpenForm("DataProcessor.GenerationOfTransferToProductionOrdersByReference.Form",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
	
EndProcedure
#EndRegion

#Region PurchaseOrders

// Handler for the connected command.
//
// Parameters:
//   DocumentBasis - DocumentObject - The document that the command is being executed for.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure GenerationOfPurchaseOrdersByReference(DocumentBasis, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	GenerationByReferenceTMServerCall.CheckPossibilityOfEnteringBasedOn(DocumentBasis);
	FormParameters = New Structure("DocumentBasis", DocumentBasis);
	OpenForm(
		"Document.PurchaseOrder.Form.GenerationOfPurchaseOrdersByReference", FormParameters,
		CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
EndProcedure

#EndRegion

#Region ProformaInvoice

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CreatePaymentInvoice(ReferencesArrray, ExecutionParameters) Export
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		CommandParameter = ReferencesArrray;
	Else
		CommandParameter = ReferencesArrray[0];
	EndIf;
	
	DocumentBasis = SalesServerCall.GetBasisForPaymentInvoice(CommandParameter);
	FormParameters = New Structure("Basis", DocumentBasis);
	
	OpenForm(
		"Document.CustomerCommercialInvoice.Form.CommercialInvoiceCreationForm",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);

EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CreateInvoiceForPaymentImplementationReport(ReferencesArrray, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);

	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		CommandParameter = ReferencesArrray;
	Else
		CommandParameter = ReferencesArrray[0];
	EndIf;

	FormOpenParameters = GenerationByReferenceTMServerCall.InvoiceImplementationReportGetFormOpeningParameters(CommandParameter);
	
	If FormOpenParameters = Undefined Then
		
		ErrorText = NStr("vi = '%Document% đã lập theo nhiều đơn hàng. Cần nhập hóa đơn thanh toán trên cơ sở đơn hàng.';
						|ru = '%Document% оформлена по нескольким заказам. Необходимо ввести счет на оплату на основании заказов.';
						|en = '%Document% is created by several orders. Enter the commercial invoice according to the orders.'; fa = '%Document% is created by several orders. Enter the commercial invoice according to the orders.';
						|it = '%Document% è stato emesso in base a più ordini. È necessario inserire la fattura per il pagamento in base agli ordini.';
						|pl = '%Document% jest sporządzona dla kilku zamówień. Należy wprowadzić rachunek do zapłaty na podstawie zamówień.';
						|tr = '%Document% birden fazla sipariş için düzenlenmiştir. Siparişlere göre ödeme için bir fatura girilmesi gerekmektedir.'");
		ErrorText = StrReplace(ErrorText, "%Document%", CommandParameter);
	
		Raise ErrorText;
		
	EndIf;
	
	OpenForm(
		FormOpenParameters.FormName,
		FormOpenParameters.FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);

EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CommercialInvoiceDebt(ReferencesArrray, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		CommandParameter = ReferencesArrray;
	Else
		CommandParameter = ReferencesArrray[0];
	EndIf;
	
	If Not GenerationByReferenceTMServerCall.InvoiceForPaymentUnderAgreementCheckWhetherInvoicesCanBeCreated(CommandParameter) Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập hóa đơn thanh toán trên cơ sở hợp đồng %1. Việc hạch toán được thực hiện theo đơn hàng / hóa đơn.';
				|ru = 'Не требуется вводить счет на оплату на основании договора %1. Расчеты ведутся по заказам / накладным.';
				|en = 'It is not required to enter a commercial invoice based on document %1. Settlements are made based on orders / invoices.'; fa = 'It is not required to enter a commercial invoice based on document %1. Settlements are made based on orders / invoices.';
				|it = 'Non è necessario inserire la fattura di pagamento in base al contratto. %1 I regolamenti si effettuano in base agli ordini / bolle.';
				|pl = 'Nie jest wymagane wprowadzanie rachunku do zapłaty na podstawie umowy %1. Rozliczenia są wykonywane na podstawie zamówień / listów przewozowych.';
				|tr = 'Ticari faturanın sözleşme esasında girilmesine gerek yoktur %1. Ödemeler sipariş / irsaliyelere göre yapılmakta.'"),
			CommandParameter);
		Raise Text;
	EndIf;
	
	FormParameters = New Structure("Basis", CommandParameter);
	
	OpenForm(
		"Document.CustomerCommercialInvoice.Form.CommercialInvoiceCreationForm",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	

EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CommercialInvoicePrepayment(ReferencesArrray, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		CommandParameter = ReferencesArrray;
	Else
		CommandParameter = ReferencesArrray[0];
	EndIf;
	
	If Not GenerationByReferenceTMServerCall.InvoiceForPaymentUnderAgreementCheckWhetherInvoicesCanBeCreated(CommandParameter) Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập hóa đơn thanh toán trên cơ sở hợp đồng %1. Việc hạch toán được thực hiện theo đơn hàng / hóa đơn.';
				|ru = 'Не требуется вводить счет на оплату на основании договора %1. Расчеты ведутся по заказам / накладным.';
				|en = 'It is not required to enter a commercial invoice based on document %1. Settlements are made based on orders / invoices.'; fa = 'It is not required to enter a commercial invoice based on document %1. Settlements are made based on orders / invoices.';
				|it = 'Non è necessario inserire la fattura di pagamento in base al contratto. %1 I regolamenti si effettuano in base agli ordini / bolle.';
				|pl = 'Nie jest wymagane wprowadzanie rachunku do zapłaty na podstawie umowy %1. Rozliczenia są wykonywane na podstawie zamówień / listów przewozowych.';
				|tr = 'Ticari faturanın sözleşme esasında girilmesine gerek yoktur %1. Ödemeler sipariş / irsaliyelere göre yapılmakta.'"),
			CommandParameter);
		Raise Text;
	EndIf;
	
	FormParameters = New Structure("Basis", CommandParameter);
	
	OpenForm(
		"Document.CustomerCommercialInvoice.Form.DocumentForm",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);

EndProcedure


// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CreateInvoiceForPaymentForGiverSOrder(ReferencesArrray, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure;
	CommandExecuteParameters.Insert("Source");
	CommandExecuteParameters.Insert("Uniqueness");
	CommandExecuteParameters.Insert("Window");
	CommandExecuteParameters.Insert("URL");
	
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		CommandParameter = ReferencesArrray;
		FormParameters = New Structure("Basis", CommandParameter);
	Else
		CommandParameter = ReferencesArrray[0];
		DocumentBasis = SalesServerCall.GetBasisForPaymentInvoice(ReferencesArrray[0]);
		FormParameters = New Structure("Basis", DocumentBasis);
	EndIf;
	
	FormParameters = New Structure("Basis", CommandParameter);
	
	OpenForm(
		"Document.CustomerCommercialInvoice.Form.CommercialInvoiceCreationForm",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);

EndProcedure

// Handler for the connected command.
// 
// Parameters:
//  ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//  ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
Procedure CreateInvoiceForPaymentReportToGiver2_5(ReferencesArrray, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		CommandParameter = ReferencesArrray;
	Else
		CommandParameter = ReferencesArrray[0];
	EndIf;
	
	FormOpenParameters =
		GenerationByReferenceTMServerCall.InvoiceForPaymentReportGiver2_5GetFormOpeningParameters(CommandParameter);
	
	If FormOpenParameters = Undefined Then
		
		ErrorText = StrTemplate(
			NStr("vi = '%1 đã lập theo nhiều đơn hàng. Cần nhập hóa đơn thanh toán trên cơ sở đơn hàng.';
				|ru = '%1 оформлен по нескольким заказам. Необходимо ввести счет на оплату на основании заказов.';
				|en = '%1 is registered under several orders. Enter the commercial invoice based on the orders.'; fa = '%1 is registered under several orders. Enter the commercial invoice based on the orders.';
				|it = '%1 formalizzato per diversi ordini. Inserire la fattura per il pagamento in base agli ordini.';
				|pl = '%1 jest utworzony dla kilku zamówień. Należy wprowadzić rachunek do zapłaty na podstawie zamówień.';
				|tr = '%1 birden fazla sipariş için düzenlenmiştir. Siparişlere göre ödeme için bir fatura girilmesi gerekmektedir.'"),
			CommandParameter);
	
		Raise ErrorText;
		
	EndIf;
	
	OpenForm(
		FormOpenParameters.FormName,
		FormOpenParameters.FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);

EndProcedure

#EndRegion

#Region DocumentsBasedOnOrder

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CreateActOfCompletedWorksOnBasisOfOrder(ReferencesArrray, ExecutionParameters) Export

	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	ClearMessages();
	
	OpeningParameters = GenerationByReferenceTMServerCall.ReportOfCompletedWorkFormOpeningParameters(ReferencesArrray);
	If OpeningParameters <> Undefined Then
	
		OpenForm(
			"Document.CustomerInvoiceServices.Form.DocumentForm",
			OpeningParameters,
			CommandExecuteParameters.Source,
			CommandExecuteParameters.Uniqueness,
			CommandExecuteParameters.Window,
			CommandExecuteParameters.URL);
			
	EndIf;

EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CreateInternalConsumptionBasedOnOrder(ReferencesArrray, ExecutionParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"CommonModule.GenerationByReferenceTMClient.CreateInternalConsumptionBasedOnOrder");
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	OpeningParameters =
		GenerationByReferenceTMServerCall.ParametersForOpeningInvoiceFormBasedOnOrder(
			ReferencesArrray,
			"InventoryConsumption");
	If OpeningParameters.FormParameters.Property("Basis") Then
		OpeningParameters.FormParameters.Basis.Insert("FilterByWarehouse", False);
	EndIf;
	
	ClearMessages();

	OpenForm(
		OpeningParameters.FormName,
		OpeningParameters.FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL,,
		OpeningParameters.FormWindowOpeningMode);
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure ReceiptOfGoodsFromCustodianToCreateOnBasisOfOrder(ReferencesArrray, ExecutionParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"CommonModule.GenerationByReferenceTMClient.ReceiptOfGoodsFromCustodianToCreateOnBasisOfOrder");
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	OpeningParameters = GenerationByReferenceTMServerCall.ParametersForOpeningInvoiceFormBasedOnOrder(ReferencesArrray,
																											"ReceiptOfGoodsFromCustodian");
	
	ClearMessages();

	OpenForm(
		OpeningParameters.FormName,
		OpeningParameters.FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL,,
		OpeningParameters.FormWindowOpeningMode);
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure ReceiptOfGoodsFromCommissionAgentToCreateOnBasisOfOrder(ReferencesArrray, ExecutionParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"CommonModule.GenerationByReferenceTMClient.ReceiptOfGoodsFromCustodianToCreateOnBasisOfOrder");
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	OpeningParameters = GenerationByReferenceTMServerCall.ParametersForOpeningInvoiceFormBasedOnOrder(ReferencesArrray,
						"ReceiptOfGoodsFromCustodian",PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent"));
	
	ClearMessages();

	OpenForm(
		OpeningParameters.FormName,
		OpeningParameters.FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL,,
		OpeningParameters.FormWindowOpeningMode);
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure PurchaseOfGoodsServicesCreateOnBasisOfOrder(ReferencesArrray, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	OpeningParameters = GenerationByReferenceTMServerCall.PurchaseOfGoodsAndServicesFormOpeningParameters(ReferencesArrray);
	If OpeningParameters = Undefined Then
		Return;
	EndIf;
	
	ClearMessages();

	OpenForm(
		"Document.VendorInvoice.Form.DocumentForm",
		OpeningParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);

EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure AssemblyOfGoodsCreateOnBasisOfOrder(ReferencesArrray, ExecutionParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"CommonModule.GenerationByReferenceTMClient.AssemblyOfGoodsCreateOnBasisOfOrder");
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	OpeningParameters = GenerationByReferenceTMServerCall.ParametersForOpeningInvoiceFormBasedOnOrder(ReferencesArrray,
		"AssemblyFromComponents");
	
	ClearMessages();

	OpenForm(
		OpeningParameters.FormName,
		OpeningParameters.FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL,,
		OpeningParameters.FormWindowOpeningMode);
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure SaleOfGoodsAndServicesCreatedOnBasisOfOrder(ReferencesArrray, ExecutionParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"CommonModule.GenerationByReferenceTMClient.SaleOfGoodsAndServicesCreatedOnBasisOfOrder");
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	ClearMessages();
	
	OpeningParameters = GenerationByReferenceTMServerCall.SalesOfGoodsAndServicesFormOpeningParameters(ReferencesArrray);
	
	If Not OpeningParameters = Undefined Then
	
		OpenForm(
			"Document.CustomerInvoice.Form.DocumentForm",
			OpeningParameters,
			CommandExecuteParameters.Source,
			CommandExecuteParameters.Uniqueness,
			CommandExecuteParameters.Window,
			CommandExecuteParameters.URL);
		
	EndIf;
		
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure TransferOfOwnershipBasedOnOrder(ReferencesArrray, ExecutionParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"CommonModule.GenerationByReferenceTMClient.TransferOfOwnershipBasedOnOrder",, True);
	
	CommandExecuteParameters = CommandExecuteParameters();
	FillPropertyValues(CommandExecuteParameters,
		ExecutionParameters.CommandDetails.AdditionalParameters);
	
	ClearMessages();
	
	OpeningParameters = GenerationByReferenceTMServerCall.TransferOfOwnershipFormOpeningParameters(
		ReferencesArrray);
	
	If Not OpeningParameters = Undefined Then
	
		OpenForm(
			"Document.CustomerInvoice.Form.DocumentForm",
			OpeningParameters,
			CommandExecuteParameters.Source,
			CommandExecuteParameters.Uniqueness,
			CommandExecuteParameters.Window,
			CommandExecuteParameters.URL);
		
	EndIf;
		
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure ShipmentOfItemsToCustomerToCreateBasedOn(ReferencesArrray, ExecutionParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"CommonModule.GenerationByReferenceTMClient.ShipmentOfItemsToCustomerToCreateBasedOn",, True);
	
	CommandExecuteParameters = CommandExecuteParameters();
	FillPropertyValues(CommandExecuteParameters,
		ExecutionParameters.CommandDetails.AdditionalParameters);
	
	ClearMessages();
	
	OpeningParameters = GenerationByReferenceTMServerCall.ShipmentOfItemsToClientFormOpeningParameters(
		ReferencesArrray);
	
	If Not OpeningParameters = Undefined Then
	
		OpenForm(
			"Document.GoodsShipmentToCustomer.Form.DocumentForm",
			OpeningParameters,
			CommandExecuteParameters.Source,
			CommandExecuteParameters.Uniqueness,
			CommandExecuteParameters.Window,
			CommandExecuteParameters.URL);
		
	EndIf;
		
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure MovementOfGoodsCreateOnBasisOfOrder(ReferencesArrray, ExecutionParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"CommonModule.GenerationByReferenceTMClient.MovementOfGoodsCreateOnBasisOfOrder");
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	OpeningParameters = GenerationByReferenceTMServerCall.ParametersForOpeningInvoiceFormBasedOnOrder(ReferencesArrray,
		"InventoryTransfer");
	
	ClearMessages();

	OpenForm(
		OpeningParameters.FormName,
		OpeningParameters.FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL,,
		OpeningParameters.FormWindowOpeningMode);
	
EndProcedure


// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure MovementOfProductsAndMaterialsCreateTransferToPantryBasedOnOrder(ReferencesArrray, ExecutionParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"CommonModule.GenerationByReferenceTMClient.MovementOfProductsAndMaterialsCreateTransferToPantryBasedOnOrder");
	
	CommandExecuteParameters = New Structure("Source, Uniqueness, Window, URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	OpeningParameters = GenerationByReferenceTMServerCall.ParametersForOpeningInvoiceFormBasedOnOrder(ReferencesArrray,
		"MovementOfProductsAndMaterials", PredefinedValue("Enum.BusinessTransactions.TransferOfMaterialsToStoreroom"));
	
	ClearMessages();

	OpenForm(
		OpeningParameters.FormName,
		OpeningParameters.FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL,,
		OpeningParameters.FormWindowOpeningMode);
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure MovementOfProductsAndMaterialsCreateTransferOutOfProductionBasedOnOrder(ReferencesArrray, ExecutionParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"CommonModule.GenerationByReferenceTMClient.MovementOfProductsAndMaterialsCreateTransferOutOfProductionBasedOnOrder");
	
	CommandExecuteParameters = New Structure("Source, Uniqueness, Window, URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	OpeningParameters = GenerationByReferenceTMServerCall.ParametersForOpeningInvoiceFormBasedOnOrder(ReferencesArrray,
		"MovementOfProductsAndMaterials", PredefinedValue("Enum.BusinessTransactions.TransferOfProductsFromProduction"));
	
	ClearMessages();

	OpenForm(
		OpeningParameters.FormName,
		OpeningParameters.FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL,,
		OpeningParameters.FormWindowOpeningMode);
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure MovementOfProductsAndMaterialsCreateTransferToProductionBasedOnOrder(ReferencesArrray, ExecutionParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"CommonModule.GenerationByReferenceTMClient.MovementOfProductsAndMaterialsCreateTransferToProductionBasedOnOrder");
	
	CommandExecuteParameters = New Structure("Source, Uniqueness, Window, URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	OpeningParameters = GenerationByReferenceTMServerCall.ParametersForOpeningInvoiceFormBasedOnOrder(ReferencesArrray,
		"MovementOfProductsAndMaterials", PredefinedValue("Enum.BusinessTransactions.MaterialTransferToProduction"));
	
	ClearMessages();

	OpenForm(
		OpeningParameters.FormName,
		OpeningParameters.FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL,,
		OpeningParameters.FormWindowOpeningMode);
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure MovementOfProductsAndMaterialsCreateReturnFromProductionBasedOnOrder(ReferencesArrray, ExecutionParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"CommonModule.GenerationByReferenceTMClient.MovementOfProductsAndMaterialsCreateReturnFromProductionBasedOnOrder");
	
	CommandExecuteParameters = New Structure("Source, Uniqueness, Window, URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	OpeningParameters = GenerationByReferenceTMServerCall.ParametersForOpeningInvoiceFormBasedOnOrder(ReferencesArrray,
		"MovementOfProductsAndMaterials", PredefinedValue("Enum.BusinessTransactions.ReturnOfMaterialsFromProduction"));
	
	ClearMessages();

	OpenForm(
		OpeningParameters.FormName,
		OpeningParameters.FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL,,
		OpeningParameters.FormWindowOpeningMode);
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure TransferOfGoodsToCustodianIsCarriedOutOnBasisOfOrder(ReferencesArrray, ExecutionParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"CommonModule.GenerationByReferenceTMClient.TransferOfGoodsToCustodianIsCarriedOutOnBasisOfOrder");
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	ClearMessages();
	
	OpeningParameters = GenerationByReferenceTMServerCall.TransferOfGoodsToCustodianFormOpeningParameters(ReferencesArrray);
	
	If Not OpeningParameters = Undefined Then
		
		OpenForm("Document.TransferOfGoodsToBailee.Form.DocumentForm",
					OpeningParameters,
					CommandExecuteParameters.Source,
					CommandExecuteParameters.Uniqueness,
					CommandExecuteParameters.Window,
					CommandExecuteParameters.URL);
		
	EndIf;
	
EndProcedure


// Handler for the connected command.
//
// Parameters:
//  ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//  ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure ShipmentOfGoodsFromStorageTransferToGiverCreateOnBasisOfOrder(ReferencesArrray, ExecutionParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"CommonModule.GenerationByReferenceTMClient.ShipmentOfGoodsFromStorageTransferToGiverCreateOnBasisOfOrder");
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	OpeningParameters =
		GenerationByReferenceTMServerCall.ShipmentOfGoodsFromStorageTransferOfFormOpeningParametersToGiver(ReferencesArrray);
	
	If Not OpeningParameters = Undefined Then
		
		ClearMessages();

		OpenForm(
			"Document.GoodsShipmentFromStorage.Form.DocumentForm",
			OpeningParameters,
			CommandExecuteParameters.Source,
			CommandExecuteParameters.Uniqueness,
			CommandExecuteParameters.Window,
			CommandExecuteParameters.URL);
		
	EndIf;
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//  ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//  ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure ShipmentOfGoodsFromStorageRefundGiverCreateOnBasisOfOrder(ReferencesArrray, ExecutionParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"CommonModule.GenerationByReferenceTMClient.ShipmentOfGoodsFromStorageRefundGiverCreateOnBasisOfOrder");
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	OpeningParameters =
		GenerationByReferenceTMServerCall.ShipmentOfGoodsFromStorageReturnToGiverFormOpeningParameters(ReferencesArrray);
	
	If Not OpeningParameters = Undefined Then
		
		ClearMessages();

		OpenForm(
			"Document.GoodsShipmentFromStorage.Form.DocumentForm",
			OpeningParameters,
			CommandExecuteParameters.Source,
			CommandExecuteParameters.Uniqueness,
			CommandExecuteParameters.Window,
			CommandExecuteParameters.URL);
		
	EndIf;
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//  ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//  ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure ShipmentOfGoodsFromStorageReturnOfRepairedFINISHEDProductBasedOnOrder(ReferencesArrray, ExecutionParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"CommonModule.GenerationByReferenceTMClient.ShipmentOfGoodsFromStorageReturnOfRepairedFINISHEDProductBasedOnOrder");
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	OpeningParameters =
		GenerationByReferenceTMServerCall.ShipmentOfGoodsFromStorageReturnOfRepairedFinishedProductFormOpeningParameters(ReferencesArrray);
	
	If Not OpeningParameters = Undefined Then
		
		ClearMessages();
		
		OpenForm(
			"Document.GoodsShipmentFromStorage.Form.DocumentForm",
			OpeningParameters,
			CommandExecuteParameters.Source,
			CommandExecuteParameters.Uniqueness,
			CommandExecuteParameters.Window,
			CommandExecuteParameters.URL);
		
	EndIf;
	
EndProcedure

// The connection handler for the command to create a payment card transaction based on the document for a business transaction
// for the refund of payment.
//
// Parameters:
//	ReferencesArrray - Array - array of object references for which the handler is executed.
//	ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters.
//
Procedure PaymentCardOperation_Refund(ReferencesArrray, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure("Source, Uniqueness, Window, URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	FormParameters = GenerationByReferenceTMServerCall.PaymentCardOperation_ReturnFillingParameters(ReferencesArrray);
	
	OpenForm("Document.PaymentCardTransaction.Form.DocumentForm",
					FormParameters,
					CommandExecuteParameters.Source,
					CommandExecuteParameters.Uniqueness,
					CommandExecuteParameters.Window,
					CommandExecuteParameters.URL);	
	
EndProcedure

#EndRegion

#Region SaleApproval

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CreateNewSalesOrderApprovalProcess(ReferencesArrray, ExecutionParameters) Export

	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		Basis = ReferencesArrray;
	Else
		Basis = ReferencesArrray[0];
	EndIf;
	
	OpenForm("BusinessProcess.SaleApproval.ObjectForm",
	New Structure("Basis", Basis),
	,
	,);

EndProcedure 

#EndRegion 

#Region PurchaseApproval

Procedure CreateNewPurchaseOrderApprovalProcess(ReferencesArrray, ExecutionParameters) Export

	OpenForm("BusinessProcess.PurchaseApproval.ObjectForm",
	New Structure("Basis",ReferencesArrray),
	,
	,);

EndProcedure 

#EndRegion 


// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure RelatedObjectsCreation(ReferencesArrray, ExecutionParameters) Export

	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	CommandExecuteParameters.Source = ExecutionParameters.Form;
	
	AdditionalReportsAndDataProcessorsClient.OpenAdditionalReportAndDataProcessorCommandsForm(
		ReferencesArrray,
		CommandExecuteParameters,
		AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindRelatedObjectCreation());

EndProcedure 

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure DefineReferencePlacementByCells(ReferencesArrray, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		CommandParameter = ReferencesArrray;
	Else
		CommandParameter = ReferencesArrray[0];
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("Documentreceivings",CommandParameter);
	OpenForm("DataProcessor.ReferenceAddressWarehousingOfProducts.Form.Form",Parameters,CommandExecuteParameters.Source,CommandParameter);

EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure TransferToOperationOnBasisOf(ReferencesArrray, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		CommandParameter = ReferencesArrray;
	Else
		CommandParameter = ReferencesArrray[0];
	EndIf;
	
	Basis = New Structure;
	Basis.Insert("DocumentBasis", CommandParameter);
	Basis.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.TransferToOperation"));
	
	FormParameters = New Structure("Basis", Basis);
	
	OpenForm(
		"Document.InventoryConsumption.ObjectForm",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);

EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure WriteOffForExpensesAssetsBasedOn(ReferencesArrray, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		CommandParameter = ReferencesArrray;
	Else
		CommandParameter = ReferencesArrray[0];
	EndIf;
	
	Basis = New Structure;
	Basis.Insert("DocumentBasis", CommandParameter);
	Basis.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand"));
	
	FormParameters = New Structure("Basis", Basis);
	
	OpenForm(
		"Document.InventoryConsumption.ObjectForm",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);

EndProcedure


	
// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CreateSpendingOrderForGoodsBasedOnIt(ReferencesArrray, ExecutionParameters) Export
	
	ClearMessages();
	
	ReferenceArray = New Array;
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		ReferenceArray.Add(ReferencesArrray);
	Else
		ReferenceArray = ReferencesArrray;
	EndIf;
		
	OpenForm("DataProcessor.ShipGoodsFromWarehouse.Form.SettingsFormOfGoodsIssueNotesCreation",New Structure("ReferenceArray",ReferenceArray),,,,,);	
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure DeedOfTransfer(ReferencesArrray, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		CommandParameter = ReferencesArrray;
	Else
		CommandParameter = ReferencesArrray[0];
	EndIf;
	
	FormName = "Document.CustomerInvoice.Form.DocumentForm";
	
	BasisParameters = New Structure;
	
	BasisParameters.Insert("DocumentBasis",   CommandParameter);
	BasisParameters.Insert("FillInByLeftovers", True);
	BasisParameters.Insert("SaleRegistrationOption",
	PredefinedValue("Enum.SalesRegistrationOptions.DeedOfTransfer"));
	
	OpenForm(FormName, New Structure("Basis", BasisParameters));

EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CreateOrderForInternalConsumption(ReferencesArrray, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		CommandParameter = ReferencesArrray;
	Else
		CommandParameter = ReferencesArrray[0];
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("CreatedDocumentKind", "InventoryConsumptionOrder");
	FormParameters.Insert("DocumentBasis", CommandParameter);
	OpenForm("DataProcessor.WizardOfWarehouseDocumentGenerationForRemovingFromProductRange.Form.Form",
					FormParameters,
					CommandExecuteParameters.Source,
					CommandExecuteParameters.Uniqueness,
					CommandExecuteParameters.Window);

EndProcedure 

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CreateTransferOrder(ReferencesArrray, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		CommandParameter = ReferencesArrray;
	Else
		CommandParameter = ReferencesArrray[0];
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("CreatedDocumentKind", "TransferOrder");
	FormParameters.Insert("DocumentBasis", CommandParameter);
	OpenForm("DataProcessor.WizardOfWarehouseDocumentGenerationForRemovingFromProductRange.Form.Form",
					FormParameters,
					CommandExecuteParameters.Source,
					CommandExecuteParameters.Uniqueness,
					CommandExecuteParameters.Window);
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CreateRequestForQuotation(ReferencesArrray, ExecutionParameters) Export
	
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		CommandParameter = ReferencesArrray;
	Else
		CommandParameter = ReferencesArrray[0];
	EndIf;
	
	If TypeOf(CommandParameter) = Type("DocumentRef.ApplicationForCollateral")
		Or TypeOf(CommandParameter) = Type("DocumentRef.PurchaseRequest") Then
		
		OpenForm(ExecutionParameters.CommandDetails.AdditionalParameters.FormName,
			New Structure("Basis", ReferencesArrray),
			ExecutionParameters.Form,
			True);
			
	Else
		
		CreateSecuringOrder(ReferencesArrray, ExecutionParameters);
		
	EndIf;
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CreateSecuringOrder(ReferencesArrray, ExecutionParameters) Export
	
	CommandParameter = ?(ExecutionParameters.CommandDetails.MultipleChoice, ReferencesArrray[0], ReferencesArrray);
	
	OnCloseNotifyDescription = New CallbackDescription(
		"CreateSecuringOrderAfterSpecifyingProducts",
		GenerationByReferenceTMClient,
		ExecutionParameters);
		
	OpeningParameters = New Structure();
	OpeningParameters.Insert("Ref", CommandParameter);
	OpeningParameters.Insert("NameOfDocumentManager",
		ExecutionParameters.CommandDetails.AdditionalParameters.NameOfDocumentManager);
	OpeningParameters.Insert("ParametersAreDescribedInCommonModule",
		ExecutionParameters.CommandDetails.AdditionalParameters.ParametersAreDescribedInCommonModule);
	
	OpenForm(
		"CommonForm.GenerateSpecifyTheQuantityToOrder",
		OpeningParameters,
		ExecutionParameters.Form,
		New UUID(),
		,
		,
		OnCloseNotifyDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

Procedure CreateSecuringOrderAfterSpecifyingProducts(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Basis = New Structure();
	Basis.Insert("AddressGoods", Result.AddressGoods);
	Basis.Insert("Basis", Result.Basis);
	Basis.Insert("Warehouse", Result.Warehouse);
	
	OpeningParameters = New Structure("Basis", Basis);
	
	AddlParameters = AdditionalParameters.CommandDetails; // - Structure
	OpenForm(AddlParameters.AdditionalParameters.FormName,
		OpeningParameters,
		AdditionalParameters.Form,
		New UUID);
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CreateMovingOrderBasedOnPurchaseOfGoodsServicesForGroupOfWarehouses(ReferencesArrray, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		CommandParameter = ReferencesArrray;
	Else
		CommandParameter = ReferencesArrray[0];
	EndIf;
	
	CreationParameters = GenerationByReferenceTMServerCall.CreateMovingOrderBasedOnPurchaseOfGoodsAndServicesForGroupOfWarehousesCreationParameters(CommandParameter);
	
	CreateMovingOrderBasedOnGroupOfWarehousesAfterReceivingListOfWarehouses(CreationParameters, ExecutionParameters);
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CreateMovingOrderBasedOnAcceptanceOfGoodsForStorageByWarehouseGroup(ReferencesArrray, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		CommandParameter = ReferencesArrray;
	Else
		CommandParameter = ReferencesArrray[0];
	EndIf;
	
	CreationParameters = GenerationByReferenceTMServerCall.CreateMovingOrderBasedOnAcceptanceOfGoodsForStorageByWarehouseGroupCreationParameters(CommandParameter);
	
	CreateMovingOrderBasedOnGroupOfWarehousesAfterReceivingListOfWarehouses(CreationParameters, ExecutionParameters);
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CreateMovementOfGoodsBasedOnGroupOfWarehouses(ReferencesArrray, ExecutionParameters) Export
	
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		CommandParameter = ReferencesArrray;
	Else
		CommandParameter = ReferencesArrray[0];
	EndIf;
	
	CreationParameters = GenerationByReferenceTMServerCall.CreateMovementOfGoodsBasedOnGroupOfWarehousesCreationParameters(CommandParameter);
	
	If CreationParameters.MultipleWarehouses Then
		
		OnCloseNotifyDescription = New CallbackDescription(
			"CreateMovingGoodsBasedOnWarehouseGroupAfterSelectingWarehouse",GenerationByReferenceTMClient, ExecutionParameters);
			
		OpeningParameters = New Structure();
		OpeningParameters.Insert("ValuesForSelection", CreationParameters.WarehousesList);
		OpeningParameters.Insert("Title", NStr("vi = 'Lựa chọn kho hàng';
												|ru = 'Выбор склада';
												|en = 'Select warehouse'; fa = 'انتخاب انبار';
												|it = 'Selezione del magazzino';
												|pl = 'Wybór magazynu';
												|tr = 'Ambar seçimi'"));
		
		OpenForm(
			"CommonForm.SelectValue",
			OpeningParameters,
			ExecutionParameters.Form,
			New UUID(),
			,
			,
			OnCloseNotifyDescription,
			FormWindowOpeningMode.LockOwnerWindow);
		
	Else
		
		CreateMovingGoodsBasedOnWarehouseGroupAfterSelectingWarehouse(CreationParameters.WarehousesList[0], ExecutionParameters);
		
	EndIf;
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CreateStockShortagesRecognitionBasedOnGroupOfWarehouses(ReferencesArrray, ExecutionParameters) Export
	
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		CommandParameter = ReferencesArrray;
	Else
		CommandParameter = ReferencesArrray[0];
	EndIf;
	
	CreationParameters = GenerationByReferenceTMServerCall.CreateStockShortageRecognitionBasedOnGroupOfWarehousesCreationParameters(CommandParameter);
	
	If CreationParameters.MultipleWarehouses Then
		
		OnCloseNotifyDescription = New CallbackDescription(
			"CreateStockShortageRecognitionBasedOnGroupOfWarehousesAfterSelectingWarehouse",
			GenerationByReferenceTMClient, ExecutionParameters);
			
		OpeningParameters = New Structure();
		OpeningParameters.Insert("ValuesForSelection", CreationParameters.WarehousesList);
		OpeningParameters.Insert("Title", NStr("vi = 'Lựa chọn kho hàng';
												|ru = 'Выбор склада';
												|en = 'Select warehouse'; fa = 'انتخاب انبار';
												|it = 'Selezione del magazzino';
												|pl = 'Wybór magazynu';
												|tr = 'Ambar seçimi'"));
		
		OpenForm(
			"CommonForm.SelectValue",
			OpeningParameters,
			ExecutionParameters.Form,
			New UUID(),
			,
			,
			OnCloseNotifyDescription,
			FormWindowOpeningMode.LockOwnerWindow);
		
	Else
		
		CreateStockShortageRecognitionBasedOnGroupOfWarehousesAfterSelectingWarehouse(
			CreationParameters.WarehousesList[0], ExecutionParameters);
		
	EndIf;
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CreateDamageToGoodsBasedOnGroupOfWarehouses(ReferencesArrray, ExecutionParameters) Export
	
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		CommandParameter = ReferencesArrray;
	Else
		CommandParameter = ReferencesArrray[0];
	EndIf;
	
	CreationParameters = GenerationByReferenceTMServerCall.CreateDamageToGoodsBasedOnWarehouseGroupCreationParameters(CommandParameter);
	
	If CreationParameters.MultipleWarehouses Then
		
		OnCloseNotifyDescription = New CallbackDescription(
			"CreateDamageToGoodsBasedOnGroupOfWarehousesAfterSelectingWarehouse",
			GenerationByReferenceTMClient, ExecutionParameters);
			
		OpeningParameters = New Structure();
		OpeningParameters.Insert("ValuesForSelection", CreationParameters.WarehousesList);
		OpeningParameters.Insert("Title", NStr("vi = 'Lựa chọn kho hàng';
												|ru = 'Выбор склада';
												|en = 'Select warehouse'; fa = 'انتخاب انبار';
												|it = 'Selezione del magazzino';
												|pl = 'Wybór magazynu';
												|tr = 'Ambar seçimi'"));
		
		OpenForm(
			"CommonForm.SelectValue",
			OpeningParameters,
			ExecutionParameters.Form,
			New UUID(),
			,
			,
			OnCloseNotifyDescription,
			FormWindowOpeningMode.LockOwnerWindow);
		
	Else
		
		CreateDamageToGoodsBasedOnGroupOfWarehousesAfterSelectingWarehouse(
			CreationParameters.WarehousesList[0], ExecutionParameters);
		
	EndIf;
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CreateReturnOfGoodsToSupplierBasedOnWarehouseGroup(ReferencesArrray, ExecutionParameters) Export
	
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		CommandParameter = ReferencesArrray;
	Else
		CommandParameter = ReferencesArrray[0];
	EndIf;
	
	CreationParameters = GenerationByReferenceTMServerCall.CreateReturnOfGoodsToSupplierBasedOnWarehouseGroupCreationParameters(CommandParameter);
	
	If CreationParameters.MultipleWarehouses Then
		
		OnCloseNotifyDescription = New CallbackDescription(
			"CreateReturnOfGoodsToSupplierBasedOnWarehouseGroupAfterSelectingWarehouse",
			GenerationByReferenceTMClient, ExecutionParameters);
			
		OpeningParameters = New Structure();
		OpeningParameters.Insert("ValuesForSelection", CreationParameters.WarehousesList);
		OpeningParameters.Insert("Title", NStr("vi = 'Lựa chọn kho hàng';
												|ru = 'Выбор склада';
												|en = 'Select warehouse'; fa = 'انتخاب انبار';
												|it = 'Selezione del magazzino';
												|pl = 'Wybór magazynu';
												|tr = 'Ambar seçimi'"));
		
		OpenForm(
			"CommonForm.SelectValue",
			OpeningParameters,
			ExecutionParameters.Form,
			New UUID(),
			,
			,
			OnCloseNotifyDescription,
			FormWindowOpeningMode.LockOwnerWindow);
		
	Else
		
		CreateReturnOfGoodsToSupplierBasedOnWarehouseGroupAfterSelectingWarehouse(
			CreationParameters.WarehousesList[0], ExecutionParameters);
		
	EndIf;
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CreateShipmentOfGoodsFromStorageBasedOnGroupOfWarehouses(ReferencesArrray, ExecutionParameters) Export
	
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		CommandParameter = ReferencesArrray;
	Else
		CommandParameter = ReferencesArrray[0];
	EndIf;
	
	CreationParameters = GenerationByReferenceTMServerCall.CreateShipmentOfGoodsFromStorageBasedOnGroupOfWarehousesCreationParameters(CommandParameter);
	
	If CreationParameters.MultipleWarehouses Then
		
		OnCloseNotifyDescription = New CallbackDescription(
			"CreateShipmentOfGoodsFromStorageBasedOnGroupOfWarehousesAfterSelectingWarehouse",
			GenerationByReferenceTMClient, ExecutionParameters);
			
		OpeningParameters = New Structure();
		OpeningParameters.Insert("ValuesForSelection", CreationParameters.WarehousesList);
		OpeningParameters.Insert("Title", NStr("vi = 'Lựa chọn kho hàng';
												|ru = 'Выбор склада';
												|en = 'Select warehouse'; fa = 'انتخاب انبار';
												|it = 'Selezione del magazzino';
												|pl = 'Wybór magazynu';
												|tr = 'Ambar seçimi'"));
		
		OpenForm(
			"CommonForm.SelectValue",
			OpeningParameters,
			ExecutionParameters.Form,
			New UUID(),
			,
			,
			OnCloseNotifyDescription,
			FormWindowOpeningMode.LockOwnerWindow);
		
	Else
		
		CreateShipmentOfGoodsFromStorageBasedOnGroupOfWarehousesAfterSelectingWarehouse(
			CreationParameters.WarehousesList[0], ExecutionParameters);
		
	EndIf;
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure SetInventoryLevelControl(ReferencesArrray, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		CommandParameter = ReferencesArrray;
	Else
		CommandParameter = ReferencesArrray[0];
	EndIf;
	
	If Not GenerationByReferenceTMServerCall.SetInventoryLevelControl(CommandParameter) Then
		
		ShowMessageBox(, NStr("vi = 'Chưa thiết lập duy trì vật tư bởi vì không có kho nào với định dạng đã chỉ ra';
								|ru = 'Поддержание запаса не установлено, так как нет ни одного склада указанного формата';
								|en = 'Stock maintaining is not set, since there is no warehouse of the specified format'; fa = 'Stock maintaining is not set, since there is no warehouse of the specified format';
								|it = 'Non è impostato il mantenimento delle scorte perché non ci sono magazzini di formato indicato';
								|pl = 'Nie ustalono utrzymania zapasów, z powodu braku magazynu podanego formatu';
								|tr = 'Belirtilen formatta ambarlar bulunmadığından stok destekleme oluşturulmadı'"));
		Return;
		
	EndIf;
	
	FilterStructure1 = New Structure("Document", CommandParameter);
	FormParameters = New Structure("Filter, Source", FilterStructure1, "ProductRangeChange");
	OpenForm("DataProcessor.SetUpStockReplenishment.Form", FormParameters,
		CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
		
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure SetUpStockReplenishment(ReferencesArrray, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		CommandParameter = ReferencesArrray;
	Else
		CommandParameter = ReferencesArrray[0];
	EndIf;
	
	FilterStructure1 = New Structure("Document", CommandParameter);
	FormParameters = New Structure("Filter, Source", FilterStructure1, "ProductRangeChange");
	OpenForm("DataProcessor.SetUpStockReplenishment.Form", FormParameters,
		CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
		
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure WarehouseGoodsIssueReceiptWizard(ReferencesArrray, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		CommandParameter = ReferencesArrray;
	Else
		CommandParameter = ReferencesArrray[0];
	EndIf;
	
	If TypeOf(CommandParameter) = Type("DocumentRef.InventoryRecount") Then
		CheckResult = GenerationByReferenceTMServerCall.CheckRecalculationStatusOnServer(CommandParameter);
		If Not CheckResult.YouCanOpenAssistant Then 
			CommonClientServer.MessageToUser(CheckResult.UserMessage);
			Return;
		EndIf;
	EndIf;
	
	FormParameters = New Structure("Basis", CommandParameter);
	OpenForm("DataProcessor.WarehouseGoodsIssueReceiptWizard.Form", 
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
		
EndProcedure



// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CreatingNewEmployees(ReferencesArrray, ExecutionParameters) Export
	
	ClearMessages();
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	If TypeOf(ReferencesArrray[0]) = Type("DocumentRef.BackflushProduction") Then
		
		Array = GeneralPurposeTMServerCall.ObjectsAttributesValues(ReferencesArrray, "Posted, Ref");
		
		For Each String In Array Do
			
			Attributes = String.Value;
			If Not Attributes.Posted Then
				ErrorTextIsCarriedOut = NStr("vi = 'Chứng từ %Document% chưa kết chuyển. Lập trên cơ sở bị cấm.';
											|ru = 'Документ %Document% не проведен. Ввод на основании непроведенного документа запрещен.';
											|en = 'Document %Document% is not posted. Generation from unposted documents is not allowed.'; fa = 'Document %Document% is not posted. Generation from unposted documents is not allowed.';
											|it = 'Il documento %Document% non è stato registrato. L''immissione in base al documento non registrato è proibita.';
											|pl = 'Dokument %Document% nie jest zaksięgowany. Wprowadzanie na podstawie niezaksięgowanego dokumentu jest zakazane.';
											|tr = '%Document% belgesi kaydedilmedi. Kaydedilmemiş belgeye dayalı giriş yasaktır.'");
				ErrorTextIsCarriedOut = StrReplace(ErrorTextIsCarriedOut, "%Document%", Attributes.Ref);
				Raise ErrorTextIsCarriedOut;
			EndIf;
		EndDo;
	ElsIf TypeOf(ReferencesArrray[0]) = Type("DocumentRef.ProductionStage2_2") Then
		
		Array = GeneralPurposeTMServerCall.ObjectsAttributesValues(ReferencesArrray, "Status, Posted, Ref");
		
		For Each String In Array Do
			
			Attributes = String.Value;
			
			ThereAreErrorsStatus =  Not (
			Attributes.Status = PredefinedValue("Enum.StatusesOfProductionStages2_2.Initiated")
			Or Attributes.Status = PredefinedValue("Enum.StatusesOfProductionStages2_2.Completed")
			);
			
			If ThereAreErrorsStatus Then
				ErrorTextStatus = NStr("vi = 'Chứng từ %Document% ở trạng thái ""%Status%"". Nhập trên cơ sở được phép trong trạng thái ""Đã bắt đầu"" và ""Đã hoàn thành"".';
										|ru = 'Документ %Document% находится в статусе ""%Status%"". Ввод на основании разрешен в статусах ""Начат"", и ""Завершен"".';
										|en = 'Document %Document% is in the ""%Status%"" status. Generation is only allowed from base documents in ""Started"" or ""Completed"" statuses.'; fa = 'Document %Document% is in the ""%Status%"" status. Generation is only allowed from base documents in ""Started"" or ""Completed"" statuses.';
										|it = 'Il documento %Document% è nello stato ""%Status%"". Immissione in base alla causale è consentita solo negli stati ""Avviato"" e ""Chiuso"".';
										|pl = 'Dokument %Document% jest w statusie ""%Status%"". Wprowadzanie na podstawie jest dozwolone w statusach ""Rozpoczęty"" oraz ""Zakończony"".';
										|tr = 'Belge %Document% ""%Status%"" durumundadır. ""Başlatıldı"" ve ""Tamamlandı"" durumlarında gerekçeye dayalı girişe izin verilir.'");
				
				ErrorTextStatus = StrReplace(ErrorTextStatus, "%Document%", Attributes.Ref);
				ErrorTextStatus = StrReplace(ErrorTextStatus, "%Status%",   Attributes.Status);
				Raise ErrorTextStatus;
				
			EndIf;
			
			If Not Attributes.Posted Then
				ErrorTextIsCarriedOut = NStr("vi = 'Chứng từ %Document% chưa kết chuyển. Lập trên cơ sở bị cấm.';
											|ru = 'Документ %Document% не проведен. Ввод на основании непроведенного документа запрещен.';
											|en = 'Document %Document% is not posted. Generation from unposted documents is not allowed.'; fa = 'Document %Document% is not posted. Generation from unposted documents is not allowed.';
											|it = 'Il documento %Document% non è stato registrato. L''immissione in base al documento non registrato è proibita.';
											|pl = 'Dokument %Document% nie jest zaksięgowany. Wprowadzanie na podstawie niezaksięgowanego dokumentu jest zakazane.';
											|tr = '%Document% belgesi kaydedilmedi. Kaydedilmemiş belgeye dayalı giriş yasaktır.'");
				ErrorTextIsCarriedOut = StrReplace(ErrorTextIsCarriedOut, "%Document%", Attributes.Ref);
				Raise ErrorTextIsCarriedOut;
			EndIf;
			
		EndDo;

		
	ElsIf TypeOf(ReferencesArrray[0]) = Type("DocumentRef.RMOrder") Then
		
		Array = GeneralPurposeTMServerCall.ObjectsAttributesValues(ReferencesArrray, "Status, Posted, Ref");
		
		For Each String In Array Do
			
			Attributes = String.Value;
			
			ThereAreErrorsStatus =  Not (Attributes.Status = PredefinedValue("Enum.RMOrderStatuses.Running")
			Or Attributes.Status = PredefinedValue("Enum.RMOrderStatuses.Closed"));
			
			If ThereAreErrorsStatus Then
				
				ErrorTextStatus = NStr("vi = 'Chứng từ %Document% ở trạng thái ""%Status%"". Nhập trên cơ sở được phép trong trạng thái ""Đang chạy"" và ""Đã đóng"".';
										|ru = 'Документ %Document% находится в статусе ""%Status%"". Ввод на основании разрешен в статусах ""Выполняется"" и ""Закрыт"".';
										|en = 'Document %Document% is in the ""%Status%"" status. Generation is only allowed from base documents in ""In progress"" or ""Closed"" statuses.'; fa = 'Document %Document% is in the ""%Status%"" status. Generation is only allowed from base documents in ""In progress"" or ""Closed"" statuses.';
										|it = 'Il documento %Document% è nello stato ""%Status%"". L''immissione in base alla causale è consentita solo negli stati ""In esecuzione"" e ""Chiuso"".';
										|pl = 'Dokument %Document% jest w statusie ""%Status%"". Wprowadzanie na podstawie jest dozwolone w statusach ""Wykonuje się"" oraz ""Zamknięty"".';
										|tr = 'Belge %Document% ""%Status%"" durumundadır. ""Gerçekleştiriliyor"" ve ""Kapalı"" durumlarında gerekçeye dayalı girişe izin verilir.'");
				
				ErrorTextStatus = StrReplace(ErrorTextStatus, "%Document%", Attributes.Ref);
				ErrorTextStatus = StrReplace(ErrorTextStatus, "%Status%",   Attributes.Status);
				
				Raise ErrorTextStatus;
				
			EndIf;
			
		EndDo;
		
	ElsIf TypeOf(ReferencesArrray[0]) = Type("DocumentRef.ShiftTask") Then
		Array = GeneralPurposeTMServerCall.ObjectsAttributesValues(ReferencesArrray, "Status, Posted, Ref");
		
		For Each String In Array Do
			
			Attributes = String.Value;
			
			ThereAreErrorsStatus = Not Attributes.Status = PredefinedValue("Enum.ShiftTaskStatuses.Closed");
			
			If ThereAreErrorsStatus Then
				
				ErrorTextStatus = NStr("vi = 'Chứng từ %Document% ở trạng thái ""%Status%"". Nhập trên cơ sở chỉ cho phép ở trạng thái ""Đã đóng"".';
										|ru = 'Документ %Document% находится в статусе ""%Status%"". Ввод на основании разрешен в статусе ""Закрыто"".';
										|en = '%Document% document is in the ""%Status%"" status. Generation is allowed in ""Closed"" status.'; fa = '%Document% document is in the ""%Status%"" status. Generation is allowed in ""Closed"" status.';
										|it = 'Il documento %Document% si trova nello stato ""%Status%"". L''inserimento sulla base è permesso nello stato ""Chiuso"".';
										|pl = 'Dokument %Document% ma status ""%Status%"". Wprowadzenie na podstawie dozwolono o statusie ""Zamknięto"".';
										|tr = 'Belge %Document% ""%Status%"" durumundadır. ""Kapalı"" durumunda gerekçeye dayalı girişe izin verilir.'");
				
				ErrorTextStatus = StrReplace(ErrorTextStatus, "%Document%", Attributes.Ref);
				ErrorTextStatus = StrReplace(ErrorTextStatus, "%Status%",   Attributes.Status);
				
				Raise ErrorTextStatus;
			
			EndIf;
			
		EndDo;
		
		ProductionAccountingClient.IssueDevelopmentOfEmployeesOnShiftAssignment(ReferencesArrray);
		
		Return;
	Else
		
		Raise NStr("vi = 'Thao tác không được phép đối với đối tượng được chọn.';
					|ru = 'Операция недоступна для выбранного объекта.';
					|en = 'Operation is not available for the selected object.'; fa = 'Operation is not available for the selected object.';
					|it = 'L''operazione non è disponibile per l''oggetto selezionato.';
					|pl = 'Operacja nie jest dostępna dla wybranego obiektu.';
					|tr = 'İşlem seçilen nesne için erişilebilir değil.'");
		
	EndIf;
	
	ProductionAccountingClient.IssueDevelopmentOfEmployeesOnOrders(ReferencesArrray);
	
EndProcedure

#Region AssignmentAdjustment

// Opens the form for processing the filling in of the document "Adjustment of the destination of goods" for the withdrawal of reserves.
//  Parameters:
//   ExecutionParameters - See SupplyClient.ParametersOfFormForFillingInItemAssignmentAdjustment
Procedure OpenReserveWithdrawalWizard(ExecutionParameters) Export
	
	FormParameters = SupplyClient.ParametersOfFormForFillingInItemAssignmentAdjustment();
	FillPropertyValues(FormParameters, ExecutionParameters);
	FormParameters.Master_2 = True;
	FormParameters.OperationKind = PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve");
	FormParameters.OrderDocument = ExecutionParameters.ObjectsOfBases[0];
	
	OpenForm("DataProcessor.AssignmentAdjustmentFilling.Form.ObjectForm",
		FormParameters, ExecutionParameters.Form);
	
EndProcedure

// Opens the form for processing the filling in of the document "Adjustment of the assignment of goods" for the removal of reserves from several assignments.
//  Parameters:
//   ExecutionParameters - See SupplyClient.ParametersOfFormForFillingInItemAssignmentAdjustment
Procedure OpenMassReserveWithdrawalWizard(ExecutionParameters) Export
	
	FormParameters = SupplyClient.ParametersOfFormForFillingInItemAssignmentAdjustment();
	FillPropertyValues(FormParameters, ExecutionParameters);
	FormParameters.Master_2 = True;
	FormParameters.OperationKind = PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.RemoveFromReserveForMultipleAssignments");
	FormParameters.OrderDocument = ExecutionParameters.ObjectsOfBases[0];
	FormParameters.MultipleAppointments = True;
	
	OpenForm("DataProcessor.AssignmentAdjustmentFilling.Form.ObjectForm",
		FormParameters, ExecutionParameters.Form);
	
EndProcedure

// Opens the form for processing the filling in of the document "Adjustment of the destination of goods" for reserving goods.
//  Parameters:
//   ExecutionParameters - See SupplyClient.ParametersOfFormForFillingInItemAssignmentAdjustment
Procedure OpenBackupWizard(ExecutionParameters) Export
	
	FormParameters = SupplyClient.ParametersOfFormForFillingInItemAssignmentAdjustment();
	
	FormParameters.Master_2 = True;
	FillPropertyValues(FormParameters, ExecutionParameters);
	FormParameters.OperationKind = PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.ToReserve_");
	FormParameters.OrderDocument = ExecutionParameters.ObjectsOfBases[0];
	
	OpenForm("DataProcessor.AssignmentAdjustmentFilling.Form.ObjectForm",
		FormParameters, ExecutionParameters.Form);
	
EndProcedure

// Opens the form for processing the filling in of the document "Adjustment of the purpose of goods" for reserving goods for several purposes.
//  Parameters:
//   ExecutionParameters - See SupplyClient.ParametersOfFormForFillingInItemAssignmentAdjustment
Procedure OpenMassBackupWizard(ExecutionParameters) Export
	
	FormParameters = SupplyClient.ParametersOfFormForFillingInItemAssignmentAdjustment();
	FillPropertyValues(FormParameters, ExecutionParameters);
	FormParameters.Master_2 = True;
	FormParameters.OperationKind = PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.ToReserve_");
	FormParameters.OrderDocument = ExecutionParameters.ObjectsOfBases[0];
	FormParameters.MultipleAppointments = True;
	
	OpenForm("DataProcessor.AssignmentAdjustmentFilling.Form.ObjectForm",
		FormParameters, ExecutionParameters.Form);
	
EndProcedure

//
// Opens the form for processing the filling out of the document "Correction of the destination of goods" for counter-correction of the destination of goods
//  Parameters:
//   ExecutionParameters - See SupplyClient.ParametersOfFormForFillingInItemAssignmentAdjustment
//   CallbackDescription - CallbackDescription - description of the notification to be executed after closing the Counter adjustment wizard form
Procedure OpenCounterAssignmentAdjustmentWizard(ExecutionParameters, CallbackDescription = Undefined) Export
	
	FormParameters = SupplyClient.ParametersOfFormForFillingInItemAssignmentAdjustment();
	FillPropertyValues(FormParameters, ExecutionParameters);
	FormParameters.Master_2 = True;
	FormParameters.OperationKind = PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.MutualAdjustment");
	FormParameters.OrderDocument = ExecutionParameters.ObjectsOfBases[0];
	FormParameters.QuantityToPassForAssignment = ExecutionParameters.QuantityToPassForAssignment;

	OpenForm(
		"DataProcessor.AssignmentAdjustmentFilling.Form.ObjectForm",
		FormParameters,
		ExecutionParameters.Form,,,,
		CallbackDescription);
	
EndProcedure
#EndRegion

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CreateSpendingCashOrder(ReferencesArrray, ExecutionParameters) Export
	
	CashClient.CreatePaymentDocumentBasedOnCashExpenseRequests(
		ReferencesArrray,
		"CashVoucher");
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CreateNonCashCashDebiting(ReferencesArrray, ExecutionParameters) Export
	
	CashClient.CreatePaymentDocumentBasedOnCashExpenseRequests(
		ReferencesArrray,
		"BankAccountIssue");
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   DocumentRef - AnyRef - link to the document that the command is being executed for.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CreatePaymentCardOperation(DocumentRef, ExecutionParameters) Export
	
	CashClient.CreatePaymentDocumentBasedOnCashExpenseRequests(
		CommonClientServer.ValueInArray(DocumentRef),
		"PaymentCardTransaction");
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure InstructionForShippingAgent(ReferencesArrray, ExecutionParameters) Export
	
	OpenForm("Document.InstructionForShippingAgent.Form.DocumentForm", New Structure("Basis", ReferencesArrray));
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure WriteOffOfNonCashCashTransactionsBasedOnCommissionReport_Remuneration(ReferencesArrray, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	BasisParameters = New Structure;
	BasisParameters.Insert("CommissionReportIntercompany",  ReferencesArrray);
	
	OpenForm(
		"Document.BankAccountIssue.Form.DocumentForm",
		New Structure("Basis", BasisParameters),
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
			
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure ReceiptOfNonCashCashPaymentsBasedOnCommissionReport_Remuneration(ReferencesArrray, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	BasisParameters = New Structure;	
	BasisParameters.Insert("CommissionReportIntercompany",  ReferencesArrray);
	
	OpenForm(
		"Document.BankAccountReceiptNote.Form.DocumentForm",
		New Structure("Basis", BasisParameters),
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
			
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure ApplicationForCashExpenditureBasedOnCommissionReport_Remuneration(ReferencesArrray, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	BasisParameters = New Structure;	
	BasisParameters.Insert("CommissionReportIntercompany",  ReferencesArrray);
	
	OpenForm(
		"Document.PaymentRequest.Form.DocumentForm",
		New Structure("Basis", BasisParameters),
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
			
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure AcceptanceOfGoodsForStorageIsCarriedOutOnBasisOfOrder(ReferencesArrray, ExecutionParameters) Export

	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	CommandParameter = ReferencesArrray;
	
	ClearMessages();
	OpeningParameters = GenerationByReferenceTMServerCall.AcceptanceOfGoodsForStorageFormOpeningParameters(CommandParameter);
	If OpeningParameters = Undefined Then
		Return;
	EndIf;
	
	OpenForm(
		"Document.GoodsReceiptForStorage.Form.DocumentForm",
		OpeningParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);

EndProcedure



// Create an order for production22 based on the order give2 5.
// 
// Parameters:
//  DocumentReference - DocumentRef.MaterialProviderOrder2_5
//  ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
Procedure CreateProductionOrder22BasedOnGiverSOrder2_5(DocumentReference, ExecutionParameters) Export
	
	ObjectsOfBases = New Array;
	ObjectsOfBases.Add(DocumentReference);
	
	CheckResult = GenerationByReferenceTMServerCall.CreateProductionOrder22BasedOnGiverSOrder2_5VerificationOfGrounds(ObjectsOfBases);
	If CheckResult.ErrorText <> Undefined Then
		ShowMessageBox(, CheckResult.ErrorText);
		Return;
	EndIf;
	
	OpenForm("Document.ProductionOrder2_2.ObjectForm", New Structure("Basis", DocumentReference), ExecutionParameters.Form);
	
EndProcedure

// Create a production order for the reverse kitting of FINISHED products
// 
// Parameters:
//  DocumentReference - DocumentRef.ProductionStage2_2
//  ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
Procedure CreateProductionOrderOfReverseKittingType(DocumentReference, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	ClearMessages();
	
	HeaderAttributes = New Structure;
	HeaderAttributes.Insert("ProductionProcessType", PredefinedValue("Enum.ProductionProcessTypes.Disassembly"));
	
	BasisParameters = New Structure;
	BasisParameters.Insert("Basis", DocumentReference);
	BasisParameters.Insert("HeaderAttributes", HeaderAttributes); 
	
	OpenForm("Document.ProductionOrder2_2.ObjectForm",
		New Structure("Basis", BasisParameters),
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
	
EndProcedure

// Create an order for repair work
// 
// Parameters:
//  DocumentReference - DocumentRef.ProductionStage2_2
//  ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
Procedure CreateProductionOrderOfRepairWorkType(DocumentReference, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	ClearMessages();
	
	Notification = New CallbackDescription(
		"CreateProductionOrderOfRepairWorkTypeCompletion",
		GenerationByReferenceTMClient,
		ExecutionParameters);
	
	FormParameters = New Structure;
	FormParameters.Insert("DocumentReference", DocumentReference);
	
	OpenForm("Document.ProductionOrder2_2.Form.GenerateBasedOnRMOrder",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL,
		Notification);
	
EndProcedure

// Handler for creating a repair work order
// 
// Parameters:
//  Result - Undefined, Structure -
//  AdditionalParameters - Structure -
Procedure CreateProductionOrderOfRepairWorkTypeCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	For Each FillingData In Result.FillingData Do
		
		Basis = New Structure();
		Basis.Insert("Basis", Result.Basis);
		Basis.Insert("HeaderAttributes", FillingData.HeaderAttributes);
		Basis.Insert("AddressGoods", FillingData.AddressGoods);
		
		OpeningParameters = New Structure("Basis", Basis);
		
		OpenForm("Document.ProductionOrder2_2.ObjectForm",
			OpeningParameters,
			AdditionalParameters.Form,
			New UUID);
		
	EndDo;
	
EndProcedure

Procedure CreateProductionOperationBasedOn(DocumentReference, ExecutionParameters) Export
	
	CheckResult = GenerationByReferenceTMServerCall.CreateProductionOperationBasedOnBaseCheck(DocumentReference);
	If CheckResult.ErrorText <> Undefined Then
		ShowMessageBox(, CheckResult.ErrorText);
	Else
		OpenForm("Document.ProductionOperation2_2.ObjectForm", 
			New Structure("Basis", DocumentReference), ExecutionParameters.Form);
	EndIf;
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure AcceptanceOfRepairedFinishedProductToCreateOnBasisOfOrder(ReferencesArrray, ExecutionParameters) Export

	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	CommandParameter = ReferencesArrray;
	
	ClearMessages();
	OpeningParameters = GenerationByReferenceTMServerCall.AcceptanceOfFinishedProductBeingRepairedFormOpeningParameters(CommandParameter);
	If OpeningParameters = Undefined Then
		Return;
	EndIf;
	
	OpenForm(
		"Document.GoodsReceiptForStorage.Form.DocumentForm",
		OpeningParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);

EndProcedure

Procedure ToCreateInitialRemnantsOfUnfinishedProductionByBatchesOfProduction(DocumentReference, ExecutionParameters) Export
	
	TimeConsumingOperation =
		GenerationByReferenceTMServerCall.ToCreateInitialRemnantsOfUnfinishedProductionByBatchesOfProduction(
			DocumentReference,
			ExecutionParameters.Form.UUID);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ExecutionParameters.Form);
	CallbackDescription = New CallbackDescription("DistributeRemainingWIPCompletion", ExecutionParameters.Form);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);
	
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   Handler - DocumentRef.VendorInvoice - link to the document that the command is being executed for.
//   CommandDetails - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CreateReportOnDiscrepanciesAfterAcceptanceBasedOnPurchaseOfGoodsServices(Handler, CommandDetails) Export
	
	ClearMessages();
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, CommandDetails.CommandDetails.AdditionalParameters);
	ClearMessages();
	CommandParameter = CommonClientServer.ValueInArray(Handler);
	
	OpeningParameters = GenerationByReferenceTMServerCall.ReportOfDiscrepanciesAfterAcceptanceAndOpeningOfForm(CommandParameter);
	If OpeningParameters = Undefined Then
		Return;
	EndIf;
	
	OpenForm("Document.DiscrepancyReportFollowingReceipt.Form.DocumentForm",
		OpeningParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
	
EndProcedure

Procedure CreateAdjustmentForPurposeOfGoodsBasedOnCustomerSOrder(DocumentReference, ExecutionParameters) Export
		
	CheckResult = GenerationByReferenceTMServerCall.CreateAdjustmentToDestinationOfGoodsBasedOnCustomerSOrderCheckingDestinationType(DocumentReference);
	If CheckResult.ErrorText <> Undefined Then
		ShowMessageBox(, CheckResult.ErrorText);
		Return;
	EndIf;
	
	OpenForm("Document.InventoryAssignmentAdjustment.ObjectForm", New Structure("Basis", DocumentReference), ExecutionParameters.Form);
	
EndProcedure

Procedure CreateShipmentOfGoodsFromStorageBasedOnCustomerOrder(DocumentReference, ExecutionParameters) Export
		
	CheckResult = GenerationByReferenceTMServerCall.CreateShipmentOfGoodsFromStorageBasedOnCustomerOrderDestinationTypeVerification(DocumentReference);
	If CheckResult.ErrorText <> Undefined Then
		ShowMessageBox(, CheckResult.ErrorText);
		Return;
	EndIf;
	
	OpenForm("Document.GoodsShipmentFromStorage.ObjectForm", New Structure("Basis", DocumentReference), ExecutionParameters.Form);
	
EndProcedure

#EndRegion

#Region Private

Procedure CreateMovingOrderBasedOnGroupOfWarehousesAfterReceivingListOfWarehouses(CreationParameters, ExecutionParameters)
	
	If CreationParameters.MultipleWarehouses Then
		
		OnCloseNotifyDescription = New CallbackDescription(
			"CreateMoveOrderBasedOnWarehouseGroupAfterSelectingWarehouse",
			GenerationByReferenceTMClient, ExecutionParameters);
			
		OpeningParameters = New Structure();
		OpeningParameters.Insert("ValuesForSelection", CreationParameters.WarehousesList);
		OpeningParameters.Insert("Title", NStr("vi = 'Lựa chọn kho hàng';
												|ru = 'Выбор склада';
												|en = 'Select warehouse'; fa = 'انتخاب انبار';
												|it = 'Selezione del magazzino';
												|pl = 'Wybór magazynu';
												|tr = 'Ambar seçimi'"));
		
		OpenForm(
			"CommonForm.SelectValue",
			OpeningParameters,
			ExecutionParameters.Form,
			New UUID(),
			,
			,
			OnCloseNotifyDescription,
			FormWindowOpeningMode.LockOwnerWindow);
		
	Else
		
		CreateMoveOrderBasedOnWarehouseGroupAfterSelectingWarehouse(CreationParameters.WarehousesList[0], ExecutionParameters);
		
	EndIf;
	
EndProcedure

Procedure CreateMoveOrderBasedOnWarehouseGroupAfterSelectingWarehouse(Result, AdditionalParameters) Export
	
	If TypeOf(AdditionalParameters.ReferencesArrray) = Type("Array")
				And AdditionalParameters.ReferencesArrray.Count() = 0
			Or Result = Undefined Then
		Return;
	EndIf;
	
	Basis = New Structure();
	Basis.Insert("Warehouse", Result);
	Basis.Insert("Basis");
	If AdditionalParameters.CommandDetails.MultipleChoice Then
		Basis.Basis = AdditionalParameters.ReferencesArrray;
	Else
		Basis.Basis = AdditionalParameters.ReferencesArrray[0];
	EndIf; 
	OpeningParameters = New Structure("Basis", Basis);
	
	OpenForm("Document.TransferOrder.ObjectForm",
		OpeningParameters,
		AdditionalParameters.Form,
		New UUID);
	
EndProcedure

Procedure CreateMovingGoodsBasedOnWarehouseGroupAfterSelectingWarehouse(Result, AdditionalParameters) Export
	
	If TypeOf(AdditionalParameters.ReferencesArrray) = Type("Array")
			 And AdditionalParameters.ReferencesArrray.Count() = 0
			 Or Result = Undefined Then
		Return;
	EndIf;
	
	Basis = New Structure();
	Basis.Insert("Warehouse", Result);
	Basis.Insert("Basis");
	If AdditionalParameters.CommandDetails.MultipleChoice Then
		Basis.Basis = AdditionalParameters.ReferencesArrray;
	Else
		Basis.Basis = AdditionalParameters.ReferencesArrray[0];
	EndIf; 
	OpeningParameters = New Structure("Basis", Basis);
	
	OpenForm("Document.InventoryTransfer.ObjectForm",
		OpeningParameters,
		AdditionalParameters.Form,
		New UUID);
	
EndProcedure

Procedure CreateStockShortageRecognitionBasedOnGroupOfWarehousesAfterSelectingWarehouse(Result, AdditionalParameters) Export
	
	If TypeOf(AdditionalParameters.ReferencesArrray) = Type("Array")
			 And AdditionalParameters.ReferencesArrray.Count() = 0
			 Or Result = Undefined Then
		Return;
	EndIf;
	
	Basis = New Structure();
	Basis.Insert("Warehouse", Result);
	Basis.Insert("Basis");
	If AdditionalParameters.CommandDetails.MultipleChoice Then
		Basis.Basis = AdditionalParameters.ReferencesArrray;
	Else
		Basis.Basis = AdditionalParameters.ReferencesArrray[0];
	EndIf; 
	OpeningParameters = New Structure("Basis", Basis);
	
	OpenForm("Document.WriteOffOfGoodsShortages.ObjectForm",
		OpeningParameters,
		AdditionalParameters.Form,
		New UUID);
	
EndProcedure

Procedure CreateDamageToGoodsBasedOnGroupOfWarehousesAfterSelectingWarehouse(Result, AdditionalParameters) Export
	
	If TypeOf(AdditionalParameters.ReferencesArrray) = Type("Array")
			 And AdditionalParameters.ReferencesArrray.Count() = 0
			 Or Result = Undefined Then
		Return;
	EndIf;
	
	Basis = New Structure();
	Basis.Insert("Warehouse", Result);
	Basis.Insert("Basis");
	If AdditionalParameters.CommandDetails.MultipleChoice Then
		Basis.Basis = AdditionalParameters.ReferencesArrray;
	Else
		Basis.Basis = AdditionalParameters.ReferencesArrray[0];
	EndIf; 
	OpeningParameters = New Structure("Basis", Basis);
	
	OpenForm("Document.GoodsDamage.ObjectForm",
		OpeningParameters,
		AdditionalParameters.Form,
		New UUID);
	
EndProcedure

Procedure CreateReturnOfGoodsToSupplierBasedOnWarehouseGroupAfterSelectingWarehouse(Result, AdditionalParameters) Export
	
	If TypeOf(AdditionalParameters.ReferencesArrray) = Type("Array")
			 And AdditionalParameters.ReferencesArrray.Count() = 0
			 Or Result = Undefined Then
		Return;
	EndIf;
	
	Basis = New Structure();
	Basis.Insert("Warehouse", Result);
	Basis.Insert("Basis");
	If AdditionalParameters.CommandDetails.MultipleChoice Then
		Basis.Basis = AdditionalParameters.ReferencesArrray;
	Else
		Basis.Basis = AdditionalParameters.ReferencesArrray[0];
	EndIf; 
	OpeningParameters = New Structure("Basis", Basis);
	
	OpenForm("Document.ReturnOfGoodsToVendor.ObjectForm",
		OpeningParameters,
		AdditionalParameters.Form,
		New UUID);
	
EndProcedure

Procedure CreateShipmentOfGoodsFromStorageBasedOnGroupOfWarehousesAfterSelectingWarehouse(Result, AdditionalParameters) Export
	
	If TypeOf(AdditionalParameters.ReferencesArrray) = Type("Array")
			 And AdditionalParameters.ReferencesArrray.Count() = 0
			 Or Result = Undefined Then
		Return;
	EndIf;
	
	Basis = New Structure();
	Basis.Insert("Warehouse", Result);
	Basis.Insert("Basis");
	If AdditionalParameters.CommandDetails.MultipleChoice Then
		Basis.Basis = AdditionalParameters.ReferencesArrray;
	Else
		Basis.Basis = AdditionalParameters.ReferencesArrray[0];
	EndIf; 
	OpeningParameters = New Structure("Basis", Basis);
	
	OpenForm("Document.GoodsShipmentFromStorage.ObjectForm",
		OpeningParameters,
		AdditionalParameters.Form,
		New UUID);
	
EndProcedure

// Constructor function for command execution parameters
//
// Returns:
//  Structure:
//		* Source 				- Arbitrary - a Form or a control of another Form
//		* Uniqueness			- Arbitrary - the key whose value will be used to search for Forms that have already been opened
//		* Window						- ClientApplicationWindow - the application window where the Form will be opened 
//		* URL	- String - sets the navigation link returned by the Form
//
Function CommandExecuteParameters()
	
	CommandExecuteParameters = New Structure;
	
	CommandExecuteParameters.Insert("Source", Undefined);
	CommandExecuteParameters.Insert("Uniqueness", Undefined);
	CommandExecuteParameters.Insert("Window", Undefined);
	CommandExecuteParameters.Insert("URL", Undefined);
	
	Return CommandExecuteParameters;

EndFunction

#EndRegion
