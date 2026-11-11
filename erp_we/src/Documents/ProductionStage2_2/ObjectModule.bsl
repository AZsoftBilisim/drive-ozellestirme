#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region DocumentStatus

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
	
	StatusBeforeChange = Status;
	
	MeaningOfNewStatus = Enums.StatusesOfProductionStages2_2[NewStatus];
	
	Status = MeaningOfNewStatus;
	
	FillingData = ProductionManagement.FillInDataWhenStatusChanges(ThisObject);
	
	ProductionManagement.FillInStageDetailsWhenStatusChanges(
		ThisObject,
		StatusBeforeChange,
		FillingData);
		
	If AdditionalParameters <> Undefined Then // additional actions
		
		OrdersServer.AdjustOrderLines(ThisObject, AdditionalParameters);

		FillInSoftwareWhenSettingStatus(AdditionalParameters); 
		
		AssignArtistWhenSettingStatus(AdditionalParameters);
		
	EndIf;
	
	Return CheckFilling();
	
EndFunction

#EndRegion

#Region Other

// Sets the type of RC used among the main and alternative types of RC.
//
// Parameters:
//  ConnectionKey			 - UUID - link key of the RC type (table part of the work center view).
//  WorkCenterType	 - CatalogRef.WorkCenterTypes - the type of RC to assign as used.
//
Procedure ReplaceRCTypeUsed(ConnectionKey, WorkCenterType) Export
	
	FoundRow = WorkCenterTypes.Find(ConnectionKey, "ConnectionKey");
	If Not FoundRow = Undefined Then
		FoundRow.Use = (FoundRow.WorkCenterType = WorkCenterType);
	EndIf;
	
	TheStructureOfTheSearch = New Structure("LinkKeyWorkCenterTypes", ConnectionKey);
	FoundRows = AlternateWorkCenterTypes.FindRows(TheStructureOfTheSearch);
	For Each FoundRow In FoundRows Do
		FoundRow.Use = (FoundRow.WorkCenterType = WorkCenterType);
	EndDo;
	
EndProcedure

// Fills in a document based on the data of completed production operations.
//
// Parameters:
//  DataToFill	 - See Documents.ProductionOperation2_2.DataOfOperationsPerformed
//
Procedure FillInAccordingToOperations(DataToFill = Undefined) Export
	
	If DataToFill <> Undefined Then
		OperationData_ = DataToFill;
	Else
		OperationData_ = Documents.ProductionOperation2_2.DataOfOperationsPerformed(Ref);
	EndIf;
	
	PrepareOperationDataForFillingInData(OperationData_);
	
	TechProcessParameters = ProductionProcessEditorServerCall.ParametersOfTechnicalProcessOfStage(Ref);
	AccountingSettings = Documents.ProductionOperation2_2.AccountingSettings(Department, TechProcessParameters.TechnologicalProcess);
	
	If AccountingSettings.UseFinishedProducts Then
		
		FillOutArticlesOnOperations("ManufacturedProducts", OperationData_.ManufacturedProducts, OperationData_.BatchFinishedProducts);
		FillOutArticlesOnOperations("SideAndIntermediateRelease", OperationData_.ManufacturedProducts, OperationData_.BatchFinishedProducts);
		
		FillInProductionDateInHeader();
		
		If ProductionProcessType = Enums.ProductionProcessTypes.Assembly
				Or ProductionProcessType = Enums.ProductionProcessTypes.Repair Then
			FillInHeaderAfterFillingInOperations();
		EndIf;
		
		PackageBarcodes.Load(OperationData_.PackageBarcodes);
		
	EndIf;
	
	If AccountingSettings.UseMaterials Then
		
		FillInMaterialsOnOperations(OperationData_.MaterialsAndWorks);
		
		If ProductionProcessType = Enums.ProductionProcessTypes.Disassembly Then
			FillInHeaderAfterFillingInOperations();
		EndIf;
		
		PackagingUnitBarcodesMaterials.Load(OperationData_.PackagingUnitBarcodesMaterials);
		
	EndIf;
	
	If Documents.ProductionStage2_2.MarkOfPerformedLaborCostsIsUsed(ThisObject) Then
		
		FillInLaborCostsForOperations(OperationData_.LaborCosts);
		
	EndIf;
	
	If ProductionManagementClientServer.ComparisonOfStageStatuses(Enums.StatusesOfProductionStages2_2.Initiated, Status) > 0 Then
		
		SetStatus("Initiated", Undefined);
		
	EndIf;
	
	ItIsRequiredToPopulateByOperationsManually = False;
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in tabular parts
// 'Output products', 'Side products', 'Consumables of work', 'Provision of materials and works'
// and 'Economy of materials' of the document, and also fills in the tabular parts of 'Types of supplies' and 'Types of supplies'.
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.ProductionStage2_2.CollectionOfTabularPartsOfGoods.
//
Procedure FillOutTypesOfStockWhenExchanging(Cancel, DocumentTables) Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	
	If DocumentTables <> Undefined Then
		FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables);
		AdditionalProperties.Insert("TablesOfFillingOfTypesOfStocksAtExchange", DocumentTables);
	Else
		ParameterName = "DocumentTables";
		
		ExceptionText = NStr("vi = 'Để điền dạng vật tư, không chuyển tham số ""%1"".';
							|ru = 'Для заполнения видов запасов не передан параметр ""%1"".';
							|en = 'The ""%1"" parameter is not transferred to fill in the inventory owner attributes.'; fa = 'The ""%1"" parameter is not transferred to fill in the inventory owner attributes.';
							|it = 'Per la compilazione dei tipi di scorte non è indicato il parametro ""%1"".';
							|pl = 'Do wypełnienia rodzajów zapasów nie przekazano parametru ""%1"".';
							|tr = 'Stok sahibi özniteliklerinin doldurulması için ""%1"" parametresi belirtilmedi.'");
		ExceptionText = StrTemplate(ExceptionText, ParameterName);
		
		Raise ExceptionText;
	EndIf;
	
	FillStockTypes(Cancel);
	AdditionalProperties.Delete("TablesOfFillingOfTypesOfStocksAtExchange");
	
EndProcedure

// Allows you to change the Attributes associated with the division of the stage when changing the batch of production.
// The Attributes are stored in the registers of the details of the production stage and the technological process of the production stage
// Writing to the register occurs in a document recording transaction.
// 
// Parameters:
//  DivisionAttributes - See DataProcessors.ProductionLotDivision.DivisionAttributesConstructor
//
Procedure ChangeDivisionAttributes(DivisionAttributes) Export
	
	AdditionalProperties.Insert("DivisionAttributes", DivisionAttributes);
	
EndProcedure

// Allows you to change the Attributes associated with the process parameters
// The Attributes are stored in the register of technological processingproduction steps
// Writing to the register occurs in a document recording transaction.
//
// Parameters:
//  TechProcessParameters - See ProductionProcessEditorClientServer.ProcessParametersConstructor
//
Procedure ChangeTechProcessParameters(TechProcessParameters) Export
	
	AdditionalProperties.Insert("TechProcessParameters", TechProcessParameters);
	
EndProcedure

#EndRegion

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If IsNew() Then
		If BatchGenerationIsPerformed()
			And Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
			ModuleAccessManagement = Common.CommonModule("AccessManagement");
			ModuleAccessManagement.SetLockBeforeWriteToFileIB(True);
		EndIf;
		
		RefToNew = GetNewObjectRef();
		If RefToNew.IsEmpty() Then
			RefToNew = Documents.ProductionStage2_2.GetRef();
			SetNewObjectRef(RefToNew);
		EndIf;
		UUID = RefToNew.UUID();
	ElsIf Not ValueIsFilled(UUID) Then
		UUID = Ref.UUID();
	EndIf;
	
	OrderStructureDocumentPosting.ProductionStageBeforeWrite(ThisObject, AdditionalProperties, Cancel);
	
	SetKeyInRowsOfTableParts(Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	NamesOfTS = "ManufacturedProducts,SideAndIntermediateRelease,SupplyWithMaterialsAndWorks,MaterialsAndWorksConsumption,UnusedMaterials";
	TMCommonUse.FillInDocumentIDs(ThisObject, NamesOfTS);
	
	FillInServiceDetails();
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If BatchGenerationIsPerformed() Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	CheckProductionProcess(Cancel, WriteMode);
	
	If WriteMode = DocumentWriteMode.UndoPosting Then
		
		// It is not allowed to cancel the stage included in the order to the processor.
		If ProductionByThirdParty2_5
			And ValueIsFilled(SubcontractOrder)
			And Common.ObjectAttributeValue(SubcontractOrder, "Posted") Then
			
			ErrorText = NStr("vi = 'Đơn hàng đặt gia công đã thực hiện bao gồm công đoạn sản xuất. Không thể hủy bỏ kết chuyển.';
							|ru = 'Этап производства включен в проведенный заказ переработчика. Отмена проведения невозможна.';
							|en = 'The production stage is included in the posted subcontracting purchase order. You cannot unpost the order.'; fa = 'The production stage is included in the posted subcontracting purchase order. You cannot unpost the order.';
							|it = 'Этап производства включен в проведенный заказ переработчика. Отмена проведения невозможна.';
							|pl = 'The production stage is included in the posted subcontracting purchase order. You cannot unpost the order.';
							|tr = 'Üretim aşaması, fason satın alma siparişine dahil edilmiştir. Kaydetmenin iptali mümkün değildir.'");
			
			Common.MessageToUser(
				ErrorText,
				Ref,
				"SubcontractOrder",,
				Cancel);
			
		EndIf;
		
	EndIf;
	
	#Region Rounding
	
	RoundingParameters = Documents.ProductionStage2_2.TSParametersForRounding();
		
	ProductsServer.RoundUpNumberOfUnitItems(
			ThisObject, WriteMode, RoundingParameters["ManufacturedProducts"]);
			
	ProductsServer.RoundUpNumberOfUnitItems(
			ThisObject, WriteMode, RoundingParameters["SideAndIntermediateRelease"]);
			
	ProductsServer.RoundUpNumberOfUnitItems(
			ThisObject, WriteMode, RoundingParameters["SupplyWithMaterialsAndWorks"]);

	ProductsServer.RoundUpNumberOfUnitItems(
			ThisObject, WriteMode, RoundingParameters["UnusedMaterials"]);
			
	#EndRegion		
	
	#Region FillingAppointments

	If IsNew() And Not ValueIsFilled(Purpose) // The link to the assignment can be formed earlier (for example, for communication on the release of PF at the stage)
		Or Not IsNew() Then	
		
		OldPurpose = Purpose;
		
		DestinationPattern = Documents.ProductionStage2_2.DestinationPattern(ThisObject);
		UpdatedAssignment = Catalogs.Assignments.CheckFillBeforeRecording(
			Purpose,
			DestinationPattern,
			ThisObject,
			"LineOfBusiness,Partner,Contract,BusinessOperation",
			Cancel);
		If UpdatedAssignment Then
			TheStructureOfTheSearch = New Structure("SupplyAssignment", OldPurpose);
			For Each String In SupplyWithMaterialsAndWorks.FindRows(TheStructureOfTheSearch) Do
				String.SupplyAssignment = Purpose;
				If String.WithAssignment Then
					String.Purpose = Purpose;
				EndIf;
			EndDo;
		EndIf;
		
	EndIf;
	
	#EndRegion
	
	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.ProductionStage2_2.AccountingAccountSettings_());
	
	ItemsAndDimensionsSelectionParameters = Documents.ProductionStage2_2.ItemsAndDimensionsSelectionParameters(ThisObject);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ClearUnusedData();
	
	FillInCacheOfMainVRC();
	
	DataBeforeChange = Undefined;
	
	If WriteMode <> DocumentWriteMode.Write Then
		
		DataBeforeChange = DataBeforeChange();
		
		If WriteMode = DocumentWriteMode.Posting
			And Status <> Enums.StatusesOfProductionStages2_2.BeingGenerated Then
			FillInProductTrackingDataInTabularPartsOfProducts();
		EndIf;
		
		If WriteMode = DocumentWriteMode.Posting 
			And Status <> Enums.StatusesOfProductionStages2_2.BeingGenerated
			And Status <> Enums.StatusesOfProductionStages2_2.Generated1
			And Status <> Enums.StatusesOfProductionStages2_2.ForCompletion Then
			FillStockTypes(Cancel);
		Else
			InventoryOwnerAttributesProducts.Clear();
			InventoryOwnerAttributesMaterials.Clear();
		EndIf;
		
		#Region MotionRewritingPeriod
		
		// Let's check the need to create a task for cost recalculation, fill in the periods of changes in the table parts.
		TabularSectionsDetails = New Structure;
		
		#Region DescriptionConsumptionOfMaterialsAndWorks
		
		CheckParameters = New Structure;
		CheckParameters.Insert("Resources", "Count,NumberOfPackages");
		CheckParameters.Insert("Date", "DateOfMaterialWorkConsumption");
		
		TabularSectionsDetails.Insert("MaterialsAndWorksConsumption", CheckParameters);
		
		#EndRegion
		
		#Region DescriptionProvisionOfMaterialsAndWorks
		
		CheckParameters = New Structure;
		CheckParameters.Insert("Resources", "Count,NumberOfPackages");
		CheckParameters.Insert("Date", "DateOfShipment");
		
		RowFilter = New Map;
		
		TMCommonUse.AddSelectionItemToCollection(
			RowFilter,
			"T.SupplyOption",
			"VALUE(Enum.SupplyOptions.Ship)",
			"=");
		
		TMCommonUse.AddSelectionItemToCollection(
			RowFilter,
			"ISNULL(T.Warehouse.ShopFloorStockroom, T.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5))",
			"TRUE",
			"=");
		
		TMCommonUse.AddSelectionItemToCollection(
			RowFilter,
			"CASE WHEN T.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5) THEN T.Department ELSE T.Warehouse.Department END",
			"T.Department",
			"=");
		
		CheckParameters.Insert("Filter", RowFilter);
		
		TabularSectionsDetails.Insert("SupplyWithMaterialsAndWorks", CheckParameters);
		
		#EndRegion
		
		#Region DescriptionSavingMaterials
		
		CheckParameters = New Structure;
		CheckParameters.Insert("Resources", "Count,NumberOfPackages");
		CheckParameters.Insert("Date", "DateOfTransaction");
		
		TabularSectionsDetails.Insert("UnusedMaterials", CheckParameters);
		
		#EndRegion
		
		#Region DescriptionOfLaborCosts
		
		CheckParameters = New Structure;
		CheckParameters.Insert("Resources", "Count");
		CheckParameters.Insert("Date", "ExecutionDate");
		
		RowFilter = New Map;
		TMCommonUse.AddSelectionItemToCollection(
			RowFilter,
			"T.Completed2",
			"TRUE",
			"=");
		
		CheckParameters.Insert("Filter", RowFilter);
		
		TabularSectionsDetails.Insert("LaborCosts", CheckParameters);
		
		#EndRegion
		
		#Region OutputProductsDescription
		
		CheckParameters = New Structure;
		CheckParameters.Insert("Resources", "Count");
		CheckParameters.Insert("Date", "ProductionDate");
		
		RowFilter = New Map;
		TMCommonUse.AddSelectionItemToCollection(
			RowFilter,
			"T.Manufactured",
			"TRUE",
			"=");
		
		CheckParameters.Insert("Filter", RowFilter);
		
		TabularSectionsDetails.Insert("ManufacturedProducts", CheckParameters);
		
		#EndRegion
		
		#Region DescriptionOfByProducts
		
		CheckParameters = New Structure;
		CheckParameters.Insert("Resources", "Count");
		CheckParameters.Insert("Date", "ProductionDate");
		
		RowFilter = New Map;
		TMCommonUse.AddSelectionItemToCollection(
			RowFilter,
			"T.Manufactured",
			"TRUE",
			"=");
		
		CheckParameters.Insert("Filter", RowFilter);
		
		TabularSectionsDetails.Insert("SideAndIntermediateRelease", CheckParameters);
		
		#EndRegion
		
		#Region DescriptionTypesAndMaterials
		
		CheckParameters = New Structure;
		CheckParameters.Insert("Resources", "Count");
		CheckParameters.Insert("Date", "DateOfTransaction");
		
		TabularSectionsDetails.Insert("InventoryOwnerAttributesMaterials", CheckParameters);
		
		#EndRegion
		
		#Region DescriptionTypesOfProductStocks
		
		CheckParameters = New Structure;
		CheckParameters.Insert("Resources", "Count, CostShare, Sum");
		CheckParameters.Insert("Date", "DateOfTransaction");
		
		TabularSectionsDetails.Insert("InventoryOwnerAttributesProducts", CheckParameters);
		
		#EndRegion
		
		CheckResult = CostCalculationAppliedAlgorithms.PeriodsOfChangeTabularPartsOfDocument(ThisObject, TabularSectionsDetails);
		ProductionStage2_2Localization.FillinAdditionalProperties(ThisObject, CheckResult);
		
		If ValueIsFilled(CheckResult.TotalMinimumPeriod) Then
			PeriodOfRewritingRegisteredRecords = BegOfMonth(CheckResult.TotalMinimumPeriod);
		Else
			// If the document data has not changed after rechecking, then all movements should be saved.
			// The period of filling equal to the empty date corresponds to the mode of saving all movements.
			// The period of filling equal to INDEFINITE corresponds to the mode of overwriting all movements.
			// The filling period equal to the beginning of the month corresponds to the mode of saving movements in previous months and the formation
			// of new ones starting from the beginning of the month.
			If AdditionalProperties.Property("PeriodOfRewritingRegisteredRecords") Then
				PeriodOfRewritingRegisteredRecords = AdditionalProperties.PeriodOfRewritingRegisteredRecords;
			Else
				PeriodOfRewritingRegisteredRecords = Date(1,1,1);
			EndIf;
		EndIf;
		
		If Not CheckResult.TotalMinimumPeriod = Undefined Then
			
			CheckDate = Undefined;
			For Each KeyValue In CheckResult Do
				
				If (KeyValue.Key = "TotalMinimumPeriod"
						Or KeyValue.Key = "InventoryOwnerAttributesProducts"
						Or KeyValue.Key = "InventoryOwnerAttributesMaterials")
						And Not WriteMode = DocumentWriteMode.UndoPosting
					Or Not ValueIsFilled(KeyValue.Value) Then
					Continue;
				EndIf;
				
				If ValueIsFilled(CheckDate) Then
					CheckDate = Min(CheckDate, KeyValue.Value);
				Else
					CheckDate = KeyValue.Value;
				EndIf;
				
			EndDo;
			
			If ValueIsFilled(CheckDate) Then
				
				DataToCheck = PeriodClosingDates.DataToCheckTemplate();
				
				NewRow = DataToCheck.Add();
				NewRow.Date   = BegOfDay(CheckDate);
				NewRow.Section = "Production";
				NewRow.Object = Organization;
				
				DataDetails = New Structure;
				DataDetails.Insert("NewVersion", True);
				DataDetails.Insert("Data",      Ref);
				
				ErrorDescription = "";
				If PeriodClosingDates.PeriodEndClosingFound(DataToCheck, DataDetails, ErrorDescription) Then
					Cancel = True;
					Raise ErrorDescription;
				EndIf;
				
			EndIf;
			
		EndIf;
		
		If Not PeriodOfRewritingRegisteredRecords = Date(1,1,1) Then
			
			DataToCheck = PeriodClosingDates.DataToCheckTemplate();
			
			NewRow = DataToCheck.Add();
			If PeriodOfRewritingRegisteredRecords = Undefined Then
				NewRow.Date = Date(1,1,1);
			Else
				NewRow.Date = PeriodOfRewritingRegisteredRecords;
			EndIf;
			
			NewRow.Section = "RoutineOperations";
			NewRow.Object = Organization;
			
			DataDetails = New Structure;
			DataDetails.Insert("NewVersion", True);
			DataDetails.Insert("Data",      Ref);
			
			ErrorDescription = "";
			If PeriodClosingDates.PeriodEndClosingFound(DataToCheck, DataDetails, ErrorDescription) Then
				Cancel = True;
				Raise ErrorDescription;
			EndIf;
		
		EndIf;
		
		AdditionalProperties.Insert("PeriodOfRewritingRegisteredRecords", PeriodOfRewritingRegisteredRecords);
		
		#EndRegion
		
	EndIf;
	
	#Region UpdatingRelatedData
	
	AdditionalProperties.Insert("AssociatedDataUpdateHandlers", New Structure());
	
	If DocumentsPosting.DocumentProperties(ThisObject).WriteMode <> DocumentWriteMode.Write Then
			
			If DataBeforeChange = Undefined Then
				DataBeforeChange = DataBeforeChange();
			EndIf;
			
			RegisterStateUpdate(DataBeforeChange);
			RegisterOrderStateUpdate(DataBeforeChange);
			
			RegisterCalculationOfQueueOfProductionOperations(DataBeforeChange);
			RegisterScheduleCheckOfAdjacentStages(DataBeforeChange);
			
			RegisterUpdateOfPlacementParametersInChart(DataBeforeChange);
			RegisterUpdateOfParametersOfRegulatorySchedule(DataBeforeChange);
			RegisterUpdateOfDurationCalculationParametersBeforeRelease(DataBeforeChange);
			
			RegisterProductionScheduleCleanup();
			RegisterFeatureCleanupOnCriticalPath();
			
	EndIf;
	
	#EndRegion
	
	AdditionalProperties.Insert("DataBeforeChange", DataBeforeChange);
	
	ProductionStage2_2Localization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DestinationPattern = Documents.ProductionStage2_2.DestinationPattern(ThisObject);
	Catalogs.Assignments.OnWriteDocument(Purpose, DestinationPattern, ThisObject, Department, ProductionIssueForActivity);

	OrderStructureDocumentPosting.StageOfProductionDuringRecording(ThisObject, AdditionalProperties, Cancel);
	
	If AdditionalProperties.Property("DivisionAttributes") Then
		DataProcessors.ProductionLotDivision.ChangeStageDivisionAttributes(Ref, AdditionalProperties.DivisionAttributes);
	EndIf;
	
	If AdditionalProperties.Property("TechProcessParameters") Then
		InformationRegisters.TechnologicalProcessesOfProductionStages.RecordProcessParameters(Ref, AdditionalProperties.TechProcessParameters);
	EndIf;
	
	If BatchGenerationIsPerformed() Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	If DocumentsPosting.DocumentProperties(ThisObject).WriteMode = DocumentWriteMode.UndoPosting Then
		UpdateRelatedData(Cancel, True);
	EndIf;
	
	If ValueIsFilled(ProductionLot) Then
		
		Block = New DataLock;
		
		LockItem = Block.Add("Catalog.ProductionLots");
		LockItem.SetValue("Code", StartingLotNumber);
		LockItem.SetValue("Document", ReferenceOrder);
		LockItem.Mode = DataLockMode.Exclusive;
		
		Try
			
			Block.Lock();
			
			PerformDataControlOfChainOfStages(Cancel);
			
			BatchFields =
				Documents.ProductionStage2_2.BatchFields(
					ThisObject,
					Documents.ProductionStage2_2.MainProductOfChainOfStages(Ref),
					False);
			
			Catalogs.ProductionLots.CreateUpdateProductionBatch(ProductionLot, BatchFields);
			
		Except
			Event = NStr("vi = 'Công đoạn sản xuất';
						|ru = 'Этап производства';
						|en = 'Production stage'; fa = 'مرحله تولید';
						|it = 'Fase di produzione';
						|pl = 'Etap produkcji';
						|tr = 'Üretim aşaması'", Common.DefaultLanguageCode()) + "."
				+ NStr("vi = 'Thay đổi lô sản xuất';
						|ru = 'Изменение партии производства';
						|en = 'Change production lot'; fa = 'تغییر لات تولید';
						|it = 'Change production lot';
						|pl = 'Change production lot';
						|tr = 'Üretim lotunu düzenleme'", Common.DefaultLanguageCode());
			WriteLogEvent(Event,
				EventLogLevel.Error,
				Metadata(),
				Ref,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			MessageText = NStr("vi = 'Không thể chặn công đoạn của lô hàng.';
								|ru = 'Не удалось заблокировать этапы партии.';
								|en = 'Cannot lock the lot stages.'; fa = 'Cannot lock the lot stages.';
								|it = 'Cannot lock the lot stages.';
								|pl = 'Cannot lock the lot stages.';
								|tr = 'Lot aşamaları engellenemedi.'");
			Common.MessageToUser(MessageText, Ref,,, Cancel);
			Return;
		EndTry;
		
	EndIf;
	
	If HandlerMustBeExecuted("RecordManualPlacementOfStageInGraph") Then
		KeyLot = ?(DynamicStructure,
			ProductionLot.UUID(),
			New UUID("00000000-0000-0000-0000-000000000000"));
		Dimensions = New Structure;
		Dimensions.Insert("ProductionOrder", ReferenceOrder);
		Dimensions.Insert("Stage", Ref);
		Dimensions.Insert("KeyLot", KeyLot);
		
		If QuantityPerReleaseLotUnit <> 0 Then
			ZoomRatio = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(PackagePlan, Undefined);
			QuantityOfBatches = NumberOfPackagesPlan * ZoomRatio / QuantityPerReleaseLotUnit;
		Else
			QuantityOfBatches = 0;
		EndIf;
		Attributes = New Structure;
		Attributes.Insert("Department", Department);
		Attributes.Insert("BillOfMaterials", BillOfMaterials);
		Attributes.Insert("QuantityOfBatches", QuantityOfBatches);
		
		InformationRegisters.ScheduleOfProductionStages2_2.RecordManualPlacementOfStageInGraph(
			Dimensions, AdditionalProperties.ProductionSchedule, Attributes);
	EndIf;
	
	ProductionStage2_2Localization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	UUID = Undefined;
	ReferenceOrder            = Undefined;
	Organization             = Undefined;
	ProductionIssueForActivity   = Undefined;
	InternalSubcontracting   = Undefined;
	MaterialProviderCompany      = Undefined;
	LineOfBusiness = Undefined;
	Partner                 = Undefined;
	Contract                 = Undefined;
	ControlledLotReference    = Undefined;
	
	BillOfMaterials = Undefined;
	
	Purpose              = Undefined;
	AssignmentProducts     = Undefined;
	
	RowsCount = SupplyWithMaterialsAndWorks.Count();
	If RowsCount > 0 Then
		SupplyWithMaterialsAndWorks.LoadColumn(New Array(RowsCount), "Purpose");
	EndIf;
	
	InventoryOwnerAttributesProducts.Clear();
	InventoryOwnerAttributesMaterials.Clear();
	
	GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption();
	
	FillParameters = Documents.ProductionStage2_2.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(ProductionIssueForActivity, FillParameters);
	
	TSRow = "ManufacturedProducts,SideAndIntermediateRelease,SupplyWithMaterialsAndWorks,MaterialsAndWorksConsumption,UnusedMaterials,InventoryOwnerAttributesProducts,InventoryOwnerAttributesMaterials";
	TMCommonUse.ClearDocumentIDs(ThisObject, TSRow);
	OrderStructureDocumentPosting.ClearRowKeysInTablePart(ThisObject, "SupplyWithMaterialsAndWorks", "KeyProducts");
	OrderStructureDocumentPosting.ClearRowKeysInTablePart(ThisObject, "LaborCosts", "KeyWorkType");
	
	ProductionStage2_2Localization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
	
		If FillingData.Property("HeaderAttributes") Then
			FillPropertyValues(ThisObject, FillingData.HeaderAttributes);
		EndIf;
		
		If FillingData.Property("SpecificationData")
			And FillingData.Property("Data_Stage") Then
			
			FillInByBOM(FillingData.SpecificationData, FillingData.Data_Stage);
			
		Else
			
			If FillingData.Property("ManufacturedProducts") Then
				ManufacturedProducts.Load(FillingData.ManufacturedProducts);
			EndIf;
			If FillingData.Property("SideAndIntermediateRelease") Then
				SideAndIntermediateRelease.Load(FillingData.SideAndIntermediateRelease);
			EndIf;
			If FillingData.Property("ManufacturedProducts")
				Or FillingData.Property("SideAndIntermediateRelease") Then
				FillInProductionDateInHeader();
			EndIf;
			If FillingData.Property("SupplyWithMaterialsAndWorks") Then
				SupplyWithMaterialsAndWorks.Load(FillingData.SupplyWithMaterialsAndWorks);
			EndIf;
			If FillingData.Property("LaborCosts") Then
				LaborCosts.Load(FillingData.LaborCosts);
			EndIf;
			If FillingData.Property("WorkCenterTypes") Then
				WorkCenterTypes.Load(FillingData.WorkCenterTypes);
			EndIf;
			If FillingData.Property("AlternateWorkCenterTypes") Then
				AlternateWorkCenterTypes.Load(FillingData.AlternateWorkCenterTypes);
			EndIf;
			If FillingData.Property("Successors")
					And TypeOf(FillingData.Successors) = Type("Array") Then
				Successors.Clear();
				For Each Follower In FillingData.Successors Do
					NewRow = Successors.Add();
					NewRow.Stage     = Follower;
					NewRow.LinkType = Documents.ProductionStage2_2.CommunicationTypeFollower();
				EndDo;
			EndIf;
			If FillingData.Property("MaterialsAndWorksSets") Then
				MaterialsAndWorksSets.Load(FillingData.MaterialsAndWorksSets);
				ProductDataManagement.UpdateSetsOfMaterialsAndWorksTable(ThisObject);
			EndIf;
			
			If IsNew() Then
				TMCommonUse.ClearDocumentIDs(ThisObject, "ManufacturedProducts,SideAndIntermediateRelease,SupplyWithMaterialsAndWorks");
				OrderStructureDocumentPosting.ClearRowKeysInTablePart(ThisObject, "SupplyWithMaterialsAndWorks", "KeyProducts");
				OrderStructureDocumentPosting.ClearRowKeysInTablePart(ThisObject, "LaborCosts", "KeyWorkType");
			EndIf;
			
		EndIf;
		
		If FillingData.Property("BatchFinishedProducts") Then
			BatchFinishedProducts.Load(FillingData.BatchFinishedProducts);
		EndIf;
		If FillingData.Property("BatchSideAndIntermediateRelease") Then
			BatchSideAndIntermediateRelease.Load(FillingData.BatchSideAndIntermediateRelease);
		EndIf;
		If FillingData.Property("MaterialsAndWorksConsumption") Then
			MaterialsAndWorksConsumption.Load(FillingData.MaterialsAndWorksConsumption);
		EndIf;
		If FillingData.Property("UnusedMaterials") Then
			UnusedMaterials.Load(FillingData.UnusedMaterials);
		EndIf;
		If FillingData.Property("SavingMaterialsBatch") Then
			SavingMaterialsBatch.Load(FillingData.SavingMaterialsBatch);
		EndIf;
		
		SeriesSpecificationParameters = Documents.ProductionStage2_2.SeriesSpecificationParameters(ThisObject);
		FillInStatusesForSpecifyingVHFSeries("ManufacturedProducts", SeriesSpecificationParameters);
		FillInStatusesForSpecifyingVHFSeries("SideAndIntermediateRelease", SeriesSpecificationParameters);
		FillInStatusesForSpecifyingVHFSeries("SupplyWithMaterialsAndWorks", SeriesSpecificationParameters);
		FillInStatusesForSpecifyingVHFSeries("MaterialsAndWorksConsumption", SeriesSpecificationParameters);
		FillInStatusesForSpecifyingVHFSeries("UnusedMaterials", SeriesSpecificationParameters);
		
		If FillingData.Property("TechProcessParameters") Then
			ChangeTechProcessParameters(FillingData.TechProcessParameters);
		EndIf;
		
	EndIf;
	
	FillInNumberByOrder();
	
	FillInCacheOfMainVRC();
	
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	
	If Not ValueIsFilled(EmployeeResponsible) Then
		EmployeeResponsible  = Users.CurrentUser();
	EndIf;
	
	PriceKind = Catalogs.TypesOfPrices.TypeOfPricePlannedCostOfInventory(PriceKind);
	If Not ValueIsFilled(Currency) Then
		Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(Catalogs.TypesOfPrices.GetPriceTypeDetails(PriceKind).PriceCurrency);
	EndIf;
	If Not ValueIsFilled(GoodsReceiptOption) Then
		GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption();
	EndIf;
	
	If Not BatchGenerationIsPerformed() Then
		
		ProductionSupply.FillInPurposeOfSemiFinishedProductsInProductionPhase(ThisObject);
		
		FillParameters = Documents.ProductionStage2_2.ParametersForFillingInVATActivityType(ThisObject);
		VATAccountingERP.FillInTypeOfActivityVAT(ProductionIssueForActivity, FillParameters);
		
		ItemsAndDimensionsSelectionParameters = Documents.ProductionStage2_2.ItemsAndDimensionsSelectionParameters(ThisObject);
		IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);

	EndIf;
	
	ProductionStage2_2Localization.Filling(ThisObject, FillingData, FillingText, StandardProcessing);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Status = Enums.StatusesOfProductionStages2_2.BeingGenerated Then
		
		RequiredDetails_ = Documents.ProductionStage2_2.ListOfRequiredBankingDetailsInStatusIsGenerated(ThisObject);
		
		For IndexOf = -CheckedAttributes.Count() + 1 To 0 Do
			If RequiredDetails_.Find(CheckedAttributes[-IndexOf]) = Undefined Then
				CheckedAttributes.Delete(-IndexOf);
			EndIf;
		EndDo;
		
		If ProductionByThirdParty
			And ValueIsFilled(SubcontractOrder) Then
			
			ErrorText = NStr("vi = 'Đăng một chứng từ với trạng thái Chế độ Lập nên hay biểu mẫu chỉ có sẵn trong trường hợp không có lệnh cho gia công.';
							|ru = 'Проведение документа со статусом ""Формируется"" или ""Сформирован"" доступно только при отсутствии заказа переработчику.';
							|en = 'You can post a document with the Being generated or Generated status only if a ""Subcontracting purchase order"" is missing.'; fa = 'You can post a document with the Being generated or Generated status only if a ""Subcontracting purchase order"" is missing.';
							|it = 'L''esecuzione di un documento con lo stato ""in elaborazione"" o ""elaborato"" è disponibile solo in mancanza di un ordine per il processore.';
							|pl = 'Posiadanie dokumentu o statusie ""W trakcie tworzenia"" lub ""Utworzony"" jest dostępne tylko w przypadku braku zamówienia do przetwórcy.';
							|tr = '""Düzenleniyor"" veya ""Oluşturuldu"" durumuna sahip bir belgenin kaydedilmesi sadece fason üretici satın alma siparişinin yokluğunda mevcuttur.'");
			
			CommonClientServer.MessageToUser(
				ErrorText,
				Ref,
				"Status",,
				Cancel);
			
		EndIf;
		
		Return; // for the status being formed, the check is performed in the minimum version
		
	EndIf;
	
	Documents.ProductionStage2_2.CheckUseOfBatchAccounting22(ThisObject, Cancel);
	
	NotCheckedAttributeArray = New Array;
	
	ThisIsAProductionIssueStage = ProductionManagementClientServer.ThisIsAProductionIssueStage(ThisObject);
	
	If ManufacturedProducts.Find(False, "Canceled") = Undefined Then
		NotCheckedAttributeArray.Add("MethodOfAllocatingFinishedProductCosts");
	EndIf;
	
	If PlanOperationsOfWorkCenterTypes Or StagePlacementInProductionSchedule Then
		NotCheckedAttributeArray.Add("UnitOfMeasureOfStageDuration");
	EndIf;
	
	If Not PlanOperationsOfWorkCenterTypes Or StagePlacementInProductionSchedule Then
		NotCheckedAttributeArray.Add("UnitOfMeasureOfPreliminaryBuffer");
		NotCheckedAttributeArray.Add("UnitOfMeasureOfFollowUpBuffer");
	EndIf;
	
	NotCheckedAttributeArray.Add("OperatingProcedureOfWorkCenterTypes");
	If BatchGenerationIsPerformed() Then
		CheckOrderOfWorkCenterTypes(Cancel);
	EndIf;
	
	If Not ConsumptionInOneDay Or MaterialsAndWorksConsumption.Count() = 0 Then
		NotCheckedAttributeArray.Add("DateOfMaterialWorkConsumption");
	EndIf;
	
	If ProductionProcessType = Enums.ProductionProcessTypes.WithoutBillsOfMaterials Then
		NotCheckedAttributeArray.Add("NumberOfPackagesPlan");
	EndIf;
	
	#Region ManufacturedProducts
	
	If ThisIsAProductionIssueStage
		And Not ProductionProcessType = Enums.ProductionProcessTypes.WithoutBillsOfMaterials Then
		
		If ManufacturedProducts.Find(False, "Canceled") = Undefined Then
			
			MessageText = CommonClientServer.FillingErrorText(
				"List", "FillType",,, Ref.Metadata().TabularSections.ManufacturedProducts.Synonym);
			
			If ProductionByThirdParty Then
				// For production on the side, verification is not exceptional - the conduct does not stop.
				Common.MessageToUser(
					MessageText,
					ThisObject,
					"ManufacturedProducts");
			Else
				Common.MessageToUser(
					MessageText,
					ThisObject,
					"ManufacturedProducts",,
					Cancel);
			EndIf;
			
		EndIf;
		
	ElsIf ProductionByThirdParty
		And SideAndIntermediateRelease.Find(False, "Canceled") = Undefined
		And Not ProductionProcessType = Enums.ProductionProcessTypes.WithoutBillsOfMaterials Then
		
		MessageText = CommonClientServer.FillingErrorText(
			"List", "FillType",,, Ref.Metadata().TabularSections.SideAndIntermediateRelease.Synonym);
		
		Common.MessageToUser(
			MessageText,
			ThisObject,
			"SideAndIntermediateRelease");
		
	EndIf;
	
	#EndRegion
	
	#Region ProcessingByThirdParties
	
	If ProductionByThirdParty Then
		
		If ProductionProcessType <> Enums.ProductionProcessTypes.Assembly
			And ProductionProcessType <> Enums.ProductionProcessTypes.WithoutBillsOfMaterials Then
			
			Template = NStr("vi = 'Đối với quy trình sản xuất dạng ""%1"", không hỗ trợ thực hiện công đoạn bởi gia công của bên thứ ba.';
							|ru = 'Для производственного процесса типа ""%1"" не поддерживается выполнение этапа сторонними переработчиками.';
							|en = 'Third party subcontractors cannot execute stage for the production process of the ""%1"" type.'; fa = 'Third party subcontractors cannot execute stage for the production process of the ""%1"" type.';
							|it = 'Per il processo produttivo di tipo ""%1"" non è supportato il completamento della fase da parte di processori terzi.';
							|pl = 'Dla procesu produkcyjnego typu ""%1"" etap nie jest obsługiwane wykonanie etapu przez zewnętrznych przetwórców.';
							|tr = '""%1"" türündeki üretim süreci için üçüncü taraf fason üretici tarafından aşamanın gerçekleştirilmesi desteklenmemektedir.'");
			MessageText = StrTemplate(Template, ProductionProcessType);
			Common.MessageToUser(MessageText, ThisObject, "ProductionByThirdParty",, Cancel);
			
		EndIf;
		
		If BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
				And Not GetFunctionalOption("UseSubcontractOrders2_5") Then
			
			MessageText = NStr("vi = 'Khi sản xuất từ nguyên vật liệu gia công, không hỗ trợ thực hiện công đoạn bởi bên gia công thứ ba, phiên bản 2.4.
										|Để có thể chuyển sang bên gia công thứ ba, cần bật sử dụng đơn hàng cho bên gia công, phiên bản 2.5.';
										|ru = 'При производстве из давальческого сырья не поддерживается выполнение этапа сторонними переработчиками версии 2.4.
										|Для возможности передачи сторонним переработчикам нужно включить использование заказа переработчику версии 2.5.';
										|en = 'Stage execution by third-party subcontractors of version 2.4 is not supported for subcontracting.
										|To transfer to third-party subcontractors, enable subcontracting purchase orders 2.5.'; fa = 'Stage execution by third-party subcontractors of version 2.4 is not supported for subcontracting.
										|To transfer to third-party subcontractors, enable subcontracting purchase orders 2.5.';
										|it = 'In caso di produzione da materie prime del fornitore non è supportata l''esecuzione della fase da parte di elaboratori aggiuntivi della versione 2.4.
										|Per trasferire tramite gli elaboratori aggiuntivi è necessario attivare l''utilizzo dell''ordine all''elaboratore della versione 2.5.';
										|pl = 'W przypadku produkcji z surowców przekazanych przez właściciela surowców nie jest obsługiwane wykonanie etapu przez przetwórców zewnętrznych wersji 2.4.
										|Dla możliwości przekazania przetwórcom zewnętrznym należy włączyć użycie zamówienia do przetwórcy wersji 2.5.';
										|tr = 'Tedarikçi hammaddelerinden üretim yapılırken, aşamanın üçüncü taraf fason üreticiler sürüm 2.4. tarafından gerçekleştirilmesi desteklenmemektedir.
										|Üçüncü taraf fason üreticiler  transfer yapabilmek için fason üretici  satın alma siparişi sürüm 2.5.''in kullanılması etkinleştirilmelidir.'");
			Common.MessageToUser(MessageText, ThisObject, "ProductionByThirdParty",, Cancel);
		EndIf;
		
	EndIf;
	
	#EndRegion
	
	
	TempTablesManager = Documents.ProductionStage2_2.TemporaryObjectDataTables(ThisObject);
	Documents.ProductionStage2_2.CheckObjectFilling(ThisObject, TempTablesManager, Cancel, CheckedAttributes);
	
	If Not BatchGenerationIsPerformed() Then
		
		If Status = Enums.StatusesOfProductionStages2_2.Completed
			And Not ProductionByThirdParty
			And ProductionProcessType <> Enums.ProductionProcessTypes.WithoutBillsOfMaterials Then
			
			CountPlan = NumberOfPackagesPlan;
			CountReal = NumberOfPackagesReal;
			CountCanceled = NumberOfPackagesCanceled;
			
			If PackagePlan <> PackageActualData
				Or PackagePlan <> PackageCanceled Then
				QueryText = 
					"SELECT
					|	ISNULL(&QueryTextPackagingFactorPlan, 1)     AS CoefficientPlan,
					|	ISNULL(&QueryTextPackagingFactorFact, 1)     AS CoefficientFact,
					|	ISNULL(&QueryTextPackagingFactorCanceled, 1) AS ZoomRatioCanceled
					|FROM
					|	Catalog.ProductionLots AS ProductionLots
					|WHERE
					|	ProductionLots.Ref = &ProductionLot";
				
				QueryText = StrReplace(QueryText,
					"&QueryTextPackagingFactorPlan",
					Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
						"CAST(&PackagePlan AS Catalog.PackagesAndUnitsOfMeasure)",
						"ProductionLots.MainProductProducts"));
				
				QueryText = StrReplace(QueryText,
					"&QueryTextPackagingFactorFact",
					Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
						"CAST(&PackageActualData AS Catalog.PackagesAndUnitsOfMeasure)",
						"ProductionLots.MainProductProducts"));
				
				QueryText = StrReplace(QueryText,
					"&QueryTextPackagingFactorCanceled",
					Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
						"CAST(&PackageCanceled AS Catalog.PackagesAndUnitsOfMeasure)",
						"ProductionLots.MainProductProducts"));
				
				Query = New Query(QueryText);
				Query.SetParameter("ProductionLot", ProductionLot);
				Query.SetParameter("PackagePlan", PackagePlan);
				Query.SetParameter("PackageActualData", PackageActualData);
				Query.SetParameter("PackageCanceled", PackageCanceled);
				Selection = Query.Execute().Select();
				
				If Selection.Next() Then
					CountPlan = NumberOfPackagesPlan * Selection.CoefficientPlan;
					CountReal = NumberOfPackagesReal * Selection.CoefficientFact;
					CountCanceled = NumberOfPackagesCanceled * Selection.ZoomRatioCanceled;
				EndIf;
			EndIf;
			
			If CountPlan > CountReal + CountCanceled Then
				
				CommonClientServer.MessageToUser(
					NStr("vi = 'Tất cả số lượng theo kế hoạch phải được đảm bảo hoặc hủy bỏ.';
						|ru = 'Все запланированное количество должно быть выполнено или отменено.';
						|en = 'All scheduled quantity must be completed or cancelled.'; fa = 'All scheduled quantity must be completed or cancelled.';
						|it = 'Tutta la quantità programmata deve essere eseguita o annullata.';
						|pl = 'Cała zaplanowana ilość powinna być wykonana lub anulowana.';
						|tr = 'Planlanan tüm miktarlar gerçekleştirilmeli veya iptal edilmelidir.'"),
					ThisObject,
					"NumberOfPackagesReal",,
					Cancel);
				
			ElsIf CountCanceled <> Max(CountPlan-CountReal, 0) Then
				
				CommonClientServer.MessageToUser(
					NStr("vi = 'Số tiền bị hủy không được vượt quá kế hoạch trừ đi hoàn thành.';
						|ru = 'Отмененное количество не должно превышать запланированное за вычетом выполненного.';
						|en = 'The cancelled amount must not exceed the planned amount minus the completed amount.'; fa = 'The cancelled amount must not exceed the planned amount minus the completed amount.';
						|it = 'La quantità annullata non deve superare quella pianificata meno la quantità eseguita.';
						|pl = 'Anulowana ilość nie powinna przekraczać zaplanowane z wyjątkiem wykonanego.';
						|tr = 'İptal edilen miktar, planlanandan daha az tamamlanmış olanı aşmamalıdır.'"),
					ThisObject,
					"NumberOfPackagesCanceled",,
					Cancel);
			
			EndIf;
		
		EndIf;
		
		CheckSeriesCompletion(NotCheckedAttributeArray, Cancel);
		
		ItemsAndDimensionsSelectionParameters = Documents.ProductionStage2_2.ItemsAndDimensionsSelectionParameters(ThisObject);
		IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
		
		RoundingParameters = Documents.ProductionStage2_2.TSParametersForRounding();
		ProductsServer.CheckQuantityRounding(ThisObject, Cancel, RoundingParameters["ManufacturedProducts"]);
		ProductsServer.CheckQuantityRounding(ThisObject, Cancel, RoundingParameters["SideAndIntermediateRelease"]);
		ProductsServer.CheckQuantityRounding(ThisObject, Cancel, RoundingParameters["SupplyWithMaterialsAndWorks"]);
		ProductsServer.CheckQuantityRounding(ThisObject, Cancel, RoundingParameters["UnusedMaterials"]);
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	ProductionStage2_2Localization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	If BatchGenerationIsPerformed() Then
		Return;
	EndIf;
	
	FillParameters = ParametersForFillingInventoryTypes("Posting");
	AdditionalProperties.Insert("ParametersForFillingInventoryTypes", FillParameters);
	AdditionalProperties.Insert("UseFillingParametersForInventoryTypesInPreparation");
	
	AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	AddlParameters.AdditionalProperties = AdditionalProperties;
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel, AddlParameters);
	
	PerformControlWhenClosingStage(Cancel);
	
	UpdateRelatedData(Cancel);
	
	If Not Cancel And ValueIsFilled(AdditionalProperties.PeriodOfRewritingRegisteredRecords)
	 And Not CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject) Then
		InformationRegisters.JobsForCalculatingCost.CreateRegisterEntry(
			AdditionalProperties.PeriodOfRewritingRegisteredRecords,
			Ref,
			Organization);
	EndIf;
	
	ProductionStage2_2Localization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	FillParameters = ParametersForFillingInventoryTypes("Posting");
	
	AdditionalProperties.Insert("ParametersForFillingInventoryTypes", FillParameters);
	AdditionalProperties.Insert("UseFillingParametersForInventoryTypesInPreparation");
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	ProductionStage2_2Localization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region FillChecking

Function DataOfProductionStages() Export
	
	DataStructureOfStages = ProductionManagement.DataStructureOfProductionStages();
	
	FinalCheck = (Status = Enums.StatusesOfProductionStages2_2.Initiated
					Or Status = Enums.StatusesOfProductionStages2_2.Completed);
	
	// Details of the caps
	FillPropertyValues(DataStructureOfStages.Attributes.Add(), ThisObject);
	
	// ManufacturedProducts
	If (FinalCheck Or ManufacturedProducts.Count() > 0) Then
		FillInTsToCheckFill(DataStructureOfStages, "ManufacturedProducts")
	EndIf;
	
	// SideAndIntermediateRelease
	If (FinalCheck Or SideAndIntermediateRelease.Count() > 0) Then
		FillInTsToCheckFill(DataStructureOfStages, "SideAndIntermediateRelease")
	EndIf;
	
	// SupplyWithMaterialsAndWorks
	If (FinalCheck Or SupplyWithMaterialsAndWorks.Count() > 0) Then
		FillInTsToCheckFill(DataStructureOfStages, "SupplyWithMaterialsAndWorks")
	EndIf;
	
	// MaterialsAndWorksConsumption
	If FinalCheck Then
		FillInTsToCheckFill(DataStructureOfStages, "MaterialsAndWorksConsumption")
	EndIf;
	
	// UnusedMaterials
	If FinalCheck Then
		FillInTsToCheckFill(DataStructureOfStages, "UnusedMaterials")
	EndIf;
	
	// LaborCosts
	If (FinalCheck Or LaborCosts.Count() > 0)
		And Documents.ProductionStage2_2.MarkOfPerformedLaborCostsIsUsed(ThisObject) Then
		FillInTsToCheckFill(DataStructureOfStages, "LaborCosts")
	EndIf;
	
	Return DataStructureOfStages;
	
EndFunction

Procedure FillInTsToCheckFill(DataToCheck, TSName)
	
	DocumentTables = DocumentTables();
	
	DataToCheck["CheckingTS" + TSName] = True;
	
	For Each String In DocumentTables[TSName] Do
		CheckTable = DataToCheck[TSName]; // ValueTable - 
		
		NewRow = CheckTable.Add();
		FillPropertyValues(NewRow, String);
		FillPropertyValues(NewRow, ThisObject, "Ref");
	EndDo;
	
EndProcedure

Procedure CheckSeriesCompletion(NotCheckedAttributeArray, Cancel)
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ProductionStage2_2);
	ParametersArray  = New Array;
	CheckParameters = Undefined;
	
	If WorkPlanning Then
		CheckParameters = ProductsServer.SeriesFillCheckParameters();
		CheckParameters.PresentationOfTS = Documents.ProductionStage2_2.PresentationOfTSSupply(ThisObject);
		ParametersArray.Add(SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);
	Else
		ParametersArray.Add(SeriesSpecificationParameters.ManufacturedProducts);
		ParametersArray.Add(SeriesSpecificationParameters.SideAndIntermediateRelease);
		ParametersArray.Add(SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);
		ParametersArray.Add(SeriesSpecificationParameters.MaterialsAndWorksConsumption);
		ParametersArray.Add(SeriesSpecificationParameters.UnusedMaterials);
	EndIf;
	
	ProductsServer.CheckSeriesCompletion(ThisObject,
		ParametersArray,
		Cancel,
		NotCheckedAttributeArray,
		CheckParameters);
	
EndProcedure

#EndRegion

#Region ControlOfConduct

Procedure PerformDataControlOfChainOfStages(Cancel)
	
	// In the editing mode of the chain of stages, separate checks are performed
	If AdditionalProperties.Property("DisableVerificationOfStageChainDetails") Then
		Return;
	EndIf;
	
	ChecksArray = New Array;
	
	ThisIsAProductionIssueStage = ProductionManagementClientServer.ThisIsAProductionIssueStage(ThisObject);
	If ThisIsAProductionIssueStage
		And Status <> Enums.StatusesOfProductionStages2_2.BeingGenerated Then
		ChecksArray.Add("CheckSharesOfCostOfOutputProducts");
	EndIf;
	
	If (Status = Enums.StatusesOfProductionStages2_2.Initiated
		Or Status = Enums.StatusesOfProductionStages2_2.Completed)
		And Not ProductionByThirdParty
		And Common.DebugMode() Then
		ChecksArray.Add("CheckDetailsOfChainOfStages");
	EndIf;
	
	If ChecksArray.UBound() = -1 Then
		Return;
	EndIf;
	
	If ChecksArray.Find("CheckSharesOfCostOfOutputProducts") <> Undefined Then
		CheckSharesOfCostOfOutputProducts(Cancel);
	EndIf;
	
	If ChecksArray.Find("CheckDetailsOfChainOfStages") <> Undefined Then
		CheckDetailsOfChainOfStages(Cancel);
	EndIf;
	
EndProcedure

Procedure CheckSharesOfCostOfOutputProducts(Cancel)
	
	CostAllocationParameters = Documents.ProductionStage2_2.CostAllocationParameters(ThisObject);
	
	QueryText = Documents.ProductionStage2_2.QueryTextCheckCOSTShares(
		ThisObject,	CostAllocationParameters.LinkFields);
	
	Query = New Query(QueryText);
	Query.SetParameter("ProductionLot", ProductionLot);
	Query.SetParameter("MethodOfAllocatingFinishedProductCosts", MethodOfAllocatingFinishedProductCosts);
	
	Result = Query.ExecuteBatch();
	NumberOfPackages_ = Result.Count();
	
	If Not Result[NumberOfPackages_-1].IsEmpty() Then
		
		MessageText = NStr("vi = 'Điều kiện tiên quyết ""Phương pháp phân bổ chi phí cho hàng hóa đầu ra"" phải có cùng giá trị cho tất cả các công đoạn sản xuất.';
							|ru = 'Реквизит ""Способ распределения затрат на выходные изделия"" должен иметь одинаковое значение для всех выпускающих этапов.';
							|en = 'The Method of allocating finished product costs attribute must have the same value for all release stages.'; fa = 'The Method of allocating finished product costs attribute must have the same value for all release stages.';
							|it = 'Il requisito ""metodi di allocazione del costo dei prodotti di output"" dovrebbe avere lo stesso valore per tutte le fasi produttive.';
							|pl = 'Rekwizyt ""Sposób przydziału kosztów wyrobów wychodzących"" powinien mieć tę samą wartość dla wszystkich etapów produkcji.';
							|tr = '""Üretilen nihai ürünlere yönelik maliyet dağıtım yöntemi"" özniteliği, tüm ürün çıkış aşamaları için aynı değere sahip olmalıdır.'");
		CommonClientServer.MessageToUser(
					MessageText,
					ThisObject,
					"MethodOfAllocatingFinishedProductCosts",,
					Cancel);
		
	EndIf;
	
	If Not Result[NumberOfPackages_-2].IsEmpty() Then
		
		Template = NStr("vi = 'Khi phát hành một số mặt hàng của hàng hóa đầu ra, cần phải chỉ ra phần chi phí của họ (dòng %1 %2).';
						|ru = 'При выпуске нескольких наименований выходных изделий требуется указать их долю стоимости (строка %1%2).';
						|en = 'When releasing several names of finished products, you should specify their cost share (line %1%2).'; fa = 'When releasing several names of finished products, you should specify their cost share (line %1%2).';
						|it = 'In caso di emissione di diversi tipi di prodotti è necessario indicare la loro parte nel costo (riga %1%2).';
						|pl = 'W wypadku produkcji kilku pozycji produktów wychodzących trzeba wskazać ich udział wartości (wiersz %1%2).';
						|tr = 'Üretilen nihai ürünlerin birden fazla öğesinin çıkışı esnasında, bunların maliyet paylarının belirtilmesi gerekmektedir (%2%1 satırı).'");
		
		Selection = Result[NumberOfPackages_-2].Select();
		While Selection.Next() Do
			
			LineNumber = Format(Selection.LineNumber, "NG=");
			
			If Selection.Ref <> Ref Then
				
				MessageText = StrTemplate(Template, LineNumber, ", " + Selection.Ref + "");
				Field = CommonClientServer.PathToTabularSection("ManufacturedProducts", Selection.LineNumber, "CostShare");
				
				CommonClientServer.MessageToUser(
					MessageText,
					Selection.Ref,
					Field,
					,
					Cancel);
				
			Else
				
				MessageText = StrTemplate(Template, LineNumber, "");
				Field = CommonClientServer.PathToTabularSection("ManufacturedProducts", Selection.LineNumber, "CostShare");
				
				CommonClientServer.MessageToUser(
					MessageText,
					ThisObject,
					Field,
					,
					Cancel);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure CheckDetailsOfChainOfStages(Cancel)
	
	SubstitutionText = "";
	CommonAttributes = Documents.ProductionStage2_2.GeneralDetailsOfChainOfStages(True);
	
	For Each AttributeName In CommonAttributes Do
		SubstitutionText = SubstitutionText
			+ ?(IsBlankString(SubstitutionText),"",","+Chars.LF)
			+ StrTemplate("ChainStages.%1", AttributeName);
	EndDo;
	
	QueryText = "
	|SELECT
	|	TRUE
	|FROM
	|	(SELECT DISTINCT
	|		&SubstitutionText
	|	FROM
	|		Document.ProductionStage2_2 AS ChainStages
	|	WHERE
	|		ChainStages.ProductionLot = &ProductionLot
	|		AND NOT ChainStages.DeletionMark) AS T
	|
	|HAVING
	|	COUNT(*) > 1";
	
	QueryText = StrReplace(QueryText, "&SubstitutionText", SubstitutionText);
	
	Query = New Query(QueryText);
	Query.SetParameter("ProductionLot", ProductionLot);
	
	// The general details in one chain should not differ
	If Not Query.Execute().IsEmpty() Then
		
		MessageText = NStr("vi = 'Các chi tiết chung của một chuỗi các bước là khác nhau. Liên hệ với quản trị viên của bạn.';
							|ru = 'Общие реквизиты одной цепочки этапов отличаются. Обратитесь к администратору.';
							|en = 'Common attributes of one stage chain are different. Please contact the administrator.'; fa = 'Common attributes of one stage chain are different. Please contact the administrator.';
							|it = 'I dettagli generali di una singola catena di fasi differiscono. Rivolgersi all''amministratore.';
							|pl = 'Wspólne rekwizyty jednego łańcucha etapów są różne. Skontaktuj się z administratorem.';
							|tr = 'Aynı aşama zincirinin genel öznitelikleri farklıdır. Yöneticiye başvurun.'");
		CommonClientServer.MessageToUser(
					MessageText,
					ThisObject,
					,,
					Cancel);
		
	EndIf;
	
EndProcedure

Procedure CheckProductionProcess(Cancel, WriteMode)
	
	If WriteMode <> DocumentWriteMode.Posting Then
		Return;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	Table.Ref
	|FROM
	|	Document.ProductionOrder2_2 AS Table
	|WHERE
	|	Table.Ref = &Ref
	|	AND Table.Posted");
		
	Query.SetParameter("Ref", ThisObject.ReferenceOrder);
	
	If Query.Execute().IsEmpty() Then
		
		TemplateText = NStr("vi = 'Không thể thực hiện kỳ sản xuất số %1 ngày %2 liên quan đến đơn hàng sản xuất chưa được giao.';
							|ru = 'Невозможно провести этап производства № %1 от %2, относящийся к непроведенному заказу на производство.';
							|en = 'Cannot post production stage No. %1, %2 which belongs to the unposted production order.'; fa = 'Cannot post production stage No. %1, %2 which belongs to the unposted production order.';
							|it = 'Impossibile eseguire la fase di produzione № %1 di %2, relativo a un ordine di produzione non prodotto.';
							|pl = 'Nie można zaksięgować fazy produkcji nr %1 z dnia %2, odnoszącej się do nie zaksięgowanego zlecenia produkcyjnego.';
							|tr = 'Kaydedilmemiş bir üretim emriyle ilgili %2 tarihli %1 numaralı üretim aşaması kaydedilemez.'");
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			TemplateText,
			ObjectsPrefixesClientServer.NumberForPrinting(Number, False, True),
			Format(Date, "DLF=D"));
		
		CommonClientServer.MessageToUser(ErrorText, ThisObject, ,, Cancel);
		
		Return;
		
	EndIf;
		
	If Status <> Enums.StatusesOfProductionStages2_2.BeingGenerated Then
		
		If ThisObject.StageNumber >= ThisObject.NextStageNo And ThisObject.NextStageNo <> 0 Then
			
			MessageText = NStr("vi = 'Số công đoạn tiếp theo phải lớn hơn số công đoạn.';
								|ru = 'Номер следующего этапа должен быть больше номера этапа.';
								|en = 'Next stage number should be more than the stage number.'; fa = 'Next stage number should be more than the stage number.';
								|it = 'Il numero della fase successiva deve essere superiore al numero della fase.';
								|pl = 'Numer kolejnego etapu musi być większy niż numer etapu.';
								|tr = 'Sonraki işlem numarası, aşama numarasından büyük olmalıdır.'");
			
			CommonClientServer.MessageToUser(
						MessageText,
						ThisObject,,, 
						Cancel);
			
		EndIf;
		
		If ThisObject.PlanOperationsOfWorkCenterTypes Then
			
			If ThisObject.WorkCenterTypes.Count() > 0 Then
				
				References = WorkCenterTypes.UnloadColumn("WorkCenterType");
				For Each StringAlternativeViewOfRC In AlternateWorkCenterTypes Do
					References.Add(StringAlternativeViewOfRC.WorkCenterType);
				EndDo;
				AttributesValues = Common.ObjectsAttributesValues(References, "ParallelLoad");
				
				LineNumber = 0;
				For Each RowMainViewOfRC In ThisObject.WorkCenterTypes Do
					
					LineNumber = LineNumber + 1;
					
					CheckTypesOfWorkCenters(
						RowMainViewOfRC, LineNumber, AttributesValues[RowMainViewOfRC.WorkCenterType], Cancel);
					
					TheStructureOfTheSearch = New Structure("LinkKeyWorkCenterTypes", RowMainViewOfRC.ConnectionKey);
					
					For Each StringAlternativeViewOfRC In ThisObject.AlternateWorkCenterTypes.FindRows(TheStructureOfTheSearch) Do
						
						LineNumber = LineNumber + 1;
						
						CheckTypesOfWorkCenters(
							StringAlternativeViewOfRC, LineNumber, AttributesValues[StringAlternativeViewOfRC.WorkCenterType], Cancel);
						
					EndDo;
					
				EndDo;
				
			Else 
				
				MessageText = NStr("vi = 'Không có một dòng nào được nhập vào danh sách ""Dạng trung tâm làm việc"".';
									|ru = 'Не введено ни одной строки в список ""Виды рабочих центров"".';
									|en = 'No lines are entered into the ""Work center types"" list.'; fa = 'No lines are entered into the ""Work center types"" list.';
									|it = 'Non è stata inserita nemmeno una riga nell''elenco ""Tipi di centri di lavoro"".';
									|pl = 'Nie wprowadzono ani jednego wiersza do listy ""Rodzaje centrów wykonania pracy"".';
									|tr = '""İş Merkezi Türleri"" listesine herhangi bir satır girilmedi.'");
				
				CommonClientServer.MessageToUser(
							MessageText, 
							, 
							"WorkCenterTypes",, 
							Cancel);
				
			EndIf;
			
			CheckOrderOfWorkCenterTypes(Cancel);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CheckTypesOfWorkCenters(CurrentRow, LineNumber, DetailsOfRCType, Cancel)

	ParametersOfTablePart = New Structure;
	ParametersOfTablePart.Insert("Name",           "WorkCenterTypes");
	ParametersOfTablePart.Insert("Presentation", NStr("vi = 'Dạng nguồn lực sản xuất';
														|ru = 'Виды рабочих центров';
														|en = 'Work center types'; fa = 'انواع مرکز کاری';
														|it = 'Tipi di centri operativi';
														|pl = 'Rodzaj centrów wykonania pracy';
														|tr = 'İş merkezi türleri'"));
	ParametersOfTablePart.Insert("LineNumber",   LineNumber);
	
	MessageTemplate = NStr("vi = 'Chưa điền cột ""%1"" trong dòng %2 của danh sách ""%3"".';
							|ru = 'Не заполнена колонка ""%1"" в строке %2 списка ""%3"".';
							|en = 'Column ""%1"" in line %2 of list ""%3"" is required.'; fa = 'Column ""%1"" in line %2 of list ""%3"" is required.';
							|it = 'La colonna ""%1"" nella riga %2 dell''elenco ""%3"" non è compilata.';
							|pl = 'Nie wypełniono kolumny ""%1"" w wierszu %2 listy ""%3"".';
							|tr = '""%3"" listesinin %2 satırındaki ""%1"" sütunu doldurulmadı.'");
	
	If Not ValueIsFilled(CurrentRow.WorkCenterType) Then
		
		Field = CommonClientServer.PathToTabularSection(
					ParametersOfTablePart.Name, LineNumber, "WorkCenterType");
		
		MessageText = StrTemplate(MessageTemplate, 
									NStr("vi = 'Dạng nguồn lực sản xuất';
										|ru = 'Вид рабочего центра';
										|en = 'Work center type'; fa = 'نوع مرکز کاری';
										|it = 'Tipo di centro di lavoro';
										|pl = 'Rodzaj centrum wykonania pracy';
										|tr = 'İş merkezi türü'"),
									LineNumber,
									ParametersOfTablePart.Presentation);
		
		CommonClientServer.MessageToUser(
			MessageText, 
			ThisObject, 
			Field,, 
			Cancel); 
		
	EndIf;
	
	If Not ValueIsFilled(CurrentRow.OperationTime) Then
		
		Field = CommonClientServer.PathToTabularSection(
					ParametersOfTablePart.Name, LineNumber, "OperationTime");
		
		MessageText = StrTemplate(MessageTemplate, 
									NStr("vi = 'Thời gian làm việc';
										|ru = 'Время работы';
										|en = 'Working time'; fa = 'زمان کاری';
										|it = 'Tempo di lavoro';
										|pl = 'Czas pracy';
										|tr = 'Çalışma süresi'"),
									LineNumber,
									ParametersOfTablePart.Presentation);
		
		CommonClientServer.MessageToUser(
			MessageText, 
			ThisObject, 
			Field,, 
			Cancel); 
		
	EndIf; 
	
	If Not ValueIsFilled(CurrentRow.UnitOfMeasure) Then
		
		Field = CommonClientServer.PathToTabularSection(
					ParametersOfTablePart.Name, LineNumber, "UnitOfMeasure");
		
		MessageText = StrTemplate(MessageTemplate, 
									NStr("vi = 'Đơn vị tính thời gian';
										|ru = 'Единица измерения времени';
										|en = 'Time unit of measure'; fa = 'واحد اندازه‌گیری زمان';
										|it = 'Unità di misura del tempo';
										|pl = 'Jednostka miary czasu';
										|tr = 'Zaman ölçü birimi'"),
									LineNumber,
									ParametersOfTablePart.Presentation);
		
		CommonClientServer.MessageToUser(
			MessageText, 
			ThisObject, 
			Field,, 
			Cancel); 
		
	EndIf; 
	
	If DetailsOfRCType.ParallelLoad
		And Not ValueIsFilled(CurrentRow.Load) Then
		
		Field = CommonClientServer.PathToTabularSection(
			ParametersOfTablePart.Name, LineNumber, "Load");
		
		MessageText = StrTemplate(MessageTemplate, 
									NStr("vi = 'Kết nhập';
										|ru = 'Загрузка';
										|en = 'Load'; fa = 'بارگذاری';
										|it = 'Загрузка';
										|pl = 'Pobieranie';
										|tr = 'İndirme'"),
									LineNumber,
									ParametersOfTablePart.Presentation);
		
		CommonClientServer.MessageToUser(
			MessageText, 
			ThisObject, 
			Field,, 
			Cancel); 
		
	EndIf; 
	
EndProcedure

Procedure CheckOrderOfWorkCenterTypes(Cancel)
	
	If PlanOperationsOfWorkCenterTypes
		And ThisObject.WorkCenterTypes.Count() > 1 Then
		
		If OperatingProcedureOfWorkCenterTypes = Enums.OperatingProcedureOfWorkCenterTypes.EmptyRef() Then
			
			MessageText  = CommonClientServer.FillingErrorText(
				,
				,
				Ref.Metadata().Attributes.OperatingProcedureOfWorkCenterTypes.Synonym);
			
			CommonClientServer.MessageToUser(
						MessageText, 
						ThisObject, 
						"OperatingProcedureOfWorkCenterTypes",
						, 
						Cancel);
			
		ElsIf OperatingProcedureOfWorkCenterTypes = Enums.OperatingProcedureOfWorkCenterTypes.Simultaneously Then
			
			ValidationValues = Undefined;
			WorkingTimeIsSame = True;
			
			For Cnt = 1 To 2 Do
				
				For Each String In ?(Cnt = 1, ThisObject.WorkCenterTypes, ThisObject.AlternateWorkCenterTypes) Do
				
					If Not String.Use Then
						Continue;
					EndIf;
					
					If ValidationValues = Undefined Then
						
						ValidationValues = String;
						
					ElsIf String.OperationTime <> ValidationValues.OperationTime
						Or String.UnitOfMeasure <> ValidationValues.UnitOfMeasure Then
						
						WorkingTimeIsSame = False;
						Break;
						
					EndIf;
					
				EndDo;
				
				If Not WorkingTimeIsSame Then
					Break;
				EndIf;
				
			EndDo;
		
			If Not WorkingTimeIsSame Then
				
				MessageText = NStr("vi = 'Khi sử dụng dịch vụ cùng lúc, thứ tự tải lên, giờ làm việc của dạng trung tâm làm việc phải giống nhau.';
									|ru = 'При использовании порядка загрузки ""Одновременно"" время работы видов рабочих центров должно быть одинаковым.';
									|en = 'When using the ""Simultaneously"" load procedure, working time of work center types must be the same.'; fa = 'When using the ""Simultaneously"" load procedure, working time of work center types must be the same.';
									|it = 'Quando si utilizza la procedura di caricamento ""Simultaneamente"", le ore di lavoro dei tipi di centri di lavoro devono essere le stesse.';
									|pl = 'Podczas korzystania z trybu pobierania ""Jednocześnie"" czas pracy rodzajów centrów roboczych powinny być takie same.';
									|tr = '""Eş zamanlı"" yükleme düzeni kullanılırken, iş merkezi türlerinin çalışma süreleri aynı olmalıdır.'");
					
				CommonClientServer.MessageToUser(
					MessageText, 
					ThisObject, 
					"OperatingProcedureOfWorkCenterTypes",
					, 
					Cancel);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure PerformControlWhenClosingStage(Cancel)
	
	If Status <> Enums.StatusesOfProductionStages2_2.Completed
		Or (AdditionalProperties.DataBeforeChange <> Undefined
				And AdditionalProperties.DataBeforeChange.Attributes.Status = Enums.StatusesOfProductionStages2_2.Completed) Then
		Return;
	EndIf;
	
	ArrayOfTexts = New Array;
	ControlIndexes = New Map;
	
	If Constants.ControlOperationCompletionWhenClosingProductionStages.Get() Then
		
		QueryText = "
			|SELECT TOP 1
			|	TRUE
			|FROM
			|	InformationRegister.QueueOfProductionOperations AS Queue
			|WHERE
			|	Queue.Stage = &Ref
			|GROUP BY
			|	Queue.OperationID
			|HAVING
			|	SUM(Queue.Scheduled) > SUM(Queue.Completed2) + SUM(Queue.Skipped3) + SUM(Queue.DefectiveGoods)
			|
			|UNION ALL
			|
			|SELECT TOP 1
			|	TRUE
			|FROM
			|	Document.ProductionOperation2_2 AS DocOperation
			|WHERE
			|	DocOperation.Stage = &Ref
			|	AND DocOperation.Posted
			|	AND NOT DocOperation.BasedOnMasterData
			|	AND DocOperation.Status IN (
			|		VALUE(Enum.ProductionOperationStatuses.BeingGenerated),
			|		VALUE(Enum.ProductionOperationStatuses.CreatedOn_),
			|		VALUE(Enum.ProductionOperationStatuses.Running))
			|
			|UNION ALL
			|
			|SELECT
			|	TRUE
			|FROM
			|	(SELECT
			|		&TechProcessParameters
			|	FROM
			|		Document.ProductionStage2_2 AS DocStage
			|
			|		LEFT JOIN InformationRegister.TechnologicalProcessesOfProductionStages AS TechnicalProcess
			|		ON DocStage.Ref = TechnicalProcess.Stage
			|
			|	WHERE
			|		DocStage.Ref = &Ref
			|		AND DocStage.ProductionProcessType <> VALUE(Enum.ProductionProcessTypes.WithoutBillsOfMaterials)
			|		AND DocStage.Department.UseOperationManagement
			|		AND NOT DocStage.ProductionByThirdParty
			|	) AS NestedQuery
			|WHERE
			|	NestedQuery.ThereAreTechnologicalOperations
			|	AND NOT TRUE IN (
			|		SELECT TOP 1
			|			TRUE
			|		FROM
			|			InformationRegister.QueueOfProductionOperations AS Queue
			|		WHERE
			|			Queue.Stage = &Ref)
			|";
			
		QueryText = StrReplace(QueryText,
			"&TechProcessParameters",
			ProductionProcessEditor.QueryTextParametersOfTechnicalProcessOfStage("DocStage"));
			
		ArrayOfTexts.Add(QueryText);
		
		MessageText = StrTemplate(
			NStr("vi = 'Giao dịch chứng từ ""%1"" đã thực hiện chưa đầy đủ.
				|Chỉ có thể đóng công đoạn với các giao dịch đã thực hiện đầy đủ/đã bỏ qua.';
				|ru = 'Операции документа ""%1"" выполнены не полностью.
				|Закрытие этапа возможно только с полностью выполненными/пропущенными операциями.';
				|en = 'Not all operations of the %1 document are performed.
				|You can close the stage only with fully performed/skipped operations.'; fa = 'Not all operations of the %1 document are performed.
				|You can close the stage only with fully performed/skipped operations.';
				|it = 'Le operazioni del documento ""%1"" non sono state eseguite completamente. 
				| La chiusura della fase è possibile solamente a operazioni ultimate e/o abbandonate.';
				|pl = 'Operacje dokumentu ""%1"" nie są w pełni zakończone. 
				|Zamknięcie etapu jest możliwe tylko przy całkowicie zakończonych / pominiętych operacjach.';
				|tr = '""%1"" belgesinin işlemleri tümüyle gerçekleştirilmedi.
				|Aşama sadece tümüyle gerçekleştirilen/atlanan işlemlerle kapatılabilir.'"),
			Ref);
		ControlIndexes.Insert(ArrayOfTexts.UBound(), MessageText);
		
	Else
		
		ArrayOfTexts.Add(
			"SELECT TOP 1
			|	TRUE
			|FROM
			|	Document.ProductionOperation2_2 AS DocOperation
			|WHERE
			|	DocOperation.Stage = &Ref
			|	AND DocOperation.Posted
			|	AND DocOperation.Status IN (
			|		VALUE(Enum.ProductionOperationStatuses.BeingGenerated),
			|		VALUE(Enum.ProductionOperationStatuses.CreatedOn_),
			|		VALUE(Enum.ProductionOperationStatuses.Running))
			|");
		
		MessageText = StrTemplate(
			NStr("vi = 'Đối với chứng từ ""%1"" có giao dịch chưa hoàn thành.
				|Có thể đóng công đoạn sau khi chuyển tất cả giao dịch sang trạng thái tiếp theo: Đã thực hiện, Chưa thực hiện, Bỏ qua.';
				|ru = 'У документа ""%1"" имеются незавершенные операции.
				|Закрытие этапа возможно после перевода всех операций в следующие статусы: Выполнена, Не выполнена, Пропущена.';
				|en = 'The %1 document has unfinished operations.
				| You can close the stage only if all operations have the following statuses: Completed, Failed, Skipped.'; fa = 'The %1 document has unfinished operations.
				| You can close the stage only if all operations have the following statuses: Completed, Failed, Skipped.';
				|it = 'Il documento ""%1"" ha operazioni incomplete.
				| La chiusura della fase è possibile quando tutte le operazioni riportino uno dei seguenti stati: Completato, Non completato, Abbandonato.';
				|pl = 'Dokument ""%1"" ma niekompletne operacje. 
				|Możliwe jest zamknięcie etapu po przeniesieniu wszystkich operacji do następujących statusów: Zakończone, Niezakończone, Pominięte.';
				|tr = '""%1"" belgesinde tamamlanmamış işlemler mevcut.
				|Tüm işlemlerin aşağıdaki durumlara aktarılmasından sonra aşamanın kapatılması mümkündür: Gerçekleştirildi, Gerçekleştirilmedi, Atlandı.'"),
			Ref);
		ControlIndexes.Insert(ArrayOfTexts.UBound(), MessageText);
		
	EndIf;
	
	//

	ArrayOfTexts.Add(
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	InformationRegister.OperationsToCreateShiftTasks AS AssignedOperations
		|WHERE
		|	AssignedOperations.Stage = &Ref
		|	AND AssignedOperations.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef)");
	
	MessageText = StrTemplate(
		NStr("vi = 'Chứng từ ""%1"" có các hoạt động được gán cho các công việc theo ca mới nổi.';
			|ru = 'У документа ""%1"" имеются операции, назначенные формирующимся сменным заданиям.';
			|en = 'The %1 document has operations assigned for shift tasks being generated.'; fa = 'The %1 document has operations assigned for shift tasks being generated.';
			|it = 'Il documento ""%1"" presenta delle operazioni assegnate a compiti sostituibili in formazione.';
			|pl = 'Dokument ""%1"" ma operacje przypisane do pojawiających się zadań zmianowych.';
			|tr = '""%1"" belgesinde, düzenlenen vardiyalı görevlere atanan işlemler mevcuttur.'"),
		Ref);
	ControlIndexes.Insert(ArrayOfTexts.UBound(), MessageText);
	
	//
	
	Query = New Query(StrConcat(ArrayOfTexts, ";"));
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("StoreOperationsInBillsOfMaterials", GetFunctionalOption("StoreOperationsInBillsOfMaterials"));
	ResultsArray = Query.ExecuteBatch();
	
	For Each Control In ControlIndexes Do
		
		If ResultsArray[Control.Key].IsEmpty() Then
			Continue;
		Else
			CommonClientServer.MessageToUser(
				Control.Value, 
				ThisObject,,, 
				Cancel);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region FillingInServiceAttributes

Procedure FillInServiceDetails() Export
	
	FillInNumberByOrder();
	
	NumberForPrinting = ObjectsPrefixesClientServer.NumberForPrinting(Number);
	
	MainEntry_ = Documents.ProductionStage2_2.MainDocumentRegistryEntry(ThisObject);
	FillPropertyValues(ThisObject, MainEntry_);
	
	FillInMaximumProductionDate();
	FillInMaximumShipmentDate();
	FillInMaximumExpenseDate();
	
	If Not BatchGenerationIsPerformed() Then // the details are filled in separately in batch mode
		
		If PlanOperationsOfWorkCenterTypes Then
			
			ProductDataManagement.FillInUnitOfMeasurementAndDurationOfBBVStage(
				ThisObject,
				ThisObject.WorkCenterTypes.FindRows(New Structure("Use", True)),
				True);
			
		EndIf;
		
		FillInUserStageDetails();
		
		ProductionStage2_2Localization.FillInServiceDetails(ThisObject);
		
	EndIf;
	
	FillInFollowers();
	
EndProcedure

Procedure ClearUnusedData()
	
	If ProductionByThirdParty
		Or (Not ProductionManagementCached.TheProductionScheduleIsUsed()
			And Not DynamicStructure) Then
		PlanOperationsOfWorkCenterTypes = False;
	EndIf;
	
	If Not ProductionManagementCached.TheProductionScheduleIsUsed() Then
		StagePlacementInProductionSchedule = False;
	EndIf;
	
	If Not PlanOperationsOfWorkCenterTypes
		And Not StagePlacementInProductionSchedule Then
		WorkCenterTypes.Clear();
		AlternateWorkCenterTypes.Clear();
	EndIf;
	
	ActualStageStart = BegOfMinute(ActualStageStart);
	ActualStageEnd = BegOfMinute(ActualStageEnd);
	
	If StagePlacementInProductionSchedule Then
		PlanNotEarlierThan = Undefined;
	Else
		OccupancyOfWorkCenterTypes.Clear();
	EndIf;
	
	ThisIsAProductionIssueStage = ProductionManagementClientServer.ThisIsAProductionIssueStage(ThisObject);
	If Not ThisIsAProductionIssueStage Then
		ManufacturedProducts.Clear();
		MethodOfAllocatingFinishedProductCosts = Undefined;
	EndIf;
	
	If Not StageExecutionIsStarted() Then
		
		If Not DynamicStructure And (Not ProductionByThirdParty Or SubcontractOrder = Undefined) Then
			ProductionDate = '00010101';
		EndIf;
		
		ProductTableNames = ProductionManagementClientServer.ProductTableNames();
		For Each TableName In ProductTableNames Do
			For Each String In ThisObject[TableName] Do
				String.Manufactured = False;
				If Not DynamicStructure And (Not ProductionByThirdParty Or SubcontractOrder = Undefined) Then
					String.ProductionDate = '00010101';
				EndIf;
			EndDo;
		EndDo;
		
		For Each String In ThisObject.LaborCosts Do
			String.Completed2 = False;
			String.ExecutionDate = '00010101';
		EndDo;
		
		MaterialsAndWorksConsumption.Clear();
		UnusedMaterials.Clear();
		
	EndIf;
	
	If ItIsRequiredToPopulateByOperationsManually Then
		DepartmentData = ProductionServerCached.ProductionBusinessUnitDescription(Department);
		If DepartmentData.UseOperationManagement Then
			CheckedStatuses = Documents.ProductionStage2_2.StatusesOperationsAvailable(DepartmentData);
			If CheckedStatuses.Find(Status) = Undefined Then
				ItIsRequiredToPopulateByOperationsManually = False;
			EndIf;
		EndIf;
	EndIf;
	
	If ProductionByThirdParty Then
		
		MaterialsAndWorksConsumption.Clear();
		UnusedMaterials.Clear();
		LaborCosts.Clear();
		WorkCenterTypes.Clear();
		AlternateWorkCenterTypes.Clear();
		OccupancyOfWorkCenterTypes.Clear();
		
		IndexOf = InventoryOwnerAttributesMaterials.Count() - 1;
		While IndexOf >= 0 Do
			
			CurRow = InventoryOwnerAttributesMaterials[IndexOf];
			If Not CurRow.BusinessOperation =
								Enums.BusinessTransactions.MaterialTransferToProduction Then
				InventoryOwnerAttributesMaterials.Delete(CurRow);
			EndIf;
			
			IndexOf = IndexOf - 1;
		EndDo;
		
	Else
		
		SubcontractOrder = Undefined;
		
	EndIf;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ProductionStage2_2);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters.ManufacturedProducts);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters.SideAndIntermediateRelease);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters.MaterialsAndWorksConsumption);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters.UnusedMaterials);
	
EndProcedure

Procedure FillInNumberByOrder()
	
	If ValueIsFilled(Number) Then
		Return;
	EndIf;
	
	If ValueIsFilled(ReferenceOrder) Then
		
		Attributes = ProductionManagementCached.ProductionOrderData(ReferenceOrder);
		
		Number = ObjectsPrefixesClientServer.DeleteLeadingZerosFromObjectNumber(Attributes.Number);
		Number = TrimAll(Number);
		
		If Not ValueIsFilled(StartingLotNumber) Then
			StartingLotNumber = Catalogs.ProductionLots.ProductionBatchNumber(ProductionLot);
		EndIf;
		
		If Not ValueIsFilled(StartingLotStageNumber) Then
			StartingLotStageNumber = Documents.ProductionStage2_2.NewStageNumberInLaunchBatch(ProductionLot);
		EndIf;
		
	Else
		Number = "";
	EndIf;
	
	If ValueIsFilled(StartingLotNumber) And ValueIsFilled(StartingLotStageNumber) Then
		Number = Documents.ProductionStage2_2.DocumentNumber(Number, StartingLotNumber, StartingLotStageNumber);
	EndIf;
	
EndProcedure

Procedure FillInUserStageDetails()
	
	// In the tabular parts of <Output products>, <Side products>, the service details <This consumer> are stored,
	//  used to build the order structure.
	//
	// The details are filled in automatically, except for production orders created before version 2.4.6,
	//  for which separation by production stages is disabled.
	//
	// When forming the stages, the details are filled in in batches (transmitted via "specification data").
	
	Filter = New Structure("Canceled", False);
	NamesOfTS = New Array;
	NamesOfTS.Insert(0, "ManufacturedProducts");
	NamesOfTS.Insert(1, "SideAndIntermediateRelease");
	Products_1 = New ValueTable;
	Products_1.Columns.Add("TSIndex", New TypeDescription("Number"));
	Products_1.Columns.Add("RowIndex", New TypeDescription("Number"));
	Products_1.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	Products_1.Columns.Add("StageConsumer", New TypeDescription("DocumentRef.ProductionStage2_2"));
	Products_1.Columns.Add("ToExpenseAs", New TypeDescription("Boolean"));
	For TSIndex = 0 To NamesOfTS.UBound() Do
		FoundRows = TabularPartByName(NamesOfTS[TSIndex]).FindRows(Filter);
		For Each String In FoundRows Do
			NewRow = Products_1.Add();
			FillPropertyValues(NewRow, String);
			NewRow.TSIndex = TSIndex;
			NewRow.RowIndex = String.LineNumber - 1;
		EndDo;
	EndDo;
	
	Query = New Query(
	"SELECT
	|	Table.TSIndex AS TSIndex,
	|	Table.RowIndex AS RowIndex,
	|	Table.Purpose AS Purpose,
	|	Table.StageConsumer AS StageConsumer,
	|	Table.ToExpenseAs AS ToExpenseAs
	|INTO Products_1
	|FROM
	|	&Products_1 AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Products_1.TSIndex AS TSIndex,
	|	Products_1.RowIndex AS RowIndex,
	|	ISNULL(StagesOfDevelopment.Ref, VALUE(Document.ProductionStage2_2.EmptyRef)) AS StageConsumer
	|FROM
	|	Products_1 AS Products_1
	|	
	|		LEFT JOIN Document.ProductionStage2_2 AS StagesOfDevelopment
	|		 ON Products_1.Purpose = StagesOfDevelopment.Purpose
	|			AND NOT Products_1.ToExpenseAs
	|			AND Products_1.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|	
	|		INNER JOIN Document.ProductionOrder2_2 AS Orders
	|		 ON (TRUE)
	|WHERE
	|	Orders.Ref = &ReferenceOrder
	|	AND NOT Orders.DisabledAssignmentByProductionStageForIntermediateProducts
	|	AND Products_1.StageConsumer <> ISNULL(StagesOfDevelopment.Ref, VALUE(Document.ProductionStage2_2.EmptyRef))
	|");
	Query.SetParameter("ReferenceOrder", ReferenceOrder);
	Query.SetParameter("Products_1", Products_1);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	While Selection.Next() Do
		ThisObject[NamesOfTS[Selection.TSIndex]][Selection.RowIndex].StageConsumer = Selection.StageConsumer;
	EndDo;
	
EndProcedure

Procedure FillInFollowers() Export
	
	// The table part <Followers> stores two types
	//  - of links - links of type [0] are determined by the sequence of the production process, edited manually
	//  - connections of type [1] are determined by the stages-consumers of output products, are filled in automatically through the <Purpose> field in this procedure
	
	StageConnections = New Map;
	
	For Each String In ManufacturedProducts Do
		
		If Not String.Canceled And Not String.ToExpenseAs And Not String.StageConsumer.IsEmpty() And String.StageConsumer <> Ref Then
			StageConnections.Insert(String.StageConsumer);
		EndIf;
		
	EndDo;
	
	For Each String In SideAndIntermediateRelease Do
		
		If Not String.Canceled And Not String.ToExpenseAs And Not String.StageConsumer.IsEmpty() And String.StageConsumer <> Ref Then
			StageConnections.Insert(String.StageConsumer);
		EndIf;
		
	EndDo;
	
	For IndexOf = -Successors.Count() + 1 To 0 Do
		
		String = Successors[-IndexOf];
		
		If StageConnections[String.Stage] <> Undefined Then
			
			StageConnections.Delete(String.Stage);
			
		ElsIf String.LinkType = Documents.ProductionStage2_2.CommunicationTypeConsumer() Then
			
			Successors.Delete(-IndexOf);
			
		EndIf;
		
	EndDo;
	
	For Each Link In StageConnections Do
		
		NewRow = Successors.Add();
		NewRow.Stage     = Link.Key;
		NewRow.LinkType = Documents.ProductionStage2_2.CommunicationTypeConsumer();
		
	EndDo;
	
EndProcedure

Procedure FillInCacheOfMainVRC()
	
	If WorkCenterTypes.Count() > 0 And WorkCenterTypes[0].Use Then
		MainVRC = WorkCenterTypes[0].WorkCenterType;
	ElsIf AlternateWorkCenterTypes.Count() > 0 And AlternateWorkCenterTypes[0].Use Then
		MainVRC = AlternateWorkCenterTypes[0].WorkCenterType;
	EndIf;
	
EndProcedure

#EndRegion

#Region FillingInByBOM

Procedure FillInByBOM(SpecificationData, Data_Stage)
	
	FillInHeaderBySpecification(SpecificationData, Data_Stage);
	FillInMaterialsAndWorkAccordingToSpecification(SpecificationData, Data_Stage);
	FillOutputProductsAccordingToSpecification(SpecificationData, Data_Stage);
	FillByProductsAccordingToSpecification(SpecificationData, Data_Stage);
	FillInTypesOfWorkCentersBySpecification(SpecificationData, Data_Stage);
	FillLaborCostsBySpecification(SpecificationData, Data_Stage);
	FillFollowersBySpecification(SpecificationData);
	
	
EndProcedure

// Fills in the header according to the specification
//
// Parameters:
//  SpecificationData - See Catalogs.BillsOfMaterials.DataSpecificationConstructor
//  Data_Stage - ValueTableRow - 
//
Procedure FillInHeaderBySpecification(SpecificationData, Data_Stage)
	
	FillPropertyValues(ThisObject, Data_Stage,, "Partner");
	FillPropertyValues(ThisObject, SpecificationData, "BillOfMaterials, ProductionProcessType");
	
	If ValueIsFilled(Data_Stage.Partner)
		And TypeOf(Data_Stage.Partner) = Type("CatalogRef.Companies")
		And Data_Stage.Partner <> Organization Then
		
		If Not Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(Data_Stage.Partner, Organization) Then
			
			CheckStructure = Catalogs.Companies.CountriesOfRegistrationAndCurrenciesOfRegulatedAccountingCoincide(Data_Stage.Partner, Organization);
			
			If CheckStructure.CurrenciesDoNotMatch
				And CheckStructure.CountriesMatch Then
				MaterialProviderCompany = Organization;
				Organization = Data_Stage.Partner;
				InternalSubcontracting = True;
			Else
				
				If Not CheckStructure.CurrenciesDoNotMatch Then
					ErrorText =
						NStr("vi = '%1.
									|Tiền tệ kế toán tài chính của doanh nghiệp nhận gia công và doanh nghiệp đặt gia công không trùng nhau.
									|Công đoạn được tạo theo tên của doanh nghiệp trong đơn hàng sản xuất.';
									|ru = '%1.
									|Валюты регламентированного учета организации-переработчика и организации-давальца не совпадают.
									|Этап сформирован от имени организации заказа на производство.';
									|en = '%1.
									|Local accounting currencies of the subcontractor company and the material provider company are different.
									|The stage is generated on behalf of the production order company.'; fa = '%1.
									|Local accounting currencies of the subcontractor company and the material provider company are different.
									|The stage is generated on behalf of the production order company.';
									|it = '%1.
									|Валюты регламентированного учета организации-переработчика и организации-давальца не совпадают.
									|Этап сформирован от имени организации заказа на производство.';
									|pl = '%1.
									|Local accounting currencies of the subcontractor company and the material provider company are different.
									|The stage is generated on behalf of the production order company.';
									|tr = '%1.
									|Fason üretici  iş yerinin ve tedarikçi iş yerinin yerel muhasebe para birimleri aynı değildir.
									|Aşama, üretim emri iş yeri adına oluşturuldu.'");
					ErrorText = StrTemplate(ErrorText, Data_Stage.StagePresentation);
					Common.MessageToUser(ErrorText);
				EndIf;
				
				If Not CheckStructure.CountriesMatch Then
					ErrorText =
						NStr("vi = '%1.
									|Quốc gia đăng ký của doanh nghiệp nhận gia công và doanh nghiệp đặt gia công phải trùng nhau.
									|Công  đoạn được tạo theo tên của doanh nghiệp trong đơn hàng sản xuất.';
									|ru = '%1.
									|Страны регистрации организации-переработчика и организации-давальца должны совпадать.
									|Этап сформирован от имени организации заказа на производство.';
									|en = '%1.
									|Countries of residence of the subcontractor company and the material provider company must be the same.
									|The stage is generated on behalf of the production order company.'; fa = '%1.
									|Countries of residence of the subcontractor company and the material provider company must be the same.
									|The stage is generated on behalf of the production order company.';
									|it = '%1.
									|Страны регистрации организации-переработчика и организации-давальца должны совпадать.
									|Этап сформирован от имени организации заказа на производство.';
									|pl = '%1.
									|Countries of residence of the subcontractor company and the material provider company must be the same.
									|The stage is generated on behalf of the production order company.';
									|tr = '%1.
									|Fason üretici iş yerinin ve tedarikçi iş yerinin ikamet edilen ülkeleri aynı olmalıdır.
									|Aşama, üretim emri iş yeri adına oluşturuldu.'");
					ErrorText = StrTemplate(ErrorText, Data_Stage.StagePresentation);
					Common.MessageToUser(ErrorText);
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	StageName = Data_Stage.StagePresentation;
	
	NumberOfPackagesPlan = SpecificationData.MainProduct.NumberOfPackages;
	PackagePlan = SpecificationData.MainProduct.Package;
	PackageActualData = SpecificationData.MainProduct.Package;
	PackageCanceled = SpecificationData.MainProduct.Package;
	
	QuantityPerReleaseLotUnit = SpecificationData.MainProduct.NumberOfPackagesPerUnitOfProductionBatch
		* SpecificationData.MainProduct.PackageData.Numerator
		/ SpecificationData.MainProduct.PackageData.Denominator;
	
	If Data_Stage.Owner().Columns.Find("BOMStage") <> Undefined Then
		Stage = Data_Stage.BOMStage;
	EndIf;
	
	If PlanOperationsOfWorkCenterTypes
		And Not ProductionManagementCached.PlanningByProductionResourcesIsUsed()
		And Not DynamicStructure Then
		PlanOperationsOfWorkCenterTypes = False;
	EndIf;
	
	If ProductionManagementClientServer.ThisIsAProductionIssueStage(ThisObject) Then
		MethodOfAllocatingFinishedProductCosts = SpecificationData.MethodOfAllocatingFinishedProductCosts;
	EndIf;
	
	If ProductionByThirdParty Then
		
		Settings = ProductionServerCached.SubsystemSettingsProduction();
		If Not Settings.ProductionByThirdPartyIsUsed
				And Not Settings.UseSubcontractOrders2_5 Then
			ProductionByThirdParty = False;
		EndIf;
		
		If Not Settings.UseSubcontractOrders2_5 Then
			ProductionByThirdParty2_5 = False;
			LeaveProductsAtSubcontractor = False;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInMaterialsAndWorkAccordingToSpecification(SpecificationData, Data_Stage)
	
	TheStructureOfTheSearch = New Structure("Stage", Data_Stage.Stage);
	
	For Cnt = 1 To 2 Do
		
		TableName = ?(Cnt = 1, "IncomingProducts", "MaterialsAndServices");
		If SpecificationData[TableName].Count() = 0 Then
			Continue;
		EndIf;
		
		FoundRows = SpecificationData[TableName].FindRows(TheStructureOfTheSearch);
		For Each String In FoundRows Do
			NewRow = SupplyWithMaterialsAndWorks.Add();
			FillPropertyValues(NewRow, String);
			
			NewRow.LinkKeyBOM = String.ConnectionKey;
			NewRow.Department = String.StageSubdivision;
			
			If NotShipInInstallments Then
				NewRow.DateOfShipment = DateOfShipment;
			EndIf;
		EndDo;
		
	EndDo;
	
	If SpecificationData.Property("MaterialsAndWorksSets")
		And SpecificationData.MaterialsAndWorksSets.Count() > 0 Then
		
		FoundRows = SpecificationData.MaterialsAndWorksSets.Copy(TheStructureOfTheSearch);
		For Each String In FoundRows Do
			
			NewRow = MaterialsAndWorksSets.Add();
			FillPropertyValues(NewRow, String);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure FillOutputProductsAccordingToSpecification(SpecificationData, Data_Stage)
	
	If SpecificationData.ManufacturedProducts.Count() = 0 Then
		Return;
	EndIf;
	
	ArticlesToFillInSettings = New Array();
	
	FoundRows = SpecificationData.ManufacturedProducts.FindRows(New Structure("Stage", Data_Stage.Stage));
	For Each String In FoundRows Do
		
		NewRow = ManufacturedProducts.Add();
		FillPropertyValues(NewRow, String);
		
		NewRow.Department = String.StageSubdivision;
		
		If ProductionInOneDay Then
			NewRow.ProductionDate = ProductionDate;
		EndIf;
		
		If NewRow.ExpenseItem = Undefined Then
			NewRow.ExpenseItem = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
		ElsIf Not ValueIsFilled(NewRow.GLAccountSettings)
			And TypeOf(NewRow.ExpenseItem) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems")
			And ArticlesToFillInSettings.Find(NewRow.ExpenseItem) = Undefined Then
			ArticlesToFillInSettings.Add(NewRow.ExpenseItem);
		EndIf;
		
	EndDo;
	
	If ArticlesToFillInSettings.UBound() <> -1 Then
		FillInTheDefaultAccountSettings(ManufacturedProducts, ArticlesToFillInSettings);
	EndIf;
	
EndProcedure

Procedure FillByProductsAccordingToSpecification(SpecificationData, Data_Stage)
	
	If SpecificationData.RecyclableWaste.Count() = 0 Then
		Return;
	EndIf;
	
	ArticlesToFillInSettings = New Array();
	
	FoundRows = SpecificationData.RecyclableWaste.FindRows(New Structure("Stage", Data_Stage.Stage));
	For Each String In FoundRows Do
		
		NewRow = SideAndIntermediateRelease.Add();
		FillPropertyValues(NewRow, String);
		
		NewRow.Department = String.StageSubdivision;
		
		If ProductionInOneDay Then
			NewRow.ProductionDate = ProductionDate;
		EndIf;
		
		If NewRow.ExpenseItem = Undefined Then
			NewRow.ExpenseItem = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
		ElsIf Not ValueIsFilled(NewRow.GLAccountSettings)
			And TypeOf(NewRow.ExpenseItem) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems")
			And ArticlesToFillInSettings.Find(NewRow.ExpenseItem) = Undefined Then
			ArticlesToFillInSettings.Add(NewRow.ExpenseItem);
		EndIf;
		
		If InternalSubcontracting
			And ValueIsFilled(MaterialProviderCompany) Then
			NewRow.ProductOwner = MaterialProviderCompany;
		EndIf;
		
	EndDo;
	
	If ArticlesToFillInSettings.UBound() <> -1 Then
		FillInTheDefaultAccountSettings(SideAndIntermediateRelease, ArticlesToFillInSettings);
	EndIf;
	
EndProcedure

Procedure FillInTypesOfWorkCentersBySpecification(SpecificationData, Data_Stage)
	
	If Not SpecificationData.Property("WorkCenterTypes")
		Or SpecificationData.WorkCenterTypes.Count() = 0
		Or (Not ProductionManagementCached.PlanningByProductionResourcesIsUsed()
			And Not DynamicStructure) Then
		Return;
	EndIf;
	
	TheStructureOfTheSearch = New Structure("Stage", Data_Stage.Stage);
	
	For Cnt = 1 To 2 Do
		TableName = ?(Cnt = 1, "WorkCenterTypes", "AlternateWorkCenterTypes");
		If Not SpecificationData.Property(TableName) Then
			Return;
		EndIf;
		TabularSection = ThisObject[TableName]; // DocumentTabularSection.ProductionStage2_2.WorkCenterTypes
		
		If Cnt = 1 And SpecificationData.WorkCenterTypes.Columns.Find("Use") = Undefined Then
			DefaultValues = New Structure;
			DefaultValues.Insert("Use", True);
		Else
			DefaultValues = New Structure;
		EndIf;
		
		FoundRows = SpecificationData[TableName].FindRows(TheStructureOfTheSearch);
		For Each String In FoundRows Do
			
			NewRow = TabularSection.Add();
			
			FillPropertyValues(NewRow, String);
			FillPropertyValues(NewRow, DefaultValues);
			
			NewRow.OperationTimeStandard = String.OperatingTimePerBatchUnit;
			NewRow.LoadStandard = String.LoadingPerUnitOfLotReference;
			
		EndDo;
	EndDo;
	
EndProcedure

Procedure FillLaborCostsBySpecification(SpecificationData, Data_Stage)
	
	If SpecificationData.LaborCosts.Count() = 0 Then
		Return;
	EndIf;
	
	FoundRows = SpecificationData.LaborCosts.FindRows(New Structure("Stage", Data_Stage.Stage));
	For Each String In FoundRows Do
		
		NewRow = LaborCosts.Add();
		FillPropertyValues(NewRow, String);
		
		NewRow.Department = String.StageSubdivision;
		
	EndDo;
	
EndProcedure

Procedure FillFollowersBySpecification(SpecificationData)
	
	If Not ValueIsFilled(NextStageNo) Then
		Return;
	EndIf;
	
	TheStructureOfTheSearch = New Structure("StageNumber", NextStageNo);
	FoundRows = SpecificationData.Stages.FindRows(TheStructureOfTheSearch);
	
	For Each String In FoundRows Do
		NewRow = Successors.Add();
		NewRow.Stage     = String.ProductionStage;
		NewRow.LinkType = Documents.ProductionStage2_2.CommunicationTypeFollower();
	EndDo;
	
EndProcedure

Procedure FillInTheDefaultAccountSettings(TabularSection, ArticlesToFillInSettings)
	
	DefaultAccountSettings = GLAccountSettingsInternalServerCall.DefaultAccountSettingsData(ArticlesToFillInSettings);
	
	For Each TSRow In TabularSection Do
		If Not ValueIsFilled(TSRow.GLAccountSettings)
			And DefaultAccountSettings[TSRow.ExpenseItem] <> Undefined Then
			TSRow.GLAccountSettings = 
				GLAccountSettingsServer.NewAccountSettings_(DefaultAccountSettings[TSRow.ExpenseItem].ConfigurationData);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region FillingInOperations

#Region CommonActions

// Prepares operation data for filling in data
//
// Parameters:
//  OperationData_ - Structure - Contains:
//                    * ManufacturedProducts - ValueTable - Contains:
//                     ** ExecutionDate - Date -
//                    * BatchFinishedProducts - ValueTable - Contains:
//                     ** ExecutionDate - Date -
//                    * MaterialsAndWorks - ValueTable - Contains:
//                     ** ExecutionDate - Date -
//                    * LaborCosts - ValueTable - 
//
Procedure PrepareOperationDataForFillingInData(OperationData_)
	
	FromString = New TypeDescription("String",, New StringQualifiers(50));
	
	OperationData_.ManufacturedProducts.Columns.ExecutionDate.Name = "ProductionDate";
	OperationData_.ManufacturedProducts.Columns.Add("TSName", FromString);
	
	For Each String In OperationData_.ManufacturedProducts Do
		FoundRow = ManufacturedProducts.Find(String.Products, "Products");
		String.TSName = ?(FoundRow = Undefined, "SideAndIntermediateRelease", "ManufacturedProducts");
	EndDo;
	
	//
	
	OperationData_.BatchFinishedProducts.Columns.ExecutionDate.Name = "ProductionDate";
	OperationData_.BatchFinishedProducts.Columns.Add("TSName", FromString);
	
	For Each String In OperationData_.BatchFinishedProducts Do
		FoundRow = ManufacturedProducts.Find(String.Products, "Products");
		String.TSName = ?(FoundRow = Undefined, "SideAndIntermediateRelease", "ManufacturedProducts");
	EndDo;
	
	//
	
	OperationData_.MaterialsAndWorks.Columns.ExecutionDate.Name = "DateOfMaterialWorkConsumption";
	
EndProcedure

Procedure FillInHeaderAfterFillingInOperations()
	
	BatchData = Common.ObjectAttributesValues(
		ProductionLot,
		"MainProductProducts, MainProductCharacteristic");
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Products", BatchData.MainProductProducts);
	TheStructureOfTheSearch.Insert("Characteristic", BatchData.MainProductCharacteristic);
	
	ThereIsBatchProduct = False;
	
	PackagingFactPM = Undefined;
	QuantityOfTSParticles = 0;
	NumberOfPackagesPerTS = 0;
	
	If ProductionProcessType = Enums.ProductionProcessTypes.Disassembly Then
		 
		FoundRows = MaterialsAndWorksConsumption.FindRows(TheStructureOfTheSearch);
		If FoundRows.UBound() <> -1 Then
			
			ThereIsBatchProduct = True;
			For Each String In FoundRows Do
				
				If QuantityOfTSParticles = 0 Then
					PackagingFactPM = String.Package;
				ElsIf PackagingFactPM <> Undefined
					And PackagingFactPM <> String.Package Then
					PackagingFactPM = Undefined;
				EndIf;
				
				QuantityOfTSParticles = QuantityOfTSParticles + String.Count;
				NumberOfPackagesPerTS = NumberOfPackagesPerTS + String.NumberOfPackages;
				
			EndDo;
			
		ElsIf SupplyWithMaterialsAndWorks.FindRows(TheStructureOfTheSearch).UBound() <> -1 Then
			ThereIsBatchProduct = True;
		EndIf;
		
	Else
		
		For Cnt = 1 To 2 Do
			
			FoundRows = ThisObject[?(Cnt = 1, "ManufacturedProducts", "SideAndIntermediateRelease")].FindRows(TheStructureOfTheSearch);
			If FoundRows.UBound() <> -1 Then
			
				ThereIsBatchProduct = True;
				For Each String In FoundRows Do

					If String.Manufactured Then
						
						If QuantityOfTSParticles = 0 Then
							PackagingFactPM = String.Package;
						ElsIf PackagingFactPM <> Undefined
							And PackagingFactPM <> String.Package Then
							PackagingFactPM = Undefined;
						EndIf;
						
						QuantityOfTSParticles = QuantityOfTSParticles + String.Count;
						NumberOfPackagesPerTS = NumberOfPackagesPerTS + String.NumberOfPackages;
						
					EndIf;
					
				EndDo;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If ThereIsBatchProduct Then
		
		If QuantityOfTSParticles = 0 Then
			NumberOfPackagesReal = 0;
		Else
			
			If PackagingFactPM = Undefined Then
				
				// Conversion through basic units
				ZoomRatio = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(
					PackageActualData,
					BatchData.MainProductProducts);
				NumberOfPackagesReal = Round(QuantityOfTSParticles / ZoomRatio, 3);
			
			ElsIf PackagingFactPM <> PackageActualData Then
			
				// Recalculation via packages
				TSCoefficient = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(
					PackagingFactPM,
					BatchData.MainProductProducts);
				CapCoefficient = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(
					PackageActualData,
					BatchData.MainProductProducts);
				NumberOfPackagesReal =
					Round(NumberOfPackagesPerTS * TSCoefficient / CapCoefficient, 3);
			
			Else
				NumberOfPackagesReal = NumberOfPackagesPerTS;
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region StringOperations

Procedure VerifyNumberOfPMWithOperationData(OperationData_, OperationSearchStructure, NumberOfTS)
	
	FoundRows = OperationData_.FindRows(OperationSearchStructure);
		
	For Each LineOperation In FoundRows Do
		
		NumberOfCredits = Min(NumberOfTS, LineOperation.Count);
		
		LineOperation.Count = LineOperation.Count - NumberOfCredits;
		If LineOperation.Count = 0 Then
			OperationData_.Delete(LineOperation);
		EndIf;
		
		NumberOfTS = NumberOfTS - NumberOfCredits;
		If NumberOfTS = 0 Then
			Break;
		EndIf;
	
	EndDo;
	
EndProcedure

Procedure ReduceAmountExecutedInTSLine(TSName, TSRow, QuantityNotProduced, FlagNameProduced)
	
	If TSRow.Count = QuantityNotProduced Then
		
		TSRow[FlagNameProduced] = False;
		
		If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
			TSRow.Series = Catalogs.ItemsBatches.EmptyRef();
		EndIf;
		
	Else
		
		ExcludeColumns = ?(TSName = "LaborCosts",
			"RowCode, KeyWorkType",
			"RowCode, RowID, KeyProducts");
		
		NewRow = TabularPartByName(TSName).Add();
		
		FillPropertyValues(NewRow, TSRow,, ExcludeColumns);
		
		NewRow.Count = QuantityNotProduced;
		NewRow[FlagNameProduced] = False;
		
		If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
			NewRow.Series = Catalogs.ItemsBatches.EmptyRef();
		EndIf;
		
		TSRow.Count = TSRow.Count - QuantityNotProduced;
		
		If TSName = "ManufacturedProducts" Then
			
			ProductionClientServer.RecalculateFractionOfCostWhenSplittingRow(NewRow, TSRow, MethodOfAllocatingFinishedProductCosts);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure AddOperationDataToNotPerformedLine(TSName, OperationData, TheStructureOfTheSearch, FieldsNames)
	
	ExcludeColumns = ?(TSName = "LaborCosts",
		"RowCode, KeyWorkType",
		"RowCode, RowID, KeyProducts");
	
	FoundRows = ThisObject[TSName].FindRows(TheStructureOfTheSearch);
	
	For Each ReleaseString In FoundRows Do
		
		NumberOfCredits = Min(ReleaseString.Count, OperationData.Count);
		
		If NumberOfCredits = ReleaseString.Count Then
			
			ReleaseString[FieldsNames.FlagManufactured] = True;
			
			FillPropertyValues(ReleaseString, OperationData, FieldsNames.FillInByOperation);
			
		Else
			
			NewRow = ThisObject[TSName].Add();
			
			FillPropertyValues(NewRow, ReleaseString,, ExcludeColumns);
		
			NewRow.Count = NumberOfCredits;
			NewRow[FieldsNames.FlagManufactured] = True;
			
			FillPropertyValues(NewRow, OperationData, FieldsNames.FillInByOperation);
			
			ReleaseString.Count = ReleaseString.Count - NumberOfCredits;
			
			If TSName = "ManufacturedProducts" Then
				
				ProductionClientServer.RecalculateFractionOfCostWhenSplittingRow(NewRow, ReleaseString, MethodOfAllocatingFinishedProductCosts);
				
			EndIf;
			
		EndIf;
		
		OperationData.Count = OperationData.Count - NumberOfCredits;
		
		If OperationData.Count = 0 Then
			Break;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure AddOperationDataToPerformedLine(TSName, OperationData, TheStructureOfTheSearch, FieldsNames)
	
	FillPropertyValues(TheStructureOfTheSearch, OperationData);
	TheStructureOfTheSearch[FieldsNames.FlagManufactured] = True;
	
	FoundRows = ThisObject[TSName].FindRows(TheStructureOfTheSearch);
	
	If FoundRows.Count() > 0 Then
		
		FoundRows[0].Count = FoundRows[0].Count + OperationData.Count;
		
		OperationData.Count = 0;
		
	EndIf;
	
EndProcedure

Procedure FillInProductionDateForTS(TSName, DateTS, OneDate, FieldsNames)
	
	For Each String In ThisObject[TSName] Do
		
		ProcessString_ = Not FieldsNames.Property("FlagCanceled")
			Or Not String[FieldsNames.FlagCanceled];
		
		If ProcessString_ Then
			
			If ValueIsFilled(DateTS) Then
				
				If DateTS = String[FieldsNames.Date] Then
					Continue;
				Else
					OneDate = False;
					Break;
				EndIf;
				
			Else
				DateTS = String[FieldsNames.Date];
				OneDate = True;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region UsedMaterials

Procedure FillInMaterialsOnOperations(MaterialsOfOperations)
	
	// Reconciliation of a stage with operations
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Products");
	TheStructureOfTheSearch.Insert("Characteristic");
	TheStructureOfTheSearch.Insert("DateOfMaterialWorkConsumption");
	TheStructureOfTheSearch.Insert("Series");	
	TheStructureOfTheSearch.Insert("Department");
	
	LinesToRecalculateOfOperation = New Array;
	RowsToRecalculate_Expense = New Array;
	StructureOfActions = New Structure("RecalculateNumberOfPackages",
		BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfNumberOfPackages());
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	For IndexOf = -MaterialsAndWorksConsumption.Count()+1 To 0 Do
		
		String = MaterialsAndWorksConsumption[-IndexOf];
		Count = 0;
		FillPropertyValues(TheStructureOfTheSearch, String);
		
		For Each LineOperation In MaterialsOfOperations.FindRows(TheStructureOfTheSearch) Do
			
			NumberOfCredits = Min(String.Count - Count, LineOperation.Count);
			
			If NumberOfCredits = LineOperation.Count Then
				MaterialsOfOperations.Delete(LineOperation);
			Else
				LineOperation.Count = LineOperation.Count - NumberOfCredits;
				LinesToRecalculateOfOperation.Add(LineOperation);
			EndIf;
			
			Count = Count + NumberOfCredits;
			If Count = String.Count Then
				Break;
			EndIf;
			
		EndDo;
		
		If Count = 0 Then
			MaterialsAndWorksConsumption.Delete(String);
		ElsIf Count < String.Count Then
			String.Count = Count;
			RowsToRecalculate_Expense.Add(String);
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		LinesToRecalculateOfOperation,
		StructureOfActions,
		MaterialsOfOperations,
		CachedValues);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToRecalculate_Expense,
		StructureOfActions,
		MaterialsAndWorksConsumption,
		CachedValues);
	
	// Loading the remaining data
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Products");
	TheStructureOfTheSearch.Insert("Characteristic");
	TheStructureOfTheSearch.Insert("Department");
	TheStructureOfTheSearch.Insert("Canceled", False);
	
	ExpenseOfMaterialsAndWorksAdd = MaterialsAndWorksConsumption.UnloadColumns();
	
	For Each LineOperation In MaterialsOfOperations Do

		NewRow = ExpenseOfMaterialsAndWorksAdd.Add();
		FillPropertyValues(NewRow, LineOperation);
		
		If Not ValueIsFilled(NewRow.ProductCostElement) Then
			FillPropertyValues(TheStructureOfTheSearch, LineOperation);
			FoundRows = SupplyWithMaterialsAndWorks.FindRows(TheStructureOfTheSearch);
			If FoundRows.Count() > 0 Then
				NewRow.ProductCostElement = FoundRows[0].ProductCostElement;
			EndIf;
		EndIf;
		
	EndDo;
	
	If ExpenseOfMaterialsAndWorksAdd.Count() > 0 Then
		ProductionServer.CollapseValueTable(ExpenseOfMaterialsAndWorksAdd,,"NumberOfPackages,Count", True);
		TMCommonUse.AddRowsToTable(MaterialsAndWorksConsumption, ExpenseOfMaterialsAndWorksAdd);
	EndIf;
	
	FillInStatusesForSpecifyingVHFSeries("MaterialsAndWorksConsumption");
	
	// Filling in the expense date
	DateTS = '00010101';
	OneDate = False;
	
	FieldsNames = New Structure;
	
	FieldsNames.Insert("Date", "DateOfMaterialWorkConsumption");
	FillInProductionDateForTS("MaterialsAndWorksConsumption", DateTS, OneDate, FieldsNames);
	
	FieldsNames.Insert("Date", "DateOfTransaction");
	FillInProductionDateForTS("UnusedMaterials", DateTS, OneDate, FieldsNames);
	
	If OneDate Then
		DateOfMaterialWorkConsumption = DateTS;
	Else
		DateOfMaterialWorkConsumption = '00010101';
	EndIf;
	
	ConsumptionInOneDay = OneDate;
	
EndProcedure

#EndRegion

#Region OutputByProducts

Procedure FillOutArticlesOnOperations(TSName, ProductsTypes, ProductsOfThisSeries)

	// Loading of products	
	VerifyProductsWithTransactionData(TSName, ProductsTypes, ProductsOfThisSeries);
	UploadOperationDataToProducts(TSName, ProductsTypes);
	
	If TSName = "ManufacturedProducts" Then
		TSSeriesName = "BatchFinishedProducts";
	ElsIf TSName = "SideAndIntermediateRelease" Then
		TSSeriesName = "BatchSideAndIntermediateRelease";
	EndIf;
	
	// Loading Series	
	SeriesBeforeLoading = ThisObject[TSSeriesName].Unload();
	ThisObject[TSSeriesName].Clear();
	
	DownloadProductsFromSeries(TSName, ProductsOfThisSeries);
	RestoreSeriesToDownload(TSName, SeriesBeforeLoading);
	FillInStatusesForSpecifyingVHFSeries(TSName);
	RecalculateStatuses = MoveSeriesToProductTable(TSName);
	
	// Actions after loading 
	If TSName = "SideAndIntermediateRelease" Then
		Documents.ProductionStage2_2.FillInPricesByPriceKind(ThisObject);
	EndIf;
	
	TableCopy_ = ThisObject[TSName].Unload(); //ValueTable
	TableCopy_.Columns.Add("ShopFloorStockroom", New TypeDescription("Boolean"));
	TableCopy_.Columns.Add("MustBeRoundOff", New TypeDescription("Boolean"));
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages",
		BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfNumberOfPackages());
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	BatchProcessingOfTablePartServer.TreatTS(TableCopy_, StructureOfActions, CachedValues);
	
	ActionStructureRounding = New Structure;
	ActionStructureRounding.Insert("FillInShopPantryAttribute", New Structure("WarehouseFieldName", "Recipient"));
	ActionStructureRounding.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	BatchProcessingOfTablePartServer.TreatTS(TableCopy_, ActionStructureRounding, CachedValues);
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Products");
	TheStructureOfTheSearch.Insert("Characteristic");
	TheStructureOfTheSearch.Insert("Recipient");
	TheStructureOfTheSearch.Insert("Purpose");
	TheStructureOfTheSearch.Insert("ProductionDate");
	TheStructureOfTheSearch.Insert("Manufactured");
	TheStructureOfTheSearch.Insert("Department");
	If TSName = "SideAndIntermediateRelease" Then
		TheStructureOfTheSearch.Insert("ProductOwner");
	EndIf;
	
	For IndexOf = 0 To ThisObject[TSName].Count() - 1 Do
		
		String = ThisObject[TSName][IndexOf];
		LineCopy = TableCopy_[IndexOf];
		
		If String.Count <> LineCopy.Count Then
			
			FillPropertyValues(TheStructureOfTheSearch, String);
			
			For Each RowSeries In ThisObject[TSSeriesName].FindRows(TheStructureOfTheSearch) Do  
				RowSeries.Count = Round(RowSeries.Count);
				RecalculateStatuses = True;
			EndDo;
			
		EndIf;
		
		FillPropertyValues(String, LineCopy, "Count, NumberOfPackages");
		
	EndDo;
	
	If RecalculateStatuses Then
		FillInStatusesForSpecifyingVHFSeries(TSName);
	EndIf;
	
EndProcedure

Procedure VerifyProductsWithTransactionData(TSName, ProductsTypes, ProductsOfThisSeries)
	
	For Each String In ThisObject[TSName] Do
		
		If Not String.Manufactured Or String.Canceled Then
			Continue;
		EndIf;
		
		CountBalance = String.Count;
		
		VerifyIssueWithTransactionData(String, CountBalance, ProductsTypes, ProductsOfThisSeries);
		
		If CountBalance > 0 Then
			
			ReduceAmountExecutedInTSLine(TSName, String, CountBalance, "Manufactured");
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure VerifyIssueWithTransactionData(ReleaseString, QuantityRelease, ProductsTypes, ProductsOfThisSeries)
	
	TheStructureOfTheSearch = New Structure("Products, Characteristic, ProductionDate, Department");
	FillPropertyValues(TheStructureOfTheSearch, ReleaseString);
	
	FoundRows = ProductsTypes.FindRows(TheStructureOfTheSearch);
		
	For Each LineOperation In FoundRows Do
		
		NumberOfCredits = Min(QuantityRelease, LineOperation.Count);
		
		SeriesAreReconciled = (ReleaseString.Series = LineOperation.Series)
			Or VerifyReleaseSeriesWithTransactionData(ReleaseString, ProductsOfThisSeries, NumberOfCredits);
		If Not SeriesAreReconciled Then
			Continue;
		EndIf;
		
		LineOperation.Count = LineOperation.Count - NumberOfCredits;
		If LineOperation.Count = 0 Then
			ProductsTypes.Delete(LineOperation);
		EndIf;
		
		QuantityRelease = QuantityRelease - NumberOfCredits;
		If QuantityRelease = 0 Then
			Break;
		EndIf;
	
	EndDo;
	
EndProcedure

Function VerifyReleaseSeriesWithTransactionData(ReleaseString, ProductsOfThisSeries, Val QuantityRelease)
	
	If ValueIsFilled(ReleaseString.Series) Then
		
		TheStructureOfTheSearch = New Structure("Products, Characteristic, ProductionDate, Series, Department");
		FillPropertyValues(TheStructureOfTheSearch, ReleaseString);
		
		FoundRows = ProductsOfThisSeries.FindRows(TheStructureOfTheSearch);
		
		Count = 0;
		For Each String In FoundRows Do
			Count = Count + String.Count;
		EndDo;
		
		If Count >= QuantityRelease Then
			
			SeriesAreReconciled = True;
			
			For Each String In FoundRows Do
				
				NumberOfCredits = Min(QuantityRelease, String.Count);
				
				String.Count = String.Count - NumberOfCredits;
				If String.Count = 0 Then
					ProductsOfThisSeries.Delete(String);
				EndIf;
				
				QuantityRelease = QuantityRelease - NumberOfCredits;
				If QuantityRelease = 0 Then
					Break;
				EndIf;
				
			EndDo;
			
		Else
			
			SeriesAreReconciled = False;
			
		EndIf;
		
	Else
		
		SeriesAreReconciled = True;
		
	EndIf;
	
	Return SeriesAreReconciled;
	
EndFunction

Procedure UploadOperationDataToProducts(TSName, ProductsTypes)
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();

	CurRowStructure = TMCommonUse.StructureWithMetadataObjectProperties(
									Metadata.Documents.ProductionStage2_2.TabularSections[TSName]);

	CurRowStructure.Insert("ShopFloorStockroom");
	CurRowStructure.Insert("MustBeRoundOff");
	
	CostAllocationParameters = Documents.ProductionStage2_2.CostAllocationParameters(ThisObject);
	
	PurposeOfTollRelease = Undefined;
	If BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
		Or False Then
		PurposeOfTollRelease = Documents.ProductionStage2_2.DefaultAssignmentForByProducts(ReferenceOrder);
	EndIf;
	
	ReadyForProcessing_ = New Array;
	
	FieldsNames = New Structure;
	FieldsNames.Insert("FlagManufactured", "Manufactured");
	FieldsNames.Insert("FillInByOperation", "ProductionDate, Series");
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Canceled", False);
	TheStructureOfTheSearch.Insert("Manufactured", False);
	
	For Each String In ProductsTypes Do
		
		If Not String.TSName = TSName Then
			Continue;
		EndIf;
		
		TheStructureOfTheSearch.Insert("Products", String.Products);
		TheStructureOfTheSearch.Insert("Characteristic", String.Characteristic);
		TheStructureOfTheSearch.Insert("Department", String.Department);
		
		AddOperationDataToNotPerformedLine(
			TSName, String, TheStructureOfTheSearch, FieldsNames);
		
		If String.Count > 0 Then
			NewRow = TabularPartByName(TSName).Add();
			FillPropertyValues(NewRow, String);
			NewRow.Manufactured = True;
			
			ReadyForProcessing_.Add(NewRow);
		EndIf;
		
	EndDo;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("CheckFillAssignment", PurposeOfTollRelease);
	If TSName = "ManufacturedProducts" Then
		StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
	EndIf;
	
	ActionParameters = New Structure("Department, WarehouseFieldName", Undefined, "Recipient");
	StructureOfActions.Insert("CheckFillProductionWarehouse" , ActionParameters);
	
	ProductionManagementClientServer.AddQualityControlActionsToStructure(TSName, StructureOfActions, QualityControl.DataCacheOfMechanism(ThisObject));
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ReadyForProcessing_,
		StructureOfActions,
		TabularPartByName(TSName));
	
EndProcedure

Procedure DownloadProductsFromSeries(TSName, ProductsOfThisSeries)
	
	If ProductsOfThisSeries.Count() = 0 Then
		Return;
	EndIf;
	
	If TSName = "ManufacturedProducts" Then
		
		TSSeriesName = "BatchFinishedProducts";
		
		ProductItemTable = ThisObject[TSName].Unload(
			New Structure("Manufactured, Canceled", True, False),
			"Products, Characteristic, ProductionDate, Recipient, Purpose, Department, Count");
		
		ProductItemTable.GroupBy(
			"Products, Characteristic, ProductionDate, Recipient, Purpose, Department", "Count");
	
	ElsIf TSName = "SideAndIntermediateRelease" Then
		
		TSSeriesName = "BatchSideAndIntermediateRelease";
		
		ProductItemTable = ThisObject[TSName].Unload(
			New Structure("Manufactured, Canceled", True, False),
			"Products, Characteristic, ProductionDate, Recipient, Purpose, Department, ProductOwner, Count");
		
		ProductItemTable.GroupBy(
			"Products, Characteristic, ProductionDate, Recipient, Purpose, Department, ProductOwner", "Count");
		
	EndIf;
	
	TheStructureOfTheSearch = New Structure("Products, Characteristic, ProductionDate, Department");
	
	For Each RowSeries In ProductsOfThisSeries Do
		
		FillPropertyValues(TheStructureOfTheSearch, RowSeries);
		
		FoundRows = ProductItemTable.FindRows(TheStructureOfTheSearch);
		
		For Each ProductLine In FoundRows Do
			
			Count = Min(RowSeries.Count, ProductLine.Count);
			
			NewRow = ThisObject[TSSeriesName].Add();
			
			FillPropertyValues(NewRow, RowSeries);
			
			If TSName = "SideAndIntermediateRelease" Then
				FillPropertyValues(NewRow, ProductLine, "Recipient, Purpose, ProductOwner");
			Else
				FillPropertyValues(NewRow, ProductLine, "Recipient, Purpose");
			EndIf;
			
			NewRow.Count = Count;
			NewRow.Manufactured = True;
			
			ProductLine.Count = ProductLine.Count - Count;
			If ProductLine.Count = 0 Then
				ProductItemTable.Delete(ProductLine);
			EndIf;
			
			RowSeries.Count = RowSeries.Count - Count;
			If RowSeries.Count = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure RestoreSeriesToDownload(TSName, SeriesBeforeLoading)
	
	ExcludeSeriesLoadedFromOperations(TSName, SeriesBeforeLoading);
	
	If SeriesBeforeLoading.Count() = 0 Then
		Return;
	EndIf;
	
	If TSName = "ManufacturedProducts" Then
		TSSeriesName = "BatchFinishedProducts";
		Dimensions = "Products, Characteristic, ProductionDate, Recipient, Purpose, Department";
	ElsIf TSName = "SideAndIntermediateRelease" Then
		TSSeriesName = "BatchSideAndIntermediateRelease";
		Dimensions = "Products, Characteristic, ProductionDate, Recipient, Purpose, Department, ProductOwner";
	EndIf;
	
	SeriesBeforeLoading.FillValues(False, "Manufactured");
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Manufactured", False);
	FilterStructure1.Insert("Canceled", False);
	FilterStructure1.Insert("Series", Catalogs.ItemsBatches.EmptyRef());
	
	ProductItemTable = TabularPartByName(TSName).Unload(
		FilterStructure1,
		Dimensions + ", Count");
	
	ProductItemTable.GroupBy(Dimensions, "Count");
	
	TheStructureOfTheSearch = New Structure(Dimensions);
	
	For Each String In ProductItemTable Do
		
		NumberOfSeries_ = 0;
		FillPropertyValues(TheStructureOfTheSearch, String);
		SeriesLines = SeriesBeforeLoading.FindRows(TheStructureOfTheSearch);
		
		For Each StringSeries In SeriesLines Do
			NumberOfSeries_ = NumberOfSeries_ + StringSeries.Count;
		EndDo;
		
		If String.Count = NumberOfSeries_ Then
			
			For Each StringSeries In SeriesLines Do
				
				FillPropertyValues(
					TabularPartByName(TSSeriesName).Add(),
					StringSeries);
					
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ExcludeSeriesLoadedFromOperations(TSName, SeriesBeforeLoading)
	
	If SeriesBeforeLoading.Count() = 0 Then
		Return;
	EndIf;
	
	If TSName = "ManufacturedProducts" Then
		TSSeriesName = "BatchFinishedProducts";
	ElsIf TSName = "SideAndIntermediateRelease" Then
		TSSeriesName = "BatchSideAndIntermediateRelease";
	EndIf;
	
	For Each String In ThisObject[TSSeriesName] Do
		
		If Not String.Manufactured Or String.Count = 0 Then
			Continue;
		EndIf;
		
		CountExclude = String.Count;
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("Products");
		TheStructureOfTheSearch.Insert("Characteristic");
		TheStructureOfTheSearch.Insert("Recipient");
		TheStructureOfTheSearch.Insert("Purpose");
		TheStructureOfTheSearch.Insert("Department");
		TheStructureOfTheSearch.Insert("Series");
		TheStructureOfTheSearch.Insert("ProductionDate");
		TheStructureOfTheSearch.Insert("Manufactured", True);
		
		If TSName = "SideAndIntermediateRelease" Then
			TheStructureOfTheSearch.Insert("ProductOwner");
		EndIf;
		
		For Cnt = 1 To 2 Do
			
			If Cnt = 2 Then
				TheStructureOfTheSearch.Delete("ProductionDate");
				TheStructureOfTheSearch.Insert("Manufactured", False);
			EndIf;
			
			FillPropertyValues(TheStructureOfTheSearch, String, , "Manufactured");
			LinesBeforeChange_ = SeriesBeforeLoading.FindRows(TheStructureOfTheSearch);
		
			For Each LineBeforeChange In LinesBeforeChange_ Do
				
				If CountExclude >= LineBeforeChange.Count Then
					
					CountExclude = CountExclude - LineBeforeChange.Count;
					SeriesBeforeLoading.Delete(LineBeforeChange);
					
				Else
					
					LineBeforeChange.Count = LineBeforeChange.Count - CountExclude;
					CountExclude = 0;
					
				EndIf;
			
				If CountExclude = 0 Then
					Break;
				EndIf;
				
			EndDo;
			
			If CountExclude = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Function MoveSeriesToProductTable(TSName)
	
	RecalculateStatuses = False;
	StatusOfSeriesInCurTS = 13;
	
	If TSName = "ManufacturedProducts" Then
		TSSeriesName = "BatchFinishedProducts";
		TheStructureOfTheSearch = New Structure(
			"Products, Characteristic, ProductionDate, Recipient, Purpose, Manufactured, Department");
	ElsIf TSName = "SideAndIntermediateRelease" Then
		TSSeriesName = "BatchSideAndIntermediateRelease";
		TheStructureOfTheSearch = New Structure(
			"Products, Characteristic, ProductionDate, Recipient, Purpose, Manufactured, Department, ProductOwner");
	EndIf;
	
	ExcludeColumns = "RowCode, RowID, KeyProducts";
	
	For Each String In ThisObject[TSName] Do
		
		If Not String.Manufactured
			Or String.Canceled
			Or String.BatchesIndicationStatus <> StatusOfSeriesInCurTS
			Or ValueIsFilled(String.Series) Then
			Continue;
		EndIf;
		
		RecalculateStatuses = True;
		
		FillPropertyValues(TheStructureOfTheSearch, String);
		FoundRows = ThisObject[TSSeriesName].FindRows(TheStructureOfTheSearch);
		
		For Each RowSeries In FoundRows Do
				
			NumberOfCredits = Min(String.Count, RowSeries.Count);
			
			If String.Count = NumberOfCredits Then
				
				String.Series = RowSeries.Series;
				
			Else
			
				NewRow = ThisObject[TSName].Add();
				FillPropertyValues(NewRow, String,, ExcludeColumns);
				
				NewRow.Count = NumberOfCredits;
				NewRow.Series = RowSeries.Series;
				
				String.Count = String.Count - NumberOfCredits;
				
				If TSName = "ManufacturedProducts" Then
					
					ProductionClientServer.RecalculateFractionOfCostWhenSplittingRow(NewRow, String, MethodOfAllocatingFinishedProductCosts);
					
				EndIf;
				
			EndIf;
			
			If RowSeries.Count = NumberOfCredits Then
				
				ThisObject[TSSeriesName].Delete(RowSeries);
				
			Else
				
				RowSeries.Count = RowSeries.Count - NumberOfCredits;
				
			EndIf;
			
			If ValueIsFilled(String.Series) Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return RecalculateStatuses;
	
EndFunction

Procedure FillInProductionDateInHeader()
	
	DateTS = '00010101';
	OneDate = False;
	
	FieldsNames = New Structure;
	FieldsNames.Insert("Date", "ProductionDate");
	FieldsNames.Insert("FlagCanceled", "Canceled");
	
	FillInProductionDateForTS("ManufacturedProducts", DateTS, OneDate, FieldsNames);
	FillInProductionDateForTS("SideAndIntermediateRelease", DateTS, OneDate, FieldsNames);
	
	If OneDate Then
		ProductionDate = DateTS;
	Else
		ProductionDate = '00010101';
	EndIf;
	
	ProductionInOneDay = OneDate;
	
EndProcedure

#EndRegion

#Region LaborrCosts

Procedure FillInLaborCostsForOperations(LaborCostsOfOperations)
	
	// Reconciliation
	For Each String In LaborCosts Do
		
		If Not String.Completed2 Or String.Canceled Then
			Continue;
		EndIf;
		
		CountBalance = String.Count;
		
		TheStructureOfTheSearch = New Structure("WorkKind, Performer, WorkAssignment, ExecutionDate, Department");
		FillPropertyValues(TheStructureOfTheSearch, String);
		VerifyNumberOfPMWithOperationData(LaborCostsOfOperations, TheStructureOfTheSearch, CountBalance);
		
		If CountBalance > 0 Then
			ReduceAmountExecutedInTSLine("LaborCosts", String, CountBalance, "Completed2");
		EndIf;
		
	EndDo;
	
	// Load
	For Each String In LaborCostsOfOperations Do
		
		FieldsNames = New Structure;
		FieldsNames.Insert("FlagManufactured", "Completed2");
		FieldsNames.Insert("FillInByOperation", "ExecutionDate, Performer, WorkAssignment");
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("WorkKind", String.WorkKind);
		TheStructureOfTheSearch.Insert("Department", String.Department);
		TheStructureOfTheSearch.Insert("Completed2", False);
		TheStructureOfTheSearch.Insert("Canceled", False);
		
		AddOperationDataToNotPerformedLine(
			"LaborCosts", String, TheStructureOfTheSearch, FieldsNames);
		
		If String.Count > 0 Then
				
			SearchStructureProduced = New Structure(
				"WorkKind, Performer, WorkAssignment, ExecutionDate, Completed2, Department");
				
			AddOperationDataToPerformedLine(
				"LaborCosts", String, SearchStructureProduced, FieldsNames);
			
		EndIf;
		
		If String.Count > 0 Then
			
			NewRow = ThisObject.LaborCosts.Add();
			FillPropertyValues(NewRow, String);
			NewRow.Completed2 = True;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region FillingStockTypes

Procedure FillStockTypes(Cancel)
	
	If ProductionByThirdParty
		And Not ProductionByThirdParty2_5 Then
		
		InventoryOwnerAttributesMaterials.Clear();
		InventoryOwnerAttributesProducts.Clear();
		
		Return;
		
	EndIf;
	
	SetPrivilegedMode(True);
	
	TempTablesManager = TemporaryDocumentDataTables();
	
	PeriodFromWhichYouNeedToRecalculateTypesOfStocks(TempTablesManager);
	
	If AdditionalProperties.PeriodFromWhichYouNeedToRecalculateTypesOfStocks = InventoriesServer.DateOfCurrentBalances() Then
		Return;
	EndIf;
	
	TableTypesOfInventoryItems = TableToFillInTypesOfProductStocks(TempTablesManager);
	InventoriesServer.FillStockTypesByDefault(TempTablesManager, TableTypesOfInventoryItems);
	FillInInventoryTypesOfProduct(TempTablesManager, TableTypesOfInventoryItems);
	
	ParametersForFillingInventoryTypes = ParametersForFillingInventoryTypes("InventoryOwnerAttributesMaterials");
	TemporaryTablesToFillInInventoryTypesMaterials(TempTablesManager);

	InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject, TempTablesManager, Cancel, ParametersForFillingInventoryTypes);
	
	FillInAdditionalColumnsInventoryTypesMaterials(TempTablesManager, ParametersForFillingInventoryTypes, Cancel);
	
	If Not Cancel Then
		TSRow = "InventoryOwnerAttributesProducts,InventoryOwnerAttributesMaterials";
		TMCommonUse.FillInDocumentIDs(ThisObject, TSRow);
	EndIf;
	
EndProcedure

Procedure FillInAdditionalColumnsInventoryTypesMaterials(TempTablesManager, ParametersForFillingInventoryTypes, Cancel)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	NestedQuery.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	NestedQuery.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|	NestedQuery.CorAnalyticsAccountingProductsToFillIn	AS CorAnalyticsAccountingProductsToFillIn,
	|	SUM(NestedQuery.Count)				AS Count,
	|	NestedQuery.BusinessOperation			AS BusinessOperation,
	|	NestedQuery.Period							AS Period,
	|	NestedQuery.DateOfTransaction					AS DateOfTransaction,
	|	NestedQuery.ToExpenseAs				AS ToExpenseAs,
	|	NestedQuery.Recipient						AS Recipient,
	|	NestedQuery.ExpenseItem					AS ExpenseItem,
	|	NestedQuery.DimensionOfExpenses				AS DimensionOfExpenses,
	|	NestedQuery.AssetsLiabilitiesDimension		AS AssetsLiabilitiesDimension,
	|	NestedQuery.GLAccountSettings			AS GLAccountSettings,
	|	NestedQuery.RowID				AS RowID,
	|	NestedQuery.Order							AS Order,
	|	NestedQuery.Department					AS Department,
	|	NestedQuery.ItemsLocationAttributes.Products   AS Products,
	|	NestedQuery.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	NestedQuery.ItemsLocationAttributes.Series          AS Series,
	|	ISNULL(NestedQuery.CorAnalyticsAccountingProductsToFillIn.Purpose.AssignmentType,
	|		VALUE(Enum.AssignmentTypes.EmptyRef))   AS TypeOfDestinationCor,
	|	NestedQuery.CorAnalyticsAccountingProductsToFillIn.StorageLocation AS BoxStorageLocation
	|FROM
	|	(SELECT
	|		1														AS Order,
	|		ConsumptionAndArrivalInStorerooms.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|		ConsumptionAndArrivalInStorerooms.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|		ConsumptionAndArrivalInStorerooms.CorItemsLocationAttributes	AS CorAnalyticsAccountingProductsToFillIn,
	|		CASE
	|			WHEN ConsumptionAndArrivalInStorerooms.Count > 0
	|				THEN ConsumptionAndArrivalInStorerooms.Count
	|			ELSE -ConsumptionAndArrivalInStorerooms.Count
	|		END													AS Count,
	|		ConsumptionAndArrivalInStorerooms.BusinessOperation			AS BusinessOperation,
	|		ConsumptionAndArrivalInStorerooms.Period							AS Period,
	|		ConsumptionAndArrivalInStorerooms.DateOfTransaction						AS DateOfTransaction,
	|		FALSE													AS ToExpenseAs,
	|		VALUE(Catalog.BusinessStructure.EmptyRef)	AS Recipient,
	|		UNDEFINED											AS ExpenseItem,
	|		UNDEFINED											AS DimensionOfExpenses,
	|		UNDEFINED											AS AssetsLiabilitiesDimension,
	|		UNDEFINED											AS GLAccountSettings,
	|		""""													AS RowID,
	|		ConsumptionAndArrivalInStorerooms.Department					AS Department
	|	FROM
	|		ConsumptionAndArrivalInStorerooms AS ConsumptionAndArrivalInStorerooms
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		1														AS Order,
	|		Software_3.ItemsLocationAttributes			AS ItemsLocationAttributes,
	|		Software_3.CorItemsLocationAttributes		AS CorItemsLocationAttributes,
	|		Software_3.CorItemsLocationAttributes		AS CorAnalyticsAccountingProductsToFillIn,
	|		Software_3.Count							AS Count,
	|		&BusinessTransactionSupply									AS BusinessOperation,
	|		Software_3.Period								AS Period,
	|		Software_3.DateOfShipment							AS DateOfTransaction,
	|		FALSE													AS ToExpenseAs,
	|		VALUE(Catalog.BusinessStructure.EmptyRef)	AS Recipient,
	|		UNDEFINED											AS ExpenseItem,
	|		UNDEFINED											AS DimensionOfExpenses,
	|		UNDEFINED											AS AssetsLiabilitiesDimension,
	|		UNDEFINED											AS GLAccountSettings,
	|		""""													AS RowID,
	|		Software_3.Department						AS Department
	|	FROM
	|		SupplyWithMaterialsAndWorks AS Software_3
	|			INNER JOIN Catalog.Products AS CatalogProducts
	|			ON Software_3.Products = CatalogProducts.Ref
	|	
	|	WHERE
	|		NOT Software_3.Canceled
	|		AND Software_3.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|		AND &UseTraceableImportedGoodsAccounting
	|		AND CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND CatalogProducts.TracedGoods
	|		AND Software_3.Period >= &PeriodFromWhichYouNeedToRecalculateTypesOfStocks
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		2																	AS Order,
	|		UnusedMaterials.ItemsLocationAttributes						AS ItemsLocationAttributes,
	|		VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)	AS CorItemsLocationAttributes,
	|		VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)	AS CorAnalyticsAccountingProductsToFillIn,
	|		UnusedMaterials.Count										AS Count,
	|		&BusinessTransactionEconomy												AS BusinessOperation,
	|		UnusedMaterials.Period											AS Period,
	|		UnusedMaterials.DateOfTransaction										AS DateOfTransaction,
	|		UnusedMaterials.ToExpenseAs									AS ToExpenseAs,
	|		UnusedMaterials.Recipient										AS Recipient,
	|		UnusedMaterials.ExpenseItem									AS ExpenseItem,
	|		UnusedMaterials.DimensionOfExpenses								AS DimensionOfExpenses,
	|		UnusedMaterials.AssetsLiabilitiesDimension							AS AssetsLiabilitiesDimension,
	|		UnusedMaterials.GLAccountSettings								AS GLAccountSettings,
	|		UnusedMaterials.RowID								AS RowID,
	|		UnusedMaterials.Department									AS Department
	|	FROM
	|		UnusedMaterials AS UnusedMaterials
	|	
	|	WHERE
	|		UnusedMaterials.Period >= &PeriodFromWhichYouNeedToRecalculateTypesOfStocks
	|		AND UnusedMaterials.ToExpenseAs
	|		AND NOT &ProductionByThirdParty2_5
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		2																	AS Order,
	|		MaterialsAndWorksConsumption.ItemsLocationAttributes					AS ItemsLocationAttributes,
	|		VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)	AS CorItemsLocationAttributes,
	|		MaterialsAndWorksConsumption.CorItemsLocationAttributes				AS CorAnalyticsAccountingProductsToFillIn,
	|		MaterialsAndWorksConsumption.Count									AS Count,
	|		&BusinessTransactionExpense													AS BusinessOperation,
	|		MaterialsAndWorksConsumption.Period										AS Period,
	|		MaterialsAndWorksConsumption.DateOfMaterialWorkConsumption									AS DateOfTransaction,
	|		FALSE																AS ToExpenseAs,
	|		VALUE(Catalog.BusinessStructure.EmptyRef)				AS Recipient,
	|		UNDEFINED														AS ExpenseItem,
	|		UNDEFINED														AS DimensionOfExpenses,
	|		UNDEFINED														AS AssetsLiabilitiesDimension,
	|		UNDEFINED														AS GLAccountSettings,
	|		""""																AS RowID,
	|		MaterialsAndWorksConsumption.Department								AS Department
	|	FROM
	|		MaterialsAndWorksConsumption AS MaterialsAndWorksConsumption
	|	
	|	WHERE
	|		MaterialsAndWorksConsumption.Period >= &PeriodFromWhichYouNeedToRecalculateTypesOfStocks
	|		AND NOT &ProductionByThirdParty2_5
	|	
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.CorItemsLocationAttributes,
	|	NestedQuery.DateOfTransaction,
	|	NestedQuery.Recipient,
	|	NestedQuery.ExpenseItem,
	|	NestedQuery.BusinessOperation,
	|	NestedQuery.DimensionOfExpenses,
	|	NestedQuery.RowID,
	|	NestedQuery.ItemsLocationAttributes,
	|	NestedQuery.Period,
	|	NestedQuery.AssetsLiabilitiesDimension,
	|	NestedQuery.GLAccountSettings,
	|	NestedQuery.ToExpenseAs,
	|	NestedQuery.CorAnalyticsAccountingProductsToFillIn,
	|	NestedQuery.Order,
	|	NestedQuery.Department,
	|	ISNULL(NestedQuery.CorAnalyticsAccountingProductsToFillIn.Purpose.AssignmentType,
	|		VALUE(Enum.AssignmentTypes.EmptyRef))
	|
	|ORDER BY
	|	Order";
	
	Query.SetParameter("BusinessTransactionSupply",	BusinessOperationNamedTS("SupplyWithMaterialsAndWorks"));
	Query.SetParameter("BusinessTransactionEconomy",	BusinessOperationNamedTS("SavingMaterialsWriteOff"));
	Query.SetParameter("BusinessTransactionExpense",		BusinessOperationNamedTS("MaterialsAndWorksConsumption"));
	Query.SetParameter("PeriodFromWhichYouNeedToRecalculateTypesOfStocks",
								AdditionalProperties.PeriodFromWhichYouNeedToRecalculateTypesOfStocks);
	Query.SetParameter("ProductionByThirdParty2_5", ProductionByThirdParty2_5);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	GoodsTable = Query.Execute().Unload();
	
	SearchFields	= "ItemsLocationAttributes,CorItemsLocationAttributes,BusinessOperation,Period";
	SearchSelection	= New Structure(SearchFields);
	
	TableTypesOfStocks_ = ParametersForFillingInventoryTypes.TableTypesOfStocks_;
	TableTypesOfStocks_.Indexes.Add(SearchFields);
	
	InventoryTypes =
		Common.ObjectsAttributeValue(
			TableTypesOfStocks_.UnloadColumn("InventoryOwnerAttribute"),
			"InventoryType");
	
	For Each RowOfGoods In GoodsTable Do
		
		GoodsQuantity = RowOfGoods.Count;
		
		If GoodsQuantity = 0 Then
			Continue;
		EndIf;
		
		FillPropertyValues(SearchSelection, RowOfGoods);
		
		For Each InventoryLine In TableTypesOfStocks_.FindRows(SearchSelection) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count			= Min(GoodsQuantity, InventoryLine.Count);
			QuantityByGBRN	= Count * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			
			If InventoryLine.Count = Count Then
				LineToFillInByProduct = InventoryLine;
			Else
				LineToFillInByProduct = TableTypesOfStocks_.Add();
				FillPropertyValues(LineToFillInByProduct, InventoryLine);
				
				InventoryLine.Count		= InventoryLine.Count - Count;
				InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - QuantityByGBRN;
			EndIf;
			
			FillPropertyValues(LineToFillInByProduct, RowOfGoods);
			
			LineToFillInByProduct.CorItemsLocationAttributes = RowOfGoods.CorAnalyticsAccountingProductsToFillIn;
			
			If RowOfGoods.BusinessOperation = BusinessOperationNamedTS("SavingMaterialsReturn")
				And (InventoryTypes[LineToFillInByProduct.InventoryOwnerAttribute] = Enums.InventoryTypes.MaterialOfMaterialProvider
					Or InventoryTypes[LineToFillInByProduct.InventoryOwnerAttribute] = Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider
					Or InventoryTypes[LineToFillInByProduct.InventoryOwnerAttribute] = Enums.InventoryTypes.ProductsOfMaterialProvider)
				And Not RowOfGoods.TypeOfDestinationCor = Enums.AssignmentTypes.ProvidedMaterialsForStage22
				And Not RowOfGoods.TypeOfDestinationCor = Enums.AssignmentTypes.Giveaway2_5 Then
				
				ErrorText = NStr("vi = 'Việc tiết kiệm nguyên vật liệu gia công ""%1"" trong kho ""%2"" phải được tách biệt theo mục đích gia công. Cần thiết lập mục đích tương ứng trong dòng của phần bảng.';
								|ru = 'Экономия давальческого материала ""%1"" на склад ""%2"" должна обосабливаться под давальческое назначение. Необходимо установить соответствующее назначение в строке табличной части.';
								|en = 'The savings of the ""%1"" material provided to the ""%2"" warehouse must be assigned for the provider assignment. Set the corresponding assignment in the table row.'; fa = 'The savings of the ""%1"" material provided to the ""%2"" warehouse must be assigned for the provider assignment. Set the corresponding assignment in the table row.';
								|it = 'Il risparmio di materiali del fornitore ""%1"" nel magazzino ""%2"" deve essere separato su assegnazione del fornitore. Impostare l''assegnazione corrispondente nella stringa della parte tabellare.';
								|pl = 'Oszczędność materiału, dostarczanego przez właściciela surowców ""%1"" do magazynu ""%2"" powinna być oddzielana dla przeznaczenia powierzonego. Należy ustawić odpowiednie przeznaczenie w wierszu sekcji tabelarycznej.';
								|tr = '""%2"" ambarına ""%1"" tedarikçi malzemesinden yapılan tasarruflar, tedarikçi atamasın altında ayrılmalıdır. İlgili atamayı, tablo bölümü satırında yapılandırmanız gerekmektedir.'");
				ErrorText =
					StrTemplate(
						ErrorText,
						ProductsClientServer.ProductPresentation(
							RowOfGoods.Products,
							RowOfGoods.Characteristic,,
							RowOfGoods.Series),
						RowOfGoods.BoxStorageLocation);
				
				Common.MessageToUser(ErrorText, ThisObject, "UnusedMaterials",, Cancel);
				
				Continue;
				
			EndIf;
			
			LineToFillInByProduct.Count = Count;
			LineToFillInByProduct.QuantityByGBRN = QuantityByGBRN;
			
			If InventoryTypes[LineToFillInByProduct.InventoryOwnerAttribute] = Enums.InventoryTypes.ConsignedGoods
				And (LineToFillInByProduct.ToExpenseAs
					Or LineToFillInByProduct.BusinessOperation = Enums.BusinessTransactions.ExpensingToProductionLots) Then
				
				LineToFillInByProduct.CorInventoryOwnerAttribute = Catalogs.InventoryKinds.DocumentInventoryView(
																Organization,
																RowOfGoods.BusinessOperation,
																RowOfGoods);
				
			Else
				LineToFillInByProduct.CorInventoryOwnerAttribute = LineToFillInByProduct.InventoryOwnerAttribute;
			EndIf;
			
			GoodsQuantity = GoodsQuantity - Count;
			
			If GoodsQuantity = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	TTAddedInventoryTypes.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TTAddedInventoryTypes.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	TTAddedInventoryTypes.CCDNumber						AS CCDNumber,
	|	TTAddedInventoryTypes.Count						AS Count,
	|	TTAddedInventoryTypes.QuantityByGBRN				AS QuantityByGBRN,
	|	TTAddedInventoryTypes.DateOfTransaction					AS DateOfTransaction,
	|	TTAddedInventoryTypes.BusinessOperation			AS BusinessOperation,
	|	TTAddedInventoryTypes.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|	TTAddedInventoryTypes.CorInventoryOwnerAttribute					AS CorInventoryOwnerAttribute,
	|	TTAddedInventoryTypes.ToExpenseAs				AS ToExpenseAs,
	|	TTAddedInventoryTypes.Recipient						AS Recipient,
	|	TTAddedInventoryTypes.ExpenseItem					AS ExpenseItem,
	|	TTAddedInventoryTypes.DimensionOfExpenses				AS DimensionOfExpenses,
	|	TTAddedInventoryTypes.AssetsLiabilitiesDimension		AS AssetsLiabilitiesDimension,
	|	TTAddedInventoryTypes.GLAccountSettings			AS GLAccountSettings,
	|	TTAddedInventoryTypes.RowID			AS RowID,
	|	TTAddedInventoryTypes.Period							AS Period,
	|	TTAddedInventoryTypes.Department					AS Department
	|INTO TTAddedInventoryTypes
	|FROM
	|	&TableTypesOfStocks_ AS TTAddedInventoryTypes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTStockTypesMaterials.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TTStockTypesMaterials.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	TTStockTypesMaterials.CCDNumber							AS CCDNumber,
	|	TTStockTypesMaterials.Count						AS Count,
	|	TTStockTypesMaterials.QuantityByGBRN					AS QuantityByGBRN,
	|	TTStockTypesMaterials.DateOfTransaction						AS DateOfTransaction,
	|	TTStockTypesMaterials.BusinessOperation			AS BusinessOperation,
	|	TTStockTypesMaterials.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|	TTStockTypesMaterials.CorInventoryOwnerAttribute					AS CorInventoryOwnerAttribute,
	|	TTStockTypesMaterials.ToExpenseAs					AS ToExpenseAs,
	|	TTStockTypesMaterials.Recipient						AS Recipient,
	|	TTStockTypesMaterials.ExpenseItem					AS ExpenseItem,
	|	TTStockTypesMaterials.DimensionOfExpenses				AS DimensionOfExpenses,
	|	TTStockTypesMaterials.AssetsLiabilitiesDimension			AS AssetsLiabilitiesDimension,
	|	TTStockTypesMaterials.GLAccountSettings				AS GLAccountSettings,
	|	TTStockTypesMaterials.RowID				AS RowID,
	|	TTStockTypesMaterials.FinRecordID			AS FinRecordID,
	|	TTStockTypesMaterials.Period							AS Period,
	|	TTStockTypesMaterials.Department					AS Department
	|FROM
	|	TTStockTypesMaterials AS TTStockTypesMaterials
	|WHERE
	|	TTStockTypesMaterials.Period < &PeriodFromWhichYouNeedToRecalculateTypesOfStocks
	|
	|UNION ALL
	|
	|SELECT
	|	TTAddedInventoryTypes.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TTAddedInventoryTypes.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	TTAddedInventoryTypes.CCDNumber						AS CCDNumber,
	|	SUM(TTAddedInventoryTypes.Count)				AS Count,
	|	SUM(TTAddedInventoryTypes.QuantityByGBRN)		AS QuantityByGBRN,
	|	TTAddedInventoryTypes.DateOfTransaction					AS DateOfTransaction,
	|	TTAddedInventoryTypes.BusinessOperation			AS BusinessOperation,
	|	TTAddedInventoryTypes.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|	TTAddedInventoryTypes.CorInventoryOwnerAttribute					AS CorInventoryOwnerAttribute,
	|	TTAddedInventoryTypes.ToExpenseAs				AS ToExpenseAs,
	|	TTAddedInventoryTypes.Recipient						AS Recipient,
	|	TTAddedInventoryTypes.ExpenseItem					AS ExpenseItem,
	|	TTAddedInventoryTypes.DimensionOfExpenses				AS DimensionOfExpenses,
	|	TTAddedInventoryTypes.AssetsLiabilitiesDimension		AS AssetsLiabilitiesDimension,
	|	TTAddedInventoryTypes.GLAccountSettings			AS GLAccountSettings,
	|	TTAddedInventoryTypes.RowID			AS RowID,
	|	""""													AS FinRecordID,
	|	TTAddedInventoryTypes.Period							AS Period,
	|	TTAddedInventoryTypes.Department					AS Department
	|FROM
	|	TTAddedInventoryTypes AS TTAddedInventoryTypes
	|
	|GROUP BY
	|	TTAddedInventoryTypes.ItemsLocationAttributes,
	|	TTAddedInventoryTypes.InventoryOwnerAttribute,
	|	TTAddedInventoryTypes.CCDNumber,
	|	TTAddedInventoryTypes.DateOfTransaction,
	|	TTAddedInventoryTypes.BusinessOperation,
	|	TTAddedInventoryTypes.CorItemsLocationAttributes,
	|	TTAddedInventoryTypes.CorInventoryOwnerAttribute,
	|	TTAddedInventoryTypes.ToExpenseAs,
	|	TTAddedInventoryTypes.Recipient,
	|	TTAddedInventoryTypes.ExpenseItem,
	|	TTAddedInventoryTypes.DimensionOfExpenses,
	|	TTAddedInventoryTypes.AssetsLiabilitiesDimension,
	|	TTAddedInventoryTypes.GLAccountSettings,
	|	TTAddedInventoryTypes.RowID,
	|	TTAddedInventoryTypes.Period,
	|	TTAddedInventoryTypes.Department
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTAddedInventoryTypes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ConsumptionAndArrivalInStorerooms
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TableOfProductsByPeriod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TableTypesOfStocksByPeriod";
	
	Query.SetParameter("TableTypesOfStocks_", TableTypesOfStocks_);
	Query.SetParameter(
		"PeriodFromWhichYouNeedToRecalculateTypesOfStocks",
		AdditionalProperties.PeriodFromWhichYouNeedToRecalculateTypesOfStocks);

	InventoryOwnerAttributesMaterials.Load(Query.Execute().Unload());
	
EndProcedure

// Fill in additional columns types of inventory items.
// 
// Parameters:
//  TempTablesManager - TempTablesManager - temporary table Manager
//  TableTypesOfStocks_ - ValueTable - Table types of stocks
//
Procedure FillInInventoryTypesOfProduct(TempTablesManager, TableTypesOfStocks_)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber						AS CCDNumber,
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.DateOfTransaction					AS DateOfTransaction,
	|	TableTypesOfStocks_.BusinessOperation		AS BusinessOperation,
	|	TableTypesOfStocks_.ProductCostElement			AS ProductCostElement,
	|	TableTypesOfStocks_.ToExpenseAs				AS ToExpenseAs,
	|	TableTypesOfStocks_.Recipient					AS Recipient,
	|	TableTypesOfStocks_.ExpenseItem				AS ExpenseItem,
	|	TableTypesOfStocks_.DimensionOfExpenses			AS DimensionOfExpenses,
	|	TableTypesOfStocks_.AssetsLiabilitiesDimension		AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.GLAccountSettings			AS GLAccountSettings,
	|	TableTypesOfStocks_.RowID			AS RowID,
	|	TableTypesOfStocks_.RowCode					AS RowCode,
	|	TableTypesOfStocks_.CostShare				AS CostShare,
	|	TableTypesOfStocks_.Sum						AS Sum,
	|	TableTypesOfStocks_.Period						AS Period,
	|	TableTypesOfStocks_.Department				AS Department,
	|	TableTypesOfStocks_.ProductOwner				AS ProductOwner
	|INTO TTAddedInventoryTypes
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Organization									AS Organization,
	|	TTTypesOfProductStocks.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TTTypesOfProductStocks.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TTTypesOfProductStocks.CCDNumber					AS CCDNumber,
	|	TTTypesOfProductStocks.Count					AS Count,
	|	0												AS QuantityByGBRN,
	|	TTTypesOfProductStocks.DateOfTransaction				AS DateOfTransaction,
	|	TTTypesOfProductStocks.BusinessOperation		AS BusinessOperation,
	|	TTTypesOfProductStocks.ProductCostElement			AS ProductCostElement,
	|	TTTypesOfProductStocks.ToExpenseAs			AS ToExpenseAs,
	|	TTTypesOfProductStocks.Recipient					AS Recipient,
	|	TTTypesOfProductStocks.ExpenseItem				AS ExpenseItem,
	|	TTTypesOfProductStocks.DimensionOfExpenses			AS DimensionOfExpenses,
	|	TTTypesOfProductStocks.AssetsLiabilitiesDimension	AS AssetsLiabilitiesDimension,
	|	TTTypesOfProductStocks.GLAccountSettings		AS GLAccountSettings,
	|	TTTypesOfProductStocks.RowID		AS RowID,
	|	TTTypesOfProductStocks.FinRecordID		AS FinRecordID,
	|	TTTypesOfProductStocks.RowCode					AS RowCode,
	|	TTTypesOfProductStocks.CostShare				AS CostShare,
	|	TTTypesOfProductStocks.Sum						AS Sum,
	|	TTTypesOfProductStocks.Period						AS Period,
	|	TTTypesOfProductStocks.Department				AS Department,
	|	TTTypesOfProductStocks.ProductOwner			AS ProductOwner
	|INTO TTIncomingTypesOfStocksOfProductIntermediate
	|FROM
	|	TTTypesOfProductStocks AS TTTypesOfProductStocks
	|WHERE
	|	TTTypesOfProductStocks.Period < &PeriodFromWhichYouNeedToRecalculateTypesOfStocks
	|
	|UNION ALL
	|
	|SELECT
	|	&Organization AS Organization,
	|	TTAddedInventoryTypes.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TTAddedInventoryTypes.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TTAddedInventoryTypes.CCDNumber					AS CCDNumber,
	|	TTAddedInventoryTypes.Count					AS Count,
	|	0													AS QuantityByGBRN,
	|	TTAddedInventoryTypes.DateOfTransaction				AS DateOfTransaction,
	|	TTAddedInventoryTypes.BusinessOperation		AS BusinessOperation,
	|	TTAddedInventoryTypes.ProductCostElement			AS ProductCostElement,
	|	TTAddedInventoryTypes.ToExpenseAs			AS ToExpenseAs,
	|	TTAddedInventoryTypes.Recipient					AS Recipient,
	|	TTAddedInventoryTypes.ExpenseItem				AS ExpenseItem,
	|	TTAddedInventoryTypes.DimensionOfExpenses			AS DimensionOfExpenses,
	|	TTAddedInventoryTypes.AssetsLiabilitiesDimension	AS AssetsLiabilitiesDimension,
	|	TTAddedInventoryTypes.GLAccountSettings		AS GLAccountSettings,
	|	TTAddedInventoryTypes.RowID		AS RowID,
	|	""""												AS FinRecordID,
	|	TTAddedInventoryTypes.RowCode					AS RowCode,
	|	TTAddedInventoryTypes.CostShare				AS CostShare,
	|	TTAddedInventoryTypes.Sum						AS Sum,
	|	TTAddedInventoryTypes.Period						AS Period,
	|	TTAddedInventoryTypes.Department				AS Department,
	|	TTAddedInventoryTypes.ProductOwner			AS ProductOwner
	|FROM
	|	TTAddedInventoryTypes AS TTAddedInventoryTypes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTTypesOfProductStocks.Organization				AS Organization,
	|	TTTypesOfProductStocks.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TTTypesOfProductStocks.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TTTypesOfProductStocks.CCDNumber					AS CCDNumber,
	|	TTTypesOfProductStocks.Count					AS Count,
	|	TTTypesOfProductStocks.QuantityByGBRN			AS QuantityByGBRN,
	|	TTTypesOfProductStocks.DateOfTransaction				AS DateOfTransaction,
	|	TTTypesOfProductStocks.BusinessOperation		AS BusinessOperation,
	|	TTTypesOfProductStocks.ProductCostElement			AS ProductCostElement,
	|	TTTypesOfProductStocks.ToExpenseAs			AS ToExpenseAs,
	|	TTTypesOfProductStocks.Recipient					AS Recipient,
	|	TTTypesOfProductStocks.ExpenseItem				AS ExpenseItem,
	|	TTTypesOfProductStocks.DimensionOfExpenses			AS DimensionOfExpenses,
	|	TTTypesOfProductStocks.AssetsLiabilitiesDimension	AS AssetsLiabilitiesDimension,
	|	TTTypesOfProductStocks.GLAccountSettings		AS GLAccountSettings,
	|	TTTypesOfProductStocks.RowID		AS RowID,
	|	TTTypesOfProductStocks.FinRecordID		AS FinRecordID,
	|	TTTypesOfProductStocks.RowCode					AS RowCode,
	|	TTTypesOfProductStocks.CostShare				AS CostShare,
	|	TTTypesOfProductStocks.Sum						AS Sum,
	|	TTTypesOfProductStocks.Period						AS Period,
	|	TTTypesOfProductStocks.Department				AS Department,
	|	TTTypesOfProductStocks.ProductOwner			AS ProductOwner
	|INTO TTIncomingTypesOfProductInventory
	|FROM
	|	TTIncomingTypesOfStocksOfProductIntermediate AS TTTypesOfProductStocks
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON TTTypesOfProductStocks.ItemsLocationAttributes = DimensionKeys.Ref
	|		
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON DimensionKeys.Products = CatalogProducts.Ref
	|WHERE
	|	NOT (&UseTraceableImportedGoodsAccounting
	|		AND ISNULL(CatalogProducts.TracedGoods, FALSE)
	|		AND TTTypesOfProductStocks.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|	)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTAddedInventoryTypes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP OriginalProductTable
	|";
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("TableTypesOfStocks_", TableTypesOfStocks_);
	Query.SetParameter("PeriodFromWhichYouNeedToRecalculateTypesOfStocks", AdditionalProperties.PeriodFromWhichYouNeedToRecalculateTypesOfStocks);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Results = Query.ExecuteBatchWithIntermediateData();
	
	InventoryOwnerAttributesProducts.Load(Results[1].Unload());
	
	Query.Text ="DROP TTIncomingTypesOfStocksOfProductIntermediate";
	Query.Execute();
	
EndProcedure

Function ParametersForFillingInventoryTypes(TSName, TempTablesManager = Undefined)
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	
	FillParameters.SelectionOfStockTypes_.InventoryType.Clear();
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.OwnGoods);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.MaterialOfMaterialProvider);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.ConsignedGoods);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
	If GetFunctionalOption("UseExcisableGoods") Then
		FillParameters.SelectionOfStockTypes_.SubjectToExcise.Clear();
	EndIf;
	If TSName = "InventoryOwnerAttributesMaterials"Then
		
		FillParameters.SelectStocksOfDifferentPeriods = True;
		FillParameters.NameTSTypesOfStocks = TSName;
		FillParameters.TableTypesOfStocks_ = ThisObject[TSName].UnloadColumns();
		FillParameters.FillingPeriod = AdditionalProperties.PeriodFromWhichYouNeedToRecalculateTypesOfStocks;
		FillParameters.DocumentMakesBothArrivalAndExpenditure = True;
		
		FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "ByBusinessTransaction");
		FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.MaterialOfMaterialProvider,              "ByBusinessTransaction");
		FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider,          "ByBusinessTransaction");
		FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.ProductsOfMaterialProvider,             "ByBusinessTransaction");
		
		ActionsForBusinessTransaction = New Map;
		
		ActionOnBusinessTransaction = New Map();
		ActionOnBusinessTransaction.Insert(BusinessOperationNamedTS("SupplyWithMaterialsAndWorks"), "Always");
		ActionOnBusinessTransaction.Insert(BusinessOperationNamedTS("SavingMaterialsReturn"),       "Always");
		ActionOnBusinessTransaction.Insert(BusinessOperationNamedTS("SavingMaterialsWriteOff"),      "ByAgreementSettings");
		ActionOnBusinessTransaction.Insert(BusinessOperationNamedTS("MaterialsAndWorksConsumption"),          "AccordingToSettingsOfProductionContract");
		
		ActionsForBusinessTransaction.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, ActionOnBusinessTransaction);
		
		ActionOnBusinessTransaction = New Map();
		ActionOnBusinessTransaction.Insert(BusinessOperationNamedTS("SupplyWithMaterialsAndWorks"), "Always");
		ActionOnBusinessTransaction.Insert(BusinessOperationNamedTS("SavingMaterialsReturn"),       "Always");
		ActionOnBusinessTransaction.Insert(BusinessOperationNamedTS("SavingMaterialsWriteOff"),      "ByAgreementSettings");
		ActionOnBusinessTransaction.Insert(BusinessOperationNamedTS("MaterialsAndWorksConsumption"),          "Always");
		
		ActionsForBusinessTransaction.Insert(Enums.InventoryTypes.MaterialOfMaterialProvider,     ActionOnBusinessTransaction);
		ActionsForBusinessTransaction.Insert(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider, ActionOnBusinessTransaction);
		ActionsForBusinessTransaction.Insert(Enums.InventoryTypes.ProductsOfMaterialProvider,    ActionOnBusinessTransaction);
		
		FillParameters.ActionsOfSelectionOfGoodsAcceptedForResponsibleStorageOnEconomicOperation =
			ActionsForBusinessTransaction;
		
		FillParameters.ThereIsTableOfInventoryTypes = True;
		FillParameters.NameOfInventoryTypeTable  = "TTIncomingTypesOfProductInventory";
		
		If InternalSubcontracting Then
			FillParameters.SelectionOfStockTypes_.MaterialProviderCompany = MaterialProviderCompany;
		EndIf;
		
		FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.Work_5);
		
	ElsIf Not TSName = "Posting" Then
		
		ExceptionText = NStr("vi = 'Tên không xác định cho phần bảng của loại hàng tồn kho: ""%TSName%""';
							|ru = 'Неизвестное имя табличной части видов запасов: ""%TSName%""';
							|en = 'Unknown name of table of inventory owner attributes: ""%TSName%""'; fa = 'Unknown name of table of inventory owner attributes: ""%TSName%""';
							|it = 'Nome della tabella di tipi di scorte sconosciuto ""%TSName%""';
							|pl = 'Nieznana nazwa sekcji tabelarycznej rodzajów zapasów: ""%TSName%""';
							|tr = 'Stok türlerinin tablo bölümünün bilinmeyen adı: ""%TSName%'");
		ExceptionText = StrReplace(ExceptionText, "%TSName%", TSName);
		Return ExceptionText;
		
	EndIf;
	
	Return FillParameters;
	
EndFunction

Function TemporaryDocumentDataTables()
	
	TempTablesManager = Documents.ProductionStage2_2.TemporaryObjectDataTables(ThisObject);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	StageDetails_.Date										AS Date,
	|	StageDetails_.Organization									AS Organization,
	|	StageDetails_.InternalSubcontracting						AS InternalSubcontracting,
	|	StageDetails_.MaterialProviderCompany							AS MaterialProviderCompany,
	|	UNDEFINED												AS Partner,
	|	UNDEFINED												AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)	AS Terms,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef)		AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef)					AS Currency,
	|	CASE
	|		WHEN &UseSeparateAccountingByTaxation
	|			THEN StageDetails_.ProductionIssueForActivity
	|		ELSE VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	END														AS ProductionIssueForActivity,
	|	CASE
	|		WHEN &UseSeparateAccountingByTaxation
	|			THEN StageDetails_.ProductionIssueForActivity
	|		ELSE VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	END														AS VATTaxation,
	|	VALUE(Enum.BusinessTransactions.EmptyRef)	AS BusinessOperation,
	|	FALSE														AS ThereAreTransactionsInTablePart,
	|	VALUE(Catalog.Users.EmptyRef)				AS Manager,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)			AS SalesOpportunity,
	|	VALUE(Enum.InventoryTypes.OwnGoods)					AS InventoryType
	|INTO DocumentDataTable
	|FROM
	|	StageDetails_ AS StageDetails_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryOwnerAttributesMaterials.LineNumber					AS LineNumber,
	|	InventoryOwnerAttributesMaterials.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	InventoryOwnerAttributesMaterials.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	InventoryOwnerAttributesMaterials.CCDNumber						AS CCDNumber,
	|	InventoryOwnerAttributesMaterials.Count						AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(InventoryOwnerAttributesMaterials.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE InventoryOwnerAttributesMaterials.QuantityByGBRN
	|	END												AS QuantityByGBRN,
	|	InventoryOwnerAttributesMaterials.DateOfTransaction					AS DateOfTransaction,
	|	InventoryOwnerAttributesMaterials.BusinessOperation			AS BusinessOperation,
	|	InventoryOwnerAttributesMaterials.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|	InventoryOwnerAttributesMaterials.CorInventoryOwnerAttribute					AS CorInventoryOwnerAttribute,
	|	InventoryOwnerAttributesMaterials.ToExpenseAs				AS ToExpenseAs,
	|	InventoryOwnerAttributesMaterials.Recipient						AS Recipient,
	|	InventoryOwnerAttributesMaterials.ExpenseItem					AS ExpenseItem,
	|	InventoryOwnerAttributesMaterials.DimensionOfExpenses				AS DimensionOfExpenses,
	|	InventoryOwnerAttributesMaterials.AssetsLiabilitiesDimension		AS AssetsLiabilitiesDimension,
	|	InventoryOwnerAttributesMaterials.GLAccountSettings			AS GLAccountSettings,
	|	InventoryOwnerAttributesMaterials.RowID			AS RowID,
	|	InventoryOwnerAttributesMaterials.FinRecordID			AS FinRecordID,
	|	InventoryOwnerAttributesMaterials.Period							AS Period,
	|	InventoryOwnerAttributesMaterials.Department					AS Department
	|INTO TTStockTypesMaterials
	|FROM
	|	&InventoryOwnerAttributesMaterials AS InventoryOwnerAttributesMaterials
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryOwnerAttributesProducts.LineNumber					AS LineNumber,
	|	InventoryOwnerAttributesProducts.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	InventoryOwnerAttributesProducts.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	InventoryOwnerAttributesProducts.CCDNumber						AS CCDNumber,
	|	InventoryOwnerAttributesProducts.Count					AS Count,
	|	0												AS QuantityByGBRN,
	|	InventoryOwnerAttributesProducts.DateOfTransaction					AS DateOfTransaction,
	|	InventoryOwnerAttributesProducts.BusinessOperation		AS BusinessOperation,
	|	InventoryOwnerAttributesProducts.ProductCostElement			AS ProductCostElement,
	|	InventoryOwnerAttributesProducts.ToExpenseAs				AS ToExpenseAs,
	|	InventoryOwnerAttributesProducts.Recipient					AS Recipient,
	|	InventoryOwnerAttributesProducts.ExpenseItem				AS ExpenseItem,
	|	InventoryOwnerAttributesProducts.DimensionOfExpenses			AS DimensionOfExpenses,
	|	InventoryOwnerAttributesProducts.AssetsLiabilitiesDimension		AS AssetsLiabilitiesDimension,
	|	InventoryOwnerAttributesProducts.GLAccountSettings			AS GLAccountSettings,
	|	InventoryOwnerAttributesProducts.RowID			AS RowID,
	|	InventoryOwnerAttributesProducts.FinRecordID		AS FinRecordID,
	|	InventoryOwnerAttributesProducts.RowCode					AS RowCode,
	|	InventoryOwnerAttributesProducts.CostShare				AS CostShare,
	|	InventoryOwnerAttributesProducts.Sum						AS Sum,
	|	InventoryOwnerAttributesProducts.Period						AS Period,
	|	InventoryOwnerAttributesProducts.Department				AS Department,
	|	InventoryOwnerAttributesProducts.ProductOwner				AS ProductOwner
	|INTO TTTypesOfProductStocks
	|FROM
	|	&InventoryOwnerAttributesProducts AS InventoryOwnerAttributesProducts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Software_3.Period							AS Period,
	|	Software_3.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	Software_3.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|	Software_3.Department					AS Department,
	|	Software_3.CCDNumber							AS CCDNumber
	|INTO CounterArrivalsAndExpensesInStorerooms
	|FROM
	|	SupplyWithMaterialsAndWorks AS Software_3
	|		INNER JOIN UnusedMaterials AS TableEconomy
	|		ON Software_3.Period = TableEconomy.Period
	|			AND Software_3.ItemsLocationAttributes = TableEconomy.CorItemsLocationAttributes
	|			AND Software_3.CorItemsLocationAttributes = TableEconomy.ItemsLocationAttributes
	|			AND Software_3.Department = TableEconomy.Department
	|			AND Software_3.CCDNumber = TableEconomy.CCDNumber
	|
	|WHERE
	|	NOT Software_3.Canceled
	|	AND NOT &ProductionByThirdParty2_5
	|	AND Software_3.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom
	|	AND Software_3.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND TableEconomy.CorItemsLocationAttributes <> VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|	AND Software_3.ItemsLocationAttributes.WarehouseArea.Department = Software_3.Department
	|
	|INDEX BY
	|	Period,
	|	ItemsLocationAttributes,
	|	CorItemsLocationAttributes,
	|	Department,
	|	CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(ConsumptionAndArrivalInStorerooms.LineNumber)				AS LineNumber,
	|	CASE
	|		WHEN SUM(ConsumptionAndArrivalInStorerooms.Count) > 0
	|			THEN ConsumptionAndArrivalInStorerooms.ItemsLocationAttributes
	|		ELSE ConsumptionAndArrivalInStorerooms.CorItemsLocationAttributes
	|	END														AS ItemsLocationAttributes,
	|	CASE
	|		WHEN SUM(ConsumptionAndArrivalInStorerooms.Count) > 0
	|			THEN ConsumptionAndArrivalInStorerooms.CorItemsLocationAttributes
	|		ELSE ConsumptionAndArrivalInStorerooms.ItemsLocationAttributes
	|	END														AS CorItemsLocationAttributes,
	|	CASE
	|		WHEN SUM(ConsumptionAndArrivalInStorerooms.Count) > 0
	|			THEN &BusinessTransactionOfSupply
	|		ELSE &BusinessTransactionEconomy
	|	END														AS BusinessOperation,
	|	CASE
	|		WHEN SUM(ConsumptionAndArrivalInStorerooms.Count) > 0
	|			THEN SUM(ConsumptionAndArrivalInStorerooms.Count)
	|		ELSE -SUM(ConsumptionAndArrivalInStorerooms.Count)
	|	END														AS Count,
	|	CASE
	|		WHEN SUM(ConsumptionAndArrivalInStorerooms.QuantityByGBRN) > 0
	|			THEN SUM(ConsumptionAndArrivalInStorerooms.QuantityByGBRN)
	|		ELSE -SUM(ConsumptionAndArrivalInStorerooms.QuantityByGBRN)
	|	END														AS QuantityByGBRN,
	|	ConsumptionAndArrivalInStorerooms.Period								AS Period,
	|	ConsumptionAndArrivalInStorerooms.Department						AS Department,
	|	ConsumptionAndArrivalInStorerooms.CCDNumber								AS CCDNumber,
	|	MAX(ConsumptionAndArrivalInStorerooms.DateOfTransaction)				AS DateOfTransaction
	|INTO ConsumptionAndArrivalInStorerooms
	|FROM
	|	(SELECT
	|		Software_3.LineNumber + &SecurityProcedure	AS LineNumber,
	|		Software_3.ItemsLocationAttributes			AS ItemsLocationAttributes,
	|		Software_3.CorItemsLocationAttributes		AS CorItemsLocationAttributes,
	|		Software_3.Count							AS Count,
	|		Software_3.QuantityByGBRN						AS QuantityByGBRN,
	|		Software_3.Period								AS Period,
	|		Software_3.DateOfShipment							AS DateOfTransaction,
	|		Software_3.Department						AS Department,
	|		Software_3.CCDNumber								AS CCDNumber
	|	FROM
	|		SupplyWithMaterialsAndWorks AS Software_3
	|			INNER JOIN CounterArrivalsAndExpensesInStorerooms AS CounterCollateral
	|			ON Software_3.Period = CounterCollateral.Period
	|				AND Software_3.ItemsLocationAttributes = CounterCollateral.ItemsLocationAttributes
	|				AND Software_3.CorItemsLocationAttributes = CounterCollateral.CorItemsLocationAttributes
	|				AND Software_3.Department = CounterCollateral.Department
	|				AND Software_3.CCDNumber = CounterCollateral.CCDNumber
	|	WHERE
	|		NOT Software_3.Canceled
	|		AND NOT &ProductionByThirdParty2_5
	|		AND Software_3.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableEconomy.LineNumber + &OrderSaving	AS LineNumber,
	|		TableEconomy.CorItemsLocationAttributes	AS ItemsLocationAttributes,
	|		TableEconomy.ItemsLocationAttributes		AS CorItemsLocationAttributes,
	|		-TableEconomy.Count						AS Count,
	|		-TableEconomy.QuantityByGBRN				AS QuantityByGBRN,
	|		TableEconomy.Period							AS Period,
	|		TableEconomy.DateOfTransaction					AS DateOfTransaction,
	|		TableEconomy.Department					AS Department,
	|		TableEconomy.CCDNumber						AS CCDNumber
	|	FROM
	|		UnusedMaterials AS TableEconomy
	|			INNER JOIN CounterArrivalsAndExpensesInStorerooms AS CounterSavings
	|			ON TableEconomy.Period = CounterSavings.Period
	|				AND TableEconomy.CorItemsLocationAttributes = CounterSavings.ItemsLocationAttributes
	|				AND TableEconomy.ItemsLocationAttributes = CounterSavings.CorItemsLocationAttributes
	|				AND TableEconomy.Department = CounterSavings.Department
	|				AND TableEconomy.CCDNumber = CounterSavings.CCDNumber
	|	WHERE
	|		NOT &ProductionByThirdParty2_5
	|	) AS ConsumptionAndArrivalInStorerooms
	|
	|GROUP BY
	|	ConsumptionAndArrivalInStorerooms.ItemsLocationAttributes,
	|	ConsumptionAndArrivalInStorerooms.CorItemsLocationAttributes,
	|	ConsumptionAndArrivalInStorerooms.Period,
	|	ConsumptionAndArrivalInStorerooms.Department,
	|	ConsumptionAndArrivalInStorerooms.CCDNumber
	|
	|HAVING
	|	SUM(ConsumptionAndArrivalInStorerooms.Count) <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	MAX(Software_3.LineNumber + &SecurityProcedure)	AS LineNumber,
	|	Software_3.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	Software_3.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|	&BusinessTransactionOfSupply								AS BusinessOperation,
	|	SUM(Software_3.Count)				AS Count,
	|	SUM(Software_3.QuantityByGBRN)			AS QuantityByGBRN,
	|	Software_3.Period							AS Period,
	|	Software_3.Department					AS Department,
	|	Software_3.CCDNumber							AS CCDNumber,
	|	Software_3.DateOfShipment						AS DateOfTransaction
	|FROM
	|	SupplyWithMaterialsAndWorks AS Software_3
	|		LEFT JOIN CounterArrivalsAndExpensesInStorerooms AS CounterCollateral
	|		ON Software_3.Period = CounterCollateral.Period
	|			AND Software_3.ItemsLocationAttributes = CounterCollateral.ItemsLocationAttributes
	|			AND Software_3.CorItemsLocationAttributes = CounterCollateral.CorItemsLocationAttributes
	|			AND Software_3.Department = CounterCollateral.Department
	|			AND Software_3.CCDNumber = CounterCollateral.CCDNumber
	|WHERE
	|	NOT &ProductionByThirdParty2_5
	|	AND NOT Software_3.Canceled
	|	AND CounterCollateral.ItemsLocationAttributes IS NULL
	|	AND Software_3.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom
	|	AND Software_3.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND Software_3.ItemsLocationAttributes.WarehouseArea.Department = Software_3.Department
	|
	|GROUP BY
	|	Software_3.ItemsLocationAttributes,
	|	Software_3.CorItemsLocationAttributes,
	|	Software_3.Period,
	|	Software_3.Department,
	|	Software_3.CCDNumber,
	|	Software_3.DateOfShipment
	|
	|UNION ALL
	|
	|SELECT
	|	MAX(TableEconomy.LineNumber + &OrderSaving)	AS LineNumber,
	|	TableEconomy.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableEconomy.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|	&BusinessTransactionEconomy							AS BusinessOperation,
	|	SUM(TableEconomy.Count)				AS Count,
	|	SUM(TableEconomy.QuantityByGBRN)			AS QuantityByGBRN,
	|	TableEconomy.Period							AS Period,
	|	TableEconomy.Department					AS Department,
	|	TableEconomy.CCDNumber						AS CCDNumber,
	|	TableEconomy.DateOfTransaction					AS DateOfTransaction
	|FROM
	|	UnusedMaterials AS TableEconomy
	|		LEFT JOIN CounterArrivalsAndExpensesInStorerooms AS CounterSavings
	|		ON TableEconomy.Period = CounterSavings.Period
	|			AND TableEconomy.CorItemsLocationAttributes = CounterSavings.ItemsLocationAttributes
	|			AND TableEconomy.ItemsLocationAttributes = CounterSavings.CorItemsLocationAttributes
	|			AND TableEconomy.Department = CounterSavings.Department
	|			AND TableEconomy.CCDNumber = CounterSavings.CCDNumber
	|WHERE
	|	NOT &ProductionByThirdParty2_5
	|	AND CounterSavings.ItemsLocationAttributes IS NULL
	|	AND TableEconomy.CorItemsLocationAttributes <> VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|
	|GROUP BY
	|	TableEconomy.ItemsLocationAttributes,
	|	TableEconomy.CorItemsLocationAttributes,
	|	TableEconomy.Period,
	|	TableEconomy.Department,
	|	TableEconomy.CCDNumber,
	|	TableEconomy.DateOfTransaction
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP CounterArrivalsAndExpensesInStorerooms";
	
	Query.SetParameter("UseSeparateAccountingByTaxation",
		AccountingPoliciesTaxSettingsCached.SeparateAccountingOfGoodsByVATTaxation(Organization, Date));
	
	Query.SetParameter("InventoryOwnerAttributesMaterials", InventoryOwnerAttributesMaterials);
	
	If ProductionByThirdParty2_5 Then
		Query.SetParameter("InventoryOwnerAttributesProducts", InventoryOwnerAttributesProducts.UnloadColumns());
	Else
		Query.SetParameter("InventoryOwnerAttributesProducts", InventoryOwnerAttributesProducts);
	EndIf;
	
	Query.SetParameter("OrderSaving",	OrderOfTS("UnusedMaterials"));
	Query.SetParameter("SecurityProcedure",	OrderOfTS("SupplyWithMaterialsAndWorks"));
	
	Query.SetParameter("BusinessTransactionOfSupply",	BusinessOperationNamedTS("SupplyWithMaterialsAndWorks"));
	Query.SetParameter("BusinessTransactionEconomy",	BusinessOperationNamedTS("SavingMaterialsReturn"));
	
	Query.SetParameter("ProductionByThirdParty2_5", ProductionByThirdParty2_5);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

// Tables for filling in the types of inventory of the product.
// 
// Parameters:
//  TempTablesManager - TempTablesManager - temporary table Manager
// 
// Returns:
//  ValueTable - Tables to fill in types of product inventory
//
Function TableToFillInTypesOfProductStocks(TempTablesManager)
	
	QueryTexts = New Array;
	
	PartOfTheRequestText = 
	"SELECT
	|	TableOfGoods.ProductionDate	AS Period,
	|	CASE
	|		WHEN &InternalSubcontracting
	|			THEN &MaterialProviderCompany
	|		ELSE &Organization
	|	END							AS Organization
	|INTO ttCompaniesData
	|FROM
	|	ManufacturedProducts AS TableOfGoods
	|WHERE
	|	NOT &ProductionByThirdParty2_5
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.ProductionDate	AS Period,
	|	CASE
	|		WHEN NOT TableOfGoods.ProductOwner = VALUE(Catalog.Companies.EmptyRef)
	|			THEN TableOfGoods.ProductOwner
	|		WHEN &InternalSubcontracting
	|			THEN &MaterialProviderCompany
	|		ELSE &Organization
	|	END							AS Organization
	|FROM
	|	SideAndIntermediateRelease AS TableOfGoods
	|WHERE
	|	NOT &ProductionByThirdParty2_5
	|
	|INDEX BY
	|	Period,
	|	Organization";
	QueryTexts.Add(PartOfTheRequestText);
	
	PartOfTheRequestText = ExcisableGoodsAccounting.QueryTextManufacturersOfExcisableItems(
							TempTablesManager,
							"ttCompaniesData");
	QueryTexts.Add(PartOfTheRequestText);
	
	PartOfTheRequestText = 
	"SELECT
	|	NestedQuery.Organization										AS Organization,
	|	ManufacturersOfExcisableItems.Country							AS Country,
	|	&Currency															AS Currency,
	|	NestedQuery.TaxationOfOrganization						AS TaxationOfOrganization,
	|	UNDEFINED													AS Terms,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef)		AS VATTaxation,
	|	NestedQuery.BusinessOperation							AS BusinessOperation,
	|	NestedQuery.Department									AS Department,
	|	MAX(NestedQuery.LineNumber)							AS LineNumber,
	|	NestedQuery.Period											AS Period,
	|	NestedQuery.DateOfTransaction									AS DateOfTransaction,
	|	NestedQuery.Products									AS Products,
	|	NestedQuery.Characteristic									AS Characteristic,
	|	NestedQuery.Purpose										AS Purpose,
	|	NestedQuery.InventoryType										AS InventoryType,
	|	NestedQuery.GoodsOwner									AS GoodsOwner,
	|	NestedQuery.Counterparty										AS Counterparty,
	|	NestedQuery.Contract											AS Contract,
	|	NestedQuery.Recipient										AS Recipient,
	|	NestedQuery.ItemsLocationAttributes						AS ItemsLocationAttributes,
	|	NestedQuery.ProductCostElement								AS ProductCostElement,
	|	NestedQuery.ToExpenseAs								AS ToExpenseAs,
	|	NestedQuery.ExpenseItem									AS ExpenseItem,
	|	NestedQuery.DimensionOfExpenses								AS DimensionOfExpenses,
	|	NestedQuery.AssetsLiabilitiesDimension						AS AssetsLiabilitiesDimension,
	|	NestedQuery.GLAccountSettings							AS GLAccountSettings,
	|	NestedQuery.RowCode										AS RowCode,
	|	NestedQuery.RowID								AS RowID,
	|	NestedQuery.ProductOwner									AS ProductOwner,
	|	NestedQuery.CCDNumber										AS CCDNumber,
	|	SUM(NestedQuery.Count)								AS Count,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)					AS CurViewOfStocks,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)					AS InventoryOwnerAttribute,
	|	SUM(NestedQuery.CostShare)							AS CostShare,
	|	SUM(NestedQuery.Sum)									AS Sum,
	|	FALSE															AS ThisIsReusablePackage
	|INTO TableOfGoods
	|FROM
	|	(SELECT
	|		TableOfGoods.LineNumber + &OrderOfManufactureOfProduct					AS LineNumber,
	|		TableOfGoods.Period													AS Period,
	|		CASE
	|			WHEN &InternalSubcontracting
	|				THEN &MaterialProviderCompany
	|			ELSE &Organization
	|		END																	AS Organization,
	|		CASE
	|			WHEN &InternalSubcontracting
	|				THEN &TaxationOfGiverSCompany
	|			ELSE &TaxationOfOrganization
	|		END																	AS TaxationOfOrganization,
	|		TableOfGoods.Products												AS Products,
	|		TableOfGoods.Characteristic											AS Characteristic,
	|		TableOfGoods.Purpose												AS Purpose,
	|		CASE
	|			WHEN ISNULL(TableOfGoods.Purpose.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|					VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|					VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|				THEN VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			ELSE VALUE(Enum.InventoryTypes.OwnGoods)
	|		END																	AS InventoryType,
	|		CASE
	|			WHEN ISNULL(TableOfGoods.Purpose.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|					VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|					VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|				THEN TableOfGoods.Purpose.Partner
	|			WHEN &InternalSubcontracting
	|				THEN &MaterialProviderCompany
	|			ELSE &Organization
	|		END																	AS GoodsOwner,
	|		ISNULL(TableOfGoods.Purpose.Contract.Counterparty, UNDEFINED)	AS Counterparty,
	|		ISNULL(TableOfGoods.Purpose.Contract, UNDEFINED)				AS Contract,
	|		TableOfGoods.Recipient												AS Recipient,
	|		TableOfGoods.Count												AS Count,
	|		TableOfGoods.ItemsLocationAttributes								AS ItemsLocationAttributes,
	|		TableOfGoods.CCDNumber													AS CCDNumber,
	|		TableOfGoods.ProductionDate											AS DateOfTransaction,
	|		VALUE(Catalog.ProductCostElements.EmptyRef)						AS ProductCostElement,
	|		TableOfGoods.ToExpenseAs											AS ToExpenseAs,
	|		TableOfGoods.ExpenseItem											AS ExpenseItem,
	|		TableOfGoods.DimensionOfExpenses										AS DimensionOfExpenses,
	|		TableOfGoods.AssetsLiabilitiesDimension									AS AssetsLiabilitiesDimension,
	|		TableOfGoods.GLAccountSettings										AS GLAccountSettings,
	|		TableOfGoods.RowCode												AS RowCode,
	|		TableOfGoods.RowID										AS RowID,
	|		TableOfGoods.CostShare											AS CostShare,
	|		TableOfGoods.Sum													AS Sum,
	|		VALUE(Enum.BusinessTransactions.ProductsRelease)			AS BusinessOperation,
	|		TableOfGoods.Department											AS Department,
	|		VALUE(Catalog.Companies.EmptyRef)							AS ProductOwner
	|	FROM
	|		ManufacturedProducts AS TableOfGoods
	|	WHERE
	|		(NOT TableOfGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			OR TableOfGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|				AND TableOfGoods.Products.TracedGoods)
	|		AND TableOfGoods.Manufactured
	|		AND NOT TableOfGoods.Canceled
	|		AND NOT &ProductionByThirdParty2_5
	|		AND TableOfGoods.Period >= &PeriodFromWhichYouNeedToRecalculateTypesOfStocks
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableOfGoods.LineNumber + &OrderByProducts					AS LineNumber,
	|		TableOfGoods.Period													AS Period,
	|		CASE
	|			WHEN NOT TableOfGoods.ProductOwner = VALUE(Catalog.Companies.EmptyRef)
	|				THEN TableOfGoods.ProductOwner
	|			WHEN &InternalSubcontracting
	|				THEN &MaterialProviderCompany
	|			ELSE &Organization
	|		END																	AS Organization,
	|		CASE
	|			WHEN NOT TableOfGoods.ProductOwner = VALUE(Catalog.Companies.EmptyRef)
	|				THEN TableOfGoods.ProductOwner
	|			ELSE &TaxationOfOrganization
	|		END																	AS TaxationOfOrganization,
	|		TableOfGoods.Products												AS Products,
	|		TableOfGoods.Characteristic											AS Characteristic,
	|		TableOfGoods.Purpose												AS Purpose,
	|		CASE
	|			WHEN ISNULL(TableOfGoods.Purpose.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|					VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|					VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|				THEN VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			ELSE VALUE(Enum.InventoryTypes.OwnGoods)
	|		END																	AS InventoryType,
	|		CASE
	|			WHEN ISNULL(TableOfGoods.Purpose.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|					VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|					VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|				THEN TableOfGoods.Purpose.Partner
	|			WHEN NOT TableOfGoods.ProductOwner = VALUE(Catalog.Companies.EmptyRef)
	|				THEN TableOfGoods.ProductOwner
	|			ELSE &Organization
	|		END																	AS GoodsOwner,
	|		ISNULL(TableOfGoods.Purpose.Contract.Counterparty, UNDEFINED)	AS Counterparty,
	|		ISNULL(TableOfGoods.Purpose.Contract, UNDEFINED)				AS Contract,
	|		TableOfGoods.Recipient												AS Warehouse,
	|		TableOfGoods.Count												AS Count,
	|		TableOfGoods.ItemsLocationAttributes								AS ItemsLocationAttributes,
	|		TableOfGoods.CCDNumber													AS CCDNumber,
	|		TableOfGoods.ProductionDate											AS DateOfTransaction,
	|		TableOfGoods.ProductCostElement										AS ProductCostElement,
	|		TableOfGoods.ToExpenseAs											AS ToExpenseAs,
	|		TableOfGoods.ExpenseItem											AS ExpenseItem,
	|		TableOfGoods.DimensionOfExpenses										AS DimensionOfExpenses,
	|		TableOfGoods.AssetsLiabilitiesDimension									AS AssetsLiabilitiesDimension,
	|		TableOfGoods.GLAccountSettings										AS GLAccountSettings,
	|		TableOfGoods.RowCode												AS RowCode,
	|		TableOfGoods.RowID										AS RowID,
	|		0																		AS CostShare,
	|		TableOfGoods.Sum													AS Sum,
	|		VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost) AS BusinessOperation,
	|		TableOfGoods.Department											AS Department,
	|		TableOfGoods.ProductOwner											AS ProductOwner
	|	FROM
	|		SideAndIntermediateRelease AS TableOfGoods
	|	WHERE
	|		(NOT TableOfGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			OR TableOfGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|				AND TableOfGoods.Products.TracedGoods)
	|		AND TableOfGoods.Period >= &PeriodFromWhichYouNeedToRecalculateTypesOfStocks
	|		AND TableOfGoods.Manufactured
	|		AND NOT &ProductionByThirdParty2_5
	|		AND NOT TableOfGoods.Canceled
	|	) AS NestedQuery
	|		LEFT JOIN TTManufacturersOfExcisableItems AS ManufacturersOfExcisableItems
	|		ON NestedQuery.Organization = ManufacturersOfExcisableItems.Organization
	|			AND NestedQuery.DateOfTransaction = ManufacturersOfExcisableItems.Period
	|
	|GROUP BY
	|	NestedQuery.Organization,
	|	ManufacturersOfExcisableItems.Country,
	|	NestedQuery.TaxationOfOrganization,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Products,
	|	NestedQuery.Period,
	|	NestedQuery.Purpose,
	|	NestedQuery.InventoryType,
	|	NestedQuery.GoodsOwner,
	|	NestedQuery.Counterparty,
	|	NestedQuery.Contract,
	|	NestedQuery.Recipient,
	|	NestedQuery.ItemsLocationAttributes,
	|	NestedQuery.ProductOwner,
	|	NestedQuery.CCDNumber,
	|	NestedQuery.DateOfTransaction,
	|	NestedQuery.ProductCostElement,
	|	NestedQuery.ToExpenseAs,
	|	NestedQuery.ExpenseItem,
	|	NestedQuery.DimensionOfExpenses,
	|	NestedQuery.AssetsLiabilitiesDimension,
	|	NestedQuery.GLAccountSettings,
	|	NestedQuery.RowCode,
	|	NestedQuery.RowID,
	|	NestedQuery.BusinessOperation,
	|	NestedQuery.Department
	|";
	QueryTexts.Add(PartOfTheRequestText);
	
	RequestTextParameters = ExcisableGoodsAccounting.ParametersOfQueryTextTTExciseCategoriesOfItems();
	RequestTextParameters.SelectingCategoriesByDate	= False;
	RequestTextParameters.CountryWH			= True;
	RequestTextParameters.FieldNamePeriod		= "DateOfTransaction";
	
	QueryTexts.Add(ExcisableGoodsAccounting.QueryTextTTExciseCategoriesOfItems(
							TempTablesManager,
							RequestTextParameters));
	
	PartOfTheRequestText = 
	"SELECT
	|	TableOfGoods.Organization							AS Organization,
	|	TableOfGoods.Currency								AS Currency,
	|	TableOfGoods.TaxationOfOrganization			AS TaxationOfOrganization,
	|	TableOfGoods.Terms							AS Terms,
	|	TableOfGoods.VATTaxation					AS VATTaxation,
	|	TableOfGoods.BusinessOperation				AS BusinessOperation,
	|	TableOfGoods.Department						AS Department,
	|	TableOfGoods.LineNumber							AS LineNumber,
	|	TableOfGoods.Period								AS Period,
	|	TableOfGoods.DateOfTransaction							AS DateOfTransaction,
	|	TableOfGoods.Products							AS Products,
	|	TableOfGoods.Characteristic						AS Characteristic,
	|	TableOfGoods.Purpose							AS Purpose,
	|	TableOfGoods.InventoryType							AS InventoryType,
	|	TableOfGoods.GoodsOwner						AS GoodsOwner,
	|	TableOfGoods.Counterparty							AS Counterparty,
	|	TableOfGoods.Contract								AS Contract,
	|	TableOfGoods.Recipient							AS Recipient,
	|	TableOfGoods.ItemsLocationAttributes			AS ItemsLocationAttributes,
	|	TableOfGoods.ProductCostElement					AS ProductCostElement,
	|	TableOfGoods.ToExpenseAs						AS ToExpenseAs,
	|	TableOfGoods.ExpenseItem						AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses					AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension				AS AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings					AS GLAccountSettings,
	|	TableOfGoods.RowCode							AS RowCode,
	|	TableOfGoods.RowID					AS RowID,
	|	TableOfGoods.ProductOwner						AS ProductOwner,
	|	TableOfGoods.CCDNumber								AS CCDNumber,
	|	TableOfGoods.Count							AS Count,
	|	TableOfGoods.CurViewOfStocks					AS CurViewOfStocks,
	|	TableOfGoods.InventoryOwnerAttribute							AS InventoryOwnerAttribute,
	|	TableOfGoods.CostShare						AS CostShare,
	|	TableOfGoods.Sum								AS Sum,
	|	TableOfGoods.ThisIsReusablePackage					AS ThisIsReusablePackage,
	|	ISNULL(Category_Data.ExcisableGoods, FALSE)	AS SubjectToExcise,
	|	&Department										AS BusinessUnitProduction
	|INTO OriginalProductTable
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN TTExciseCategoriesOfItems AS Category_Data
	|		ON TableOfGoods.Products = Category_Data.Products
	|			AND TableOfGoods.Country = Category_Data.Country
	|			AND TableOfGoods.DateOfTransaction = Category_Data.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ttCompaniesData";
	QueryTexts.Add(PartOfTheRequestText);
	
	TaxationOfOrganization	=
		VATAccountingERP.AccountingParametersForOrganization(Organization, Date).BasicTaxationVATSales;
	TaxationOfGiverSCompany = VATAccountingERP.AccountingParametersForOrganization(MaterialProviderCompany, Date).BasicTaxationVATSales;
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods");
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("Organization",				Organization);
	Query.SetParameter("MainCountry",				SettingsValueClientServerCached.MainCountry());
	Query.SetParameter("Department",				Department);
	Query.SetParameter("Currency",						Currency);
	Query.SetParameter("OrderOfManufactureOfProduct",		OrderOfTS("ManufacturedProducts"));
	Query.SetParameter("OrderByProducts",		OrderOfTS("SideAndIntermediateRelease"));
	Query.SetParameter("TaxationOfOrganization",	TaxationOfOrganization);
	Query.SetParameter("PeriodFromWhichYouNeedToRecalculateTypesOfStocks", AdditionalProperties.PeriodFromWhichYouNeedToRecalculateTypesOfStocks);
	Query.SetParameter("InternalSubcontracting",		InternalSubcontracting);
	Query.SetParameter("MaterialProviderCompany",			MaterialProviderCompany);
	Query.SetParameter("ProductionByThirdParty2_5",	ProductionByThirdParty2_5);
	Query.SetParameter("UseExcisableGoods", UseExcisableGoods);
	Query.SetParameter("TaxationOfGiverSCompany", TaxationOfGiverSCompany);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	Result = Query.ExecuteBatchWithIntermediateData();
	
	Return Result[Result.UBound() - 2].Unload();
	
EndFunction

Procedure TemporaryTablesToFillInInventoryTypesMaterials(TempTablesManager)
	
	// In the Balance filling algorithm, you need to transfer the amount of goods
	// that is not covered by quantities from other table parts within the same period.
	// 
	// After filling in the Balances, the amount will be supplemented by the one that is covered by quantities from
	// other tabular parts. Therefore, the formulas for calculating the amount of Balances are as follows
	// 
	// To write off from the pantry: Provision - Savings
	// For debiting from a division: Expense + Savings - Provision
	// When writing off a unit, the entire amount can be taken from the Balance table or from collateral
	// for the same period. For expenses and cost savings, the distribution between these itochniki is made
	// in the request itself. To save money in another (relative to the one from which the pantry was provided), the distribution
	// is then done in a cycle.
	// 
	// You also need to take into account that the document makes the following movements:
	// 	Expense from the unit = all savings + all expenses
	// 	Coming to the unit = provision that is made only from the storerooms of this unit
	// 	Consumption from the warehouse = provision only for the storerooms of this division
	// 	Coming to the warehouse = saving only on the storerooms of this division
	// 
	// Inside the Balance filling algorithm, Balances from the registers will be added
	// 	Types of stocks coming from Output and By-products
	//  Types of stocks selected for previous periods of this document (i.e., in one period, they selected
	//  collateral for Balances, and in the other, they filled out the types of stocks in the expense)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	MAX(ExpenseFromDivisionForEmptyCoreAnalytics.LineNumber)			AS LineNumber,
	|	&BusinessTransactionExpense														AS BusinessOperation,
	|	ExpenseFromDivisionForEmptyCoreAnalytics.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)		AS CorItemsLocationAttributes,
	|	CASE
	|		WHEN SUM(ExpenseFromDivisionForEmptyCoreAnalytics.CountReceipt) > SUM(ExpenseFromDivisionForEmptyCoreAnalytics.CountExpense)
	|			THEN 0
	|		ELSE SUM(ExpenseFromDivisionForEmptyCoreAnalytics.CountExpense) - SUM(ExpenseFromDivisionForEmptyCoreAnalytics.CountReceipt)
	|	END																	AS QuantityByBalance,
	|	CASE
	|		WHEN SUM(ExpenseFromDivisionForEmptyCoreAnalytics.CountReceipt) > SUM(ExpenseFromDivisionForEmptyCoreAnalytics.CountExpense)
	|			THEN SUM(ExpenseFromDivisionForEmptyCoreAnalytics.CountExpense)
	|		ELSE SUM(ExpenseFromDivisionForEmptyCoreAnalytics.CountReceipt)
	|	END																	AS CurPeriodQuantity,
	|	CASE
	|		WHEN SUM(ExpenseFromDivisionForEmptyCoreAnalytics.QuantityByGBRNReceipt) > SUM(ExpenseFromDivisionForEmptyCoreAnalytics.QuantityByGBRNExpense)
	|			THEN 0
	|		ELSE SUM(ExpenseFromDivisionForEmptyCoreAnalytics.QuantityByGBRNExpense) - SUM(ExpenseFromDivisionForEmptyCoreAnalytics.QuantityByGBRNReceipt)
	|	END																	AS QuantityByRNPTByBalance,
	|	CASE
	|		WHEN SUM(ExpenseFromDivisionForEmptyCoreAnalytics.QuantityByGBRNReceipt) > SUM(ExpenseFromDivisionForEmptyCoreAnalytics.QuantityByGBRNExpense)
	|			THEN SUM(ExpenseFromDivisionForEmptyCoreAnalytics.QuantityByGBRNExpense)
	|		ELSE SUM(ExpenseFromDivisionForEmptyCoreAnalytics.QuantityByGBRNReceipt)
	|	END																	AS QuantityByRPTForCurPeriod,
	|	ExpenseFromDivisionForEmptyCoreAnalytics.Period						AS Period,
	|	ExpenseFromDivisionForEmptyCoreAnalytics.CCDNumber						AS CCDNumber
	|INTO ConsumptionOfMaterialsAndWorksBySources
	|FROM
	|	(SELECT
	|		MaterialsAndWorksConsumption.LineNumber + &OrderExpense	AS LineNumber,
	|		MaterialsAndWorksConsumption.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		MaterialsAndWorksConsumption.Count					AS CountExpense,
	|		0													AS CountReceipt,
	|		MaterialsAndWorksConsumption.QuantityByGBRN				AS QuantityByGBRNExpense,
	|		0													AS QuantityByGBRNReceipt,
	|		MaterialsAndWorksConsumption.Period						AS Period,
	|		MaterialsAndWorksConsumption.CCDNumber						AS CCDNumber
	|	FROM
	|		MaterialsAndWorksConsumption AS MaterialsAndWorksConsumption
	|	
	|	WHERE
	|		MaterialsAndWorksConsumption.Period >= &PeriodFromWhichYouNeedToRecalculateTypesOfStocks
	|		AND NOT &ProductionByThirdParty2_5
	|		AND NOT MaterialsAndWorksConsumption.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ConsumptionAndArrivalInStorerooms.LineNumber + &SecurityProcedure,
	|		ConsumptionAndArrivalInStorerooms.CorItemsLocationAttributes,
	|		0,
	|		ConsumptionAndArrivalInStorerooms.Count,
	|		0,
	|		ConsumptionAndArrivalInStorerooms.QuantityByGBRN,
	|		ConsumptionAndArrivalInStorerooms.Period,
	|		ConsumptionAndArrivalInStorerooms.CCDNumber
	|	FROM
	|		ConsumptionAndArrivalInStorerooms AS ConsumptionAndArrivalInStorerooms
	|	
	|	WHERE
	|		ConsumptionAndArrivalInStorerooms.Period >= &PeriodFromWhichYouNeedToRecalculateTypesOfStocks
	|		AND ConsumptionAndArrivalInStorerooms.BusinessOperation = &BusinessTransactionSupply) AS ExpenseFromDivisionForEmptyCoreAnalytics
	|
	|GROUP BY
	|	ExpenseFromDivisionForEmptyCoreAnalytics.ItemsLocationAttributes,
	|	ExpenseFromDivisionForEmptyCoreAnalytics.Period,
	|	ExpenseFromDivisionForEmptyCoreAnalytics.CCDNumber
	|
	|HAVING
	|	(CASE
	|		WHEN SUM(ExpenseFromDivisionForEmptyCoreAnalytics.CountReceipt) > SUM(ExpenseFromDivisionForEmptyCoreAnalytics.CountExpense)
	|			THEN 0
	|		ELSE SUM(ExpenseFromDivisionForEmptyCoreAnalytics.CountExpense) - SUM(ExpenseFromDivisionForEmptyCoreAnalytics.CountReceipt)
	|	END > 0
	|	OR CASE
	|			WHEN SUM(ExpenseFromDivisionForEmptyCoreAnalytics.CountReceipt) > SUM(ExpenseFromDivisionForEmptyCoreAnalytics.CountExpense)
	|				THEN SUM(ExpenseFromDivisionForEmptyCoreAnalytics.CountExpense)
	|			ELSE SUM(ExpenseFromDivisionForEmptyCoreAnalytics.CountReceipt)
	|		END > 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ConsumptionAndArrivalInStorerooms.LineNumber						AS LineNumber,
	|	&InternalSubcontracting									AS InternalSubcontracting,
	|	&MaterialProviderCompany										AS MaterialProviderCompany,
	|	ConsumptionAndArrivalInStorerooms.BusinessOperation			AS BusinessOperation,
	|	ConsumptionAndArrivalInStorerooms.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	ConsumptionAndArrivalInStorerooms.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|	ConsumptionAndArrivalInStorerooms.Count						AS QuantityByBalance,
	|	0														AS CurPeriodQuantity,
	|	ConsumptionAndArrivalInStorerooms.QuantityByGBRN					AS QuantityByRNPTByBalance,
	|	0														AS QuantityByRPTForCurPeriod,
	|	ConsumptionAndArrivalInStorerooms.Period							AS Period,
	|	ConsumptionAndArrivalInStorerooms.CCDNumber							AS CCDNumber
	|INTO TableOfProductsByPeriod
	|FROM
	|	ConsumptionAndArrivalInStorerooms AS ConsumptionAndArrivalInStorerooms
	|
	|WHERE
	|	ConsumptionAndArrivalInStorerooms.Period >= &PeriodFromWhichYouNeedToRecalculateTypesOfStocks
	|
	|UNION ALL
	|
	|SELECT
	|	ConsumptionOfMaterialsAndWorksBySources.LineNumber,
	|	&InternalSubcontracting,
	|	&MaterialProviderCompany,
	|	ConsumptionOfMaterialsAndWorksBySources.BusinessOperation,
	|	ConsumptionOfMaterialsAndWorksBySources.ItemsLocationAttributes,
	|	ConsumptionOfMaterialsAndWorksBySources.CorItemsLocationAttributes,
	|	ConsumptionOfMaterialsAndWorksBySources.QuantityByBalance,
	|	ConsumptionOfMaterialsAndWorksBySources.CurPeriodQuantity,
	|	ConsumptionOfMaterialsAndWorksBySources.QuantityByRNPTByBalance,
	|	ConsumptionOfMaterialsAndWorksBySources.QuantityByRPTForCurPeriod,
	|	ConsumptionOfMaterialsAndWorksBySources.Period,
	|	ConsumptionOfMaterialsAndWorksBySources.CCDNumber
	|FROM
	|	ConsumptionOfMaterialsAndWorksBySources AS ConsumptionOfMaterialsAndWorksBySources
	|
	|WHERE
	|	(ConsumptionOfMaterialsAndWorksBySources.QuantityByBalance > 0
	|			OR ConsumptionOfMaterialsAndWorksBySources.CurPeriodQuantity > 0)
	|
	|UNION ALL
	|
	|SELECT
	|	MAX(SavingMaterialsWriteOffBySource.LineNumber),
	|	&InternalSubcontracting,
	|	&MaterialProviderCompany,
	|	&HouseholdsSavingMaterialsWriteOff,
	|	SavingMaterialsWriteOffBySource.ItemsLocationAttributes,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef),
	|	CASE
	|		WHEN SUM(SavingMaterialsWriteOffBySource.CountReceipt) > SUM(SavingMaterialsWriteOffBySource.CountExpense)
	|			THEN 0
	|		ELSE SUM(SavingMaterialsWriteOffBySource.CountExpense) - SUM(SavingMaterialsWriteOffBySource.CountReceipt)
	|	END,
	|	CASE
	|		WHEN SUM(SavingMaterialsWriteOffBySource.CountReceipt) > SUM(SavingMaterialsWriteOffBySource.CountExpense)
	|			THEN SUM(SavingMaterialsWriteOffBySource.CountExpense)
	|		ELSE SUM(SavingMaterialsWriteOffBySource.CountReceipt)
	|	END,
	|	CASE
	|		WHEN SUM(SavingMaterialsWriteOffBySource.QuantityByGBRNReceipt) > SUM(SavingMaterialsWriteOffBySource.QuantityByGBRNExpense)
	|			THEN 0
	|		ELSE SUM(SavingMaterialsWriteOffBySource.QuantityByGBRNExpense) - SUM(SavingMaterialsWriteOffBySource.QuantityByGBRNReceipt)
	|	END,
	|	CASE
	|		WHEN SUM(SavingMaterialsWriteOffBySource.QuantityByGBRNReceipt) > SUM(SavingMaterialsWriteOffBySource.QuantityByGBRNExpense)
	|			THEN SUM(SavingMaterialsWriteOffBySource.QuantityByGBRNExpense)
	|		ELSE SUM(SavingMaterialsWriteOffBySource.QuantityByGBRNReceipt)
	|	END,
	|	SavingMaterialsWriteOffBySource.Period,
	|	SavingMaterialsWriteOffBySource.CCDNumber
	|FROM
	|	(SELECT
	|		UnusedMaterials.LineNumber + &OrderSaving	AS LineNumber,
	|		UnusedMaterials.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|		UnusedMaterials.Count						AS CountExpense,
	|		0													AS CountReceipt,
	|		UnusedMaterials.QuantityByGBRN					AS QuantityByGBRNExpense,
	|		0													AS QuantityByGBRNReceipt,
	|		UnusedMaterials.Period							AS Period,
	|		UnusedMaterials.CCDNumber							AS CCDNumber
	|	FROM
	|		UnusedMaterials AS UnusedMaterials
	|	
	|	WHERE
	|		UnusedMaterials.Period >= &PeriodFromWhichYouNeedToRecalculateTypesOfStocks
	|		AND UnusedMaterials.ToExpenseAs
	|		AND NOT &ProductionByThirdParty2_5
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ConsumptionAndArrivalInStorerooms.LineNumber + &SecurityProcedure,
	|		ConsumptionAndArrivalInStorerooms.CorItemsLocationAttributes,
	|		0,
	|		ConsumptionAndArrivalInStorerooms.Count,
	|		0,
	|		ConsumptionAndArrivalInStorerooms.QuantityByGBRN,
	|		ConsumptionAndArrivalInStorerooms.Period,
	|		ConsumptionAndArrivalInStorerooms.CCDNumber
	|	FROM
	|		ConsumptionAndArrivalInStorerooms AS ConsumptionAndArrivalInStorerooms
	|	
	|	WHERE
	|		ConsumptionAndArrivalInStorerooms.Period >= &PeriodFromWhichYouNeedToRecalculateTypesOfStocks
	|		AND ConsumptionAndArrivalInStorerooms.BusinessOperation = &BusinessTransactionSupply
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ConsumptionOfMaterialsAndWorksBySources.LineNumber + &SecurityProcedure,
	|		ConsumptionOfMaterialsAndWorksBySources.CorItemsLocationAttributes,
	|		0,
	|		-ConsumptionOfMaterialsAndWorksBySources.CurPeriodQuantity,
	|		0,
	|		-ConsumptionOfMaterialsAndWorksBySources.QuantityByRPTForCurPeriod,
	|		ConsumptionOfMaterialsAndWorksBySources.Period,
	|		ConsumptionOfMaterialsAndWorksBySources.CCDNumber
	|	FROM
	|		ConsumptionOfMaterialsAndWorksBySources AS ConsumptionOfMaterialsAndWorksBySources
	|	
	|	WHERE
	|		ConsumptionOfMaterialsAndWorksBySources.CurPeriodQuantity > 0) AS SavingMaterialsWriteOffBySource
	|
	|GROUP BY
	|	SavingMaterialsWriteOffBySource.ItemsLocationAttributes,
	|	SavingMaterialsWriteOffBySource.Period,
	|	SavingMaterialsWriteOffBySource.CCDNumber
	|
	|HAVING
	|	CASE
	|		WHEN SUM(SavingMaterialsWriteOffBySource.CountReceipt) > SUM(SavingMaterialsWriteOffBySource.CountExpense)
	|			THEN 0
	|		ELSE SUM(SavingMaterialsWriteOffBySource.CountExpense) - SUM(SavingMaterialsWriteOffBySource.CountReceipt)
	|	END + CASE
	|		WHEN SUM(SavingMaterialsWriteOffBySource.CountReceipt) > SUM(SavingMaterialsWriteOffBySource.CountExpense)
	|			THEN SUM(SavingMaterialsWriteOffBySource.CountExpense)
	|		ELSE SUM(SavingMaterialsWriteOffBySource.CountReceipt)
	|	END > 0
	|
	|UNION ALL
	|
	|SELECT
	|	MAX(Software_3.LineNumber + &SecurityProcedure)	AS LineNumber,
	|	&InternalSubcontracting								AS InternalSubcontracting,
	|	&MaterialProviderCompany									AS MaterialProviderCompany,
	|	&BusinessTransactionSupply								AS BusinessOperation,
	|	Software_3.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	Software_3.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|	SUM(Software_3.Count)				AS CountExpense,
	|	0													AS CountReceipt,
	|	SUM(Software_3.QuantityByGBRN)			AS QuantityByGBRNExpense,
	|	0													AS QuantityByGBRNReceipt,
	|	Software_3.Period							AS Period,
	|	Software_3.CCDNumber							AS CCDNumber
	|FROM
	|	SupplyWithMaterialsAndWorks AS Software_3
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON Software_3.Products = CatalogProducts.Ref
	|
	|WHERE
	|	NOT Software_3.Canceled
	|	AND Software_3.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND &UseTraceableImportedGoodsAccounting
	|	AND CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND CatalogProducts.TracedGoods
	|	AND Software_3.Period >= &PeriodFromWhichYouNeedToRecalculateTypesOfStocks
	|
	|GROUP BY
	|	Software_3.ItemsLocationAttributes,
	|	Software_3.CorItemsLocationAttributes,
	|	Software_3.Period,
	|	Software_3.CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber						AS LineNumber,
	|	TableTypesOfStocks_.Period							AS Period,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.BusinessOperation			AS BusinessOperation,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber							AS CCDNumber,
	|	TableTypesOfStocks_.Count						AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN					AS QuantityByGBRN
	|INTO TableTypesOfStocksByPeriod
	|FROM
	|	TTStockTypesMaterials AS TableTypesOfStocks_
	|
	|WHERE
	|	TableTypesOfStocks_.Period >= &PeriodFromWhichYouNeedToRecalculateTypesOfStocks
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UndistributedBalanceOfCurPeriod.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	SUM(UndistributedBalanceOfCurPeriod.Count)			AS Count,
	|	SUM(UndistributedBalanceOfCurPeriod.QuantityByGBRN)	AS QuantityByGBRN,
	|	UndistributedBalanceOfCurPeriod.Period						AS Period,
	|	UndistributedBalanceOfCurPeriod.CCDNumber					AS CCDNumber
	|INTO UndistributedBalanceOfCurPeriod
	|FROM
	|	(SELECT
	|		TableOfProductsByPeriod.CorItemsLocationAttributes	AS ItemsLocationAttributes,
	|		TableOfProductsByPeriod.QuantityByBalance			AS Count,
	|		TableOfProductsByPeriod.QuantityByRNPTByBalance		AS QuantityByGBRN,
	|		TableOfProductsByPeriod.Period							AS Period,
	|		TableOfProductsByPeriod.CCDNumber						AS CCDNumber
	|	FROM
	|		TableOfProductsByPeriod AS TableOfProductsByPeriod
	|	
	|	WHERE
	|		TableOfProductsByPeriod.BusinessOperation = &BusinessTransactionSupply
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableOfProductsByPeriod.ItemsLocationAttributes,
	|		-TableOfProductsByPeriod.CurPeriodQuantity,
	|		-TableOfProductsByPeriod.QuantityByRPTForCurPeriod,
	|		TableOfProductsByPeriod.Period,
	|		TableOfProductsByPeriod.CCDNumber
	|	FROM
	|		TableOfProductsByPeriod AS TableOfProductsByPeriod
	|	
	|	WHERE
	|		TableOfProductsByPeriod.BusinessOperation <> &BusinessTransactionSupply) AS UndistributedBalanceOfCurPeriod
	|
	|GROUP BY
	|	UndistributedBalanceOfCurPeriod.ItemsLocationAttributes,
	|	UndistributedBalanceOfCurPeriod.Period,
	|	UndistributedBalanceOfCurPeriod.CCDNumber
	|
	|HAVING
	|	SUM(UndistributedBalanceOfCurPeriod.Count) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReturnsToAnotherPantryForDistribution.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	ReturnsToAnotherPantryForDistribution.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|	ReturnsToAnotherPantryForDistribution.CCDNumber						AS CCDNumber,
	|	ReturnsToAnotherPantryForDistribution.QuantityByBalance			AS QuantityByBalance,
	|	ReturnsToAnotherPantryForDistribution.CurPeriodQuantity	AS CurPeriodQuantity,
	|	ReturnsToAnotherPantryForDistribution.QuantityByRNPTByBalance		AS QuantityByRNPTByBalance,
	|	ReturnsToAnotherPantryForDistribution.QuantityByRPTForCurPeriod AS QuantityByRPTForCurPeriod,
	|	ReturnsToAnotherPantryForDistribution.Period						AS Period,
	|	ReturnsToAnotherPantryForDistribution.LineNumber					AS LineNumber,
	|	ReturnsToAnotherPantryForDistribution.BusinessOperation			AS BusinessOperation
	|INTO ReturnsToAnotherPantryForDistribution
	|FROM
	|	TableOfProductsByPeriod AS ReturnsToAnotherPantryForDistribution
	|WHERE
	|	ReturnsToAnotherPantryForDistribution.BusinessOperation = &HozSavingMaterialsRefund
	|	AND NOT &ProductionByThirdParty2_5
	|	AND (ReturnsToAnotherPantryForDistribution.ItemsLocationAttributes, ReturnsToAnotherPantryForDistribution.Period, ReturnsToAnotherPantryForDistribution.CCDNumber) IN
	|			(SELECT
	|				UndistributedBalanceOfCurPeriod.ItemsLocationAttributes,
	|				UndistributedBalanceOfCurPeriod.Period,
	|				UndistributedBalanceOfCurPeriod.CCDNumber
	|			FROM
	|				UndistributedBalanceOfCurPeriod)";
	
	Query.SetParameter("SecurityProcedure",				OrderOfTS("SupplyWithMaterialsAndWorks"));
	Query.SetParameter("OrderSaving",				OrderOfTS("UnusedMaterials"));
	Query.SetParameter("OrderExpense",					OrderOfTS("MaterialsAndWorksConsumption"));	
	Query.SetParameter("HouseholdsSavingMaterialsWriteOff",	BusinessOperationNamedTS("SavingMaterialsWriteOff"));
	Query.SetParameter("HozSavingMaterialsRefund",	BusinessOperationNamedTS("SavingMaterialsReturn"));
	Query.SetParameter("BusinessTransactionExpense",				BusinessOperationNamedTS("MaterialsAndWorksConsumption"));
	Query.SetParameter("BusinessTransactionSupply",			BusinessOperationNamedTS("SupplyWithMaterialsAndWorks"));
	Query.SetParameter("PeriodFromWhichYouNeedToRecalculateTypesOfStocks",
								AdditionalProperties.PeriodFromWhichYouNeedToRecalculateTypesOfStocks);
	Query.SetParameter("InternalSubcontracting",    InternalSubcontracting);
	Query.SetParameter("MaterialProviderCompany",       MaterialProviderCompany);
	Query.SetParameter("ProductionByThirdParty2_5", ProductionByThirdParty2_5);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	QueryResults = Query.ExecuteBatchWithIntermediateData();
	
	ReturnsToAnotherPantryForDistribution = QueryResults[QueryResults.UBound()].Unload();
	
	If ReturnsToAnotherPantryForDistribution.Count() = 0 Then
		Return;
	EndIf;
	
	SearchFields	= "ItemsLocationAttributes, Period, CCDNumber";
	SearchSelection	= New Structure(SearchFields);
	
	UndistributedBalanceOfCurPeriod = QueryResults[QueryResults.UBound() - 1].Unload();
	UndistributedBalanceOfCurPeriod.Indexes.Add(SearchFields);
	
	For Each ReturnString In ReturnsToAnotherPantryForDistribution Do
		
		FillPropertyValues(SearchSelection, ReturnString);
		
		RemainderLineToDistribution = UndistributedBalanceOfCurPeriod.FindRows(SearchSelection)[0];
		
		If RemainderLineToDistribution.Count = 0 Then
			Continue;
		EndIf;
		
		QuantityFromRemainder = Min(ReturnString.QuantityByBalance, RemainderLineToDistribution.Count);
		AmountOfRNPTFromBalance = Min(ReturnString.QuantityByRNPTByBalance, RemainderLineToDistribution.QuantityByGBRN);
		
		ReturnString.QuantityByBalance			= ReturnString.QuantityByBalance - QuantityFromRemainder;
		ReturnString.CurPeriodQuantity	= ReturnString.CurPeriodQuantity + QuantityFromRemainder;
		
		ReturnString.QuantityByRNPTByBalance			= ReturnString.QuantityByRNPTByBalance - AmountOfRNPTFromBalance;
		ReturnString.QuantityByRPTForCurPeriod	= ReturnString.QuantityByRPTForCurPeriod + AmountOfRNPTFromBalance;
		
		RemainderLineToDistribution.Count			= RemainderLineToDistribution.Count - QuantityFromRemainder;
		RemainderLineToDistribution.QuantityByGBRN	= RemainderLineToDistribution.QuantityByGBRN - AmountOfRNPTFromBalance;
		
	EndDo;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	ReturnsToAnotherPantryDistributed.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	ReturnsToAnotherPantryDistributed.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|	ReturnsToAnotherPantryDistributed.QuantityByBalance			AS QuantityByBalance,
	|	ReturnsToAnotherPantryDistributed.CurPeriodQuantity	AS CurPeriodQuantity,
	|	ReturnsToAnotherPantryDistributed.QuantityByRNPTByBalance		AS QuantityByRNPTByBalance,
	|	ReturnsToAnotherPantryDistributed.QuantityByRPTForCurPeriod	AS QuantityByRPTForCurPeriod,
	|	ReturnsToAnotherPantryDistributed.Period						AS Period,
	|	ReturnsToAnotherPantryDistributed.LineNumber					AS LineNumber,
	|	ReturnsToAnotherPantryDistributed.BusinessOperation			AS BusinessOperation,
	|	ReturnsToAnotherPantryDistributed.CCDNumber						AS CCDNumber
	|INTO ReturnsToAnotherPantryDistributed
	|FROM
	|	&ReturnsToAnotherPantryDistributed AS ReturnsToAnotherPantryDistributed
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfProductsByPeriod.LineNumber					AS LineNumber,
	|	TableOfProductsByPeriod.BusinessOperation			AS BusinessOperation,
	|	TableOfProductsByPeriod.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableOfProductsByPeriod.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|	TableOfProductsByPeriod.QuantityByBalance			AS QuantityByBalance,
	|	TableOfProductsByPeriod.CurPeriodQuantity	AS CurPeriodQuantity,
	|	TableOfProductsByPeriod.QuantityByRNPTByBalance		AS QuantityByRNPTByBalance,
	|	TableOfProductsByPeriod.QuantityByRPTForCurPeriod	AS QuantityByRPTForCurPeriod,
	|	TableOfProductsByPeriod.Period							AS Period,
	|	TableOfProductsByPeriod.CCDNumber						AS CCDNumber
	|INTO TableOfProductsByPeriodWithoutReturnsToDistribution
	|FROM
	|	TableOfProductsByPeriod AS TableOfProductsByPeriod
	|WHERE
	|	NOT (TableOfProductsByPeriod.LineNumber, TableOfProductsByPeriod.BusinessOperation, TableOfProductsByPeriod.ItemsLocationAttributes, TableOfProductsByPeriod.CorItemsLocationAttributes, TableOfProductsByPeriod.Period, TableOfProductsByPeriod.CCDNumber) IN
	|				(SELECT
	|					ReturnsToAnotherPantryForDistribution.LineNumber,
	|					ReturnsToAnotherPantryForDistribution.BusinessOperation,
	|					ReturnsToAnotherPantryForDistribution.ItemsLocationAttributes,
	|					ReturnsToAnotherPantryForDistribution.CorItemsLocationAttributes,
	|					ReturnsToAnotherPantryForDistribution.Period,
	|					ReturnsToAnotherPantryForDistribution.CCDNumber
	|				FROM
	|					ReturnsToAnotherPantryForDistribution)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TableOfProductsByPeriod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfProductsByPeriodWithoutReturnsToDistribution.LineNumber AS LineNumber,
	|	&InternalSubcontracting									AS InternalSubcontracting,
	|	&MaterialProviderCompany										AS MaterialProviderCompany,
	|	TableOfProductsByPeriodWithoutReturnsToDistribution.BusinessOperation AS BusinessOperation,
	|	TableOfProductsByPeriodWithoutReturnsToDistribution.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfProductsByPeriodWithoutReturnsToDistribution.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	TableOfProductsByPeriodWithoutReturnsToDistribution.QuantityByBalance AS QuantityByBalance,
	|	TableOfProductsByPeriodWithoutReturnsToDistribution.CurPeriodQuantity AS CurPeriodQuantity,
	|	TableOfProductsByPeriodWithoutReturnsToDistribution.QuantityByRNPTByBalance AS QuantityByRNPTByBalance,
	|	TableOfProductsByPeriodWithoutReturnsToDistribution.QuantityByRPTForCurPeriod AS QuantityByRPTForCurPeriod,
	|	TableOfProductsByPeriodWithoutReturnsToDistribution.Period AS Period,
	|	TableOfProductsByPeriodWithoutReturnsToDistribution.CCDNumber AS CCDNumber
	|INTO TableOfProductsByPeriod
	|FROM
	|	TableOfProductsByPeriodWithoutReturnsToDistribution AS TableOfProductsByPeriodWithoutReturnsToDistribution
	|
	|UNION ALL
	|
	|SELECT
	|	ReturnsToAnotherPantryDistributed.LineNumber,
	|	&InternalSubcontracting									AS InternalSubcontracting,
	|	&MaterialProviderCompany										AS MaterialProviderCompany,
	|	ReturnsToAnotherPantryDistributed.BusinessOperation,
	|	ReturnsToAnotherPantryDistributed.ItemsLocationAttributes,
	|	ReturnsToAnotherPantryDistributed.CorItemsLocationAttributes,
	|	ReturnsToAnotherPantryDistributed.QuantityByBalance,
	|	ReturnsToAnotherPantryDistributed.CurPeriodQuantity,
	|	ReturnsToAnotherPantryDistributed.QuantityByRNPTByBalance,
	|	ReturnsToAnotherPantryDistributed.QuantityByRPTForCurPeriod,
	|	ReturnsToAnotherPantryDistributed.Period,
	|	ReturnsToAnotherPantryDistributed.CCDNumber
	|FROM
	|	ReturnsToAnotherPantryDistributed AS ReturnsToAnotherPantryDistributed";
	
	Query.SetParameter("ReturnsToAnotherPantryDistributed", ReturnsToAnotherPantryForDistribution);
	Query.SetParameter("InternalSubcontracting",                 InternalSubcontracting);
	Query.SetParameter("MaterialProviderCompany",                    MaterialProviderCompany);
	
	Query.Execute();
	
EndProcedure

Procedure PeriodFromWhichYouNeedToRecalculateTypesOfStocks(TempTablesManager)
	
	RefillInventoryKinds = InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
	
	If RefillInventoryKinds 
		And AdditionalProperties.Property("BeginningOfPeriodForCorrectingBalances") Then
		AdditionalProperties.Insert(
			"PeriodFromWhichYouNeedToRecalculateTypesOfStocks",
			AdditionalProperties.BeginningOfPeriodForCorrectingBalances);
		Return;
	EndIf;
	
	RefillInventoryKinds =
		InventoriesServer.CheckChangesToDocumentDetails(
			TempTablesManager,
			Ref,
			"Organization, InternalSubcontracting, MaterialProviderCompany");
	
	If RefillInventoryKinds Then
		AdditionalProperties.Insert("PeriodFromWhichYouNeedToRecalculateTypesOfStocks", Date(1, 1, 1));
		Return;
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text =
	"SELECT
	|	MIN(NestedRequest.Period)	AS Period
	|FROM
	|	(SELECT
	|		NestedQueryOutputItems.Period		AS Period
	|	FROM
	|		(SELECT
	|			ManufacturedProducts.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|			-ManufacturedProducts.Count					AS Count,
	|			-ManufacturedProducts.Sum						AS Sum,
	|			ManufacturedProducts.ProductionDate			AS DateOfTransaction,
	|			ManufacturedProducts.ToExpenseAs			AS ToExpenseAs,
	|			ManufacturedProducts.ExpenseItem				AS ExpenseItem,
	|			ManufacturedProducts.DimensionOfExpenses			AS DimensionOfExpenses,
	|			ManufacturedProducts.RowID			AS RowID,
	|			ManufacturedProducts.RowCode					AS RowCode,
	|			ManufacturedProducts.CostShare				AS CostShare,
	|			ManufacturedProducts.Period						AS Period,
	|			ManufacturedProducts.Department				AS Department
	|		FROM
	|			ManufacturedProducts AS ManufacturedProducts
	|		WHERE
	|			(NOT ManufacturedProducts.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|				OR (ManufacturedProducts.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|					AND ManufacturedProducts.Products.TracedGoods))
	|			AND ManufacturedProducts.Manufactured
	|			AND NOT ManufacturedProducts.Canceled
	|			AND NOT &ProductionByThirdParty2_5
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			InventoryOwnerAttributesProducts.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|			InventoryOwnerAttributesProducts.Count					AS Count,
	|			InventoryOwnerAttributesProducts.Sum						AS Sum,
	|			InventoryOwnerAttributesProducts.DateOfTransaction					AS DateOfTransaction,
	|			InventoryOwnerAttributesProducts.ToExpenseAs				AS ToExpenseAs,
	|			InventoryOwnerAttributesProducts.ExpenseItem				AS ExpenseItem,
	|			InventoryOwnerAttributesProducts.DimensionOfExpenses			AS DimensionOfExpenses,
	|			InventoryOwnerAttributesProducts.RowID			AS RowID,
	|			InventoryOwnerAttributesProducts.RowCode					AS RowCode,
	|			InventoryOwnerAttributesProducts.CostShare				AS CostShare,
	|			InventoryOwnerAttributesProducts.Period						AS Period,
	|			InventoryOwnerAttributesProducts.Department				AS Department
	|		FROM
	|			TTTypesOfProductStocks AS InventoryOwnerAttributesProducts
	|		WHERE
	|			InventoryOwnerAttributesProducts.BusinessOperation = &BusinessTransactionOutputProducts
	|	) AS NestedQueryOutputItems
	|	
	|	GROUP BY
	|		NestedQueryOutputItems.DimensionOfExpenses,
	|		NestedQueryOutputItems.ItemsLocationAttributes,
	|		NestedQueryOutputItems.ExpenseItem,
	|		NestedQueryOutputItems.ToExpenseAs,
	|		NestedQueryOutputItems.DateOfTransaction,
	|		NestedQueryOutputItems.RowID,
	|		NestedQueryOutputItems.RowCode,
	|		NestedQueryOutputItems.CostShare,
	|		NestedQueryOutputItems.Period,
	|		NestedQueryOutputItems.Department
	|	
	|	HAVING
	|		(SUM(NestedQueryOutputItems.Count) <> 0
	|			OR SUM(NestedQueryOutputItems.Sum) <> 0)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		NestedQueryByProducts.Period AS Period
	|	FROM
	|		(SELECT
	|			SideAndIntermediateRelease.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|			-SideAndIntermediateRelease.Count					AS Count,
	|			SideAndIntermediateRelease.ProductionDate			AS DateOfTransaction,
	|			SideAndIntermediateRelease.ProductCostElement			AS ProductCostElement,
	|			SideAndIntermediateRelease.ToExpenseAs			AS ToExpenseAs,
	|			SideAndIntermediateRelease.ExpenseItem				AS ExpenseItem,
	|			SideAndIntermediateRelease.DimensionOfExpenses			AS DimensionOfExpenses,
	|			SideAndIntermediateRelease.RowID			AS RowID,
	|			SideAndIntermediateRelease.RowCode					AS RowCode,
	|			-SideAndIntermediateRelease.Sum						AS Sum,
	|			SideAndIntermediateRelease.Period						AS Period,
	|			SideAndIntermediateRelease.Department				AS Department,
	|			SideAndIntermediateRelease.ProductOwner				AS ProductOwner
	|		FROM
	|			SideAndIntermediateRelease AS SideAndIntermediateRelease
	|		WHERE
	|			(NOT SideAndIntermediateRelease.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|				OR (SideAndIntermediateRelease.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|					AND SideAndIntermediateRelease.Products.TracedGoods))
	|			AND SideAndIntermediateRelease.Manufactured
	|			AND NOT SideAndIntermediateRelease.Canceled
	|			AND NOT &ProductionByThirdParty2_5
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			InventoryOwnerAttributesProducts.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|			InventoryOwnerAttributesProducts.Count					AS Count,
	|			InventoryOwnerAttributesProducts.DateOfTransaction					AS DateOfTransaction,
	|			InventoryOwnerAttributesProducts.ProductCostElement			AS ProductCostElement,
	|			InventoryOwnerAttributesProducts.ToExpenseAs				AS ToExpenseAs,
	|			InventoryOwnerAttributesProducts.ExpenseItem				AS ExpenseItem,
	|			InventoryOwnerAttributesProducts.DimensionOfExpenses			AS DimensionOfExpenses,
	|			InventoryOwnerAttributesProducts.RowID			AS RowID,
	|			InventoryOwnerAttributesProducts.RowCode					AS RowCode,
	|			InventoryOwnerAttributesProducts.Sum						AS Sum,
	|			InventoryOwnerAttributesProducts.Period						AS Period,
	|			InventoryOwnerAttributesProducts.Department				AS Department,
	|			InventoryOwnerAttributesProducts.ProductOwner				AS ProductOwner
	|		FROM
	|			TTTypesOfProductStocks AS InventoryOwnerAttributesProducts
	|		WHERE
	|			InventoryOwnerAttributesProducts.BusinessOperation = &BusinessTransactionBySideAndIntermediateRelease
	|	) AS NestedQueryByProducts
	|	
	|	GROUP BY
	|		NestedQueryByProducts.DimensionOfExpenses,
	|		NestedQueryByProducts.ItemsLocationAttributes,
	|		NestedQueryByProducts.ExpenseItem,
	|		NestedQueryByProducts.ToExpenseAs,
	|		NestedQueryByProducts.DateOfTransaction,
	|		NestedQueryByProducts.RowID,
	|		NestedQueryByProducts.RowCode,
	|		NestedQueryByProducts.Period,
	|		NestedQueryByProducts.Department,
	|		NestedQueryByProducts.ProductOwner
	|	
	|	HAVING
	|		(SUM(NestedQueryByProducts.Count) <> 0
	|			OR SUM(NestedQueryByProducts.Sum) <> 0)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		NestedRequestExpenseFromPantry.Period AS Period
	|	FROM
	|		(SELECT
	|			ExpenseComingToPantry.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|			ExpenseComingToPantry.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|			ExpenseComingToPantry.DateOfTransaction					AS DateOfTransaction,
	|			ExpenseComingToPantry.Period						AS Period,
	|			ExpenseComingToPantry.Department					AS Department,
	|			-ExpenseComingToPantry.Count					AS Count
	|		FROM
	|			ConsumptionAndArrivalInStorerooms AS ExpenseComingToPantry
	|		WHERE
	|			ExpenseComingToPantry.BusinessOperation = &BusinessTransactionSupply
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			InventoryOwnerAttributesMaterials.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|			InventoryOwnerAttributesMaterials.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|			InventoryOwnerAttributesMaterials.DateOfTransaction					AS DateOfTransaction,
	|			InventoryOwnerAttributesMaterials.Period							AS Period,
	|			InventoryOwnerAttributesMaterials.Department					AS Department,
	|			InventoryOwnerAttributesMaterials.Count						AS Count
	|		FROM
	|			TTStockTypesMaterials AS InventoryOwnerAttributesMaterials
	|		WHERE
	|			InventoryOwnerAttributesMaterials.BusinessOperation = &BusinessTransactionSupply
	|	) AS NestedRequestExpenseFromPantry
	|	
	|	GROUP BY
	|		NestedRequestExpenseFromPantry.Period,
	|		NestedRequestExpenseFromPantry.ItemsLocationAttributes,
	|		NestedRequestExpenseFromPantry.CorItemsLocationAttributes,
	|		NestedRequestExpenseFromPantry.DateOfTransaction,
	|		NestedRequestExpenseFromPantry.Department
	|	
	|	HAVING
	|		SUM(NestedRequestExpenseFromPantry.Count) <> 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AttachedRequestComingToPantry.Period AS Period
	|	FROM
	|		(SELECT
	|			ExpenseComingToPantry.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|			ExpenseComingToPantry.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|			ExpenseComingToPantry.DateOfTransaction					AS DateOfTransaction,
	|			ExpenseComingToPantry.Period						AS Period,
	|			ExpenseComingToPantry.Department					AS Department,
	|			-ExpenseComingToPantry.Count					AS Count
	|		FROM
	|			ConsumptionAndArrivalInStorerooms AS ExpenseComingToPantry
	|		WHERE
	|			ExpenseComingToPantry.BusinessOperation = &BusinessTransactionEconomy
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			InventoryOwnerAttributesMaterials.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|			InventoryOwnerAttributesMaterials.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|			InventoryOwnerAttributesMaterials.DateOfTransaction					AS DateOfTransaction,
	|			InventoryOwnerAttributesMaterials.Period							AS Period,
	|			InventoryOwnerAttributesMaterials.Department					AS Department,
	|			InventoryOwnerAttributesMaterials.Count						AS Count
	|		FROM
	|			TTStockTypesMaterials AS InventoryOwnerAttributesMaterials
	|		WHERE
	|			InventoryOwnerAttributesMaterials.BusinessOperation = &BusinessTransactionEconomy
	|	) AS AttachedRequestComingToPantry
	|	
	|	GROUP BY
	|		AttachedRequestComingToPantry.Period,
	|		AttachedRequestComingToPantry.ItemsLocationAttributes,
	|		AttachedRequestComingToPantry.CorItemsLocationAttributes,
	|		AttachedRequestComingToPantry.DateOfTransaction,
	|		AttachedRequestComingToPantry.Department
	|	
	|	HAVING
	|		SUM(AttachedRequestComingToPantry.Count) <> 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		NestedQuerySavingMaterials.Period AS Period
	|	FROM
	|		(SELECT
	|			UnusedMaterials.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|			UnusedMaterials.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|			UnusedMaterials.DateOfTransaction						AS DateOfTransaction,
	|			UnusedMaterials.ExpenseItem					AS ExpenseItem,
	|			UnusedMaterials.DimensionOfExpenses				AS DimensionOfExpenses,
	|			UnusedMaterials.AssetsLiabilitiesDimension			AS AssetsLiabilitiesDimension,
	|			UnusedMaterials.RowID				AS RowID,
	|			UnusedMaterials.Period							AS Period,
	|			-UnusedMaterials.Count						AS Count,
	|			UnusedMaterials.Recipient						AS Recipient,
	|			UnusedMaterials.ToExpenseAs					AS ToExpenseAs,
	|			UnusedMaterials.Department					AS Department
	|		FROM
	|			UnusedMaterials AS UnusedMaterials
	|		WHERE
	|			UnusedMaterials.ToExpenseAs
	|			AND NOT &ProductionByThirdParty2_5
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			InventoryOwnerAttributesMaterials.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|			InventoryOwnerAttributesMaterials.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|			InventoryOwnerAttributesMaterials.DateOfTransaction					AS DateOfTransaction,
	|			InventoryOwnerAttributesMaterials.ExpenseItem					AS ExpenseItem,
	|			InventoryOwnerAttributesMaterials.DimensionOfExpenses				AS DimensionOfExpenses,
	|			InventoryOwnerAttributesMaterials.AssetsLiabilitiesDimension		AS AssetsLiabilitiesDimension,
	|			InventoryOwnerAttributesMaterials.RowID			AS RowID,
	|			InventoryOwnerAttributesMaterials.Period							AS Period,
	|			InventoryOwnerAttributesMaterials.Count						AS Count,
	|			InventoryOwnerAttributesMaterials.Recipient						AS Recipient,
	|			InventoryOwnerAttributesMaterials.ToExpenseAs				AS ToExpenseAs,
	|			InventoryOwnerAttributesMaterials.Department					AS Department
	|		FROM
	|			TTStockTypesMaterials AS InventoryOwnerAttributesMaterials
	|		WHERE
	|			InventoryOwnerAttributesMaterials.BusinessOperation = &BusinessTransactionEconomyWriteOff
	|	) AS NestedQuerySavingMaterials
	|	
	|	GROUP BY
	|		NestedQuerySavingMaterials.ItemsLocationAttributes,
	|		NestedQuerySavingMaterials.CorItemsLocationAttributes,
	|		NestedQuerySavingMaterials.DateOfTransaction,
	|		NestedQuerySavingMaterials.ExpenseItem,
	|		NestedQuerySavingMaterials.DimensionOfExpenses,
	|		NestedQuerySavingMaterials.AssetsLiabilitiesDimension,
	|		NestedQuerySavingMaterials.RowID,
	|		NestedQuerySavingMaterials.Period,
	|		NestedQuerySavingMaterials.Recipient,
	|		NestedQuerySavingMaterials.ToExpenseAs,
	|		NestedQuerySavingMaterials.Department
	|	
	|	HAVING
	|		SUM(NestedQuerySavingMaterials.Count) <> 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		NestedRequestForMaterialsAndWorkConsumption.Period AS Period
	|	FROM
	|		(SELECT
	|			MaterialsAndWorksConsumption.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|			MaterialsAndWorksConsumption.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|			-MaterialsAndWorksConsumption.Count						AS Count,
	|			MaterialsAndWorksConsumption.DateOfMaterialWorkConsumption						AS DateOfTransaction,
	|			MaterialsAndWorksConsumption.Period							AS Period,
	|			MaterialsAndWorksConsumption.Department					AS Department
	|		FROM
	|			MaterialsAndWorksConsumption AS MaterialsAndWorksConsumption
	|		WHERE
	|			NOT MaterialsAndWorksConsumption.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			Software_3.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|			Software_3.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|			-Software_3.Count						AS Count,
	|			Software_3.DateOfShipment						AS DateOfTransaction,
	|			Software_3.Period							AS Period,
	|			Software_3.Department					AS Department
	|		FROM
	|			SupplyWithMaterialsAndWorks AS Software_3
	|				INNER JOIN Catalog.Products AS CatalogProducts
	|				ON Software_3.Products = CatalogProducts.Ref
	|		WHERE
	|			NOT Software_3.Canceled
	|			AND Software_3.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|			AND &UseTraceableImportedGoodsAccounting
	|			AND CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND CatalogProducts.TracedGoods
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			InventoryOwnerAttributesMaterials.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|			InventoryOwnerAttributesMaterials.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|			InventoryOwnerAttributesMaterials.Count						AS Count,
	|			InventoryOwnerAttributesMaterials.DateOfTransaction					AS DateOfTransaction,
	|			InventoryOwnerAttributesMaterials.Period							AS Period,
	|			InventoryOwnerAttributesMaterials.Department					AS Department
	|		FROM
	|			TTStockTypesMaterials AS InventoryOwnerAttributesMaterials
	|		WHERE
	|			InventoryOwnerAttributesMaterials.BusinessOperation = &BusinessTransactionExpense
	|	) AS NestedRequestForMaterialsAndWorkConsumption
	|	
	|	GROUP BY
	|		NestedRequestForMaterialsAndWorkConsumption.ItemsLocationAttributes,
	|		NestedRequestForMaterialsAndWorkConsumption.CorItemsLocationAttributes,
	|		NestedRequestForMaterialsAndWorkConsumption.DateOfTransaction,
	|		NestedRequestForMaterialsAndWorkConsumption.Period,
	|		NestedRequestForMaterialsAndWorkConsumption.Department
	|	
	|	HAVING
	|		SUM(NestedRequestForMaterialsAndWorkConsumption.Count) <> 0
	|) AS NestedRequest
	|";
	
	Query.SetParameter("BusinessTransactionSupply", BusinessOperationNamedTS("SupplyWithMaterialsAndWorks"));
	Query.SetParameter("BusinessTransactionEconomy", BusinessOperationNamedTS("SavingMaterialsReturn"));
	Query.SetParameter("BusinessTransactionEconomyWriteOff", BusinessOperationNamedTS("SavingMaterialsWriteOff"));
	Query.SetParameter("BusinessTransactionExpense", BusinessOperationNamedTS("MaterialsAndWorksConsumption"));
	Query.SetParameter("BusinessTransactionOutputProducts", BusinessOperationNamedTS("ManufacturedProducts"));
	Query.SetParameter("BusinessTransactionBySideAndIntermediateRelease", BusinessOperationNamedTS("SideAndIntermediateRelease"));
	Query.SetParameter("ProductionByThirdParty2_5", ProductionByThirdParty2_5);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next()
		And ValueIsFilled(Selection.Period) Then
		Period = Selection.Period;
	Else
		Period = InventoriesServer.DateOfCurrentBalances();
	EndIf;
	
	AdditionalProperties.Insert("PeriodFromWhichYouNeedToRecalculateTypesOfStocks", Period);
	
EndProcedure

Function OrderOfTS(TSName)
	
	DocumentTables = DocumentTables();
	
	NumberOfRowsInAllTs =
		DocumentTables.ManufacturedProducts.Count()
		+ DocumentTables.SideAndIntermediateRelease.Count()
		+ DocumentTables.SupplyWithMaterialsAndWorks.Count()
		+ DocumentTables.UnusedMaterials.Count()
		+ DocumentTables.MaterialsAndWorksConsumption.Count();
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		Return 0;
	ElsIf TSName = "UnusedMaterials" Then
		Return NumberOfRowsInAllTs;
	ElsIf TSName = "MaterialsAndWorksConsumption" Then
		Return NumberOfRowsInAllTs * 2;
	ElsIf TSName = "ManufacturedProducts" Then
		Return NumberOfRowsInAllTs * 3;
	ElsIf TSName = "SideAndIntermediateRelease" Then
		Return NumberOfRowsInAllTs * 4;
	Else
		ExceptionText = NStr("vi = 'Phần bảng%TSName% không có đơn hàng';
							|ru = 'Табличной части %TSName% не поставлен порядок';
							|en = 'The order is not set for the %TSName% table'; fa = 'The order is not set for the %TSName% table';
							|it = 'Non è stato assegnato un ordine alla tabella %TSName%';
							|pl = 'Dla sekcji tabelarycznej %TSName% nie ustawiono kolejności';
							|tr = '%TSName% tablo bölümü sıralı değil'");
		ExceptionText = StrReplace(ExceptionText, "%TSName%", TSName);
		
		Raise ExceptionText;
	EndIf;
	
EndFunction

Function BusinessOperationNamedTS(TSName)
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		Return Enums.BusinessTransactions.TransferToProduction;
	ElsIf TSName = "SavingMaterialsReturn" Then
		Return Enums.BusinessTransactions.ReturnFromProduction;
	ElsIf TSName = "SavingMaterialsWriteOff" Then
		Return Enums.BusinessTransactions.GoodsConsumptionOnDemand;
	ElsIf  TSName = "MaterialsAndWorksConsumption" Then
		Return Enums.BusinessTransactions.ExpensingToProductionLots;
	ElsIf TSName = "ManufacturedProducts" Then
		Return Enums.BusinessTransactions.ProductsRelease;
	ElsIf TSName = "SideAndIntermediateRelease" Then
		Return Enums.BusinessTransactions.ProductsReleaseFixCost;
	Else
		ExceptionText = NStr("vi = 'Phần bảng %TSName% không được liên kết với giao dịch kinh doanh';
							|ru = 'Табличная часть %TSName% не сопоставлена с хозяйственной операцией';
							|en = '%TSName% table is not mapped with the business transaction'; fa = '%TSName% table is not mapped with the business transaction';
							|it = 'La tabella %TSName% non è associata con l''operazione gestionale';
							|pl = 'Sekcji tabelarycznej %TSName% nie porównano z operacją gospodarczą';
							|tr = '%TSName% tablo bölümü ticari işlemle eşleştirilmedi'");
		ExceptionText = StrReplace(ExceptionText, "%TSName%", TSName);
		Raise ExceptionText;
	EndIf;
	
EndFunction

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.ProductionStage2_2.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.ProductionStage2_2.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
#Region FillingInAnalystKeys
	
	// We will get all the warehouses used and fill in the month of movements (props "Period")
	WarehouseArray = New Array;
	
	For Each String In DocumentTables.ManufacturedProducts Do
		
		If String.Canceled Then
			Continue;
		EndIf;
		
		If TypeOf(String.Recipient) = Type("CatalogRef.Warehouses") Then
			WarehouseArray.Add(String.Recipient);
		EndIf;
		
		String.Period = EndOfMonth(String.ProductionDate);
		
	EndDo;
	
	For Each String In DocumentTables.SideAndIntermediateRelease Do
		
		If String.Canceled Then
			Continue;
		EndIf;
		
		If TypeOf(String.Recipient) = Type("CatalogRef.Warehouses") Then
			WarehouseArray.Add(String.Recipient);
		EndIf;
		
		String.Period = EndOfMonth(String.ProductionDate);
		
	EndDo;
	
	ProductsArray = New Array;
	
	For Each String In DocumentTables.SupplyWithMaterialsAndWorks Do
		
		If String.SupplyOption = Enums.SupplyOptions.TransferedEarlier
			Or String.Canceled Then
			Continue;
		EndIf;
		
		ProductsArray.Add(String.Products);

		String.Period = EndOfMonth(String.DateOfShipment);
		
	EndDo;
	
	For Each String In DocumentTables.MaterialsAndWorksConsumption Do
		String.Period = EndOfMonth(String.DateOfMaterialWorkConsumption);
	EndDo;

	For Each String In DocumentTables.UnusedMaterials Do
		If TypeOf(String.Recipient) = Type("CatalogRef.Warehouses") Then
			WarehouseArray.Add(String.Recipient);
		EndIf;
		
		String.Period = EndOfMonth(String.DateOfTransaction);	
	EndDo;
	
	SetPrivilegedMode(True);
	
	PurposeOfDirectionOfActivity = Common.ObjectAttributeValue(LineOfBusiness, "Purpose");
	
	DetailsOfWarehouses = Common.ObjectsAttributesValues(WarehouseArray, "ShopFloorStockroom, Department");
	ItemsTypes = Common.ObjectsAttributeValue(ProductsArray, "ItemsType");
	
	// If the items remain for further processing, the recipient is not filled in
	If LeaveProductsAtSubcontractor Then
		
		DetailsOfEmptyWarehouse = New Structure;
		DetailsOfEmptyWarehouse.Insert("ShopFloorStockroom", False);
		DetailsOfEmptyWarehouse.Insert("Department", Catalogs.BusinessStructure.EmptyRef());
		
		DetailsOfWarehouses.Insert(Catalogs.Warehouses.EmptyRef(), DetailsOfEmptyWarehouse);
		
	EndIf;
	
	LayoutStructure = New Structure;
	LayoutStructure.Insert("Products");
	LayoutStructure.Insert("Characteristic");
	LayoutStructure.Insert("Series");
	LayoutStructure.Insert("Warehouse");
	LayoutStructure.Insert("Purpose");
	LayoutStructure.Insert("ProductCostElement");
	
	// Output items
	For Each String In DocumentTables.ManufacturedProducts Do
		
		If String.Canceled Then
			Continue;
		EndIf;
		
		FillPropertyValues(LayoutStructure, String);
		
		If String.ToExpenseAs
			Or TypeOf(String.Recipient) = Type("CatalogRef.Warehouses")
				And Not DetailsOfWarehouses[String.Recipient].ShopFloorStockroom
			Or TypeOf(String.Recipient) = Type("CatalogRef.Warehouses")
				And DetailsOfWarehouses[String.Recipient].ShopFloorStockroom
				And String.Department <> DetailsOfWarehouses[String.Recipient].Department Then
			
			If String.BatchesIndicationStatusSender <> 14 Then
				LayoutStructure.Series = Catalogs.ItemsBatches.EmptyRef();
			EndIf;
			
			LayoutStructure.Warehouse = String.Department;
			
			If String.ToExpenseAs Then
				LayoutStructure.Purpose = PurposeOfDirectionOfActivity;
			EndIf;
			
			If IsProductAssignment Then
				LayoutStructure.Purpose = Purpose;
			EndIf;
			
		Else
			
			If String.BatchesIndicationStatusRecipient <> 14 Then
				LayoutStructure.Series = Catalogs.ItemsBatches.EmptyRef();
			EndIf;
			
			LayoutStructure.Warehouse = String.Recipient;
			
		EndIf;
		
		String.ItemsLocationAttributes = InformationRegisters.ItemsLocationAttributes.AnalyticsKeyValue(LayoutStructure);
		
		If String.ToExpenseAs Then
			String.Purpose = Undefined;
		EndIf;
		
	EndDo;
	
	// By-products
	For Each String In DocumentTables.SideAndIntermediateRelease Do
		
		If String.Canceled Then
			Continue;
		EndIf;
		
		FillPropertyValues(LayoutStructure, String);
		
		If String.ToExpenseAs
			Or TypeOf(String.Recipient) = Type("CatalogRef.Warehouses")
				And Not DetailsOfWarehouses[String.Recipient].ShopFloorStockroom
			Or TypeOf(String.Recipient) = Type("CatalogRef.Warehouses")
				And DetailsOfWarehouses[String.Recipient].ShopFloorStockroom
				And String.Department <> DetailsOfWarehouses[String.Recipient].Department Then
			
			If String.BatchesIndicationStatusSender <> 14 Then
				LayoutStructure.Series = Catalogs.ItemsBatches.EmptyRef();
			EndIf;
			
			LayoutStructure.Warehouse = String.Department;
			
			If String.ToExpenseAs Then
				LayoutStructure.Purpose = PurposeOfDirectionOfActivity;
			EndIf;
			
			If IsProductAssignment Then
				LayoutStructure.Purpose = Purpose;
			EndIf;
			
		Else
			
			If String.BatchesIndicationStatusRecipient <> 14 Then
				LayoutStructure.Series = Catalogs.ItemsBatches.EmptyRef();
			EndIf;
			
			LayoutStructure.Warehouse = String.Recipient;
			
		EndIf;
		
		LayoutStructure.ProductCostElement = Catalogs.ProductCostElements.EmptyRef();
		String.ItemsLocationAttributes = InformationRegisters.ItemsLocationAttributes.AnalyticsKeyValue(LayoutStructure);
		
		If String.ToExpenseAs Then
			String.Purpose = Undefined;
		EndIf;
		
	EndDo;
	
	SetPrivilegedMode(False);
	
	// SupplyWithMaterialsAndWorks
	For Each String In DocumentTables.SupplyWithMaterialsAndWorks Do
		
		If String.Canceled Then
			Continue;
		EndIf;
		
		// ItemsLocationAttributes
		FillPropertyValues(LayoutStructure, String);
		
		If String.SupplyOption = Enums.SupplyOptions.TransferedEarlier
			Or ItemsTypes[String.Products] = Enums.ItemsTypes.Work_5 Then
			LayoutStructure.Warehouse = String.Department;
		EndIf;
		
		If Not String.WithAssignment Then
			LayoutStructure.Purpose = Catalogs.Assignments.EmptyRef();
		EndIf;
		
		If Not String.BatchesIndicationStatusSender = 14 Then
			LayoutStructure.Series = Catalogs.ItemsBatches.EmptyRef();
		EndIf;
		
		LayoutStructure.ProductCostElement = Catalogs.ProductCostElements.EmptyRef();
		
		String.ItemsLocationAttributes = InformationRegisters.ItemsLocationAttributes.AnalyticsKeyValue(LayoutStructure);
		
		// CorItemsLocationAttributes
		FillPropertyValues(LayoutStructure, String);
		
		LayoutStructure.Warehouse = String.Department;
		LayoutStructure.Purpose = Purpose;
		If Not String.BatchesIndicationStatusRecipient = 14 Then
			LayoutStructure.Series = Catalogs.ItemsBatches.EmptyRef();
		EndIf;
		
		LayoutStructure.ProductCostElement = Catalogs.ProductCostElements.EmptyRef();
		
		String.CorItemsLocationAttributes = InformationRegisters.ItemsLocationAttributes.AnalyticsKeyValue(LayoutStructure);
		
	EndDo;
	
	// Consummentmaterialsreferences
	// Analyticscountainment
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
					Enums.BusinessTransactions.ProductsRelease,
					Undefined,
					Undefined,
					Undefined);
		
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.Insert("Purpose", New Structure("FieldText,Value","&Purpose",Purpose));
	FieldsNames.Insert("Arbitrary", "Department");
	FieldsNames.Insert("Work_5", "Department");
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(DocumentTables.MaterialsAndWorksConsumption,
																	PlacesOfAccounting,
																	FieldsNames);
	
	// Consummentmaterialsreferences
	// Koranalitikauchetanomenclature
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
					Enums.BusinessTransactions.ProductsRelease,
					Undefined,
					Undefined,
					Undefined);
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.Insert("Purpose", New Structure("FieldText,Value","&Purpose",Purpose));
	FieldsNames.Insert("Arbitrary", "Department");
	FieldsNames.Insert("Work_5", "Department");
	FieldsNames.Insert("ProductCostElement", "ProductCostElement");
	FieldsNames.Insert("ItemsLocationAttributes", "CorItemsLocationAttributes");
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(DocumentTables.MaterialsAndWorksConsumption,
																	PlacesOfAccounting,
																	FieldsNames);
	
	//Economy of materials
	//Analyticscountainment
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
					Enums.BusinessTransactions.ReturnFromProduction,
					Undefined,
					Undefined,
					Undefined);
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	// The purpose of the returned materials corresponds to the purpose for which the materials are transferred under the stage,
	//	that is, the purpose is the stage.
	FieldsNames.Insert("Purpose", New Structure("FieldText,Value","&Purpose",Purpose));
	FieldsNames.Insert("Arbitrary", "Department");
	FieldsNames.Insert("Work_5", "Department");
	FieldsNames.Insert("BatchesIndicationStatus", "BatchesIndicationStatusSender");
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(DocumentTables.UnusedMaterials,
																	PlacesOfAccounting,
																	FieldsNames);
	
	//Economy of materials
	// Koranalitikauchetanomenclature
	LayoutStructure = New Structure();
	LayoutStructure.Insert("Products");
	LayoutStructure.Insert("Characteristic");
	LayoutStructure.Insert("Series");
	LayoutStructure.Insert("Warehouse");
	LayoutStructure.Insert("Purpose");
	LayoutStructure.Insert("ProductCostElement");
	
	For Each String In DocumentTables.UnusedMaterials Do
		
		FillPropertyValues(LayoutStructure, String);
		
		If String.ToExpenseAs
			Or TypeOf(String.Recipient) = Type("CatalogRef.Warehouses")
				And Not DetailsOfWarehouses[String.Recipient].ShopFloorStockroom
			Or TypeOf(String.Recipient) = Type("CatalogRef.Warehouses")
				And DetailsOfWarehouses[String.Recipient].ShopFloorStockroom
				And Not String.Department = DetailsOfWarehouses[String.Recipient].Department Then
			
			String.CorItemsLocationAttributes = Catalogs.InventoryLocationAttributeKeys.EmptyRef();
			
			Continue;
			
		EndIf;
		
		If String.BatchesIndicationStatusRecipient <> 14 Then
			LayoutStructure.Series = Catalogs.ItemsBatches.EmptyRef();
		EndIf;
		
		LayoutStructure.Warehouse = String.Recipient;
		
		String.CorItemsLocationAttributes = InformationRegisters.ItemsLocationAttributes.AnalyticsKeyValue(LayoutStructure);
		
	EndDo;
	
#EndRegion
	
EndProcedure

#EndRegion

#Region ObjectProcessingParameters

// When recording a document, the standard production schedule is updated,
// if the duration of the stage has changed, or its relationship with other documents
// (for more information, see Register the update of the Parameter Normativegraphics).
// However, this behavior may not be desirable when changing stages in groups.
// To disable the recalculation of the regulatory schedule, use this procedure.
// In this case, the recalculation of the regulatory schedule will not be performed, and it needs
// to be initiated independently.
//
Procedure DisableFillingInRegulatoryScheduleWhenRecording() Export
	
	AdditionalProperties.Insert(
		KeyIsNotToFillRegulatorySchedule());
	
EndProcedure

// Sets a service flag that will not register
// the handler for updating the status of the production order.
//
Procedure DisableOrderStateUpdate() Export
	
	AdditionalProperties.Insert(DisableOrderStateUpdateKey());
	
EndProcedure

// Sets a service flag that does not control changes
// in the stage placement parameters in the schedule.
//
Procedure DisableControlOfPlacementParametersInChart() Export
	
	AdditionalProperties.Insert(
		KeyDisableControlOfPlacementParametersInChart());
	
EndProcedure

// Sets a service flag that indicates that this document is created
// by the mechanisms of group formation of production stages.
//
Procedure SetBatchGenerationMode() Export
	
	AdditionalProperties.Insert(KeyBatchGenerationMode());
	AdditionalProperties.Insert("DocumentVerification_Disable", True);
	
EndProcedure

// Sets a service flag that indicates that this document is being processed
// by the mechanisms for group transfer of stages for execution.
//
Procedure SetPacketTransferModeToExecute() Export
	
	AdditionalProperties.Insert(DisableOrderStateUpdateKey());
	
	AdditionalProperties.Insert(KeyBatchModeTransferToExecution());
	
EndProcedure

Function BatchGenerationIsPerformed() Export
	
	Return ProductionManagement.BatchFormationOfStagesIsPerformed(ThisObject);
	
EndFunction

Function BatchTransferToExecutionIsPerformed()
	
	Return AdditionalProperties.Property(KeyBatchModeTransferToExecution());
	
EndFunction

Function DisabledControlOfPlacementParametersInChart()
	
	Return AdditionalProperties.Property(KeyDisableControlOfPlacementParametersInChart());
	
EndFunction

Function OrderStateUpdateDisabled()
	
	Return AdditionalProperties.Property(DisableOrderStateUpdateKey());
	
EndFunction

// Cocking a service flag which will not allow you to inspect details of the chain of stages.
//
Procedure DisableVerificationOfStageChainDetails() Export
	
	AdditionalProperties.Insert("DisableVerificationOfStageChainDetails");
	
EndProcedure

// Raises a service flag, in the presence of which the delayed calculation of the duration before the release by production stages will not be executed.
//
Procedure DisableCalculationOfDurationBeforeReleaseByStagesOfProduction() Export
	
	AdditionalProperties.Insert("DisableCalculationOfDurationBeforeReleaseByStagesOfProduction");
	
EndProcedure

#EndRegion

#Region UpdatingRelatedData

#Region RegisteringHandlers

Procedure RegisterStateUpdate(DataBeforeChange)
	
	ConnectionsHaveChanged = False;
	
	FirstTable = DataBeforeChange.Successors;
	SecondTable = Successors;
	
	For Cnt = 1 To 2 Do
		
		For Each String In FirstTable Do
			
			If SecondTable.Find(String.Stage, "Stage") = Undefined Then
				ConnectionsHaveChanged = True;
				Break;
			EndIf;
			
		EndDo;
		
		If ConnectionsHaveChanged Then
			Break;
		Else
			FirstTable = Successors;
			SecondTable = DataBeforeChange.Successors;
		EndIf;
		
	EndDo;
	
	NothingHasChangedBefore = DataBeforeChange.Attributes.PlanNotEarlierThan <> ThisObject.PlanNotEarlierThan
		And (
			TypeOf(DataBeforeChange.Attributes.PlanNotEarlierThan) = Type("DocumentRef.ProductionStage2_2")
			Or TypeOf(ThisObject.PlanNotEarlierThan) = Type("DocumentRef.ProductionStage2_2")
			);
			
	CanceledAmountHasChanged = DataBeforeChange.Attributes.NumberOfPackagesCanceled <> ThisObject.NumberOfPackagesCanceled;
	
	If (ConnectionsHaveChanged
			Or NothingHasChangedBefore
			Or CanceledAmountHasChanged
			Or StatusOrStateOfDocumentHasChanged(DataBeforeChange)
			Or ProvisionOfMaterialsHasChanged(DataBeforeChange)
			Or ChangedLaborCostsForRegistration(DataBeforeChange)
		) Then
		AddUpdateHandlerForRelatedData(
			"UpdateStageStates",
			Documents.ProductionStage2_2.Successors(Ref));
	EndIf;
	
EndProcedure

Procedure RegisterOrderStateUpdate(DataBeforeChange)
	
	If OrderStateUpdateDisabled() Then
		Return;
	EndIf;
	
	AddUpdateHandlerForRelatedData("UpdateStateOfOrderInQueue");
	
EndProcedure

Procedure RegisterCalculationOfQueueOfProductionOperations(DataBeforeChange)
	
	DepartmentData = ProductionServerCached.ProductionBusinessUnitDescription(Department);
	If Not DepartmentData.UseOperationManagement Then
		Return;
	EndIf;
	
	DocumentProperties = DocumentsPosting.DocumentProperties(ThisObject);
	
	If DocumentProperties.IsNew Then
		
		QueryText = "
		|SELECT TOP 1
		|	TRUE
		|FROM
		|	Catalog.ManufacturingOperations AS T
		|
		|	LEFT JOIN Catalog.ProductionStages AS BOMStage
		|	ON BOMStage.Ref = &BOMStage
		|
		|WHERE
		|	NOT T.DeletionMark
		|	AND T.Owner = CASE
		|		WHEN &StoreOperationsInBillsOfMaterials
		|			THEN BOMStage.Ref
		|		ELSE
		|			BOMStage.RouteSheet
		|		END
		|";
		
		Query = New Query(QueryText);
		Query.SetParameter("BOMStage", Stage);
		Query.SetParameter("StoreOperationsInBillsOfMaterials", GetFunctionalOption("StoreOperationsInBillsOfMaterials"));
		
		ThereAreTechnologicalOperations = Not Query.Execute().IsEmpty();
		
	Else
		
		ThereAreTechnologicalOperations = ProductionProcessEditorServerCall.ParametersOfTechnicalProcessOfStage(Ref).ThereAreTechnologicalOperations;
		
	EndIf;
	
	If Not ThereAreTechnologicalOperations Then
		Return;
	EndIf;
	
	CheckedStatuses = ProductionManagementClientServer.StatusesAvailableByOperationalManagement(DepartmentData);
	
	ExceptionTransitions = New Map;
	If DepartmentData.UseShiftTasks
		Or DepartmentData.UseManufacturingExecutionSystem Then
		ExceptionTransitions.Insert(Enums.StatusesOfProductionStages2_2.Initiated, ProductionServer.ArrayOfValues(Enums.StatusesOfProductionStages2_2.ForCompletion));
	EndIf;
	
	AddedQueueRestriction  = AdditionalProperties.Property("DivisionAttributes");
	ProcessParametersHaveBeenChanged = AdditionalProperties.Property("TechProcessParameters");
	
	If (CheckedStatuses.Find(Status) <> Undefined
			Or CheckedStatuses.Find(DataBeforeChange.Attributes.Status) <> Undefined)
		And (StatusOrStateOfDocumentHasChanged(DataBeforeChange, ExceptionTransitions)
			Or DocumentProperties.IsNew
			Or PackagePlan <> DataBeforeChange.Attributes.PackagePlan
			Or NumberOfPackagesPlan <> DataBeforeChange.Attributes.NumberOfPackagesPlan
			Or AddedQueueRestriction
			Or ProcessParametersHaveBeenChanged) Then
		AddUpdateHandlerForRelatedData("CalculateQueueOfProductionOperations");
	EndIf;
	
EndProcedure

Procedure RegisterUpdateOfPlacementParametersInChart(DataBeforeChange)
	
	TheProductionScheduleIsUsed = ProductionManagementCached.TheProductionScheduleIsUsed();
	DocumentProperties = DocumentsPosting.DocumentProperties(ThisObject);
	
	CanBeScheduled = Status = Enums.StatusesOfProductionStages2_2.BeingGenerated
		Or Status = Enums.StatusesOfProductionStages2_2.Generated1
		Or Status = Enums.StatusesOfProductionStages2_2.ForCompletion;
	
	If DocumentProperties.WriteMode <> DocumentWriteMode.Posting
		Or (Not DynamicStructure And Not TheProductionScheduleIsUsed)
		Or (Not StagePlacementInProductionSchedule And Not CanBeScheduled)
		Or DisabledControlOfPlacementParametersInChart() Then
		Return;
	EndIf;
	
	ParametersChanged_ = DocumentProperties.IsNew;
	
	If DataFromObjectCache("ChangedManualPlacementOfStageInSchedule") Then
		ParametersChanged_ = True;
		AddUpdateHandlerForRelatedData("RecordManualPlacementOfStageInGraph");
	EndIf;
	
	If Not ParametersChanged_ Then
		CheckWhetherPlacementParametersInDetailsChartHaveChanged(DataBeforeChange, ParametersChanged_);
	EndIf;
	
	If Not ParametersChanged_ Then
		CheckWhetherPlacementParametersInTableGraphHaveChanged(DataBeforeChange, ParametersChanged_);
	EndIf;
	
	If ParametersChanged_ Then
		
		If StagePlacementInProductionSchedule Then
			AddUpdateHandlerForRelatedData("CheckGraphOfAdjacentStages");
		EndIf;
		
		AddUpdateHandlerForRelatedData("ChangedPlacementParametersInChart");
		
	EndIf;
	
EndProcedure

Procedure RegisterUpdateOfParametersOfRegulatorySchedule(DataBeforeChange)
	
	DocumentProperties = DocumentsPosting.DocumentProperties(ThisObject);
	
	If DocumentProperties.WriteMode <> DocumentWriteMode.Posting
		Or DynamicStructure Then
		Return;
	EndIf;
	
	ParametersChanged_ = DocumentProperties.IsNew;
	
	// Check the details of the caps
	If Not ParametersChanged_ Then
		
		ParametersChanged_ = Not DataBeforeChange.Attributes.Posted
			Or DataBeforeChange.Attributes.StageDuration <> ThisObject.StageDuration
			Or DataBeforeChange.Attributes.UnitOfMeasureOfStageDuration <> ThisObject.UnitOfMeasureOfStageDuration
			Or (
				DataBeforeChange.Attributes.PlanNotEarlierThan <> ThisObject.PlanNotEarlierThan
					And (TypeOf(DataBeforeChange.Attributes.PlanNotEarlierThan) = Type("DocumentRef.ProductionStage2_2")
						Or TypeOf(ThisObject.PlanNotEarlierThan) = Type("DocumentRef.ProductionStage2_2")));
		
	EndIf;
	
	// Checking table parts
	If Not ParametersChanged_ Then
		
		ParametersChanged_ = ChangedTabularPartOfDocument(DataBeforeChange, "Successors");
		
	EndIf;
	
	If Not ParametersChanged_ Then
			
		Attributes = New Array;
		Attributes.Add("Purpose");
		Attributes.Add("StageConsumer");
		Attributes.Add("Canceled");
		
		ParametersChanged_ = ChangedTabularPartOfDocument(DataBeforeChange, "ManufacturedProducts", Attributes)
			
	EndIf;
	
	If ParametersChanged_ Then
		AddUpdateHandlerForRelatedData("ParametersOfRegulatoryScheduleHaveChanged")
	EndIf;

EndProcedure

Procedure RegisterUpdateOfDurationCalculationParametersBeforeRelease(DataBeforeChange)
	
	If Not DynamicStructure Or AdditionalProperties.Property("DisableCalculationOfDurationBeforeReleaseByStagesOfProduction") Then
		Return;
	EndIf;
	
	DocumentProperties = DocumentsPosting.DocumentProperties(ThisObject);

	If DocumentProperties.WriteMode <> DocumentWriteMode.Posting Then
		Return;
	EndIf;
	
	ParametersChanged_ = DocumentProperties.IsNew;
	
	If Not ParametersChanged_ Then
		ParametersChanged_ = DataBeforeChange.Attributes.StageDuration <> ThisObject.StageDuration;
	EndIf;
	
	If Not ParametersChanged_ Then
		ParametersChanged_ = (Not DataBeforeChange.Attributes.Posted And DocumentProperties.WriteMode = DocumentWriteMode.Posting)
			Or (DataBeforeChange.Attributes.Status <> ThisObject.Status And DataBeforeChange.Attributes.Status = Enums.StatusesOfProductionStages2_2.Completed);
	EndIf;

	If ParametersChanged_ Then
		AddUpdateHandlerForRelatedData("ParametersForCalculatingDurationBeforeReleaseHaveChanged");
	EndIf;
	
EndProcedure

Procedure RegisterProductionScheduleCleanup()
	
	DocumentProperties = DocumentsPosting.DocumentProperties(ThisObject);
	
	If DocumentProperties.IsNew Then
		Return;
	EndIf;
	
	If ProductionManagementCached.TheProductionScheduleIsUsed()
		And DocumentProperties.WriteMode = DocumentWriteMode.UndoPosting Then
		
		ProductionSchedule = DataFromObjectCache("ProductionSchedule");
		TheScheduleIsCalculated = ProductionSchedule.Count() > 0
			And ProductionSchedule[0].Calculated;
		
		If TheScheduleIsCalculated Then
			
			AddUpdateHandlerForRelatedData("ClearProductionSchedule")
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure RegisterScheduleCheckOfAdjacentStages(DataBeforeChange)
	
	DocumentProperties = DocumentsPosting.DocumentProperties(ThisObject);
	If DocumentProperties.IsNew
		Or Not DocumentProperties.WriteMode = DocumentWriteMode.Posting
		Or Status = Enums.StatusesOfProductionStages2_2.Completed
		Or Not ProductionManagementCached.TheProductionScheduleIsUsed()
		Or DisabledControlOfPlacementParametersInChart()
		Or DynamicStructure
		Or HandlerMustBeExecuted("CheckGraphOfAdjacentStages") Then
		
		Return;
		
	EndIf;
	
	If DataFromObjectCache("ChangedManualPlacementOfStageInSchedule")
		Or DataBeforeChange.Attributes.ActualStageStart <> ThisObject.ActualStageStart
		Or DataBeforeChange.Attributes.ProductionDate <> ThisObject.ProductionDate Then
		
		AddUpdateHandlerForRelatedData("CheckGraphOfAdjacentStages");
		
	EndIf;
	
EndProcedure

Procedure RegisterFeatureCleanupOnCriticalPath()
	
	DocumentProperties = DocumentsPosting.DocumentProperties(ThisObject);
	If DocumentProperties.IsNew 
		Or DocumentProperties.WriteMode <> DocumentWriteMode.Posting
		Or Status <> Enums.StatusesOfProductionStages2_2.Completed
		Or Not ProductionManagementCached.TheProductionScheduleIsUsed()
		Or HandlerMustBeExecuted("ClearProductionSchedule") Then
		
		Return;
		
	EndIf;
	
	ScheduleData = DataFromObjectCache("ProductionSchedule");
	
	If ValueIsFilled(ScheduleData) And ScheduleData[0].OnCriticalPath Then
		
		AddUpdateHandlerForRelatedData("ClearStageAttributeOnCriticalPath");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region CheckingForChanges

Function DataBeforeChange()
	
	QueryText =
		"SELECT
		|	&AttributeSet
		|FROM
		|	Document.ProductionStage2_2 AS Table
		|WHERE
		|	Table.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.Products    AS Products,
		|	Table.Characteristic  AS Characteristic,
		|	Table.Recipient      AS Recipient,
		|	Table.Purpose      AS Purpose,
		|	Table.StageConsumer AS StageConsumer,
		|	Table.Manufactured     AS Manufactured,
		|	Table.Canceled        AS Canceled,
		|	Table.Count      AS Count
		|FROM
		|	Document.ProductionStage2_2.ManufacturedProducts AS Table
		|WHERE
		|	Table.Ref = &Ref
		|
		|ORDER BY
		|	Table.LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.Products    AS Products,
		|	Table.Characteristic  AS Characteristic,
		|	Table.Recipient      AS Recipient,
		|	Table.Purpose      AS Purpose,
		|	Table.StageConsumer AS StageConsumer,
		|	Table.Manufactured     AS Manufactured,
		|	Table.Canceled        AS Canceled,
		|	Table.Count      AS Count
		|FROM
		|	Document.ProductionStage2_2.SideAndIntermediateRelease AS Table
		|WHERE
		|	Table.Ref = &Ref
		|
		|ORDER BY
		|	Table.LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.Products       AS Products,
		|	Table.Characteristic     AS Characteristic,
		|	Table.SupplyOption AS SupplyOption,
		|	Table.Produced       AS Produced,
		|	Table.Warehouse              AS Warehouse,
		|	Table.Count         AS Count,
		|	Table.Canceled           AS Canceled
		|FROM
		|	Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS Table
		|WHERE
		|	Table.Ref = &Ref
		|
		|ORDER BY
		|	Table.LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.Stage AS Stage
		|FROM
		|	Document.ProductionStage2_2.Successors AS Table
		|WHERE
		|	Table.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.WorkCenterType AS WorkCenterType,
		|	Table.OperationTime       AS OperationTime,
		|	Table.UnitOfMeasure  AS UnitOfMeasure,
		|	Table.Use      AS Use,
		|	Table.SetupSettings    AS SetupSettings
		|FROM
		|	Document.ProductionStage2_2.WorkCenterTypes AS Table
		|WHERE
		|	Table.Ref = &Ref
		|
		|ORDER BY
		|	Table.LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.WorkCenterType AS WorkCenterType,
		|	Table.OperationTime       AS OperationTime,
		|	Table.UnitOfMeasure  AS UnitOfMeasure,
		|	Table.Use      AS Use,
		|	Table.SetupSettings    AS SetupSettings
		|FROM
		|	Document.ProductionStage2_2.AlternateWorkCenterTypes AS Table
		|WHERE
		|	Table.Ref = &Ref
		|
		|ORDER BY
		|	Table.LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.WorkCenterType AS WorkCenterType,
		|	Table.IntervalDate     AS IntervalDate,
		|	Table.Count        AS Count
		|FROM
		|	Document.ProductionStage2_2.OccupancyOfWorkCenterTypes AS Table
		|WHERE
		|	Table.Ref = &Ref
		|
		|ORDER BY
		|	Table.LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.WorkKind AS WorkKind,
		|	Table.Performer AS Performer,
		|	Table.Count AS Count,
		|	Table.ExecutionDate AS ExecutionDate,
		|	Table.Canceled AS Canceled
		|FROM
		|	Document.ProductionStage2_2.LaborCosts AS Table
		|WHERE
		|	Table.Ref = &Ref
		|
		|ORDER BY
		|	Table.LineNumber";
	
	AttributeSet = 
		"Status, 
		|Posted, 
		|StageDuration, 
		|UnitOfMeasureOfStageDuration, 
		|StagePlacementInProductionSchedule,
		|PlanNotEarlierThan, 
		|PlanOperationsOfWorkCenterTypes, 
		|DateOfShipment, 
		|PreliminaryBuffer, 
		|UnitOfMeasureOfPreliminaryBuffer, 
		|FollowUpBuffer, 
		|UnitOfMeasureOfFollowUpBuffer, 
		|Continuous_,
		|ActualStageStart,
		|ActualStageEnd,
		|ProductionDate,
		|OperatingProcedureOfWorkCenterTypes,
		|NumberOfPackagesCanceled,
		|StageNumber,
		|NextStageNo,
		|PackagePlan,
		|NumberOfPackagesPlan";
		
	QueryText = StrReplace(QueryText, "&AttributeSet", AttributeSet);
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", ThisObject.Ref);
	
	QueryResult = Query.ExecuteBatch();
	
	If ThisObject.IsNew() Then
		
		Attributes = New Structure(AttributeSet);
		FillPropertyValues(Attributes, ThisObject);
		
	Else
		
		Selection = QueryResult[0].Select();
		Selection.Next();
		
		Attributes = New Structure(AttributeSet);
		FillPropertyValues(Attributes, Selection);
		
	EndIf;
	
	DataBeforeChange = New Structure;
	
	DataBeforeChange.Insert("Attributes", Attributes);
	DataBeforeChange.Insert("ManufacturedProducts", QueryResult[1].Unload());
	DataBeforeChange.Insert("SideAndIntermediateRelease", QueryResult[2].Unload());
	DataBeforeChange.Insert("SupplyWithMaterialsAndWorks", QueryResult[3].Unload());
	DataBeforeChange.Insert("Successors", QueryResult[4].Unload());
	DataBeforeChange.Insert("WorkCenterTypes", QueryResult[5].Unload());
	DataBeforeChange.Insert("AlternateWorkCenterTypes", QueryResult[6].Unload());
	DataBeforeChange.Insert("OccupancyOfWorkCenterTypes", QueryResult[7].Unload());
	DataBeforeChange.Insert("LaborCosts", QueryResult[8].Unload());
	
	Return DataBeforeChange;
	
EndFunction

Function StatusOrStateOfDocumentHasChanged(DataBeforeChange, ExceptionTransitions = Undefined)
	
	DocumentProperties = DocumentsPosting.DocumentProperties(ThisObject);
	If (DocumentProperties.WriteMode = DocumentWriteMode.Posting
			And Not DataBeforeChange.Attributes.Posted
		Or DocumentProperties.WriteMode = DocumentWriteMode.UndoPosting
			And DataBeforeChange.Attributes.Posted)
		Then
		Return True;
	ElsIf ExceptionTransitions <> Undefined
			And ExceptionTransitions[ThisObject.Status] <> Undefined
			And ExceptionTransitions[ThisObject.Status].Find(DataBeforeChange.Attributes.Status) <> Undefined
		Then
		Return False;
	EndIf;
	Return ThisObject.Status <> DataBeforeChange.Attributes.Status;
	
EndFunction

Function ProvisionOfMaterialsHasChanged(DataBeforeChange)
	
	Attributes = New Array;
	
	Attributes.Add("Products");
	Attributes.Add("Characteristic");
	Attributes.Add("SupplyOption");
	Attributes.Add("Produced");
	Attributes.Add("Warehouse");
	Attributes.Add("Count");
	Attributes.Add("Canceled");
	
	Result = ChangedTabularPartOfDocument(DataBeforeChange, "SupplyWithMaterialsAndWorks", Attributes);
	Return Result;
	
EndFunction

Function ChangedLaborCostsForRegistration(DataBeforeChange)
	
	Attributes = New Array;
	
	Attributes.Add("WorkKind");
	Attributes.Add("Performer");
	Attributes.Add("Count");
	Attributes.Add("ExecutionDate");
	Attributes.Add("Canceled");
	
	ChangedTablePart = ChangedTabularPartOfDocument(
		DataBeforeChange,
		"LaborCosts",
		Attributes);
	
	Result = ChangedTablePart Or StatusOrStateOfDocumentHasChanged(DataBeforeChange);
	Return Result;
	
EndFunction

Function ChangedTabularPartOfDocument(DataBeforeChange, TableName, Attributes = Undefined)
	
	Return ProductionManagement.ChangedTabularPartOfDocument(
				ThisObject,
				DataBeforeChange,
				TableName,
				Attributes);
	
EndFunction

Procedure CheckWhetherPlacementParametersInDetailsChartHaveChanged(DataBeforeChange, ParametersChanged_)
	
	Attributes = PlacementParametersInChartDetails();
	
	For Each Attribute In Attributes Do
		If DataBeforeChange.Attributes[Attribute] <> ThisObject[Attribute] Then
			
			If Attribute = "PlanNotEarlierThan"
				And TypeOf(PlanNotEarlierThan) = Type("Date")
				And PlanNotEarlierThan <> '00010101' Then
				
				ScheduleData = DataFromObjectCache("ProductionSchedule");
				
				If ValueIsFilled(ScheduleData)
					And ScheduleData[0].Begin >= PlanNotEarlierThan Then
					
					Continue;
					
				EndIf;
				
			EndIf;
			
			ParametersChanged_ = True;
			Break;
			
		EndIf;
	EndDo;
	
	If Not ParametersChanged_ Then
		
		ParametersChanged_ = Not DataBeforeChange.Attributes.Posted
			And DocumentsPosting.DocumentProperties(ThisObject).WriteMode = DocumentWriteMode.Posting;
		
	EndIf;
	
EndProcedure

Procedure CheckWhetherPlacementParametersInTableGraphHaveChanged(DataBeforeChange, ParametersChanged_)
	
	TableHasChanged = False;
	
	If StagePlacementInProductionSchedule Then
		
		TableHasChanged = ChangedTabularPartOfDocument(DataBeforeChange, "OccupancyOfWorkCenterTypes");
		
	ElsIf PlanOperationsOfWorkCenterTypes Then
		
		TableHasChanged = ChangedTabularPartOfDocument(DataBeforeChange, "WorkCenterTypes");
		
		If Not TableHasChanged Then
			
			TableHasChanged = ChangedTabularPartOfDocument(DataBeforeChange, "AlternateWorkCenterTypes")
			
		EndIf;
		
		If Not TableHasChanged Then
			
			TableHasChanged = ChangedTabularPartOfDocument(DataBeforeChange, "Successors")
			
		EndIf;
		
		If Not TableHasChanged
			And Not DynamicStructure Then
			
			Attributes = New Array;
			Attributes.Add("Purpose");
			Attributes.Add("Canceled");
	
			TableHasChanged = ChangedTabularPartOfDocument(DataBeforeChange, "ManufacturedProducts", Attributes)
			
		EndIf;
		
	EndIf;
	
	If TableHasChanged Then
		
		ParametersChanged_ = True;
		
	EndIf;
	
EndProcedure

Function PlacementParametersInChartDetails()
	
	Result = New Array;
	
	Result.Add("StagePlacementInProductionSchedule");
	Result.Add("PlanNotEarlierThan");
	
	If Not StagePlacementInProductionSchedule Then
		
		Result.Add("PlanOperationsOfWorkCenterTypes");
		
		If PlanOperationsOfWorkCenterTypes Then
			
			Result.Add("PreliminaryBuffer");
			Result.Add("UnitOfMeasureOfPreliminaryBuffer");
			Result.Add("FollowUpBuffer");
			Result.Add("UnitOfMeasureOfFollowUpBuffer");
			Result.Add("Continuous_");
			Result.Add("OperatingProcedureOfWorkCenterTypes");
			
		Else
			
			Result.Add("StageDuration");
			Result.Add("UnitOfMeasureOfStageDuration");
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function EditedParametersForManualPlacementInChart()
	
	Return StagePlacementInProductionSchedule And AdditionalProperties.Property("ProductionSchedule");
	
EndFunction

#EndRegion

#Region UpdatingData

Procedure UpdateRelatedData(Cancel, RemovalOfBody = False)
	
	Var ProcessingParameters;
	
	If Cancel Or UpdatingRelatedDataIsNotRequired() Then
		Return;
	EndIf;
	
	If HandlerMustBeExecuted("ChangedPlacementParametersInChart") Then
		
		If StagePlacementInProductionSchedule Then
			
			If OccupancyOfWorkCenterTypes.Count() > 0 Then
				
				IntervalColumns = "WorkCenterType, IntervalDate";
				Intervals = OccupancyOfWorkCenterTypes.Unload(, IntervalColumns);
				Intervals.GroupBy(IntervalColumns);
				AccumulationRegisters.AvailabilityOfWorkCenterTypes.CheckDownloadDoesNotExceedScheduleAvailability(Intervals);
				
			EndIf;
			
		Else
			
			If DynamicStructure Then
				AutoStart = Not ProductionManagementCached.TheProductionScheduleIsUsed()
					And Not AdditionalProperties.Property(KeyIsNotToFillRegulatorySchedule());
				InformationRegisters.OrderStructureCalculationJobsProductionSchedule.AddJob(ReferenceOrder, Ref,, AutoStart);
			Else
				InformationRegisters.JobsToProductionScheduleCalculation.AddTasks(Ref);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If HandlerMustBeExecuted("ParametersOfRegulatoryScheduleHaveChanged") Then
		
		AutoStart = Not AdditionalProperties.Property(KeyIsNotToFillRegulatorySchedule());
		InformationRegisters.JobsForTargetProductionScheduleCalculation.AddJob(ReferenceOrder, AutoStart);
		
	EndIf;
	
	If HandlerMustBeExecuted("CheckGraphOfAdjacentStages") Then
		
		ProductionManagement.CheckOrderOfSteps(Ref);
		
	EndIf;
	
	If HandlerMustBeExecuted("ClearProductionSchedule") Then
		
		InformationRegisters.ScheduleOfProductionStages2_2.ToClearStageSchedule(ReferenceOrder, Ref);
		
	EndIf;
	
	If Not (DocumentsPosting.DocumentProperties(ThisObject).IsNew
		Or Not ProductionManagementCached.TheProductionScheduleIsUsed()) Then
		
		UndoPosting = DocumentsPosting.DocumentProperties(ThisObject).WriteMode
			= DocumentWriteMode.UndoPosting;
	
		CanBeScheduled = Status = Enums.StatusesOfProductionStages2_2.BeingGenerated
			Or Status = Enums.StatusesOfProductionStages2_2.Generated1
			Or Status = Enums.StatusesOfProductionStages2_2.ForCompletion;
	
		EditingManualPlacement = EditedParametersForManualPlacementInChart();
	
		If UndoPosting
			Or Not CanBeScheduled
			Or EditingManualPlacement Then
			
			If DynamicStructure Then
				RecordsFilter = New Structure("ProductionOrder, ProductionStage", ReferenceOrder, Ref);
				InformationRegisters.OrderStructureCalculationJobsProductionSchedule.DeleteSelectionEntries(RecordsFilter);
			Else
				RecordsFilter = New Structure("ReferenceOrder, ProductionStage", ReferenceOrder, Ref);
				InformationRegisters.JobsToProductionScheduleCalculation.DeleteSelectionEntries(RecordsFilter);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If HandlerMustBeExecuted("ParametersForCalculatingDurationBeforeReleaseHaveChanged") Then
		
		Job = New Structure;
		Job.Insert("ProductionLot", ProductionLot);
		Job.Insert("Stage",               Ref);
		
		DeferredJobs.ProcessQueueTasks("TasksOfCalculatingDurationBeforeReleaseByProductionStages", Job);
		
	EndIf;
	
	If HandlerMustBeExecuted("ClearStageAttributeOnCriticalPath") Then
		
		InformationRegisters.ScheduleOfProductionStages2_2.ClearStageAttributeOnCriticalPath(Ref);
		
	EndIf;
	
	If HandlerMustBeExecuted("CalculateQueueOfProductionOperations") Then
		
		If BatchTransferToExecutionIsPerformed() Then
			InformationRegisters.JobsForCalculatingProductionOperationQueue.AddTasks(Ref, False);
		Else
			InformationRegisters.QueueOfProductionOperations.AddTaskToQueueCalculation(Ref, RemovalOfBody, Cancel);
		EndIf;
		
	EndIf;
	
	If HandlerMustBeExecuted("UpdateStageStates", ProcessingParameters) Then
		
		CommonClientServer.SupplementArray(
			ProcessingParameters,
			Documents.ProductionStage2_2.Successors(Ref),
			True);
		
		StepsToUpdate = ProcessingParameters; // Array
		StepsToUpdate.Add(Ref);
		
		RegistersToBeReflected = DocumentsStates.RegistersToReflectStateOfOrders();
		RegistersToBeReflected.ProductionStageStates = True;
		
		DocumentsStates.AddTasksToStateOfOrders(
			Undefined,
			StepsToUpdate,
			"ACTION_FEFLECT_STAGES_STATE",
			RegistersToBeReflected);
		
	EndIf;
	
	If HandlerMustBeExecuted("UpdateStateOfOrderInQueue") Then
		
		RegistersToBeReflected = DocumentsStates.RegistersToReflectStateOfOrders();
		RegistersToBeReflected.StatesOfProductionOrders = True;
		
		DocumentsStates.AddTasksToStateOfOrders(Undefined, ReferenceOrder,, RegistersToBeReflected);
		
	EndIf;
	
	ClearListOfAssociatedDataUpdateHandlers();
	
EndProcedure

#EndRegion

#Region Other

Function UpdatingRelatedDataIsNotRequired()
	
	Var Handlers;
	
	If AdditionalProperties.Property("AssociatedDataUpdateHandlers", Handlers) Then
		Return (Handlers.Count() = 0);
	Else
		Return True;
	EndIf;
	
EndFunction

Procedure ClearListOfAssociatedDataUpdateHandlers()
	
	If AdditionalProperties.Property("AssociatedDataUpdateHandlers") Then
		AdditionalProperties.Delete("AssociatedDataUpdateHandlers");
	EndIf;
	
EndProcedure

Procedure AddUpdateHandlerForRelatedData(HandlerName, ProcessingParameters = Undefined)
	
	AssociatedDataUpdateHandlers = AdditionalProperties.AssociatedDataUpdateHandlers;
	AssociatedDataUpdateHandlers.Insert(HandlerName, ProcessingParameters);
	
EndProcedure

Function HandlerMustBeExecuted(HandlerName, ProcessingParameters = Undefined)
	
	Var Handlers;
	
	If AdditionalProperties.Property("AssociatedDataUpdateHandlers", Handlers) Then
		Return Handlers.Property(HandlerName, ProcessingParameters);
	Else
		Return False;
	EndIf;
	
EndFunction

#EndRegion

#EndRegion

#Region Constants

Function KeyBatchGenerationMode()
	
	Return ProductionManagement.KeyBatchModeForGeneratingStages();
	
EndFunction

Function KeyBatchModeTransferToExecution()
	
	Return "BatchModeTransferToExecution";
	
EndFunction

Function KeyIsNotToFillRegulatorySchedule()
	
	Return "DoNotFillInRegulatorySchedule"
	
EndFunction

Function KeyDisableControlOfPlacementParametersInChart()
	
	Return "DisableControlOfPlacementParametersInChart";
	
EndFunction

Function DisableOrderStateUpdateKey()
	
	Return "DisableOrderStateUpdate";
	
EndFunction

#EndRegion

#Region Other

// Corrects lines that had not been issued a receipt or warehouse warrant or there are differences in the measured products.
//
// Parameters:
// 		ParametersStructure - Structure - Structure of adjustment parameters, constructor: Orderserver.The structure of the correction of the order order()
// 		Disallowestroke - Boolean - Is cocked when the object is corrected (the stage form is closed), if the Status is set to Completed,
// 											because in this Status of the line with Produced = The falsehoods will be removed and the separation makes no sense.
//
// Returns:
// 		Structure
// 		* Number of rows - the Number of canceled / adjusted rows
// 		* Adoration amount - The amount of increase in the order due to excess shipment of measured goods.
//
Function AdjustOrderLines(ParametersStructure) Export
	
	If Not ParametersStructure.CancelUnprocessedLines And Not ParametersStructure.CorrectMeasuringGoods Then
		Return OrdersServer.ResultOfUndoingUnprocessedRows(Undefined)
	EndIf;
	
	NumberOfAdjustedRows = 0;
	
	If Not ParametersStructure.CheckBalance Then
		
		NumberOfAdjustedRows = NumberOfAdjustedRows + SupplyWithMaterialsAndWorks.Count();
		SupplyWithMaterialsAndWorks.Clear();
		
		Return OrdersServer.ResultOfUndoingUnprocessedRows(NumberOfAdjustedRows);
	EndIf;
	
	FillParameters = OrdersServer.FillOptionsForCancelingRows();
	FillParameters.RegisterManager  = AccumulationRegisters.OrdersOfMaterialsForProduction;
	FillParameters.TabularSectionName = "SupplyWithMaterialsAndWorks";
	
	CancellationOptions = OrdersServer.OptionsForCancelingOrderLines();
	CancellationOptions.DeleteRows_1 = True;
	CancellationOptions.CancelOnlyMeasuredGoods = Not ParametersStructure.CancelUnprocessedLines
		And ParametersStructure.CorrectMeasuringGoods;
	CancellationOptions.CorrectMeasuringGoods = ParametersStructure.CorrectMeasuringGoods;
	
	Return OrdersServer.UndoUnprocessedShippingLines(ThisObject, FillParameters, CancellationOptions);
	
EndFunction

Procedure FillInSoftwareWhenSettingStatus(AdditionalParameters)
	
	If Not AdditionalParameters.Property("FillInSupply") Or Not AdditionalParameters.FillInSupply Then
		Return;
	EndIf;
	
	EmbeddingParameters = Documents.ProductionStage2_2.AvailableRemainingEmbeddingOptions(ThisObject);
	ActionSettingParameters = Documents.ProductionStage2_2.ParametersForExecutingCommandsAndActions(Ref, AdditionalParameters.ActionCode);
	If ActionSettingParameters.NeedQuestion Then
		ActionSettingParameters.Insert("UncheckShipByOneDateFlag", True);
		ActionSettingParameters.Insert("FillShippingDateWithSingleDate", False);
	EndIf;
	
	ProvisionInDocumentsServer.FillInBalanceProvisionOptionForSelectedObjectRows(
		ThisObject,
		AdditionalParameters.ActionCode,
		ActionSettingParameters,
		Undefined,
		EmbeddingParameters);
	
	If AdditionalParameters.Replace_With_Analogues Then
		
		TableName = "SupplyWithMaterialsAndWorks";
		
		AdditionalParametersForReplacementWithAnalogs = New Structure;
		AdditionalParametersForReplacementWithAnalogs.Insert("AvailableRemainingEmbeddingOptions", EmbeddingParameters);
		
		ReplacementResult = Documents.ProductionStage2_2.Replace_With_Analogues(
							ThisObject,
							TableName,,
							AdditionalParameters.ActionCodeAnalogs,
							AdditionalParametersForReplacementWithAnalogs);
		
		Documents.ProductionStage2_2.AfterReplacementWithAnalogs(ThisObject, TableName, ReplacementResult);
		
	EndIf;
	
EndProcedure

Procedure AssignArtistWhenSettingStatus(AdditionalParameters)
	
	If Not AdditionalParameters.Property("AssignAssignee") Or Not AdditionalParameters.AssignAssignee Then
		Return;
	EndIf; 
	
	DivisionParameters = ProductionServerCached.ProductionBusinessUnitDescription(Department);
	
	If DivisionParameters.UseOperationManagement Then
		Return;
	EndIf;

	InformationAboutAPerformer = Undefined;
	
	If Not AdditionalParameters.Property("InformationAboutAPerformer", InformationAboutAPerformer) Then
		SetPrivilegedMode(True);
		InformationAboutAPerformer = ProductionManagement.InformationAboutContractorSPlaceOfWork(AdditionalParameters.Performer); 
		SetPrivilegedMode(False);
		AdditionalParameters.Insert("InformationAboutAPerformer", InformationAboutAPerformer); // Caching
	EndIf;
	
	PerformerType = TypeOf(AdditionalParameters.Performer);
	
	If (InformationAboutAPerformer.Department = Department Or Not ValueIsFilled(InformationAboutAPerformer.Department))
			And (InformationAboutAPerformer.Organization = Organization Or Not ValueIsFilled(InformationAboutAPerformer.Organization))
			And (DivisionParameters.UsePersonalWorkOrders
						And PerformerType = Type("CatalogRef.Persons")
				Or DivisionParameters.UseTeamWorkOrders
						And PerformerType = Type("CatalogRef.Teams")) Then
				
		Performer = AdditionalParameters.Performer;
		
	Else
		
		ErrorText = NStr("vi = 'Đối với chứng từ %Document%, chưa thiết lập người thực hiện, người thực hiện không tương ứng với Bộ phận hoặc Doanh nghiệp.';
						|ru = 'Для документа %Document% не установлен исполнитель, исполнитель не соответствует Подразделению или Организации.';
						|en = 'The assignee is not specified for the ""%Document%"" document. The assignee does not correspond to the Business unit or Company.'; fa = 'The assignee is not specified for the ""%Document%"" document. The assignee does not correspond to the Business unit or Company.';
						|it = 'Для документа %Document% не установлен исполнитель, исполнитель не соответствует Подразделению или Организации.';
						|pl = 'The assignee is not specified for the ""%Document%"" document. The assignee does not correspond to the Business unit or Company.';
						|tr = '%Document% belgesi için atanan yapılandırılmadı, atanan Departmana veya İş Yerine karşılık gelmemektedir.'");
		ErrorText = StrReplace(ErrorText, "%Document%", Ref);
		
		Common.MessageToUser(
					ErrorText,
					Ref,
					"Status",,); // we limit ourselves to a warning
		
	EndIf;
	
EndProcedure

// When processing on the side, all stages included in a single order to the processor must have an end-to-end line code.
//
Procedure FillInNewLineCodeWhenProcessingOnSide(Cancel)

	If ManufacturedProducts.Find(0, "RowCode") = Undefined
		And SideAndIntermediateRelease.Find(0, "RowCode") = Undefined 
		And SupplyWithMaterialsAndWorks.Find(0, "RowCode") = Undefined Then
		Return;
	EndIf;
	
	LockSpace = ?(TypeOf(SubcontractOrder) = Type("DocumentRef.SubcontractOrder2_5"),
		"Document.SubcontractOrder2_5",
		"Document.SubcontractOrder");
	
	Block = New DataLock;
	LockItem = Block.Add(LockSpace);
	LockItem.SetValue("Ref", SubcontractOrder);
	LockItem.Mode = DataLockMode.Exclusive;
	Try
		Block.Lock();
	Except
		Event = NStr("vi = 'Công đoạn sản xuất';
					|ru = 'Этап производства';
					|en = 'Production stage'; fa = 'مرحله تولید';
					|it = 'Fase di produzione';
					|pl = 'Etap produkcji';
					|tr = 'Üretim aşaması'", Common.DefaultLanguageCode()) + "."
			+ NStr("vi = 'Điền mã dòng';
					|ru = 'Заполнение кодов строк';
					|en = 'Fill in line codes'; fa = 'Fill in line codes';
					|it = 'Fill in line codes';
					|pl = 'Fill in line codes';
					|tr = 'Satır kodlarını doldurma'", Common.DefaultLanguageCode());
		WriteLogEvent(Event,
			EventLogLevel.Error,
			Metadata(),
			Ref,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		MessageText = NStr("vi = 'Không thể chặn công đoạn đã đưa vào đơn đặt hàng gia công.';
							|ru = 'Не удалось заблокировать этапы, включенные в заказ переработчику.';
							|en = 'Cannot lock the stages included in the subcontracting purchase order.'; fa = 'Cannot lock the stages included in the subcontracting purchase order.';
							|it = 'Cannot lock the stages included in the subcontracting purchase order.';
							|pl = 'Cannot lock the stages included in the subcontracting purchase order.';
							|tr = 'Fason satın alma siparişine dahil edilmiş aşamalar engellenemedi.'");
		Common.MessageToUser(MessageText, Ref,,, Cancel);
		Return;
	EndTry;
	
	QueryText = 
	"SELECT
	|	ISNULL(MAX(MaximumLineCodes.MaximumRowCodeFinishedProductsSideAndIntermediateRelease), 0)     AS MaximumRowCodeFinishedProductsSideAndIntermediateRelease,
	|	ISNULL(MAX(MaximumLineCodes.MaximumRowCodeMaterialsAndServicesSupply), 0) AS MaximumRowCodeMaterialsAndServicesSupply
	|FROM
	|	(SELECT
	|		OrdersToProcessor.ProductsMaxRowCode   AS MaximumRowCodeFinishedProductsSideAndIntermediateRelease,
	|		OrdersToProcessor.MaximumRowCodeMaterials AS MaximumRowCodeMaterialsAndServicesSupply
	|	FROM
	|		Document.SubcontractOrder2_5 AS OrdersToProcessor
	|	WHERE
	|		OrdersToProcessor.Ref = &SubcontractOrder
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProductionStages.MaximumRowCodeFinishedProductsSideAndIntermediateRelease     AS MaximumRowCodeFinishedProductsSideAndIntermediateRelease,
	|		ProductionStages.MaximumRowCodeMaterialsAndServicesSupply AS MaximumRowCodeMaterialsAndServicesSupply
	|	FROM
	|		Document.ProductionStage2_2 AS ProductionStages
	|	WHERE
	|		ProductionStages.SubcontractOrder = &SubcontractOrder
	|	) AS MaximumLineCodes
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("SubcontractOrder", SubcontractOrder);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	CodeSelection = Result.Select();
	CodeSelection.Next();
	MaximumRowCodeFinishedProductsSideAndIntermediateRelease     = CodeSelection.MaximumRowCodeFinishedProductsSideAndIntermediateRelease;
	MaximumRowCodeMaterialsAndServicesSupply = CodeSelection.MaximumRowCodeMaterialsAndServicesSupply;
	
	ManagerOfDocument = Common.ObjectManagerByRef(SubcontractOrder);
	ManagerOfDocument.FillInLineCodeInTableSection(ManufacturedProducts, False, MaximumRowCodeFinishedProductsSideAndIntermediateRelease);
	ManagerOfDocument.FillInLineCodeInTableSection(SideAndIntermediateRelease, False, MaximumRowCodeFinishedProductsSideAndIntermediateRelease);
	ManagerOfDocument.FillInLineCodeInTableSection(SupplyWithMaterialsAndWorks, False, MaximumRowCodeMaterialsAndServicesSupply);
	
EndProcedure

Procedure SetKeyInRowsOfTableParts(Cancel)
	
	If ProductionByThirdParty And Not SubcontractOrder = Undefined Then
		
		FillInNewLineCodeWhenProcessingOnSide(Cancel);
		
	Else
		
		OrdersServer.SetKeyInRowsOfTablePart(
			ThisObject, "ManufacturedProducts", "MaximumRowCodeFinishedProductsSideAndIntermediateRelease");
		
		OrdersServer.SetKeyInRowsOfTablePart(
			ThisObject, "SideAndIntermediateRelease", "MaximumRowCodeFinishedProductsSideAndIntermediateRelease");
		
		OrdersServer.SetKeyInRowsOfTablePart(
			ThisObject, "SupplyWithMaterialsAndWorks", "MaximumRowCodeMaterialsAndServicesSupply");
		
		OrdersServer.SetKeyInRowsOfTablePart(
			ThisObject, "UnusedMaterials", "MaximumRowCodeSavings");
		
		OrdersServer.SetKeyInRowsOfTablePart(
			ThisObject, "LaborCosts", "MaximumRowCodeLaborCosts");
		
	EndIf;
	
EndProcedure

Procedure FillInMaximumProductionDate()
	
	If Not ProductionInOneDay Then
		ProductionDate = Max(Documents.ProductionStage2_2.MaximumDateWH(FindUndoneRows("ManufacturedProducts"), "ProductionDate"),
								Documents.ProductionStage2_2.MaximumDateWH(FindUndoneRows("SideAndIntermediateRelease"), "ProductionDate"));
	EndIf;
	
EndProcedure

Procedure FillInMaximumShipmentDate()
	
	If Not NotShipInInstallments Then
		DateOfShipment = '000101010000';
		For Each RowData In SupplyWithMaterialsAndWorks Do
			If RowData.SupplyOption <> Enums.SupplyOptions.Ship Then
				DateOfShipment = Max(RowData.DateOfShipment, DateOfShipment);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Procedure FillInMaximumExpenseDate()
	
	If Not ConsumptionInOneDay Then
		DateOfMaterialWorkConsumption = Max(Documents.ProductionStage2_2.MaximumDateWH(MaterialsAndWorksConsumption, "DateOfMaterialWorkConsumption"),
								Documents.ProductionStage2_2.MaximumDateWH(UnusedMaterials, "DateOfTransaction"));
	EndIf;
	
EndProcedure

Procedure FillInStatusesForSpecifyingVHFSeries(TSName, SeriesSpecificationParameters = Undefined)
	
	If SeriesSpecificationParameters = Undefined Then
		SeriesSpecificationParameters = Documents.ProductionStage2_2.SeriesSpecificationParameters(ThisObject);
	EndIf;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters[TSName]);
	
EndProcedure

Function StageExecutionIsStarted()
	
	Return Status = Enums.StatusesOfProductionStages2_2.Initiated
		Or Status = Enums.StatusesOfProductionStages2_2.Completed;
	
EndFunction

Function DataFromObjectCache(Var_Key)
	
	Var Result, CachedValues;
	
	If Not AdditionalProperties.Property("CachedValues", CachedValues) Then
		CachedValues = New Structure();
		AdditionalProperties.Insert("CachedValues", CachedValues);
	EndIf;
	
	If Not CachedValues.Property(Var_Key, Result) Then
		
		If Var_Key = "ProductionSchedule" Then
			
			Result = InformationRegisters.ScheduleOfProductionStages2_2.ProductionSchedule(
				CommonClientServer.ValueInArray(ThisObject.Ref));
			
		ElsIf Var_Key = "ChangedManualPlacementOfStageInSchedule" Then
			
			Result = False;
			
			If EditedParametersForManualPlacementInChart() Then
				
				If InformationRegisters.ScheduleOfProductionStages2_2.PlacementOfStageInScheduleHasChanged(
					ThisObject.Ref, AdditionalProperties.ProductionSchedule) Then
					
					Result = True;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		CachedValues.Insert(Var_Key, Result);
		
	EndIf;
	
	Return Result;
	
EndFunction

Function FindUndoneRows(TSName)
	
	Return ThisObject[TSName].FindRows(New Structure("Canceled", False));
	
EndFunction

Procedure ShouldRecalculate(ZoomRatio) Export
	
	NumberOfPackagesPlan = NumberOfPackagesPlan * ZoomRatio;
	
	If Not PlanOperationsOfWorkCenterTypes
		And Not StagePlacementInProductionSchedule Then
		StageDuration = StageDuration * ZoomRatio;
	EndIf;
	
	StructureOfActions = New Structure("RecalculateNumberOfPackages",
		BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfNumberOfPackages());
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	// Supply
	For IndexOf = -SupplyWithMaterialsAndWorks.Count()+1 To 0 Do
		
		String = SupplyWithMaterialsAndWorks[-IndexOf];
		String.Count = String.Count * ZoomRatio;
		
		If String.Count = 0 Then
			SupplyWithMaterialsAndWorks.Delete(String);
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.TreatTS(SupplyWithMaterialsAndWorks, StructureOfActions, CachedValues);
	
	// Output items
	RowsWithSeries_ = New Array;
	
	For IndexOf = -ManufacturedProducts.Count()+1 To 0 Do
		
		String = ManufacturedProducts[-IndexOf];
		String.Count = String.Count * ZoomRatio;
		
		If String.Count = 0 Then
			ManufacturedProducts.Delete(String);
		ElsIf String.BatchesIndicationStatus <> 0 Then
			RowsWithSeries_.Add(String);
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.TreatTS(ManufacturedProducts, StructureOfActions, CachedValues);
	
	If RowsWithSeries_.UBound() <> -1 Then
		
		Analysts = "Products,Characteristic,Purpose,Recipient,Manufactured,ProductionDate";
		TheStructureOfTheSearch = New Structure(Analysts);
		Products_1 = ManufacturedProducts.Unload(RowsWithSeries_, Analysts + ",Count");
		Products_1.GroupBy(Analysts, "Count");
		
		For Each ProductLine In Products_1 Do
			Balance = ProductLine.Count;
			FillPropertyValues(TheStructureOfTheSearch, ProductLine);
			For Each StringSeries In BatchFinishedProducts.FindRows(TheStructureOfTheSearch) Do
				
				If Balance = 0 Then
					BatchFinishedProducts.Delete(StringSeries);
				Else
					StringSeries.Count = Min(StringSeries.Count, Balance);
					Balance = Balance - StringSeries.Count;
				EndIf;
				
			EndDo;
		EndDo;
		
		FillInStatusesForSpecifyingVHFSeries(
			"ManufacturedProducts",
			Documents.ProductionStage2_2.SeriesSpecificationParameters(ThisObject));
		
	EndIf;
	
	// By-products
	RowsWithSeries_.Clear();
	
	For IndexOf = -SideAndIntermediateRelease.Count()+1 To 0 Do
		
		String = SideAndIntermediateRelease[-IndexOf];
		String.Count = String.Count * ZoomRatio;
		
		If String.Count = 0 Then
			SideAndIntermediateRelease.Delete(String);
		ElsIf String.BatchesIndicationStatus <> 0 Then
			RowsWithSeries_.Add(String);
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.TreatTS(SideAndIntermediateRelease, StructureOfActions, CachedValues);
	
	If RowsWithSeries_.UBound() <> -1 Then
		
		Analysts = "Products,Characteristic,Purpose,Recipient,Manufactured,ProductionDate,ProductOwner";
		TheStructureOfTheSearch = New Structure(Analysts);
		Products_1 = SideAndIntermediateRelease.Unload(RowsWithSeries_, Analysts + ",Count");
		Products_1.GroupBy(Analysts, "Count");
		
		For Each ProductLine In Products_1 Do
			Balance = ProductLine.Count;
			FillPropertyValues(TheStructureOfTheSearch, ProductLine);
			For Each StringSeries In BatchSideAndIntermediateRelease.FindRows(TheStructureOfTheSearch) Do
				
				If Balance = 0 Then
					BatchSideAndIntermediateRelease.Delete(StringSeries);
				Else
					StringSeries.Count = Min(StringSeries.Count, Balance);
					Balance = Balance - StringSeries.Count;
				EndIf;
				
			EndDo;
		EndDo;
		
		FillInStatusesForSpecifyingVHFSeries(
			"SideAndIntermediateRelease",
			Documents.ProductionStage2_2.SeriesSpecificationParameters(ThisObject));
		
	EndIf;
	
	// LaborCosts
	For IndexOf = -LaborCosts.Count()+1 To 0 Do
		
		String = LaborCosts[-IndexOf];
		String.Count = String.Count * ZoomRatio;
		
		If String.Count = 0 Then
			LaborCosts.Delete(String);
		EndIf;
		
	EndDo;
	
	// Types of work centers
	For IndexOf = -WorkCenterTypes.Count()+1 To 0 Do
		
		String = WorkCenterTypes[-IndexOf];
		String.OperationTime = String.OperationTime * ZoomRatio;
		
		If String.OperationTime = 0 Then
			WorkCenterTypes.Delete(String);
		EndIf;
		
	EndDo;
	
	// Alternative types of work centers
	For IndexOf = -AlternateWorkCenterTypes.Count()+1 To 0 Do
		
		String = AlternateWorkCenterTypes[-IndexOf];
		String.OperationTime = String.OperationTime * ZoomRatio;
		
		If String.OperationTime = 0 Then
			AlternateWorkCenterTypes.Delete(String);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ReflectTheNumberOfHoursOfWH(Performer = Undefined) Export
	
	If NumberOfPackagesPlan = 0 Then
		Return;
	EndIf;
	
	BatchData = Common.ObjectAttributesValues(ProductionLot,
		"MainProductProducts, MainProductCharacteristic");
	
	// Calculation of the coefficient
	ZoomRatio = 0;
	If PackagePlan = PackageActualData Then
		ZoomRatio = NumberOfPackagesReal/NumberOfPackagesPlan;
	Else
		CoefficientPlan = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(
			PackagePlan, BatchData.MainProductProducts);
		CoefficientFact = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(
			PackageActualData, BatchData.MainProductProducts);
		ZoomRatio = (NumberOfPackagesReal * CoefficientFact) / (NumberOfPackagesPlan * CoefficientPlan);
	EndIf;
	
	// Variable declaration
	TheStructureOfTheSearch = New Structure("Department, Products, Characteristic");
	SeriesSearchStructure = New Structure("Department, Products, Characteristic, Recipient, Purpose, Manufactured, ProductionDate");
	ReadyForProcessing_ = New Array;
	StructureOfActions = New Structure("RecalculateNumberOfPackages");
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	SeriesSpecificationParameters = Documents.ProductionStage2_2.SeriesSpecificationParameters(ThisObject);
	
	// Consumption of materials and works
	TableResults_ = SupplyWithMaterialsAndWorks.Unload(, "Department, Products, Characteristic, Count");
	TableResults_.GroupBy("Department, Products, Characteristic", "Count");
	For Each String In TableResults_ Do
		String.Count = String.Count * ZoomRatio;
	EndDo;
	TableResults_.Indexes.Add("Department, Products, Characteristic");
	
	TableExpense = MaterialsAndWorksConsumption.Unload(, "Department, Products, Characteristic, Count");
	SubtractRowsFromTable(TableResults_, TableExpense, New Structure("Department, Products, Characteristic"), False);
	
	TableBalance = SupplyWithMaterialsAndWorks.Unload(
		New Structure("Canceled", False),
		"Department, Products, Characteristic, Series, Package, Count, ProductCostElement");
	TableBalance.Sort("Products, Characteristic, Series, Package, ProductCostElement, Department");
	TableBalance.Indexes.Add("Department, Products, Characteristic, Series");
	TableBalance.Indexes.Add("Department, Products, Characteristic");
	
	TableExpense = MaterialsAndWorksConsumption.Unload(, "Department, Products, Characteristic, Series, Count");
	TableEconomy = UnusedMaterials.Unload(, "Department, Products, Characteristic, Series, Count");
	
	TMCommonUse.AddSequenceNumberOfRowsToTable(TableBalance);
	SubtractRowsFromTable(TableBalance, TableExpense, New Structure("Department, Products, Characteristic, Series"));
	SubtractRowsFromTable(TableBalance, TableEconomy, New Structure("Department, Products, Characteristic, Series"));
	SubtractRowsFromTable(TableBalance, TableEconomy, New Structure("Department, Products, Characteristic"));
	SubtractRowsFromTable(TableBalance, TableExpense, New Structure("Department, Products, Characteristic"));
	
	If ConsumptionInOneDay Then
		DateOfTransaction = DateOfMaterialWorkConsumption;
	ElsIf ActualStageEnd <> '000101010000'
			And Status = Enums.StatusesOfProductionStages2_2.Completed Then
		DateOfTransaction = BegOfDay(ActualStageEnd);
	Else
		DateOfTransaction = BegOfDay(CurrentSessionDate());
	EndIf;
	
	FilterStructure1 = New Structure("Products, Characteristic, Series, Package, ProductCostElement, Department");
	ComparisonStructure = New Structure("Products, Characteristic, Series, Package, ProductCostElement, Department");
	
	For IndexOf = 0 To TableBalance.Count()-1 Do
		
		StringBalance = TableBalance[IndexOf];
		If StringBalance.Count = 0 Then
			Continue;
		EndIf;
		
		FillPropertyValues(FilterStructure1, StringBalance);
		DataMatch = Common.DataMatch(FilterStructure1, ComparisonStructure);
		FillPropertyValues(ComparisonStructure, FilterStructure1);
		
		FillPropertyValues(TheStructureOfTheSearch, StringBalance);
		FoundRows = TableResults_.FindRows(TheStructureOfTheSearch);
		If FoundRows.UBound() = -1 
				Or FoundRows[0].Count = 0 Then
			Continue;
		EndIf;
		RowTotals = FoundRows[0];
		NumberOfEmployees = Min(StringBalance.Count, RowTotals.Count);
		
		If Not DataMatch Then
			NewRow = MaterialsAndWorksConsumption.Add();
		EndIf;
		
		FillPropertyValues(NewRow, StringBalance,, "Count");
		NewRow.Count = NewRow.Count + NumberOfEmployees;
		NewRow.DateOfMaterialWorkConsumption = DateOfTransaction;
		
		If Not DataMatch Then
			ReadyForProcessing_.Add(NewRow);
		EndIf;
		
		RowTotals.Count = RowTotals.Count - NumberOfEmployees;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ReadyForProcessing_,
		StructureOfActions,
		MaterialsAndWorksConsumption,
		CachedValues);
	ReadyForProcessing_.Clear();
	
	FillInStatusesForSpecifyingVHFSeries("MaterialsAndWorksConsumption", SeriesSpecificationParameters);
	
	// Output and by-products
	If ProductionInOneDay Then
		DateOfTransaction = ProductionDate;
	ElsIf ActualStageEnd <> '000101010000'
			And Status = Enums.StatusesOfProductionStages2_2.Completed Then
		DateOfTransaction = BegOfDay(ActualStageEnd);
	Else
		DateOfTransaction = BegOfDay(CurrentSessionDate());
	EndIf;
	
	ExcludeColumns = "RowCode, RowID, KeyProducts";
	
	For Cnt = 1 To 2 Do
		
		If Cnt = 1 Then
			TSName      = "ManufacturedProducts";
			TSSeriesName = "BatchFinishedProducts";
		Else
			TSName      = "SideAndIntermediateRelease";
			TSSeriesName = "BatchSideAndIntermediateRelease";
		EndIf;
		
		TableResults_ = TabularPartByName(TSName).Unload(, "Department, Products, Characteristic, Count, Manufactured");
		TableResults_.Columns.Add("QuantityProduced", New TypeDescription("Number", New NumberQualifiers(15,3)));
		TableResults_.Columns.Add("Allocate", New TypeDescription("Number", New NumberQualifiers(15,3)));
		
		For Each String In TableResults_.FindRows(New Structure("Manufactured", True)) Do
			String.QuantityProduced = String.Count;
		EndDo;
		TableResults_.GroupBy("Department, Products, Characteristic", "Count, QuantityProduced, Allocate");
		For Each String In TableResults_ Do
			String.Allocate = String.Count * ZoomRatio - String.QuantityProduced;
		EndDo;
		TableResults_.Indexes.Add("Department, Products, Characteristic");
		
		IndexOf = 0;
		While IndexOf < ThisObject[TSName].Count() Do
			
			String = ThisObject[TSName][IndexOf];
			IndexOf = IndexOf + 1;
			If String.Manufactured
				Or String.Canceled
				Or String.Count = 0 Then
				Continue;
			EndIf;
			
			FillPropertyValues(TheStructureOfTheSearch, String);
			RowTotals = TableResults_.FindRows(TheStructureOfTheSearch)[0];
			If RowTotals.Allocate <= 0 Then
				Continue;
			EndIf;
			
			StringProduced = String;
			If RowTotals.Allocate < String.Count Then
				
				NewRow = ThisObject[TSName].Insert(IndexOf);
				FillPropertyValues(NewRow, String,, ExcludeColumns);
				NewRow.Count = RowTotals.Allocate;
				ReadyForProcessing_.Add(NewRow);
				
				String.Count = String.Count - RowTotals.Allocate;
				ReadyForProcessing_.Add(String);
				
				If TSName = "ManufacturedProducts" Then
					ProductionClientServer.RecalculateFractionOfCostWhenSplittingRow(
						NewRow,
						String,
						MethodOfAllocatingFinishedProductCosts);
				EndIf;
				
				StringProduced = NewRow;
				IndexOf = IndexOf + 1;
				
			EndIf;
			
			If StringProduced.BatchesIndicationStatus <> 0 Then
				
				Allocate = StringProduced.Count;
				
				FillPropertyValues(SeriesSearchStructure, StringProduced);
				For Each RowSeries In ThisObject[TSSeriesName].FindRows(SeriesSearchStructure) Do
					
					If Allocate >= RowSeries.Count Then
						RowSeries.Manufactured = True;
						RowSeries.ProductionDate = DateOfTransaction;
						Allocate = Allocate - RowSeries.Count;
					Else
						NewRowSeries = ThisObject[TSSeriesName].Add();
						FillPropertyValues(NewRowSeries, RowSeries);
						NewRowSeries.Count = Allocate;
						NewRowSeries.Manufactured = True;
						NewRowSeries.ProductionDate = DateOfTransaction;
						
						RowSeries.Count = RowSeries.Count - Allocate;
						Allocate = 0;
					EndIf;
					
					If Allocate = 0 Then
						Break;
					EndIf;
					
				EndDo;
				
			EndIf;
			
			StringProduced.Manufactured = True;
			StringProduced.ProductionDate = DateOfTransaction;
				
			RowTotals.Allocate = RowTotals.Allocate - StringProduced.Count;

		EndDo;
		
		If TSName = "ManufacturedProducts"
			And ZoomRatio > 1 Then
			CoefficientFact = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(
				PackageActualData, BatchData.MainProductProducts);
			CountReal = NumberOfPackagesReal * CoefficientFact;
			
			ProductItemSearchStructure = New Structure;
			ProductItemSearchStructure.Insert("Products", BatchData.MainProductProducts);
			ProductItemSearchStructure.Insert("Characteristic", BatchData.MainProductCharacteristic);
			
			QuantityInTable = ManufacturedProducts.Unload(ProductItemSearchStructure, "Count").Total("Count");
			
			If CountReal > QuantityInTable Then
				ProductItemSearchStructure.Insert("Manufactured", True);
				ProductItemSearchStructure.Insert("ProductionDate", DateOfTransaction);
				FoundRows = ManufacturedProducts.FindRows(ProductItemSearchStructure);
				If FoundRows.UBound() <> -1 Then
					String = FoundRows[0];
					String.Count = String.Count + (CountReal - QuantityInTable);
					ReadyForProcessing_.Add(String);
					
					If String.BatchesIndicationStatus <> 0 Then
						FillPropertyValues(SeriesSearchStructure, String);
						FoundSeriesRows = BatchFinishedProducts.FindRows(SeriesSearchStructure);
						If FoundSeriesRows.UBound() <> -1 Then
							FoundSeriesRows[0].Count = FoundSeriesRows[0].Count
								+ (CountReal - QuantityInTable);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		ElsIf TSName = "SideAndIntermediateRelease" Then
			Documents.ProductionStage2_2.FillInPricesByPriceKind(ThisObject);
		EndIf;
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			ReadyForProcessing_,
			StructureOfActions,
			ThisObject[TSName],
			CachedValues);
		ReadyForProcessing_.Clear();
		
		FillInStatusesForSpecifyingVHFSeries(TSName, SeriesSpecificationParameters);
		
	EndDo;
	
	// LaborCosts
	TheStructureOfTheSearch = New Structure("Department, WorkKind");
	If Documents.ProductionStage2_2.MarkOfPerformedLaborCostsIsUsed(ThisObject) Then
		
		TableResults_ = LaborCosts.Unload(, "Department, WorkKind, Count, Completed2");
		TableResults_.Columns.Add("QuantityCompleted", New TypeDescription("Number", New NumberQualifiers(15,3)));
		TableResults_.Columns.Add("Allocate", New TypeDescription("Number", New NumberQualifiers(15,3)));
		
		For Each String In TableResults_.FindRows(New Structure("Completed2", True)) Do
			String.QuantityCompleted = String.Count;
		EndDo;
		TableResults_.GroupBy("Department, WorkKind", "Count, QuantityCompleted, Allocate");
		For Each String In TableResults_ Do
			String.Allocate = String.Count * ZoomRatio - String.QuantityCompleted;
		EndDo;
		TableResults_.Indexes.Add("Department, WorkKind");
		
		If WorkPerformanceAsOneDay Then
			DateOfTransaction = WorkExecutionDate;
		ElsIf ActualStageEnd <> '000101010000'
				And Status = Enums.StatusesOfProductionStages2_2.Completed Then
			DateOfTransaction = BegOfDay(ActualStageEnd);
		Else
			DateOfTransaction = BegOfDay(CurrentSessionDate());
		EndIf;
		
		IndexOf = 0;
		While IndexOf < LaborCosts.Count() Do
			
			String = LaborCosts[IndexOf];
			IndexOf = IndexOf + 1;
			
			If String.Completed2
				And Not ValueIsFilled(String.Performer)
				And ValueIsFilled(Performer) Then
				String.Performer = Performer;
			EndIf;
			
			If String.Completed2
				Or String.Canceled
				Or String.Count = 0 Then
				Continue;
			EndIf;
		
			FillPropertyValues(TheStructureOfTheSearch, String);
			RowTotals = TableResults_.FindRows(TheStructureOfTheSearch)[0];
			If RowTotals.Allocate <= 0 Then
				Continue;
			EndIf;
			
			LineCompleted = String;
			If RowTotals.Allocate < String.Count Then
				
				NewRow = LaborCosts.Insert(IndexOf);
				FillPropertyValues(NewRow, String, , "RowCode,KeyWorkType");
				NewRow.Count = RowTotals.Allocate;
				
				String.Count = String.Count - RowTotals.Allocate;
				
				LineCompleted = NewRow;
				IndexOf = IndexOf + 1;
				
			EndIf;
			LineCompleted.Completed2 = True;
			LineCompleted.ExecutionDate = DateOfTransaction;
			If ValueIsFilled(Performer)
					And Not ValueIsFilled(LineCompleted.Performer) Then
				LineCompleted.Performer = Performer;
			EndIf;
			
			RowTotals.Allocate = RowTotals.Allocate - LineCompleted.Count;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure ReflectTheAmountCanceledByWH(CancellationReason) Export
	
	If NumberOfPackagesPlan = 0 Then
		Return;
	EndIf;
	
	// Calculation of the coefficient
	ZoomRatio = 0;
	If PackagePlan = PackageCanceled Then
		ZoomRatio = NumberOfPackagesCanceled/NumberOfPackagesPlan;
	Else
		Products = Common.ObjectAttributeValue(ProductionLot, "MainProductProducts");
		CoefficientPlan = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(PackagePlan, Products);
		ZoomRatioCanceled = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(PackageCanceled, Products);
		ZoomRatio = (NumberOfPackagesCanceled * ZoomRatioCanceled) / (NumberOfPackagesPlan * CoefficientPlan);
	EndIf;
	
	// Variable declaration
	TheStructureOfTheSearch = New Structure("Department, Products, Characteristic");
	SeriesSearchStructure = New Structure("Department, Products, Characteristic, Recipient, Purpose, Manufactured, ProductionDate");
	ReadyForProcessing_ = New Array;
	StructureOfActions = New Structure("RecalculateNumberOfPackages");
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	SeriesSpecificationParameters = Documents.ProductionStage2_2.SeriesSpecificationParameters(ThisObject);
	ExcludeColumns = "RowCode, RowID, KeyProducts";
	
	// Provision of materials and works
	TableResults_ = SupplyWithMaterialsAndWorks.Unload(, "Department, Products, Characteristic, Count, Canceled");
	TableResults_.Columns.Add("CountCanceled", New TypeDescription("Number", New NumberQualifiers(15,3)));
	TableResults_.Columns.Add("Allocate", New TypeDescription("Number", New NumberQualifiers(15,3)));
	
	For Each String In TableResults_.FindRows(New Structure("Canceled", True)) Do
		String.CountCanceled = String.Count;
	EndDo;
	TableResults_.GroupBy("Department, Products, Characteristic", "Count, CountCanceled, Allocate");
	For Each String In TableResults_ Do
		String.Allocate = String.Count * ZoomRatio - String.CountCanceled;
	EndDo;
	TableResults_.Indexes.Add("Department, Products, Characteristic");
	
	IndexOf = 0;
	While IndexOf < SupplyWithMaterialsAndWorks.Count() Do
		
		String = SupplyWithMaterialsAndWorks[IndexOf];
		IndexOf = IndexOf + 1;
		If String.SupplyOption = Enums.SupplyOptions.Ship
			Or String.Canceled
			Or String.Count = 0 Then
			Continue;
		EndIf;
		
		FillPropertyValues(TheStructureOfTheSearch, String);
		RowTotals = TableResults_.FindRows(TheStructureOfTheSearch)[0];
		If RowTotals.Allocate <= 0 Then
			Continue;
		EndIf;
		
		StringCanceled = String;
		If RowTotals.Allocate < String.Count Then
			
			NewRow = SupplyWithMaterialsAndWorks.Insert(IndexOf);
			FillPropertyValues(NewRow, String,, ExcludeColumns);
			NewRow.Count = RowTotals.Allocate;
			ReadyForProcessing_.Add(NewRow);
			
			String.Count = String.Count - RowTotals.Allocate;
			ReadyForProcessing_.Add(String);
			
			StringCanceled = NewRow;
			IndexOf = IndexOf + 1;
			
		EndIf;
		StringCanceled.Canceled = True;
		StringCanceled.CancellationReason = CancellationReason;
			
		RowTotals.Allocate = RowTotals.Allocate - StringCanceled.Count;
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ReadyForProcessing_,
		StructureOfActions,
		SupplyWithMaterialsAndWorks,
		CachedValues);
	ReadyForProcessing_.Clear();
	
	FillInStatusesForSpecifyingVHFSeries("SupplyWithMaterialsAndWorks", SeriesSpecificationParameters);
	
	// Output and by-products
	For Cnt = 1 To 2 Do
		
		TSName = ?(Cnt = 1, "ManufacturedProducts", "SideAndIntermediateRelease");
		
		TableResults_ = TabularPartByName(TSName).Unload(, "Department, Products, Characteristic, Count, Canceled");
		TableResults_.Columns.Add("CountCanceled", New TypeDescription("Number", New NumberQualifiers(15,3)));
		TableResults_.Columns.Add("Allocate", New TypeDescription("Number", New NumberQualifiers(15,3)));
		
		For Each String In TableResults_.FindRows(New Structure("Canceled", True)) Do
			String.CountCanceled = String.Count;
		EndDo;
		TableResults_.GroupBy("Department, Products, Characteristic", "Count, CountCanceled, Allocate");
		For Each String In TableResults_ Do
			String.Allocate = String.Count * ZoomRatio - String.CountCanceled;
		EndDo;
		TableResults_.Indexes.Add("Department, Products, Characteristic");
		
		IndexOf = 0;
		While IndexOf < ThisObject[TSName].Count() Do
			
			String = ThisObject[TSName][IndexOf];
			IndexOf = IndexOf + 1;
			If String.Manufactured
				Or String.Canceled
				Or String.Count = 0 Then
				Continue;
			EndIf;
			
			FillPropertyValues(TheStructureOfTheSearch, String);
			RowTotals = TableResults_.FindRows(TheStructureOfTheSearch)[0];
			If RowTotals.Allocate <= 0 Then
				Continue;
			EndIf;
			
			StringCanceled = String;
			If RowTotals.Allocate < String.Count Then
				
				NewRow = ThisObject[TSName].Insert(IndexOf);
				FillPropertyValues(NewRow, String,, ExcludeColumns);
				NewRow.Count = RowTotals.Allocate;
				ReadyForProcessing_.Add(NewRow);
				
				String.Count = String.Count - RowTotals.Allocate;
				ReadyForProcessing_.Add(String);
				
				If TSName = "ManufacturedProducts" Then
					ProductionClientServer.RecalculateFractionOfCostWhenSplittingRow(
						NewRow,
						String,
						MethodOfAllocatingFinishedProductCosts);
				EndIf;
				
				StringCanceled = NewRow;
				IndexOf = IndexOf + 1;
				
			EndIf;
			StringCanceled.Canceled = True;
			StringCanceled.CancellationReason = CancellationReason;
				
			RowTotals.Allocate = RowTotals.Allocate - StringCanceled.Count;

		EndDo;
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			ReadyForProcessing_,
			StructureOfActions,
			ThisObject[TSName],
			CachedValues);
		ReadyForProcessing_.Clear();
	
		FillInStatusesForSpecifyingVHFSeries(TSName, SeriesSpecificationParameters);
		
	EndDo;
	
	// LaborCosts
	TheStructureOfTheSearch = New Structure("Department, WorkKind");
	
	TableResults_ = LaborCosts.Unload(, "Department, WorkKind, Count, Canceled");
	TableResults_.Columns.Add("CountCanceled", New TypeDescription("Number", New NumberQualifiers(15,3)));
	TableResults_.Columns.Add("Allocate", New TypeDescription("Number", New NumberQualifiers(15,3)));
	
	For Each String In TableResults_.FindRows(New Structure("Canceled", True)) Do
		String.CountCanceled = String.Count;
	EndDo;
	TableResults_.GroupBy("Department, WorkKind", "Count, CountCanceled, Allocate");
	For Each String In TableResults_ Do
		String.Allocate = String.Count * ZoomRatio - String.CountCanceled;
	EndDo;
	TableResults_.Indexes.Add("Department, WorkKind");
	
	IndexOf = 0;
	While IndexOf < LaborCosts.Count() Do
		
		String = LaborCosts[IndexOf];
		IndexOf = IndexOf + 1;
		If String.Completed2
			Or String.Canceled
			Or String.Count = 0 Then
			Continue;
		EndIf;
		
		FillPropertyValues(TheStructureOfTheSearch, String);
		RowTotals = TableResults_.FindRows(TheStructureOfTheSearch)[0];
		If RowTotals.Allocate <= 0 Then
			Continue;
		EndIf;
		
		StringCanceled = String;
		If RowTotals.Allocate < String.Count Then
			
			NewRow = LaborCosts.Insert(IndexOf);
			FillPropertyValues(NewRow, String, , "RowCode,KeyWorkType");
			NewRow.Count = RowTotals.Allocate;
			
			String.Count = String.Count - RowTotals.Allocate;
			
			StringCanceled = NewRow;
			IndexOf = IndexOf + 1;
			
		EndIf;
		StringCanceled.Canceled = True;
		StringCanceled.CancellationReason = CancellationReason;
		
		RowTotals.Allocate = RowTotals.Allocate - StringCanceled.Count;
		
	EndDo;
	
EndProcedure

Procedure SubtractRowsFromTable(Table1, Table2, SearchCondition, ProcessingInRowOrder = True)
	
	IndexOf2 = 0;
	
	While IndexOf2 < Table2.Count() Do
		
		String2 = Table2[IndexOf2];
		
		FillPropertyValues(SearchCondition, String2);
		FoundRows = ?(ProcessingInRowOrder,
			TMCommonUse.FindRowsWithPreservingOrder(Table1, SearchCondition, True),
			Table1.FindRows(SearchCondition));
		
		For Index1 = 0 To FoundRows.UBound() Do

			String1 = FoundRows[Index1];
			Count = Min(String1.Count, String2.Count);
			
			String1.Count = String1.Count - Count;
			String2.Count = String2.Count - Count;
			
			If String2.Count = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
		If String2.Count = 0 Then
			Table2.Delete(String2);
		Else
			IndexOf2 = IndexOf2 + 1;
		EndIf;
		
	EndDo;
	
EndProcedure

Function TabularPartByName(TSName)

	If TSName = "ManufacturedProducts" Then
		TabularSection = ThisObject.ManufacturedProducts;
		
	ElsIf TSName = "BatchFinishedProducts" Then
		TabularSection = ThisObject.BatchFinishedProducts;
		
	ElsIf TSName = "SideAndIntermediateRelease" Then
		TabularSection = ThisObject.SideAndIntermediateRelease;
		
	ElsIf TSName = "BatchSideAndIntermediateRelease" Then
		TabularSection = ThisObject.SideAndIntermediateRelease;

	ElsIf TSName = "SupplyWithMaterialsAndWorks" Then
		TabularSection = ThisObject.SupplyWithMaterialsAndWorks;

	ElsIf TSName = "MaterialsAndWorksConsumption" Then
		TabularSection = ThisObject.MaterialsAndWorksConsumption;

	ElsIf TSName = "UnusedMaterials" Then
		TabularSection = ThisObject.UnusedMaterials;

	ElsIf TSName = "SavingMaterialsBatch" Then
		TabularSection = ThisObject.SavingMaterialsBatch;

	ElsIf TSName = "LaborCosts" Then
		TabularSection = ThisObject.LaborCosts;

	ElsIf TSName = "WorkCenterTypes" Then
		TabularSection = ThisObject.WorkCenterTypes;

	ElsIf TSName = "AlternateWorkCenterTypes" Then
		TabularSection = ThisObject.AlternateWorkCenterTypes;

	ElsIf TSName = "OccupancyOfWorkCenterTypes" Then
		TabularSection = ThisObject.OccupancyOfWorkCenterTypes;

	ElsIf TSName = "Successors" Then
		TabularSection = ThisObject.Successors;

	ElsIf TSName = "InventoryOwnerAttributesProducts" Then
		TabularSection = ThisObject.InventoryOwnerAttributesProducts;

	ElsIf TSName = "InventoryOwnerAttributesMaterials" Then
		TabularSection = ThisObject.InventoryOwnerAttributesMaterials;

	Else
		TabularSection = Undefined;

	EndIf;
	
	Return TabularSection;
	
EndFunction

// Returns the data of the document tables.
//
// Returns:
//	See Documents.ProductionStage2_2.CollectionOfTabularPartsOfGoods
//
Function DocumentTables()
	
	If AdditionalProperties.Property("TablesOfFillingOfTypesOfStocksAtExchange")
			And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange <> Undefined Then
		
		DocumentTables = AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange;
		
	Else
		DocumentTables = Documents.ProductionStage2_2.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	Return DocumentTables;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
