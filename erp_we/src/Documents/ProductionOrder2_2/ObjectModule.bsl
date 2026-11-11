#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Sets the status for the document object
//
// Parameters:
//	NewStatus - String - Name of the status that will be set for orders
//	AdditionalParameters - Structure - Structure of additional parameters for setting the status
//								Structure constructor: Order a server.Structurecorrectionslist of orders().
//
// Returns:
//	Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.ProductionOrderStatuses2_2[NewStatus];
	
	Status = MeaningOfNewStatus;
	
	Return CheckFilling();
	
EndFunction

// Cancel the products of the order.
// 
// Parameters:
//  Products - CatalogRef.Products
//  Characteristic - CatalogRef.ItemsCharacteristics
//  BillOfMaterials - CatalogRef.BillsOfMaterials
//  Count - Number
//  CancellationReason - CatalogRef.ReasonsForProductionCancellation
//
Procedure CancelProducts(Products, Characteristic, BillOfMaterials, Val Count, CancellationReason) Export
	
	ReadyForProcessing_ = New Array;
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Products", Products);
	TheStructureOfTheSearch.Insert("Characteristic", Characteristic);
	TheStructureOfTheSearch.Insert("BillOfMaterials", BillOfMaterials);
	TheStructureOfTheSearch.Insert("Canceled", False);
	
	FoundRows = ManufacturedProduct.FindRows(TheStructureOfTheSearch);
	For IndexOf = -FoundRows.UBound() To 0 Do
		String = FoundRows[-IndexOf];
		
		If String.Count > Count Then
			NewRow = ManufacturedProduct.Insert(ManufacturedProduct.IndexOf(String)+1);
			FillPropertyValues(NewRow, String,, "Count, NumberOfPackages, KeyProducts");
			NewRow.Count = Count;
			NewRow.Canceled = True;
			NewRow.CancellationReason = CancellationReason;
			ReadyForProcessing_.Add(NewRow);
			
			String.Count = String.Count - Count;
			ReadyForProcessing_.Add(String);
			
			Count = 0;
		Else
			String.Canceled = True;
			String.CancellationReason = CancellationReason;
			Count = Count - String.Count;
		EndIf;
		
		If Count = 0 Then
			Break;
		EndIf;
	EndDo;
	
	If ReadyForProcessing_.Count() <> 0 Then
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfPackages");
		
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			ReadyForProcessing_,
			StructureOfActions,
			ManufacturedProduct,
			CachedValues);
	EndIf;
	
EndProcedure

// Replace the products of the order.
// 
// Parameters:
//  KeysOfProduction - Structure - Contains:
//    * Products - CatalogRef.Products
//    * Characteristic - CatalogRef.ItemsCharacteristics
//    * BillOfMaterials - CatalogRef.BillsOfMaterials
//  Count - Number
//  CancellationReason - CatalogRef.ReasonsForProductionCancellation
//  NewProductKeys - Structure - Contains:
//    * Products - CatalogRef.Products
//    * Characteristic - CatalogRef.ItemsCharacteristics
//    * BillOfMaterials - CatalogRef.BillsOfMaterials
//
Procedure ReplaceProducts(KeysOfProduction, Val Count, CancellationReason, NewProductKeys) Export
	
	ReadyForProcessing_ = New Array;
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Products", KeysOfProduction.Products);
	TheStructureOfTheSearch.Insert("Characteristic", KeysOfProduction.Characteristic);
	TheStructureOfTheSearch.Insert("BillOfMaterials", KeysOfProduction.BillOfMaterials);
	TheStructureOfTheSearch.Insert("Canceled", False);
	
	FoundRows = ManufacturedProduct.FindRows(TheStructureOfTheSearch);
	For IndexOf = -FoundRows.UBound() To 0 Do
		String = FoundRows[-IndexOf];
		CancelLine = Undefined;
		
		If String.Count > Count Then
			NewRow = ManufacturedProduct.Insert(ManufacturedProduct.IndexOf(String)+1);
			FillPropertyValues(NewRow, String,, "Count, NumberOfPackages, KeyProducts");
			NewRow.Count = Count;
			NewRow.Canceled = True;
			NewRow.CancellationReason = CancellationReason;
			ReadyForProcessing_.Add(NewRow);
			CancelLine = NewRow;
			
			String.Count = String.Count - Count;
			ReadyForProcessing_.Add(String);
			
			Count = 0;
		Else
			String.Canceled = True;
			String.CancellationReason = CancellationReason;
			CancelLine = String;
			Count = Count - String.Count;
		EndIf;
		
		NewRow = ManufacturedProduct.Insert(ManufacturedProduct.IndexOf(CancelLine)+1);
		FillPropertyValues(NewRow, CancelLine,, "Products, Characteristic, BillOfMaterials, Canceled, CancellationReason, KeyProducts");
		NewRow.Products = NewProductKeys.Products;
		NewRow.Characteristic = NewProductKeys.Characteristic;
		NewRow.BillOfMaterials = NewProductKeys.BillOfMaterials;
		If Not NewRow.Package.IsEmpty() Then
			NewRow.Package = Catalogs.PackagesAndUnitsOfMeasure.IdenticalPackaging(
				CancelLine.Products, NewRow.Products, NewRow.Package);
		EndIf;
		If ReadyForProcessing_.Count() <> 0 Then
			ReadyForProcessing_.Add(NewRow);
		EndIf;
		
		If Count = 0 Then
			Break;
		EndIf;
	EndDo;
	
	If ReadyForProcessing_.Count() <> 0 Then
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfPackages");
		
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			ReadyForProcessing_,
			StructureOfActions,
			ManufacturedProduct,
			CachedValues);
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	Author = Users.AuthorizedUser();
	
	ProductionProcessType = Metadata.Documents.ProductionOrder2_2.Attributes.ProductionProcessType.FillValue;
	DynamicStructure = GetFunctionalOption("DynamicStructureOfProductionOrders");
	EarliestStartDate = BegOfDay(CurrentSessionDate());
	ProductionScheduling = ?(DynamicStructure, 
		Enums.WayOfLinkingProductionOperations.ToFinish, // not used in dynamic structure
		Metadata.Documents.ProductionOrder2_2.Attributes.ProductionScheduling.FillValue);

	SetPriorityAndQueueNumberAsNeeded = False;
	ClearBusinessTransaction = False;

	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("HeaderAttributes") Then
			FillPropertyValues(ThisObject, FillingData.HeaderAttributes);
		Else
			FillPropertyValues(ThisObject, FillingData);
		EndIf;
		
		If FillingData.Property("Basis") Then // creation based on an order
			
			BasisType = TypeOf(FillingData.Basis);
			If BasisType = Type("DocumentRef.SalesOrder") Then
				FillInOnTheCustomerSOrder(FillingData);
			ElsIf BasisType = Type("DocumentRef.TransferOrder") Then
				FillInByMovingOrder(FillingData);
				Assignments = ManufacturedProduct.Unload(, "Purpose").UnloadColumn("Purpose");
				BusinessOperation = TollingScheme.BusinessTransactionOfProduction(Assignments);
				ClearBusinessTransaction = Not ValueIsFilled(BusinessOperation);
			ElsIf BasisType = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
				FillInRefundRequestSoftware(FillingData);
			ElsIf BasisType = Type("DocumentRef.InventoryConsumptionOrder") Then
				FillOnOrderForDomesticConsumption(FillingData);
			ElsIf BasisType = Type("DocumentRef.RMOrder") Then
				FillInByRepairOrder(FillingData);
			ElsIf BasisType = Type("DocumentRef.ByAssemblyDisassemblyOrder") Then
				FillInByOrderForAssembly(FillingData);
			ElsIf BasisType = Type("DocumentRef.OrderOfMaterialsForProduction") Then
				FillInOrderOfMaterialsInProduction(FillingData);
				Assignments = ManufacturedProduct.Unload(, "Purpose").UnloadColumn("Purpose");
				BusinessOperation = TollingScheme.BusinessTransactionOfProduction(Assignments);
				ClearBusinessTransaction = Not ValueIsFilled(BusinessOperation);
			ElsIf BasisType = Type("DocumentRef.ProductionStage2_2") Then
				FillInByProductionStage2_2(FillingData);
			EndIf;
			
		ElsIf FillingData.Property("Goods") Then // Filling out of processing of provision of needs, formation of the order of production plan
			
			FillInProductsTable(FillingData.Goods);
			
			SetPriorityAndQueueNumberAsNeeded = True;
			
		EndIf;
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.MaterialProviderOrder2_5") Then
		FillInByOrderOfGiver2_5(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ApplicationForCollateral") Then
		FillInDocumentBasedOnSupplyRequest(FillingData);
	EndIf;
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Department = SettingsValueCached.GetDefaultManagerDivision(Department, EmployeeResponsible);
	
	If SetPriorityAndQueueNumberAsNeeded Then
		If FillingData.Property("Source") And FillingData.Source = "GenerationOfProductionOrdersByPlans" Then
				SetNewQueueNumberByDateOfNeed();
			Else
				SetPriorityAndQueueNumberAccordingToPurposeOfNeed();
		EndIf;
	EndIf;

	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	Priority = SettingsValueCached.GetDefaultPriority(Priority);
	EmployeeResponsible = Users.CurrentUser();

	FillParameters = Documents.ProductionOrder2_2.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(OrderForActivity, FillParameters);
	
	ItemsAndDimensionsSelectionParameters = Documents.ProductionOrder2_2.ItemsAndDimensionsSelectionParameters(ThisObject);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	If Not ValueIsFilled(BusinessOperation) Then
		BusinessOperation = Enums.BusinessTransactions.OwnProduction;
	EndIf;
	If ClearBusinessTransaction Then
		BusinessOperation = Enums.BusinessTransactions.EmptyRef();
	EndIf; 
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	UseCharacteristics = GetFunctionalOption("UseItemVariants");
	TheProductionScheduleIsPlanned = ProductionManagementCached.TheProductionScheduleIsUsed();
	
	NeedDateIsUsed = Not
		ProductionProcessType = Enums.ProductionProcessTypes.Disassembly;
	DemandDateRequired_ = NeedDateIsUsed
		And (DynamicStructure And Not TheProductionScheduleIsPlanned
			Or Not DynamicStructure And ProductionScheduling = Enums.WayOfLinkingProductionOperations.ToFinish);
		
#Region IsMain
	
	// Division-dispatcher
	If ValueIsFilled(Department) 
		And ProductionServerCached.ProductionBusinessUnitDescription(Department).ProductionDispatcherBusinessUnit <> True Then
		ErrorText = NStr("vi = 'Bộ phận chịu trách nhiệm thực hiện lệnh phải là Bộ phận điều phối';
						|ru = 'Подразделением, ответственным за выполнение заказа, должно быть подразделение-диспетчер';
						|en = 'Dispatching unit should be a business unit responsible for the order fulfillment'; fa = 'Dispatching unit should be a business unit responsible for the order fulfillment';
						|it = 'Il reparto responsabile per l''evasione dell''ordine deve essere reparto di controllo';
						|pl = 'Działem, odpowiedzialnym za wykonanie zamówienie, powinien dział dyspozytor';
						|tr = 'Siparişin karşılanmasından sorumlu departman, üretim planlama departmanı olmalıdır'");
		Common.MessageToUser(ErrorText,,"Department", "Object", Cancel);
	EndIf;
	
	// Desired date, start no earlier, release mixing
	NotCheckedAttributeArray.Add("DemandDate");
	
	If Not DemandDateIsSpecifiedInLines
		And (DemandDateRequired_ And Not ValueIsFilled(DemandDate)) Then
		ErrorText = NStr("vi = 'Chưa điền ngày mong muốn xuất xưởng';
						|ru = 'Желаемая дата выпуска не заполнена';
						|en = 'Requested release date is unfilled'; fa = 'Requested release date is unfilled';
						|it = 'Желаемая дата выпуска не заполнена';
						|pl = 'Requested release date is unfilled';
						|tr = 'Talep edilen bitiş tarihi doldurulmadı'");
		Common.MessageToUser(ErrorText,,"DateOfNeedOnForm",, Cancel);
	EndIf;
	
	If Not DemandDateIsSpecifiedInLines
		And (EarliestStartDate > DemandDate And ValueIsFilled(EarliestStartDate) And ValueIsFilled(DemandDate)) Then
		ErrorText = NStr("vi = 'Ngày dự kiến xuất xưởng nhỏ hơn ngày bắt đầu sản xuất';
						|ru = 'Желаемая дата выпуска меньше даты начала производства';
						|en = 'Required release date is earlier than the production start date'; fa = 'Required release date is earlier than the production start date';
						|it = 'Data di avvio richiesta è precedente alla data di inizio di produzione';
						|pl = 'Pożądana data produkcji jest mniejsza niż data rozpoczęcia produkcji';
						|tr = 'Talep edilen bitiş tarihi, üretim başlangıç ​​tarihinden daha eskidir'");
		Common.MessageToUser(ErrorText,,"DateOfNeedOnForm",, Cancel);
	EndIf;
	
	If Status = Enums.ProductionOrderStatuses2_2.BeingGenerated Or DynamicStructure Then
		NotCheckedAttributeArray.Add("ProductionScheduling");
	EndIf;
	
	// Giveaway production
	If BusinessOperation = Enums.BusinessTransactions.OwnProduction Then
		NotCheckedAttributeArray.Add("Partner");
		NotCheckedAttributeArray.Add("Contract");
	Else
		If ContractIsNotRequired Then
			NotCheckedAttributeArray.Add("Contract");
		EndIf;
	EndIf;
	
	// The purpose of the output finished products obtained as a result of REVERSE kitting should be filled in the toll-taking scheme for the static structure.
	If BusinessOperation <> Enums.BusinessTransactions.TollManufacturing2_5
			And True
		Or Not DestinationIsIndicatedInHeaderOfDocument() Then
		NotCheckedAttributeArray.Add("AssignmentProducts");
	EndIf;
	
	// The cost allocation method for output items should be filled in only for orders
	// with the "No Specifications" process type
	If ProductionProcessType <> Enums.ProductionProcessTypes.WithoutBillsOfMaterials Then
		NotCheckedAttributeArray.Add("MethodOfAllocatingFinishedProductCosts");
	EndIf;

#EndRegion	

#Region FinishedProductBeingRepaired
	
	// Checking the Attributes of the finishedproduct being repaired.
	If ProductionProcessType = Enums.ProductionProcessTypes.PerformRM
		And Not UnderRepairProduct.IsEmpty() Then
		
		If Not UseCharacteristics
			Or Not Catalogs.Products.ItemVariantsAreUsed(UnderRepairProduct) Then
			
			NotCheckedAttributeArray.Add("UnderRepairVariant");
			
		EndIf;
		
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ProductionOrder2_2);
		
		ProductsServer.CheckSeriesCompletion(
			ProductionManagementClientServer.DataOfFinishedProductBeingRepairedByStructure(ThisObject),
			SeriesSpecificationParameters.FinishedProductBeingRepaired,
			Cancel,
			NotCheckedAttributeArray);
		
	Else
		NotCheckedAttributeArray.Add("UnderRepairVariant");
		NotCheckedAttributeArray.Add("UnderRepairBatch");
	EndIf;
	
#EndRegion

#Region ManufacturedProduct
	
	// Checking the tabular part "Products"

	NotCheckedAttributeArray.Add("ManufacturedProduct");
	NotCheckedAttributeArray.Add("ManufacturedProduct.Products");
	NotCheckedAttributeArray.Add("ManufacturedProduct.Characteristic");
	NotCheckedAttributeArray.Add("ManufacturedProduct.Warehouse");
	NotCheckedAttributeArray.Add("ManufacturedProduct.Department");
	NotCheckedAttributeArray.Add("ManufacturedProduct.Purpose");
	NotCheckedAttributeArray.Add("ManufacturedProduct.BillOfMaterials");
	NotCheckedAttributeArray.Add("ManufacturedProduct.DemandDate");
	NotCheckedAttributeArray.Add("ManufacturedProduct.CancellationReason");
	NotCheckedAttributeArray.Add("ManufacturedProduct.NumberOfPackages");
	NotCheckedAttributeArray.Add("ManufacturedProduct.Count");
	NotCheckedAttributeArray.Add("ManufacturedProduct.CostShare");

	TSHeader = ProductionClientServer.TitleOfTablePartByProcessType(ProductionProcessType);
	
	If Not ValueIsFilled(ManufacturedProduct) Then
		
		MessageText = StrTemplate(NStr("vi = 'Chưa điền phần bảng ""%1""';
										|ru = 'Не заполнена табличная часть ""%1""';
										|en = 'Table ""%1"" is not filled in'; fa = 'Table ""%1"" is not filled in';
										|it = 'Non è compilata la parte tabulare ""%1""';
										|pl = 'Nie wypełniono części tabelarycznej ""%1""';
										|tr = '""%1"" tablo bölümü doldurulmadı'"), TSHeader);
		Common.MessageToUser(MessageText, ThisObject, "ManufacturedProduct",, Cancel);
		
	Else
	
		ProductAttributes = New Map;
		
		Query = New Query(
			"SELECT DISTINCT
			|	CatalogProducts.Ref AS Products,
			|	CatalogProducts.ItemsType AS ItemsType,
			|	CatalogProducts.KeepRecordsByCCD AS KeepRecordsByCCD,
			|	CatalogProducts.TracedGoods AS TracedGoods,
			|	CASE
			|		WHEN CatalogProducts.UseVariants IN (
			|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
			|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
			|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS ItemVariantsAreUsed
			|
			|FROM
			|	Catalog.Products AS CatalogProducts
			|WHERE
			|	CatalogProducts.Ref IN (&ReferencesArrray)");
		Query.SetParameter("ReferencesArrray", TMCommonUse.UnloadColumnValues(ManufacturedProduct, "Products"));

		Selection = Query.Execute().Select();
		While Selection.Next() Do
			AttributesNames		= "ItemsType, ItemVariantsAreUsed, KeepRecordsByCCD, TracedGoods";
			AttributesValues	= New Structure(AttributesNames);
			
			FillPropertyValues(AttributesValues, Selection);
			ProductAttributes.Insert(Selection.Products, AttributesValues);
		EndDo;
		
		RestrictTransactionsWithImportedGoodsWithoutCCDNumbers =
			GetFunctionalOption("RestrictTransactionsWithImportedGoodsWithoutCCDNumbers");
		
		AddressTemplate = NStr("vi = 'trong dòng %1 của danh sách ""%2""';
								|ru = 'в строке %1 списка ""%2""';
								|en = 'in line %1 of the ""%2"" list'; fa = 'in line %1 of the ""%2"" list';
								|it = 'nella riga %1 dell''elenco ""%2""';
								|pl = 'w wierszu %1 listy ""%2""';
								|tr = '""%2"" listesinin %1 satırında'");
		CCDTemplate = NStr("vi = 'Trong dòng %1 danh sách ""%2"" đã chọn mặt hàng để tiến hành ghi nhận theo tờ khai hải quan.
			|Khi bật tùy chọn ""Cấm tạo giao dịch với các mặt hàng không có số TKHQ"", cấm chọn mặt hàng như vậy.';
			|ru = 'В строке %1 списка ""%2"" выбрана номенклатура, для которой ведется учет по ГТД.
			|При включенной опции ""Запретить операции с товарами без номеров ГТД"" выбор такой номенклатуры запрещен.';
			|en = 'Items with CCD records are selected in line %1 of the %2 list. 
			|You cannot select such products while the ""Prohibit operations with goods without CCD numbers"" option is enabled.'; fa = 'Items with CCD records are selected in line %1 of the %2 list. 
			|You cannot select such products while the ""Prohibit operations with goods without CCD numbers"" option is enabled.';
			|it = 'Items with CCD records are selected in line %1 of the %2 list. 
			|You cannot select such products while the ""Prohibit operations with goods without CCD numbers"" option is enabled.';
			|pl = 'Items with CCD records are selected in line %1 of the %2 list. 
			|You cannot select such products while the ""Prohibit operations with goods without CCD numbers"" option is enabled.';
			|tr = '""%2"" listesinin  %1  satırında Kargo Gümrük Beyannamesine göre muhasebesinin tutulduğu öğe seçildi.
			|""Kargo Gümrük Beyannamesi numaraları olmayan ürün işlemlerini yasakla"" seçeneği etkinleştirildiğinde, bu türdeki bir öğenin seçilmesi yasaktır.'");
		
		For Each String In ManufacturedProduct Do
			
			ErrorAddress = StrTemplate(AddressTemplate, String.LineNumber, TSHeader);
			
			AttributesOfCurrentItem = ProductAttributes[String.Products];
			
			// Checking the filling of the "Nomenclature" column
			If String.Products.IsEmpty() Then
				MessageText = NStr("vi = 'Chưa điền cột ""Mặt hàng""';
									|ru = 'Не заполнена колонка ""Номенклатура""';
									|en = 'Column ""Items"" is not filled in'; fa = 'Column ""Items"" is not filled in';
									|it = 'La colonna ""articolo"" non è compilata';
									|pl = 'Nie wypełniono kolumny ""Номенклатура""';
									|tr = '""Öğe"" sütunu doldurulmadı'");
				Field = CommonClientServer.PathToTabularSection("ManufacturedProduct", String.LineNumber, "Products");
				Common.MessageToUser(MessageText + " " + ErrorAddress,ThisObject,Field,,Cancel);
				Continue;
			EndIf;
			
			// Checking the correctness of the choice of products when accounting for GTE
			If Not String.Products.IsEmpty()
				And RestrictTransactionsWithImportedGoodsWithoutCCDNumbers
				And AttributesOfCurrentItem.KeepRecordsByCCD = True
				And Not AttributesOfCurrentItem.TracedGoods = True
				And (AttributesOfCurrentItem.ItemsType = Enums.ItemsTypes.OwnGoods
					Or AttributesOfCurrentItem.ItemsType = Enums.ItemsTypes.ReusablePackage) Then
				
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					CCDTemplate,
					String.LineNumber,
					TSHeader);
				Field = CommonClientServer.PathToTabularSection("ManufacturedProduct", String.LineNumber, "Products");
				Common.MessageToUser(MessageText,ThisObject, Field,,Cancel);
				
			EndIf;
			
			// Checking the filling of the "Characteristic" column
			If UseCharacteristics
				And AttributesOfCurrentItem.ItemVariantsAreUsed
				And String.Characteristic.IsEmpty() Then
				MessageText = NStr("vi = 'Chưa điền cột ""Đặc tính""';
									|ru = 'Не заполнена колонка ""Характеристика""';
									|en = 'Column ""Variant"" is not filled in'; fa = 'Column ""Variant"" is not filled in';
									|it = 'La colonna ""Caratteristica"" non è compilata';
									|pl = 'Nie wypełniono kolumny ""Характеристика""';
									|tr = '""Varyant"" sütunu doldurulmadı'");
				Field = CommonClientServer.PathToTabularSection("ManufacturedProduct", String.LineNumber, "Characteristic");
				Common.MessageToUser(MessageText + " " + ErrorAddress,ThisObject,Field,, Cancel);
			EndIf;
			
			// Checking the filling of the "Destination" column
			If (BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
					Or False)
				And Not DestinationIsIndicatedInHeaderOfDocument()
				And Not String.Canceled
				And Not AttributesOfCurrentItem.ItemsType = Enums.ItemsTypes.ReusablePackage
				And String.Purpose.IsEmpty() Then
				
				MessageText = NStr("vi = 'Chưa điền cột ""Mục đích""';
									|ru = 'Не заполнена колонка ""Назначение""';
									|en = 'Column ""Assignment"" is not filled in'; fa = 'Column ""Assignment"" is not filled in';
									|it = 'La colonna ""Destinazione"" non è compilata';
									|pl = 'Nie wypełniono kolumny ""Назначение""';
									|tr = '""Atama"" sütunu doldurulmadı'");
				Field = CommonClientServer.PathToTabularSection("ManufacturedProduct", String.LineNumber, "Purpose");
				Common.MessageToUser(MessageText + " " + ErrorAddress,ThisObject,Field,, Cancel);
				
			EndIf;
			
			// Checks depend on the type of item
			If AttributesOfCurrentItem.ItemsType = Enums.ItemsTypes.Work_5 Then
				
				If String.Department.IsEmpty() Then
					MessageText = NStr("vi = 'Chưa điền cột ""Bộ phận""';
										|ru = 'Не заполнена колонка ""Подразделение""';
										|en = 'Column ""Business unit"" is not filled in'; fa = 'Column ""Business unit"" is not filled in';
										|it = 'La colonna ""Reparto"" non è compilata';
										|pl = 'Nie wypełniono kolumny ""Dział""';
										|tr = '""Departman"" sütunu doldurulmadı'");
					Field = CommonClientServer.PathToTabularSection("ManufacturedProduct", String.LineNumber, "Department");
					Common.MessageToUser(MessageText + " " + ErrorAddress, ThisObject, Field,, Cancel);
				EndIf;
				
				If (ProductionProcessType = Enums.ProductionProcessTypes.Disassembly
					Or ProductionProcessType = Enums.ProductionProcessTypes.Repair) Then
					MessageText = NStr("vi = 'Không được phép chỉ ra công việc';
										|ru = 'Не допускается указание работы';
										|en = 'It is not allowed to specify work'; fa = 'It is not allowed to specify work';
										|it = 'Non è consentito specificare il lavoro';
										|pl = 'Nie dopuszcza się wskazanie pracy';
										|tr = 'İşin belirtilmesine izin verilmemektedir'");
					Field = CommonClientServer.PathToTabularSection("ManufacturedProduct", String.LineNumber, "Products");
					Common.MessageToUser(MessageText + " " + ErrorAddress,ThisObject,Field,,Cancel);
				EndIf;
				
			Else
				
				If String.ToExpenseAs Then
					
					If String.Department.IsEmpty() Then
						MessageText = NStr("vi = 'Chưa điền cột ""Bộ phận""';
											|ru = 'Не заполнена колонка ""Подразделение""';
											|en = 'Column ""Business unit"" is not filled in'; fa = 'Column ""Business unit"" is not filled in';
											|it = 'La colonna ""Reparto"" non è compilata';
											|pl = 'Nie wypełniono kolumny ""Dział""';
											|tr = '""Departman"" sütunu doldurulmadı'");
						Field = CommonClientServer.PathToTabularSection("ManufacturedProduct", String.LineNumber, "Department");
						Common.MessageToUser(MessageText + " " + ErrorAddress,ThisObject,Field,, Cancel);
					EndIf;
				Else
					
					If String.Warehouse.IsEmpty() Then
						MessageText = NStr("vi = 'Chưa điền cột ""Kho bãi""';
											|ru = 'Не заполнена колонка ""Склад""';
											|en = 'Column ""Warehouse"" is not filled in'; fa = 'Column ""Warehouse"" is not filled in';
											|it = 'La colonna ""Magazzino"" non è compilata';
											|pl = 'Nie wypełniono kolumny ""Magazyn""';
											|tr = '""Ambar"" sütunu doldurulmadı'");
						Field = CommonClientServer.PathToTabularSection("ManufacturedProduct", String.LineNumber, "Warehouse");
						Common.MessageToUser(MessageText + " " + ErrorAddress,ThisObject,Field,, Cancel);
					EndIf;
					
				EndIf;
				
				// Additional verification of compliance of the item type with the type of production process
				If ProductionProcessType = Enums.ProductionProcessTypes.PerformRM Then
					MessageText = NStr("vi = 'Không cho phép chỉ định hàng hóa';
										|ru = 'Не допускается указание товаров';
										|en = 'Cannot specify the goods'; fa = 'Cannot specify the goods';
										|it = 'Cannot specify the goods';
										|pl = 'Cannot specify the goods';
										|tr = 'Ürünün belirtilmesine izin verilmemektedir'");
					Field = CommonClientServer.PathToTabularSection("ManufacturedProduct", String.LineNumber, "Products");
					Common.MessageToUser(MessageText + " " + ErrorAddress,ThisObject,Field,,Cancel);
				EndIf;
			
			EndIf;
			
			// Checking the filling of the "Quantity" column
			If String.Count = 0 And Not String.Canceled Then
				MessageText = NStr("vi = 'Chưa điền cột ""Số lượng""';
									|ru = 'Не заполнена колонка ""Количество""';
									|en = 'Column ""Quantity"" is not filled in'; fa = 'Column ""Quantity"" is not filled in';
									|it = 'La colonna ""Quantità"" non è compilata';
									|pl = 'Nie wypełniono kolumny ""Количество""';
									|tr = '""Miktar"" sütunu doldurulmadı'");
				Field = CommonClientServer.PathToTabularSection("ManufacturedProduct", String.LineNumber, "Count");
				Common.MessageToUser(MessageText + " " + ErrorAddress, ThisObject, Field,, Cancel);
			EndIf;
				
			// The reason for cancellation is mandatory in the lines without the Canceled attribute
			If String.Canceled And Not ValueIsFilled(String.CancellationReason) Then
				MessageText = NStr("vi = 'Cần chỉ ra nguyên nhân hủy bỏ';
									|ru = 'Необходимо указать причину отмены';
									|en = 'Cancellation reason is required'; fa = 'Cancellation reason is required';
									|it = 'È necessario specificare il motivo di annullamento';
									|pl = 'Należy wskazać przyczynę anulowania';
									|tr = 'İptal nedeni belirtilmelidir'");
				Field = CommonClientServer.PathToTabularSection("ManufacturedProduct", String.LineNumber, "CancellationReason");
				Common.MessageToUser(MessageText + " " + ErrorAddress, ThisObject, Field,, Cancel);
			EndIf;
			
			// Checking the filling of the "Specification" column
			If DynamicStructure And String.BillOfMaterials.IsEmpty()
				And Not Status = Enums.ProductionOrderStatuses2_2.BeingGenerated
				And Not String.Canceled Then
				MessageText = NStr("vi = 'Chưa điền cột ""Bảng chi tiết nguyên vật liệu""';
									|ru = 'Не заполнена колонка ""Спецификация""';
									|en = 'Column ""BOM"" is not filled in'; fa = 'Column ""BOM"" is not filled in';
									|it = 'La colonna ""Specifica"" non è compilata';
									|pl = 'Nie wypełniono kolumny ""Спецификация""';
									|tr = '""Ürün Reçetesi"" sütunu doldurulmadı'");
				Field = CommonClientServer.PathToTabularSection("ManufacturedProduct", String.LineNumber, "BillOfMaterials");
				Common.MessageToUser(MessageText + " " + ErrorAddress, ThisObject, Field,, Cancel);
			EndIf;

			// Checking the filling of the column "Date of need"
			If DemandDateIsSpecifiedInLines And DemandDateRequired_ And Not ValueIsFilled(String.DemandDate) Then
				MessageText = NStr("vi = 'Chưa điền cột ""Ngày mong muốn""';
									|ru = 'Не заполнена колонка ""Желаемая дата""';
									|en = 'The ""Requested date"" column is not filled'; fa = 'The ""Requested date"" column is not filled';
									|it = 'Не заполнена колонка ""Желаемая дата""';
									|pl = 'The ""Requested date"" column is not filled';
									|tr = '""İstenen tarih"" sütunu doldurulmadı'");
				Field = CommonClientServer.PathToTabularSection("ManufacturedProduct", String.LineNumber, "DemandDate");
				Common.MessageToUser(MessageText + " " + ErrorAddress, ThisObject, Field,, Cancel);
			EndIf;
			
			// Checking the compliance of the "Start no earlier" and "Need date" dates
			If DemandDateIsSpecifiedInLines And EarliestStartDate > String.DemandDate And ValueIsFilled(EarliestStartDate) And ValueIsFilled(String.DemandDate) Then
				MessageText = NStr("vi = 'Ngày dự kiến xuất xưởng nhỏ hơn ngày bắt đầu sản xuất';
									|ru = 'Желаемая дата выпуска меньше даты начала производства';
									|en = 'The required release date is earlier than the production start date'; fa = 'The required release date is earlier than the production start date';
									|it = 'Желаемая дата выпуска меньше даты начала производства';
									|pl = 'Pożądana data produkcji jest mniejsza niż data rozpoczęcia produkcji';
									|tr = 'Talep edilen bitiş tarihi, üretim başlangıç ​​tarihinden daha eskidir'");
				Field = CommonClientServer.PathToTabularSection("ManufacturedProduct", String.LineNumber, "DemandDate");
				Common.MessageToUser(MessageText + " " + ErrorAddress, ThisObject, Field,, Cancel);
			EndIf;
			
			// Checking the filling in of the "Cost share" column
			If ProductionProcessType = Enums.ProductionProcessTypes.WithoutBillsOfMaterials
				And ProductionServer.ItIsRequiredToFillInFractionOfCost(ThisObject, String) Then
				
				MessageText = NStr("vi = 'Chưa điền cột ""Tỷ lệ giá trị""';
									|ru = 'Не заполнена колонка ""Доля стоимости""';
									|en = 'Column ""Cost share"" is not filled in'; fa = 'Column ""Cost share"" is not filled in';
									|it = 'La colonna ""Parte del costo"" non è compilata';
									|pl = 'Nie wypełniono kolumny ""Доля стоимости""';
									|tr = '""Maliyet Payı"" sütunu doldurulmadı'");
				Field = CommonClientServer.PathToTabularSection("ManufacturedProduct", String.LineNumber, "CostShare");
				Common.MessageToUser(MessageText + " " + ErrorAddress, ThisObject, Field,, Cancel);
				
			EndIf;
			
		EndDo;
		
		If BusinessOperation = Enums.BusinessTransactions.OwnProduction
				And (GetFunctionalOption("UseTollManufacturing2_5")
					Or False) Then
			CheckTollingAppointmentsOfVHFManufacturedProducts(Cancel); // we need to check the indication of giving assignments.
		EndIf;
		
		If ProductionProcessType = Enums.ProductionProcessTypes.Disassembly
			And DynamicStructure Then
			
			// checking bill of Materials, additional restrictions
			Query = New Query(
			"SELECT
			|	ManufacturedProduct.LineNumber AS LineNumber,
			|	CAST(ManufacturedProduct.BillOfMaterials AS Catalog.BillsOfMaterials) AS BillOfMaterials
			|INTO ManufacturedProduct
			|FROM
			|	&ManufacturedProducts_BillOfMaterials AS ManufacturedProduct
			|WHERE
			|	NOT ManufacturedProduct.BillOfMaterials = VALUE(Catalog.BillsOfMaterials.EmptyRef)
			|;
			|SELECT
			|	ManufacturedProduct.LineNumber AS LineNumber
			|FROM
			|	ManufacturedProduct AS ManufacturedProduct
			|WHERE
			|	1 NOT IN
			|			(SELECT
			|				COUNT(*)
			|			FROM
			|				Catalog.ProductionStages AS Stages
			|			WHERE
			|				Stages.Owner = ManufacturedProduct.BillOfMaterials
			|				AND NOT Stages.DeletionMark)");
			
			Query.SetParameter("ManufacturedProducts_BillOfMaterials", ManufacturedProduct.Unload(, "LineNumber, BillOfMaterials"));
			QueryResult = Query.Execute();
			
			If Not QueryResult.IsEmpty() Then
				
				MessageTextTemplate = NStr("vi = 'Không hỗ trợ bảng kê chi tiết phân rã theo nhiều công đoạn (xem dòng %1 của danh sách %2)';
											|ru = 'Не поддерживаются многоэтапные разборочные спецификации (см. строка %1 списка %2)';
											|en = 'Multi-stage disassembly BOMs are not supported (see line %1 of the %2 list)'; fa = 'Multi-stage disassembly BOMs are not supported (see line %1 of the %2 list)';
											|it = 'Multi-stage disassembly BOMs are not supported (see line %1 of the %2 list)';
											|pl = 'Multi-stage disassembly BOMs are not supported (see line %1 of the %2 list)';
											|tr = 'Çok aşamalı demontaj özellikleri desteklenmiyor (%2. listenin %1. satırına bakınız)'");
				Selection = QueryResult.Select();
				
				While Selection.Next() Do
					MessageText = StrTemplate(MessageTextTemplate, Selection.LineNumber, TSHeader);
					Field = CommonClientServer.PathToTabularSection("ManufacturedProduct", Selection.LineNumber, "BillOfMaterials");
					Common.MessageToUser(MessageText, ThisObject, Field,, Cancel);
				EndDo;
				
			EndIf;
			
		EndIf;
		
		ItemsAndDimensionsSelectionParameters = Documents.ProductionOrder2_2.ItemsAndDimensionsSelectionParameters(ThisObject);
		IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
		
		CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
		CheckParameters.TSName = "ManufacturedProduct";
		ProductsServer.CheckQuantityRounding(ThisObject, Cancel, CheckParameters);
		
		CheckCorrectnessOfIndicationOfExcisableItems(Cancel);
	EndIf;

#EndRegion	
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	ProductionOrder2_2Localization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If IsNew() Then
		RefToNew = GetNewObjectRef();
		If RefToNew.IsEmpty() Then
			RefToNew = Documents.ProductionOrder2_2.GetRef();
			SetNewObjectRef(RefToNew);
		EndIf;
		UUID = RefToNew.UUID();
	ElsIf Not ValueIsFilled(UUID) Then
		UUID = Ref.UUID();
	EndIf;
	If IsBlankString(UUIDLine) Then
		UUIDLine = String(UUID);
	EndIf;
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode); 
	
	AdditionalProperties.Insert("DocumentDataBeforeWrite",
		Common.ObjectAttributesValues(Ref, "Priority,Department,Queue" + ",EarliestStartDate,DemandDate,ProductionScheduling"));
	
	OrderStructureDocumentPosting.ProductionOrderBeforeWrite(ThisObject, AdditionalProperties, Cancel);
	
	SetNewQueueNumber();
	
	If ProductionProcessType = Enums.ProductionProcessTypes.WithoutBillsOfMaterials And Not ValueIsFilled(ProductionLot) Then
		ProductionLot = Catalogs.ProductionLots.GetRef();
	EndIf;
	
	#Region Assignments
	
	CurSeparationOption = OptionOfAssignment;
	
	If OptionOfAssignment.IsEmpty() Then
		OptionOfAssignment = ProductionManagement.OptionOfMaterialAssignmentInProduction(
			BusinessOperation,
			DynamicStructure);
	EndIf;
	
	If ProductionProcessType = Enums.ProductionProcessTypes.WithoutBillsOfMaterials
		And OptionOfAssignment = Enums.OptionsOfMaterialAssignmentInProduction.ProductionStage Then
		OptionOfAssignment = Enums.OptionsOfMaterialAssignmentInProduction.ProductionOrder;
	ElsIf ProductionProcessType = Enums.ProductionProcessTypes.Disassembly
		And DynamicStructure
		And OptionOfAssignment <> Enums.OptionsOfMaterialAssignmentInProduction.AssignmentOfProducts Then
		OptionOfAssignment = Enums.OptionsOfMaterialAssignmentInProduction.AssignmentOfProducts;
	EndIf;
	
	If DynamicStructure
		And OptionOfAssignment = Enums.OptionsOfMaterialAssignmentInProduction.AssignmentOfProducts Then
		If Not ConsolidatedOrderByProductAssignments
			And CommonClientServer.CollapseArray(ManufacturedProduct.UnloadColumn("Purpose")).Count() > 1 Then
			ConsolidatedOrderByProductAssignments = True;
		EndIf;
	Else
		ConsolidatedOrderByProductAssignments = False;
	EndIf;
	
	If CurSeparationOption <> OptionOfAssignment Then
		Purpose = Undefined;
	EndIf;
	
	DestinationPattern = Documents.ProductionOrder2_2.DestinationPattern(ThisObject);
	EmptyTemplate = OptionOfAssignment = Enums.OptionsOfMaterialAssignmentInProduction.ProductionStage;
	DestinationDegeneration = Catalogs.Assignments.CheckFillBeforeRecording(Purpose, DestinationPattern,
		ThisObject, "LineOfBusiness,Partner,Contract,BusinessOperation", Cancel, False, EmptyTemplate);
	
	If DestinationDegeneration Then
		DisabledAssignmentByProductionStageForIntermediateProducts = False;
	EndIf;
	
	#EndRegion
	
	RoundingParameters = ProductsServer.ParametersForRoundingNumberOfUnitProducts();
	RoundingParameters.TSName = "ManufacturedProduct";
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode, RoundingParameters);
	
	ItemsAndDimensionsSelectionParameters = Documents.ProductionOrder2_2.ItemsAndDimensionsSelectionParameters(ThisObject);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	If DemandDateIsSpecifiedInLines Then
		NewNeedDate = Date(1,1,1);
		
		If ManufacturedProduct.Count() > 0 Then
			
			FoundRows = ManufacturedProduct.FindRows(New Structure("Canceled", False));
			If FoundRows.Count() > 0 Then
				RowsSet = ManufacturedProduct.Unload(FoundRows, "DemandDate");
				RowsSet.Sort("DemandDate Asc");
				NewNeedDate = RowsSet[0].DemandDate;
			EndIf;
			
		EndIf;
		
		DemandDate = NewNeedDate;
	Else
		ProductionServer.FillInDetailsInCollection(ManufacturedProduct, "DemandDate", DemandDate);
	EndIf;
	
	#Region Clearing_Outdated_Data
	
	If ProductionProcessType <> Enums.ProductionProcessTypes.PerformRM Then
		UnderRepairProduct        = Undefined;
		UnderRepairVariant      = Undefined;
		UnderRepairBatch               = Undefined;
		UnderRepairBatchSpecificationStatus = Undefined;
	EndIf;
	
	For Each TSRow In ManufacturedProduct Do
		If TSRow.ToExpenseAs Then
			TSRow.Purpose = Undefined;
		EndIf;
	EndDo;

	#EndRegion
	
	AdditionalProperties.Insert("DeletionMarkBeforeRecording",
		?(IsNew(), False,
			Common.ObjectAttributeValue(Ref, "DeletionMark")));
	
	If IsNew() Then
		If Not ValueIsFilled(Author) Then
			Author = Users.AuthorizedUser();
		EndIf;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	#Region FillingAppointments
	
	DestinationPattern = Documents.ProductionOrder2_2.DestinationPattern(ThisObject);
	Catalogs.Assignments.OnWriteDocument(Purpose, DestinationPattern, ThisObject, Department, OrderForActivity);
	
	#EndRegion
	
	#Region FillingProductionBatch
	
	If ValueIsFilled(ProductionLot) Then
		
		BatchFields = Documents.ProductionOrder2_2.BatchFields(ThisObject);
		BatchFields.DeletionMark = DeletionMark;
		If Not ProductionProcessType = Enums.ProductionProcessTypes.WithoutBillsOfMaterials Then
			BatchFields.DeletionMark = True;
		EndIf;
		
		Catalogs.ProductionLots.CreateUpdateProductionBatch(
			ProductionLot,
			BatchFields,
			ProductionBatchUpdateAvailable());
		
		If Not ProductionProcessType = Enums.ProductionProcessTypes.WithoutBillsOfMaterials Then
			ProductionLot = Catalogs.ProductionLots.EmptyRef();
		EndIf;
		
	EndIf;
	
	#EndRegion
	
	OrderStructureDocumentPosting.ProductionOrderForRecording(ThisObject, AdditionalProperties, Cancel);
	
	OnChangingPriorityOfOrder();
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	MetadataAttributes = Metadata.Documents.ProductionOrder2_2.Attributes;
	
	UUIDLine = "";
	UUID = Undefined;
	DocumentBasis = Undefined;
	Purpose = Undefined;
	ContractIsNotRequired = False;
	ProductionLot = Undefined;
	OptionOfAssignment = Undefined;
	DisabledAssignmentByProductionStageForIntermediateProducts = False;
	SupplyOfAssignedMaterialsAndWorks = False;
	
	Status = MetadataAttributes.Status.FillValue;
	Queue = MetadataAttributes.Queue.FillValue;
	
	DynamicStructure =
		GetFunctionalOption("DynamicStructureOfProductionOrders");
		
	If DynamicStructure
		And (ProductionProcessType = Enums.ProductionProcessTypes.WithoutBillsOfMaterials
			Or ProductionProcessType = Enums.ProductionProcessTypes.Repair) Then
		ProductionProcessType = Enums.ProductionProcessTypes.Assembly;
		ManufacturedProduct.Clear();
	EndIf;
	
	If ValueIsFilled(EarliestStartDate) Then
		UsePlanningIntervalHour = Constants.UsePlanningIntervalHour.Get();
		EarliestStartDate = Max(
			EarliestStartDate,
			?(UsePlanningIntervalHour, BegOfHour(CurrentSessionDate()), BegOfDay(CurrentSessionDate())));
	EndIf;
	
	ProductionScheduling = ?(DynamicStructure,
							Enums.WayOfLinkingProductionOperations.ToFinish,
							Metadata.Documents.ProductionOrder2_2.Attributes.ProductionScheduling.FillValue);
	
	OrderStructureDocumentPosting.ClearRowKeysInTablePart(ThisObject, "ManufacturedProduct", "KeyProducts");
	
	FillParameters = Documents.ProductionOrder2_2.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(OrderForActivity, FillParameters);
	
	Author = Users.AuthorizedUser();
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	PerformOrderControlAfterConducting(Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region FillType


Procedure FillInByOrderOfGiver2_5(MaterialProviderOrder)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	MaterialProviderOrder2_5.Ref                             AS OrderDocument,
	|	MaterialProviderOrder2_5.Status                             AS DocumentStatus,
	|	MaterialProviderOrder2_5.Priority                          AS Priority,
	|	VALUE(Enum.BusinessTransactions.TollManufacturing2_5) AS BusinessOperation,
	|	MaterialProviderOrder2_5.ProductionProcessType       AS ProductionProcessType,
	|	MaterialProviderOrder2_5.UnderRepairProduct   AS UnderRepairProduct,
	|	MaterialProviderOrder2_5.UnderRepairVariant AS UnderRepairVariant,
	|	MaterialProviderOrder2_5.UnderRepairBatch          AS UnderRepairBatch,
	|	MaterialProviderOrder2_5.Organization                        AS Organization,
	|	MaterialProviderOrder2_5.VATTaxation                 AS OrderForActivity,
	|	MaterialProviderOrder2_5.Partner                            AS Partner,
	|	MaterialProviderOrder2_5.Contract                            AS Contract,
	|	CASE 
	|		WHEN MaterialProviderOrder2_5.LineOfBusiness.CostAccounting
	|			THEN MaterialProviderOrder2_5.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END                                               AS LineOfBusiness,
	|	MaterialProviderOrder2_5.Status NOT IN (
	|						VALUE(Enum.StatusesOfMaterialProviderOrders.ToProduce),
	|						VALUE(Enum.StatusesOfMaterialProviderOrders.ToShip),
	|						VALUE(Enum.StatusesOfMaterialProviderOrders.Closed)) AS ThereAreErrorsStatus,
	|	NOT MaterialProviderOrder2_5.Posted                        AS ThereAreErrorsPosted
	|FROM
	|	Document.MaterialProviderOrder2_5 AS MaterialProviderOrder2_5
	|WHERE
	|	MaterialProviderOrder2_5.Ref = &MaterialProviderOrder
	|;
	|";
	
	Query.SetParameter("MaterialProviderOrder", MaterialProviderOrder);
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	AcceptableStatuses = New Array;
	AcceptableStatuses.Add(Enums.StatusesOfMaterialProviderOrders.ToProduce);
	AcceptableStatuses.Add(Enums.StatusesOfMaterialProviderOrders.ToShip);
	AcceptableStatuses.Add(Enums.StatusesOfMaterialProviderOrders.Closed);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		MaterialProviderOrder,
		Attributes.DocumentStatus,
		Attributes.ThereAreErrorsPosted,
		Attributes.ThereAreErrorsStatus,
		AcceptableStatuses);
	
	// Filling in the header
	HeaderAttributes = "Priority,
					 |BusinessOperation,
					 |ProductionProcessType,
					 |UnderRepairProduct,
					 |UnderRepairVariant,
					 |UnderRepairBatch,
					 |Organization,
					 |OrderForActivity,
					 |LineOfBusiness,
					 |Partner,
					 |Contract";
	
	FillPropertyValues(ThisObject, Attributes, HeaderAttributes);
	
	DocumentBasis     = MaterialProviderOrder;
	
	FillInStatusOfIndicationOfBatchesOfFINISHEDProductBeingRepaired();
	
	AnArrayOfOrders = CommonClientServer.ValueInArray(MaterialProviderOrder);
	TableOfGoods = Documents.ProductionOrder2_2.ProductionResiduesToProvideGiver(AnArrayOfOrders, ProductionProcessType);
	FillInProductsTable(TableOfGoods);
	
EndProcedure

Procedure FillInDocumentBasedOnSupplyRequest(ApplicationForCollateral)
	
	ReceivingParameters = Documents.ApplicationForCollateral.ParametersForReceivingFillInDataBasedOn();
	ReceivingParameters.ItemsType = ProductsServer.SupportedDocumentItemTypes(Ref, "ManufacturedProduct");
	FillingData = Documents.ApplicationForCollateral.FillingDataBasedOn(
		ApplicationForCollateral,
		ReceivingParameters);
	
	// Filling in the header:
	HeaderProperties = New Structure;
	HeaderProperties.Insert("Organization");
	HeaderProperties.Insert("Warehouse");
	HeaderProperties.Insert("Department");
	HeaderProperties.Insert("LineOfBusiness");
	FillPropertyValues(HeaderProperties, FillingData.Header);
	FillPropertyValues(ThisObject, HeaderProperties,, "Department");
	
	DocumentBasis = ApplicationForCollateral;
	
	// Filling PM: 
	If FillingData.Goods.Columns.Find("Department") = Undefined Then
		// To write off expenses, fill in the division from the header:
		FillingData.Goods.Columns.Add(
			"Department",
			New TypeDescription("CatalogRef.BusinessStructure"));
		
		FillingData.Goods.FillValues(HeaderProperties.Department, "Department");
	EndIf;
	
	FillInProductsTable(FillingData.Goods);
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(HeaderProperties.Warehouse);
	WarehousesServer.FillInWarehousesInTablePart(HeaderProperties.Warehouse, WarehouseGroup_, ManufacturedProduct, False, "ToExpenseAs");
	
EndProcedure

Procedure FillInOnTheCustomerSOrder(FillingData)
	
	SalesOrder = FillingData.Basis;
	Query = New Query(
		"SELECT
		|	SalesOrder.Priority          AS Priority,
		|	SalesOrder.Organization        AS Organization,
		|	SalesOrder.VATTaxation AS VATTaxation,
		|	CASE 
		|		WHEN SalesOrder.LineOfBusiness.CostAccounting
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
	DocumentBasis       = SalesOrder;
	OrderForActivity    = Attributes.VATTaxation;
	Priority               = Attributes.Priority;
	LineOfBusiness = Attributes.LineOfBusiness;
	
	// Filling In The Table Part
	FillInGoodsFromStorageTable(FillingData.AddressGoods, "DateOfShipment");
	
EndProcedure

Procedure FillInByMovingOrder(FillingData)
	
	TransferOrder = FillingData.Basis;
	Query = New Query(
		"SELECT
		|	TransferOrder.Organization AS Organization,
		|	CASE
		|		WHEN TransferOrder.LineOfBusiness.CostAccounting
		|			THEN TransferOrder.LineOfBusiness
		|	END AS LineOfBusiness
		|FROM
		|	Document.TransferOrder AS TransferOrder
		|WHERE
		|	TransferOrder.Ref = &TransferOrder");
	
	Query.SetParameter("TransferOrder", TransferOrder);
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	// Filling in the header
	Organization             = Attributes.Organization;
	DocumentBasis       = TransferOrder;
	LineOfBusiness = Attributes.LineOfBusiness;
	
	// Filling In The Table Part
	FillInGoodsFromStorageTable(FillingData.AddressGoods, "DateOfShipment");

EndProcedure

Procedure FillInRefundRequestSoftware(FillingData)
	
	ReturnRequest = FillingData.Basis;
	Query = New Query(
		"SELECT
		|	SalesOrder.Organization AS Organization,
		|	SalesOrder.VATTaxation AS VATTaxation,
		|	CASE
		|		WHEN SalesOrder.LineOfBusiness.CostAccounting
		|			THEN SalesOrder.LineOfBusiness
		|	END AS LineOfBusiness
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS SalesOrder
		|WHERE
		|	SalesOrder.Ref = &ReturnRequest");
	
	Query.SetParameter("ReturnRequest", ReturnRequest);
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	// Filling in the header
	Organization				= Attributes.Organization;
	DocumentBasis		= ReturnRequest;
	OrderForActivity	= Attributes.VATTaxation;
	LineOfBusiness = Attributes.LineOfBusiness;
	
	// Filling In The Table Part
	FillInGoodsFromStorageTable(FillingData.AddressGoods, "DateOfShipment");
	
EndProcedure

Procedure FillOnOrderForDomesticConsumption(FillingData)
	
	InventoryConsumptionOrder = FillingData.Basis;
	Query = New Query(
		"SELECT
		|	OrderDocument.Organization AS Organization,
		|	CASE
		|		WHEN OrderDocument.LineOfBusiness.CostAccounting
		|			THEN OrderDocument.LineOfBusiness
		|	END AS LineOfBusiness
		|FROM
		|	Document.InventoryConsumptionOrder AS OrderDocument
		|WHERE
		|	OrderDocument.Ref = &OrderDocument");
	
	Query.SetParameter("OrderDocument", InventoryConsumptionOrder);
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	// Filling in the header
	Organization				= Attributes.Organization;
	DocumentBasis		= InventoryConsumptionOrder;
	LineOfBusiness = Attributes.LineOfBusiness;
	
	// Filling In The Table Part
	FillInGoodsFromStorageTable(FillingData.AddressGoods, "DateOfShipment");
	
EndProcedure

Procedure FillInOrderOfMaterialsInProduction(FillingData)
	
	OrderOfMaterialsForProduction = FillingData.Basis;
	Query = New Query(
		"SELECT
		|	OrderDocument.Organization AS Organization,
		|	CASE
		|		WHEN OrderDocument.LineOfBusiness.CostAccounting
		|			THEN OrderDocument.LineOfBusiness
		|	END AS LineOfBusiness
		|FROM
		|	Document.OrderOfMaterialsForProduction AS OrderDocument
		|WHERE
		|	OrderDocument.Ref = &OrderDocument");
	Query.SetParameter("OrderDocument", OrderOfMaterialsForProduction);
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	// Filling in the header
	Organization	      = Attributes.Organization;
	DocumentBasis = OrderOfMaterialsForProduction;
	
	// Filling In The Table Part
	FillInGoodsFromStorageTable(FillingData.AddressGoods, "DateOfShipment");
	
EndProcedure

Procedure FillInByRepairOrder(FillingData)
	
	RMOrder = FillingData.Basis;
	Query = New Query(
		"SELECT
		|	OrderDocument.Organization AS Organization,
		|	OrderDocument.StartDate AS DemandDate,
		|	CASE
		|		WHEN OrderDocument.LineOfBusiness.CostAccounting
		|			THEN OrderDocument.LineOfBusiness
		|	END AS LineOfBusiness
		|FROM
		|	Document.RMOrder AS OrderDocument
		|WHERE
		|	OrderDocument.Ref = &RMOrder");
	
	Query.SetParameter("RMOrder", RMOrder);
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	// Filling in the header
	Organization				= Attributes.Organization;
	DocumentBasis		= RMOrder;
	LineOfBusiness = Attributes.LineOfBusiness;
	DemandDate         = Attributes.DemandDate;
	
	// Filling In The Table Part
	FillInGoodsFromStorageTable(FillingData.AddressGoods);
	ProductionServer.FillInDetailsInCollection(ManufacturedProduct, "DemandDate", DemandDate);
	
EndProcedure

Procedure FillInByOrderForAssembly(FillingData)
	
	ByAssemblyDisassemblyOrder = FillingData.Basis;
	Query = New Query(
		"SELECT
		|	OrderDocument.Organization             AS Organization,
		|	OrderDocument.AssemblyDisassemblyStart    AS DemandDate,
		|	CASE
		|		WHEN OrderDocument.LineOfBusiness.CostAccounting
		|			THEN OrderDocument.LineOfBusiness
		|	END AS LineOfBusiness
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS OrderDocument
		|WHERE
		|	OrderDocument.Ref = &ByAssemblyDisassemblyOrder");
		
	Query.SetParameter("ByAssemblyDisassemblyOrder", ByAssemblyDisassemblyOrder);
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	// Filling in the header
	Organization				= Attributes.Organization;
	DocumentBasis		= ByAssemblyDisassemblyOrder;
	LineOfBusiness = Attributes.LineOfBusiness;
	DemandDate         = Attributes.DemandDate;
	
	// Filling In The Table Part
	FillInGoodsFromStorageTable(FillingData.AddressGoods);
	ProductionServer.FillInDetailsInCollection(ManufacturedProduct, "DemandDate", DemandDate);
	
EndProcedure

Procedure FillInByProductionStage2_2(FillingData)
	
	Stage = FillingData.Basis;
	
	Query = New Query(
		"SELECT
		|	ProductionStage2_2.Organization AS Organization,
		|	ProductionStage2_2.ProductionDate AS EarliestStartDate,
		|	ProductionStage2_2.ReferenceOrder.BusinessOperation AS BusinessOperation,
		|	ProductionStage2_2.ReferenceOrder.Department AS Department,
		|	ProductionStage2_2.ReferenceOrder.OrderForActivity AS OrderForActivity,
		|	ProductionStage2_2.ReferenceOrder.Partner AS Partner,
		|	ProductionStage2_2.ReferenceOrder.Contract AS Contract,
		|	CASE 
		|		WHEN ProductionStage2_2.LineOfBusiness.CostAccounting
		|			THEN ProductionStage2_2.LineOfBusiness
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END AS LineOfBusiness
		|FROM
		|	Document.ProductionStage2_2 AS ProductionStage2_2
		|WHERE
		|	ProductionStage2_2.Ref = &Stage
		|;
		|
		|SELECT
		|	ManufacturedProducts.*
		|FROM
		|	Document.ProductionStage2_2.ManufacturedProducts AS ManufacturedProducts
		|WHERE
		|	ManufacturedProducts.Ref = &Stage
		|	AND ManufacturedProducts.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
		|	AND NOT ManufacturedProducts.Canceled
		|");
	
	Query.SetParameter("Stage", Stage);
	
	QueryResults = Query.ExecuteBatch();
	QueryResultsQuantity = QueryResults.Count();;
	
	HeaderSelection = QueryResults[QueryResultsQuantity-2].Select();
	HeaderSelection.Next();
	
	DocumentBasis = Stage;
	FillPropertyValues(ThisObject, HeaderSelection);
	
	FillInStatusOfIndicationOfBatchesOfFINISHEDProductBeingRepaired();
	
	If ProductionProcessType = Enums.ProductionProcessTypes.Disassembly Then
		
		TableOfGoods = QueryResults[QueryResultsQuantity-1].Unload(); // ValueTable
		TableOfGoods.Columns.Recipient.Name = "Warehouse";
		
		FillInProductsTable(TableOfGoods);
		
		AssignmentsArray = TableOfGoods.UnloadColumn("Purpose");
		TMCommonUse.DeleteDuplicateElementsFromArray(AssignmentsArray);
		If AssignmentsArray.Count() = 1 Then
			AssignmentProducts = AssignmentsArray[0];
		EndIf;
		
	ElsIf ProductionProcessType = Enums.ProductionProcessTypes.PerformRM Then
		
		FillInGoodsFromStorageTable(FillingData.AddressGoods);
		
	EndIf;
	
EndProcedure

Procedure FillInGoodsFromStorageTable(AddressGoods, ColumnNameDateOfNeed = "")
	
	TableOfGoods = GetFromTempStorage(AddressGoods); // ValueTable
	DeleteFromTempStorage(AddressGoods);
	
	If ColumnNameDateOfNeed <> "" Then
		TableOfGoods.Columns[ColumnNameDateOfNeed].Name = "DemandDate";
	EndIf;
	
	FillInProductsTable(TableOfGoods);
	
EndProcedure

Procedure FillInProductsTable(TableOfGoods)
	
	If TableOfGoods.Count() = 0 Then
		Return;
	EndIf;
	
	ThereIsBOM = TableOfGoods.Columns.Find("BillOfMaterials") <> Undefined;
	
	ThereIsToStartNoEarlier = TableOfGoods.Columns.Find("EarliestStartDate") <> Undefined;
	If ThereIsToStartNoEarlier Then
		EarliestStartDate = TableOfGoods[0].EarliestStartDate;
	EndIf;

	SeveralNeedDatesAreAvailable = DynamicStructure;
	SeveralDemandDates = False;

	ThereIsDate = TableOfGoods.Columns.Find("DemandDate") <> Undefined;	
	If ThereIsDate Then
		DemandDate = TableOfGoods[0].DemandDate;
	EndIf;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;      
	
	If TableOfGoods.Columns.Find("NumberOfPackages") = Undefined Then
		StructureOfActions.Insert("RecalculateNumberOfPackages");
	EndIf;
	
	PropertiesExclusions = "";
	If ProductionProcessType = Enums.ProductionProcessTypes.Disassembly Then
		PropertiesExclusions = "Purpose";
	EndIf;
	
	RowsToProcess = New Array;
	For Each RowOfProduct In TableOfGoods Do
		
		LineProducts = ManufacturedProduct.Add();
		FillPropertyValues(LineProducts, RowOfProduct,, PropertiesExclusions);

		If ThereIsToStartNoEarlier Then
			EarliestStartDate = Min(EarliestStartDate, RowOfProduct.EarliestStartDate);
		EndIf;
		
		If ThereIsDate Then

			If DemandDate <> RowOfProduct.DemandDate And Not SeveralDemandDates Then
				SeveralDemandDates = True;
			EndIf;
			
			DemandDate = Min(DemandDate, RowOfProduct.DemandDate);
			
		EndIf;
		
		RowsToProcess.Add(LineProducts);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		ManufacturedProduct,
		CachedValues);
	
	If ValueIsFilled(DemandDate) Then
		ProductionScheduling = Enums.WayOfLinkingProductionOperations.ToFinish;
	EndIf;
	If SeveralDemandDates Then
		If Not SeveralNeedDatesAreAvailable Then 
			ProductionServer.FillInDetailsInCollection(ManufacturedProduct, "DemandDate", DemandDate);
		Else
			DemandDateIsSpecifiedInLines = True;
		EndIf;
	EndIf;
	
	FillInSpecificationDataInLines();
	
	// if a specification is sent along with the goods, you need to exclude possible conflicts 
	If ThereIsBOM And DynamicStructure Then 
		EliminateDuplicationOfSpecificationsInTabularPart(ManufacturedProduct);
	EndIf;
	
EndProcedure

Procedure FillInSpecificationDataInLines(OnlyEmpty = True)
	
	BOMSelectionParameters = ProductDataManagement.BOMSelectionParameters(ThisObject, Documents.ProductionOrder2_2);
	
	// Filling in specifications
	DataArray = New Array;
	RowsArray = New Array;
	
	For Each String In ManufacturedProduct Do
		
		If OnlyEmpty And Not String.BillOfMaterials.IsEmpty() Then
			Continue;
		EndIf;

		ProductData = ProductDataManagementClientServer.CollectProductDataForSpecificationSelection(
			ThisObject, String, BOMSelectionParameters);
		
		DataArray.Add(ProductData);
		RowsArray.Add(String);
		
	EndDo;
	
	// Fill in the specifications
	ProductDataManagement.FillInSpecificationInLines(RowsArray, DataArray, BOMSelectionParameters);
	
EndProcedure

Procedure EliminateDuplicationOfSpecificationsInTabularPart(TabularSection, AddedRows = Undefined) 
		
	Query = New Query();    
	Query.SetParameter("TS", TMCommonUse.ExportValuesTable(TabularSection,, "Products,Characteristic,Warehouse,Department,Purpose,BillOfMaterials"));
	Query.Text = 
		"SELECT
		|	TS.Products AS Products,
		|	TS.Characteristic AS Characteristic,
		|	TS.Warehouse AS Warehouse,
		|	TS.Department AS Department,
		|	TS.Purpose AS Purpose,
		|	TS.BillOfMaterials AS BillOfMaterials
		|INTO TS
		|FROM
		|	&TS AS TS
		|;
		|
		|SELECT
		|	TS.Products AS Products,
		|	TS.Characteristic AS Characteristic,
		|	TS.Warehouse AS Warehouse,
		|	TS.Department AS Department,
		|	TS.Purpose AS Purpose
		|FROM
		|	TS AS TS
		|
		|GROUP BY
		|	TS.Products,
		|	TS.Characteristic,
		|	TS.Warehouse,
		|	TS.Department,
		|	TS.Purpose
		|
		|HAVING
		|	COUNT(DISTINCT TS.BillOfMaterials) > 1";
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	FilterStructure1 = New Structure("Products,Characteristic,Warehouse,Department,Purpose");
	ProblematicLines = Query.Execute().Unload();
	ProblematicLines.Indexes.Add("Products,Characteristic,Warehouse,Department,Purpose");
	
	RowsToProcess = ?(AddedRows = Undefined, 
		TabularSection, AddedRows);
			
	For Each String In RowsToProcess Do
		FillPropertyValues(FilterStructure1, String);
		If ProblematicLines.FindRows(FilterStructure1).Count() > 0 Then 
			String.BillOfMaterials = Undefined;
		EndIf;
	EndDo;
		
EndProcedure

#EndRegion

#Region Queue

Procedure SetNewQueueNumber()
	
	If Status <> Enums.ProductionOrderStatuses2_2.ToProduce
		Or ValueIsFilled(Queue) Then
		
		If Status = Enums.ProductionOrderStatuses2_2.BeingGenerated Then
			Queue = 0;
		EndIf;
		
		Return;
	EndIf;
	
	If Not ValueIsFilled(Queue) Then
		Queue = Documents.ProductionOrder2_2.NewQueueNumber();
	EndIf;
	
EndProcedure

Procedure SetPriorityAndQueueNumberAccordingToPurposeOfNeed()
	
	If ManufacturedProduct.Count() = 0 Then
		Return;
	EndIf;
	
	ProductAssignments_ = TMCommonUse.UniqueValuesFromTableColumn(ManufacturedProduct, "Purpose");
	
	Query = New Query;
	Query.SetParameter("ProductAssignments_", ProductAssignments_);
	
	Query.Text =
		"SELECT DISTINCT
		|	Assignments.OrderDocument AS OrderDocument
		|INTO OrdersPendingSupply
		|FROM
		|	Catalog.Assignments AS Assignments
		|WHERE
		|	Assignments.Ref IN(&ProductAssignments_)
		|	AND Assignments.OrderDocument <> UNDEFINED
		|
		|INDEX BY
		|	OrderDocument
		|;
		|
		|SELECT TOP 1
		|	T.Priority AS Priority
		|FROM
		|	InformationRegister.DocumentsRegistry AS T
		|WHERE
		|	T.Ref IN
		|			(SELECT
		|				T.OrderDocument
		|			FROM
		|				OrdersPendingSupply AS T)
		|
		|ORDER BY
		|	T.Priority.AddlOrderingAttribute
		|;
		|
		|SELECT DISTINCT
		|	CASE
		|		WHEN VALUETYPE(OrdersPendingSupply.OrderDocument) = TYPE(Document.ProductionStage2_2)
		|			THEN CAST(OrdersPendingSupply.OrderDocument AS Document.ProductionStage2_2).ReferenceOrder
		|		ELSE OrdersPendingSupply.OrderDocument
		|	END AS OrderDocument
		|FROM
		|	OrdersPendingSupply AS OrdersPendingSupply
		|WHERE
		|	VALUETYPE(OrdersPendingSupply.OrderDocument) IN (TYPE(Document.ProductionOrder2_2), TYPE(Document.ProductionStage2_2))";
	
	SetPrivilegedMode(True);
	QueryResult = Query.ExecuteBatch();
	SetPrivilegedMode(False);

	If Not QueryResult[1].IsEmpty() Then
		
		Selection = QueryResult[1].Select();
		Selection.Next();
		
		Priority = Selection.Priority;
		
	EndIf;
	
	If Not QueryResult[2].IsEmpty() Then
		
		References = QueryResult[2].Unload().UnloadColumn(0);
		Queue = Documents.ProductionOrder2_2.QueueNumberToInsertBeforeDocuments(References);
		
	EndIf
	
EndProcedure

Procedure SetNewQueueNumberByDateOfNeed()
	
	If Not ValueIsFilled(DemandDate)
		Or Priority.IsEmpty()
		Or Department.IsEmpty() Then
		Return;
	EndIf;
	
	Query = New Query(
		"SELECT TOP 1
		|	Orders.Ref
		|FROM
		|	Document.ProductionOrder2_2 AS Orders
		|WHERE
		|	Orders.Priority = &Priority
		|	AND Orders.Department = &Department
		|	AND Orders.DemandDate > &DemandDate
		|	AND Orders.Posted
		|
		|ORDER BY
		|	Orders.Priority.AddlOrderingAttribute,
		|	Orders.Department.AddlOrderingAttribute,
		|	Orders.Queue");
	
	Query.SetParameter("Priority", Priority);
	Query.SetParameter("Department", Department);
	Query.SetParameter("DemandDate", DemandDate);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		References = CommonClientServer.ValueInArray(Selection.Ref);
		Queue = Documents.ProductionOrder2_2.QueueNumberToInsertBeforeDocuments(References);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ControlOfResultsOf

Procedure PerformOrderControlAfterConducting(Cancel)
	
	PerformOrderClosingControl(Cancel);
	
EndProcedure

Procedure PerformOrderClosingControl(Cancel)
	
	If Status <> Enums.ProductionOrderStatuses2_2.Closed Then
		Return;
	EndIf;
	
	ReferencesArrray = New Array;
	ReferencesArrray.Add(Ref);
	
	CheckParameters = New Structure("OrderFulfillmentControl");
	Query =
		Documents.ProductionOrder2_2.GenerateVerificationRequestWhenStatusChanges(
			ReferencesArrray,
			Status,
			CheckParameters);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Cancel = Cancel Or Not Documents.ProductionOrder2_2.CheckingBeforeChangingStatus(Selection, Status, CheckParameters);
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

Procedure CheckTollingAppointmentsOfVHFManufacturedProducts(Cancel) 
	
	Query = New Query();
	Query.SetParameter("ManufacturedProduct", ManufacturedProduct.Unload(New Structure("Canceled", False), "LineNumber,Purpose"));
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.Text =
		"SELECT
		|	ManufacturedProduct.LineNumber AS LineNumber,
		|	CAST(ManufacturedProduct.Purpose AS Catalog.Assignments) AS Purpose
		|INTO TableToCheck
		|FROM
		|	&ManufacturedProduct AS ManufacturedProduct
		|INDEX BY
		|	Purpose
		|;
		|
		|/////////////////////////////////////////
		|SELECT
		|	Table.LineNumber AS LineNumber,
		|	Table.ErrorInSpecifyingTollFreeDestination AS ErrorInSpecifyingTollFreeDestination
		|FROM(
		|	SELECT
		|		ManufacturedProduct.LineNumber AS LineNumber,
		|		ManufacturedProduct.Purpose AS Purpose,
		|		CASE
		|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OwnProduction)
		|					AND ManufacturedProduct.Purpose.AssignmentType IN(
		|						VALUE(Enum.AssignmentTypes.Giveaway2_5),
		|						VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22))
		|				THEN TRUE
		|			ELSE FALSE
		|		END AS ErrorInSpecifyingTollFreeDestination
		|	FROM
		|		TableToCheck AS ManufacturedProduct) AS Table
		|WHERE
		|	Table.ErrorInSpecifyingTollFreeDestination
		|ORDER BY
		|	LineNumber";
		
	ErrorsTable = Query.Execute().Unload();
	
	For IndexOf = 0 To ErrorsTable.Count() - 1 Do
		
		CurrentError = ErrorsTable[IndexOf];
		String = ManufacturedProduct[CurrentError.LineNumber - 1];
		
		If CurrentError.ErrorInSpecifyingTollFreeDestination Then
		
			MessageTemplate = NStr("vi = 'Cấm chọn mục đích của người đặt gia công khi sản xuất đặt riêng (dòng %1 của danh sách ""%2"").';
									|ru = 'Запрещено выбирать назначение давальца при собственном производстве (строка %1 списка ""%2"").';
									|en = 'Cannot select the provider assignment for in-house production (line %1 of the ""%2"" list).'; fa = 'Cannot select the provider assignment for in-house production (line %1 of the ""%2"" list).';
									|it = 'Non è possibile selezionare l''assegnazione del fornitore in caso di produzione propria (stringa %1 dell''elenco ""%2"").';
									|pl = 'Nie można wybierać przeznaczenia powierzonego w przypadku własnej produkcji (wiersz %1 listy ""%2"").';
									|tr = 'Şirket içi üretimde tedarikçi ataması seçmek yasaktır (""%2"" listesinin %1 satırı).'");
			MessageText = StrTemplate(MessageTemplate, String.LineNumber, NStr("vi = 'Sản phẩm';
																				|ru = 'Продукция';
																				|en = 'Manufactured product'; fa = 'محصول تولیدی';
																				|it = 'Продукция';
																				|pl = 'Manufactured product';
																				|tr = 'İmal edilen ürünler'"));
			DestinationField_ = CommonClientServer.PathToTabularSection("ManufacturedProduct", String.LineNumber, "Purpose");
			Common.MessageToUser(
				MessageText,
				ThisObject,
				DestinationField_,
				Undefined,
				Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function ProductionBatchUpdateAvailable()
	
	Query = New Query(
	"SELECT TOP 1
	|	ProductionStage22.Ref AS Ref
	|FROM
	|	Document.ProductionStage2_2 AS ProductionStage22
	|WHERE
	|	ProductionStage22.ProductionLot = &ProductionLot
	|	AND ProductionStage22.Posted");
	Query.SetParameter("ProductionLot", ProductionLot);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	Return Result.IsEmpty();
	
EndFunction

Function DestinationIsIndicatedInHeaderOfDocument()
	
	If ThisObject.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly Then
		Return True;
	EndIf;
	
	If ThisObject.ProductionProcessType = Enums.ProductionProcessTypes.WithoutBillsOfMaterials Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

Procedure OnChangingPriorityOfOrder()
	
	If AdditionalProperties.DocumentsPosting.DocumentProperties.IsNew Then
		Return;
	EndIf;
	
	If Not AdditionalProperties.DocumentsPosting.DocumentProperties.Posted
		Or AdditionalProperties.DocumentsPosting.DocumentProperties.WriteMode = DocumentWriteMode.UndoPosting Then
		Return;
	EndIf;
	
	If Not Status = Enums.ProductionOrderStatuses2_2.ToProduce Then
		Return;
	EndIf;

	PriorityChanged = Priority <> AdditionalProperties.DocumentDataBeforeWrite.Priority;
	
	If PriorityChanged Then
		UniversalQueueOfRealTimeJobs.ProcessTask_(Ref, Enums.UniversalQueueTasks.UpdatePriorityInProductionStages);
	EndIf;
	
	ChangedPlaceInQueue =
		Priority         <> AdditionalProperties.DocumentDataBeforeWrite.Priority
		Or Department <> AdditionalProperties.DocumentDataBeforeWrite.Department
		Or Queue       <> AdditionalProperties.DocumentDataBeforeWrite.Queue;
	
	If DynamicStructure And ChangedPlaceInQueue Then
		UniversalQueueOfRealTimeJobs.ProcessTask_(Ref, Enums.UniversalQueueTasks.UpdateOrderStructureWhenQueuePlaceIsChanged);
	EndIf;
	
EndProcedure

Procedure CheckCorrectnessOfIndicationOfExcisableItems(Cancel)
	
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods");
	
	If Not UseExcisableGoods Then
		Return;
	EndIf;
	
	QueryTexts = New Array;
	
	PartOfTheRequestText = 
	"SELECT
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	TableOfGoods.Products	AS Products,
	|	TableOfGoods.Purpose	AS Purpose,
	|	TableOfGoods.Warehouse		AS Warehouse
	|INTO TTManufacturedProduct
	|FROM
	|	&ManufacturedProduct AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	TableOfGoods.Products	AS Products,
	|	TableOfGoods.Warehouse		AS Warehouse
	|INTO TableOfGoods
	|FROM
	|	TTManufacturedProduct AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN Catalog.Assignments AS CatalogAssignments
	|		ON TableOfGoods.Purpose = CatalogAssignments.Ref
	|
	|WHERE
	|	CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|	AND NOT (ISNULL(CatalogAssignments.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|				VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|				VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|	)
	|";
	QueryTexts.Add(PartOfTheRequestText);
	QueryTexts.Add(ExcisableGoodsAccounting.QueryTextTTExciseCategoriesOfItems());
	
	PartOfTheRequestText = 
	"SELECT
	|	ErrorsTable.LineNumber				AS LineNumber,
	|	ErrorsTable.ExcisableItemIsSpecified	AS ExcisableItemIsSpecified,
	|	ErrorsTable.RetailWarehouseIsSpecified		AS RetailWarehouseIsSpecified
	|FROM
	|	(SELECT
	|		TableOfGoods.LineNumber	AS LineNumber,
	|		CASE
	|			WHEN NOT &ProductionOfExcisableItemsIsUsed
	|					AND ISNULL(Category_Data.ExcisableGoods, FALSE)
	|				THEN TRUE
	|			ELSE FALSE
	|		END						AS ExcisableItemIsSpecified,
	|		CASE
	|			WHEN &ProductionOfExcisableItemsIsUsed
	|					AND ISNULL(Category_Data.ExcisableGoods, FALSE)
	|					AND ISNULL(CatalogWarehouses.WarehouseStore, UNDEFINED) = VALUE(Enum.TypesOfWarehouses.RetailStore)
	|				THEN TRUE
	|			ELSE FALSE
	|		END						AS RetailWarehouseIsSpecified
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|			LEFT JOIN TTExciseCategoriesOfItems AS Category_Data
	|			ON TableOfGoods.Products = Category_Data.Products
	|			
	|			LEFT JOIN Catalog.Warehouses AS CatalogWarehouses
	|			ON TableOfGoods.Warehouse = CatalogWarehouses.Ref
	|	
	|	) AS ErrorsTable
	|
	|WHERE
	|	(ErrorsTable.ExcisableItemIsSpecified
	|		OR ErrorsTable.RetailWarehouseIsSpecified
	|	)
	|
	|ORDER BY
	|	LineNumber";
	QueryTexts.Add(PartOfTheRequestText);
	
	UnloadedColumns = "LineNumber, Products, Purpose, Warehouse";
	
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization);
	ProductionOfExcisableItemsIsUsed =
		ExcisableGoodsAccounting.ProductionOfExcisableItemsIsUsed(Organization, Date);
	
	Query = New Query;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("Date",			Date);
	Query.SetParameter("Organization",	Organization);
	Query.SetParameter("Country",			RegistrationCountry);
	Query.SetParameter("ManufacturedProduct",		ManufacturedProduct.Unload(, UnloadedColumns));
	Query.SetParameter("UseExcisableGoods", UseExcisableGoods);
	Query.SetParameter("ProductionOfExcisableItemsIsUsed", ProductionOfExcisableItemsIsUsed);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	TSHeader = ProductionClientServer.TitleOfTablePartByProcessType(ProductionProcessType);
	
	ExciseItemTemplate = NStr("vi = 'Trong dòng %1 danh sách ""%2"" có chỉ định sản phẩm chịu thuế TTĐB.
		|Cấm chọn mặt hàng này, vì chính sách kế toán tài chính của doanh nghiệp ""%Organization%"" không cho phép sản xuất sản phẩm chịu thuế TTĐB.';
		|ru = 'В строке %1 списка ""%2"" указана подакцизная продукция.
		|Выбор такой номенклатуры запрещен, так как учетная политика финансового учета организации ""%Organization%"" не предусматривает производство подакцизной продукции.';
		|en = 'Excisable products are specified in line %1 of the ""%2"" list.
		|Cannot select this item, as the financial accounting policy of the ""%Organization%"" company does not allow producing excisable products.'; fa = 'Excisable products are specified in line %1 of the ""%2"" list.
		|Cannot select this item, as the financial accounting policy of the ""%Organization%"" company does not allow producing excisable products.';
		|it = 'Excisable products are specified in line %1 of the ""%2"" list.
		|Cannot select this item, as the financial accounting policy of the ""%Organization%"" company does not allow producing excisable products.';
		|pl = 'Excisable products are specified in line %1 of the ""%2"" list.
		|Cannot select this item, as the financial accounting policy of the ""%Organization%"" company does not allow producing excisable products.';
		|tr = '""%2"" listesinin %1 satırında tüketim vergisine tabi imal edilen ürünler belirtildi.
		|""%Organization%"" iş yerinin mali muhasebe bölümünün muhasebe politikasında tüketim vergisine tabi ürünlerin üretimi öngörülmediğinden, bu tür bir öğenin seçilmesi yasaktır.'");
	ExciseItemTemplate = StrReplace(ExciseItemTemplate, "%Organization%", String(Organization));
	RetailWarehouseTemplate = NStr("vi = 'Trong dòng %1 danh sách ""%2"" có chỉ định kho bán lẻ là nơi nhận.
		|Cấm xuất xưởng sản phẩm chịu thuế TTĐB vào kho bán lẻ.';
		|ru = 'В строке %1 списка ""%2"" в качестве получателя указан розничный склад.
		|Выпуск подакцизной продукции на розничный склад запрещен.';
		|en = 'In line %1 of the ""%2"" list, the recipient is a retail warehouse.
		|Cannot release excisable goods to a retail warehouse.'; fa = 'In line %1 of the ""%2"" list, the recipient is a retail warehouse.
		|Cannot release excisable goods to a retail warehouse.';
		|it = 'In line %1 of the ""%2"" list, the recipient is a retail warehouse.
		|Cannot release excisable goods to a retail warehouse.';
		|pl = 'In line %1 of the ""%2"" list, the recipient is a retail warehouse.
		|Cannot release excisable goods to a retail warehouse.';
		|tr = '""%2"" listesinin %1 satırında alıcı olarak perakende ambarı belirtildi.
		|Tüketim vergisine tabi imal edilen ürünlerin perakende ambarına verilmesi yasaktır.'");
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		FieldName			= "";
		MessageText	= "";
		
		If Selection.ExcisableItemIsSpecified Then
			FieldName			= "Products";
			MessageText	= StrTemplate(ExciseItemTemplate, Selection.LineNumber, TSHeader);
		ElsIf Selection.RetailWarehouseIsSpecified Then
			FieldName			= "Warehouse";
			MessageText	= StrTemplate(RetailWarehouseTemplate, Selection.LineNumber, TSHeader);
		EndIf;
		
		If Not IsBlankString(MessageText) Then
			Field = CommonClientServer.PathToTabularSection("ManufacturedProduct", Selection.LineNumber, FieldName);
			
			Common.MessageToUser(MessageText, ThisObject , Field, "", Cancel);
		EndIf;
	EndDo;
	
EndProcedure

Procedure FillInStatusOfIndicationOfBatchesOfFINISHEDProductBeingRepaired()
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ProductionOrder2_2);
	DataStructureOfFinishedProductBeingRepaired = ProductionManagementClientServer.DataOfFinishedProductBeingRepairedByStructure(ThisObject);
	ProductsServer.FillInStatusesForSpecifyingSeries(DataStructureOfFinishedProductBeingRepaired, SeriesSpecificationParameters.FinishedProductBeingRepaired);
	UnderRepairBatch = DataStructureOfFinishedProductBeingRepaired.Series;
	UnderRepairBatchSpecificationStatus = DataStructureOfFinishedProductBeingRepaired.BatchesIndicationStatus;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
