
#Region Public

// Performs product and semi-finished product
//  partitioning and gets the specified set of resource specification data for each element in the product structure. In the process of processing
//  , the consolidation of batches of products and semi-finished products is also performed.
//
// Parameters:
//  Products_1	              - ValueTable - a table with the item that you want to get the production structure for.
//	NodulationParameters - See ProductDecomposition.NodulationParameters.
//  SelectionParameters      - Structure - resource specification data selection parameters
//		See Catalogs.BillsOfMaterials.DataSamplingParameters.
// 
// Returns:
//  Structure - structure with elements:
//  	* SpecificationsData - Array, Undefined - array elements are structures that contain data from resource specifications.
//  	* HasError - Boolean - True if an error occurred during the node mapping (in this case, the specification Data is set to Undefined).
//  	* ErrorText - String - description of the error that occurred.
//  	* LinkError - CatalogRef, DocumentRef - a reference to the object that the error is associated with.
//
Function Explosion(Products_1, NodulationParameters, SelectionParameters) Export
	
	Result = New Structure;
	Result.Insert("SpecificationsData", Undefined);
	Result.Insert("HasError",         False);
	Result.Insert("ErrorText",        "");
	Result.Insert("LinkError",       Undefined);
	
	Demands = UnloadIncomingItemsForProcessing(Products_1);
	SelectionParameters.ListOfData = Catalogs.BillsOfMaterials.ListOfSpecificationData();
	UnravelNeedsRecursively(Demands, Demands, NodulationParameters, SelectionParameters);
	
	ErrorDescription = New Structure("HasError, ErrorText, LinkError", False, "", Undefined);
	CheckCorrectnessOfSpecifications(Demands.UnloadColumn("BillOfMaterials"), ErrorDescription);
	
	If Not ErrorDescription.HasError Then
		FillDeadlinesForEnsuringBedRest(Demands);
		If NodulationParameters.GroupData_ Then
			CollapseNeeds(Demands, NodulationParameters, SelectionParameters);
		EndIf;
		Result.SpecificationsData = DivideNeedsIntoBatches(Demands, NodulationParameters);
		
	Else
		FillPropertyValues(Result, ErrorDescription);
	EndIf;
	
	Return Result;
	
EndFunction

// The constructor function of a structure that defines the parameters of the explosion products.
//
// Returns:
//  Structure - structure of parameters.
Function NodulationParameters() Export
	
	Result = New Structure;
	
	// Divide the result of the splitting into wholesale batches or return it in one batch.
	Result.Insert("DivideIntoOptimalBatches", True);
	
	// The Group Data parameter determines the need to combine (consolidate) 
	// data related to the same specification. In addition to the specification, you can specify
	// an arbitrary set of fields in the context of which the union - Grouping fields will be performed.
	// As a value, specify the column names of the product table without spaces separated by commas.
	// The grouping fields will also be transferred to the result of the splitting.
	Result.Insert("GroupData_", False);
	Result.Insert("GroupFields", "");
	
	// The parameter contains the names of the columns of the table of products that need to be "stretched" through the entire
	// structure of products, inheriting their values from the parent to its descendants. The values of the fields are transferred
	// to the result of the splitting. When grouping, additional information is inherited from one of the products
	// selected in an arbitrary way.
	Result.Insert("AdditionalInformation", "");
	
	// If the reserve parameter of the warehouse has the value True,
	// then according to the PF produced in the process, an attempt is first made to make a reserve in the
	// warehouse / in the schedule, and further disassembly is performed on the missing part.
	// If it is also necessary to analyze isolated balances during the reserve, then
	// the product table should contain a column with the appropriate purpose, and the column name
	// should be passed through the Reserve parameter by the field value. To reserve
	// exclusively isolated balances, the Reserve parameter is used only separately.
	Result.Insert("ReservePFFromWarehouse", False);
	Result.Insert("ReservePFFieldNamePurpose", "");
	Result.Insert("ReservePFOnlySeparately", False);
	
	// Flag of the need to replace PF in the process with analogs. Replacement occurs only if
	// the Balance of the analogue is available in stock. Therefore, this parameter can accept the Truth only
	// together with the Reservpfsosclad parameter.
	Result.Insert("ReplacePFNaAnalogues", False);
	Return Result;
	
EndFunction

// Function-defines the grouping fields for the item layout
//
// Parameters:
//  Fields - String - list of fields required by the user of the node interface
//
// Returns:
//  String - list of fields supplemented with required fields
Function GroupFields(Fields = "") Export
	
	Result = New Array;
	
	If Not IsBlankString(Fields) Then
		Result.Add(Fields);
	EndIf;
	
	For Each ParameterName In StrSplit("LineOfBusiness,ProductionDispatcherBusinessUnit", ",") Do
		If ProductDataManagementCached.TypeOfDestinationParameterIsUsed(
				Enums.TypesOfBOMAssignmentParameters[ParameterName]) Then
			Result.Add(ParameterName);
		EndIf;
	EndDo;
	
	Return StrConcat(Result, ",");
	
EndFunction

#EndRegion

#Region Private

// Returns:
// 	ValueTable:
// * Id - Number -
// * SpecificationData - Structure -
// * Inputs - See NewCommunicationNeeds
// * Outputs - See NewCommunicationNeeds
// * CollapsedIncomingNeeds - Array -
// * Supply - See NewDemandAssurance
// * Substitutes - See NewAnaloguesNeed
// * PlanNotEarlierThan - CatalogRef.ProductionStages -
// * ThisIsDisassembly - Boolean -
// * ThisIsRepair - Boolean -
// * ThisIsIncomingNeed - Boolean -
// * ThisIsPushingScheme - Boolean -
// * Begin - Date -
// * Ending - Date -
// * DateOfPFProvision - Date -
// * MaximumQueuePeriod - Number -
// * PeriodOfProductQueue - Date -
// * ReleaseParty - Structure -
// * DaysFromDemand - Number -
// * ProductionDispatcherBusinessUnit - CatalogRef.BusinessStructure -
// * LineOfBusiness - CatalogRef.LinesOfBusiness -
// * ToExpenseAs - Boolean -
// * ExpenseItem - ChartOfCharacteristicTypesRef.ExpenseItems, ChartOfCharacteristicTypesRef.AssetLiabilityItems -
// * DimensionOfExpenses - Characteristic.ExpenseItems
// * AssetsLiabilitiesDimension - Characteristic.AssetLiabilityItems
// * ReceivingBusinessUnit - CatalogRef.Warehouses, CatalogRef.BusinessStructure -
// * ProductionStart - Date -
// * Parent - ValueTableRow -
// * Collapsed_ - Boolean -
// * Processed1 - Boolean -
// * Sender - CatalogRef.Warehouses - 
// * Recipient - CatalogRef.Warehouses -
Function UnloadIncomingItemsForProcessing(Products_1)
	
	Demands = Products_1.Copy();
	
	Demands.Columns.Add("Id", New TypeDescription("Number", New NumberQualifiers));
	Demands.Columns.Add("SpecificationData", New TypeDescription("Structure"));
	
	Demands.Columns.Add("Inputs", New TypeDescription("ValueTable"));
	Demands.Columns.Add("Outputs", New TypeDescription("ValueTable"));
	Demands.Columns.Add("CollapsedIncomingNeeds", New TypeDescription("Array"));
	Demands.Columns.Add("Supply", New TypeDescription("ValueTable"));
	Demands.Columns.Add("Substitutes", New TypeDescription("ValueTable"));
	Demands.Columns.Add("PlanNotEarlierThan", New TypeDescription("CatalogRef.ProductionStages"));
	
	Demands.Columns.Add("ThisIsDisassembly", New TypeDescription("Boolean"));
	Demands.Columns.Add("ThisIsRepair", New TypeDescription("Boolean"));
	Demands.Columns.Add("ThisIsIncomingNeed", New TypeDescription("Boolean"));
	Demands.Columns.Add("ThisIsPushingScheme", New TypeDescription("Boolean"));
	
	Demands.Columns.Add("Begin", New TypeDescription("Date",,, New DateQualifiers));
	Demands.Columns.Add("Ending", New TypeDescription("Date",,, New DateQualifiers));
	
	Demands.Columns.Add("MaximumQueuePeriod", New TypeDescription("Number"));
	Demands.Columns.Add("PeriodOfProductQueue", New TypeDescription("Date"));
	
	Demands.Columns.Add("ReleaseParty", New TypeDescription("Structure"));
	Demands.Columns.Add("DaysFromDemand", New TypeDescription("Number", New NumberQualifiers));
	
	If Demands.Columns.Find("ProductionDispatcherBusinessUnit") = Undefined Then
		Demands.Columns.Add("ProductionDispatcherBusinessUnit",
			New TypeDescription("CatalogRef.BusinessStructure"));
	EndIf;
		
	If Demands.Columns.Find("LineOfBusiness") = Undefined Then
		Demands.Columns.Add("LineOfBusiness",
			New TypeDescription("CatalogRef.LinesOfBusiness"));
	EndIf;
		
	If Demands.Columns.Find("ToExpenseAs") = Undefined Then
		
		TypesOfArticles = New Array;
		TypesOfArticles.Add(Type("ChartOfCharacteristicTypesRef.ExpenseItems"));
		TypesOfArticles.Add(Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems"));
		
		Demands.Columns.Add("ToExpenseAs"         , New TypeDescription("Boolean"));
		Demands.Columns.Add("ExpenseItem"           , New TypeDescription(TypesOfArticles));
		Demands.Columns.Add("DimensionOfExpenses"        , Metadata.ChartsOfCharacteristicTypes.ExpenseItems.Type);
		Demands.Columns.Add("AssetsLiabilitiesDimension" , Metadata.ChartsOfCharacteristicTypes.AssetLiabilityItems.Type);
		
	EndIf;
	
	RecipientTypes = New Array;
	RecipientTypes.Add(Type("CatalogRef.BusinessStructure"));
	RecipientTypes.Add(Type("CatalogRef.Warehouses"));
	Demands.Columns.Add("ReceivingBusinessUnit", New TypeDescription(RecipientTypes));
	Demands.Columns.Add("ProductionStart", New TypeDescription("Date"));
	
	// Service fields
	Demands.Columns.Add("Parent", New TypeDescription("Null, ValueTableRow"));
	Demands.Columns.Add("Level", New TypeDescription("Number"));
	Demands.Columns.Add("Collapsed_", New TypeDescription("Boolean"));
	Demands.Columns.Add("Processed1", New TypeDescription("Boolean"));
	Demands.Columns.Add("Order", New TypeDescription("Number"));
	Demands.Columns.Add("DescendantsAreCollapsed", New TypeDescription("Boolean"));
	
	Id = 1;
	
	For Each String In Demands Do
		
		String.Id = Id;
		String.ThisIsIncomingNeed = True;
		String.Inputs = NewCommunicationNeeds();
		String.Outputs = NewCommunicationNeeds();
		String.Supply = NewDemandAssurance();
		String.ProductionStart = String.StartDate2;
		String.Order = String.LineNumber;
		String.Substitutes = NewAnaloguesNeed();
		Id = Id + 1;
		
	EndDo;
	
	Return Demands;
	
EndFunction

// Parameters:
// 	Demands - See UnloadIncomingItemsForProcessing
// 	StringsToProcess - See UnloadIncomingItemsForProcessing
// 	NodulationParameters - See NodulationParameters
// 	SelectionParameters - See Catalogs.BillsOfMaterials.DataSamplingParameters
// 	Id - Number - ID of the current line
// 	PFReserves - See NewReservesOfSemiFinishedProducts
//
Procedure UnravelNeedsRecursively(Demands, StringsToProcess, NodulationParameters, SelectionParameters, Id = Undefined, PFReserves = Undefined)
	
	SpecificationsData = Catalogs.BillsOfMaterials.SpecificationData(
		?(TypeOf(StringsToProcess) = Type("Array"), Demands.Copy(StringsToProcess), StringsToProcess),
		SelectionParameters);
	
	If NodulationParameters.ReservePFFromWarehouse Then
		ReplacePFNaAnalogues = False;
		ReplacePFNaAnalogues = NodulationParameters.ReplacePFNaAnalogues;
		PFSelectionQueue = NewWayToSelectSemiFinishedProducts(ReplacePFNaAnalogues);
		
		If PFReserves = Undefined Then
			PFReserves = NewReservesOfSemiFinishedProducts();
		EndIf;
	Else
		PFSelectionQueue = Undefined;
	EndIf;
	
	Id = ?(Id = Undefined, Demands.Count(), Id);
	NodalQueue = New Array;
	
	For IndexOf = 0 To StringsToProcess.Count()-1 Do
		
		Demand = StringsToProcess[IndexOf];
		SpecificationData = SpecificationsData[Demand.Id]; // See Catalogs.BillsOfMaterials.DataSpecificationConstructor
		
		ItemData_3 = Catalogs.BillsOfMaterials.ProductData_5();
		FillPropertyValues(ItemData_3, Demand);
		ReleaseParty = Catalogs.BillsOfMaterials.CalculateBatchOfOutputByProduct(
			ItemData_3, SpecificationData, SelectionParameters);
		
		CalculateQuantityPerBatchRelease(
			NodulationParameters, ReleaseParty, SpecificationData, ItemData_3);
		
		// The fields are filled in when calculating the regulatory schedule
		SpecificationData.Stages.Columns.Add("StageCode", 
			New TypeDescription("Number", New NumberQualifiers));
		SpecificationData.Stages.Columns.Add("DateOfShipment",
			New TypeDescription("Date",,, New DateQualifiers));
		SpecificationData.Stages.Columns.Add("NotShipInInstallments", New TypeDescription("Boolean"));
		SpecificationData.Stages.Columns.Add("ReadyForFulfillment", New TypeDescription("Boolean"));
		
		Demand.SpecificationData = SpecificationData;
		Demand.ReleaseParty = ReleaseParty;
		Demand.MaximumQueuePeriod = SpecificationData.MaximumPeriodOfLyingInDays * 86400;
		Demand.ThisIsDisassembly =
			SpecificationData.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly;
		Demand.ThisIsRepair = 
			SpecificationData.ProductionProcessType = Enums.ProductionProcessTypes.Repair;
		Demand.ThisIsPushingScheme = Demand.ThisIsDisassembly 
			Or (Demand.ThisIsRepair And Not Demand.ThisIsIncomingNeed);
		
		#Region AddingLinks
		For Each Enter In Demand.Inputs Do
			If SpecificationData.IncomingProducts.Count() = 1 Then
				
				String = SpecificationData.IncomingProducts[0];
				String.WithAssignment = True;
				String.Produced = True;
				
				Enter.RsString = String;
				Enter.RsStringOwnerName = "IncomingProducts";
				
				If ValueIsFilled(Enter.Link) Then
					Enter.Link.CommunicationStage = String.Stage;
				Else
					// There may not be a one-to-one relationship if the repaired product is entered in several lines
					SVNeed = Demands.Find(Enter.LinkID_, "Id");
					For Each Output_ In SVNeed.Outputs.FindRows(
							New Structure("LinkID_", Demand.Id)) Do
						Output_.CommunicationStage = String.Stage;
					EndDo;
				EndIf;
				
			Else
				
				If ValueIsFilled(Enter.Link) Then
					Enter.Link.Owner().Delete(Enter.Link);
				Else
					// There may not be a one-to-one relationship if the repaired product is entered in several lines
					SVNeed = Demands.Find(Enter.LinkID_, "Id");
					For Each Output_ In SVNeed.Outputs.FindRows(
							New Structure("LinkID_", Demand.Id)) Do
						SVNeed.Outputs.Delete(Output_);
					EndDo;
				EndIf;
				Demand.Inputs.Delete(Enter);
				
			EndIf;
		EndDo;
		For Each Output_ In Demand.Outputs Do
			FoundRows = SpecificationData.ManufacturedProducts.FindRows(
				New Structure("Products, Characteristic",
					Output_.Link.RsString.Products, Output_.Link.RsString.Characteristic));
			If FoundRows.Count() = 1 Then
				Output_.RsString = FoundRows[0];
				Output_.RsStringOwnerName = "ManufacturedProducts";
				Output_.Link.CommunicationStage = FoundRows[0].Stage;
			Else
				Output_.Link.Owner().Delete(Output_.Link);
				Demand.Outputs.Delete(Output_);
			EndIf;
		EndDo;
		#EndRegion
		
		LinesToUnify = SpecificationLinesForDisentanglement(SpecificationData);
		
		For Each Data In LinesToUnify Do
			
			// Specification looping control
			Parent = Demand;
			While Parent <> Undefined Do
				If Parent.BillOfMaterials = Data.BillOfMaterials Then
					Raise StrTemplate(
						NStr("vi = 'Trong quá trình kiểm tra sản phẩm, một vòng lặp được phát hiện trên bảng kê chi tiết các nguồn lực sản xuất ""%1"".';
							|ru = 'В процессе разузлования изделий обнаружено зацикливание на спецификации ""%1"".';
							|en = 'Loop on the ""%1"" BOM is detected during product explosion.'; fa = 'Loop on the ""%1"" BOM is detected during product explosion.';
							|it = 'Nel processo di snodo dei prodotti è stato rilevato un ciclo sulla specifica ""%1"".';
							|pl = 'W procesie rozwęźlenia wyrobów wykryto zapętlenie specyfikacji ""%1"".';
							|tr = 'Nihai ürünlerin ayrıştırılması sırasında ""%1"" ürün reçetesine yönelik döngü tespit edildi.'"),
						Demand.BillOfMaterials);
				EndIf;
				Parent = Parent.Parent
			EndDo;
			
			// Adding a need
			String = Data.String;
			
			If Not Data.ThisIsDisassembly Then
				RequiredToClarifyMaterial = Not ValueIsFilled(String.Products)
					Or Not ValueIsFilled(String.Characteristic) And String.ItemVariantsAreUsed
					Or Not ValueIsFilled(String.Count);
				If RequiredToClarifyMaterial Then
					Continue;
				EndIf;
			EndIf;
			
			Id = Id + 1;
			
			NewRow = Demands.Add();
			
			FillPropertyValues(NewRow, String);
			FillPropertyValues(NewRow, Demand,
				"ProductionDispatcherBusinessUnit,
				|LineOfBusiness,
				|ProductionStart,
				|StartDate2,
				|DateOfProduction,
				|ProductionScheduling"
					+ ?(IsBlankString(NodulationParameters.GroupFields), "", "," + NodulationParameters.GroupFields)
					+ ?(IsBlankString(NodulationParameters.AdditionalInformation), "", "," + NodulationParameters.AdditionalInformation)
					+ ?(IsBlankString(NodulationParameters.ReservePFFieldNamePurpose), "", "," + NodulationParameters.ReservePFFieldNamePurpose));
			
			// Rounding of piece-dimensional goods
			If Not (Data.ThisIsDisassembly Or Data.ThisIsRepair Or Data.ThisIsWork)
					And String.RoundOff
					And Int(String.Count) <> String.Count Then
				NewRow.Count = Int(String.Count) + 1;
			EndIf;
			
			NewRow.BillOfMaterials = Data.BillOfMaterials;
			NewRow.Id = Id;
			NewRow.Inputs = NewCommunicationNeeds();
			NewRow.Outputs = NewCommunicationNeeds();
			NewRow.Supply = NewDemandAssurance();
			NewRow.Parent = Demand;
			NewRow.Level = ?(Data.ThisIsDisassembly, Demand.Level+1, Demand.Level-1);
			NewRow.Order = ?(Data.ThisIsDisassembly Or Data.ThisIsRepair, 200000, 0);
			NewRow.Substitutes = NewAnaloguesNeed();
			#Region BuildingConnections
			If Data.ThisIsDisassembly Then
				
				Link1 = Demand.Outputs.Add();
				Link1.RsString = String;
				Link1.RsStringOwnerName = Data.RsStringOwnerName;
				Link1.LinkID_ = Id;
				
				Link2 = NewRow.Inputs.Add();
				Link2.CommunicationStage = String.Stage;
				Link2.LinkID_ = Demand.Id;
				Link2.Parent = True;
				Link2.Link = Link1;
				
				Link1.Link = Link2;
				
			Else
				
				// Assembly and repair
				Link1 = Demand.Inputs.Add();
				Link1.RsString = String;
				Link1.RsStringOwnerName = Data.RsStringOwnerName;
				Link1.LinkID_ = Id;
				
				Link2 = NewRow.Outputs.Add();
				Link2.CommunicationStage = String.Stage;
				Link2.LinkID_ = Demand.Id;
				Link2.Parent = True;
				Link2.Link = Link1;
				
				Link1.Link = Link2;
				
				If Data.ThisIsRepair Then
					
					// the repaired product is a transfer
					TheStructureOfTheSearch = New Structure("Products, Characteristic, Stage",
						String.Products, String.Characteristic, String.SourceOfSemiFinishedProduct);
					FoundRows = SpecificationData.RecyclableWaste.FindRows(TheStructureOfTheSearch);
					Link1 = Undefined;
					
					For Each ReleaseString In FoundRows Do
						Link1 = Demand.Outputs.Add();
						Link1.RsString = ReleaseString;
						Link1.RsStringOwnerName = "RecyclableWaste";
						Link1.LinkID_ = Id;
					EndDo;
					
					// repaired product - receiving
					Link2 = NewRow.Inputs.Add();
					Link2.CommunicationStage = String.SourceOfSemiFinishedProduct;
					Link2.LinkID_ = Demand.Id;
					Link2.Parent = True;
					
					If FoundRows.Count() = 1 Then
						Link2.Link = Link1;
						Link1.Link = Link2;
					EndIf;
					
				EndIf;
				
			EndIf;
			#EndRegion
			
			NodalQueue.Add(NewRow);
			
			If PFSelectionQueue <> Undefined
				And Not (Data.ThisIsDisassembly Or Data.ThisIsRepair Or Data.ThisIsWork) Then
				
				StringSelection__ = PFSelectionQueue.Add();
				FillPropertyValues(StringSelection__, String);
				StringSelection__.Id = NodalQueue.UBound();
				StringSelection__.Purpose = ?(IsBlankString(NodulationParameters.ReservePFFieldNamePurpose),
					Undefined,
					Demand[NodulationParameters.ReservePFFieldNamePurpose]);
				StringSelection__.WithAssignment = ValueIsFilled(StringSelection__.Purpose);
				StringSelection__.NotSeparately = Not NodulationParameters.ReservePFOnlySeparately;
				If NodulationParameters.ReplacePFNaAnalogues Then
					
					StringSelection__.BillOfMaterials = Demand.BillOfMaterials;
					StringSelection__.Product = Demand.SpecificationData.MainProduct.Products;
					StringSelection__.ItemVariantOfProduct = Demand.SpecificationData.MainProduct.Characteristic;
					StringSelection__.Department = String.StageSubdivision;
					
					If Demands.Columns.Find("ReferenceOrder") <> Undefined Then
						StringSelection__.ProductionOrder = Demand.ReferenceOrder;
					EndIf;
					If Demands.Columns.Find("LineOfBusiness") <> Undefined Then
						StringSelection__.LineOfBusiness = Demand.LineOfBusiness;
					EndIf;
					
				EndIf;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	// Selection of residues and analogues of PF
	If ValueIsFilled(PFSelectionQueue) Then
		
		PFSelectionQueue.Indexes.Add("Id");
		
		If NodulationParameters.ReservePFFromWarehouse Then
			PickUpRemainsOfSemiFinishedProducts(NodalQueue, PFSelectionQueue, PFReserves);
		EndIf;
		If NodulationParameters.ReplacePFNaAnalogues
				And ValueIsFilled(PFSelectionQueue) Then
			ChooseAnaloguesOfSemiFinishedProducts(NodalQueue, PFSelectionQueue, PFReserves);
		EndIf;
		For IndexOf = -NodalQueue.UBound() To 0 Do
			Demand = NodalQueue[-IndexOf];
			If Demand.Count = 0 Then
				Table = Demand.Outputs[0].Link.Owner(); // ValueTable
				Table.Delete(Demand.Outputs[0].Link);
				
				Table = Demand.Owner(); // ValueTable
				Table.Delete(Demand);
				
				NodalQueue.Delete(-IndexOf);
			EndIf;
		EndDo;
		
		PFReserves.GroupBy("Products,Characteristic,Warehouse,Purpose", "Count");
		
	EndIf;
	
	// Recursive partitioning
	If NodalQueue.UBound() <> -1 Then
		UnravelNeedsRecursively(
			Demands, NodalQueue, NodulationParameters, SelectionParameters, Id, PFReserves);
	EndIf;
	
EndProcedure

Function SpecificationLinesForDisentanglement(SpecificationData)
	
	Result = New ValueTable;
	
	Result.Columns.Add("String", New TypeDescription("ValueTableRow"));
	Result.Columns.Add("RsStringOwnerName", New TypeDescription("String",, New StringQualifiers));
	Result.Columns.Add("BillOfMaterials", New TypeDescription("CatalogRef.BillsOfMaterials"));
	Result.Columns.Add("ThisIsDisassembly", New TypeDescription("Boolean"));
	Result.Columns.Add("ThisIsRepair", New TypeDescription("Boolean"));
	Result.Columns.Add("ThisIsWork", New TypeDescription("Boolean"));
	
	// Materials - assembly and repair
	TheStructureOfTheSearch = New Structure("ProducedInProcess", True);
	
	For Each String In SpecificationData.MaterialsAndServices.FindRows(TheStructureOfTheSearch) Do
		
		If String.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials Then
			
			If String.BillOfMaterials.IsEmpty() Then
				
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể chọn bảng kê vật liệu cho dòng  %1 (bảng kê chi tiết các nguồn lực sản xuất ""%2"")';
						|ru = 'Не удалось подобрать спецификацию для материала в строке %1 (спецификация ""%2"")';
						|en = 'Cannot pick the bill of materials for the material in the line %1 (bill of materials ""%2"")'; fa = 'Cannot pick the bill of materials for the material in the line %1 (bill of materials ""%2"")';
						|it = 'Non è stato possibile selezionare una specifica per il materiale nella riga %1 (specifica ""%2"")';
						|pl = 'Nie udało się dobrać specyfikację dla materiału w wierszu %1 (specyfikacja ""%2"")';
						|tr = '%1 satırındaki malzeme için ürün reçetesi seçilemedi (ürün reçetesi ""%2"")'"),
					String.LineNumber,
					SpecificationData.BillOfMaterials);
				
				If SpecificationData.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM Then
					ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Không thể chọn bảng kê vật liệu cho %1 (bảng kê chi tiết ""%2"")';
							|ru = 'Не удалось подобрать спецификацию для ""%1"" (спецификация ""%2"")';
							|en = 'Cannot pick the bill of materials for %1 (""%2"" bill of materials)'; fa = 'Cannot pick the bill of materials for %1 (""%2"" bill of materials)';
							|it = 'Cannot pick the bill of materials for %1 (""%2"" bill of materials)';
							|pl = 'Cannot pick the bill of materials for %1 (""%2"" bill of materials)';
							|tr = '""%1"" için ürün bulunamadı (ürün reçetesi ""%2"")'"),
						String.Products,
						SpecificationData.BillOfMaterials);
				EndIf;
				
				Raise ErrorDescription;
			EndIf;
			
			NewRow = Result.Add();
			NewRow.String = String;
			NewRow.RsStringOwnerName = "MaterialsAndServices";
			NewRow.BillOfMaterials = String.BillOfMaterials;
			NewRow.ThisIsWork = String.ItemsType = Enums.ItemsTypes.Work_5;
			
			// Redefinition of specification data -
			// manufactured semi-finished products are provided separately
			String.WithAssignment = True;
			
		ElsIf String.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProducedOnStage
			And Not String.BillOfMaterialsRM.IsEmpty() Then
			
			NewRow = Result.Add();
			NewRow.String = String;
			NewRow.RsStringOwnerName = "MaterialsAndServices";
			NewRow.BillOfMaterials = String.BillOfMaterialsRM;
			NewRow.ThisIsRepair = True;
			
		EndIf;
		
	EndDo;
	
	// Output products - disassembly
	TheStructureOfTheSearch = New Structure("ProcessByBOM", True);
	
	For Each String In SpecificationData.ManufacturedProducts.FindRows(TheStructureOfTheSearch) Do
			
		NewRow = Result.Add();
		NewRow.String = String;
		NewRow.RsStringOwnerName = "ManufacturedProducts";
		NewRow.BillOfMaterials = String.BillOfMaterials;
		NewRow.ThisIsDisassembly = True;
		
	EndDo;
	
	// Returnable waste - disassembly
	For Each String In SpecificationData.RecyclableWaste.FindRows(TheStructureOfTheSearch) Do
		
		NewRow = Result.Add();
		NewRow.String = String;
		NewRow.RsStringOwnerName = "RecyclableWaste";
		NewRow.BillOfMaterials = String.BillOfMaterials;
		NewRow.ThisIsDisassembly = True;
			
	EndDo;
	
	Return Result;
	
EndFunction

// Reduces the need for semi-finished products by the amount of inventory balances.
// 
// Parameters:
// 	LinesOfNeed - Array - rows in the requirements table.
// 	UsedMaterials - See NewWayToSelectSemiFinishedProducts.
// 	Reserves - See NewReservesOfSemiFinishedProducts.
//
Procedure PickUpRemainsOfSemiFinishedProducts(LinesOfNeed, UsedMaterials, Reserves)
	
	// Data acquisition
	Texts = New Array();
	
	Texts.Add(
		"SELECT
		|	UsedMaterials.Id  AS Id,
		|	UsedMaterials.Products   AS Products,
		|	UsedMaterials.Characteristic AS Characteristic,
		|	UsedMaterials.Warehouse          AS Warehouse,
		|	UsedMaterials.Purpose     AS Purpose,
		|	UsedMaterials.Count     AS Count,
		|	UsedMaterials.WithAssignment    AS WithAssignment,
		|	UsedMaterials.NotSeparately  AS NotSeparately
		|INTO TTMaterials
		|FROM
		|	&UsedMaterials AS UsedMaterials
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	Purpose
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Reserves.Products   AS Products,
		|	Reserves.Characteristic AS Characteristic,
		|	Reserves.Warehouse          AS Warehouse,
		|	Reserves.Purpose     AS Purpose,
		|	Reserves.Count     AS Count
		|INTO TTReserves
		|FROM
		|	&Reserves AS Reserves
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	Purpose
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	UsedMaterials.Products AS Products,
		|	UsedMaterials.Characteristic AS Characteristic,
		|	UsedMaterials.Warehouse AS Warehouse,
		|	UsedMaterials.Purpose AS Purpose
		|INTO FilterMaterialsToObtainBalance
		|FROM
		|	TTMaterials AS UsedMaterials
		|WHERE
		|	UsedMaterials.WithAssignment
		|		AND UsedMaterials.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	UsedMaterials.Products AS Products,
		|	UsedMaterials.Characteristic AS Characteristic,
		|	UsedMaterials.Warehouse AS Warehouse,
		|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose
		|FROM
		|	TTMaterials AS UsedMaterials
		|WHERE
		|	UsedMaterials.NotSeparately
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose");
	
	QueryText =
		"SELECT
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
		|				Filter.Products AS Products,
		|				Filter.Characteristic AS Characteristic,
		|				Filter.Warehouse AS Warehouse,
		|				Filter.Purpose AS Purpose
		|			FROM
		|				FilterMaterialsToObtainBalance AS Filter)) AS Inventories";
	
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	ProvisionInDocumentsServer.CalculationOfBalancesForSettingActions(QueryText, TablesNames);
	
	Texts.Add(QueryText);
	
	Texts.Add(
		"SELECT
		|	TTMaterials.Id  AS Id,
		|	TTMaterials.Products   AS Products,
		|	TTMaterials.Characteristic AS Characteristic,
		|	TTMaterials.Warehouse          AS Warehouse,
		|	TTMaterials.Purpose     AS Purpose,
		|	TTMaterials.Count     AS Count,
		|	CASE
		|		WHEN ISNULL(RemainsApart.QuantityForShipAction, 0) - ISNULL(ReservesSeparately.Count, 0) > 0
		|			THEN
		|				ISNULL(RemainsApart.QuantityForShipAction, 0) - ISNULL(ReservesSeparately.Count, 0)
		|		ELSE 0
		|	END AS RemainderIsSeparate,
		|	CASE
		|		WHEN ISNULL(RemainsUndivided.QuantityForShipAction, 0) - ISNULL(ReservesNotSeparately.Count, 0) > 0
		|			THEN
		|				ISNULL(RemainsUndivided.QuantityForShipAction, 0) - ISNULL(ReservesNotSeparately.Count, 0)
		|		ELSE 0
		|	END AS RemainderUndivided
		|FROM
		|	TTMaterials AS TTMaterials
		|
		|		LEFT JOIN CalculationOfBalancesForSettingActions AS RemainsApart
		|		ON TTMaterials.Products = RemainsApart.Products
		|			AND TTMaterials.Characteristic = RemainsApart.Characteristic
		|			AND TTMaterials.Warehouse = RemainsApart.Warehouse
		|			AND TTMaterials.Purpose = RemainsApart.Purpose
		|			AND RemainsApart.QuantityForShipAction > 0
		|			AND TTMaterials.WithAssignment
		|
		|		LEFT JOIN TTReserves AS ReservesSeparately
		|		ON TTMaterials.Products = ReservesSeparately.Products
		|			AND TTMaterials.Characteristic = ReservesSeparately.Characteristic
		|			AND TTMaterials.Warehouse = ReservesSeparately.Warehouse
		|			AND TTMaterials.Purpose = ReservesSeparately.Purpose
		|			AND TTMaterials.WithAssignment
		|
		|		LEFT JOIN CalculationOfBalancesForSettingActions AS RemainsUndivided
		|		ON TTMaterials.Products = RemainsUndivided.Products
		|			AND TTMaterials.Characteristic = RemainsUndivided.Characteristic
		|			AND TTMaterials.Warehouse = RemainsUndivided.Warehouse
		|			AND RemainsUndivided.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|			AND RemainsUndivided.QuantityForShipAction > 0
		|			AND TTMaterials.NotSeparately
		|
		|		LEFT JOIN TTReserves AS ReservesNotSeparately
		|		ON TTMaterials.Products = ReservesNotSeparately.Products
		|			AND TTMaterials.Characteristic = ReservesNotSeparately.Characteristic
		|			AND TTMaterials.Warehouse = ReservesNotSeparately.Warehouse
		|			AND (ReservesNotSeparately.Purpose = VALUE(Catalog.Assignments.EmptyRef))
		|			AND TTMaterials.NotSeparately
		|
		|ORDER BY
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	Purpose,
		|	Id");
	
	Query = New Query();
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	
	Query.SetParameter("UsedMaterials", UsedMaterials);
	Query.SetParameter("Reserves", Reserves);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Balance = QueryResult.Unload();
	PreviousString = Balance[0];
	
	// Data processing
	For IndexOf = 0 To Balance.Count()-1 Do
		
		String = Balance[IndexOf];
		
		// Inheritance of leftovers
		If String.Products = PreviousString.Products
			And String.Characteristic = PreviousString.Characteristic
			And String.Warehouse = PreviousString.Warehouse Then
			
			String.RemainderUndivided = PreviousString.RemainderUndivided;
			
			If String.Purpose = PreviousString.Purpose Then
				String.RemainderIsSeparate = PreviousString.RemainderIsSeparate;
			EndIf;
			
		EndIf;
		
		NumberOfCredits = 0;
		
		Demand = LinesOfNeed[String.Id];
		Software_1 = Demand.Outputs[0].Link.RsString; // ValueTableRow
		RowIndex = Software_1.Owner().IndexOf(Software_1);
		
		// Isolated remainder
		If String.RemainderIsSeparate <> 0 Then
			
			Count = Min(String.Count, String.RemainderIsSeparate);
			
			String.Count = String.Count - Count;
			String.RemainderIsSeparate = String.RemainderIsSeparate - Count;
			NumberOfCredits = NumberOfCredits + Count;
			
			// Adding provision information to a parent need
			Software_3 = Demand.Parent.Supply; // ValueTable
			NewRow = Software_3.Add();
			NewRow.RowIndex2 = RowIndex;
			NewRow.Count = Count;
			NewRow.WithAssignment = True;
			
			// Adding reserves - they are taken into account in the following calls
			NewRow = Reserves.Add();
			FillPropertyValues(NewRow, String,, "Count");
			NewRow.Count = Count;
			
		EndIf;
		
		// Non-isolated remainder
		If String.RemainderUndivided <> 0 And String.Count <> 0 Then
			
			Count = Min(String.Count, String.RemainderUndivided);
			
			String.Count = String.Count - Count;
			String.RemainderUndivided = String.RemainderUndivided - Count;
			NumberOfCredits = NumberOfCredits + Count;
			
			// Adding provision information to a parent need
			Software_3 = Demand.Parent.Supply; // ValueTable
			NewRow = Software_3.Add();
			NewRow.RowIndex2 = RowIndex;
			NewRow.Count = Count;
			NewRow.WithAssignment = False;
			
			// Adding reserves - they are taken into account in the following calls
			NewRow = Reserves.Add();
			FillPropertyValues(NewRow, String,, "Count, Purpose");
			NewRow.Count = Count;
			
		EndIf;
		
		// Reducing the need
		Demand.Count = Demand.Count - NumberOfCredits;
		
		StringMaterial = UsedMaterials.Find(String.Id, "Id");
		If StringMaterial.Count = NumberOfCredits Then
			UsedMaterials.Delete(StringMaterial);
		Else
			StringMaterial.Count = StringMaterial.Count - NumberOfCredits;
		EndIf;
		
		PreviousString = String;
		
	EndDo;
	
EndProcedure

Procedure ChooseAnaloguesOfSemiFinishedProducts(LinesOfNeed, TableOfMaterials, PFReserves)
	
	TableOfGoods = TableOfMaterials.Copy(,
			"Id, Products, Characteristic, Department,
			|LineOfBusiness, ProductionOrder, BillOfMaterials,
			|Product, ItemVariantOfProduct, Count");
	
	TableOfGoods.Columns.Add("TotalCount1", Common.TypeDescriptionNumber(15, 3));
	TableOfGoods.Columns.Add("SupplyAssignment", New TypeDescription("CatalogRef.Assignments"));
	TableOfGoods.Columns.Add("WithAssignment", New TypeDescription("Boolean"));
	TableOfGoods.Columns.Add("StageOfResourceBillOfMaterials", New TypeDescription("CatalogRef.ProductionStages"));
	SourceType = Common.TypeDescriptionNumber(10);
	TableOfGoods.Columns.Add("Stage", SourceType);
	
	For Each SpecificationRow In TableOfGoods Do
		SpecificationRow.Stage = SpecificationRow.Id;
		SpecificationRow.TotalCount1 = SpecificationRow.Count;
	EndDo;
	
	Filter = New Map();
	PermissionSelectionParameters = New Map();
	
	If GetFunctionalOption("DynamicStructureOfProductionOrders") Then
	
		TMCommonUse.AddSelectionItemToCollection(Filter, "AlternativeMaterials.UseItForAutocorrectInOrders", "&UseItForAutocorrectInOrders");
		PermissionSelectionParameters.Insert("UseItForAutocorrectInOrders", CommonClientServer.ValueInArray(True));	
	
	EndIf;
	
	SelectionOfPermissions = New Structure();
	SelectionOfPermissions.Insert("Filter", Filter);
	SelectionOfPermissions.Insert("PermissionSelectionParameters", PermissionSelectionParameters);
	
	Substitutes = AlternativeMaterials.GetReplacementTableForGeneratingStages(TableOfGoods, SelectionOfPermissions, PFReserves, False, SourceType);
	If Substitutes = Undefined
		Or Substitutes.Count() = 0 Then
		Return;
	EndIf;
	
	Substitutes.Sort("Id, Resolution", New CompareValues());
	TableOfMaterials.Indexes.Add("Id");
	
	FillingValues = Substitutes[0];
	For IndexOf = 0 To Substitutes.Count()-1 Do
		
		If Not Substitutes[IndexOf].ThisIsASubstitute Then
			Continue;
		EndIf;
		
		Substitute = Substitutes[IndexOf];
		ReplacementQuantity = 0;
		
		For Each KeyAndValue In Substitute.ReplacedQuantityLineByLine Do
			Substitute.Id = KeyAndValue.Key;
			ReplacementQuantity = KeyAndValue.Value;
			Break;
		EndDo;
		
		// Adding reserves - they are taken into account in the following calls
		NewRow = PFReserves.Add();
		FillPropertyValues(
			NewRow,
			TableOfMaterials.Find(Substitute.Id, "Id"),
			,
			"Products,Characteristic,Warehouse,Purpose,Count");
		FillPropertyValues(NewRow, Substitute, "Products,Characteristic,Warehouse,Count");
		
		Demand = LinesOfNeed[Substitute.Id];
		Software_1 = Demand.Outputs[0].Link.RsString; // ValueTableRow
		RowIndex = Software_1.Owner().IndexOf(Software_1);
		
		// Adding provision information to a parent need
		TableAnalogues = Demand.Parent.Substitutes; // ValueTable
		NewRow = TableAnalogues.Add();
		NewRow.RowIndex2 = RowIndex;
		FillPropertyValues(NewRow, Substitute, "Resolution, Products, Characteristic, Warehouse, SupplyOption, Count");
		
		If IndexOf = 0
			Or FillingValues.Id <> Substitute.Id
			Or FillingValues.Resolution <> Substitute.Resolution Then
			
			FillingValues = Substitute;
			
			Software_3 = Demand.Parent.Supply; // ValueTable
			NewRow = Software_3.Add();
			NewRow.RowIndex2   = RowIndex;
			NewRow.Count     = ReplacementQuantity;
			NewRow.WithAssignment    = False; // Analogues are selected only in the non-isolated remainder
			NewRow.Resolution     = Substitute.Resolution;
			NewRow.ReplacementWithAnalog = True;
			
			// Reducing the need
			Demand.Count = Demand.Count - ReplacementQuantity;
			
		EndIf;
		
	EndDo;
	
EndProcedure
Function DivideNeedsIntoBatches(Demands, NodulationParameters)
	
	Result = New Array;
	
	Inputs = New ValueTable;
	Inputs.Columns.Add("Id", New TypeDescription("Number", New NumberQualifiers));
	Inputs.Columns.Add("Stage", New TypeDescription("CatalogRef.ProductionStages"));
	Inputs.Columns.Add("RsString", New TypeDescription("ValueTableRow"));
	Inputs.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	Inputs.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Inputs.Columns.Add("StageCode", New TypeDescription("Number", New NumberQualifiers));
	Inputs.Columns.Add("SpecificationData", New TypeDescription("Structure"));
	
	Outputs = New ValueTable;
	Outputs.Columns.Add("Id", New TypeDescription("Number", New NumberQualifiers));
	Outputs.Columns.Add("Stage", New TypeDescription("CatalogRef.ProductionStages"));
	Outputs.Columns.Add("RsString", New TypeDescription("ValueTableRow"));
	Outputs.Columns.Add("RsStringOwnerName", New TypeDescription("String",, New StringQualifiers));
	Outputs.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	Outputs.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Outputs.Columns.Add("SpecificationData", New TypeDescription("Structure"));
	Outputs.Columns.Add("Demand", New TypeDescription("ValueTableRow"));
	
	StOfPFSearchAtStage = New Structure("MethodOfReceivingMaterial, BillOfMaterialsRM",
		Enums.MethodsOfReceivingBOMMaterials.ProducedOnStage,
		Catalogs.BillsOfMaterials.EmptyRef());
	StNHStage = New Structure("Products, Characteristic, Stage");
	StAnalogues = New Structure("RowIndex2, Resolution");
	Demands.Sort("Order, Begin, Ending, Level, Products, Characteristic, BillOfMaterials, Purpose, Recipient, Sender");
	
	StageCode = 10000000;
	IdOfReleaseAtStage = 10000000;
	For IndexNeed = 0 To Demands.Count()-1 Do
		
		Demand = Demands[IndexNeed];
		If Demand.Collapsed_ Then
			Continue;
		EndIf;
		
		TotalBatches = 1;
		If NodulationParameters.DivideIntoOptimalBatches
				And Demand.ReleaseParty.Details <> Undefined Then
			TotalBatches = Demand.ReleaseParty.Details.Count();
		EndIf;
		
		For CountBatch = 1 To TotalBatches Do
			
			// Filling out the batch
			If TotalBatches = 1 Then
				SpecificationData = Demand.SpecificationData;
				ReleaseParty = Demand.ReleaseParty;
			Else
				SpecificationData = CommonClientServer.CopyStructure(Demand.SpecificationData);
				
				ReleaseParty = Demand.ReleaseParty.Details[CountBatch-1];
				ItemData_3 = Catalogs.BillsOfMaterials.ProductData_5();
				FillPropertyValues(ItemData_3, Demand);
				Catalogs.BillsOfMaterials.CalculateQuantityPerBatchRelease(ReleaseParty, SpecificationData, ItemData_3);
				
				For Each Stage In SpecificationData.Stages Do
					Stage.StageCode = StageCode;
					StageCode = StageCode + 1;
				EndDo;
			EndIf;
			
			AddFieldsToSpecificationData(SpecificationData, NodulationParameters);
			
			FillPropertyValues(
				SpecificationData,
				Demand,
				"StartDate2, DateOfProduction, Begin, Ending, ProductionScheduling"
				+ ?(IsBlankString(NodulationParameters.GroupFields), "", "," + NodulationParameters.GroupFields)
				+ ?(IsBlankString(NodulationParameters.AdditionalInformation), "", "," + NodulationParameters.AdditionalInformation));
			
			SpecificationData.ReleaseParty = ReleaseParty;
			
			If SpecificationData.ManufacturedProducts.Count() <> 0 Then
				SpecificationData.ManufacturedProducts.LoadColumn(
					SpecificationData.ManufacturedProducts.UnloadColumn("Warehouse"), "Recipient");
			EndIf;
			If SpecificationData.RecyclableWaste.Count() <> 0 Then
				SpecificationData.RecyclableWaste.LoadColumn(
					SpecificationData.RecyclableWaste.UnloadColumn("Warehouse"), "Recipient");
			EndIf;
			
			// Filling in the details for incoming data
			For IndexOf = 0 To Demand.CollapsedIncomingNeeds.Count() Do
				VhNeed = ?(IndexOf = 0,
					?(Demand.ThisIsIncomingNeed, Demand, Undefined),
					Demand.CollapsedIncomingNeeds[IndexOf - 1]);
				If VhNeed = Undefined Or VhNeed.Count = 0 Then
					Continue;
				EndIf;
				If VhNeed.ThisIsDisassembly Then
					
					For Each String In SpecificationData.IncomingProducts Do
						
						If String.Allocated = String.Count
							Or String.Products <> VhNeed.Products
							Or String.Characteristic <> VhNeed.Characteristic
								And ValueIsFilled(String.Characteristic)
								And Not String.AnyCharacteristic Then
							Continue;
						EndIf;
						
						If VhNeed.Count >= String.Count Then
							FillLine = String;
						Else
							NewRow = SpecificationData.IncomingProducts.Add();
							FillPropertyValues(NewRow, String);
							NewRow.Count = VhNeed.Count;
							NewRow.NumberOfPackages = NewRow.Count
								* NewRow.PackageData.Denominator / NewRow.PackageData.Numerator;
							FillLine = NewRow;
								
							String.Count = String.Count - VhNeed.Count;
							String.NumberOfPackages = String.Count
								* String.PackageData.Denominator / String.PackageData.Numerator;
						EndIf;
						
						If ValueIsFilled(VhNeed.Sender) Then
							FillLine.Warehouse = VhNeed.Sender;
						EndIf;
						FillLine.Characteristic = VhNeed.Characteristic;
						If ValueIsFilled(VhNeed.StageSource) Then
							FillLine.StageSender = VhNeed.StageSource;
							FillLine.WithAssignment = True;
							FillLine.Produced = True;
						EndIf;
						FillLine.Allocated = FillLine.Count;
						
						VhNeed.Count = VhNeed.Count - FillLine.Count;
						If VhNeed.Count = 0 Then
							Break;
						EndIf;
					EndDo;
					
				Else // Assembly and repair

					For Cnt = 1 To 2 Do
						For Each String In SpecificationData[?(Cnt = 1, "ManufacturedProducts", "RecyclableWaste")] Do
							If String.Allocated = String.Count
								Or String.Products <> VhNeed.Products
								Or String.Characteristic <> VhNeed.Characteristic
									And ValueIsFilled(String.Characteristic)
									And Not String.AnyCharacteristic Then
								Continue;
							EndIf;
							
							Allocated = Min(String.Count-String.Allocated, VhNeed.Count);
							
							If (String.Allocated = 0
									And VhNeed.Count >= String.Count)
								Or (LinesAreIdentical(String, VhNeed,
										"Characteristic,Recipient,Purpose,ToExpenseAs,ExpenseItem,DimensionOfExpenses,AssetsLiabilitiesDimension")
									And String.StageConsumer = VhNeed.StageSource) Then
								
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
									NewRow = OwnerOfString.Add();
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
								EndIf;
								
							Else
								
								// Splitting the string
								OwnerOfString = String.Owner(); // ValueTable
								NewRow = OwnerOfString.Add();
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
								
							EndIf;
							
							FillPropertyValues(FillLine, VhNeed,
								"Characteristic,Recipient,Purpose,ToExpenseAs,ExpenseItem,DimensionOfExpenses,AssetsLiabilitiesDimension");
							FillLine.StageConsumer = VhNeed.StageSource;
							FillLine.Allocated = FillLine.Allocated + Allocated;
							
							VhNeed.Count = VhNeed.Count - Allocated;
							If VhNeed.Count = 0 Then
								Break;
							EndIf;
							
						EndDo;
						If VhNeed.Count = 0 Then
							Break;
						EndIf;
					EndDo;
				EndIf;
			EndDo;
			
			// Offset of security data
			Collapse = New Map;
			DeleteMaterials = New Array;
			For Each Supply In Demand.Supply Do
				String = SpecificationData.MaterialsAndServices[Supply.RowIndex2];
				If Supply.Count = 0 Or String.Count = 0 Or Not String.Produced Then
					Continue;
				EndIf;
				
				NumberOfCredits = Min(String.Count, Supply.Count);
				If Supply.ReplacementWithAnalog Then
					
					// Provision through replacement with analogues
					FillPropertyValues(StAnalogues, Supply);
					For Each Substitute In Demand.Substitutes.FindRows(StAnalogues) Do
						NewRow = SpecificationData.MaterialsAndServices.Add();
						FillPropertyValues(NewRow, Substitute, "Products,Characteristic,Warehouse");
						FillPropertyValues(NewRow, String, "Stage,StageSubdivision");
						If Supply.Count = NumberOfCredits Then
							NewRow.Count = Substitute.Count;
						Else
							NewRow.Count = Round(Substitute.Count * NumberOfCredits / Supply.Count, 3);
							Substitute.Count = Substitute.Count - NewRow.Count;
						EndIf;
						NewRow.NumberOfPackages = NewRow.Count;
						NewRow.WithAssignment = Supply.WithAssignment;
						NewRow.SupplyOption = Substitute.SupplyOption;
						NewRow.Produced = False;
					EndDo;
					
					String.Count = String.Count - NumberOfCredits;
					If String.Count = 0 Then
						String.Produced = False;
						String.ProducedInProcess = False;
						DeleteMaterials.Add(String);
					Else
						// When replaced with analogs, the original string is converted to the base unit.
						String.NumberOfPackages = String.Count;
						String.Package = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
					EndIf;
					
				Else
					// Provision from stock balances
					FillLine = Undefined;
					If String.Count = NumberOfCredits Then
						FillLine = String;
					Else
						NewRow = SpecificationData.MaterialsAndServices.Add();
						FillPropertyValues(NewRow, String);
						NewRow.Count = NumberOfCredits;
						NewRow.NumberOfPackages = NewRow.Count
							* String.PackageData.Denominator / String.PackageData.Numerator;
						
						FillLine = NewRow;
						
						String.Count = String.Count - NumberOfCredits;
						String.NumberOfPackages = String.Count
							* String.PackageData.Denominator / String.PackageData.Numerator;
					EndIf;
					
					FillLine.Produced = False;
					FillLine.ProducedInProcess = False;
					FillLine.SourceOfSemiFinishedProduct = Catalogs.BillsOfMaterials.EmptyRef();
					FillLine.BillOfMaterials = Catalogs.BillsOfMaterials.EmptyRef();
					FillLine.WithAssignment = Supply.WithAssignment;
					FillLine.SupplyOption = Enums.SupplyOptions.FromWarehouse;
				EndIf;
				Supply.Count = Supply.Count - NumberOfCredits;
			EndDo;
			
			// Adding outputs
			For Each Link In Demand.Outputs Do
				Link.Link = Undefined; // Breaking cyclic links
				
				If TotalBatches = 1 Then
					RsString = Link.RsString;
				Else
					TableRs = Link.RsString.Owner(); // ValueTable
					RsString = SpecificationData[Link.RsStringOwnerName][TableRs.IndexOf(Link.RsString)];
				EndIf;
				
				Output_ = Outputs.Add();
				Output_.Id = Link.LinkID_;
				Output_.Stage = Link.CommunicationStage;
				Output_.RsString = RsString;
				Output_.RsStringOwnerName = Link.RsStringOwnerName;
				Output_.Products = Link.RsString.Products;
				Output_.Characteristic = Link.RsString.Characteristic;
				Output_.SpecificationData = SpecificationData;
				Output_.Demand = Demand;
			EndDo;
			
			// Adding Inputs
			For Each Link In Demand.Inputs Do
				Link.Link = Undefined; // Breaking cyclic links
				
				If TotalBatches = 1 Then
					RsString = Link.RsString;
				Else
					TableRs = Link.RsString.Owner(); // ValueTable
					RsString = SpecificationData[Link.RsStringOwnerName][TableRs.IndexOf(Link.RsString)];
				EndIf;
				If Link.Parent                  // Links to parental needs are added via incoming items
					Or Not RsString.Produced Then // The need is closed by providing
					Continue; 
				EndIf;
				
				Enter = Inputs.Add();
				Enter.Id = Demand.Id;
				Enter.Stage = RsString.Stage;
				Enter.RsString = RsString;
				Enter.Products = Link.RsString.Products;
				Enter.Characteristic = Link.RsString.Characteristic;
				Enter.StageCode = SpecificationData.Stages.Find(Enter.RsString.Stage, "Stage").StageCode;
				Enter.SpecificationData = SpecificationData;
			EndDo;
			For Each String In SpecificationData.IncomingProducts Do
				If String.Allocated = String.Count Then
					Continue;
				EndIf;
				Enter = Inputs.Add();
				Enter.Id = Demand.Id;
				Enter.Stage = String.Stage;
				Enter.RsString = String;
				Enter.Products = String.Products;
				Enter.Characteristic = String.Characteristic;
				Enter.StageCode = SpecificationData.Stages.Find(String.Stage, "Stage").StageCode;
				Enter.SpecificationData = SpecificationData;
			EndDo;
			// Adding links by PF produced at the stage
			For Each String In SpecificationData.MaterialsAndServices.FindRows(StOfPFSearchAtStage) Do
				Enter = Inputs.Add();
				Enter.Id = IdOfReleaseAtStage;
				Enter.Stage = String.Stage;
				Enter.RsString = String;
				Enter.Products = String.Products;
				Enter.Characteristic = String.Characteristic;
				Enter.StageCode = SpecificationData.Stages.Find(String.Stage, "Stage").StageCode;
				Enter.SpecificationData = SpecificationData;
				
				StNHStage.Products = String.Products;
				StNHStage.Characteristic = String.Characteristic;
				StNHStage.Stage = String.SourceOfSemiFinishedProduct;
				
				For Each LineOutput In SpecificationData.RecyclableWaste.FindRows(StNHStage) Do
					Output_ = Outputs.Add();
					Output_.Id = IdOfReleaseAtStage;
					Output_.Stage = String.Stage;
					Output_.RsString = LineOutput;
					Output_.RsStringOwnerName = "RecyclableWaste";
					Output_.Products = LineOutput.Products;
					Output_.Characteristic = LineOutput.Characteristic;
					Output_.SpecificationData = SpecificationData;
					Output_.Demand = Demand;
				EndDo;
				
				IdOfReleaseAtStage = IdOfReleaseAtStage + 1;
			EndDo;
			
			For Each String In DeleteMaterials Do
				SpecificationData.MaterialsAndServices.Delete(String);
			EndDo;
			
			Result.Add(SpecificationData);
		EndDo;
	EndDo;
	
	// Building relationships
	Inputs.Sort("Id, Stage, Products, Characteristic", New CompareValues());
	Outputs.Sort("Id, Stage, Products, Characteristic", New CompareValues());
	IndOutput = 0;
	IndOutputMax = Outputs.Count()-1;
	
	For IndusEntrance = 0 To Inputs.Count()-1 Do
		Enter = Inputs[IndusEntrance];
		Balance = Enter.RsString.Count;
		IndOutput = ?(IndOutput <= IndOutputMax, IndOutput, 0);
		While IndOutput <= IndOutputMax Do
			Output_ = Outputs[IndOutput];
			
			If Output_.RsString.Allocated = Output_.RsString.Count
				Or Output_.RsString.Count = 0
				Or Output_.Id <> Enter.Id
				Or Output_.Stage <> Enter.Stage
				Or Output_.Products <> Enter.Products
				Or Output_.Characteristic <> Enter.Characteristic
					And ValueIsFilled(Output_.Characteristic) Then
				IndOutput = IndOutput + 1;
				Continue;
			EndIf;
			
			If Not Output_.Demand.PlanNotEarlierThan.IsEmpty() Then // Linking to the planning stage earlier
				Output_.SpecificationData.PlanNoEarlierThanStageCode =
					Enter.SpecificationData.Stages.Find(Output_.Demand.PlanNotEarlierThan, "Stage").StageCode;
			EndIf;
			
			If Output_.RsString.Allocated <> 0 
				Or Output_.RsString.Count > Balance Then
				LineOutput = Output_.RsString.Owner().Insert(0);
				FillPropertyValues(LineOutput, Output_.RsString);
				LineOutput.Count = Min((Output_.RsString.Count-Output_.RsString.Allocated), Balance);
				LineOutput.NumberOfPackages = LineOutput.Count * LineOutput.PackageData.Denominator / LineOutput.PackageData.Numerator;
				
				Output_.RsString.Count = Output_.RsString.Count - LineOutput.Count;
				Output_.RsString.NumberOfPackages = Output_.RsString.Count * Output_.RsString.PackageData.Denominator / Output_.RsString.PackageData.Numerator;
				
				If Output_.RsStringOwnerName = "ManufacturedProducts" Then
					ProductionClientServer.RecalculateFractionOfCostWhenSplittingRow(
						LineOutput, Output_.RsString, SpecificationData.MethodOfAllocatingFinishedProductCosts);
				EndIf;
				
				// Monitoring compliance with rounding rules
				If Output_.RsString.RoundOff
					And Round(Output_.RsString.Count) <> Output_.RsString.Count Then
					
					If Output_.RsString.Allocated = 0 Then
						Output_.RsString.Recipient = Enter.RsString.Warehouse;
						Output_.RsString.RoundOff = False;
					ElsIf Output_.RsString.Count > Output_.RsString.Allocated Then
						NewRow = Output_.RsString.Owner().Insert(0);
						FillPropertyValues(NewRow, Output_.RsString);
						NewRow.Count = Output_.RsString.Count - Output_.RsString.Allocated;
						NewRow.NumberOfPackages = NewRow.Count * NewRow.PackageData.Denominator / NewRow.PackageData.Numerator;
						NewRow.Allocated = 0;
						NewRow.Recipient = Enter.RsString.Warehouse;
						NewRow.RoundOff = False;
						
						Output_.RsString.Count = Output_.RsString.Allocated;
						Output_.RsString.NumberOfPackages = Output_.RsString.Count * Output_.RsString.PackageData.Denominator / Output_.RsString.PackageData.Numerator;
						
						If Output_.RsStringOwnerName = "ManufacturedProducts" Then
							ProductionClientServer.RecalculateFractionOfCostWhenSplittingRow(
								NewRow, Output_.RsString, SpecificationData.MethodOfAllocatingFinishedProductCosts);
						EndIf;
					EndIf;	
				EndIf;
			Else
				LineOutput = Output_.RsString;
				IndOutput = IndOutput + 1;
			EndIf;
			
			LineOutput.Recipient = ?(Enter.RsString.ItemsType = Enums.ItemsTypes.Work_5,
				Enter.RsString.StageSubdivision,
				Enter.RsString.Warehouse);
			LineOutput.RecipientStageCode = Enter.StageCode;
			LineOutput.Allocated = LineOutput.Count;
			
			If Output_.RsString.AnyCharacteristic
				And Not ValueIsFilled(Output_.Characteristic) Then
				LineOutput.Characteristic = Enter.RsString.Characteristic;
			EndIf;
			
			Balance = Balance - LineOutput.Count;
			If Balance = 0 Then
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

Procedure AddFieldsToSpecificationData(SpecificationData, NodulationParameters)
	
	SpecificationData.Insert("StartDate2");
	SpecificationData.Insert("DateOfProduction");
	SpecificationData.Insert("Begin");
	SpecificationData.Insert("Ending");
	SpecificationData.Insert("ProductionScheduling");
	SpecificationData.Insert("ReleaseParty");
	SpecificationData.Insert("PlanNoEarlierThanStageCode");
	
	If NodulationParameters.GroupData_ Then
		For Each Field In StrSplit(NodulationParameters.GroupFields, ",", False) Do
			SpecificationData.Insert(Field);
		EndDo;
		For Each Field In StrSplit(NodulationParameters.AdditionalInformation, ",", False) Do
			SpecificationData.Insert(Field);
		EndDo;
	EndIf;
	
	RecipientTypes = New Array;
	RecipientTypes.Add(Type("CatalogRef.BusinessStructure"));
	RecipientTypes.Add(Type("CatalogRef.Warehouses"));
	FromRecipient = New TypeDescription(RecipientTypes);
		
	FromStage = New TypeDescription("Undefined");
	FromStage = New TypeDescription("DocumentRef.ProductionStage2_2");
	TypesOfArticles = New Array;
	TypesOfArticles.Add(Type("ChartOfCharacteristicTypesRef.ExpenseItems"));
	TypesOfArticles.Add(Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems"));
	FromExpenseItem = New TypeDescription(TypesOfArticles);
	
	// Output products and returnable waste
	For Cnt = 1 To 2 Do
		
		Table = SpecificationData[?(Cnt = 1, "ManufacturedProducts", "RecyclableWaste")]; // ValueTable
		Table.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
		Table.Columns.Add("StageConsumer", FromStage);
		Table.Columns.Add("Recipient", FromRecipient);
		Table.Columns.Add("Allocated", New TypeDescription("Number", New NumberQualifiers));
		Table.Columns.Add("RecipientStageCode", New TypeDescription("Number", New NumberQualifiers));
		Table.Columns.Add("ToExpenseAs", New TypeDescription("Boolean"));
		Table.Columns.Add("ExpenseItem", FromExpenseItem);
		Table.Columns.Add("DimensionOfExpenses", Metadata.ChartsOfCharacteristicTypes.ExpenseItems.Type);
		Table.Columns.Add("AssetsLiabilitiesDimension",
			Metadata.ChartsOfCharacteristicTypes.AssetLiabilityItems.Type);
		
	EndDo;
	
	// Incoming Products
	Table = SpecificationData.IncomingProducts; // ValueTable
	Table.Columns.Add("StageSender", FromStage);
	Table.Columns.Add("Allocated", New TypeDescription("Number", New NumberQualifiers));
EndProcedure

Procedure CheckCorrectnessOfSpecifications(Specifications, ErrorDescription)
	
	Query = New Query(
		"SELECT TOP 1
		|	ProductionStages.Owner               AS BillOfMaterials,
		|	ProductionStages.Owner.Presentation AS BillOfMaterialsPresentation,
		|	TRUE                                   AS SeveralReleasingStages,
		|	FALSE                                     AS NotValid
		|FROM
		|	Catalog.ProductionStages AS ProductionStages
		|WHERE
		|	ProductionStages.Owner IN(&Specifications)
		|	AND ProductionStages.DeletionMark = FALSE
		|	AND ProductionStages.NextStageNo = 0
		|	AND ProductionStages.Owner.ProductionProcessType <> VALUE(Enum.ProductionProcessTypes.Disassembly)
		|
		|GROUP BY
		|	ProductionStages.Owner,
		|	ProductionStages.Owner.Presentation
		|
		|HAVING
		|	COUNT(ProductionStages.Ref) > 1
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	BillsOfMaterials.Ref               AS BillOfMaterials,
		|	BillsOfMaterials.Ref.Presentation AS BillOfMaterialsPresentation,
		|	FALSE                                       AS SeveralReleasingStages,
		|	TRUE                                     AS NotValid
		|FROM
		|	Catalog.BillsOfMaterials AS BillsOfMaterials
		|WHERE
		|	BillsOfMaterials.Ref IN(&Specifications)
		|	AND BillsOfMaterials.Status <> VALUE(Enum.BOMStatuses.Valid)");
	
	Query.SetParameter("Specifications", Specifications);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		
		ErrorDescription.HasError = True;
		ErrorDescription.LinkError = Selection.BillOfMaterials;
		
		If Selection.SeveralReleasingStages Then
			ErrorDescription.ErrorText = StrTemplate(
					NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất ""%1""chứa nhiều công đoạn xuất xưởng';
						|ru = 'Спецификация ""%1"" содержит несколько выпускающих этапов';
						|en = 'The ""%1"" BOM contains several release stages'; fa = 'The ""%1"" BOM contains several release stages';
						|it = 'La specifica ""%1"" contiene diverse fasi di rilascio';
						|pl = 'Specyfikacja ""%1"" zawiera kilka etapów wypuszczania produkcji';
						|tr = '""%1"" ürün reçetesi birden fazla ürün çıkış aşaması içermektedir'"),
					Selection.BillOfMaterialsPresentation);
		ElsIf Selection.NotValid Then
			ErrorDescription.ErrorText = StrTemplate(
					NStr("vi = 'Bảng kê chi tiết ""%1"" không có trạng thái ""Có hiệu lực""';
						|ru = 'Спецификация ""%1"" не находится в статусе ""Действует""';
						|en = 'The bill of materials ""%1"" is not ""Valid""'; fa = 'The bill of materials ""%1"" is not ""Valid""';
						|it = 'La specifica ""%1"" non si trova nello stato ""Attivo""';
						|pl = 'Specyfikacja ""%1"" nie znajduje się w statusie ""Obowiązuje""';
						|tr = '""%1"" ürün reçetesi ""Aktif"" durumunda değildir'"),
					Selection.BillOfMaterialsPresentation);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CalculateQuantityPerBatchRelease(NodulationParameters, ReleaseParty, SpecificationData, ItemData_3)
	
	Catalogs.BillsOfMaterials.CalculateQuantityPerBatchRelease(
		ReleaseParty,
		SpecificationData,
		ItemData_3);
	
	// Recalculation of PM in which the number of items is rounded
	If NodulationParameters.DivideIntoOptimalBatches
		And ReleaseParty.Details <> Undefined
		And ReleaseParty.Details.Count() > 1 Then
		
		SpecificationDataCopy = CommonClientServer.CopyStructure(SpecificationData);
		
		Tables = StrSplit("ManufacturedProducts,RecyclableWaste,IncomingProducts,MaterialsAndServices", ",");
		For Each Table In Tables Do
			SpecificationData[Table].FillValues(0, "Count,NumberOfPackages");
		EndDo;
		
		For Each BatchReleaseDecryption In ReleaseParty.Details Do
			
			Catalogs.BillsOfMaterials.CalculateQuantityPerBatchRelease(
				BatchReleaseDecryption,
				SpecificationDataCopy,
				ItemData_3);
			
			For Each Table In Tables Do
				For IndexOf = 0 To SpecificationData[Table].Count()-1 Do
					SpecificationData[Table][IndexOf].Count = SpecificationData[Table][IndexOf].Count
						+ SpecificationDataCopy[Table][IndexOf].Count;
					SpecificationData[Table][IndexOf].NumberOfPackages = SpecificationData[Table][IndexOf].NumberOfPackages
						+ SpecificationDataCopy[Table][IndexOf].NumberOfPackages;
				EndDo;
			EndDo;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Function LinesAreIdentical(String1, String2, ColumnsNames)
	
	For Each Column In StrSplit(ColumnsNames, ",") Do
		If String1[Column] <> String2[Column] Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

#Region Constructors

// Returns:
// 	ValueTable:
// * String - ValueTableRow -
// * RsStringOwnerName - String -
// * Link - ValueTableRow of See NewCommunicationNeeds
// * LinkID_ - Number -
// * CommunicationStage - CatalogRef.ProductionStages -
// * Parent - Boolean -
Function NewCommunicationNeeds()
	
	Result = New ValueTable;
	
	// Specification data table row - Communication source/receiver
	Result.Columns.Add("RsString", New TypeDescription("ValueTableRow"));
	
	// Name of the table part that the string belongs to
	Result.Columns.Add("RsStringOwnerName", New TypeDescription("String",, New StringQualifiers));
	
	// The row of the relationship table opposite to this row
	// Example: if this line is the output, then the field refers to the input line
	// The links are also cross-linked - in the example above, the input line contains a link to this line
	Result.Columns.Add("Link", New TypeDescription("ValueTableRow"));
	
	// ID of the related need
	Result.Columns.Add("LinkID_", New TypeDescription("Number", New NumberQualifiers));
	
	// Related need stage - Receiver/communication source
	Result.Columns.Add("CommunicationStage", New TypeDescription("CatalogRef.ProductionStages"));
	
	// If True then the link refers to the parental need
	Result.Columns.Add("Parent", New TypeDescription("Boolean"));
	
	Return Result;
	
EndFunction

Function NewDemandAssurance()
	
	Result = New ValueTable;
	
	// Index of the pm line of the materials and services to which the security data relate
	Result.Columns.Add("RowIndex2", New TypeDescription("Number", New NumberQualifiers));
	
	// Security data
	Result.Columns.Add("Count", New TypeDescription("Number", New NumberQualifiers));
	
	// When providing from the rest in the warehouse
	Result.Columns.Add("WithAssignment", New TypeDescription("Boolean"));
	
	// When provided by replacing with analogs
	Result.Columns.Add("Resolution", New TypeDescription("DocumentRef.EngineeringChangeOrder"));
	Result.Columns.Add("ReplacementWithAnalog", New TypeDescription("Boolean"));
	Return Result;
	
EndFunction

// Returns:
// 	ValueTable - LongDesc:
// * Products - CatalogRef.Products -
// * Characteristic - CatalogRef.ItemsCharacteristics -
// * Warehouse - CatalogRef.Warehouses -
// * Department - CatalogRef.BusinessStructure -
// * Purpose - CatalogRef.Assignments -
// * ItemsType - EnumRef.ItemsTypes -
// * SupplyOption - EnumRef.SupplyOptions -
// * DateOfShipment - Date -
// * WorkShipmentDate - Date -
// * Count - Number -
Function NewReservesOfSemiFinishedProducts()
	
	Result = New ValueTable;
	
	Result.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	Result.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Result.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	Result.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	Result.Columns.Add("Count", New TypeDescription("Number", New NumberQualifiers(15, 3)));
	
	Return Result;
	
EndFunction

// Returns:
// 	ValueTable:
// * Id - Number
Function NewWayToSelectSemiFinishedProducts(ReplacePFNaAnalogues)
	
	Result = New ValueTable;
	Result.Columns.Add("Id", New TypeDescription("Number", New NumberQualifiers));
	Result.Columns.Add("WithAssignment", New TypeDescription("Boolean"));
	Result.Columns.Add("NotSeparately", New TypeDescription("Boolean"));
	
	Result.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	Result.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Result.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	Result.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	Result.Columns.Add("Count", New TypeDescription("Number", New NumberQualifiers(15, 3)));
	If ReplacePFNaAnalogues Then
		Result.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
		Result.Columns.Add("LineOfBusiness", New TypeDescription("CatalogRef.LinesOfBusiness"));
		Result.Columns.Add("ProductionOrder", New TypeDescription("DocumentRef.ProductionOrder2_2"));
		Result.Columns.Add("BillOfMaterials", New TypeDescription("CatalogRef.BillsOfMaterials"));
		Result.Columns.Add("Product", New TypeDescription("CatalogRef.Products"));
		Result.Columns.Add("ItemVariantOfProduct", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	EndIf;
	Return Result;
	
EndFunction

// Returns:
// 	ValueTable
Function NewAnaloguesNeed()
	
	Result = New ValueTable;
	
	// Index of the pm line of the materials and services to which the security data relate
	Result.Columns.Add("RowIndex2", New TypeDescription("Number", New NumberQualifiers));
	Result.Columns.Add("Resolution", New TypeDescription("DocumentRef.EngineeringChangeOrder"));
	Result.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	Result.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Result.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	Result.Columns.Add("SupplyOption", New TypeDescription("EnumRef.SupplyOptions"));
	Result.Columns.Add("Count", New TypeDescription("Number", New NumberQualifiers));
	
	Return Result;
	
EndFunction

#EndRegion
#Region RegulatorySchedule

Procedure FillDeadlinesForEnsuringBedRest(Demands)
	
	RegulatorySchedule = NormativeScheduleAccordingToTableOfNeeds(Demands); // ValueTable
	RegulatorySchedule.Indexes.Add("Id, ProductionStage");
	RegulatorySchedule.Indexes.Add("Id, Stage");
	
	StSearchKey = New Structure("Id, ProductionStage");
	StSearchLink = New Structure("Id, Stage");
	
	For Each Demand In Demands Do
		
		BorderToBeginning = ?(Demand.StartDate2 >= CurrentSessionDate(),
			Demand.StartDate2,
			CurrentSessionDate());
		BorderToEnd = Demand.DateOfProduction;
		
		Begin = '39991231';
		Ending = '00010101';
		
		StSearchKey.Id = Demand.Id;
		
		For Each Stage In Demand.SpecificationData.Stages Do
			
			StSearchKey.ProductionStage = Stage.StageCode;
			RecordingGraph = RegulatorySchedule.FindRows(StSearchKey)[0];
			
			Stage.DateOfShipment = BorderToBeginning + RecordingGraph.DurationBeforeStart;
			Stage.NotShipInInstallments = True;
			Stage.ReadyForFulfillment = (RecordingGraph.DurationBeforeStart = 0);
			
			If Stage.StageNumber = 1 Then
				If Demand.ProductionScheduling = Enums.WayOfLinkingProductionOperations.Backward Then
					Begin = Min(Begin, BorderToBeginning + RecordingGraph.DurationBeforeStart);
				Else
					If RecordingGraph.ResourceIntensity > 0 Then
						Begin = Min(Begin, BorderToEnd - Int(RecordingGraph.DurationBeforeProductionIssue) - RecordingGraph.ResourceIntensity);
					Else
						Begin = Min(Begin, BorderToEnd - RecordingGraph.DurationBeforeProductionIssue);
					EndIf;
				EndIf;
			EndIf;
			
			If Stage.NextStageNo = 0 Then
				If Demand.ProductionScheduling = Enums.WayOfLinkingProductionOperations.Backward Then
					If RecordingGraph.ResourceIntensity > 0 Then
						Ending = Max(Ending, BorderToBeginning + Int(RecordingGraph.DurationBeforeStart) + RecordingGraph.ResourceIntensity);
					Else
						Ending = Max(Ending, BorderToBeginning + RecordingGraph.DurationBeforeStart);
					EndIf;
				Else
					Ending = Max(Ending, BorderToEnd - RecordingGraph.DurationBeforeProductionIssue);
				EndIf;
			EndIf;
			
		EndDo;
		
		Demand.Begin = Begin;
		Demand.Ending = Ending;
		
		// Period of bedsores
		If Demand.ThisIsRepair Then
			
			If Not Demand.ThisIsIncomingNeed Then
				ParentRelationship = Demand.Outputs.Find(True, "Parent");
				StSearchLink.Id = ParentRelationship.LinkID_;
				StSearchLink.Stage = ParentRelationship.CommunicationStage;
				RecipientStage = RegulatorySchedule.FindRows(StSearchLink)[0];
				If Demand.ProductionScheduling = Enums.WayOfLinkingProductionOperations.Backward Then
					Demand.PeriodOfProductQueue = BorderToBeginning + RecipientStage.DurationBeforeStart;
				Else
					Demand.PeriodOfProductQueue = BorderToEnd - RecipientStage.DurationBeforeProductionIssue - RecipientStage.ResourceIntensity;
				EndIf;
			EndIf;
			
		ElsIf Demand.SpecificationData.QueuePeriodIsLimited Then
			
			If Demand.ThisIsDisassembly Then
				Demand.PeriodOfProductQueue = Begin + Demand.MaximumQueuePeriod;
			Else
				Demand.PeriodOfProductQueue = Ending - Demand.MaximumQueuePeriod;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function NormativeScheduleAccordingToTableOfNeeds(Demands)
	
	StagesAndDependencies = TablesForCalculatingStandardProductionSchedule(
		TMCommonUse.UnloadColumnValues(Demands, "ReferenceOrder"));
	Stages       = StagesAndDependencies.Stages;
	Dependencies = StagesAndDependencies.Dependencies;
	
	FillInStepsOnNeedsTable(Demands, Stages);
	
	Index1 = Demands.Indexes.Add("Id");
	IndexOf2 = Stages.Indexes.Add("ProductionStage");
	IndexOf3 = Stages.Indexes.Add("RelatedToProductionStage");
	
	For Each Demand In Demands Do
		
		FillInInternalDependencies(Demand.SpecificationData.Stages, Dependencies);
		FillInExternalDependenciesOnNeedsTable(Demands, Demand, Dependencies);
		
	EndDo;
	
	FillInDependenciesOfCreatedAndExistingStages(Stages, Dependencies);
	
	Demands.Indexes.Delete(Index1);
	Stages.Indexes.Delete(IndexOf2);
	Stages.Indexes.Delete(IndexOf3);
	
	InformationRegisters.StandardScheduleOfProductionStages.CalculateTheSchedule(Stages, Dependencies);
	
	Return Stages;
	
EndFunction

Function TablesForCalculatingStandardProductionSchedule(References)
	
	Types = New Array;
	Types.Add(Type("DocumentRef.ProductionStage2_2"));
	Types.Add(Type("Number"));
	DescriptionOfDataTypes = New TypeDescription(Types, New NumberQualifiers);
	
	Stages = New ValueTable;
	Stages.Columns.Add("ProductionStage", DescriptionOfDataTypes);
	Stages.Columns.Add("StageSource", New TypeDescription("DocumentRef.ProductionStage2_2"));
	Stages.Columns.Add("Stage", New TypeDescription("CatalogRef.ProductionStages"));
	Stages.Columns.Add("ReferenceOrder", New TypeDescription("DocumentRef.ProductionOrder2_2"));
	Stages.Columns.Add("ResourceIntensity", New TypeDescription("Number", New NumberQualifiers));
	Stages.Columns.Add("ThisIsDisassembly", New TypeDescription("Boolean"));
	Stages.Columns.Add("FirstStage", New TypeDescription("Boolean"));
	Stages.Columns.Add("LastStage", New TypeDescription("Boolean"));
	Stages.Columns.Add("DurationBeforeStart", New TypeDescription("Number", New NumberQualifiers(14, 4)));
	Stages.Columns.Add("DurationBeforeProductionIssue", New TypeDescription("Number", New NumberQualifiers(14, 4)));
	Stages.Columns.Add("RelatedToProductionStage", New TypeDescription("Boolean"));
	Stages.Columns.Add("Id", New TypeDescription("Number", New NumberQualifiers));
	Stages.Columns.Add("StageNumber", New TypeDescription("Number", New NumberQualifiers));
	Stages.Columns.Add("NextStageNo", New TypeDescription("Number", New NumberQualifiers));
	
	Dependencies = New ValueTable;
	Dependencies.Columns.Add("Stage", DescriptionOfDataTypes);
	Dependencies.Columns.Add("NextStage", DescriptionOfDataTypes);
	
	Query = New Query(
		"SELECT
		|	ProductionStage2_2.Ref                                        AS ProductionStage,
		|	CASE ProductionStage2_2.UnitOfMeasureOfStageDuration
		|		WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|			THEN 60
		|		WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|			THEN 3600
		|		WHEN VALUE(Enum.TimeMeasureUnits.DAY)
		|			THEN 86400
		|		WHEN VALUE(Enum.TimeMeasureUnits.Days1)
		|			THEN 86400
		|		ELSE 1
		|	END * ProductionStage2_2.StageDuration                     AS ResourceIntensity,
		|	NOT TRUE IN
		|				(SELECT 
		|					TRUE
		|				FROM
		|					TTCommunicationStages AS Links
		|				WHERE                       
		|					Links.NextStage = ProductionStage2_2.Ref) AS FirstStage,
		|	NOT TRUE IN
		|				(SELECT 
		|					TRUE
		|				FROM
		|					TTCommunicationStages AS Links
		|				WHERE                       
		|					Links.Stage = ProductionStage2_2.Ref)          AS LastStage
		|FROM
		|	Document.ProductionStage2_2 AS ProductionStage2_2
		|WHERE
		|	ProductionStage2_2.ReferenceOrder IN (&References)
		|	AND ProductionStage2_2.Posted
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTCommunicationStages.Stage          AS Stage,
		|	TTCommunicationStages.NextStage AS NextStage
		|FROM
		|	TTCommunicationStages AS TTCommunicationStages");
	
	Query.SetParameter("References", References);
	
	TempTablesManager = New TempTablesManager;
	Documents.ProductionStage2_2.CreateTTCommunicationStagesByOrder(
		TempTablesManager,
		References,
		True);
	Query.TempTablesManager = TempTablesManager;
	
	ResultsArray = Query.ExecuteBatch();
	
	Selection = ResultsArray[0].Select();
	While Selection.Next() Do
		FillPropertyValues(Stages.Add(), Selection);
	EndDo;
	
	Selection = ResultsArray[1].Select();
	While Selection.Next() Do
		FillPropertyValues(Dependencies.Add(), Selection);
	EndDo;
	
	Result = New Structure("Stages, Dependencies", Stages, Dependencies);
	
	Return Result;
	
EndFunction

// Parameters:
// 	Demands - ValueTable
// 	Stages - ValueTable
//
Procedure FillInStepsOnNeedsTable(Demands, Stages)
	
	StageCode = 1;
	
	For Each Demand In Demands Do
		
		For Each Stage In Demand.SpecificationData.Stages Do
			
			Stage.StageCode = StageCode;
			StageCode = StageCode + 1;
			
			NewRow = Stages.Add();
			
			FillPropertyValues(NewRow, Demand, "ReferenceOrder, Id, ThisIsDisassembly");
			FillPropertyValues(NewRow, Stage, "StageNumber, NextStageNo, Stage");
			
			NewRow.ProductionStage = Stage.StageCode;
			NewRow.ResourceIntensity = Stage.StageDurationInSeconds;
			
			If Stage.StageNumber = 1 Or Demand.SpecificationData.Stages.Find(Stage.StageNumber, "NextStageNo") = Undefined Then
				
				ThereAreEntrances = False;
				For Each Enter In Demand.Inputs Do
					If Enter.RsString.Stage = Stage.Stage Then
						ThereAreEntrances = True;
						Break;
					EndIf;
				EndDo;
				
				DisassemblyUnderStage = Demand.ThisIsDisassembly And ValueIsFilled(Demand.StageSource);
				
				NewRow.FirstStage = Not ThereAreEntrances
					And Not DisassemblyUnderStage
					And Demand.PlanNotEarlierThan.IsEmpty();
				
				If DisassemblyUnderStage Then
					NewRow.RelatedToProductionStage = True;
					NewRow.StageSource = Demand.StageSource;
				EndIf;
				
			EndIf;
			
			If Stage.NextStageNo = 0 Then
				
				ThereAreExits = False;
				For Each Output_ In Demand.Outputs Do
					If Output_.RsString.Stage = Stage.Stage Then
						ThereAreExits = True;
						Break;
					EndIf;
				EndDo;
				
				ReleaseUnderStage = Not Demand.ThisIsDisassembly And ValueIsFilled(Demand.StageSource);
				
				NewRow.LastStage = Not ThereAreExits And Not ReleaseUnderStage;
				
				If ReleaseUnderStage Then
					NewRow.RelatedToProductionStage = True;
					NewRow.StageSource = Demand.StageSource;
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Parameters:
// 	Stages - ValueTable
// 	Dependencies - ValueTable
//
Procedure FillInInternalDependencies(Stages, Dependencies)
	
	TheStructureOfTheSearch = New Structure("StageNumber");
	
	For Each Stage In Stages Do
		
		If ValueIsFilled(Stage.NextStageNo) Then
			
			TheStructureOfTheSearch.StageNumber = Stage.NextStageNo;
			FoundRows = Stages.FindRows(TheStructureOfTheSearch);
			
			For Each String In FoundRows Do
				
				NewRow = Dependencies.Add();
				NewRow.Stage = Stage.StageCode;
				NewRow.NextStage = String.StageCode;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
// 	Demands - ValueTable
// 	Demand - ValueTableRow
// 	Dependencies - ValueTable
//
Procedure FillInExternalDependenciesOnNeedsTable(Demands, Demand, Dependencies)
	
	For Each Output_ In Demand.Outputs Do
		
		SVNeed = Demands.Find(Output_.LinkID_, "Id");
		
		SenderString = Demand.SpecificationData.Stages.Find(Output_.RsString.Stage, "Stage");
		RecipientRow = SVNeed.SpecificationData.Stages.Find(Output_.CommunicationStage, "Stage");
		
		If SenderString <> Undefined And RecipientRow <> Undefined Then
					
			NewRow = Dependencies.Add();
			NewRow.Stage = SenderString.StageCode;
			NewRow.NextStage = RecipientRow.StageCode;
				
		EndIf;
		
		If Not Demand.PlanNotEarlierThan.IsEmpty() Then
					
			SenderString = SVNeed.SpecificationData.Stages.Find(Demand.PlanNotEarlierThan);
			RecipientLines_ = Demand.SpecificationData.Stages.FindRows(New Structure("StageNumber", 1));
					
			If SenderString <> Undefined And RecipientLines_.UBound() <> -1 Then
						
				For Each RecipientRow In RecipientLines_ Do
							
					NewRow = Dependencies.Add();
					NewRow.Stage = SenderString.StageCode;
					NewRow.NextStage = RecipientRow.StageCode;
							
				EndDo;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
// 	Stages - ValueTable
// 	Dependencies - ValueTable
//
Procedure FillInDependenciesOfCreatedAndExistingStages(Stages, Dependencies)
	
	TheStructureOfTheSearch = New Structure("RelatedToProductionStage", True);
	FoundRows = Stages.FindRows(TheStructureOfTheSearch);
	
	For Each String In FoundRows Do
		
		If String.ThisIsDisassembly Then
			
			NewRow = Dependencies.Add();
			NewRow.Stage = String.StageSource;
			NewRow.NextStage = String.ProductionStage;
			
			StageString = Stages.Find(String.StageSource, "ProductionStage");
			If StageString <> Undefined Then
				StageString.LastStage = False;
			EndIf;
			
		Else
			
			NewRow = Dependencies.Add();
			NewRow.Stage = String.ProductionStage;
			NewRow.NextStage = String.StageSource;
		
			StageString = Stages.Find(String.StageSource, "ProductionStage");
			If StageString <> Undefined Then
				StageString.FirstStage = False;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region ConvolutionOfNeeds

Procedure CollapseNeeds(Demands, NodulationParameters, SelectionParameters)
	
	Index1 = Demands.Indexes.Add("Id");
	SelectionFields_1 = "BillOfMaterials"
		+ ?(IsBlankString(NodulationParameters.GroupFields), "", "," + NodulationParameters.GroupFields);
	IndexOf2 = Demands.Indexes.Add(SelectionFields_1);
	SelectionStructure = New Structure(SelectionFields_1);
	
	Children = New ValueTable; // Transfer of Software and Analogues from collapsed needs to enlarged ones
	Children.Columns.Add("BillOfMaterials", New TypeDescription("CatalogRef.BillsOfMaterials"));
	Children.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	Children.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Children.Columns.Add("Supply", New TypeDescription("Array"));
	Children.Columns.Add("Substitutes", New TypeDescription("Array"));
	
	StructureOfDescendantsSearch = New Structure("BillOfMaterials, Products, Characteristic");
	
	Queue = New Array;
	
	For Cnt = 1 To 2 Do
		
		PushingScheme = (Cnt = 1);
		
		If Demands.Find(PushingScheme, "ThisIsPushingScheme") = Undefined Then
			Continue;
		EndIf;
		
		Demands.Sort(?(PushingScheme,
			"Begin Asc, Id Desc",
			"Ending Desc, Id Desc"));
		
		For IndexNeed = 0 To Demands.Count()-1 Do
			
			CurNeed = Demands[IndexNeed];
			
			If CurNeed.Processed1
				Or CurNeed.DescendantsAreCollapsed
				Or CurNeed.ThisIsPushingScheme <> PushingScheme
				Or Not CurNeed.PlanNotEarlierThan.IsEmpty() Then
				Continue;
			EndIf;
			
			ArrayOfNeeds = SelectNeedsForConvolution(Demands, CurNeed, SelectionStructure);
			If ArrayOfNeeds.UBound() = -1 Then
				CurNeed.Processed1 = True;
				Continue;
			EndIf;
			
			Children.Clear();
			
			// Choosing a consolidated need
			SummaryNeed = CurNeed;
			For Each Demand In ArrayOfNeeds Do
				If Demand.Begin = SummaryNeed.Begin Then
					
					If Not SummaryNeed.SpecificationData.MainProduct.ThisIsMainProduct
						And Demand.SpecificationData.MainProduct.ThisIsMainProduct Then
						SummaryNeed = Demand;
					EndIf;
					
				ElsIf CurNeed.ThisIsDisassembly Or CurNeed.ThisIsRepair Then
					
					If Demand.Begin > SummaryNeed.Begin Then
						SummaryNeed = Demand;
					EndIf;
					
				Else // Assembly
					
					If Demand.Begin < SummaryNeed.Begin Then
						SummaryNeed = Demand;
					EndIf;
					
				EndIf;
			EndDo;
			ArrayOfNeeds.Add(CurNeed);
			
			// Filling in the summary requirement
			SummaryNeed.Processed1 = True;
			SummaryNeed.DaysFromDemand = DaysFromNeedByGroupOfNeeds(ArrayOfNeeds);
			NeedMainProduct = Undefined;
			
			CollapsedNeeds = Demands.CopyColumns(
				"BillOfMaterials, Products, Characteristic, Count, SpecificationData");
			For Each Demand In ArrayOfNeeds Do
				
				// Preparation of data for the calculation of the release batch
				AddNewRow = True;
				For Each CollapsedString In CollapsedNeeds Do
					If CollapsedString.Products = Demand.Products
						And (CollapsedString.Characteristic = Demand.Characteristic
							Or CollapsedString.SpecificationData.MainProduct.AnyCharacteristic
							And Demand.SpecificationData.MainProduct.AnyCharacteristic) Then
						
						CollapsedString.Count = CollapsedString.Count + Demand.Count;
						AddNewRow = False;
						Break;
				
					EndIf;
				EndDo;
				If AddNewRow Then
					FillPropertyValues(CollapsedNeeds.Add(), Demand);
				EndIf;
				
				// Control of the availability of the main product in the Consolidated Need
				If Not SummaryNeed.SpecificationData.MainProduct.ThisIsMainProduct
						And Demand.SpecificationData.MainProduct.ThisIsMainProduct Then
					NeedMainProduct = Demand;
				EndIf;
				
				// Transferring data to a consolidated need
				If Demand <> SummaryNeed Then
					If Demand.ThisIsIncomingNeed Then
						SummaryNeed.CollapsedIncomingNeeds.Add(Demand);
					EndIf;
					For Each Supply In Demand.Supply Do
						FillPropertyValues(SummaryNeed.Supply.Add(), Supply);
					EndDo;
					For Each Substitute In Demand.Substitutes Do
						FillPropertyValues(SummaryNeed.Substitutes.Add(), Substitute);
					EndDo;
					SummaryNeed.Order = Min(SummaryNeed.Order, Demand.Order);
					
					// Fixation of descendants for subsequent inheritance of Collateral and Analogues
					// when recalculating the descendants of the consolidated need
					Queue.Clear();
					For Each Link In ?(Demand.ThisIsDisassembly, Demand.Outputs, Demand.Inputs) Do
						If Not Link.Parent Then
							Queue.Add(Link);
						EndIf;
					EndDo;
					While Queue.UBound() <> -1 Do
						Link = Queue[0];
						
						Child = Demands.Find(Link.LinkID_, "Id");
						If Child.Supply.Count() > 0
							Or Child.Substitutes.Count() > 0 Then
							FillPropertyValues(StructureOfDescendantsSearch, Child);
							FoundRows = Children.FindRows(StructureOfDescendantsSearch);
							If FoundRows.Count() = 0 Then
								DescendantsLine = Children.Add();
								FillPropertyValues(DescendantsLine, Child, "BillOfMaterials, Products, Characteristic");
							Else
								DescendantsLine = FoundRows[0];
							EndIf;
							If Child.Supply.Count() > 0 Then
								DescendantsLine.Supply.Add(Child.Supply);
							EndIf;
							If Child.Substitutes.Count() > 0 Then
								DescendantsLine.Substitutes.Add(Child.Substitutes);
							EndIf;
						EndIf;
						
						For Each DescendantConnection In ?(Child.ThisIsDisassembly, Child.Outputs, Child.Inputs) Do
							If Not DescendantConnection.Parent Then
								Queue.Add(DescendantConnection);
							EndIf;
						EndDo;
						
						Queue.Delete(0);
					EndDo;
				EndIf;
				
				// The number of inputs in the summary needs should be >= the number in the collapsible needs.
				// If this condition is not met, it means that a reserve has been fulfilled in the consolidated need
				// PF in stock (in the schedule). In this case, it is necessary to transfer the links to the consolidated need.
				If Demand <> SummaryNeed
					And Demand.Inputs.Count() > SummaryNeed.Inputs.Count() Then
					For IndexOf = -Demand.Inputs.Count()+1 To 0 Do
						Link = Demand.Inputs[-IndexOf];
						If Link.Parent Then
							Continue;
						EndIf;
						TransferLink = True;
						For Each SVODConnection In SummaryNeed.Inputs Do
							If Not SVODConnection.Parent
								And Link.RsString.ConnectionKey = SVODConnection.RsString.ConnectionKey Then
								TransferLink = False;
								Break;
							EndIf;
						EndDo;
						
						If TransferLink Then
							NewLink = SummaryNeed.Inputs.Add();
							FillPropertyValues(NewLink, Link);
							NewLink.RsString = SummaryNeed.SpecificationData[Link.RsStringOwnerName].Find(
								Link.RsString.ConnectionKey, "ConnectionKey");
							NewLink.Link.LinkID_ = SummaryNeed.Id;
							NewLink.Link.Link = NewLink;
							
							Demand.Inputs.Delete(Link);
							
							// Shifting underlying needs
							If SummaryNeed.Begin < Demand.Begin Then
								Deviation = Demand.Begin - SummaryNeed.Begin;
								Queue.Clear();
								Queue.Add(NewLink.LinkID_);
								While Queue.UBound() <> -1 Do
									Child = Demands.Find(Queue[0], "Id");
									Child.Begin = Child.Begin - Deviation;
									Child.Ending = Child.Ending - Deviation;
									If ValueIsFilled(Child.PeriodOfProductQueue) Then
										Child.PeriodOfProductQueue = Child.PeriodOfProductQueue - Deviation;
									EndIf;
									Queue.Delete(0);
									For Each DescendantCommunication In Child.Inputs Do
										Queue.Add(DescendantCommunication.LinkID_);
									EndDo;
								EndDo;
							EndIf;
						EndIf;
					EndDo;
				EndIf;
			EndDo;
			
			If SummaryNeed.Supply.Count() > 1 Then
				SummaryNeed.Supply.GroupBy("RowIndex2,WithAssignment,Resolution,ReplacementWithAnalog", "Count");
			EndIf;
			If SummaryNeed.Substitutes.Count() > 1 Then
				SummaryNeed.Substitutes.GroupBy("RowIndex2, Resolution, Products, Characteristic, Warehouse, SupplyOption", "Count");
			EndIf;
			
			// Calculation of the release batch
			ReleaseParty = Catalogs.BillsOfMaterials.ReleaseParty(0,1);
			For Each String In CollapsedNeeds Do
				BatchIssueNov = Catalogs.BillsOfMaterials.CalculateBatchOfOutputByProduct(
					String, String.SpecificationData, SelectionParameters);
				If Catalogs.BillsOfMaterials.CompareReleaseBatches(BatchIssueNov, ReleaseParty) > 0 Then
					ReleaseParty = BatchIssueNov;
				EndIf;
			EndDo;
			SummaryNeed.ReleaseParty = ReleaseParty;
			
			// Copying the main product to the Consolidated Need
			If NeedMainProduct <> Undefined Then
				SummaryNeed.SpecificationData.MainProduct = CommonClientServer.CopyStructure(
					NeedMainProduct.SpecificationData.MainProduct);
			EndIf;
			
			// Recalculating the quantity
			ItemData_3 = Catalogs.BillsOfMaterials.ProductData_5();
			
			FillPropertyValues(ItemData_3, SummaryNeed);
			
			CalculateQuantityPerBatchRelease(
				NodulationParameters,
				ReleaseParty,
				SummaryNeed.SpecificationData,
				ItemData_3);
			
			// Recalculating the quantity in the descendants
			Queue.Clear();
			Queue.Add(SummaryNeed);
			While Queue.UBound() <> -1 Do
				
				Demand = Queue[0];
				For Each Link In ?(Demand.ThisIsDisassembly, Demand.Outputs, Demand.Inputs) Do
					If Link.Parent Then
						Continue;
					EndIf;
					
					Count = Link.RsString.Count;
					
					// Offset of security data
					If Link.RsStringOwnerName = "MaterialsAndServices" And Demand.Supply.Count() > 0 Then
						Table = Demand.SpecificationData.MaterialsAndServices; // ValueTable
						STSoftware = New Structure("RowIndex2", Table.IndexOf(Link.RsString));
						For Each Software_1 In Demand.Supply.FindRows(STSoftware) Do
							Count = Count - Software_1.Count;
						EndDo;
					EndIf;
					
					Child = Demands.Find(Link.LinkID_, "Id");
					If Count > 0 Then
						// Recalculating the quantity
						Child.Count = Count;
						Child.ReleaseParty = Catalogs.BillsOfMaterials.CalculateBatchOfOutputByProduct(
							Child, Child.SpecificationData, SelectionParameters);
						
						FillPropertyValues(ItemData_3, Child);
						
						CalculateQuantityPerBatchRelease(
							NodulationParameters,
							Child.ReleaseParty,
							Child.SpecificationData,
							ItemData_3);
							
						// Inheritance of Collateral and Analogues
						FillPropertyValues(StructureOfDescendantsSearch, Child);
						FoundRows = Children.FindRows(StructureOfDescendantsSearch);
						If FoundRows.Count() <> 0 Then
							For Each Table In FoundRows[0].Supply Do
								For Each String In Table Do
									FillPropertyValues(Child.Supply.Add(), String);
								EndDo;
							EndDo;
							If Child.Supply.Count() > 1 Then
								Child.Supply.GroupBy("RowIndex2,WithAssignment,Resolution,ReplacementWithAnalog", "Count");
							EndIf;
							
							For Each Table In FoundRows[0].Substitutes Do
								For Each String In Table Do
									FillPropertyValues(Child.Substitutes.Add(), String);
								EndDo;
							EndDo;
							If Child.Substitutes.Count() > 1 Then
								Child.Substitutes.GroupBy("RowIndex2, Resolution, Products, Characteristic, Warehouse, SupplyOption", "Count");
							EndIf;
						EndIf;
							
						Queue.Add(Child);
					Else
						// The provision overrides the need, it is necessary to cancel all descendants
						CancelQueue = New Array;
						CancelQueue.Add(Child);
						While CancelQueue.UBound() <> -1 Do
							DescendantCancel = CancelQueue[0];
							DescendantCancel.Collapsed_ = True;
							DescendantCancel.Processed1 = True;
							
							For Each CancelConnection_ In DescendantCancel.Inputs Do
								If Not CancelConnection_.Parent Then
									CancelQueue.Add(Demands.Find(CancelConnection_.LinkID_, "Id"));
								EndIf;
							EndDo;
							CancelQueue.Delete(0);
						EndDo;
					EndIf;
				EndDo;
				Queue.Delete(0);
				
			EndDo;
			
			For Each Demand In ArrayOfNeeds Do
				
				If Demand = SummaryNeed Then
					Continue;
				EndIf;
				
				// Rebuilding relationships
				If Demand.ThisIsDisassembly Or Demand.ThisIsRepair Then
					For Each Link In Demand.Inputs Do
						If Not Link.Parent Then
							Continue;
						EndIf;
						
						SummaryNeedInputs = SummaryNeed.Inputs; // ValueTable
						NewLink = SummaryNeedInputs.Add();
						FillPropertyValues(NewLink, Link);
						NewLink.RsString = SummaryNeed.SpecificationData.IncomingProducts[0];
						
						If ValueIsFilled(Link.Link) Then
							Link.Link.LinkID_ = SummaryNeed.Id;
							Link.Link.Link = NewLink;
						Else
							// There may not be a one-to-one relationship if the repaired product is entered in several lines
							SVNeed = Demands.Find(Link.LinkID_, "Id");
							For Each Output_ In SVNeed.Outputs.FindRows(
									New Structure("LinkID_", Demand.Id)) Do
								Output_.LinkID_ = SummaryNeed.Id;
							EndDo;
						EndIf;
						
					EndDo;
				EndIf;
				
				If Not Demand.ThisIsDisassembly Then // Assembly and repair
					For Each Link In Demand.Outputs Do
						If Not Link.Parent Then
							Continue;
						EndIf;
						
						SummaryNeedOutputs = SummaryNeed.Outputs; // ValueTable
						NewLink = SummaryNeedOutputs.Add();
						FillPropertyValues(NewLink, Link);
						Table = Demand.SpecificationData.ManufacturedProducts; // ValueTable
						NewLink.RsString = SummaryNeed.SpecificationData.ManufacturedProducts[
							Table.IndexOf(Link.RsString)];
						
						Link.Link.LinkID_ = SummaryNeed.Id;
						Link.Link.Link = NewLink;
					EndDo;
				EndIf;
				
				Demand.Collapsed_ = True;
				Demand.Processed1 = True;
				
				// Tagging installation is minimized in descendants
				Queue.Clear();
				For Each Link In ?(Demand.ThisIsDisassembly, Demand.Outputs, Demand.Inputs) Do
					If Not Link.Parent Then
						Queue.Add(Link);
					EndIf;
				EndDo;
				While Queue.UBound() <> -1 Do
					Link = Queue[0];
					
					Child = Demands.Find(Link.LinkID_, "Id");
					Child.Collapsed_ = True;
					Child.Processed1 = True;
					
					For Each DescendantConnection In ?(Child.ThisIsDisassembly, Child.Outputs, Child.Inputs) Do
						If Not DescendantConnection.Parent Then
							Queue.Add(DescendantConnection);
						EndIf;
					EndDo;
					
					Queue.Delete(0);
				EndDo;
				
				// The mark of the convolution in the parents
				Parent = Demand.Parent;
				While Parent <> Undefined Do
					If Parent.Processed1 Then
						Break;
					EndIf;
					Parent.DescendantsAreCollapsed = True;
					Parent = Parent.Parent;
				EndDo;
				
			EndDo;
			
		EndDo;
	EndDo;
	
	Demands.Indexes.Delete(Index1);
	Demands.Indexes.Delete(IndexOf2);
	
EndProcedure

// Returns:
// Array of ValueTableRow:
// * Begin - Date
// * Id - Number
//
Function SelectNeedsForConvolution(Demands, Demand, SelectionStructure)
	
	Result = New Array;
	
	If Demand.SpecificationData.MainProduct.ThisIsMainProduct Then
		Products = Demand.Products;
		Characteristic = Demand.Characteristic;
	Else
		Products = Undefined;
		Characteristic = Undefined;
	EndIf;
	
	FillPropertyValues(SelectionStructure, Demand);
	FoundRows = Demands.FindRows(SelectionStructure);
	
	For Each NextNeed In FoundRows Do
		
		If Demands.IndexOf(NextNeed) <= Demands.IndexOf(Demand)
			Or NextNeed.Processed1
			Or NextNeed.DescendantsAreCollapsed
			Or Not NextNeed.PlanNotEarlierThan.IsEmpty() Then
			Continue;
		EndIf;
		
		// Limitation on the nomenclature and characteristics
		If Demand.SpecificationData.ThereIsSpecifiedMainProduct
			And NextNeed.SpecificationData.MainProduct.ThisIsMainProduct Then
			
			If Products = Undefined Then
				Products = NextNeed.Products;
				Characteristic = NextNeed.Characteristic;
			ElsIf Products <> NextNeed.Products
				Or Characteristic <> NextNeed.Characteristic Then
				Continue;
			EndIf;
			
		EndIf;
		
		// Limitation on the duration of lying down
		InsideBedsorePeriod = True;
		If Demand.ThisIsRepair Then
			If Not Demand.ThisIsIncomingNeed Then
				If NextNeed.Ending <= Demand.PeriodOfProductQueue Then
					InsideBedsorePeriod = True;
					Demand.PeriodOfProductQueue = Min(Demand.PeriodOfProductQueue, NextNeed.PeriodOfProductQueue);
				Else
					InsideBedsorePeriod = False;
				EndIf;
			EndIf;
		ElsIf Demand.SpecificationData.QueuePeriodIsLimited Then
			If Demand.ThisIsDisassembly Then
				InsideBedsorePeriod = NextNeed.Begin <= Demand.PeriodOfProductQueue;
			Else // Assembly
				If NextNeed.Ending <= Demand.Ending Then
					InsideBedsorePeriod = NextNeed.Ending >= Demand.PeriodOfProductQueue;
				Else
					InsideBedsorePeriod = Demand.Ending >= NextNeed.PeriodOfProductQueue;
				EndIf;
			EndIf;
		EndIf;
		
		If InsideBedsorePeriod Then
			Result.Add(NextNeed);
		Else
			Break;
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function DaysFromNeedByGroupOfNeeds(ArrayOfNeeds)
	
	Result = Undefined;
	
	For Each Demand In ArrayOfNeeds Do
		
		If Result = Undefined Then
			Result = Demand.DaysFromDemand;
		Else
			If Demand.ThisIsDisassembly
				Or (Demand.ThisIsRepair And Not Demand.ThisIsIncomingNeed) Then
				
				Result = Max(Result, Demand.DaysFromDemand);
				
			Else
				
				Result = Min(Result, Demand.DaysFromDemand);
				
			EndIf;
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion
#EndRegion
