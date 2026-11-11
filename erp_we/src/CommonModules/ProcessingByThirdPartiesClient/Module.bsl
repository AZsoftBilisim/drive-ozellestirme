////////////////////////////////////////////////////////////////////////////////
// Subsystem "Processing on the side".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public


// Generates data for generating orders for processors.
//
// Parameters:
//  StringsList	 - Array - Contains data for the selected lines that are used for placing orders.
// 
// Returns:
//  Structure - Contains the data necessary for the formation of orders to processors.
//
Function DataForGeneratingOrdersToProcessors2_5(StringsList) Export
	
	Organization = Undefined;
	Partner = Undefined;
	Department = Undefined;
	PurchaseForActivity = Undefined;
	LineOfBusiness = Undefined;
	GoodsReceiptOption = Undefined;
	DynamicStructure = Undefined;
	
	HeaderAttributes = New Structure;
	References = New Array;
	For Each RowData In StringsList Do
		
		If Not Organization = Undefined
			And Not Organization = RowData.Organization Then
			ShowMessageBox(, NStr("vi = 'Để lập chứng từ, cần chọn các công đoạn của một doanh nghiệp.';
									|ru = 'Для оформления документа необходимо выбрать этапы одной организации.';
									|en = 'To register the document, select stages of one company.'; fa = 'To register the document, select stages of one company.';
									|it = 'Per la formalizzazione del documento è necessario selezionare le fasi di una azienda.';
									|pl = 'W celu utworzenia dokumentu należy wybrać etapy jednej firmy.';
									|tr = 'Belgenin düzenlenmesi için aynı iş yerindeki aşamaları seçmeniz gerekmektedir.'"));
			Return Undefined;
		EndIf; 
		
		If ValueIsFilled(Partner)
			And ValueIsFilled(RowData.Partner)
			And Not Partner = RowData.Partner Then
			ShowMessageBox(, NStr("vi = 'Để lập chứng từ, cần chọn các công đoạn của một người nhận gia công.';
									|ru = 'Для оформления документа необходимо выбрать этапы одного переработчика.';
									|en = 'To register the document, select stages of one subcontractor.'; fa = 'To register the document, select stages of one subcontractor.';
									|it = 'Per la formalizzazione del documento è necessario selezionare le fasi di un elaboratore.';
									|pl = 'W celu utworzenia dokumentu należy wybrać etapy jednego przetwórcy.';
									|tr = 'Belgenin düzenlenmesi için aynı fason üreticinin aşamalarını seçmeniz gerekmektedir.'"));
			Return Undefined;
		EndIf; 
		
		If Not Department = Undefined
			And Not Department = RowData.Department Then
			ShowMessageBox(, NStr("vi = 'Để lập chứng từ, cần chọn các công đoạn của một bộ phận.';
									|ru = 'Для оформления документа необходимо выбрать этапы одного подразделения.';
									|en = 'To register the document, select stages of one business unit.'; fa = 'To register the document, select stages of one business unit.';
									|it = 'Per la formalizzazione del documento è necessario selezionare le fasi di un reparto.';
									|pl = 'W celu utworzenia dokumentu należy wybrać etapy jednego działu.';
									|tr = 'Belgenin düzenlenmesi için aynı departmanın aşamalarını seçmeniz gerekmektedir.'"));
			Return Undefined;
		EndIf; 
		
		If Not PurchaseForActivity = Undefined
			And Not PurchaseForActivity = RowData.PurchaseForActivity Then
			ShowMessageBox(, NStr("vi = 'Để lập chứng từ, cần chọn các công đoạn của một kiểu hệ thống thuế GTGT.';
									|ru = 'Для оформления документа необходимо выбрать этапы одного типа налогообложения НДС.';
									|en = 'To register the document, select all the stages of the same VAT taxation type.'; fa = 'To register the document, select all the stages of the same VAT taxation type.';
									|it = 'Per la formalizzazione del documento è necessario selezionare le fasi di un tipo di tassazione IVA.';
									|pl = 'W celu utworzenia dokumentu należy wybrać etapy jednego typu opodatkowania VAT.';
									|tr = 'Belgenin düzenlenmesi için aynı KDV vergilendirme türünün aşamalarını seçmeniz gerekmektedir.'"));
			Return Undefined;
		EndIf; 
		
		If Not LineOfBusiness = Undefined
			And Not LineOfBusiness = RowData.LineOfBusiness Then
			ShowMessageBox(, NStr("vi = 'Để lập chứng từ, cần chọn các công đoạn của một lĩnh vực hoạt động.';
									|ru = 'Для оформления документа необходимо выбрать этапы одного направления деятельности.';
									|en = 'To register the document, select stages of one line of business.'; fa = 'To register the document, select stages of one line of business.';
									|it = 'Per la formalizzazione del documento è necessario selezionare le fasi di una area di attività.';
									|pl = 'W celu utworzenia dokumentu należy wybrać etapy jednego rodzaju działalności.';
									|tr = 'Belgenin düzenlenmesi için aynı iş kolunun aşamalarını seçmeniz gerekmektedir.'"));
			Return Undefined;
		EndIf;
		
		If Not GoodsReceiptOption = Undefined
			And ValueIsFilled(RowData.GoodsReceiptOption)
			And Not GoodsReceiptOption = RowData.GoodsReceiptOption Then
			ShowMessageBox(, NStr("vi = 'Để lập chứng từ, cần chọn các đơn hàng sử dụng một phương án tiếp nhận thành phẩm.';
									|ru = 'Для оформления документа необходимо выбрать заказы, использующие один вариант приемки продукции.';
									|en = 'To register the document, select orders which use one goods receiving option.'; fa = 'To register the document, select orders which use one goods receiving option.';
									|it = 'Per la regolarizzazione del documento è necessario scegliere gli ordini che utilizzano una variante di accettazione delle merci.';
									|pl = 'Do sporządzenia dokumentu należy wybrać zamówienia, wykorzystujące jeden wariant odbioru produkcji.';
									|tr = 'Belgenin düzenlenmesi için ürün teslim almanın aynı seçeneğini kullanan siparişleri seçmeniz gerekmektedir.'"));
			Return Undefined;
		EndIf;
		
		If Not DynamicStructure = Undefined
			And Not DynamicStructure = RowData.DynamicStructure Then
			
			ShowMessageBox(, NStr("vi = 'Để lập chứng từ, cần chọn đơn hàng cùng dạng (động/không động).';
									|ru = 'Для оформления документа необходимо выбрать заказы одного вида (динамические/нединамические).';
									|en = 'To register the document, select orders of the same kind (dynamic/non-dynamic).'; fa = 'To register the document, select orders of the same kind (dynamic/non-dynamic).';
									|it = 'Per la formalizzazione del documento è necessario selezionare gli ordini di un tipo (dinamici/non dinamici).';
									|pl = 'Aby utworzyć dokument należy wybrać zamówienia jednego rodzaju (dynamiczne/niedynamiczne).';
									|tr = 'Belgenin düzenlenmesi için aynı türden (dinamik/dinamik olmayan) siparişleri seçmeniz gerekmektedir.'"));
			Return Undefined;
		EndIf;
		
		Organization = RowData.Organization;
		Partner = ?(ValueIsFilled(RowData.Partner), RowData.Partner, Partner);
		Department = RowData.Department;
		PurchaseForActivity = RowData.PurchaseForActivity;
		LineOfBusiness = RowData.LineOfBusiness;
		GoodsReceiptOption = RowData.GoodsReceiptOption;
		DynamicStructure = RowData.DynamicStructure;
		
		References.Add(RowData.ReferenceOrder);
		
	EndDo; 
	
	HeaderAttributes.Insert("Organization", Organization);
	HeaderAttributes.Insert("Partner", Partner);
	HeaderAttributes.Insert("Department", Department);
	HeaderAttributes.Insert("PurchaseForActivity", PurchaseForActivity);
	HeaderAttributes.Insert("LineOfBusiness", LineOfBusiness);
	HeaderAttributes.Insert("GroupCosts", PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages"));
	
	FillingData = New Structure;
	FillingData.Insert("HeaderAttributes", HeaderAttributes);
	FillingData.Insert("References", References);
	
	Return FillingData;
	
EndFunction

#Region GenerateFrom

// Creates A Document.Transfer of goods to the custodian on the basis of a document.Processing Order 2_5
//
// Parameters:
//  ReferencesArrray - Array -
//  ExecutionParameters - Structure - Contains:
//                         * CommandDetails - Structure - Contains:
//                            ** AdditionalParameters - Structure - 
//
Procedure TransferOfGoodsToCustodianOrOnBasisOfOrderToProcessor(ReferencesArrray, ExecutionParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"CommonModule.ProcessingByThirdPartiesClient.TransferOfGoodsToCustodianOrOnBasisOfOrderToProcessor");
	
	CommandExecuteParameters = New Structure("Source, Uniqueness, Window, URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	OpeningParameters =
		ProcessingByThirdPartiesServerCall.TransferOfGoodsToCustodianFormOpeningParameters(ReferencesArrray);
	
	If Not OpeningParameters = Undefined Then
		
		OpenForm("Document.TransferOfGoodsToBailee.Form.DocumentForm",
					OpeningParameters,
					CommandExecuteParameters.Source,
					CommandExecuteParameters.Uniqueness,
					CommandExecuteParameters.Window,
					CommandExecuteParameters.URL);
		
	EndIf;
	
EndProcedure

// Creates A Document.Receipt of the Storehouse goods on the basis of the Document.Transfer of goods to the Keeper
//
// Parameters:
//  ReferencesArrray - Array -
//  ExecutionParameters - Structure - Contains:
//                         * CommandDetails - Structure - Contains:
//                            ** AdditionalParameters - Structure - 
//
Procedure ReceiptOfGoodsFromCustodianOperationReturnFromProcessorToCreateOnBasisOf(
			ReferencesArrray, ExecutionParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"CommonModule.ProcessingByThirdPartiesClient.ReceiptOfGoodsFromCustodianOperationReturnFromProcessorToCreateOnBasisOf");
	
	CommandExecuteParameters = New Structure("Source, Uniqueness, Window, URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);

	InvoiceName		  = "ReceiptOfGoodsFromCustodian";
	BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromProcessingCompany2_5");
	
	OpeningParameters = GenerationByReferenceTMServerCall.ParametersForOpeningInvoiceFormBasedOnOrder(
							ReferencesArrray, InvoiceName, BusinessOperation);
	
	OpenForm(
		OpeningParameters.FormName,
		OpeningParameters.FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL,,
		OpeningParameters.FormWindowOpeningMode);
	
EndProcedure

// Creates A Document.Receipt of the Storehouse goods on the basis of the Document.Processing Order 2_5
//
// Parameters:
//  ReferencesArrray - Array -
//  ExecutionParameters - Structure - Contains:
//                         * CommandDetails - Structure - Contains:
//                            ** AdditionalParameters - Structure - 
//
Procedure ReceiptOfGoodsFromCustodianOperationReceiptFromProcessorToCreateOnBasisOf(
			ReferencesArrray, ExecutionParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"CommonModule.ProcessingByThirdPartiesClient.ReceiptOfGoodsFromCustodianOperationReceiptFromProcessorToCreateOnBasisOf");
	
	CommandExecuteParameters = New Structure("Source, Uniqueness, Window, URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);

	InvoiceName		  = "ReceiptOfGoodsFromCustodian";
	BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5");
	
	OpeningParameters = GenerationByReferenceTMServerCall.ParametersForOpeningInvoiceFormBasedOnOrder(
							ReferencesArrray, InvoiceName, BusinessOperation);
	
	If OpeningParameters.FormParameters.Basis.RegistrationViaRM Then
		
		ErrorText = NStr("vi = 'Không thể lập chứng từ. Để lập chứng từ, hãy sử dụng chỗ làm việc ""Chứng từ chuyển giao vào gia công (cần lập chứng từ)""';
						|ru = 'Документ не может быть оформлен. Для оформления воспользуйтесь рабочим местом ""Документы передачи в переработку (к оформлению)""';
						|en = 'The document cannot be registered. To register, use the ""Subcontracting services received - Unregistered documents"" workplace'; fa = 'The document cannot be registered. To register, use the ""Subcontracting services received - Unregistered documents"" workplace';
						|it = 'Il documento non può essere formalizzato. Per la formalizzazione, utilizzare la postazione di lavoro ""Documenti di trasferimento in elaborazione (in formalizzazione)""';
						|pl = 'Dokument nie może być utworzony. Aby utworzyć dokument użyj miejsca pracy ""Dokumenty przekazania do przetwarzania (do rejestracji)""';
						|tr = 'Belge düzenlenemez. Düzenleme için ""Fason üretim belgeleri (düzenlenecek)"" çalışma alanını kullanın'");
		Raise ErrorText;
		
	Else
		OpenForm(
			OpeningParameters.FormName,
			OpeningParameters.FormParameters,
			CommandExecuteParameters.Source,
			CommandExecuteParameters.Uniqueness,
			CommandExecuteParameters.Window,
			CommandExecuteParameters.URL,,
			OpeningParameters.FormWindowOpeningMode);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
