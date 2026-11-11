
#Region Public

Procedure CreateStagesForLaunching(ManufacturedProductsGroups, Products_1, PartyKeys, Parameters, StorageAddress) Export
	
	Result = ResultOfFormation();
	
	AssignmentsOfMaterials = Parameters.AssignmentsOfMaterials; // ValueTable
	AssignmentsOfMaterials.Indexes.Add("NumberOfGroup");
	
	PortionSize = 500;
	
	If ManufacturedProductsGroups.Count() <= PortionSize Then
		FormPortionOfStages(
			ManufacturedProductsGroups, Products_1, PartyKeys, AssignmentsOfMaterials, Parameters, Result, StorageAddress);
	Else
		Counter = 1;
		MaxIndex = ManufacturedProductsGroups.Count()-1;
		
		ProductGroupsCopy = ManufacturedProductsGroups.CopyColumns();
		ManufacturedProducts_Copy = Products_1.CopyColumns();
		LotReferenceCopyKeys = PartyKeys.CopyColumns();
	
		Products_1.Indexes.Add("NumberOfGroup");
		PartyKeys.Indexes.Add("NumberOfGroup");
		
		TheStructureOfTheSearch = New Structure("NumberOfGroup");
	
		For IndexOf = 0 To MaxIndex Do
			GroupString = ManufacturedProductsGroups[IndexOf];
			FillPropertyValues(ProductGroupsCopy.Add(), GroupString);
			
			TheStructureOfTheSearch.NumberOfGroup = GroupString.NumberOfGroup;
			For Each ProductLine In Products_1.FindRows(TheStructureOfTheSearch) Do
				FillPropertyValues(ManufacturedProducts_Copy.Add(), ProductLine);
			EndDo;
			For Each StringKey In PartyKeys.FindRows(TheStructureOfTheSearch) Do
				FillPropertyValues(LotReferenceCopyKeys.Add(), StringKey);
			EndDo;
			
			If Counter = PortionSize Or IndexOf = MaxIndex Then
				FormPortionOfStages(
					ProductGroupsCopy, ManufacturedProducts_Copy, LotReferenceCopyKeys, AssignmentsOfMaterials, Parameters, Result, StorageAddress);
				
				ProductGroupsCopy.Clear();
				ManufacturedProducts_Copy.Clear();
				LotReferenceCopyKeys.Clear();
				Counter = 1;
			Else
				Counter = Counter+1;
			EndIf;
		EndDo;
	EndIf;
	
	SupplyInDocumentsServerCall.ThereAreTasksForOrders(Result.CreatedObjects);
	OrderStructure.StartCalculation();
	
EndProcedure

#EndRegion

#Region Internal

Function ResultOfFormation() Export
	
	ResultOfFormation = New ValueTable;
	ResultOfFormation.Columns.Add("Lot", New TypeDescription("CatalogRef.ProductionLots"));
	ResultOfFormation.Columns.Add("Document", New TypeDescription("DocumentRef.ProductionStage2_2"));
	
	CreatedObjects = New Array;
	
	Errors = New ValueTable;
	Errors.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	Errors.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Errors.Columns.Add("LineOfBusiness", New TypeDescription("CatalogRef.LinesOfBusiness"));
	Errors.Columns.Add("BillOfMaterials", New TypeDescription("CatalogRef.BillsOfMaterials"));
	Errors.Columns.Add("Messages", New TypeDescription("Array, FixedArray"));
	
	Messages = New Array;
	
	Result = New Structure;
	Result.Insert("ResultOfFormation", ResultOfFormation);
	Result.Insert("CreatedObjects", CreatedObjects);
	Result.Insert("Messages", Messages);
	Result.Insert("Errors", Errors);
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

// Form a portion of the stages.
// 
// Parameters:
//  ManufacturedProductsGroups - ValueTable
//  Products_1 - ValueTable
//  PartyKeys - ValueTable
//  Parameters - Structure
//  Result - Structure
//  StorageAddress - String
//
Procedure FormPortionOfStages(ManufacturedProductsGroups, Products_1, PartyKeys, AssignmentsOfMaterials, Parameters, Result, StorageAddress)
	
	ResultOfFormation = Result.ResultOfFormation;
	CreatedObjects = Result.CreatedObjects;
	Errors = Result.Errors;
	Messages = Result.Messages;
	
	SubmitEverythingForExecution = Parameters.OptionForTransferringStagesToExecution = "All";
	PassFirstOnesToExecution = Parameters.OptionForTransferringStagesToExecution = "Top";
	TheProductionScheduleIsUsed = ProductionManagementCached.TheProductionScheduleIsUsed();
	
	Products_1.Indexes.Add("NumberOfGroup");
	
	SearchStructureGroup = New Structure("NumberOfGroup");
	SearchStructureOrder = New Structure("ReferenceOrder", Documents.ProductionOrder2_2.EmptyRef());
	SearchStructureKeyLotReference = New Structure("KeyLot");
	SearchStructureAssignmentGroup = New Structure("NumberOfGroup, Purpose", 0, Catalogs.Assignments.EmptyRef());
	
	ColumnsNames = New Array;
	For Each Column In Documents.ProductionOrder2_2.EmptyRef().Metadata().TabularSections.ManufacturedProduct.Attributes Do
		If Column.Name <> "Count"
			And Products_1.Columns.Find(Column.Name) <> Undefined Then
			ColumnsNames.Add(Column.Name);
		EndIf;
	EndDo;
	GroupingColumns = StrConcat(ColumnsNames, ",");
	
	GroupsToDelete = New Array;
	
	// Creating purchase orders
	SetPrivilegedMode(True);
	For Each Group In ManufacturedProductsGroups.FindRows(SearchStructureOrder) Do
		
		ErrorCounter = 1;
		While True Do
			
			Try
				
				HeaderAttributes = New Structure;
				
				HeaderAttributes.Insert("Department", Group.ProductionDispatcherBusinessUnit);
				HeaderAttributes.Insert("Organization", Group.Organization);
				HeaderAttributes.Insert("LineOfBusiness", Group.LineOfBusiness);
				HeaderAttributes.Insert("BusinessOperation", Group.BusinessOperation);
				HeaderAttributes.Insert("Partner", Group.Partner);
				HeaderAttributes.Insert("Contract", Group.Contract);
				HeaderAttributes.Insert("OrderForActivity", Group.OrderForActivity);
				HeaderAttributes.Insert("ProductionScheduling", Enums.WayOfLinkingProductionOperations.ToFinish);
				HeaderAttributes.Insert("EarliestStartDate", Group.EarliestStartDate);
				HeaderAttributes.Insert("DemandDate", Group.DemandDate);
				
				If ValueIsFilled(Group.Priority) Then
					HeaderAttributes.Insert("Priority", Group.Priority);
					HeaderAttributes.Insert("Queue",
						Documents.ProductionOrder2_2.QueueNumberToInsertBeforeDocuments(Group.NextOrderInQueue));
				EndIf;
				
				HeaderAttributes.Insert("DynamicStructure", True);
				HeaderAttributes.Insert("Date", CurrentSessionDate());
				HeaderAttributes.Insert("Status", Enums.ProductionOrderStatuses2_2.ToProduce);
				HeaderAttributes.Insert("OptionOfAssignment", Enums.OptionsOfMaterialAssignmentInProduction.AssignmentOfProducts);
				HeaderAttributes.Insert("Comment", NStr("vi = 'Đã tạo tự động (khởi động lô hàng)';
														|ru = 'Сформирован автоматически (запуск партий)';
														|en = 'Generated automatically (lot launch)'; fa = 'Generated automatically (lot launch)';
														|it = 'Creato automaticamente (avvio lotto)';
														|pl = 'Zarejestrowany automatycznie (uruchomienie partii)';
														|tr = 'Otomatik olarak oluşturuldu (lot başlatma)'"));
				
				SearchStructureGroup.NumberOfGroup = Group.NumberOfGroup;
				Goods = Products_1.Copy(SearchStructureGroup);
				Goods.GroupBy(GroupingColumns, "Count");
				
				FillingData = New Structure;
				FillingData.Insert("HeaderAttributes", HeaderAttributes);
				FillingData.Insert("Goods", Goods);
				
				OrderDocument = Documents.ProductionOrder2_2.CreateDocument();
				OrderDocument.Fill(FillingData);
				
				// Refusal to check filling in additional Attributes
				SessionParameters.PropertiesFillingInteractiveCheck = True;
				
				If OrderDocument.CheckFilling() Then
					OrderDocument.Write(DocumentWriteMode.Posting);
					
					Group.ReferenceOrder = OrderDocument.Ref;
					For Each Product In Products_1.FindRows(SearchStructureGroup) Do
						Product.ReferenceOrder = OrderDocument.Ref;
					EndDo;
					If Group.MultipleAppointments Then
						SearchStructureAssignmentGroup.NumberOfGroup = Group.NumberOfGroup;
						For Each String In AssignmentsOfMaterials.FindRows(SearchStructureAssignmentGroup) Do
							String.Purpose = OrderDocument.Purpose;
						EndDo;
					EndIf;
					CreatedObjects.Add(OrderDocument.Ref);
				Else
					AddError(Errors, Group, Products_1);
					
					GroupsToDelete.Add(Group);
					
					For Each Product In Products_1.FindRows(SearchStructureGroup) Do
						Products_1.Delete(Product);
					EndDo;
				EndIf;
				
				// Fixing the result
				PutToTempStorage(Result, StorageAddress);
				
			Except
				
				Event = NStr("vi = 'Công đoạn sản xuất';
							|ru = 'Этап производства';
							|en = 'Production stage'; fa = 'مرحله تولید';
							|it = 'Fase di produzione';
							|pl = 'Etap produkcji';
							|tr = 'Üretim aşaması'", Common.DefaultLanguageCode()) + "."
					+ NStr("vi = 'Tạo công đoạn ';
							|ru = 'Формирование этапов';
							|en = 'Generate stages'; fa = 'ایجاد مراحل';
							|it = 'Generazione delle fasi';
							|pl = 'Formowanie etapów';
							|tr = 'Aşamaların oluşturulması'", Common.DefaultLanguageCode());
				
				If ErrorCounter < 3 Then
					MessageText = StrTemplate(NStr("vi = 'Thử ghi lại thất bại (%1): %2';
													|ru = 'Неудачная попытка записи (%1): %2';
													|en = 'Unsuccessful attempt to write (%1): %2'; fa = 'Unsuccessful attempt to write (%1): %2';
													|it = 'Tentativo fallito di registrazione (%1): %2';
													|pl = 'Nieudana próba zapisu (%1): %2';
													|tr = 'Başarısız kayıt denemesi (%1): %2'"),
						ErrorCounter, DetailErrorDescription(ErrorInfo()));
					WriteLogEvent(Event, EventLogLevel.Warning,,, MessageText);
					
					ErrorCounter = ErrorCounter + 1;
					Continue;
				EndIf;
				
				WriteLogEvent(Event, EventLogLevel.Error,,,
					DetailErrorDescription(ErrorInfo()));
				
				AddError(Errors, Group, Products_1, DetailErrorDescription(ErrorInfo()));
				
			EndTry;
			
			Break;
			
		EndDo;
		
	EndDo;
	SetPrivilegedMode(False);
	
	For Each Group In GroupsToDelete Do
		ManufacturedProductsGroups.Delete(Group);
	EndDo;
	
	//
	ManufacturedProductsGroups.Indexes.Add("NumberOfGroup");
	Products_1.Indexes.Add("NumberOfGroup");
	Products_1.Indexes.Add("NumberOfGroup, BatchNumberInGroup");
	StructureOfSearchParty = New Structure("NumberOfGroup, BatchNumberInGroup");
	
	//
	BatchData = New Structure;
	BatchData.Insert("DynamicStructure", True);
	BatchData.Insert("ProductionLot", Undefined);
	BatchData.Insert("AssignmentProducts");
	BatchData.Insert("ReferenceOrder");
	BatchData.Insert("BillOfMaterials");
	BatchData.Insert("ProductionProcessType");
	BatchData.Insert("UnderRepairProduct");
	BatchData.Insert("UnderRepairVariant");
	BatchData.Insert("UnderRepairBatch");
	
	// Reading specification data
	SelectionParameters = Catalogs.BillsOfMaterials.DataSamplingParameters();
	SelectionParameters.ConsiderProbabilityOfDefectiveGoods = False;
	SelectionParameters.CalculateShareOfCostOfOutputProducts = True;
	SelectionParameters.IntermediateSemiFinishedProducts = ProductDataManagementClientServer.IntermediateSemiFinishedProductsGet();
	SelectionParameters.CombineMaterialsAndWorksPerformed = True;
	
	SpecificationsData = Catalogs.BillsOfMaterials.SpecificationDataByProductsList(
		Products_1,
		SelectionParameters,
		True,
		"NumberOfGroup,BatchNumberInGroup");
	
	// Creating parties
	ProductionLots = New ValueTable();
	ProductionLots.Columns.Add("Code", New TypeDescription("Number"));
	ProductionLots.Columns.Add("ProductionLot", New TypeDescription("CatalogRef.ProductionLots"));
	ProductionLots.Columns.Add("SpecificationDataLineIndex", New TypeDescription("Number"));
	
	For Each Attribute In Metadata.Catalogs.ProductionLots.Attributes Do
		ProductionLots.Columns.Add(Attribute.Name, Attribute.Type);
	EndDo;
	
	For Each TabularSection In Metadata.Catalogs.ProductionLots.TabularSections Do
		If TabularSection.Name = "AdditionalAttributes" Then
			Continue;
		EndIf;
		ProductionLots.Columns.Add(TabularSection.Name, New TypeDescription("ValueTable"));
	EndDo;
	
	For IndexOf = 0 To SpecificationsData.UBound() Do
		SpecificationData = SpecificationsData[IndexOf];
		Group = ManufacturedProductsGroups.Find(SpecificationData.NumberOfGroup, "NumberOfGroup");
		If Group.ReferenceOrder.IsEmpty() Then
			Continue; // The order was not carried out
		EndIf;
		
		FillPropertyValues(BatchData, Group,
			"ReferenceOrder, AssignmentProducts, UnderRepairProduct, UnderRepairVariant, UnderRepairBatch");
		FillPropertyValues(BatchData, SpecificationData,
			"BillOfMaterials, ProductionProcessType");
		
		If SpecificationData.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM Then
			SpecificationData.MainProduct.Insert("UnderRepairProduct",
				Group.UnderRepairProduct);
			SpecificationData.MainProduct.Insert("UnderRepairVariant",
				Group.UnderRepairVariant);
			SpecificationData.MainProduct.Insert("UnderRepairBatch",
				Group.UnderRepairBatch);
		EndIf;
		
		BatchFields = Documents.ProductionStage2_2.BatchFields(
			BatchData, SpecificationData.MainProduct,, SpecificationData);
		
		StringBatch = ProductionLots.Add();
		FillPropertyValues(StringBatch, BatchFields);
		StringBatch.SpecificationDataLineIndex = IndexOf;
	EndDo;
	
	If ProductionLots.Count() <> 0 Then
		
		// We form the keys of the cost accounting analyst (production batch)
		Catalogs.ProductionLots.GenerateProductionBatchesForListOfStages(ProductionLots);

		// Caching the place of the batch in the order structure
		LocationOfLaunchedLotAndStagesInOrderStructure = InformationRegisters.LocationOfLaunchedLotAndStagesInOrderStructure.CreateRecordSet().UnloadColumns();
		For IndexOf = -ProductionLots.Count()+1 To 0 Do
			StringBatch = ProductionLots[-IndexOf];
			If StringBatch.ProductionLot.IsEmpty() Then
				SpecificationsData.Delete(StringBatch.SpecificationDataLineIndex);
			Else
				SpecificationData = SpecificationsData[StringBatch.SpecificationDataLineIndex];
				SpecificationData.Insert("ProductionLot", StringBatch.ProductionLot);

				NewRow = LocationOfLaunchedLotAndStagesInOrderStructure.Add();
				NewRow.Lot = StringBatch.ProductionLot;
				NewRow.ProductItemsGroup = OrderStructure.ProductGroupChecksum(StringBatch,
					"BillOfMaterials", "Document");
				
				FillPropertyValues(StructureOfSearchParty, SpecificationData, "NumberOfGroup, BatchNumberInGroup");
				FoundRows = Products_1.FindRows(StructureOfSearchParty);
				TotalRows = FoundRows.Count();
				If TotalRows > 0 Then
					NewRow.Level = FoundRows[0].Level;
					NewRow.DurationBeforeProductionIssue = FoundRows[0].DurationBeforeProductionIssue;
					NewRow.ProductionLotIDInProductGroup = FoundRows[0].ProductionLotIDInProductGroup;
					For IndexOfProduct = 1 To TotalRows-1 Do
						FoundRow = FoundRows[IndexOfProduct];
						NewRow.Level = Max(NewRow.Level, FoundRow.Level);
						NewRow.DurationBeforeProductionIssue = Max(NewRow.DurationBeforeProductionIssue, FoundRow.DurationBeforeProductionIssue);
						NewRow.ProductionLotIDInProductGroup = Max(NewRow.ProductionLotIDInProductGroup, FoundRow.ProductionLotIDInProductGroup);
					EndDo;
				EndIf;
			EndIf;
		
		EndDo;
		InformationRegisters.LocationOfLaunchedLotAndStagesInOrderStructure.RecordNewLotReferences(LocationOfLaunchedLotAndStagesInOrderStructure);
		
	EndIf;
	
	//
	LinksHeld = New Array;
	
	TasksForCalculatingSchedule = PartyKeys.Copy(, "ProductionOrder, KeyLot");
	TasksForCalculatingSchedule.GroupBy("ProductionOrder, KeyLot");
	TasksForCalculatingSchedule.Columns.Add("Queue", New TypeDescription("Number", New NumberQualifiers()));
	TasksForCalculatingSchedule.Indexes.Add("KeyLot");
	
	StepsToTransferSchedule = Undefined; // Transferring schedule dates to generated documents
	StepsToTransferOrder = Undefined; // Pernos of the order of placement in the generated documents (only for the R&M)
	StepsToTransferLinks = Undefined; // Substitution of links to generated documents (Attributes to be planned earlier, only for R&M)
	If TheProductionScheduleIsUsed Then
		StepsToTransferSchedule = New ValueTable;
		StepsToTransferSchedule.Columns.Add("ProductionOrder", New TypeDescription("DocumentRef.ProductionOrder2_2"));
		StepsToTransferSchedule.Columns.Add("LotReferenceKeyIsOld", New TypeDescription("UUID"));
		StepsToTransferSchedule.Columns.Add("LotReferenceKeyIsNew", New TypeDescription("UUID"));
		StepsToTransferSchedule.Columns.Add("Ref", New TypeDescription("DocumentRef.ProductionStage2_2"));
		StepsToTransferSchedule.Columns.Add("Stage", New TypeDescription("CatalogRef.ProductionStages"));
		
		StepsToTransferOrder = StepsToTransferSchedule.Copy();
		StepsToTransferLinks = StepsToTransferSchedule.Copy();
	EndIf;
	
	HeaderAttributes = ProductionManagementServerCall.AttributesOfNewStageOfProduction();
	LinesOfBusiness = Catalogs.Assignments.AreasOfActivityOfAppointments(
		ManufacturedProductsGroups.UnloadColumn("AssignmentProducts"));
	
	For Each SpecificationData In SpecificationsData Do
		Group = ManufacturedProductsGroups.Find(SpecificationData.NumberOfGroup, "NumberOfGroup");
		If Group.ReferenceOrder.IsEmpty() Then
			Continue; // The order was not carried out
		EndIf;
		
		FillPropertyValues(StructureOfSearchParty, SpecificationData, "NumberOfGroup, BatchNumberInGroup");
		PartyItems = Products_1.Copy(StructureOfSearchParty);
		If PartyItems.Count() = 0 Then
			Continue;
		EndIf;
		
		Product = PartyItems[0];
		LotReferenceKeyIsNew = SpecificationData.ProductionLot.UUID();
		ThisIsRepair = SpecificationData.ProductionProcessType
			= Enums.ProductionProcessTypes.PerformRM;
		
		Reschedule = TheProductionScheduleIsUsed
			And PartyItems.Count() = 1
			And Product.QuantityOfBatches = 1
			And Product.Count = Product.QuantityStandard
			And BegOfDay(Product.StartDate2) = BegOfDay(Product.LaunchDateStandard)
			And ValueIsFilled(Product.KeyLot);
		
		// Tasks for calculating the schedule
		If Reschedule Then
			SearchStructureKeyLotReference.KeyLot = Product.KeyLot;
			FoundRows = TasksForCalculatingSchedule.FindRows(SearchStructureKeyLotReference);
			If FoundRows.Count() <> 0 Then
				TasksForCalculatingSchedule.Delete(FoundRows[0]);
			EndIf;
		Else
			NewRow = TasksForCalculatingSchedule.Add();
			NewRow.ProductionOrder = Group.ReferenceOrder;
			NewRow.KeyLot = LotReferenceKeyIsNew;
		EndIf;
		
		// Link to the Lot reference
		NewRow = ResultOfFormation.Add();
		NewRow.Lot = SpecificationData.ProductionLot;
		CreatedObjects.Add(SpecificationData.ProductionLot);
		
		// Scheduled date of shipment and production
		SpecificationData.Stages.Columns.Add("DateOfShipment", New TypeDescription("Date",,, New DateQualifiers));
		SpecificationData.Stages.Columns.Add("NotShipInInstallments", New TypeDescription("Boolean"));
		SpecificationData.Stages.Columns.Add("PlanNotEarlierThan", 
			New TypeDescription("DocumentRef.ProductionStage2_2, Date",,, New DateQualifiers));
		SpecificationData.Stages.FillValues(True, "NotShipInInstallments");
		SpecificationData.Stages.FillValues(Group.EarliestStartDate, "DateOfShipment");
		
		SpecificationData.Stages.Columns.Add("ProductionDate", New TypeDescription("Date",,, New DateQualifiers));
		SpecificationData.Stages.Columns.Add("ProductionInOneDay", New TypeDescription("Boolean"));
		SpecificationData.Stages.FillValues(True, "ProductionInOneDay");
		
		If Not TheProductionScheduleIsUsed Then
			SpecificationData.Stages.FillValues(Group.DemandDate, "ProductionDate"); // Desired release date
		EndIf;
		
		// Inheritance of Finished products Attributes
		If SpecificationData.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly Then
			If SpecificationData.IncomingProducts.Count() <> 0
				And SpecificationData.IncomingProducts[0].Products = Product.Products Then
				SpecificationData.IncomingProducts[0].Warehouse = Product.Warehouse;
				SpecificationData.IncomingProducts[0].WithAssignment = Not Product.Purpose.IsEmpty();
			EndIf;
		Else
			FillInProductSpecificationsForProductsForLaunch(SpecificationData, PartyItems);
		EndIf;
		
		// The object is an imitation of the party
		FillPropertyValues(BatchData, Group,
			"ReferenceOrder, AssignmentProducts, UnderRepairProduct, UnderRepairVariant, UnderRepairBatch");
		FillPropertyValues(BatchData, SpecificationData,
			"BillOfMaterials, ProductionProcessType");
		
		// The purpose of the materials
		If Group.MultipleAppointments Then
			SpecificationData.Insert("AssignmentsOfMaterials", 
				AssignmentsOfMaterials.Copy(StructureOfSearchParty, "Purpose, ZoomRatio"));
		EndIf;
		
		// Addition of specification data
		Documents.ProductionStage2_2.PrepareTheseSpecificationsForCreatingStages(SpecificationData, BatchData);
		
		// Status of stages
		SpecificationData.Stages.Columns.Add(
			"Status", New TypeDescription("EnumRef.StatusesOfProductionStages2_2"));
		
		If SubmitEverythingForExecution Then
			SpecificationData.Stages.FillValues(Enums.StatusesOfProductionStages2_2.ForCompletion, "Status");
		Else
			For Each Stage In SpecificationData.Stages Do
				If PassFirstOnesToExecution And Stage.StageNumber = 1 Then
					Stage.Status = Enums.StatusesOfProductionStages2_2.ForCompletion;
				Else
					Stage.Status = Enums.StatusesOfProductionStages2_2.Generated1;
				EndIf;
			EndDo;
		EndIf;
		
		// Clearing the message stack
		For Each Message In GetUserMessages(True) Do
			Messages.Add(Message);
		EndDo;
		
		// Preparing header Attributes
		FillPropertyValues(HeaderAttributes, Group,
			"ReferenceOrder, Organization, BusinessOperation, AssignmentProducts, LineOfBusiness, Partner, Contract");
		FillPropertyValues(HeaderAttributes, SpecificationData,
			"ProductionLot, ProductionProcessType, BillOfMaterials, ResponsibleBusinessUnit");
		If ValueIsFilled(Group.AssignmentProducts) Then
			HeaderAttributes.LineOfBusiness = LinesOfBusiness[Group.AssignmentProducts];
		EndIf;
		HeaderAttributes.ProductionIssueForActivity = Group.OrderForActivity;
		HeaderAttributes.DynamicStructure = True;
		
		// Creating stages
		For IndexOf = 0 To SpecificationData.Stages.Count()-1 Do
			
			Data_Stage = SpecificationData.Stages[IndexOf];
			
			If Data_Stage.StageNumber = 1
				And TheProductionScheduleIsUsed Then
				Data_Stage.PlanNotEarlierThan = PartyItems[0].StartDate2;
			EndIf;
			
			FillingData = New Structure;
			FillingData.Insert("HeaderAttributes", HeaderAttributes);
			FillingData.Insert("SpecificationData", SpecificationData);
			FillingData.Insert("Data_Stage", Data_Stage);
			
			DocumentObject = Documents.ProductionStage2_2.CreateDocument();
			DocumentObject.SetNewObjectRef(Data_Stage.ProductionStage);
			DocumentObject.SetBatchGenerationMode();
			DocumentObject.Fill(FillingData);
			
			// Refusal to check filling in additional Attributes
			SessionParameters.PropertiesFillingInteractiveCheck = True;
			
			If Not DocumentObject.CheckFilling() Then
				DocumentObject.Status = Enums.StatusesOfProductionStages2_2.BeingGenerated;
			EndIf;
			
			While True Do
				
				Try
					DocumentObject.Write(DocumentWriteMode.Posting);
					LinksHeld.Add(DocumentObject.Ref);
				Except
					
					If DocumentObject.Status <> Enums.StatusesOfProductionStages2_2.BeingGenerated Then
						DocumentObject.Status = Enums.StatusesOfProductionStages2_2.BeingGenerated;
						Continue;
					EndIf;
					
					DocumentObject.Write(DocumentWriteMode.Write);
					
				EndTry;
				
				Break;
			
			EndDo;
			
			NewRow = ResultOfFormation.Add();
			NewRow.Lot = SpecificationData.ProductionLot;
			NewRow.Document = DocumentObject.Ref;
			CreatedObjects.Add(DocumentObject.Ref);
			
			If Reschedule Then
				NewRow = StepsToTransferSchedule.Add();
				NewRow.ProductionOrder = DocumentObject.ReferenceOrder;
				NewRow.LotReferenceKeyIsOld = PartyItems[0].KeyLot;
				NewRow.LotReferenceKeyIsNew = LotReferenceKeyIsNew;
				NewRow.Ref = DocumentObject.Ref;
				NewRow.Stage = DocumentObject.Stage;
			EndIf;
			
			If ThisIsRepair And TheProductionScheduleIsUsed Then
				If Not Reschedule Then
					NewRow = StepsToTransferOrder.Add();
					NewRow.ProductionOrder = DocumentObject.ReferenceOrder;
					NewRow.LotReferenceKeyIsOld = PartyItems[0].KeyLot;
					NewRow.LotReferenceKeyIsNew = LotReferenceKeyIsNew;
					NewRow.Ref = DocumentObject.Ref;
					NewRow.Stage = DocumentObject.Stage;
				EndIf;
				NewRow = StepsToTransferLinks.Add();
				NewRow.ProductionOrder = DocumentObject.ReferenceOrder;
				NewRow.LotReferenceKeyIsOld = PartyItems[0].KeyLot;
				NewRow.LotReferenceKeyIsNew = LotReferenceKeyIsNew;
				NewRow.Ref = DocumentObject.Ref;
				NewRow.Stage = DocumentObject.Stage;
			EndIf;
			
			For Each Message In GetUserMessages(True) Do
				Message.DataKey = DocumentObject.Ref;
				Messages.Add(Message);
			EndDo;
			
		EndDo;
		
		// Fixing the result
		PutToTempStorage(Result, StorageAddress);
	EndDo;
	
	// Graph inheritance
	If ValueIsFilled(StepsToTransferSchedule) Then
		OrderStructureProductionSchedule.RescheduleLotReferencesAtStartup(StepsToTransferSchedule);
	EndIf;
	If ValueIsFilled(StepsToTransferOrder) Then
		OrderStructureProductionSchedule.MoveBatchOrderAtStartup(StepsToTransferOrder);
	EndIf;
	If ValueIsFilled(StepsToTransferLinks) Then
		OrderStructureProductionSchedule.ReplaceReferencesToStagesAtStartup(StepsToTransferLinks);
	EndIf;
	
	// Clearing the message stack
	For Each Message In GetUserMessages(True) Do
		Messages.Add(Message);
	EndDo;
	
	// Writing To Registers
	If LinksHeld.UBound() <> -1 Then
		References = TMCommonUse.UniqueValuesFromTableColumn(ManufacturedProductsGroups, "ReferenceOrder");
		Queue = Constants.CurrentBorderOfOrderStructureCalculationTasks.Current();
		
		// Filling in the provision and forming movements 
		GenerationParameters = Documents.ProductionStage2_2.StageGenerationSettings();
		FillPropertyValues(GenerationParameters, Parameters, "ReserveMaterials, ReplaceMaterialsWithAnalogs");
		GenerationParameters.References = References;
		Documents.ProductionStage2_2.FillInFormAndReflectRegisteredRecordsByStages(
			GenerationParameters, LinksHeld, New TempTablesManager, Queue);
		
		// Filling in related registers
		If GetFunctionalOption("UseOperationManagement")
				Or GetFunctionalOption("UseManufacturingExecutionSystem") Then
			StepsForCalculatingTaskQueue = Documents.ProductionStage2_2.ItIsRequiredToCalculateQueueOfOperations(LinksHeld);
			If StepsForCalculatingTaskQueue.Count() > 0 Then
				TaskDataTable = 
					InformationRegisters.JobsForCalculatingProductionOperationQueue.InitializeTaskDataTable();
				For Each StageForCalculation In StepsForCalculatingTaskQueue Do
					NewRow = TaskDataTable.Add();
					NewRow.ObjectOfARAP = StageForCalculation;
				EndDo;
				InformationRegisters.JobsForCalculatingProductionOperationQueue.AddTasks(TaskDataTable);
			EndIf;
		EndIf;
		
		RegistersToBeReflected = DocumentsStates.RegistersToReflectStateOfOrders();
		RegistersToBeReflected.ProductionStageStates = True;
		
		DocumentsStates.AddTasksToStateOfOrders(
			Undefined,
			LinksHeld,
			"ACTION_FEFLECT_STAGES_STATE",
			RegistersToBeReflected);
		
		RegistersToBeReflected = DocumentsStates.RegistersToReflectStateOfOrders();
		RegistersToBeReflected.StatesOfProductionOrders = True;
		
		DocumentsStates.AddTasksToStateOfOrders(
			Undefined,
			References,,
			RegistersToBeReflected);
		
		If TasksForCalculatingSchedule.Count() > 0 Then
			TasksForCalculatingSchedule.FillValues(Queue, "Queue");
			InformationRegisters.OrderStructureCalculationJobsProductionSchedule.AddTasks(TasksForCalculatingSchedule);
		EndIf;
	EndIf;
	
	// Clearing the message stack
	For Each Message In GetUserMessages(True) Do
		Messages.Add(Message);
	EndDo;
	
	// Fixing the result
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

Procedure FillInProductSpecificationsForProductsForLaunch(SpecificationData, Products_1)
	
	TypesOfArticles = New Array;
	TypesOfArticles.Add(Type("ChartOfCharacteristicTypesRef.ExpenseItems"));
	TypesOfArticles.Add(Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems"));
	FromExpenseItem = New TypeDescription(TypesOfArticles);
	
	RecipientsTypes = New Array;
	RecipientsTypes.Add(Type("CatalogRef.BusinessStructure"));
	RecipientsTypes.Add(Type("CatalogRef.Warehouses"));
	FromRecipient = New TypeDescription(RecipientsTypes);
	
	For Cnt = 1 To 2 Do
		
		Table = SpecificationData[?(Cnt = 1, "ManufacturedProducts", "RecyclableWaste")]; // ValueTable
		Table.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
		Table.Columns.Add("Allocated", New TypeDescription("Number", New NumberQualifiers));
		Table.Columns.Add("ToExpenseAs", New TypeDescription("Boolean"));
		Table.Columns.Add("ExpenseItem", FromExpenseItem);
		Table.Columns.Add("DimensionOfExpenses", Metadata.ChartsOfCharacteristicTypes.ExpenseItems.Type);
		Table.Columns.Add("AssetsLiabilitiesDimension",
			Metadata.ChartsOfCharacteristicTypes.AssetLiabilityItems.Type);
		
		Table.Columns.Add("Recipient", FromRecipient);
		Table.LoadColumn(Table.UnloadColumn("Warehouse"), "Recipient");
		
	EndDo;
	
	ColumnsNames = StrSplit(
		"Characteristic,Purpose,ToExpenseAs,ExpenseItem,DimensionOfExpenses,AssetsLiabilitiesDimension", ",");
	
	IndexOfProduct = 0;
	While IndexOfProduct < Products_1.Count() Do
		
		Product = Products_1[IndexOfProduct];
		IndexOfProduct = IndexOfProduct + 1;
		
		For Cnt = 1 To 2 Do
			
			IndexOf = 0;
			While IndexOf < SpecificationData[?(Cnt = 1, "ManufacturedProducts", "RecyclableWaste")].Count() Do
				
				String = SpecificationData[?(Cnt = 1, "ManufacturedProducts", "RecyclableWaste")][IndexOf];
				IndexOf = IndexOf + 1;
				
				If String.Allocated = String.Count
					Or String.Products <> Product.Products
					Or String.Characteristic <> Product.Characteristic
						And ValueIsFilled(String.Characteristic)
						And Not String.AnyCharacteristic Then
					Continue;
				EndIf;
				
				Allocated = Min(String.Count-String.Allocated, Product.Count);
				
				If String.Allocated = 0
						And Product.Count >= String.Count
					Or LinesAreIdentical(String, Product, ColumnsNames)
						And (String.Recipient = Product.Recipient
							Or String.Allocated = 0 And Not ValueIsFilled(String.Recipient)) Then
					
					// There is no need to split the string
					FillLine = String;
					
				ElsIf String.RoundOff
					And Not String.ThisIsWorkshopPantry
					And Round(String.Count - Allocated) <> (String.Count - Allocated) Then
					
					// Rounding rules will be violated when dividing the line
					If String.Allocated = 0 Then
						String.RoundOff = False;
						FillLine = String;
					Else
						OwnerOfString = String.Owner(); // ValueTable
						NewRow = OwnerOfString.Insert(IndexOf-1);
						FillPropertyValues(NewRow, String);
						NewRow.Count = String.Count - String.Allocated;
						NewRow.NumberOfPackages = NewRow.Count
							* NewRow.PackageData.Denominator / NewRow.PackageData.Numerator;
						NewRow.Allocated = 0;
						NewRow.RoundOff = False;
						FillLine = NewRow;
						
						String.Count = String.Allocated;
						String.NumberOfPackages = String.Count
							* String.PackageData.Denominator / String.PackageData.Numerator;
						If Cnt = 1 Then
							ProductionClientServer.RecalculateFractionOfCostWhenSplittingRow(
								NewRow, String, SpecificationData.MethodOfAllocatingFinishedProductCosts);
						EndIf;
						
						IndexOf = IndexOf + 1;
					EndIf;
					
				Else
					
					// Splitting the string
					OwnerOfString = String.Owner(); // ValueTable
					NewRow = OwnerOfString.Insert(IndexOf-1);
					FillPropertyValues(NewRow, String);
					NewRow.Count = Allocated;
					NewRow.NumberOfPackages = NewRow.Count
						* NewRow.PackageData.Denominator / NewRow.PackageData.Numerator;
					NewRow.Allocated = 0;
					FillLine = NewRow;
					
					String.Count = String.Count - Allocated;
					String.NumberOfPackages = String.Count
						* String.PackageData.Denominator / String.PackageData.Numerator;
					If Cnt = 1 Then
						ProductionClientServer.RecalculateFractionOfCostWhenSplittingRow(
							NewRow, String, SpecificationData.MethodOfAllocatingFinishedProductCosts);
					EndIf;
					
					IndexOf = IndexOf + 1;
					
				EndIf;
				
				FillPropertyValues(FillLine, Product,
					"Characteristic,Recipient,Purpose,ToExpenseAs,ExpenseItem,DimensionOfExpenses,AssetsLiabilitiesDimension");
				FillLine.Allocated = FillLine.Allocated + Allocated;
				
				Product.Count = Product.Count - Allocated;
				If Product.Count = 0 Then
					Break;
				EndIf;
				
			EndDo;
			If Product.Count = 0 Then
				Break;
			EndIf;
		EndDo;
		
	EndDo;
	
EndProcedure

Function LinesAreIdentical(String1, String2, ColumnsNames)
	
	For Each Column In ColumnsNames Do
		If String1[Column] <> String2[Column]
			And (ValueIsFilled(String1[Column])
				Or ValueIsFilled(String2[Column])) Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

Procedure AddError(Errors, Group, Products_1, ExceptionText = "")
	
	Product = Products_1.Find(Group.NumberOfGroup, "NumberOfGroup");
	
	NewRow = Errors.Add();
	FillPropertyValues(NewRow, Group, "BillOfMaterials, LineOfBusiness");
	FillPropertyValues(NewRow, Product, "Products, Characteristic");
	
	Messages = GetUserMessages(True);
	If Messages.UBound() = -1 And Not IsBlankString(ExceptionText) Then
		Message = New UserMessage();
		Message.Text = ExceptionText;
		Messages = CommonClientServer.ValueInArray(Message);
	EndIf;
	NewRow.Messages = Messages;
	
EndProcedure

#EndRegion
