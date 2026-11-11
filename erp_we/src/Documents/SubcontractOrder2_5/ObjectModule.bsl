#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Status

// Sets the status for the document object
//
// Parameters:
//	NewStatus - String - Name of the status that will be set for orders
//	AdditionalParameters - Structure - Structure of additional parameters for setting the status.
//
// Returns:
//	Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.TollingOrderStatuses[NewStatus];
	
	If MeaningOfNewStatus = Enums.TollingOrderStatuses.ForFulfillment
		Or MeaningOfNewStatus = Enums.TollingOrderStatuses.Closed Then
		// The new status of the document is "For execution" or "Closed"
		If ValueIsFilled(RequestedDeliveryDate)
			And Status <> Enums.TollingOrderStatuses.Closed
			And Status <> Enums.TollingOrderStatuses.ForFulfillment Then
			For Each TSRow In ManufacturedProducts Do
				If Not ValueIsFilled(TSRow.DateOfReceipt) Then
					TSRow.DateOfReceipt = RequestedDeliveryDate;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	If AdditionalParameters <> Undefined Then
		OrdersServer.AdjustOrderLines(ThisObject, AdditionalParameters);
	EndIf;
	
	Status = MeaningOfNewStatus;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.SubcontractOrder2_5);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);
	
	Return CheckFilling();
	
EndFunction

// Corrects lines that had not been issued a receipt or warehouse warrant or there are differences in the measured products.
// 
// Parameters:
// 	ParametersStructure - See OrdersServer.OrderLineAdjustmentStructure
// Returns:
// 	See OrdersServer.ResultOfUndoingUnprocessedRows
//
Function AdjustOrderLines(ParametersStructure) Export
	Return Documents.SubcontractOrder2_5.AdjustOrderLines(ThisObject, ParametersStructure);
EndFunction

#EndRegion

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocumentBeforeFillingItOut();
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("CatalogRef.Partners") Then
		FillInDocumentBasedOnPartner(FillingData);
	ElsIf FillInDataType = Type("Structure") Then
		
		If FillingData.Property("Basis") Then
			
			BasisType = TypeOf(FillingData.Basis);
			If BasisType = Type("DocumentRef.SalesOrder") Then
				FillInDocumentBasedOnCustomerSOrder(FillingData);
			ElsIf BasisType = Type("DocumentRef.TransferOrder") Then
				FillInDocumentBasedOnTransferOrder(FillingData);
			ElsIf BasisType = Type("DocumentRef.MaterialProviderOrder2_5") Then
				FillOutDocumentBasedOnGiverSOrder(FillingData);
			EndIf;
			
		EndIf;
		
		If FillingData.Property("Goods") Then //Filling out of the "Provision of Needs" processing.
			
			FillPropertyValues(ThisObject, FillingData);
			ManufacturedProductsWarehouse = FillingData.Warehouse;
			
			ManufacturedProducts.Load(FillingData.Goods);
			
			If SeparationOfMaterialsByProductPurpose Then
				GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductsAndAssignments;
			Else
				GroupCosts = Enums.CostGroupingsInTollingOrder.ByProducts;
			EndIf;
			
			InitializeDocumentAfterAddingProducts();
		ElsIf FillingData.Property("References") Then
			
			ProcessingByOrder = True;
			
			FillPropertyValues(ThisObject, FillingData.HeaderAttributes);
			Documents.SubcontractOrder2_5.FillByStagesOfProduction(FillingData.References, ThisObject);
		EndIf;
	ElsIf FillInDataType = Type("DocumentRef.ProductionStage2_2") Then
		FillInDocumentBasedOnProductionStage(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.SalesOpportunitiesToCustomer") Then
		FillInDocumentBasedOnTransaction(FillingData);
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.SubcontractOrder2_5.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	InitializeDocument();
	
	AdditionalProperties.Insert("NeedToFillInCashRegisterWhenUsingMultipleCashRegistersIsFalse",   False);
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	
	If Not GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	EndIf;
	
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	
	If Not ValueIsFilled(MethodOfAllocatingFinishedProductCosts)
		And (GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductBOM
			Or GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductBOMAndAssignments
			Or GroupCosts = Enums.CostGroupingsInTollingOrder.NoGrouping) Then
		MethodOfAllocatingFinishedProductCosts = Enums.MethodsOfCostAllocatingOnProductCosts.ByCostShares;
	EndIf;
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DateEmpty = Date(1,1,1);
	
	MaximumRowCodeMaterials = 0;
	ProductsMaxRowCode   = 0;
	Status                         = Enums.TollingOrderStatuses.NotApproved;
	RequestedDeliveryDate        = DateEmpty;
	DateOfShipment                   = DateEmpty;
	DateOfReceipt                = DateEmpty;
	ApprovalDate               = DateEmpty;
	ExecutionDate                 = DateEmpty;
	Purpose                     = Undefined;
	TransferPurpose             = Undefined;
	DocumentBasis              = Undefined;
	MaximumNumberOfCostGroup  = 0;
	GoodsReceiptOption          = Undefined;
	
	InitializationParameters = New Structure("FillOutHouseholdOfOperation, BusinessOperation", True, CopiedObject.BusinessOperation);
	InitializeDocumentBeforeFillingItOut(InitializationParameters);
	
	// Production details
	For Each TSRow In ManufacturedProducts Do
		TSRow.RowCode       = 0;
		TSRow.DateOfReceipt = DateEmpty;
		TSRow.Canceled        = False;
		TSRow.CancellationReason   = Catalogs.ReasonsForPurchaseOrderCancellation.EmptyRef();
	EndDo;
	
	For Each TSRow In SideAndIntermediateRelease Do
		TSRow.RowCode       = 0;
		TSRow.DateOfReceipt = DateEmpty;
		TSRow.Canceled        = False;
		TSRow.CancellationReason   = Catalogs.ReasonsForPurchaseOrderCancellation.EmptyRef();
	EndDo;
	
	For Each TSRow In SupplyWithMaterialsAndWorks Do
		TSRow.RowCode     = 0;
		TSRow.DateOfShipment  = DateEmpty;
		TSRow.Canceled      = False;
		TSRow.Purpose    = Catalogs.Assignments.EmptyRef();
	EndDo;
	ProvisionInDocumentsServer.FillInDefaultSecurityOption(SupplyWithMaterialsAndWorks);
	
	For Each TSRow In Services Do
		TSRow.RowCode     = 0;
		TSRow.RowID = Undefined;
		TSRow.ExecutionDate = ExecutionDate;
		TSRow.Canceled       = False;
		TSRow.CancellationReason  = Undefined;
	EndDo;
	
	InitializeDocument();
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	For Each TSRow In PaymentScheduleSteps Do
		TSRow.PaymentDate = DateEmpty;
	EndDo;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentStatusAboveNotAgreed =
		Not Status = Enums.TollingOrderStatuses.NotApproved;
	MaximumPossibleDateOfShipmentOfMaterials = MaximumPossibleDateOfShipmentOfMaterials();
	DatesOfReceipt = MaximumProductionDatesOfCostGroups();
	
	QualityConfirmationDateRequired_ =
		Status = Enums.TollingOrderStatuses.ForFulfillment
			Or Status = Enums.TollingOrderStatuses.Closed;
	
	CostsServer.CheckUseOfBatchAccounting22(ThisObject, Date, Cancel);
	
	NotCheckedAttributeArray = New Array;
	
	If GroupCosts = Enums.CostGroupingsInTollingOrder.ByProducts
		Or GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductsAndAssignments Then
		NotCheckedAttributeArray.Add("MethodOfAllocatingFinishedProductCosts");
	EndIf;
	
	If GroupCosts = Enums.CostGroupingsInTollingOrder.NoGrouping
		Or GroupCosts = Enums.CostGroupingsInTollingOrder.ByProducts
		Or GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductsAndAssignments Then
		NotCheckedAttributeArray.Add("ManufacturedProducts.BillOfMaterials");
	EndIf;
	
	#Region GeneralChecks
	
	#Region ComplianceOfProcessorSReportsWithOrderToProcessor
	
	ProcessingByThirdParties.CheckComplianceOfProcessorSReportsWithOrderToProcessor(ThisObject, Cancel);
	
	#EndRegion
	
	#Region CostGroups
	
	CheckCostGroups(Cancel, NotCheckedAttributeArray);
	
	#EndRegion
	
	#Region TS_SetOfSeries
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.SubcontractOrder2_5);
	ProductsServer.CheckSeriesCompletion(
		ThisObject,
		SeriesSpecificationParameters.SupplyWithMaterialsAndWorks,
		Cancel,
		NotCheckedAttributeArray);
	
	#EndRegion
	
	#Region TS_Count
	
	RoundingParameters = Documents.SubcontractOrder2_5.TSParametersForRounding();
	
	ProductsServer.CheckQuantityRounding(ThisObject, Cancel, RoundingParameters.ManufacturedProducts);
	ProductsServer.CheckQuantityRounding(ThisObject, Cancel, RoundingParameters.SideAndIntermediateRelease);
	ProductsServer.CheckQuantityRounding(ThisObject, Cancel, RoundingParameters.SupplyWithMaterialsAndWorks);
	
	#EndRegion
	
	#Region TS_Services
	
	If ProcessingServices = Enums.OptionsOfRegisteringProcessingDocumentServices.RegisteredSeparately Then
		NotCheckedAttributeArray.Add("ExecutionDate");
		NotCheckedAttributeArray.Add("Services");
	EndIf;
	
	// The obligation to fill in the receipt date in the header
	AllLinesAreCanceled = TMCommonUse.AllLinesAreCanceled(ThisObject, "Services", "Canceled");
	If Not WorkPerformanceAsOneDay
		Or (WorkPerformanceAsOneDay And Not DocumentStatusAboveNotAgreed)
		Or (WorkPerformanceAsOneDay And AllLinesAreCanceled) Then
		NotCheckedAttributeArray.Add("ExecutionDate");
	EndIf;
	
	If Not DocumentStatusAboveNotAgreed Then
		NotCheckedAttributeArray.Add("Services.ExecutionDate");
	EndIf;
	
	NotCheckedAttributeArray.Add("Services.CancellationReason");
	
	// The date of completion of the work in the header must be at least the date of the document
	If WorkPerformanceAsOneDay
		And ValueIsFilled(ExecutionDate)
		And Not ProcessingServices = Enums.OptionsOfRegisteringProcessingDocumentServices.RegisteredSeparately
		And ExecutionDate < BegOfDay(Date) Then
		
		ErrorText = NStr("vi = 'Ngày thực hiện công việc không được nhỏ hơn ngày chứng từ %Date%';
						|ru = 'Дата выполнения работ должна быть не меньше даты документа %Date%';
						|en = 'Work completion date must be not earlier than the document date: %Date%'; fa = 'Work completion date must be not earlier than the document date: %Date%';
						|it = 'La data di esecuzione lavori non deve essere precedente alla data del documento %Date%';
						|pl = 'Data wykonania prac powinna być nie mniejsza niż data dokumentu %Date%';
						|tr = 'İş gerçekleştirme tarihi, belgenin %Date% tarihinden önce olmamalıdır'");
		ErrorText = StrReplace(ErrorText, "%Date%", Format(Date,"DLF=D"));
		
		Common.MessageToUser(ErrorText, ThisObject, "ExecutionDate", , Cancel);
		
	EndIf;
	
	// The month of the work completion date should not be more than the month of the last issue
	If WorkPerformanceAsOneDay
		And ValueIsFilled(ExecutionDate)
		And ValueIsFilled(BegOfMonth(MaximumPossibleDateOfShipmentOfMaterials))
		And Not ProcessingServices = Enums.OptionsOfRegisteringProcessingDocumentServices.RegisteredSeparately
		And ExecutionDate > MaximumPossibleDateOfShipmentOfMaterials Then
	
		ErrorText = NStr("vi = 'Tháng thực hiện công việc không được lớn hơn tháng tiếp nhận sản phẩm và phế liệu thu hồi (%Date%)';
						|ru = 'Месяц выполнения работ должен быть не больше месяца поступления продукции и возвратных отходов (%Date%)';
						|en = 'Work execution month must be not later than the month of products and recyclable waste receipt (%Date%)'; fa = 'Work execution month must be not later than the month of products and recyclable waste receipt (%Date%)';
						|it = 'Il mese di esecuzione lavoro non deve essere successivo al mese di ricezione della produzione e resi (%Date%)';
						|pl = 'Miesiąc wykonania prac powinien być nie większy niż miesiąc wpływu produkcji i odpadów zwrotnych (%Date%)';
						|tr = 'İş gerçekleştirme ayı, imal edilen ürünlerin ve geri dönüştürülebilir atıkların giriş ayından sonra olmamalıdır (%Date%)'");
		ErrorText =
			StrReplace(
				ErrorText,
				"%Date%",
				Format(MaximumPossibleDateOfShipmentOfMaterials, "DF='MMMM yyyy'"));
		
		Common.MessageToUser(ErrorText, ThisObject, "ExecutionDate", , Cancel);
		
	EndIf;
	
	For Each CurRow In Services Do
		
		// The date of completion of the work in the pm of the Service must be at least the date of the document
		If Not WorkPerformanceAsOneDay
			And ValueIsFilled(CurRow.ExecutionDate)
			And CurRow.ExecutionDate < BegOfDay(Date) Then
			
			ErrorText = NStr("vi = 'Ngày thực hiện công việc không được nhỏ hơn ngày chứng từ %Date% tại dòng %LineNumber% của danh sách ""Dịch vụ""';
							|ru = 'Дата выполнения работ должна быть не меньше даты документа %Date% в строке %LineNumber% списка ""Услуги""';
							|en = 'Work completion date must be not earlier than document date %Date% in line %LineNumber% of the ""Services"" list'; fa = 'Work completion date must be not earlier than document date %Date% in line %LineNumber% of the ""Services"" list';
							|it = 'La data di esecuzione lavoro non deve essere precedente alla data del documento %Date% nella riga %LineNumber% dell''elenco ""Servizi""';
							|pl = 'Data wykonania prac powinna być nie mniejsza niż data dokumentu ""%Date%"" w wierszu %LineNumber% listy ""Usługi""';
							|tr = 'İş gerçekleştirme tarihi, ""Hizmetler"" listesinin %LineNumber% satırındaki belgenin %Date% tarihinden önce olmamalıdır'");
			ErrorText = StrReplace(ErrorText, "%LineNumber%", CurRow.LineNumber);
			ErrorText = StrReplace(ErrorText, "%Date%", Format(Date,"DLF=D"));
			KTCHPath     = CommonClientServer.PathToTabularSection("Services", CurRow.LineNumber, "ExecutionDate");
			
			Common.MessageToUser(ErrorText, ThisObject, KTCHPath, , Cancel);
			
		EndIf;
		
		// The month of work should be no more than a month of receipt of products and returnable waste.
		GroupsReceiptDate = DatesOfReceipt.Get(CurRow.CostGroupNumber);
		If Not WorkPerformanceAsOneDay
			And ValueIsFilled(BegOfMonth(GroupsReceiptDate))
			And CurRow.ExecutionDate > GroupsReceiptDate Then
			
			ErrorText = NStr("vi = 'Tháng thực hiện công việc không được lớn hơn tháng tiếp nhận sản phẩm đầu ra (%Date%)';
							|ru = 'Месяц выполнения работ должен быть не больше месяца поступления выходных изделий (%Date%)';
							|en = 'Work execution month must be not later than the month of finished product receipt (%Date%)'; fa = 'Work execution month must be not later than the month of finished product receipt (%Date%)';
							|it = 'Il mese di esecuzione lavoro non deve essere successivo al mese di ricezione della produzione in uscita (%Date%)';
							|pl = 'Miesiąc wykonania prac powinien być nie większy niż miesiąc wpływu gotowych produktów (%Date%)';
							|tr = 'İş gerçekleştirme ayı, üretilen nihai ürünlerin giriş ayından sonra olmamalıdır (%Date%)'");
			ErrorText =
				StrReplace(
					ErrorText,
					"%Date%",
					Format(GroupsReceiptDate, "DF='MMMM yyyy'"));
			KTCHPath = CommonClientServer.PathToTabularSection("Services", CurRow.LineNumber, "ExecutionDate");
			
			Common.MessageToUser(ErrorText, ThisObject, KTCHPath,, Cancel);
			
		EndIf;
		
		// The reason for cancellation is required to be filled in the canceled lines
		If GetFunctionalOption("UseReasonsForPurchaseOrderCancellations")
			And CurRow.Canceled
			And Not ValueIsFilled(CurRow.CancellationReason) Then
			
			ErrorText = NStr("vi = 'Cần chỉ ra nguyên nhân hủy bỏ trong các dòng %LineNumber% của danh sách ""Dịch vụ""';
							|ru = 'Необходимо указать причину отмены в строке %LineNumber% списка ""Услуги""';
							|en = 'Specify a cancellation reason in line %LineNumber% of the Services list'; fa = 'Specify a cancellation reason in line %LineNumber% of the Services list';
							|it = 'È necessario indicare il motivo di annullamento nella riga %LineNumber% dell''elenco ""Servizi""';
							|pl = 'Należy podać przyczynę anulować w wierszu %LineNumber% listy ""Usługi""';
							|tr = '""Hizmetler"" listesinin %LineNumber% satırında iptal nedeni belirtilmelidir'");
			ErrorText = StrReplace(ErrorText, "%LineNumber%", CurRow.LineNumber);
			KTCHPath     = CommonClientServer.PathToTabularSection("Services", CurRow.LineNumber, "CancellationReason");
			
			Common.MessageToUser(ErrorText, ThisObject, KTCHPath, , Cancel);
			
		EndIf;
		
	EndDo;
	
	If ProcessingServices = Enums.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder Then
		CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
		CheckParameters.TSName = "Services";
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
	EndIf;
	
	#EndRegion
	
	#Region Delivery
	GoodsDelivery.CheckDeliveryDetails(ThisObject, NotCheckedAttributeArray, Cancel);
	#EndRegion
	
	#Region VATAccounting
	
	CheckParameters = VATAccountingERP.VerificationParametersFillingInDocumentOnVATTaxationPurchases();
	CheckParameters.TabularSectionName						= "ManufacturedProducts";
	CheckParameters.BankingDetailsNameExpenseItem			= "ExpenseItem";
	CheckParameters.ExpenseAnalystDetailsName			= "DimensionOfExpenses";
	
	VATAccountingERP.CheckCompletionOfPurchaseDocumentForVATTaxation(
		ThisObject,
		VATTaxation,
		CheckParameters,
		Cancel);
	
	CheckParameters.TabularSectionName = "SideAndIntermediateRelease";
	
	VATAccountingERP.CheckCompletionOfPurchaseDocumentForVATTaxation(
		ThisObject,
		VATTaxation,
		CheckParameters,
		Cancel);
	
	CheckParameters = VATAccountingERP.ParametersForCheckingDocumentFillingByTypeOfActivity();
	CheckParameters.TabularSectionName						= "ManufacturedProducts";
	CheckParameters.BankingDetailsNameExpenseItem			= "ExpenseItem";
	CheckParameters.ExpenseAnalystDetailsName			= "DimensionOfExpenses";
	CheckParameters.DetailsNameItemOfAssetsLiabilities		= "ExpenseItem";
	CheckParameters.NameOfAssetLiabilityAnalystDetails	= "AssetsLiabilitiesDimension";
	
	VATAccountingERP.CheckCompletionOfDocumentByTypeOfVATActivity(
		ThisObject,
		PurchaseForActivity,
		CheckParameters,
		Cancel);
	
	CheckParameters.TabularSectionName = "SideAndIntermediateRelease";
	
	VATAccountingERP.CheckCompletionOfDocumentByTypeOfVATActivity(
		ThisObject,
		PurchaseForActivity,
		CheckParameters,
		Cancel);
	
	#EndRegion
	
	#Region ARAPAccounting
	// The validity period of the order must be at least the date of the document
	If Not Status = Enums.TollingOrderStatuses.NotApproved And
		ValueIsFilled(ApprovalDate) And ApprovalDate < BegOfDay(Date) Then
		
		ErrorText = NStr("vi = 'Ngày thống nhất không được nhỏ hơn ngày chứng từ %Date%';
						|ru = 'Дата согласования должна быть не меньше даты документа %Date%';
						|en = 'Date of approval cannot be before the document creation: %Date%'; fa = 'Date of approval cannot be before the document creation: %Date%';
						|it = 'La data della definizione non deve essere inferiore alla data del documento %Date%';
						|pl = 'Data uzgodnienia powinna być nie mniejsza niż data dokumentu %Date%';
						|tr = 'Onay tarihi, belgenin %Date% tarihinden önce olmamalıdır'");
		ErrorText = StrReplace(ErrorText, "%Date%", Format(Date, "DLF=DD"));
		
		Common.MessageToUser(ErrorText, ThisObject, "ApprovalDate",, Cancel);
		
	EndIf;
	#EndRegion
	
	#EndRegion
	If Not GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		#Region OrderVerificationWithoutOrders
		
		#Region ManufacturedProductsWarehouse
		If LeaveProductsAtSubcontractor Then
			NotCheckedAttributeArray.Add("ManufacturedProductsWarehouse");
		EndIf;
		#EndRegion
		
		#Region DateInHeader
		
		// The obligation to fill in the receipt date in the header
		AllLinesAreCanceled = TMCommonUse.AllLinesAreCanceled(ThisObject, "ManufacturedProducts", "Canceled");
		If Not OneDateReceipt
			Or (OneDateReceipt And Not DocumentStatusAboveNotAgreed)
			Or (OneDateReceipt And AllLinesAreCanceled) Then
			NotCheckedAttributeArray.Add("DateOfReceipt");
		EndIf;
		
		// The date of receipt in the header must be at least the date of the document
		If OneDateReceipt
			And ValueIsFilled(DateOfReceipt)
			And DateOfReceipt < BegOfDay(Date) Then
			
			ErrorText = NStr("vi = 'Ngày tiếp nhận không được nhỏ hơn ngày chứng từ %Date%';
							|ru = 'Дата поступления должна быть не меньше даты документа %Date%';
							|en = 'Date of receipt cannot be less than document date %Date%'; fa = 'Date of receipt cannot be less than document date %Date%';
							|it = 'La data dell''arrivo non deve essere inferiore alla data del documento %Date%';
							|pl = 'Data wpłaty powinna być nie mniejsza niż data dokumentu %Date%';
							|tr = 'Giriş tarihi, belgenin %Date% tarihinden önce olmamalıdır'");
			ErrorText = StrReplace(ErrorText, "%Date%", Format(Date,"DLF=D"));
			
			Common.MessageToUser(ErrorText, ThisObject, "DateOfReceipt", , Cancel);
			
		EndIf;
		
		// The date of shipment in the header must be at least the date of the document
		If NotShipInInstallments
			And ValueIsFilled(DateOfShipment)
			And DateOfShipment < BegOfDay(Date) Then
			
			ErrorText = NStr("vi = 'Ngày giao hàng không được nhỏ hơn ngày chứng từ %Date%';
							|ru = 'Дата отгрузки должна быть не меньше даты документа %Date%';
							|en = 'Shipment date cannot be less than document date%Date%'; fa = 'Shipment date cannot be less than document date%Date%';
							|it = 'La data della spedizione non deve essere inferiore alla data del documento %Date%';
							|pl = 'Data wysyłki powinna być nie mniejsza niż data dokumentu %Date%';
							|tr = 'Sevkiyat tarihi, belgenin %Date% tarihinden önce olmamalıdır'");
			ErrorText = StrReplace(ErrorText, "%Date%", Format(Date,"DLF=D"));
			
			Common.MessageToUser(ErrorText, ThisObject, "DateOfShipment", , Cancel);
			
		EndIf;
		
		// The month of the shipment date should not be more than the month of the last issue
		If NotShipInInstallments
			And ValueIsFilled(DateOfShipment)
			And ValueIsFilled(BegOfMonth(MaximumPossibleDateOfShipmentOfMaterials))
			And DateOfShipment > MaximumPossibleDateOfShipmentOfMaterials Then
		
			ErrorText = NStr("vi = 'Tháng giao hàng không được lớn hơn tháng tiếp nhận thành phẩm và phế liệu thu hồi (%Date%)';
							|ru = 'Месяц отгрузки должен быть не больше месяца поступления продукции и возвратных отходов (%Date%)';
							|en = 'Shipment month cannot be later than the month of products and recyclable waste receipt (%Date%)'; fa = 'Shipment month cannot be later than the month of products and recyclable waste receipt (%Date%)';
							|it = 'Il mese di spedizione non deve essere successivo al mese del ricezione della produzione e scarti restituibili (%Date%)';
							|pl = 'Miesiąc wysyłki musi być nie większy niż miesiąc wpływu produkcji i odpadów zwrotnych (%Date%)';
							|tr = 'Sevkiyat ayı, imal edilen ürünlerin ve geri dönüştürülebilir atıkların giriş ayından sonra olmamalıdır (%Date%)'");
			ErrorText =
				StrReplace(
					ErrorText,
					"%Date%",
					Format(MaximumPossibleDateOfShipmentOfMaterials, "DF='MMMM yyyy'"));
			
			Common.MessageToUser(ErrorText, ThisObject, "DateOfShipment", , Cancel);
			
		EndIf;
		
		#EndRegion
		
		#Region Header_DesiredReceiptDate
		
		// The desired date of receipt in the header must be at least the date of the document
		If ValueIsFilled(RequestedDeliveryDate)
			And RequestedDeliveryDate < BegOfDay(Date) Then
			
			ErrorText = NStr("vi = 'Ngày tiếp nhận không được nhỏ hơn ngày chứng từ %Date%';
							|ru = 'Дата поступления должна быть не меньше даты документа %Date%';
							|en = 'Date of receipt cannot be less than document date %Date%'; fa = 'Date of receipt cannot be less than document date %Date%';
							|it = 'La data dell''arrivo non deve essere inferiore alla data del documento %Date%';
							|pl = 'Data wpłaty powinna być nie mniejsza niż data dokumentu %Date%';
							|tr = 'Giriş tarihi, belgenin %Date% tarihinden önce olmamalıdır'");
			ErrorText = StrReplace(ErrorText, "%Date%", Format(Date,"DLF=D"));
			
			Common.MessageToUser(ErrorText, ThisObject, "RequestedDeliveryDate", , Cancel);
			
		EndIf;
		
		#EndRegion
		
		#Region Header_Division
		
		// Checking the filling of the department for the order with the status "to be provided" and higher.
		If Not DocumentStatusAboveNotAgreed
			And Not GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then 
			NotCheckedAttributeArray.Add("Department");
		EndIf;
		
		#EndRegion
		
		#Region TS_Characteristics
		
		CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
		
		CheckParameters.TSName = "ManufacturedProducts";
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
		
		CheckParameters.TSName = "SideAndIntermediateRelease";
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
		
		CheckParameters.TSName = "SupplyWithMaterialsAndWorks";
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
		
		#EndRegion
		
		#Region TS_ProductCostElement
		
		If Not DocumentStatusAboveNotAgreed Then
			NotCheckedAttributeArray.Add("SideAndIntermediateRelease.ProductCostElement");
			NotCheckedAttributeArray.Add("SupplyWithMaterialsAndWorks.ProductCostElement");
			NotCheckedAttributeArray.Add("Services.ProductCostElement");
		EndIf;
		
		#EndRegion
		
		#Region TS_ManufacturedProducts
		
		NotCheckedAttributeArray.Add("ManufacturedProducts.Purpose");
		NotCheckedAttributeArray.Add("ManufacturedProducts.Recipient");
		NotCheckedAttributeArray.Add("ManufacturedProducts.DateOfReceipt");
		NotCheckedAttributeArray.Add("ManufacturedProducts.CancellationReason");
		
		For CurIndex__ = 0 To ManufacturedProducts.Count() - 1 Do
			
			CurRow = ManufacturedProducts[CurIndex__];
			
			// The receipt date is required to be filled only for orders in 
			// the statuses of Non-fulfillment, Non-fulfillment, Closed.
			If DocumentStatusAboveNotAgreed
				And Not CurRow.Canceled
				And Not ValueIsFilled(CurRow.DateOfReceipt) Then
				
				ErrorText = NStr("vi = 'Chưa điền cột ""Ngày tiếp nhận"" tại dòng %LineNumber% của danh sách ""Sản phẩm đầu ra""';
								|ru = 'Не заполнена колонка ""Дата поступления"" в строке %LineNumber% списка ""Выходные изделия""';
								|en = 'The ""Date of receipt"" column in line %LineNumber% of the ""Finished products"" list is not filled in'; fa = 'The ""Date of receipt"" column in line %LineNumber% of the ""Finished products"" list is not filled in';
								|it = 'Colonna ""Data di ricezione"" non compilata nella riga %LineNumber% dell''elenco ""Produzione in uscita""';
								|pl = 'Nie wypełniono kolumny ""Data wpływu"" w wierszu %LineNumber% listy ""Wyroby wyjściowe""';
								|tr = '""Üretilen Nihai Ürünler"" listesinin %LineNumber% satırında ""Giriş Tarihi"" sütunu doldurulmadı'");
				ErrorText = StrReplace(ErrorText, "%LineNumber%", CurRow.LineNumber);
				KTCHPath     = CommonClientServer.PathToTabularSection("ManufacturedProducts", CurRow.LineNumber, "DateOfReceipt");
				
				Common.MessageToUser(ErrorText, ThisObject, KTCHPath, , Cancel);
				
			EndIf;
			
			// The date of receipt in pm output products must be at least the date of the document
			If Not OneDateReceipt
				And ValueIsFilled(CurRow.DateOfReceipt)
				And CurRow.DateOfReceipt < BegOfDay(Date) Then
				
				ErrorText = NStr("vi = 'Ngày tiếp nhận không được nhỏ hơn ngày chứng từ %Date% tại dòng %LineNumber% trong danh sách ""Sản phẩm đầu ra""';
								|ru = 'Дата поступления должна быть не меньше даты документа %Date% в строке %LineNumber% списка ""Выходные изделия""';
								|en = 'Receipt date cannot be less than document date ""%Date%"" in line %LineNumber% of the ""Finished products"" list'; fa = 'Receipt date cannot be less than document date ""%Date%"" in line %LineNumber% of the ""Finished products"" list';
								|it = 'La data di ricezione non deve essere precedente alla data del documento %Date% nella riga %LineNumber% dell''elenco ""Produzione in uscita""';
								|pl = 'Data wpływu powinna być nie mniejsza niż data dokumentu %Date% w wierszu %LineNumber% listy ""Wyroby wyjściowe""';
								|tr = 'Giriş tarihi, ""Üretilen Nihai Ürünler"" listesinin %LineNumber% satırındaki belgenin %Date% tarihinden önce olmamalıdır'");
				ErrorText = StrReplace(ErrorText, "%LineNumber%", CurRow.LineNumber);
				ErrorText = StrReplace(ErrorText, "%Date%", Format(Date,"DLF=D"));
				KTCHPath     = CommonClientServer.PathToTabularSection("ManufacturedProducts", CurRow.LineNumber, "DateOfReceipt");
				
				Common.MessageToUser(ErrorText, ThisObject, KTCHPath, , Cancel);
				
			EndIf;
			
			// The reason for cancellation is required to be filled in the canceled lines
			If GetFunctionalOption("UseReasonsForPurchaseOrderCancellations")
				And CurRow.Canceled
				And Not ValueIsFilled(CurRow.CancellationReason) Then
				
				ErrorText = NStr("vi = 'Cần chỉ ra lý do hủy tại dòng %LineNumber% của danh sách ""Sản phẩm đầu ra""';
								|ru = 'Необходимо указать причину отмены в строке %LineNumber% списка ""Выходные изделия""';
								|en = 'Cancellation reason is required in line %LineNumber% of the ""Finished products"" list'; fa = 'Cancellation reason is required in line %LineNumber% of the ""Finished products"" list';
								|it = 'È necessario indicare il motivo dell''annullamento nella riga %LineNumber% dell''elenco ""Produzione in uscita""';
								|pl = 'Należy podać przyczynę anulowania w wierszu %LineNumber% listy ""Wyroby wyjściowe""';
								|tr = '""Üretilen Nihai Ürünler"" listesinin %LineNumber% satırında iptal nedeni belirtilmelidir'");
				ErrorText = StrReplace(ErrorText, "%LineNumber%", CurRow.LineNumber);
				KTCHPath     = CommonClientServer.PathToTabularSection("ManufacturedProducts", CurRow.LineNumber, "CancellationReason");
				
				Common.MessageToUser(ErrorText, ThisObject, KTCHPath, , Cancel);
				
			EndIf;
			
		EndDo;
		
		ProductionServer.CheckIfCostFractionsAreFilledInInTablePart(
			ThisObject, "ManufacturedProducts", NotCheckedAttributeArray, Cancel);
		
		If DocumentStatusAboveNotAgreed Then
			ProductionServer.CheckRecipientSFillingInTablePart(ThisObject, "ManufacturedProducts", Cancel);
		EndIf;
		
		QualityControl.ProcessingVerificationOfFillingInReceiptDocument(
			ThisObject,
			NotCheckedAttributeArray,
			Cancel,
			"ManufacturedProducts",
			NStr("vi = 'Sản phẩm giá trị ước tính';
				|ru = 'Изделия по рассчитываемой стоимости';
				|en = 'Products by calculated cost'; fa = 'محصولات بر اساس بهای محاسبه‌شده';
				|it = 'Prodotti in base al valore calcolato';
				|pl = 'Wyroby po szacowanej cenie';
				|tr = 'Hesaplanan maliyete göre nihai ürünler'"),
			".DateOfReceipt",
			QualityConfirmationDateRequired_);
		
		#EndRegion
		
		#Region TS_SideAndIntermediateRelease
		
		NotCheckedAttributeArray.Add("SideAndIntermediateRelease");
		NotCheckedAttributeArray.Add("SideAndIntermediateRelease.Recipient");
		NotCheckedAttributeArray.Add("SideAndIntermediateRelease.DateOfReceipt");
		NotCheckedAttributeArray.Add("SideAndIntermediateRelease.CancellationReason");
		
		For CurIndex__ = 0 To SideAndIntermediateRelease.Count() - 1 Do
			
			CurRow = SideAndIntermediateRelease[CurIndex__];
			
			// The receipt date is required to be filled only for orders in 
			// the statuses of Non-fulfillment, Non-fulfillment, Closed.
			If DocumentStatusAboveNotAgreed
				And Not CurRow.Canceled
				And Not ValueIsFilled(CurRow.DateOfReceipt) Then
				
				ErrorText = NStr("vi = 'Chưa điền cột ""Ngày tiếp nhận"" tại dòng %LineNumber% của danh sách ""Sản phẩm phụ""';
								|ru = 'Не заполнена колонка ""Дата поступления"" в строке %LineNumber% списка ""Побочные изделия""';
								|en = 'The ""Date of receipt"" column in line %LineNumber% of the ""By-products"" list is not filled in'; fa = 'The ""Date of receipt"" column in line %LineNumber% of the ""By-products"" list is not filled in';
								|it = 'Colonna ""Data di ricezione"" non compilata nella riga %LineNumber% dell''elenco ""Sottoprodotti""';
								|pl = 'Nie wypełniono kolumny ""Data wpływu"" w wierszu %LineNumber% listy ""Wyroby poboczne""';
								|tr = '""Yan Nihai Ürünler"" listesinin %LineNumber% satırında ""Giriş Tarihi"" sütunu doldurulmadı'");
				ErrorText = StrReplace(ErrorText, "%LineNumber%", CurRow.LineNumber);
				KTCHPath     = CommonClientServer.PathToTabularSection("SideAndIntermediateRelease", CurRow.LineNumber, "DateOfReceipt");
				
				Common.MessageToUser(ErrorText, ThisObject, KTCHPath, , Cancel);
				
			EndIf;
			
			// The date of receipt of the pm by-products must be at least the date of the document
			If Not OneDateReceipt
				And ValueIsFilled(CurRow.DateOfReceipt)
				And CurRow.DateOfReceipt < BegOfDay(Date) Then
				
				ErrorText = NStr("vi = 'Ngày tiếp nhận không được nhỏ hơn ngày chứng từ %Date% tại dòng %LineNumber% trong danh sách ""Sản phẩm phụ""';
								|ru = 'Дата поступления должна быть не меньше даты документа %Date% в строке %LineNumber% списка ""Побочные изделия""';
								|en = 'Receipt date cannot be less than document date ""%Date%"" in line %LineNumber% of the ""By-products"" list'; fa = 'Receipt date cannot be less than document date ""%Date%"" in line %LineNumber% of the ""By-products"" list';
								|it = 'La data di ricezione non deve essere precedente alla data del documento %Date% nella riga %LineNumber% dell''elenco ""Sottoprodotti""';
								|pl = 'Data wpływu powinna być nie mniejsza niż data dokumentu %Date% w wierszu %LineNumber% listy ""Wyroby poboczne""';
								|tr = 'Giriş tarihi, ""Yan Nihai Ürünler"" listesinin %LineNumber% satırındaki belgenin %Date% tarihinden önce olmamalıdır'");
				ErrorText = StrReplace(ErrorText, "%LineNumber%", CurRow.LineNumber);
				ErrorText = StrReplace(ErrorText, "%Date%", Format(Date,"DLF=D"));
				KTCHPath     = CommonClientServer.PathToTabularSection("SideAndIntermediateRelease", CurRow.LineNumber, "DateOfReceipt");
				
				Common.MessageToUser(ErrorText, ThisObject, KTCHPath, , Cancel);
				
			EndIf;
			
			// The reason for cancellation is required to be filled in the canceled lines
			If GetFunctionalOption("UseReasonsForPurchaseOrderCancellations")
				And CurRow.Canceled
				And Not ValueIsFilled(CurRow.CancellationReason) Then
				
				ErrorText = NStr("vi = 'Cần chỉ ra lý do hủy tại dòng %LineNumber% của danh sách ""Sản phẩm phụ""';
								|ru = 'Необходимо указать причину отмены в строке %LineNumber% списка ""Побочные изделия""';
								|en = 'Cancellation reason is required in line %LineNumber% of the ""By-products"" list'; fa = 'Cancellation reason is required in line %LineNumber% of the ""By-products"" list';
								|it = 'È necessario indicare il motivo di annullamento nella riga %LineNumber% dell''elenco ""Sottoprodotti""';
								|pl = 'Należy podać przyczynę anulowania w wierszu %LineNumber% listy ""Wyroby poboczne""';
								|tr = '""Yan Nihai Ürünler"" listesinin %LineNumber% satırında iptal nedeni belirtilmelidir'");
				ErrorText = StrReplace(ErrorText, "%LineNumber%", CurRow.LineNumber);
				KTCHPath     = CommonClientServer.PathToTabularSection("SideAndIntermediateRelease", CurRow.LineNumber, "CancellationReason");
				
				Common.MessageToUser(ErrorText, ThisObject, KTCHPath, , Cancel);
				
			EndIf;
			
		EndDo;
		
		If DocumentStatusAboveNotAgreed Then
			ProductionServer.CheckRecipientSFillingInTablePart(ThisObject, "SideAndIntermediateRelease", Cancel);
		EndIf;
		
		QualityControl.ProcessingVerificationOfFillingInReceiptDocument(
			ThisObject,
			NotCheckedAttributeArray,
			Cancel,
			"SideAndIntermediateRelease",
			NStr("vi = 'Sản phẩm phụ và xuất xưởng trung gian với giá trị cố định';
				|ru = 'Побочный и промежуточный выход по фиксированной стоимости';
				|en = 'Side and intermediate product at fixed cost'; fa = 'محصول فرعی و میانی با بهای ثابت';
				|it = 'Uscita collaterale e intermedia ad un costo fisso';
				|pl = 'Produkcja poboczna i pośrednia po stałej cenie';
				|tr = 'Sabit maliyetle yan ve ara ürün çıkışı'"),
			".DateOfReceipt",
			QualityConfirmationDateRequired_);
		
		#EndRegion
		
		#Region TS_SupplyWithMaterialsAndWorks
		
		NotCheckedAttributeArray.Add("SupplyWithMaterialsAndWorks.DateOfShipment");
		NotCheckedAttributeArray.Add("SupplyWithMaterialsAndWorks.Warehouse");
		
		EmbeddingParameters = Documents.SubcontractOrder2_5.AvailableRemainingEmbeddingOptions();
		ErrorsTable = ProvisionInDocumentsServer.TableOfFillingErrors(ThisObject, EmbeddingParameters);
		
		DateOfShipmentRequired_ = False;
		TextTemplateShipmentDate = NStr("vi = 'Chưa điền cột ""Ngày giao hàng"" tại dòng %LineNumber% trong danh sách ""Nguyên vật liệu và công việc"".';
										|ru = 'Не заполнена колонка ""Дата отгрузки"" в строке %LineNumber% списка ""Материалы и работы"".';
										|en = 'Column ""Shipment date"" in line %LineNumber% of the ""Materials and works"" list is not filled in.'; fa = 'Column ""Shipment date"" in line %LineNumber% of the ""Materials and works"" list is not filled in.';
										|it = 'Colonna ""Data di spedizione"" non compilata nella riga %LineNumber% dell''elenco ""Materiali e lavori"".';
										|pl = 'Nie wypełniono kolumny ""Data wysyłki"" w wierszu %LineNumber% listy ""Materiały i prace"".';
										|tr = '""Malzemeler ve İşler"" listesinin %LineNumber% satırında ""Sevkiyat Tarihi"" sütunu doldurulmadı.'");
		WarehouseTextTemplate        = NStr("vi = 'Chưa điền cột ""Kho bãi"" tại dòng %LineNumber% của danh sách ""Nguyên vật liệu và công việc"".';
											|ru = 'Не заполнена колонка ""Склад"" в строке %LineNumber% списка ""Материалы и работы"".';
											|en = 'The ""Warehouse"" column in line %LineNumber% of the ""Materials and works"" list is not filled in.'; fa = 'The ""Warehouse"" column in line %LineNumber% of the ""Materials and works"" list is not filled in.';
											|it = 'Non è compilata la colonna ""Magazzino"" nella riga %LineNumber% dell''elenco ""Materiali e lavori"".';
											|pl = 'Nie wypełniono kolumny ""Magazyn"" w wierszu %LineNumber% listy ""Materiały i prace"".';
											|tr = '""Malzemeler ve İşler"" listesinin %LineNumber% satırında ""Ambar"" sütunu doldurulmadı.'");
		
		For CurIndex__ = 0 To ErrorsTable.Count() - 1 Do
			
			ErrorString = ErrorsTable[CurIndex__];
			
			If Not NotShipInInstallments
				And ErrorString.DateOfShipmentRequired_
				And ErrorString.ShipmentDateNotFilledIn Then
				
				ErrorText   = StrReplace(TextTemplateShipmentDate, "%LineNumber%", ErrorString.LineNumber);
				PathToTop = CommonClientServer.PathToTabularSection("SupplyWithMaterialsAndWorks", ErrorString.LineNumber, "DateOfShipment");
				Common.MessageToUser(ErrorText, ThisObject, PathToTop, , Cancel);
				
			EndIf;
			
			If ErrorString.WarehouseIsRequired
				And ErrorString.WarehouseIsNotFull Then
				
				ErrorText   = StrReplace(WarehouseTextTemplate, "%LineNumber%", ErrorString.LineNumber);
				PathToTop = CommonClientServer.PathToTabularSection("SupplyWithMaterialsAndWorks", ErrorString.LineNumber, "Warehouse");
				Common.MessageToUser(ErrorText, ThisObject, PathToTop, , Cancel);
				
			EndIf;
			DateOfShipmentRequired_ = DateOfShipmentRequired_ Or ErrorString.DateOfShipmentRequired_;
			
		EndDo;
		
		For CurIndex__ = 0 To SupplyWithMaterialsAndWorks.Count()-1 Do
			
			CurRow = SupplyWithMaterialsAndWorks[CurIndex__];
			
			If ValueIsFilled(CurRow.DateOfShipment) Then
				
				// The date of shipment in pm of the provision of materials and works must be at least the date of the document
				If Not NotShipInInstallments
					And CurRow.DateOfShipment < BegOfDay(Date) Then
					
					ErrorText = NStr("vi = 'Ngày giao hàng không được nhỏ hơn ngày chứng từ ""%Date%"" trong dòng %LineNumber% của danh sách ""Nguyên vật liệu và công việc"".';
									|ru = 'Дата отгрузки должна быть не меньше даты документа ""%Date%"" в строке %LineNumber% списка ""Материалы и работы"".';
									|en = 'Shipment date cannot be less than document date ""%Date%"" in line %LineNumber% of the ""Materials and works"" list.'; fa = 'Shipment date cannot be less than document date ""%Date%"" in line %LineNumber% of the ""Materials and works"" list.';
									|it = 'La data di spedizione non deve essere precedente alla data del documento ""%Date%"" nella riga %LineNumber% dell''elenco ""Materiali e lavori"".';
									|pl = 'Data wysyłki powinna być nie mniejsza niż data dokumentu ""%Date%"" w wierszu %LineNumber% listy ""Materiały i prace"".';
									|tr = 'Sevkiyat tarihi, ""Malzemeler ve İşler"" listesinin %LineNumber% satırındaki belgenin ""%Date%"" tarihinden önce olmamalıdır.'");
					ErrorText = StrReplace(ErrorText, "%LineNumber%", CurRow.LineNumber);
					ErrorText = StrReplace(ErrorText, "%Date%", Format(Date, "DLF=D"));
					KTCHPath     = CommonClientServer.PathToTabularSection("SupplyWithMaterialsAndWorks", CurRow.LineNumber, "DateOfShipment");
					
					Common.MessageToUser(ErrorText, ThisObject, KTCHPath, , Cancel);
					
				EndIf;
				
				// The month of shipment should be no more than a month of receipt of products and returnable waste.
				GroupsReceiptDate = DatesOfReceipt.Get(CurRow.CostGroupNumber);
				If Not GroupsReceiptDate = Undefined
					And Not NotShipInInstallments
					And ValueIsFilled(BegOfMonth(GroupsReceiptDate))
					And CurRow.DateOfShipment > GroupsReceiptDate Then
					
					ErrorText = NStr("vi = 'Tháng giao hàng không được lớn hơn tháng tiếp nhận sản phẩm đầu ra (%Date%)';
									|ru = 'Месяц отгрузки должен быть не больше месяца поступления выходных изделий (%Date%)';
									|en = 'Shipment month cannot be greater than the month of finished product receipt (%Date%)'; fa = 'Shipment month cannot be greater than the month of finished product receipt (%Date%)';
									|it = 'Il mese di spedizione non deve essere successivo al mese di ricezione della produzione in uscita (%Date%)';
									|pl = 'Miesiąc wysyłki powinien być nie większy niż miesiąc wpływu wyrobów wyjściowych (%Date%)';
									|tr = 'Sevkiyat ayı, üretilen nihai ürünlerin giriş ayından sonra olmamalıdır (%Date%)'");
					ErrorText =
						StrReplace(
							ErrorText,
							"%Date%",
							Format(
								GroupsReceiptDate,
								NStr("vi = 'ДФ=''ММММ ""năm"" г'';';
									|ru = 'ДФ=''ММММ г""""г.""""'';';
									|en = 'DF=''MMMM y'';'; fa = 'DF=''MMMM y'';';
									|it = 'DF=""MMMM y""""y.''"""";';
									|pl = 'DF=''MMMM y""""r.""""'';';
									|tr = 'DF=''MMMM y""""y.""""'';'")));
					KTCHPath = CommonClientServer.PathToTabularSection("SupplyWithMaterialsAndWorks", CurRow.LineNumber, "DateOfShipment");
					
					Common.MessageToUser(ErrorText, ThisObject, KTCHPath,, Cancel);
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
		If Not DateOfShipmentRequired_
			Or Not NotShipInInstallments Then
			NotCheckedAttributeArray.Add("DateOfShipment");
		EndIf;
		
		#EndRegion
		
		ItemsAndDimensionsSelectionParameters = Documents.SubcontractOrder2_5.ItemsAndDimensionsSelectionParameters();
		IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
		
		#EndRegion
	Else
	
	#Region DisablingOrderChecksBasedOnOrders
		
		NotCheckedAttributeArray.Add("DateOfReceipt");
		NotCheckedAttributeArray.Add("DateOfShipment");
		NotCheckedAttributeArray.Add("ExecutionDate");
		NotCheckedAttributeArray.Add("ManufacturedProductsWarehouse");
		NotCheckedAttributeArray.Add("MaterialsWarehouse");
		NotCheckedAttributeArray.Add("MethodOfAllocatingFinishedProductCosts");
		
		NotCheckedAttributeArray.Add("ManufacturedProducts");
		NotCheckedAttributeArray.Add("ManufacturedProducts.Products");
		NotCheckedAttributeArray.Add("ManufacturedProducts.Characteristic");
		NotCheckedAttributeArray.Add("ManufacturedProducts.BillOfMaterials");
		NotCheckedAttributeArray.Add("ManufacturedProducts.Purpose");
		NotCheckedAttributeArray.Add("ManufacturedProducts.CostShare");
		NotCheckedAttributeArray.Add("ManufacturedProducts.DateOfReceipt");
		NotCheckedAttributeArray.Add("ManufacturedProducts.NumberOfPackages");
		NotCheckedAttributeArray.Add("ManufacturedProducts.Count");
		NotCheckedAttributeArray.Add("ManufacturedProducts.Recipient");
		NotCheckedAttributeArray.Add("ManufacturedProducts.ExpenseItem");
		NotCheckedAttributeArray.Add("ManufacturedProducts.DimensionOfExpenses");
		NotCheckedAttributeArray.Add("ManufacturedProducts.CancellationReason");
		NotCheckedAttributeArray.Add("ManufacturedProducts.QualityConfirmationDate");
		
		NotCheckedAttributeArray.Add("SideAndIntermediateRelease");
		NotCheckedAttributeArray.Add("SideAndIntermediateRelease.Products");
		NotCheckedAttributeArray.Add("SideAndIntermediateRelease.Characteristic");
		NotCheckedAttributeArray.Add("SideAndIntermediateRelease.DateOfReceipt");
		NotCheckedAttributeArray.Add("SideAndIntermediateRelease.NumberOfPackages");
		NotCheckedAttributeArray.Add("SideAndIntermediateRelease.Count");
		NotCheckedAttributeArray.Add("SideAndIntermediateRelease.Recipient");
		NotCheckedAttributeArray.Add("SideAndIntermediateRelease.ExpenseItem");
		NotCheckedAttributeArray.Add("SideAndIntermediateRelease.DimensionOfExpenses");
		NotCheckedAttributeArray.Add("SideAndIntermediateRelease.ProductCostElement");
		NotCheckedAttributeArray.Add("SideAndIntermediateRelease.CancellationReason");
		NotCheckedAttributeArray.Add("SideAndIntermediateRelease.QualityConfirmationDate");
		
		NotCheckedAttributeArray.Add("SupplyWithMaterialsAndWorks");
		NotCheckedAttributeArray.Add("SupplyWithMaterialsAndWorks.Products");
		NotCheckedAttributeArray.Add("SupplyWithMaterialsAndWorks.Characteristic");
		NotCheckedAttributeArray.Add("SupplyWithMaterialsAndWorks.SupplyOption");
		NotCheckedAttributeArray.Add("SupplyWithMaterialsAndWorks.Warehouse");
		NotCheckedAttributeArray.Add("SupplyWithMaterialsAndWorks.DateOfShipment");
		NotCheckedAttributeArray.Add("SupplyWithMaterialsAndWorks.NumberOfPackages");
		NotCheckedAttributeArray.Add("SupplyWithMaterialsAndWorks.Count");
		NotCheckedAttributeArray.Add("SupplyWithMaterialsAndWorks.ProductCostElement");
		
	#EndRegion
	
	EndIf;
	#Region CheckingGiverSAppointments
	
	DestinationVerificationParameters = TollingScheme.ParametersForCheckingSelectionOfGiverSDestination();
	DestinationVerificationParameters.NameTSMaterialsAndWorks = Metadata().TabularSections.SupplyWithMaterialsAndWorks.Name;
	DestinationVerificationParameters.TollBasedCostGroupings.Add(Enums.CostGroupingsInTollingOrder.ByProductionStages);
	
	TollingScheme.CheckCorrectnessOfChoiceOfGiverSAppointment(ThisObject, DestinationVerificationParameters, Cancel);
	
	#EndRegion
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
	SalesServer.CheckCorrectnessOfSalesDocument(ThisObject, Cancel);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	If Not IsNew() Then
		DetailsBeforeChange = Common.ObjectAttributesValues(Ref, "GroupCosts");
		GroupCostsBeforeChange = DetailsBeforeChange.GroupCosts;
	Else
		GroupCostsBeforeChange = GroupCosts;
	EndIf;
	AdditionalProperties.Insert("GroupCostsBeforeChange", GroupCostsBeforeChange);
	AdditionalProperties.Insert("WriteMode",                  WriteMode);
	
	If GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		ManufacturedProducts.Clear();
		SideAndIntermediateRelease.Clear();
		SupplyWithMaterialsAndWorks.Clear();
		CheckAbilityToCommunicateWithOrders(Cancel);
	EndIf;
	
	If Not GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		RoundingParameters = Documents.SubcontractOrder2_5.TSParametersForRounding();
		
		ProductsServer.RoundUpNumberOfUnitItems(
			ThisObject, WriteMode, RoundingParameters["ManufacturedProducts"]);
		
		ProductsServer.RoundUpNumberOfUnitItems(
			ThisObject, WriteMode, RoundingParameters["SideAndIntermediateRelease"]);
		
		ProductsServer.RoundUpNumberOfUnitItems(
			ThisObject, WriteMode, RoundingParameters["SupplyWithMaterialsAndWorks"]);
		
		OrdersServer.SetKeyInRowsOfTablePart(ThisObject, "ManufacturedProducts",  "ProductsMaxRowCode");
		OrdersServer.SetKeyInRowsOfTablePart(ThisObject, "SideAndIntermediateRelease",  "ProductsMaxRowCode");
		OrdersServer.SetKeyInRowsOfTablePart(ThisObject, "SupplyWithMaterialsAndWorks", "MaximumRowCodeMaterials");
		OrdersServer.SetKeyInRowsOfTablePart(ThisObject, "Services",           "ProductsMaxRowCode");
	
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.SubcontractOrder2_5);
		ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);
		
		NewReceiptDate = Date(1,1,1);
		
		If ManufacturedProducts.Count() > 0 Then
			
			If Status = Enums.TollingOrderStatuses.ForFulfillment Then
				
				FilterParameters = New Structure;
				FilterParameters.Insert("Canceled", False);
				ConfirmedRows = ManufacturedProducts.FindRows(FilterParameters);
				
				If ConfirmedRows.Count() > 0 Then
					
					TableOfConfirmedRows = ManufacturedProducts.Unload(ConfirmedRows, "DateOfReceipt");
					TableOfConfirmedRows.Sort("DateOfReceipt Asc");
					NewReceiptDate = TableOfConfirmedRows[0].DateOfReceipt;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		DateOfFirstReceipt = NewReceiptDate;
		
		StructureOfCollateralData = GetDepositAmountWithShippingDate();
		DepositValue = StructureOfCollateralData.Sum;
		
		If NotShipInInstallments Then
			ProvisionInDocumentsServer.FillInShippingDatesInTable(DateOfShipment, SupplyWithMaterialsAndWorks, "DateOfShipment");
		Else
			DateOfShipment = Date(1,1,1);
		EndIf;
	Else
		UpdateMaximumRowCodesOnOrders();
		OrdersServer.SetKeyInRowsOfTablePart(ThisObject, "Services", "ProductsMaxRowCode");
	EndIf;
	If Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	If Not ValueIsFilled(ApprovalDate)
		And Not Status = Enums.TollingOrderStatuses.NotApproved Then
		ApprovalDate = CurrentSessionDate();
		ARAPAccountingServer.WhenChangingApprovalDate(ThisObject);
	ElsIf Status = Enums.TollingOrderStatuses.NotApproved Then
		ApprovalDate = Undefined;
		ARAPAccountingServer.WhenChangingApprovalDate(ThisObject);
	EndIf;
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	DocumentAmounts = DocumentAmounts();
	DocumentAmount = DocumentAmounts.AmountIncludingVAT;
	
	StepsTable = PaymentScheduleSteps.Unload(, "PaymentOption, PaymentAmount, PackageDepositValue");
	StepsTable.GroupBy("PaymentOption", "PaymentAmount, PackageDepositValue");
	
	AdvancePaymentLineBeforeConfirmation = StepsTable.Find(Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation,"PaymentOption");
	
	If AdvancePaymentLineBeforeConfirmation = Undefined Then
		AmountAdvanceBeforeConfirmation = 0;
	Else
		AmountAdvanceBeforeConfirmation = AdvancePaymentLineBeforeConfirmation.PaymentAmount + AdvancePaymentLineBeforeConfirmation.PackageDepositValue;
	EndIf;
	
	PrepaymentLineBeforeReceipt = StepsTable.Find(Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt,"PaymentOption");
	
	If PrepaymentLineBeforeReceipt = Undefined Then
		PrepaymentAmountBeforeReceipt = 0;
	Else
		PrepaymentAmountBeforeReceipt = PrepaymentLineBeforeReceipt.PaymentAmount + PrepaymentLineBeforeReceipt.PackageDepositValue;
	EndIf;
	
	If PaymentMethod <> Enums.PaymentForms.CashAccountPayment_ Then
		AttributesArray = New Array;
		AttributesArray.Add("CashAccount");
		CashServer.ClearUnusedProps(ThisObject, AttributesArray, New Array);
	EndIf;
	
	TransferDestinationPattern = Documents.SubcontractOrder2_5.TransferDestinationPattern(ThisObject);
	
	DestinationDegeneration =
		Catalogs.Assignments.CheckFillBeforeRecording(
			TransferPurpose,
			TransferDestinationPattern,
			ThisObject,
			"LineOfBusiness,GroupCosts",
			Cancel);
	
	If DestinationDegeneration Then
		TransferToSubcontractorForOrderPurpose =
			Constants.SubcontractorOptionOfAssignment2_5.Get() =
				Enums.OptionsOfAssignmentDuringTransferToProcessing.SubcontractOrder;
	EndIf;
	
	DestinationPattern = Documents.SubcontractOrder2_5.DestinationPattern(ThisObject);
	If Catalogs.Assignments.PatternsAreEqual(DestinationPattern, TransferDestinationPattern) Then
		Purpose = TransferPurpose;
	Else
		
		If Purpose = TransferPurpose Then
			Purpose = Undefined;
		EndIf;
		
		DestinationDegeneration =
			Catalogs.Assignments.CheckFillBeforeRecording(
				Purpose,
				DestinationPattern,
				ThisObject,
				"LineOfBusiness,Partner,Contract,GroupCosts",
				Cancel);
		
		If DestinationDegeneration Then
			SeparationOfMaterialsByProductPurpose =
				Constants.OptionOfAssignmentAtTransferToSubcontractor2_5.Get() =
					Enums.OptionsOfAssignmentDuringTransferToProcessing.AssignmentOfProducts;
		EndIf;
		
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.SubcontractOrder2_5.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting Then
		TMCommonUse.FillInDocumentIDs(ThisObject, "Services");
	EndIf;
	
	FillInAssignmentsInMaterials();
	
	If Status <> Enums.TollingOrderStatuses.Closed Then
		CashServerLocalization.CheckRecipientOfPaymentLinksSBP(ThisObject, WriteMode, Cancel);
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	TransferDestinationPattern = Documents.SubcontractOrder2_5.TransferDestinationPattern(ThisObject);
	Catalogs.Assignments.OnWriteDocument(TransferPurpose, TransferDestinationPattern, ThisObject, Partner, PurchaseForActivity);
	
	DestinationPattern = Documents.SubcontractOrder2_5.DestinationPattern(ThisObject);
	If Not Catalogs.Assignments.PatternsAreEqual(DestinationPattern, TransferDestinationPattern) Then
		Catalogs.Assignments.OnWriteDocument(Purpose, DestinationPattern, ThisObject, Partner, PurchaseForActivity);
	EndIf;
	If Not Posted
		And (GroupCosts =
					Enums.CostGroupingsInTollingOrder.ByProductionStages
			Or AdditionalProperties.GroupCostsBeforeChange =
					Enums.CostGroupingsInTollingOrder.ByProductionStages)
		And Not Cancel Then
		
		If Not DeletionMark Then
			UpdateOrdersRelatedToOrder(Cancel);
		Else
			RemoveLinkBetweenOrderAndOrder(Cancel);
		EndIf;
		
	EndIf;
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	// When carrying out the stages for the distribution of stocks, data from the register of documents ordered by the processor is needed.
	// Therefore, first the order is recorded and carried out to the processor, and then the stages.
	If (GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
			Or AdditionalProperties.GroupCostsBeforeChange =
					Enums.CostGroupingsInTollingOrder.ByProductionStages)
		And Not Cancel Then
		
		If Not DeletionMark Then
			UpdateOrdersRelatedToOrder(Cancel);
		Else
			RemoveLinkBetweenOrderAndOrder(Cancel);
		EndIf;
		
		// Update the document registry entries after recording the stages
		If Not Cancel Then
			Documents.SubcontractOrder2_5.UpdateDocumentRegistryEntries(Ref, Cancel);
		EndIf;
		
	EndIf;
	If Not Cancel Then
		GoodsDelivery.ReflectDeliveryState(Ref, Cancel);
		ProcessingByThirdParties.PerformOrderControlAfterConducting(ThisObject, Cancel);
	EndIf;
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel, True);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInDocumentBasedOnPartner(Val Basis)
	
	PartnerDetails_ = Common.ObjectAttributesValues(Basis, "Vendor, Client");
	
	If PartnerDetails_.Vendor And PartnerDetails_.Client Then
		Partner = Basis;
	Else
		If GetFunctionalOption("UsePartnersAsCounterparties") Then
			Raise NStr("vi = 'Bạn hàng phải đồng thời là ""nhà cung cấp"" và ""khách hàng"".';
						|ru = 'Контрагент должен являться одновременно и ""поставщиком"" и ""клиентом"".';
						|en = 'Counterparty must be both a vendor and a customer.'; fa = 'Counterparty must be both a vendor and a customer.';
						|it = 'Il contraente deve essere ""fornitore"" e ""cliente"" contemporaneamente.';
						|pl = 'Kontrahent powinien być jednocześnie i ""поставщиком"" i ""клиентом"".';
						|tr = 'Cari hesap aynı anda hem ""satıcı"" hem de ""müşteri"" olmalıdır.'");
		Else
			Raise NStr("vi = 'Bạn hàng phải đồng thời là ""nhà cung cấp"" và ""khách hàng"".';
						|ru = 'Партнер должен являться одновременно и ""поставщиком"" и ""клиентом"".';
						|en = 'Partner must be both a vendor and a customer.'; fa = 'Partner must be both a vendor and a customer.';
						|it = 'Il partner deve essere ""fornitore"" e ""cliente"" contemporaneamente.';
						|pl = 'Partner powinien być jednocześnie i ""поставщиком"" i ""клиентом"".';
						|tr = 'İş ortağı aynı anda hem ""satıcı"" hem de ""müşteri"" olmalıdır.'");
		EndIf;
	EndIf;
	
EndProcedure

Procedure FillInDocumentBasedOnTransaction(CustomerTransaction)
	
	If Documents.SalesOrder.ThereAreSeparateOrdersForTransaction(CustomerTransaction) Then
		FillInDocumentOnBasisOfTransactionOnSeparateOrders_(CustomerTransaction);
	Else
		FillInDocumentOnBasisOfTransactionInSummary(CustomerTransaction);
	EndIf;
	
EndProcedure

Procedure FillInDocumentBasedOnCustomerSOrder(FillingData)
	
	SalesOrder = FillingData.Basis;
	Query = New Query(
		"SELECT
		|	SalesOrder.Priority AS Priority,
		|	SalesOrder.Organization AS Organization,
		|	SalesOrder.SalesOpportunity AS SalesOpportunity,
		|	SalesOrder.Warehouse AS ManufacturedProductsWarehouse,
		|	ISNULL(SalesOrder.Warehouse.IsFolder, FALSE) AS IsFolder,
		|	SalesOrder.VATTaxation AS PurchaseForActivity,
		|	CASE
		|		WHEN SalesOrder.LineOfBusiness.CostAccounting
		|				OR SalesOrder.LineOfBusiness.VendorARAP
		|			THEN SalesOrder.LineOfBusiness
		|	END AS LineOfBusiness
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|WHERE
		|	SalesOrder.Ref = &SalesOrder");
	Query.SetParameter("SalesOrder", SalesOrder);
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	// Filling in the header
	Organization             = Attributes.Organization;
	ManufacturedProductsWarehouse          = Attributes.ManufacturedProductsWarehouse;
	SalesOpportunity                  = Attributes.SalesOpportunity;
	Priority               = Attributes.Priority;
	PurchaseForActivity  = Attributes.PurchaseForActivity;
	LineOfBusiness = Attributes.LineOfBusiness;
	DocumentBasis       = SalesOrder;
	
	ManufacturedProductsWarehouse = FillingData.Warehouse;
	If Not ValueIsFilled(ManufacturedProductsWarehouse)
			And Attributes.IsFolder
			And GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments") Then
		
		ManufacturedProductsWarehouse = Attributes.ManufacturedProductsWarehouse;
		
	EndIf;
	
	// Filling in the tabular part.
	ManufacturedProducts.Load(GetFromTempStorage(FillingData.AddressGoods));
	DeleteFromTempStorage(FillingData.AddressGoods);
	
	If SeparationOfMaterialsByProductPurpose Then
		GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductsAndAssignments;
	Else
		GroupCosts = Enums.CostGroupingsInTollingOrder.ByProducts;
	EndIf;
	
	InitializeDocumentAfterAddingProducts();
	
EndProcedure

Procedure FillInDocumentBasedOnTransferOrder(FillingData)

	TransferOrder = FillingData.Basis;
	Query = New Query(
		"SELECT
		|	References.Organization AS Organization,
		|	References.SalesOpportunity AS SalesOpportunity,
		|	References.TransferForActivity AS PurchaseForActivity,
		|	CASE
		|		WHEN References.LineOfBusiness.CostAccounting
		|				OR References.LineOfBusiness.VendorARAP
		|			THEN References.LineOfBusiness
		|	END AS LineOfBusiness
		|FROM
		|	Document.TransferOrder AS References
		|WHERE
		|	References.Ref = &TransferOrder");
	Query.SetParameter("TransferOrder", TransferOrder);
	Attributes = Query.Execute().Select();
	
	// Filling in the header
	DocumentBasis = TransferOrder;
	If Attributes.Next() Then
		FillPropertyValues(ThisObject, Attributes);
	EndIf;
	
	ManufacturedProductsWarehouse = FillingData.Warehouse;
	
	// Filling in the tabular part.
	ManufacturedProducts.Load(GetFromTempStorage(FillingData.AddressGoods));
	DeleteFromTempStorage(FillingData.AddressGoods);
	
	If SeparationOfMaterialsByProductPurpose Then
		GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductsAndAssignments;
	Else
		GroupCosts = Enums.CostGroupingsInTollingOrder.ByProducts;
	EndIf;
	
	InitializeDocumentAfterAddingProducts();
	
EndProcedure

Procedure FillInDocumentOnBasisOfTransactionOnSeparateOrders_(Val CatalogBasis)
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN
		|		(SELECT
		|				T.SalesOrder
		|			FROM
		|				TTOrdersByTransaction AS T)";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode, Warehouse";
	TableFormationParameters.Indicators = "Ordered, Issued_1";
	TableFormationParameters.Resources = "Count";
	TableFormationParameters.Indexes = "ReferenceOrder, Products, Characteristic, RowCode";
	TableFormationParameters.TempTableName = "TT_ShipmentOrdersTurnoverExpanded";
	
	TT_ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query = New Query(
	"SELECT
	|	T.Ref AS SalesOrder
	|
	|INTO TTOrdersByTransaction
	|
	|FROM
	|	Document.SalesOrder AS T
	|WHERE
	|	T.SalesOpportunity = &SalesOpportunity
	|	AND T.Status IN (
	|		VALUE(Enum.SalesOrderStatuses.ToSupply),
	|		VALUE(Enum.SalesOrderStatuses.ToShip))
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|" + TT_ShipmentOrdersTurnoverExpanded +
	Common.QueryBatchSeparator() + "
	|SELECT
	|	T.Products          AS Products,
	|	T.Characteristic        AS Characteristic,
	|	T.Warehouse                 AS Warehouse,
	|	T.Purpose            AS Purpose,
	|	MAX(T.LineNumber) AS LineNumber,
	|	MIN(T.OrderDate)   AS OrderDate,
	|	SUM(T.Ordered)       AS Ordered
	|	
	|INTO OrderProducts_0
	|
	|FROM
	|	(SELECT
	|		References.ReferenceOrder.Date AS OrderDate,
	|		References.Products      AS Products,
	|		References.Characteristic    AS Characteristic,
	|		References.Warehouse             AS Warehouse,
	|		CASE
	|			WHEN NOT GoodsFromOrder.Ref IS NULL
	|				THEN GoodsFromOrder.LineNumber
	|			ELSE ApplicationProducts_.LineNumber
	|		END                          AS LineNumber,
	|		(References.OrderedQuantityTurnover -
	|			References.IssuedQuantityTurnover) AS Ordered,
	|		CASE
	|			WHEN NOT GoodsFromOrder.Ref IS NULL
	|				THEN GoodsFromOrder.Ref.Purpose
	|			ELSE ApplicationProducts_.Ref.Purpose
	|		END                    AS Purpose
	|	FROM
	|		TT_ShipmentOrdersTurnoverExpanded AS References
	|
	|		LEFT JOIN Document.SalesOrder.Goods AS GoodsFromOrder
	|		ON References.ReferenceOrder  = GoodsFromOrder.Ref
	|		AND References.Products   = GoodsFromOrder.Products
	|		AND References.Characteristic = GoodsFromOrder.Characteristic
	|		AND References.RowCode      = GoodsFromOrder.RowCode
	|
	|		LEFT JOIN Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS ApplicationProducts_
	|		ON References.ReferenceOrder  = ApplicationProducts_.Ref
	|		AND References.Products   = ApplicationProducts_.Products
	|		AND References.Characteristic = ApplicationProducts_.Characteristic
	|		AND References.RowCode      = ApplicationProducts_.RowCode
	|		AND GoodsFromOrder.Ref IS NULL
	|	WHERE
	|		CASE
	|			WHEN NOT GoodsFromOrder.Ref IS NULL THEN
	|				GoodsFromOrder.SupplyOption = VALUE(Enum.SupplyOptions.ReserveAsReceived)
	|					AND GoodsFromOrder.WithAssignment
	|			ELSE
	|				ApplicationProducts_.SupplyOption = VALUE(Enum.SupplyOptions.ReserveAsReceived)
	|					AND ApplicationProducts_.WithAssignment
	|			END
	|		AND (References.OrderedQuantityTurnover -
	|			References.IssuedQuantityTurnover) > 0) AS T
	|
	|GROUP BY
	|	T.Products,
	|	T.Characteristic,
	|	T.Warehouse,
	|	T.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Inventories.Products AS Products,
	|	Inventories.Characteristic AS Characteristic,
	|	Inventories.Warehouse AS Warehouse,
	|	Inventories.Purpose AS Purpose,
	|	Inventories.OrderDocument AS OrderDocument,
	|	Inventories.LockedInStockBalance AS LockedInStockBalance,
	|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
	|	Inventories.ToUnlockBalance AS ToUnlockBalance,
	|	Inventories.ReserveAtWarehouseFromLockedBalance AS ReserveAtWarehouseFromLockedBalance,
	|	Inventories.ReserveUponReceiptFromLockedBalance AS ReserveUponReceiptFromLockedBalance
	|INTO InventoryAndNeedsBalanceOfControlledLotsReference
	|FROM
	|	AccumulationRegister.InventoryAndDemands.Balance(,
	|		(Products, Characteristic, Warehouse, Purpose) IN(
	|			SELECT
	|				FilterOfProducts_.Products AS Products,
	|				FilterOfProducts_.Characteristic AS Characteristic,
	|				FilterOfProducts_.Warehouse AS Warehouse,
	|				FilterOfProducts_.Purpose AS Purpose
	|			FROM
	|				OrderProducts_0 AS FilterOfProducts_)) AS Inventories
	|INDEX BY
	|	Products, Characteristic, Warehouse, Purpose
	|;
	|
	|////////////////////////////////////////////////////////
	|SELECT
	|	Inventories.Products AS Products,
	|	Inventories.Characteristic AS Characteristic,
	|	Inventories.Warehouse AS Warehouse,
	|	Inventories.Purpose AS Purpose,
	|	Inventories.InStockBalance AS InStockBalance,
	|	Inventories.LockedInStockBalance AS LockedInStockBalance,
	|	Inventories.OrderedBalance AS OrderedBalance,
	|	Inventories.Received_1Balance AS Received_1Balance,
	|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
	|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
	|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
	|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
	|	Inventories.ToSupplyBalance AS ToSupplyBalance,
	|	Inventories.NotProvideBalance AS NotProvideBalance
	|INTO InventoryAndDemandsBalance
	|FROM
	|	AccumulationRegister.InventoryAndDemands.Balance(,
	|		(Products, Characteristic, Warehouse, Purpose) IN(
	|			SELECT
	|				FilterOfProducts_.Products AS Products,
	|				FilterOfProducts_.Characteristic AS Characteristic,
	|				FilterOfProducts_.Warehouse AS Warehouse,
	|				FilterOfProducts_.Purpose AS Purpose
	|			FROM
	|				OrderProducts_0 AS FilterOfProducts_)) AS Inventories
	|;
	|
	|/////////////////////////////////////////////////////////
	|SELECT
	|	TTGoodsOrders.OrderDate     AS OrderDate,
	|	TTGoodsOrders.LineNumber    AS LineNumber,
	|	TTGoodsOrders.Products   AS Products,
	|	TTGoodsOrders.Characteristic AS Characteristic,
	|	TTGoodsOrders.Warehouse          AS Warehouse,
	|	TTGoodsOrders.Purpose     AS Purpose,
	|	CASE
	|		WHEN
	|			TTGoodsOrders.Ordered
	|				> Calculation.NotProvided_ReserveAsNeeded
	|					+ Calculation.NotProvided_Postpone
	|					+ Calculation.Supply_CIsNotProvided
	|			THEN
	|				Calculation.NotProvided_ReserveAsNeeded
	|					+ Calculation.NotProvided_Postpone
	|					+ Calculation.Supply_CIsNotProvided
	|		ELSE TTGoodsOrders.Ordered
	|	END AS Count
	|
	|INTO OrderProducts_2
	|
	|FROM
	|	OrderProducts_0 AS TTGoodsOrders
	|	
	|	INNER JOIN SubstitutionInventoryAllocation AS Calculation
	|	ON TTGoodsOrders.Products  = Calculation.Products
	|	AND TTGoodsOrders.Characteristic = Calculation.Characteristic
	|	AND TTGoodsOrders.Warehouse          = Calculation.Warehouse
	|	AND TTGoodsOrders.Purpose     = Calculation.Purpose
	|WHERE
	|	TTGoodsOrders.Products.ItemsType IN(
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND Calculation.NotProvided_ReserveAsNeeded
	|		+ Calculation.NotProvided_Postpone
	|		+ Calculation.Supply_CIsNotProvided > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Products           AS Products,
	|	T.Characteristic         AS Characteristic,
	|	T.Warehouse                  AS Recipient,
	|	T.Purpose             AS Purpose,
	|	T.Count             AS Count,
	|	T.Count             AS NumberOfPackages,
	|	VALUE(Enum.CostTypesOfFinishedProducts.Calculating) AS CostType
	|FROM
	|	OrderProducts_2 AS T
	|WHERE
	|	T.Warehouse IN (SELECT Tab.Warehouse FROM TTWarehouses AS Tab)
	|
	|ORDER BY T.Purpose, T.LineNumber
	|");
	
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForInventoryAllocation();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.BalanceSheetsOfControlledLotREFERENCES = "InventoryAndNeedsBalanceOfControlledLotsReference"; // @query-part-1
	TablesNames.Result = "SubstitutionInventoryAllocation"; // @query-part-1
	ProvisionInDocumentsServer.InventoryAllocation(Query.Text, TablesNames);
	
	Query.SetParameter("SalesOpportunity", CatalogBasis);
	SalesOpportunity = CatalogBasis;
	
	SetPrivilegedMode(True);
	GoodsTable = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	If GoodsTable.Count() > 0 Then 
		ManufacturedProducts.Load(GoodsTable);
	EndIf;
	
	If SeparationOfMaterialsByProductPurpose Then
		GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductsAndAssignments;
	Else
		GroupCosts = Enums.CostGroupingsInTollingOrder.ByProducts;
	EndIf;
	
	InitializeDocumentAfterAddingProducts();
	
EndProcedure

Procedure FillInDocumentOnBasisOfTransactionInSummary(Val CatalogBasis)

	Query = New Query(
	"SELECT
	|	SalesOpportunitiesToCustomer.Ref AS SalesOpportunity
	|FROM
	|	Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
	|WHERE
	|	SalesOpportunitiesToCustomer.Ref = &SalesOpportunity
	|	AND SalesOpportunitiesToCustomer.EnabledGoodsAssignmentInSalesOpportunity
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ShipmentReferences.Products AS Products,
	|	ShipmentReferences.Characteristic AS Characteristic,
	|	(ShipmentReferences.OrderedQuantityTurnover -
	|		ShipmentReferences.IssuedQuantityTurnover) AS Count
	|INTO SalesOrders
	|FROM
	|	#ShipmentOrdersTurnoverExpanded AS ShipmentReferences
	|WHERE
	|	(ShipmentReferences.OrderedQuantityTurnover -
	|		ShipmentReferences.IssuedQuantityTurnover) <> 0
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PurchaseOrders.Products AS Products,
	|	PurchaseOrders.Characteristic AS Characteristic,
	|	PurchaseOrders.OrderedReceipt AS Count
	|
	|INTO PurchaseOrders
	|FROM
	|	AccumulationRegister.PurchaseOrders.Turnovers(,, Period,
	|		PurchaseOrder.SalesOpportunity = &SalesOpportunity
	|	) AS PurchaseOrders
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SalesOrders.Products                                           AS Products,
	|	SalesOrders.Characteristic                                         AS Characteristic,
	|	SalesOrders.Count - ISNULL(PurchaseOrders.Count, 0) AS Count,
	|	SalesOrders.Count - ISNULL(PurchaseOrders.Count, 0) AS NumberOfPackages,
	|	VALUE(Enum.CostTypesOfFinishedProducts.Calculating)    AS CostType
	|FROM
	|	SalesOrders AS SalesOrders
	|
	|	LEFT JOIN PurchaseOrders AS PurchaseOrders
	|	ON SalesOrders.Products = PurchaseOrders.Products
	|	AND SalesOrders.Characteristic = PurchaseOrders.Characteristic
	|
	|WHERE
	|	(SalesOrders.Count - ISNULL(PurchaseOrders.Count, 0)) > 0
	|");
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"ReferenceOrder.SalesOpportunity = &SalesOpportunity
		|		AND ReferenceOrder.Status IN
		|			(VALUE(Enum.SalesOrderStatuses.ToSupply),
		|			VALUE(Enum.SalesOrderStatuses.ToShip))";
	TableFormationParameters.Group = "Products, Characteristic";
	TableFormationParameters.Indicators = "Ordered, Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded",
		ShipmentOrdersTurnoverExpanded);
	
	Query.SetParameter("SalesOpportunity", CatalogBasis);

	SetPrivilegedMode(True);
	ResultsArray = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	TransactionSelection = ResultsArray[0].Select();
	ProductSelection_1 = ResultsArray[3].Select();
	
	If TransactionSelection.Next() Then
		SalesOpportunity = TransactionSelection.SalesOpportunity;
	EndIf;
	
	While ProductSelection_1.Next() Do
		NewRow = ManufacturedProducts.Add();
		FillPropertyValues(NewRow, ProductSelection_1);
	EndDo;
	
	If SeparationOfMaterialsByProductPurpose Then
		GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductsAndAssignments;
	Else
		GroupCosts = Enums.CostGroupingsInTollingOrder.ByProducts;
	EndIf;
	
	InitializeDocumentAfterAddingProducts();
	
EndProcedure

Procedure FillOutDocumentBasedOnGiverSOrder(FillingData)
	
	#Region TheseGrounds
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsTable.LineNumberInDocument AS LineNumberInDocument,
	|	GoodsTable.Products          AS Products,
	|	GoodsTable.Characteristic        AS Characteristic,
	|	GoodsTable.VATRate             AS VATRate,
	|	GoodsTable.Purpose            AS Purpose,
	|	GoodsTable.Package              AS Package,
	|	GoodsTable.Count            AS Count,
	|	GoodsTable.NumberOfPackages    AS NumberOfPackages,
	|	GoodsTable.Warehouse                 AS Warehouse,
	|	GoodsTable.Department         AS Department,
	|	GoodsTable.DateOfShipment          AS DateOfShipment,
	|	GoodsTable.Recipient            AS Recipient,
	|	GoodsTable.ToExpenseAs      AS ToExpenseAs
	|INTO GoodsTable
	|FROM
	|	&GoodsTable AS GoodsTable
	|
	|INDEX BY
	|	LineNumberInDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	GoodsTable.Products              AS Products,
	|	GoodsTable.Characteristic            AS Characteristic,
	|	GoodsTable.Purpose                AS Purpose,
	|	GoodsTable.Package                  AS Package,
	|	GoodsTable.DateOfShipment              AS DateOfShipment,
	|	GoodsTable.Recipient                AS Recipient,
	|	TableProduction.BillOfMaterials           AS BillOfMaterials,
	|	SUM(GoodsTable.Count)         AS Count,
	|	SUM(GoodsTable.NumberOfPackages) AS NumberOfPackages
	|INTO TableProduction
	|FROM
	|	GoodsTable AS GoodsTable
	|	
	|	INNER JOIN Document.MaterialProviderOrder2_5.ManufacturedProduct AS TableProduction
	|	ON TableProduction.Ref = &MaterialProviderOrder
	|	AND TableProduction.LineNumber = GoodsTable.LineNumberInDocument
	|
	|GROUP BY
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Purpose,
	|	GoodsTable.Package,
	|	GoodsTable.DateOfShipment,
	|	GoodsTable.Recipient,
	|	TableProduction.BillOfMaterials
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	MaterialProviderOrder.Ref                          AS DocumentBasis,
	|	MaterialProviderOrder.Priority                       AS Priority,
	|	MaterialProviderOrder.Organization                     AS Organization,
	|	MaterialProviderOrder.SalesOpportunity                          AS SalesOpportunity,
	|	MaterialProviderOrder.Department                   AS Department,
	|	MaterialProviderOrder.Warehouse                           AS ManufacturedProductsWarehouse,
	|	MaterialProviderOrder.WarehouseForReceipt                AS MaterialsWarehouse,
	|	MaterialProviderOrder.VATTaxation              AS PurchaseForActivity,
	|	CASE
	|		WHEN MaterialProviderOrder.LineOfBusiness.CostAccounting
	|				OR MaterialProviderOrder.LineOfBusiness.VendorARAP
	|			THEN MaterialProviderOrder.LineOfBusiness
	|	END                                         AS LineOfBusiness,
	|	CASE
	|		WHEN
	|			NOT SUM(CASE
	|				WHEN NOT TableProduction.BillOfMaterials = VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|					THEN 1
	|				ELSE 0
	|			END) = 0
	|			THEN VALUE(Enum.CostGroupingsInTollingOrder.ByProductBOMAndAssignments)
	|		ELSE VALUE(Enum.CostGroupingsInTollingOrder.ByProductsAndAssignments)
	|	END                                         AS GroupCosts
	|FROM
	|	Document.MaterialProviderOrder2_5 AS MaterialProviderOrder
	|	
	|	INNER JOIN TableProduction AS TableProduction
	|	ON TRUE
	|
	|WHERE
	|	MaterialProviderOrder.Ref = &MaterialProviderOrder
	|
	|GROUP BY
	|	MaterialProviderOrder.Ref,
	|	MaterialProviderOrder.Priority,
	|	MaterialProviderOrder.Organization,
	|	MaterialProviderOrder.SalesOpportunity,
	|	MaterialProviderOrder.Department,
	|	MaterialProviderOrder.Warehouse,
	|	MaterialProviderOrder.WarehouseForReceipt,
	|	MaterialProviderOrder.VATTaxation,
	|	MaterialProviderOrder.LineOfBusiness
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TableProduction.Products       AS Products,
	|	TableProduction.Characteristic     AS Characteristic,
	|	TableProduction.Purpose         AS Purpose,
	|	TableProduction.Package           AS Package,
	|	TableProduction.Count         AS Count,
	|	TableProduction.NumberOfPackages AS NumberOfPackages,
	|	TableProduction.DateOfShipment       AS DateOfReceipt,
	|	TableProduction.Recipient         AS Recipient,
	|	TableProduction.BillOfMaterials       AS BillOfMaterials
	|FROM
	|	TableProduction AS TableProduction
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TableMaterials.Products              AS Products,
	|	TableMaterials.Characteristic            AS Characteristic,
	|	TableMaterials.Purpose                AS Purpose,
	|	TableMaterials.Series                     AS Series,
	|	TableMaterials.Warehouse                     AS Warehouse,
	|	TableMaterials.Package                  AS Package,
	|	SUM(TableMaterials.Count)         AS Count,
	|	SUM(TableMaterials.NumberOfPackages) AS NumberOfPackages,
	|	TableMaterials.Price                      AS Price,
	|	SUM(TableMaterials.Sum)              AS Sum,
	|	TableMaterials.DateOfReceipt           AS DateOfShipment,
	|	VALUE(Enum.SupplyOptions.ToSupply) AS SupplyOption,
	|	TRUE                                     AS WithAssignment
	|FROM
	|	Document.MaterialProviderOrder2_5.UsedMaterials AS TableMaterials
	|
	|WHERE
	|	TableMaterials.Ref = &MaterialProviderOrder
	|
	|GROUP BY
	|	TableMaterials.Products,
	|	TableMaterials.Characteristic,
	|	TableMaterials.Purpose,
	|	TableMaterials.Series,
	|	TableMaterials.Warehouse,
	|	TableMaterials.Package,
	|	TableMaterials.DateOfReceipt,
	|	TableMaterials.Price
	|";
	
	Query.SetParameter("MaterialProviderOrder", FillingData.Basis);
	Query.SetParameter("GoodsTable", GetFromTempStorage(FillingData.AddressGoods));
	DeleteFromTempStorage(FillingData.AddressGoods);
	
	#EndRegion
	
	Result = Query.ExecuteBatch();
	
	// Filling in the header
	Attributes = Result[Result.UBound() - 2].Select();
	Attributes.Next();
	FillPropertyValues(ThisObject, Attributes);
	
	// Filling in the tabular part.
	ManufacturedProducts.Load(Result[Result.UBound() - 1].Unload());
	
	FieldList = ProcessingByThirdPartiesClientServer.ListOfOrderCostGroupFieldsForProcessor(GroupCosts);
	FieldList = StrConcat(FieldList.UnloadValues(), ",");
	
	CostGroups = ManufacturedProducts.Unload(Undefined, FieldList);
	CostGroups.GroupBy(FieldList);
	CostGroups.Columns.Add("CostGroupNumber", Common.TypeDescriptionNumber(10, 0, AllowedSign.Nonnegative));
	For Each CurrentGroup In CostGroups Do
		MaximumNumberOfCostGroup = MaximumNumberOfCostGroup + 1;
		CurrentGroup.CostGroupNumber = MaximumNumberOfCostGroup;
	EndDo;
	CostGroups.Indexes.Add(FieldList);
	
	Filter = New Structure(FieldList);
	For Each CurrentData In ManufacturedProducts Do
		
		FillPropertyValues(Filter, CurrentData);
		
		FoundRows = CostGroups.FindRows(Filter);
		If Not FoundRows = Undefined Then
			CurrentData.CostGroupNumber = FoundRows[0].CostGroupNumber;
		EndIf;
		
	EndDo;
	
	If GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductBOMAndAssignments Then
		
		Documents.SubcontractOrder2_5.FillInByProductsMaterialsServicesAccordingToSpecification(ManufacturedProducts, ThisObject);
		
	ElsIf Not ManufacturedProducts.Count() = 0 Then
		
		SupplyWithMaterialsAndWorks.Load(Result[Result.UBound()].Unload());
		If CostGroups.Count() = 1 Then
			For Each CurrentData In SupplyWithMaterialsAndWorks Do
				CurrentData.CostGroupNumber = CostGroups[0].CostGroupNumber;
			EndDo;
		EndIf;
		
		#Region BatchProcessingOfTS
		
		StructureAndMaterials = New Structure;
		
		#Region FillInSalePrice
		
		ActionParameters = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(ThisObject, True);
		ActionParameters.Insert("PriceKind", PriceKind);
		StructureAndMaterials.Insert("FillInSalePrice", ActionParameters);
		
		#EndRegion
		
		#Region RecalculateAmount
		
		StructureAndMaterials.Insert("RecalculateAmount");
		
		#EndRegion
		
		BatchProcessingOfTablePartServer.TreatTS(SupplyWithMaterialsAndWorks, StructureAndMaterials);
		
		#EndRegion
		
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.SubcontractOrder2_5);
		ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);
		
		For Each CurrentGroup In CostGroups Do
			NewRow = Services.Add();
			NewRow.CostGroupNumber = CurrentGroup.CostGroupNumber;
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure FillInDocumentBasedOnProductionStage(Basis)

	QueryText =
	"SELECT
	|	DocumentData.Stage.Partner AS Partner,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Department AS Department,
	|	DocumentData.ProductionIssueForActivity AS PurchaseForActivity,
	|	DocumentData.GoodsReceiptOption AS GoodsReceiptOption,
	|	DocumentData.LeaveProductsAtSubcontractor AS LeaveProductsAtSubcontractor
	|FROM
	|	Document.ProductionStage2_2 AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Basis";
	
	Query = New Query(QueryText);
	Query.SetParameter("Basis", Basis);
	Result = Query.Execute();
	Selection = Result.Select();
	If Selection.Next() Then
		FillPropertyValues(ThisObject, Selection);
	EndIf;
	
	ProcessingByOrder = True;
	GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages;
	
	ReferenceArray = New Array;
	ReferenceArray.Add(Basis);
	
	Documents.SubcontractOrder2_5.FillByStagesOfProduction(ReferenceArray, ThisObject);
	
EndProcedure

Procedure InitializeDocumentBeforeFillingItOut(InitializationParameters = Undefined)
	
	If InitializationParameters <> Undefined
		And InitializationParameters.Property("FillOutHouseholdOfOperation")
		And InitializationParameters.FillOutHouseholdOfOperation Then 
		BusinessOperation = InitializationParameters.BusinessOperation;
	Else
		BusinessOperation = Enums.BusinessTransactions.ProductionByToller2_5;
	EndIf;
	Priority = SettingsValueCached.GetDefaultPriority(Priority);
	
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	
	ProcessingServices =
		?(ValueIsFilled(ProcessingServices),
			ProcessingServices,
			Enums.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder);
	
	WorkPerformanceAsOneDay = True;
	ExecutionDate = Date;
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(Currency);
	
	SelectionOfPriceType = New Structure;
	SelectionOfPriceType.Insert("PriceIncludesVAT",                 PriceIncludesVAT);
	SelectionOfPriceType.Insert("UseForIssuingProductsWorksAndServicesAtFixedCost", True);
	PriceKind = Catalogs.TypesOfPrices.DefaultPriceType(PriceKind, SelectionOfPriceType);
	
	Author = Users.CurrentUser();
	
	SeparationOfMaterialsByProductPurpose =
		Constants.OptionOfAssignmentAtTransferToSubcontractor2_5.Get() =
			Enums.OptionsOfAssignmentDuringTransferToProcessing.AssignmentOfProducts;
	
	TransferToSubcontractorForOrderPurpose =
			Constants.SubcontractorOptionOfAssignment2_5.Get() =
				Enums.OptionsOfAssignmentDuringTransferToProcessing.SubcontractOrder;
	
EndProcedure

Procedure InitializeDocument()
	
	GroupCosts =
		?(ValueIsFilled(GroupCosts),
			GroupCosts,
			?(SeparationOfMaterialsByProductPurpose,
				Enums.CostGroupingsInTollingOrder.ByProductsAndAssignments,
				Enums.CostGroupingsInTollingOrder.NoGrouping));
	
	If ValueIsFilled(Partner) Then
		
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
		
		ObjectParameters = New Structure("Partner, Contract, Counterparty, Organization");
		FillPropertyValues(ObjectParameters, ThisObject);
		ObjectParameters.Insert("Terms", Catalogs.TermsOfPurchaseFromVendors.EmptyRef());
		
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency = Currency;
		
		If ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
				And GetFunctionalOption("UseCostAccountingByLinesOfBusiness") Then
			AddlParameters.LineOfBusiness = LineOfBusiness;
		EndIf;	
		
		Contract =
			PurchasesServer.GetDefaultContract(
				ObjectParameters,
				BusinessOperation,
				AddlParameters);
		
		If ValueIsFilled(Contract)
			And (GetFunctionalOption("UseCostAccountingByLinesOfBusiness") 
				Or GetFunctionalOption("UseVendorARAPInLineOfBusiness"))
			And Not ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments
			And Not ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice Then
			LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness,, Contract);
		EndIf;
		
	EndIf;
	
	FillParameters = Documents.SubcontractOrder2_5.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);
	
	FillParameters = Documents.SubcontractOrder2_5.ParametersForFillingInVATTaxationPurchases(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
	If Not GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		MaterialsWarehouse = SettingsValueCached.GetDefaultWarehouse(MaterialsWarehouse, True, True);
		ManufacturedProductsWarehouse = SettingsValueCached.GetDefaultWarehouse(ManufacturedProductsWarehouse, True, True);
	EndIf;
	If Not ValueIsFilled(BankAccount) Then
		PurchasesServerCall.FillInBankAccountsUnderAgreement(Contract, BankAccount);
	EndIf;
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
	ParametersOfAccount.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount, BankAccount);
	
	ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
	ParametersStructure.Organization = Organization;
	ParametersStructure.PaymentMethod = PaymentMethod;
	ParametersStructure.CashAccount = CashAccount;
	CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
	
	If Not GetFunctionalOption("UseTollingOrderStatuses2_5")
		And Not GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		Status = Enums.TollingOrderStatuses.Closed;
	Else
		Status = Enums.TollingOrderStatuses.NotApproved;
	EndIf;
	
	If Not GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		
		FilterStructure1 = New Structure;
		FilterStructure1.Insert("SupplyOption", Enums.SupplyOptions.EmptyRef());
		
		Rows =
			SupplyWithMaterialsAndWorks.FindRows(
				FilterStructure1);
		
		ProvisionInDocumentsServer.FillInDefaultSecurityOption(Rows);
		
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", QualityControl.DataCacheOfMechanism(ThisObject));
	BatchProcessingOfTablePartServer.TreatTS(ManufacturedProducts, StructureOfActions);
	BatchProcessingOfTablePartServer.TreatTS(SideAndIntermediateRelease, StructureOfActions);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfFillingInVATRate.InitializingIncomingDocument = True;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.TreatTS(Services, StructureOfActions, CachedValues);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Services,
		CachedValues);
	
	If Not ValueIsFilled(GoodsReceiptOption) Then
		GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption();
	EndIf;
	
EndProcedure

Procedure InitializeDocumentAfterAddingProducts()
	
	BOMSelectionParameters = ProductDataManagement.BOMSelectionParameters(ThisObject, Documents.SubcontractOrder2_5);
	
	ProductData_2 = New Array;
	For Each StringOutputProducts In ManufacturedProducts Do
		
		MaximumNumberOfCostGroup = MaximumNumberOfCostGroup + 1;
		StringOutputProducts.CostGroupNumber = MaximumNumberOfCostGroup;
		
		ProductData =
			ProductDataManagementClientServer.CollectProductDataForSpecificationSelection(
				ThisObject,
				StringOutputProducts,
				BOMSelectionParameters.ManufacturedProducts);
		
		ProductData.Insert("CurrentSpecification", StringOutputProducts.BillOfMaterials);
			
		ProductData_2.Add(ProductData);
		
	EndDo;
	
	ProductDataManagement.FillInSpecificationInLines(
		ManufacturedProducts,
		ProductData_2,
		BOMSelectionParameters.ManufacturedProducts,,
		True);
	
	Documents.SubcontractOrder2_5.FillInByProductsMaterialsServicesAccordingToSpecification(ManufacturedProducts, ThisObject);
	
EndProcedure

#EndRegion

#Region Other

Procedure CheckCostGroups(Cancel, NotCheckedAttributeArray)
	
	NotCheckedAttributeArray.Add("ManufacturedProducts.CostGroupNumber");
	NotCheckedAttributeArray.Add("SideAndIntermediateRelease.CostGroupNumber");
	NotCheckedAttributeArray.Add("SupplyWithMaterialsAndWorks.CostGroupNumber");
	NotCheckedAttributeArray.Add("Services.CostGroupNumber");
	
	NotCheckedAttributeArray.Add("ManufacturedProducts.Purpose");
	If GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		NotCheckedAttributeArray.Add("ManufacturedProducts");
	EndIf;
	NotCheckedAttributeArray.Add("SupplyWithMaterialsAndWorks");
	NotCheckedAttributeArray.Add("Services");
	
	Query = New Query;
	If TMCommonUse.DebugMode() Then
		Query.TempTablesManager = New TempTablesManager();
	EndIf;
	
	Query.SetParameter("Date",                Date);
	Query.SetParameter("ManufacturedProducts",     ManufacturedProducts.Unload());
	Query.SetParameter("SideAndIntermediateRelease",     SideAndIntermediateRelease.Unload());
	Query.SetParameter("SupplyWithMaterialsAndWorks", SupplyWithMaterialsAndWorks.Unload());
	Query.SetParameter("Services",              Services.Unload());
	Query.SetParameter("References",        References.Unload());
	Query.SetParameter("GroupCosts",   GroupCosts);
	Query.SetParameter("ProcessingServices", ProcessingServices);
	
	TabularSections = Metadata.Documents.SubcontractOrder2_5.TabularSections;
	Query.SetParameter("TableNameOutputProducts",  TabularSections.ManufacturedProducts.Name);
	Query.SetParameter("NameOfByProductTable",  TabularSections.SideAndIntermediateRelease.Name);
	Query.SetParameter("NameOfMaterialsAndWorksTable", TabularSections.SupplyWithMaterialsAndWorks.Name);
	Query.SetParameter("ServiceTableName",           TabularSections.Services.Name);
	Query.SetParameter("NameOfDispositionTable",     TabularSections.References.Name);
	
	Query.SetParameter("NameOfManufacturedProductsPage",      "OutputProductsPage");
	
	Query.SetParameter("SynonymForTSOutputProducts",  TabularSections.ManufacturedProducts.Synonym);
	Query.SetParameter("SynonymOfTSByProducts",  TabularSections.SideAndIntermediateRelease.Synonym);
	Query.SetParameter("SynonymTSMaterialsAndWorks", TabularSections.SupplyWithMaterialsAndWorks.Synonym);
	Query.SetParameter("SynonymForTSServices",           TabularSections.Services.Synonym);
	Query.SetParameter("SynonymOfPMOrders",     TabularSections.References.Synonym);
	
	Query.SetParameter("UseImportedGoods", GetFunctionalOption("UseImportedGoods"));
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	QueryTexts = New Array;
	QueryTexts.Add(TMCommonUse.RequestTextObjectTSData(Ref, "References", False, "CostGroupNumber"));
	
	If GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
		And Not Documents.SubcontractOrder2_5.InteractiveEditing(ThisObject) Then
		QueryTexts.Add(QueryTextTSDocumentDescription("ManufacturedProducts"));
		QueryTexts.Add(QueryTextTSDocumentDescription("SideAndIntermediateRelease"));
		QueryTexts.Add(QueryTextTSDocumentDescription("SupplyWithMaterialsAndWorks"));
	Else
		QueryTexts.Add(TMCommonUse.RequestTextObjectTSData(Ref, "ManufacturedProducts", False, "CostGroupNumber"));
		QueryTexts.Add(TMCommonUse.RequestTextObjectTSData(Ref, "SideAndIntermediateRelease", False, "CostGroupNumber"));
		QueryTexts.Add(TMCommonUse.RequestTextObjectTSData(Ref, "SupplyWithMaterialsAndWorks", False, "CostGroupNumber"));
	EndIf;
	QueryTexts.Add(TMCommonUse.RequestTextObjectTSData(Ref, "Services", False, "CostGroupNumber"));
	QueryTexts.Add(Documents.SubcontractOrder2_5.RequestTextForDocumentSCostGroup());
	QueryTexts.Add(ProcessingByThirdParties.QueryTextTTImportedProducts());
	QueryTexts.Add(Documents.SubcontractOrder2_5.QueryTextTTImportedDocumentMaterials());
	
	VerificationRequestTexts = New Array;
	// The cost group is not filled in
	VerificationRequestTexts.Add(
		ProcessingByThirdParties.CheckTextNotFilledInCostGroupTSDocument(
			"ManufacturedProducts",
			"TableNameOutputProducts",
			"SynonymForTSOutputProducts"));
	
	VerificationRequestTexts.Add(
		ProcessingByThirdParties.CheckTextNotFilledInCostGroupTSDocument(
			"SideAndIntermediateRelease",
			"NameOfByProductTable",
			"SynonymOfTSByProducts"));
	
	VerificationRequestTexts.Add(
		ProcessingByThirdParties.CheckTextNotFilledInCostGroupTSDocument(
			"SupplyWithMaterialsAndWorks",
			"NameOfMaterialsAndWorksTable",
			"SynonymTSMaterialsAndWorks"));
	
	VerificationRequestTexts.Add(
		ProcessingByThirdParties.CheckTextNotFilledInCostGroupTSDocument(
			"Services",
			"ServiceTableName",
			"SynonymForTSServices"));
	
	// A non-existent cost group is specified
	VerificationRequestTexts.Add(
		ProcessingByThirdParties.VerificationTextNonExistentCostGroupTSDocument(
			"ManufacturedProducts",
			"TableNameOutputProducts",
			"SynonymForTSOutputProducts"));
	
	VerificationRequestTexts.Add(
		ProcessingByThirdParties.VerificationTextNonExistentCostGroupTSDocument(
			"SideAndIntermediateRelease",
			"NameOfByProductTable",
			"SynonymOfTSByProducts"));
	
	VerificationRequestTexts.Add(
		ProcessingByThirdParties.VerificationTextNonExistentCostGroupTSDocument(
			"SupplyWithMaterialsAndWorks",
			"NameOfMaterialsAndWorksTable",
			"SynonymTSMaterialsAndWorks"));
	
	VerificationRequestTexts.Add(
		ProcessingByThirdParties.VerificationTextNonExistentCostGroupTSDocument(
			"Services",
			"ServiceTableName",
			"SynonymForTSServices"));
	
	// Purpose not specified
	VerificationRequestTexts.Add(ProcessingByThirdParties.VerificationTextNoDestinationSpecified());
	
	// Materials are not specified
	VerificationRequestTexts.Add(
		ProcessingByThirdParties.VerificationTextMaterialsNotSpecified(
			"SupplyWithMaterialsAndWorks",
			"NameOfMaterialsAndWorksTable",
			"SynonymTSMaterialsAndWorks"));
	
	// The service is not specified
	VerificationRequestTexts.Add(ProcessingByThirdParties.VerificationTextServicesNotSpecified());
	
	// Products Not Specified
	VerificationRequestTexts.Add(ProcessingByThirdParties.TextOfCheckDoesNotSpecifyProducts());
	
	// Wrong type of cost
	VerificationRequestTexts.Add(
	"SELECT
	|	&TableNameOutputProducts       AS TableName,
	|	&SynonymForTSOutputProducts        AS TSSynonym,
	|	TabularSection.LineNumber       AS LineNumber,
	|	TabularSection.CostGroupNumber AS CostGroupNumber,
	|	""IncorrectCostType""     AS TypeOfVerification
	|FROM
	|	ManufacturedProducts AS TabularSection
	|
	|	INNER JOIN References AS References
	|	ON References.CostGroupNumber = TabularSection.CostGroupNumber
	|WHERE
	|	NOT CAST(References.ReferenceOrder AS Document.ProductionStage2_2).NextStageNo = 0
	|");
	If Not GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		
		// Several imported products are indicated
		VerificationRequestTexts.Add(ProcessingByThirdParties.TextCheckMultipleImportedProducts());
		
		// Imported material is not specified
		VerificationRequestTexts.Add(Documents.SubcontractOrder2_5.VerificationTextOmittedImportedMaterial());
		
		ProcessingByThirdPartiesLocalization.AddTextForRNPTVerification(VerificationRequestTexts, Date);
		
	EndIf;
	
	QueryTexts.Add(StrConcat(VerificationRequestTexts, TMCommonUse.QuerySeparatorInJoin()));
	
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Selection = Query.Execute().Select();
	If Not Selection.Count() = 0 Then
		
		PresentationOfCostGroups = New Map;
		
		CostGroups = Documents.SubcontractOrder2_5.CostGroupTable();
		Documents.SubcontractOrder2_5.UpdateCostGroups(ThisObject, CostGroups, 0);
		
		For Each CurGroup In CostGroups Do
			PresentationOfCostGroups.Insert(
				CurGroup.CostGroupNumber,
				ProcessingByThirdPartiesClientServer.CostGroupPresentation(
					CurGroup,
					ProcessingByThirdPartiesClientServer.ListOfOrderCostGroupFieldsForProcessor(GroupCosts)));
		EndDo;
		
		ProcessingByThirdParties.ReportErrorsFillingCostGroups(Selection, PresentationOfCostGroups, Cancel);
		
	EndIf;
	
EndProcedure

// The text of the request for orders of the document.
// 
// Parameters:
//  TSName - String - PM name
// 
// Returns:
//  String
//
Function QueryTextTSDocumentDescription(TSName) Export
	
	QueryText =
	"SELECT
	|	References.CostGroupNumber AS CostGroupNumber,
	|	&SelectionFields1
	|INTO TSName
	|FROM
	|	References AS References
	|	
	|	INNER JOIN Document.ProductionStage2_2.TSName AS TabularSection
	|	ON TabularSection.Ref = References.ReferenceOrder
	|
	|WHERE
	|	NOT TabularSection.Canceled
	|
	|INDEX BY
	|	CostGroupNumber
	|";
	
	SelectionFields1 = New Array;
	SelectionFields1.Add("TabularSection.LineNumber AS LineNumber");
	
	FieldPattern = "TabularSection.%1 AS %2";
	For Each CurProps In Metadata.Documents.ProductionStage2_2.TabularSections[TSName].Attributes Do
		SelectionFields1.Add(StrTemplate(FieldPattern, CurProps.Name, CurProps.Name));
	EndDo;
	
	QueryText = StrReplace(QueryText, "TSName", TSName);
	QueryText = StrReplace(QueryText, "&SelectionFields1", StrConcat(SelectionFields1, "," + Chars.LF));
	
	Return QueryText;
	
EndFunction

Procedure UpdateOrdersRelatedToOrder(Cancel)

	SetPrivilegedMode(True);
	
	If GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		Block = New DataLock;
		
		LockItem = Block.Add("Document.ProductionStage2_2");
		LockItem.DataSource = References;
		LockItem.UseFromDataSource("Ref", "ReferenceOrder");
		
		Try
			Block.Lock(); 
		Except
			MessageText = NStr("vi = 'Không thể phong tỏa các công đoạn sản xuất do: %Cause%';
								|ru = 'Не удалось заблокировать этапы производства по причине: %Cause%';
								|en = 'Cannot lock production stages. Reason: %Cause%'; fa = 'Cannot lock production stages. Reason: %Cause%';
								|it = 'Non è stato possibile bloccare le fasi di produzione a causa di: %Cause%';
								|pl = 'Nie udało się zablokować etapy produkcji z powodu: %Cause%';
								|tr = 'Üretim aşamalarının bloke edilememe nedeni: %Cause%'");
			MessageText = StrReplace(MessageText, "%Cause%", ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			Common.MessageToUser(MessageText,,,, Cancel); 
			Return;
		EndTry;
	EndIf;
	
	QueryText =
	"SELECT
	|	References.Ref                          AS Ref,
	|	MAX(References.OrderExcluded) AS OrderExcluded
	|FROM
	|	(SELECT
	|		ProductionStage2_2.Ref AS Ref,
	|		TRUE                     AS OrderExcluded
	|	FROM
	|		Document.ProductionStage2_2 AS ProductionStage2_2
	|	WHERE
	|		ProductionStage2_2.SubcontractOrder = &Ref
	|		AND NOT ProductionStage2_2.Ref IN (&ListOfOrders_)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProductionStage2_2.Ref AS Ref,
	|		FALSE                       AS OrderExcluded
	|	FROM
	|		Document.ProductionStage2_2 AS ProductionStage2_2
	|	WHERE
	|		ProductionStage2_2.Ref IN (&ListOfOrders_)
	|	) AS References
	|
	|GROUP BY
	|	References.Ref
	|";
		
	Query = New Query(QueryText);
	Query.SetParameter("ListOfOrders_", References.UnloadColumn("ReferenceOrder"));
	Query.SetParameter("Ref", Ref);
	
	Selection = Query.Execute().Select();
	
	OrderData_3 = Undefined;
	AdditionalProperties.Property("OrderData_3", OrderData_3);
	
	ThereIsControlOfClosingOrder = GetFunctionalOption("DoNotCloseTollingOrdersWithoutCompleteFulfillment2_5");
	
	While Selection.Next() Do
	
		OrderObject__ = Selection.Ref.GetObject(); // DocumentObject.ProductionStage2_2
		
		If Selection.OrderExcluded Then
			
			// The order was removed from the order
			OrderObject__.SubcontractOrder = Undefined;
			OrderObject__.ProductionByThirdParty2_5 = False;
			
			If OrderObject__.Status = Enums.StatusesOfProductionStages2_2.Initiated
				Or OrderObject__.Status = Enums.StatusesOfProductionStages2_2.Completed Then
				OrderObject__.Status = Enums.StatusesOfProductionStages2_2.ForCompletion;
				ProductionManagement.FillInStageDetailsWhenStatusChanges(OrderObject__, OrderObject__.Status);
			EndIf;
			
			ClearQualityControlDetails(OrderObject__);
			
		Else
			
			AddReference = Not OrderObject__.SubcontractOrder = Ref;
			StatusBeforeChange = OrderObject__.Status;
			
			OrderObject__.SubcontractOrder = Ref;
			OrderObject__.ProductionByThirdParty2_5 = True;
			
			If AddReference
				Or Not OrderData_3 = Undefined Then
				
				ParametersStructure = New Structure;
				ParametersStructure.Insert("New_Order", AddReference);
				ParametersStructure.Insert("RowFilter", New Structure("Ref", Selection.Ref));
				ParametersStructure.Insert("TSName");
				
				ParametersStructure.TSName = "ManufacturedProducts";
				FillInLineCodeInTableSectionOrders(
					OrderObject__,
					OrderData_3,
					ProductsMaxRowCode,
					ParametersStructure);
					
				ParametersStructure.TSName = "SideAndIntermediateRelease";
				FillInLineCodeInTableSectionOrders(
					OrderObject__,
					OrderData_3,
					ProductsMaxRowCode,
					ParametersStructure);
					
				ParametersStructure.TSName = "SupplyWithMaterialsAndWorks";
				FillInLineCodeInTableSectionOrders(
					OrderObject__,
					OrderData_3,
					MaximumRowCodeMaterials,
					ParametersStructure);
				
			EndIf;
			
			If Not OrderData_3 = Undefined Then
				Documents.SubcontractOrder2_5.TransferChangesToOrder(
					OrderObject__,
					OrderData_3);
			EndIf; 
			
			OrderObject__.MaximumRowCodeFinishedProductsSideAndIntermediateRelease = ProductsMaxRowCode;
			OrderObject__.MaximumRowCodeMaterialsAndServicesSupply = MaximumRowCodeMaterials;
			
			If ThereIsControlOfClosingOrder
				And Status = Enums.TollingOrderStatuses.Closed
				And Not OrderObject__.Status = Enums.StatusesOfProductionStages2_2.Completed Then
				OrderObject__.Status = Enums.StatusesOfProductionStages2_2.Completed;
				ProductionManagement.FillInStageDetailsWhenStatusChanges(OrderObject__, StatusBeforeChange);
			EndIf;
			
		EndIf;
		
		Try
			
			InteractiveEditing = Documents.SubcontractOrder2_5.InteractiveEditing(ThisObject);
			
			If (InteractiveEditing
					And Not AdditionalProperties.WriteMode = DocumentWriteMode.Posting
					Or Not InteractiveEditing)
				And OrderObject__.Posted Then
				If Not OrderObject__.CheckFilling() Then
					Cancel = True;
					Return;
				EndIf;
			EndIf;
			
			If AdditionalProperties.WriteMode = DocumentWriteMode.Posting
				Or AdditionalProperties.WriteMode = DocumentWriteMode.UndoPosting
					And OrderObject__.Posted Then
				OrderObject__.Write(DocumentWriteMode.Posting);
			Else
				OrderObject__.Write();
			EndIf;
			
		Except
			
			MessageText =
				NStr("vi = 'Không thể ghi lại các thay đổi trong công đoạn %1 do nguyên nhân:
					|%2';
					|ru = 'Не удалось записать изменения в этапе %1 по причине:
					|%2';
					|en = 'Cannot save changes for the %1 stage due to:
					|%2'; fa = 'Cannot save changes for the %1 stage due to:
					|%2';
					|it = 'Non è stato possibile registrare le modifiche nella fase %1 a causa di:
					|%2';
					|pl = 'Nie udało się zapisać zmiany w etapie %1 z powodu:
					|%2';
					|tr = '%1 aşamasında değişikliklerin kaydedilememe nedeni:
					|%2'");
			MessageText = StrTemplate(MessageText, OrderObject__, ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			
			Common.MessageToUser(MessageText, OrderObject__,,, Cancel);
			
			Return;
			
		EndTry;
	
	EndDo;
	
EndProcedure

Procedure RemoveLinkBetweenOrderAndOrder(Cancel)

	SetPrivilegedMode(True);
	
	QueryText =
	"SELECT
	|	ProductionStage2_2.Ref
	|FROM
	|	Document.ProductionStage2_2 AS ProductionStage2_2
	|WHERE
	|	ProductionStage2_2.SubcontractOrder = &Ref";
		
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Ref);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
	
		OrderObject__ = Selection.Ref.GetObject(); // DocumentObject.ProductionStage2_2
		
		OrderObject__.SubcontractOrder = Undefined;
		OrderObject__.ProductionByThirdParty2_5 = False;
		
		ClearQualityControlDetails(OrderObject__);
		
		StatusBeforeChange = OrderObject__.Status;
		If StatusBeforeChange = Enums.StatusesOfProductionStages2_2.Initiated
			Or StatusBeforeChange = Enums.StatusesOfProductionStages2_2.Completed Then
			OrderObject__.Status = Enums.StatusesOfProductionStages2_2.ForCompletion;
			ProductionManagement.FillInStageDetailsWhenStatusChanges(OrderObject__, StatusBeforeChange);
		EndIf;
		
		If OrderObject__.Posted Then
			OrderObject__.Write(DocumentWriteMode.Posting);
		Else
			OrderObject__.Write();
		EndIf;
		
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

Procedure CheckAbilityToCommunicateWithOrders(Cancel)

	SetPrivilegedMode(True);
	
	Try
		Block = New DataLock;
		LockItem = Block.Add("Document.ProductionStage2_2");
		LockItem.DataSource = References;
		LockItem.UseFromDataSource("Ref", "ReferenceOrder");
		Block.Lock();
	Except
		MessageText = NStr("vi = 'Không thể phong tỏa các công đoạn sản xuất do: %Cause%';
							|ru = 'Не удалось заблокировать этапы производства по причине: %Cause%';
							|en = 'Cannot lock production stages. Reason: %Cause%'; fa = 'Cannot lock production stages. Reason: %Cause%';
							|it = 'Non è stato possibile bloccare le fasi di produzione a causa di: %Cause%';
							|pl = 'Nie udało się zablokować etapy produkcji z powodu: %Cause%';
							|tr = 'Üretim aşamalarının bloke edilememe nedeni: %Cause%'");
		MessageText = StrReplace(MessageText, "%Cause%", ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Common.MessageToUser(MessageText,,,, Cancel); 
		Return;
	EndTry;
	
	QueryText =
	"SELECT
	|	ProductionStage2_2.Ref,
	|	TRUE AS IncludedInAnotherOrder,
	|	FALSE AS OwnProduction,
	|	FALSE AS DuringShipment,
	|	FALSE AS InProcessOfShipmentCancellationOfEvent
	|FROM
	|	Document.ProductionStage2_2 AS ProductionStage2_2
	|WHERE
	|	ProductionStage2_2.Ref IN(&StageList)
	|	AND NOT ProductionStage2_2.SubcontractOrder = &Ref
	|	AND NOT ProductionStage2_2.SubcontractOrder = UNDEFINED
	|
	|UNION ALL
	|
	|SELECT
	|	ProductionStage2_2.Ref,
	|	FALSE AS IncludedInAnotherOrder,
	|	TRUE AS OwnProduction,
	|	FALSE AS DuringShipment,
	|	FALSE AS InProcessOfShipmentCancellationOfEvent
	|FROM
	|	Document.ProductionStage2_2 AS ProductionStage2_2
	|WHERE
	|	ProductionStage2_2.Ref IN(&StageList)
	|	AND NOT ProductionStage2_2.ProductionByThirdParty
	|
	|UNION ALL
	|
	|SELECT
	|	MaterialsAndWorks.Ref,
	|	FALSE AS IncludedInAnotherOrder,
	|	FALSE AS OwnProduction,
	|	TRUE AS DuringShipment,
	|	FALSE AS InProcessOfShipmentCancellationOfEvent
	|FROM
	|	Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS MaterialsAndWorks
	|WHERE
	|	&DeletionMark
	|	AND MaterialsAndWorks.Ref IN(&StageList)
	|	AND NOT MaterialsAndWorks.Ref.DeletionMark
	|	AND MaterialsAndWorks.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|
	|GROUP BY
	|	MaterialsAndWorks.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	MaterialsAndWorks.Ref,
	|	FALSE AS IncludedInAnotherOrder,
	|	FALSE AS OwnProduction,
	|	FALSE AS DuringShipment,
	|	TRUE AS InProcessOfShipmentCancellationOfEvent
	|FROM
	|	Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS MaterialsAndWorks
	|WHERE
	|	&UndoPosting
	|	AND NOT &DeletionMark
	|	AND MaterialsAndWorks.Ref IN(&StageList)
	|	AND NOT MaterialsAndWorks.Ref.DeletionMark
	|	AND MaterialsAndWorks.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|
	|GROUP BY
	|	MaterialsAndWorks.Ref
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("StageList", References.UnloadColumn("ReferenceOrder"));
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("DeletionMark", DeletionMark);
	Query.SetParameter("UndoPosting", AdditionalProperties.WriteMode = DocumentWriteMode.UndoPosting);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		If Selection.IncludedInAnotherOrder Then
			MessageText = NStr("vi = '%1 được đưa vào một đơn hàng gia công khác. Không được phép đưa một công đoạn vào các đơn đặt hàng khác nhau.';
								|ru = '%1 включен в другой заказ переработчику. Не допускается включать один этап в разные заказы переработчику.';
								|en = '%1 is included in another subcontracting purchase order. Cannot include one stage in different subcontracting purchase orders.'; fa = '%1 is included in another subcontracting purchase order. Cannot include one stage in different subcontracting purchase orders.';
								|it = '%1 attivato in un altro ordine elaboratore. Non è concesso attivare la stessa fase in diversi ordini elaboratore.';
								|pl = '%1 jest dodany do innego zamówienia przetwórcy. Nie dopuszczalne jest dodawanie jednego etapu do różnych zamówień przetwórcy.';
								|tr = '%1, başka bir fason satın alma siparişine dahil edildi. Bir aşamanın farklı fason satın alma siparişine dahil edilmesine izin verilmemektedir.'");
			MessageText = StrTemplate(MessageText, Selection.Ref);
		ElsIf Selection.OwnProduction Then
			MessageText = NStr("vi = '%1 liên quan đến sản xuất nội bộ. Không được phép đưa công đoạn sản xuất riêng vào đơn hàng gia công.';
								|ru = '%1 относится к собственному производству. Не допускается включать в заказ переработчику этапы собственного производства.';
								|en = '%1 belongs to in-house production. Cannot include in-house production stages in subcontracting purchase order.'; fa = '%1 belongs to in-house production. Cannot include in-house production stages in subcontracting purchase order.';
								|it = '%1 si riferisce alla produzione propria. Non è consentito attivare fasi di produzione propria nell''ordine elaboratore.';
								|pl = '%1 należy do produkcji własnej. Nie dopuszczalne jest dodawanie etapów produkcji własnej do zamówienia przetwórcy.';
								|tr = '%1, şirket içi üretimi ifade etmektedir. Fason satın alma siparişine şirket içi üretim aşamalarının dahil edilmesine izin verilmemektedir.'");
			MessageText = StrTemplate(MessageText, Selection.Ref);
		ElsIf Selection.DuringShipment Then
			MessageText = NStr("vi = '%1 đang trong quá trình giao hàng. Không được phép đặt dấu xóa đơn hàng gia công.';
								|ru = '%1 находится в процессе отгрузки. Пометка на удаление заказа переработчику не допускается.';
								|en = '%1 is being shipped. Cannot mark ""Subcontracting purchase order"" for deletion.'; fa = '%1 is being shipped. Cannot mark ""Subcontracting purchase order"" for deletion.';
								|it = '%1 si trova nel processo di spedizione. Non è consentito il contrassegno per l''eliminazione dell''ordine elaboratore.';
								|pl = '%1 jest w trakcie wysyłki. Zaznaczenie do usunięcia zamówienia przetwórcy nie jest dopuszczalne.';
								|tr = '%1, sevkiyat sürecinde bulunmaktadır. Fason üretici satın alma siparişinin silinmek üzere işaretlenmesine izin verilmemektedir.'");
			MessageText = StrTemplate(MessageText, Selection.Ref);
		ElsIf Selection.InProcessOfShipmentCancellationOfEvent Then
			MessageText = NStr("vi = '%1 đang trong quá trình giao hàng. Không được phép thực hiện đơn hàng đặt gia công.';
								|ru = '%1 находится в процессе отгрузки. Отмена проведения заказа переработчику не допускается.';
								|en = '%1 is being shipped. You cannot unpost the subcontracting purchase order.'; fa = '%1 is being shipped. You cannot unpost the subcontracting purchase order.';
								|it = '%1 находится в процессе отгрузки. Отмена проведения заказа переработчику не допускается.';
								|pl = '%1 is being shipped. You cannot unpost the subcontracting purchase order.';
								|tr = '%1, sevkiyat sürecinde bulunmaktadır. Fason üretici satın alma siparişinin kaydedilmesinin iptaline izin verilmemektedir.'");
			MessageText = StrTemplate(MessageText, Selection.Ref);
		EndIf;
		Common.MessageToUser(MessageText, Selection.Ref,,, Cancel); 
		
	EndDo; 
	
	SetPrivilegedMode(False);
	
EndProcedure

Procedure UpdateMaximumRowCodesOnOrders()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ISNULL(MAX(MaximumLineCodes.ProductsMaxRowCode), 0)   AS ProductsMaxRowCode,
	|	ISNULL(MAX(MaximumLineCodes.MaximumRowCodeMaterials), 0) AS MaximumRowCodeMaterials
	|FROM
	|	(SELECT
	|		OrdersToProcessor.ProductsMaxRowCode   AS ProductsMaxRowCode,
	|		OrdersToProcessor.MaximumRowCodeMaterials AS MaximumRowCodeMaterials
	|	FROM
	|		Document.SubcontractOrder2_5 AS OrdersToProcessor
	|	WHERE
	|		OrdersToProcessor.Ref = &SubcontractOrder
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProductionStages.MaximumRowCodeFinishedProductsSideAndIntermediateRelease     AS ProductsMaxRowCode,
	|		ProductionStages.MaximumRowCodeMaterialsAndServicesSupply AS MaximumRowCodeMaterials
	|	FROM
	|		Document.ProductionStage2_2 AS ProductionStages
	|	WHERE
	|		ProductionStages.Ref IN (&References)
	|	) AS MaximumLineCodes
	|";
	Query.SetParameter("SubcontractOrder", Ref);
	Query.SetParameter("References", References.UnloadColumn("ReferenceOrder"));
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FillPropertyValues(ThisObject, Selection);
	EndIf;
	
EndProcedure

Procedure FillInLineCodeInTableSectionOrders(ReferenceOrder, OrderData_3, MaximumRowCode, ParametersStructure)
	
	TSName = ParametersStructure.TSName;
	
	CollectionOfTSStrings =
		?(Not OrderData_3 = Undefined,
			OrderData_3[TSName].FindRows(ParametersStructure.RowFilter),
			ReferenceOrder[TSName]);
	
	Documents.SubcontractOrder2_5.FillInLineCodeInTableSection(
		CollectionOfTSStrings,
		ParametersStructure.New_Order,
		MaximumRowCode);
	
EndProcedure	

// Clears the quality control Attributes of the production stage.
//
// Parameters:
//   OrderObject__ - DocumentObject.ProductionStage2_2 - The object is the order in which the Attributes are cleared.
//
Procedure ClearQualityControlDetails(OrderObject__)
	
	If GetFunctionalOption("UseGoodsQualityControl") Then
		
		Filter = New Structure("ToControlQuality", True);
		
		For Each CurrentData In OrderObject__.ManufacturedProducts.FindRows(Filter) Do
			CurrentData.ToControlQuality = False;
			CurrentData.QualityConfirmationDate = Undefined;
		EndDo;
		
		For Each CurrentData In OrderObject__.SideAndIntermediateRelease.FindRows(Filter) Do
			CurrentData.ToControlQuality = False;
			CurrentData.QualityConfirmationDate = Undefined;
		EndDo;
		
	EndIf;
	
EndProcedure

Function YouNeedToUpdateAssignment()
	If GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		Return False;
	EndIf;
	UpdateRequired_1 = False;
	YouNeedToCheckChangeOfBankingDetails = False;
	
	For Each ContentLine In SupplyWithMaterialsAndWorks Do
		If ContentLine.WithAssignment Then
			If Not ValueIsFilled(ContentLine.Purpose) Then
				UpdateRequired_1 = True;
				Break;
			ElsIf Not YouNeedToCheckChangeOfBankingDetails Then
				YouNeedToCheckChangeOfBankingDetails = True;
			EndIf;
		ElsIf ValueIsFilled(ContentLine.Purpose) Then
			UpdateRequired_1 = True;
			Break;
		EndIf;
	EndDo;
	
	If Not UpdateRequired_1 And Not IsNew() And YouNeedToCheckChangeOfBankingDetails Then
		CompositionOfVerifiedDetails = "Organization,Partner,Contract,GroupCosts,LineOfBusiness,Date,Posted";
		DetailsBeforeRecording = Common.ObjectAttributesValues(Ref, CompositionOfVerifiedDetails);
		UpdateRequired_1 = Not TMCommonUseClientServer.StructuresAreEqual(DetailsBeforeRecording, ThisObject, CompositionOfVerifiedDetails);
	EndIf;
	
	Return UpdateRequired_1;
	
EndFunction

Procedure FillInAssignmentsInMaterials()
	
	If Not YouNeedToUpdateAssignment() Then
		Return;
	EndIf;
	
	Documents.SubcontractOrder2_5.FillInAssignmentsInMaterials(ThisObject);
	
EndProcedure

Function MaximumPossibleDateOfShipmentOfMaterials()
	
	If OneDateReceipt Then
		Return EndOfMonth(DateOfReceipt);
	EndIf;
	
	// When the production date is indicated in the tabular parts of the products and returnable waste
	// , the shipment of all materials cannot be greater than the minimum date of the maximum production dates of each grouping.
	Result = Date(2999, 1, 1, 0, 0, 0);
	MaximumDates = MaximumProductionDatesOfCostGroups();
	For Each KeyAndValue In MaximumDates Do
		Result = Min(KeyAndValue.Value, Result);
	EndDo;
	
	Return Result;
	
EndFunction

Function MaximumProductionDatesOfCostGroups()
	
	Result = New Map;
	
	For Each String In ManufacturedProducts Do
		CostGroupDate = Result.Get(String.CostGroupNumber);
		If CostGroupDate = Undefined Then
			Result.Insert(String.CostGroupNumber, EndOfMonth(String.DateOfReceipt));
		Else
			Result.Insert(String.CostGroupNumber, Max(EndOfMonth(String.DateOfReceipt), CostGroupDate));
		EndIf;
	EndDo;
	If GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		
		OrderData_3 = Common.ObjectsAttributesValues(References.UnloadColumn("ReferenceOrder"), "NextStageNo");
		
		For Each CurrentData In References Do
			
			TheseOrders_ = OrderData_3.Get(CurrentData.ReferenceOrder);
			
			If Not ProductionManagementClientServer.ThisIsAProductionIssueStage(TheseOrders_) Then
				
				Filter = New Structure("CostGroupNumber", CurrentData.CostGroupNumber);
				For Each String In SideAndIntermediateRelease.FindRows(Filter) Do
					
					CostGroupDate = Result.Get(String.CostGroupNumber);
					
					If CostGroupDate = Undefined Then
						Result.Insert(String.CostGroupNumber, EndOfMonth(String.DateOfReceipt));
					Else
						Result.Insert(String.CostGroupNumber, Max(EndOfMonth(String.DateOfReceipt), CostGroupDate));
					EndIf;
					
				EndDo;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	Return Result;
	
EndFunction

// Calculates the amount of non-canceled raw material delivery lines
//
// Returns:
// 	Structure - LongDesc:
// 	* Sum - Number - Deposit amount
// 	* Date - Date - date of shipment.
//
Function GetDepositAmountWithShippingDate()
	
	Query = New Query(
	"SELECT
	|	Goods.Products AS Products,
	|	Goods.Sum AS Sum,
	|	Goods.DateOfShipment AS DateOfShipment,
	|	Goods.Canceled AS Canceled
	|INTO
	|	Goods
	|FROM
	|	&Goods AS Goods
	|;
	|SELECT
	|	ISNULL(SUM(Goods.Sum), 0) AS Sum,
	|	ISNULL(MIN(Goods.DateOfShipment), DATETIME(1,1,1)) AS DateOfShipment
	|FROM
	|	Goods AS Goods
	|WHERE
	|	NOT Goods.Canceled");
	
	Query.SetParameter("Goods", SupplyWithMaterialsAndWorks.Unload(,"Products, Sum, DateOfShipment, Canceled"));
	Upload0 = Query.Execute().Unload();
	
	Result = New Structure;
	Result.Insert("Sum", Upload0[0].Sum);
	Result.Insert("DateOfShipment", Upload0[0].DateOfShipment);
	
	Return Result;
	
EndFunction

Function DocumentAmounts()
	
	Result = New Structure("VATAmount, AmountIncludingVAT", 0, 0);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Services.AmountIncludingVAT AS AmountIncludingVAT
	|INTO TTDocumentAmount
	|FROM
	|	&Services AS Services
	|WHERE
	|	NOT Services.Canceled
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(DocumentAmounts.AmountIncludingVAT) AS AmountIncludingVAT
	|FROM
	|	TTDocumentAmount AS DocumentAmounts
	|";
	Query.SetParameter("Services", Services.Unload(, "Canceled, AmountIncludingVAT"));
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FillPropertyValues(Result, Selection);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
